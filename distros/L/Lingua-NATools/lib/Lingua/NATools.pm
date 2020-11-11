package Lingua::NATools;

our $VERSION = '0.7.12';

use 5.006;
#use v5.20;
use strict;
use warnings;
use utf8;

# locale stuff
use POSIX qw(locale_h);
setlocale(LC_CTYPE, "pt_PT.UTF-8");
use locale;

use Data::Dumper;
use Lingua::NATools::ConfigData;
use Lingua::NATools::Config;

use File::Path qw(make_path remove_tree);
use File::Spec::Functions ('catfile', 'file_name_is_absolute');
use File::Copy;
use POSIX;
use IPC::Open2;
use Compress::Zlib;
use MLDBM qw/DB_File Storable/;
use Fcntl;
use Storable;
use Time::HiRes;
use XML::TMX::Reader;
use Lingua::PT::PLNbase;
use Lingua::Identify qw/:all/;

our $DEBUG = 0;

use parent 'DynaLoader';
bootstrap Lingua::NATools $VERSION;

my $BINPREFIX = Lingua::NATools::ConfigData->config('bindir');
my $LIBPREFIX = Lingua::NATools::ConfigData->config('libdir');

our $LOG;

sub DEBUG {
    $DEBUG && print STDERR join(" ",@_),"\n"
}

sub homedir {
    my $self = shift;
    return $self->{conf}->param("homedir");
}


sub init {
    my $class = shift;
    my $ops = ref($_[0]) ? shift @_ : {};
    my ($dir, $name, @langs) = @_;

    my $homedir = $name;
    $homedir = catfile $dir, $name unless file_name_is_absolute($name);

    die "Can not delete existing '$homedir'\n"  unless !-d $homedir || remove_tree($homedir);
    die "Can'not create directory '$homedir'\n" unless make_path($homedir);

    my $cfg = catfile $homedir, "nat.cnf";

    my $self = {};
    $self->{conf} = Lingua::NATools::Config->new();
    $self->{conf}->param("nr-chunks" => 0);
    $self->{conf}->param("name"      => $name);
    $self->{conf}->param("homedir"   => $homedir);
    $self->{conf}->param("cfg"       => $cfg);
    $self->{conf}->param("nr-tus"    => 0);
    $self->{conf}->param("csize"     => $ops->{csize} || 70000);

    if (@langs) {
        $self->{conf}->param("source-language"          => $langs[0]);
        $self->{conf}->param("target-language"          => $langs[1]);
        $self->{conf}->param("noLanguageIdentification" => 1);
    }

    $self->{conf}->write($self->{conf}->param("cfg"));

    return bless $self => $class
}



sub load {
    my ($class, $dir) = @_;

    return undef unless $dir && -d $dir;

    my $self;
    my $conf = catfile $dir, "nat.cnf";

    if (-f $conf) {
        $self->{conf} = Lingua::NATools::Config->new($conf);
        return bless $self => $class;
    }

    print STDERR "Couldn't open config file [$conf]\n";
    return undef;
}

sub _new_logger {
    my ($verbose, $file) = @_;

    $verbose and return sub {
		my $filename = $file;
		if ($filename) {
        	open my $fh, ">>", $filename or die $!;
        	print $fh @_;
        	close $fh;
		}
        
        print STDERR @_;
    };
    return sub { };
}

sub codify {
    my ($self, $ops, $txt1, $txt2) = @_;
    $LOG = _new_logger($ops->{verbose} || 0, $ops->{log_file});

    # If true, the texts will be tokenized.
    my $tokenize = $self->{tokenize};

    die "Not a valid NATools object\n"   unless $self->isa('Lingua::NATools');

    die "File '$txt1' does not exist\n"  unless -f $txt1;
    die "File '$txt2' does not exist\n"  unless -f $txt2;

    unless ($self->{conf}->param("noLanguageIdentification")) {

        $LOG->(" Identifying languages...\n");

        # Identify source language
        my $source_language = uc(langof_file($txt1));
        $LOG->(" - Source language: $source_language\n");

        if (!$self->{conf}->param("source-language")) {
            $self->{conf}->param("source-language", $source_language);
        } elsif ($self->{conf}->param("source-language") ne $source_language) {
            print STDERR "Warning!! Source-language seems different from previous chunk\n"
        }

        # Identify target language
        my $target_language = uc(langof_file($txt2));
        $LOG->(" - Target language: $target_language\n");

        if (!$self->{conf}->param("target-language")) {
            $self->{conf}->param("target-language", $target_language);
        } elsif ($self->{conf}->param("target-language") ne $target_language) {
            print STDERR "Warning!! Target-language seems different from previous chunk\n"
        }

        $LOG->("\n");
    }

    my $id = $self->{conf}->param("nr-chunks") + 1;

    $LOG->(" Counting sentences...\n");
    my $size = count_sentences($txt1, $txt2, $ops->{verbose});

    $self->{conf}->param("nr-tus" => $self->{conf}->param("nr-tus") + $size);

    die "Sizes mismatch\n" unless $size;
    $LOG->(" Size: $size sentences\n");

    my $nrchunks = $self->calc_chunks($size);
    $LOG->(" Number of chunks: $nrchunks\n");

    # Split corpus simple should handle tokenization if needed.  If a
    # fifth parameter is passed with a true value, tokenization will
    # be done.
    $self->split_corpus_simple( {
                                 tokenize => $tokenize,
                                 verbose  => $ops->{verbose},
                                 chunk    => $id,
                                 nrchunks => $nrchunks
                                },
                                $txt1, $txt2);

    $LOG->("\n");

    my $totaltime = 0;
    for ($id..($id + $nrchunks - 1)) {
        my $time = pre_chunk($ops, $self->{conf}->param("homedir"), $_);
        $totaltime += $time;
        $LOG->(" Chunk number $_ codified in $time seconds\n");
    }

    $LOG->("\n");
    $LOG->("Encode done in $totaltime seconds\n");

    $self->{conf}->param("source-tokens-count",
                         read_second_U32($self->{conf}->param("homedir")."/source.lex"));
    $self->{conf}->param("target-tokens-count",
                         read_second_U32($self->{conf}->param("homedir")."/target.lex"));

    $self->{conf}->param("nr-chunks", $id + $nrchunks - 1);

    my $x = $self->homedir;

    my $Slex = Lingua::NATools::Lexicon->new("$x/source.lex");
    $self->{conf}->param("source-forms", $Slex->size);
    $Slex->close;

    my $Tlex = Lingua::NATools::Lexicon->new("$x/target.lex");
    $self->{conf}->param("target-forms", $Tlex->size);
    $Tlex->close;

    $self->{conf}->write($self->{conf}->param("cfg"));
}



sub count_sentences {
    my ($TXT1, $TXT2, $V) = @_;
    $V ||= 0;

    my $sentence_nr1 = _count_sentences($TXT1, $V);
    my $sentence_nr2 = _count_sentences($TXT2, $V);

    return ($sentence_nr1 == $sentence_nr2) ? $sentence_nr1 : undef;
}

sub _count_sentences {
    my ($txt, $v) = @_;

    my $nr = 0;
    my $last;
    open CP, $txt or die "Cannot open file '$txt' for reading\n";

    $LOG->(sprintf(" - $txt: %8d", $nr));

    while (<CP>) {
        $nr++ if m!^\$$!;
        $LOG->(sprintf("\b\b\b\b\b\b\b\b%8d", $nr)) if $nr % 1000 == 0;
        $last = $_;
    }
    $nr++ unless $last && $last =~ m!^\$$!;
    close CP;

    $LOG->(sprintf("\b\b\b\b\b\b\b\b%8d\n", $nr));

    return $nr;
}



sub user_conf {
    my $homedir = shift || $ENV{HOME};
    return Lingua::NATools::Config->new($homedir) if -f $homedir;

    return {} unless -d $homedir;
    my $natrc = catfile($homedir, ".natrc");

    return {} unless -f $natrc;
    return Lingua::NATools::Config->new($natrc);
}

sub calc_chunks {
    my ($self, $fsize) = @_;
    return $fsize > $self->{conf}->param('csize') ?
      POSIX::ceil($fsize/$self->{conf}->param('csize')) : 1;
}


sub index_invindexes {
    my ($self, $v) = @_;

    my $range = $self->{conf}->param("nr-chunks");

    my @files = map {
        sprintf("%s/source.%03d.crp.invidx", $self->{conf}->param("homedir"), $_)
    } (1..$range);

    my $commd = join(" ",
                     "nat-mergeidx",
                     sprintf("%s/source.invidx", $self->{conf}->param("homedir")),
                     @files);

    my $time = time_command($commd);
    $LOG->(" Merged source index in $time seconds\n");

    @files = map {
        sprintf("%s/target.%03d.crp.invidx", $self->{conf}->param("homedir"), $_)
    } (1..$range);

    $commd = join(" ",
                  "nat-mergeidx",
                  sprintf("%s/target.invidx",$self->{conf}->param("homedir")),
                  @files);
    $time = time_command($commd);
    $LOG->(" Merged target index in $time seconds\n");
}

sub _ngrams_reorganize {
    my ($from, $to) = @_;
    open R, "<:utf8", $from or die "Can't open file [$from] for reading";
    open W, ">:utf8", $to   or die "Can't open file [$to] for writing";
    while(<R>) {
        chomp;
        my @F = split /\s/, $_;
        push @F, shift @F;
        print W "@F\n";
    }
    close W;
    close R;
    unlink $from;
}
			
sub _ngrams_tosqlite {
    my ($from, $to, $n) = @_;
    my @v = (undef, undef, qw/bigrams trigrams tetragrams/);
    open SQL, "|sqlite3 $to";
    my $fields = join(",", map {"w$_"} (1..$n));
    print SQL "CREATE TABLE $v[$n] ($fields,occs);\n";
    print SQL ".separator ' '\n";
    print SQL ".import $from $v[$n]\n";
    for my $i (1..$n) {
        print SQL "CREATE INDEX idx${n}w${i} ON $v[$n] (w$i);"
    }
    close SQL;
    unlink $from;
}

sub index_ngrams {
    my ($self, $v) = @_;

    my $ID    = $self->{conf}->param("homedir");
    my $range = $self->{conf}->param("nr-chunks");

    for my $i (1..$range) {
        ### Source language ------------------------------------------------
        my $file = sprintf("%s/source.%03d.crp", $ID, $i);
        $LOG->(" Creating ngrams for '$file'\n");

        for my $n (2..4) {
            time_command(join(" ",
                              "nat-ngrams -n $n",
                              $file,
                              sprintf("%s/S.%03d.${n}grams", $ID, $i)));
        }

        ### Target language ------------------------------------------------
        $file = sprintf("%s/target.%03d.crp", $ID, $i);
        $LOG->(" Creating ngrams for '$file'\n");

        for my $n (2..4) {
            time_command(join(" ",
                              "nat-ngrams -n $n",
                              $file,
                              sprintf("%s/T.%03d.${n}grams", $ID, $i)));
        }
    }

    ## Merge all
    for my $i (2..4) {
        for my $l ("T","S") {
            my $ngrams = sprintf("%s/%s.%dgrams", $ID, $l, $i);
            time_command(join(" ",
                              "nat-ngrams -j",
                              $ngrams,
                              map { sprintf("%s/%s.%03d.%dgrams", $ID, $l, $_, $i) } (1..$range)));

            time_command(sprintf("nat-ngrams -o 1 -d $ngrams %s/%s.lex > $ngrams.txt",
                                 $ID, ($l eq "T")?"target":"source"));

            time_command(sprintf("LC_ALL='C' sort -n -r $ngrams.txt > %s/_%s%d", $ID, $l, $i));

            unlink "$ngrams.txt";
            unlink $ngrams;

            _ngrams_reorganize("$ID/_$l$i" => "$ID/__$l$i");
            _ngrams_tosqlite("$ID/__$l$i" => "$ID/$l.$i.sqlite", $i);
        }
    }
    $self->{conf}->param("n-grams", "1");
    $self->{conf}->write($self->{conf}->param("cfg"));
}



sub split_corpus_simple {
    my ($self, $ops, $TXT1, $TXT2) = @_;

    my $tokenize = $ops->{tokenize} || 0;
    my $nrchunks = $ops->{nrchunks} or die "split_corpus_simple called without number of chunks.";
    my $i        = $ops->{chunk}    or die "split_corpus_simple called without chunk id.";

    my $ODIR = $self->{conf}->param("homedir");
    my $local_counter;

    {
        local $/ = "\n\$\n";

        open A, "<:utf8", $TXT1 or die "Cannot open file $TXT1\n";
        open B, "<:utf8", $TXT2 or die "Cannot open file $TXT2\n";

        my $out1 = catfile $ODIR => sprintf("source.%03d",$i);
        my $out2 = catfile $ODIR => sprintf("target.%03d",$i);

        open AA, ">:utf8", $out1 or die "Cannot create output file $out1";
        open BB, ">:utf8", $out2 or die "Cannot create output file $out2";

        $local_counter++;

        $LOG->(" Creating chunks:\n");

        my $c = 0;
        my $csize = $self->{conf}->param('csize');
        while (<A>) {
        	chomp;

            $c++;
            $LOG->("\r - chunk $i: $c translation units") if $c % 100 == 0;
            
            my $next = 0;
            
            $next = 1 if $_ =~ m!^\s*$!u;
            $_ = join " ", atomiza($_) if $tokenize;
            s/\$/_\$/g;

            chomp(my $b = <B>);
            $next = 1 if $b =~ m!^\s*$!u;

            $b = join " ", atomiza($b) if $tokenize;
            $b =~ s/\$/_\$/g;

            if (!$next) {
	            print AA "$_\n\$\n";
	            print BB "$b\n\$\n";
	        }

            if ($nrchunks !=1 && $c >= $csize) {
                $LOG->("\r - chunk $i: $c translation units\n");
                $i++;
                $c = 0;
                close AA;
                close BB;

                $out1 = catfile $ODIR => sprintf("source.%03d",$i);
                $out2 = catfile $ODIR => sprintf("target.%03d",$i);

                open AA, ">:utf8", $out1 or die "Cannot create output file $out1";
                open BB, ">:utf8", $out2 or die "Cannot create output file $out2";
                $local_counter++;

                $LOG->(", $i");
            }
        }
        $LOG->("\r - chunk $i: $c translation units\n");
        close AA;
        close BB;
        close A;
        close B;
    }

    if ($local_counter < $nrchunks) {
    	$LOG->("Something went bad. Planned $nrchunks, created $local_counter\n");
    	die "Something went bad. Planned $nrchunks, created $local_counter\n";
    }
}


sub run_initmat {
    my ($self, $chunk) = @_;
    my ($crp1, $crp2) = (catfile($self->{conf}->param("homedir"),
                                 sprintf("source.%03d.crp",$chunk)),
                         catfile($self->{conf}->param("homedir"),
                                 sprintf("target.%03d.crp",$chunk)));
    my $mat = catfile($self->{conf}->param("homedir"),
                      sprintf("matrix.%03d.init",$chunk));
    time_command("nat-initmat $crp1 $crp2 $mat");
}


sub run_mat2dic {
    my ($self, $chunk) = @_;
    my $matIn = catfile($self->{conf}->param("homedir"),
                        sprintf("matrix.%03d.EM",$chunk));
    my $dic   = catfile($self->{conf}->param("homedir"),
                        sprintf("dict.%03d",$chunk));

    time_command("nat-mat2dic $matIn $dic");
    unlink $matIn;
}


sub run_post {
    my ($self, $chunk) = @_;
    my ($lex1, $lex2) = (catfile($self->{conf}->param("homedir"), "source.lex"),
                         catfile($self->{conf}->param("homedir"), "target.lex"));
    my ($bin1, $bin2) = (catfile($self->{conf}->param("homedir"),
                                 sprintf("source-target.%03d.bin", $chunk)),
                         catfile($self->{conf}->param("homedir"),
                                 sprintf("target-source.%03d.bin", $chunk)));
    my $dic = catfile($self->{conf}->param("homedir"), sprintf("dict.%03d",$chunk));
    my ($p1,$p2) = (catfile($self->{conf}->param("homedir"),
                            sprintf("source.%03d.crp.partials", $chunk)),
                    catfile($self->{conf}->param("homedir"),
                            sprintf("target.%03d.crp.partials", $chunk)));

    time_command("nat-postbin $dic $p1 $p2 $lex1 $lex2 $bin1 $bin2");

    unlink $dic;
}


sub run_generic_EM {
    my ($self, $alg, $iter,$chunk) = @_;

    my ($crp1, $crp2) = (catfile($self->{conf}->param("homedir"),
                                 sprintf("source.%03d.crp",$chunk)),
                         catfile($self->{conf}->param("homedir"),
                                 sprintf("target.%03d.crp",$chunk)));

    my $matIn  = catfile($self->{conf}->param("homedir"), sprintf("matrix.%03d.init",$chunk));
    my $matOut = catfile($self->{conf}->param("homedir"), sprintf("matrix.%03d.EM",$chunk));

    time_command("nat-$alg $iter $crp1 $crp2 $matIn $matOut");

    unlink $matIn;
}


sub align_all {
    my ($self, $conf) = @_;
    my $id = $self->{conf}->param('nr-chunks');
    for (1..$id) {
        $self->align_chunk($_, 0, $conf)
    }
}


sub align_chunk {
    my ($self, $chunk, $V, $conf) = @_;

    $LOG->(" Starting alignment for chunk $chunk\n");

    my $id = $self->{conf}->param('nr-chunks');

    die "Chunk $chunk does not exist\n" if $chunk <= 0 && $chunk > $id;

    my $algorithm = "ipfp";
    my $iters = 5;

    ## Choose algorithm
    if ($conf->{noEM}) {
        $algorithm = "none";
    } elsif ($conf->{ipfp}) {
        $algorithm = "ipfp";
        $iters = $conf->{ipfp} || 5;
    } elsif ($conf->{samplea}) {
        $algorithm = "samplea";
        $iters = $conf->{samplea} || 10;
    } elsif ($conf->{sampleb}) {
        $algorithm = "sampleb";
        $iters = $conf->{sampleb} || 10;
    }

    $self->run_initmat($chunk);

    if ($algorithm ne "none") {
        $self->run_generic_EM($algorithm, $iters, $chunk);
    } else {
        move(catfile($self->{conf}->param("homedir"), sprintf("matrix.%03d.init",$chunk)),
             catfile($self->{conf}->param("homedir"), sprintf("matrix.%03d.EM",$chunk)));
    }
    $self->run_mat2dic($chunk);
    $self->run_post($chunk);
}



sub run_dict_add {
    my ($self, $chunk) = @_;

    my ($bin1, $bin2) = (catfile($self->{conf}->param("homedir"),
                                 sprintf("source-target.%03d.bin", $chunk)),
                         catfile($self->{conf}->param("homedir"),
                                 sprintf("target-source.%03d.bin", $chunk)));
    my ($dic1, $dic2);

    if ($chunk == 1) {
        ($dic1, $dic2) = (catfile($self->{conf}->param("homedir"),"source-target.bin"),
                          catfile($self->{conf}->param("homedir"),"target-source.bin"));
        ($self->{DIC1}, $self->{DIC2}) = ($dic1, $dic2);
        copy $bin1 => $dic1;
        copy $bin2 => $dic2;
    }
    else {
        ($dic1, $dic2) = ($self->{DIC1}, $self->{DIC2});

        time_command("nat-dict add $dic1 $bin1");
        time_command("nat-dict add $dic2 $bin2");
  }
}


sub make_dict {
    my ($self, $V) = @_;

    $LOG->("Creating dictionary");
    for (1..$self->{conf}->param("nr-chunks")) {
        my $bin = catfile($self->{conf}->param("homedir"), sprintf("source-target.%03d.bin", $_));
        $LOG->(".");
        run_dict_add($self, $_, $V) if -f $bin;
    }
    $LOG->("\n");
}



sub pre_chunk {
    my ($ops, $dir, $chunk) = @_;

    my $cp1 = catfile($dir, sprintf("source.%03d", $chunk));
    my $cp2 = catfile($dir, sprintf("target.%03d", $chunk));

    my $lex1 = catfile($dir, "source.lex");
    my $lex2 = catfile($dir, "target.lex");

    my $crp1 = catfile($dir, sprintf("source.%03d.crp", $chunk));
    my $crp2 = catfile($dir, sprintf("target.%03d.crp", $chunk));

    my $ignore = "";
    $ignore = "-i" if $ops->{ignore_case};

    time_command("nat-pre $ignore $cp1 $cp2 $lex1 $lex2 $crp1 $crp2");
}


sub dump_ptd {
    my ($self, $ops) = @_;
    my $conf = shift || {};
    my $dir = $self->{conf}->param("homedir");
    my $u = "";
    time_command("nat-dumpDicts -self $dir");
}


sub time_command {
    my $command = shift;
    my $time = [Time::HiRes::gettimeofday];

    DEBUG("Running", $command);
    die "ERROR: $?\n" unless system($command)==0;

    $time = Time::HiRes::tv_interval($time);
    return $time;
}


sub split_corpus {
    my $self = shift;
    my $i = shift;

    {
        my $c = 0;
        local $/ = '$';
        open A, $self->{TXT1} or die "Cannot open file $self->{TXT1}\n";
        open B, $self->{TXT2} or die "Cannot open file $self->{TXT2}\n";
        open AA, ">",
          catfile($self->{conf}{output_dir}, $self->{TXT1}.".$i")
            or die "Cannot create output file";
        open BB, ">",
          catfile($self->{conf}{output_dir}, $self->{TXT2}.".$i")
            or die "Cannot create output file";
        DEBUG("Creating chunk $i");
        while(<A>) {

            if (exists($self->{filter1})) {
                print AA &{$self->{filter1}}($_);
            } else {
                print AA;
            }
            my $b = <B>;

            if (exists($self->{filter2})) {
                print BB &{$self->{filter2}}($b);
            } else {
                print BB $b;
            }

            $c++;
            if ($self->{'nr-chunks'}!=1 && $c >= $self->{conf}->param('csize')) {
                $i++; $c = 0;
                close AA;
                close BB;
                open AA, ">",
                  catfile($self->{conf}{output_dir}, $self->{TXT1}.".$i")
                    or die "Cannot create output file";
                open BB, ">",
                  catfile($self->{conf}{output_dir}, $self->{TXT2}.".$i")
                    or die "Cannot create output file";
                DEBUG("Creating chunk $i");
            }
        }
        close AA;
        close BB;
        close A;
        close B;
    }
}


sub get_description {
    my $self = shift;
    return $self->{conf}->param("description");
}

sub set_description {
    my ($self, $description) = @_;
    $description=~s/\n/ /g;
    $description=~s/\s\s+/ /g;
    $self->{conf}->param("description" => $description);
    $self->{conf}->save;
}

sub set_rank_cfg {
    my $self = shift;
    my $conf = $self->{conf};
    $conf->param('rank' => 'rank');
    $conf->save;
}

sub dbs {
    my $self = shift;
    return ($self->{db1},$self->{db2});
}


sub rank {
    my ($file, $slex, $tlex, $sdic, $tdic, $scrp, $tcrp) = @_;
    my ($s,$t);
    my $i = 0;

    open CSS, "nat-css $slex $scrp $tlex $tcrp all |"
      or die "Cannot open pipe...\n";

    my $lex1 = NAT::Lexicon->new($slex);
    my $lex2 = NAT::Lexicon->new($tlex);

    my $dic1 = NAT::Dict->open($sdic);
    my $dic2 = NAT::Dict->open($tdic);

    while($s = <CSS>) {
        chomp $s;
        chomp($t = <CSS>);

        my $ss = $lex1->sentence_to_ids(lc $s);
        my $tt = $lex2->sentence_to_ids(lc $t);
        my $val = full_sentence_similarity( { sourceDict => $dic1,
                                              targetDict => $dic2 }, $ss, $tt);
        #$val*=2;
        #$val = 1 if $val > 1;
        print {$file} pack("d",$val);
    }

    close CSS;
    $lex1->close;
    $lex2->close;
    $dic1->close;
    $dic2->close;
}


# This new version should work with integer dictionaries
sub full_sentence_similarity {
    # We need two dictionaries and two sentences.
    # The sentences must be an array of integers.
    return -1 unless ref $_[0];
    my ($conf,$s1,$s2) = @_;

    return -1 if not $s1 or not $s2 or not ref $s1 or not ref $s2;
    return -1 if not $conf->{sourceDict} or not $conf->{targetDict};

    return fulldicsim($conf->{sourceDict}->{id},
                      $conf->{targetDict}->{id},
                      $s1, $s2);

    my $v1 = c_sentence_similarity( +{ %{$conf},
                                       stopwrds => $conf->{sourceStopWrds},
                                       dict => $conf->{sourceDict}},
                                    $s1, $s2);
    my $v2 = c_sentence_similarity( +{ %{$conf},
                                       stopwrds => $conf->{targetStopWrds},
                                       dict => $conf->{targetDict}},
                                    $s2, $s1);
    return ($v1 + $v2)/2;
}


sub c_sentence_similarity{
    return -1 unless ref $_[0];
    my $conf = shift;
    my ($s1,$s2) = @_;
    return -1 if not $s1 or not $s2 or not $conf->{dict};

    my $dict = $conf->{dict}->{id};
    return dicsim($dict, $s1, $s2);
}


sub sentence_similarity {
    return -1 unless ref $_[0];
    my $conf = shift;
    my ($s1,$s2) = @_;
    return -1 if not $s1 or not $s2 or not $conf->{dict};

    my $dict = $conf->{dict};
    my $val = 0;

    # words for the source sentence
    my @wrds1 = @$s1;

    # remove some specific words if the stopwrds option is present;
    if ($conf->{stopwrds}) {
        my %tmp;
        @tmp{@{$conf->{stopwrds}}} = @{$conf->{stopwrds}};
        @wrds1 = grep { !exists($tmp{$_}) } @wrds1 if ($conf->{stopwrds});
    }

    # number of words to be checked
    my $s1size = scalar(@wrds1);
    $s1size = $conf->{size} if exists($conf->{size});

    # create an associative array for quick test of words existence
    my %w2;
    @w2{@$s2} = @$s2;

    # for each word on the first sentence, get the best word on the target array.
    for my $w (@wrds1) {
        if ($dict->exists($w)) {
            my %trans = (@{$dict->vals($w)});
            for my $x (keys %trans) {
                if (exists($w2{$x})) {
                    $val += (1/$s1size) * ($trans{$x} || 0);
                    last;
                }
            }
        }
    }

    return $val;
}

sub check_bidirectional_sentence_similarity {
    my $conf = (ref($_[0]))?shift():{};

    my $s1 = shift || undef;
    my $s2 = shift || undef;

    return -1 if (!$s1 || !$s2);
    return -1 if (!$conf->{sourceDict} || !$conf->{targetDict});

    # Splitting here the senteces should be a little faster...
    my @s1 = split /\s+/, $s1;
    my @s2 = split /\s+/, $s2;

    my $v1 = check_sentence_similarity( +{ %{$conf},
                                           stopwrds => $conf->{sourceStopWrds},
                                           dbfile => $conf->{sourceDict}{dbfile}}, \@s1, \@s2);
    my $v2 = check_sentence_similarity( +{ %{$conf},
                                           stopwrds => $conf->{targetStopWrds},
                                           dbfile => $conf->{targetDict}{dbfile}}, \@s2, \@s1);
    ($v1 + $v2)/2;
}


sub check_sentence_similarity {
    my $conf = (ref($_[0]))?shift():{};

    my $s1 = shift || undef;
    my $s2 = shift || undef;

    return -1 if (!$s1 || !$s2);
    return -1 if (!$conf->{dbfile});

    my $db = $conf->{dbfile};
    my $val = 0;

    # words for the source sentence
    my @wrds1 = @$s1;

    # remove words with length less than a threshold, if the ignore_size option is present
    @wrds1 = grep { length($_) > $conf->{ignore_size} } @wrds1 if ($conf->{ignore_size});

    # remove some specific words if the stopwrds option is present;
    if ($conf->{stopwrds}) {
        my %tmp;
        @tmp{@{$conf->{stopwrds}}} = @{$conf->{stopwrds}};
        @wrds1 = grep { !exists($tmp{$_}) } @wrds1 if ($conf->{stopwrds});
    }

    my $s1size = scalar(@wrds1);
    $s1size = $conf->{size} if exists($conf->{size});

    # create an associative array for quick test of words existence
    my %w2;
    @w2{@$s2} = @$s2;

    # for each word on the first sentence, get the best word on the target array.
    for my $w (@wrds1) {
        my $y;
        if ($y = search($db, $w)) {
            # TODO: Maybe it can be useful to sort these keys to get best answers first.
            for my $x (keys %{$db->{$y}{trans}}) {
                if (search(\%w2, $x)) {
                    $val += (1/$s1size) * ($db->{$y}{trans}{$x}||0);
                    last;
                }
            }
        }
    }
    return $val;
}


sub merge_dict_lex {
    my $conf = (ref($_[0]))?shift():{};
    my $dictFile = shift;
    my $lexFile = shift;

    my $dict = load_dict($dictFile);
    my $lex  = load_lex($lexFile);
    my %data;

    if ($conf->{dbfile}) {
        tie %data, 'MLDBM', $conf->{dbfile}, O_CREAT, 0640 or die $!;
    }

    for (keys %$dict) {
        $data{$_} = +{count => $lex->{$_}{count},
                      trans => $dict->{$_}};
        $data{":".$lex->{$_}{id}} = $_ if defined $lex->{$_}{id};
    }

    if ($conf->{store}) {
        store \%data, $conf->{store};
    }

    if ($conf->{dbfile}) {
        untie %data;
    }

    return \%data;
}

##
sub load_dict {
    my $conf = (ref($_[0]))?shift():{};
    my $file = shift;

    my $dic = undef;
    unless ($dic = do $file) {
        warn "This does not seems a good dicitonary file: $@" if $@;
        warn "Couldn't load file: $!" unless defined $dic;
    }

    if ($conf->{dbfile}) {
        my %data;
        tie %data, 'MLDBM', $conf->{dbfile}, O_CREAT, 0640 or die $!;
        for (keys %{$dic}) {
            $data{$_} = $dic->{$_};
        }
        untie %data;
    }

    return $dic;
}


##
sub load_lex {
    my $conf = (ref($_[0]))?shift():{};
    my $file = shift;

    my %data;

    if ($conf->{dbfile}) {
        tie %data, 'MLDBM', $conf->{dbfile}, O_CREAT, 0640 or die $!;
    }

    my $gz = gzopen($file, "rb") or die "Cannot open file: $!\n";
    my $buffer;
    $gz->gzread($buffer, 4);
    my $res = unpack("I", $buffer);

    # item count
    # REPEAT count
    ### id
    ### count
    ### string till a '\0'

    # print "RES: $res\n";
    while(--$res) {
        my ($the_id, $cnt, $chr, $str);

        $str = "";

        $gz->gzread($buffer, 4);
        $the_id = unpack("I", $buffer);

        $gz->gzread($buffer, 4);
        $cnt = unpack("I", $buffer);

        do {
            $gz->gzread($buffer, 1);
            $buffer = unpack("C", $buffer);
            $chr = chr($buffer);
            $str .= $chr if ($buffer);
        } while ($buffer);

        if ($conf->{id}) {
            $data{$the_id} = { word => $str, count => $cnt };
        } else {
            $data{$str} = { count => $cnt, id => $the_id };
        }
    }

    if ($conf->{dbfile}) {
        untie %data;
    }

    return \%data;
}

sub natdict_add_files {
    my ($f1, $f2, $f3) = @_;
    return 0 unless -f $f1 && -f $f2;
    return nat_dict_add_files($f1, $f2, $f3);
}

sub tmx2files {
    my $conf = {};
    $conf = shift if ref $_[0];
    my $tmx = shift;
    my @desired_languages = @_;

    my $reader = XML::TMX::Reader->new($tmx);
    (not $reader) and DEBUG("Error initializing XML::TMX::Reader for $tmx") and return undef;

    my @langs = map { s/_.*$//; lc $_} $reader->languages;

    my ($l1,$l2);
    print STDERR "Selecting languages..." if $conf->{verbose};
    if (@desired_languages == 2) {
        @desired_languages = map { lc } @desired_languages;

        my %tmp;
        @tmp{@langs} = @langs;
        for (@desired_languages) {
            if (not exists($tmp{$_})) {
                print STDERR " language $_ not found\n (available languages: @langs)\n";
                exit 1;
            }
        }
        ($l1,$l2) = @desired_languages;
    } else {
        if (@langs < 2) {
	    return undef;
        } else {
	    ($l1,$l2) = @langs;
        }		
    }

    print STDERR "done ($l1,$l2)\nExporting TMX..." if $conf->{verbose};
    my ($f1,$f2) = ("$tmx-$l1", "$tmx-$l2");
    my $CNT=0;
    open F1, ">:utf8", $f1 or (DEBUG "Error creating file $f1" and return undef);
    open F2, ">:utf8", $f2 or (DEBUG "Error creating file $f2" and return undef);
    $reader->ignore_markup;
    my $processor = sub {
        my $tu = shift;
        printf STDERR "\rExporting TMX (%d TU) ...", $CNT if $conf->{verbose} && !($CNT % 1000);

        # Temporary hack -- XML::TMX::Reader should normalize languages
        for (keys %$tu) {
            if (/^-/) {
                delete $tu->{$_}
            } else {
                $tu->{lc $_} = $tu->{$_}{-seg}
            }
        }

        if (exists($tu->{$l1}) && exists($tu->{$l2})) {
            $CNT++;
            my ($t1, $t2) = ($tu->{$l1}, $tu->{$l2});
            for ($t1,$t2) {
                s/\$/_DOLLAR_/g;
                $_ = mytokenize($_);
                s/^[\s\n]+//ug;
                s/[\s\n]+$//ug;
            }
            print F1 "$t1\n\$\n";
            print F2 "$t2\n\$\n";
        }
    };
    $reader->for_tu( $processor, tags => 0);
    printf STDERR "\rExported TMX (%d TU)\n", $CNT if $conf->{verbose};
    close F1;
    close F2;
    return ($f1,$f2);
}

sub mytokenize {
    my $string = shift;
#    my $punct='[\.:;,!?\'"]';
    my $punct='[.:;,!?\'"—“‘’”\x{200B}«»()]';
    $string =~ s/(\w)($punct)/$1 $2/ug;
    $string =~ s/($punct)(\w)/$1 $2/ug;
    return $string;
}


sub read_second_U32 {
    my $file = shift;
    my $int;
    open F, $file or die "Can't open file :'$file'";
    seek F, 4, 0;
    read F, $int, 4;
    close F;
    unpack "L", $int;
}

sub find_rules {
    my ($l1, $l2) = @_;
    my ($swap, $file) = (0,undef);
    my $basepath = catfile( $LIBPREFIX, 'NATools');

    print STDERR "Searching system rules file for language pair $l1 $l2\n";
    $file = catfile($basepath, "rules.${l1}-${l2}");
    if (!-f $file) {
        $file = catfile($basepath, "rules.${l2}-${l1}");
        $swap = 1;
        $file = undef unless -f $file;
    }

    return ($file, $swap);
}



1;
__END__

=encoding UTF-8

=head1 NAME

NATools - A framework for Parallel Corpora processing

=head1 ABSTRACT

  NATools is a package of tools to process parallel corpora. It
  includes a sentence aligner, a probabilistic translation dictionary
  extraction tool, a terminology extraction tool and some other
  functionalities.


=head1 DESCRIPTION

This is a collection of functions used on the NATools tools. Some of
them can be used independently. Check documentation bellow.

=head2 C<init>

Use this function to initialize a parallel corpora repository. You
must supply a C<directory> where the repository will reside, and its
C<name>:

  my $pcorpus = Lingua::NATools->init("/var/corpora", "myPCorpus")

This would create a directory named C</var/corpora/myPCorpus> with a
configuration file, and returns a blessed object.

To add texts to this empty repository use the C<codify> method.


=head2 C<load>

This function loads information from a NAT repository. Call it with
the directory where the repository was created.

  my $pcorpus = Lingua::NATools->load("/var/corpora/EuroParl-PT.EN");


=head2 C<codify>

This method is used to add a pair of NATools style texts to a parallel
corpora repository. The files should be sentence-aligned, with each
sentence separated by a C<$> in a line by itself.

The method is called in a repository object, and with two mandatory
arguments: the two file names for the two chosen languges. Note that
this method does not verify the corpora languages, so you must be
coherent when calling it. The third and optional argument C<verbose>
should be true if you want this function to print details on progress
to C<Stdout>.

The method B<dies> if the files does not exist or if the number of
sentences on both files differ.

Example of invocation:

  $pcorpus->codify({ignore_case => 1},
                   "/var/corpora/Europarl.PT",
                   "/var/corpora/Europarl.EN");


=head2 C<count_sentences>

This auxiliary function is used to count sentences on two NATools
sentence-aligned files. If the two files have the same number of
sentences that number is returned. If not, C<undef> is given.

An optional third argument can be given. That is a boolean value
stating if some verbose output should be printed in C<StdErr>.

  my $nr = count_sentences("/var/corpora/EuroParl.PT",
                           "/var/corpora/EuroParl.EN", 1);


=head2 C<user_conf>

Returns a hash reference with .natrc contents. You might pass the home directory 
as parameter, or directly the configuration file.


=head2 C<calc_chunks>

This auxiliary method receives the number of sentences in a corpora
and returns the number of chunks to be created.

  my $nrchunks = $nat->calc_chunks($nrsentences);


=head2 C<index_invindexes>

Each process of encoding chunks creates an inverted search index. This
method should be called to re-index all these indexes in a common one.

Just call it in the repository object. If needed, you can supply a
true argument so the function will be verbose.

  $pcorpus->index_invindexes;


=head2 C<index_ngrams>

This method calculates ngrams (bigrams, trigrams and tetragrams) for
both languages and ALL chunks.

  $pcorpus->index_ngrams;


=head2 C<split_corpus_simple>

This method is called by the C<codify> method to split the corpora
into chunks. Note that this method should be called for any number of
chunks, including the singular one.

The method receives an hash reference with configuration values, and
the two text files with the text to be tokenized. The hash should
include, at least, the number of chunks, and the chunk currently being
processed.

  $pcorpus->split_corpus_simple({tokenize => 0,
                                 verbose => 1,
                                 chunk => 1, nrchunks => 16},
                                    "/var/corpora/EuroParl.PT",
                                    "/var/corpora/EuroParl.EN");


=head2 C<run_initmat>

This method invoques the C program C<nat-initmat> for a specific
chunk. You must supply the chunk number, and it should exist. It
returns the time used to run the command.

  $pcorpus->run_initmat(3);


=head2 C<run_mat2dic>

This method invoques the C program C<nat-mat2dic> for a specific
chunk. You must supply the chunk number, and it should exist. It
returns the time used to run the command.

  $pcorpus->run_mat2dic(4);


=head2 C<run_post>

This method invoques the C program C<nat-postbin> for a specific
chunk. You must supply the chunk number, and it should exist. It
returns the time used to run the command.

  $pcorpus->run_post(5);

=head2 C<run_generic_EM>

This method invoques one of the three algorithms for Entropy
Maximization of the alignment matrix: C<nat-sampleA>, C<nat-sampleB>
and C<nat-ipfp>.

You should call the method with the name of the algorithm ("sampleA",
"sampleB" or "ipfp"), the number of iterations to be done, and the
chunk to be processed.

Returns the time used to run the command.

  $pcorpus->run_generic_EM("ipfp", 5, 3);

=head2 C<align_all>

This method will re-align all chunks in the corpora repository. It
will not re-encode them, just re-align.

  $pcorpus->align_all;


=head2 C<align_chunk>

This method will re-align a specific chunk in the corpora repository. It
will not re-encode it, just re-align.

You need to give a first argument with the chunk number to be aligned,
and a optional second argument stating if you want verose output.

  $pcorpus->align_chunk(3,0);


=head2 C<run_dict_add>

This method appends a chunk to both languages dictionaries (not
NATdicts). You must supply a chunk number (and it should exist).  The
method should not be called directly. Or, if really needed, call it
for all chunks, one at a time, starting with the first.

  for (1..10) {
    $pcorpus->run_dict_add($_)
  }



=head2 C<make_dict>

This method creates the corpora dictionaries (not NATDicts). The
method is called directly in the object with an optional argument to
force verbose output if needed. This method will call C<run_dict_add>
for each chunk.

  $pcorpus->make_dict;


=head2 C<pre_chunk>

This function does the encoding for each created chunk. It is called
internally by the C<codify> method. You should call it with the home
directory for the parallel corpora repository and the chunk
identifier.

   pre_chunk({ ignore_case => 1}, "/var/corpora/EuroParl", 4);


=head2 C<dump_ptd>

This function calls nat-dumpDicts command to dump a PTD for the current
corpus.

  $self->dump_ptd( );


=head2 C<time_command>

This is a C<system> like function. Pass a command and it gets
executed. Also, the time of the execution is returned.

  my $time = time_command("nat-pre... ");


=head2 Aligning corpora files

The C<align> constructor is used to align two parallel, sentence
aligned corpora. Use it with

  use NAT;
  Lingua::NATools->align("EN", "PT");

where C<EN> and C<PT> are parallel corpora files. These files syntax
is a sequence of sentences, divided by lines with the dollar sign.

  First sentence
  $
  Second sentence

Last argument (optional) is an hash table reference with align
options. For example, you can pass a reference to a processing
function to be applied to each sentence in the source or target
corpus:

  use NAT;
  Lingua::NATools->align("EN", "PT", { filter1 => sub{ ... },
                                       filter2 => sub{ ... } });

Note that you can use just one filter.

=head2 Checking translation probability

The C<check_bidirectional_sentence_similarity> function is used to get
a probability of translation between to sentences. The algorithm uses
the probable translations obtained from the word alignment.

First argument is a reference to a configuration hash. Other two, are
the sentences to be compared, in the source and in the target
languages, respectively.

  $prob = NAT::check_bidirectional_sentence_similarity( +{
                              sourceDB => 'dic1.db', targetDB => 'dic2.db',
                              }, "first sentence", "primeira frase");

The line above defines the DB File dictionaries (created with the
createDB tool --- merge_dict_lex function) to be used, and the two
sentences to be compared.

On some cases, it is desirable to ignore small words on sentences. On
that case, you can pass the C<ignore_size> option in the hash, with
the minimum size required to the word to be considered.

On some other cases, you do not want to ignore small words, but some
special ones. On that case, you can define two arrays, named
C<sourceStopWrds> and C<targetStopWrds> with the words to be ignored.

=head2 Loading Dictionary Files

NATools creates files containing a Perl Data Dumper dictionary with
translation probabilities. This function reads it and returns it.

  $dic = NAT::load_dict('dic-ipfp.1.pl');

In some cases it could be usefull to write a DB file with the hash
information. In these cases use:

  NAT::load_dict( { dbfile => 'DB' }, 'dic-ipfp.1.pl')

and the file 'DB' is created. 

=head2 Loading Lexical Files

NATools creates files containing the corpora lexicon. These files are
stored the the created directory, with the name of the corpus file and
extension C<.lex>. While small, these files are gziped binary files,
which are easy to read from C, but sometimes tricky to read from Perl.

So, you can use the C<load_lex> function from this module to do this.
If you use it simply with:

  $lex = NAT::load_lex($file);

it will return an hash reference for the file information, where keys
are the lexicon words. Data is another hash reference with the
following structure:

  { count => word_occurrence, id => word_identifier }

You can use as the first argument to the function a reference to an
hash with configuration options. For example,

  $lex = NAT::load_lex( { id => 1 }, $file )

will return an hash reference where the keys are the word identifiers,
and each data is an hash reference with the structure:

 { count => word_occurrence, word => the_word }

Additionally, you can supply as an option the key C<dbfile> pointing
to a filename. In this case, the structure is returned but the file is
also created with an MLDBM (Storable + DB_File) for the data
structure;

=head2 Merging Dictionary and Lexicon Files

This function is specially useful to create a MLDBM File or a Storable
file with the information of the lexicon and the terminologic
dictionary putted together.

To use it you must supply the dictionary file name (created with one
of the three alignment methods) and the lexicon file. The function
returns a perl structure with the created dictionary.

  $dict = NAT::merge_dict_lex("dict.ipfp.1.pl", "corpus1.lex");

If you want the output on a DB file, use:

  NAT::merge_dict_lex( +{dbfile => "filename.db"},
                       "dict.ipfp.1.pl", "corpus1.lex");

On the same mood, use the following line for Storable output:

  NAT::merge_dict_lex( +{store => "filename.db"},
                       "dict.ipfp.1.pl", "corpus1.lex");

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2014  Alberto Simões

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut

