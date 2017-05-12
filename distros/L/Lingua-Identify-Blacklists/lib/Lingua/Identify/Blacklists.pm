#-*-perl-*-

package Lingua::Identify::Blacklists;

use 5.008;
use strict;

use File::ShareDir qw/dist_dir/;
use File::Basename qw/dirname/;
use File::GetLineMaxLength;

use Lingua::Identify qw(:language_identification);;
use Lingua::Identify::CLD;

use Exporter 'import';
our @EXPORT_OK = qw( identify identify_file identify_stdin 
                     train train_blacklist run_experiment 
                     available_languages available_blacklists );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.04';

=encoding UTF-8

=head1 NAME

Lingua::Identify::Blacklists - Language identification for related languages based on blacklists

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

  use Lingua::Identfy::Blacklists qw/:all/;

  # detect language for a given text 
  # (discriminate between Bosanian, Croatian and Serbian)
  my $lang = identify( ".... text to be classified ...", 
                       langs => ['bs','hr','sr']);

  # check if the assumed language ('hr') is confused with another one
  my $lang = identify( ".... text to be classified ...", assumed => 'hr' );

  # use a general-purpose identfier and check confusable langauges if necessary
  my $lang = identify( ".... text to be classified ...");

  # delect language in the given file (Unicode UTF-8 is assumed)
  my $lang = identify_file( $filename, langs => [...] );
  my $lang = identify_file( $filename, assumed => '..' );
  my $lang = identify_file( $filename );

  # delect language for every line separately from the given file 
  # (return a list of lang-IDs)
  my @langs = identify_file( $filename, every_line => 1, langs = [...] );
  my @langs = identify_file( $filename, every_line => 1, assumed = '..' );
  my @langs = identify_file( $filename, every_line => 1 );


  # learn classifiers (blacklists) for all pairs of languages 
  # given some training data
  train( { cs => $file_with_cs_text,
           sk => $file_with_sk_text,
           pl => $file_with_pl_text } );

  # learn a blacklist from a given pair of texts (prints to STDOUT)
  train_blacklist( $filename1, $filename2 );

  # ... the same but write to outfile
  train_blacklist( $filename1, $filename2, outfile => $outfilename );

  # train and evaluate the classification using given training/test data
  my @traindata = ($trainfile1, $trainfile2, $trainfile3);
  my @evaldata  = ($testfile1, $testfile2, $testfile3);
  run_experiment(\@traindata, \@evaldata, $lang1 $lang2, $lang3);

  # train with different parameters (optional)
  my %para = ( 
      min_high => 5,      # minimal token frequency in one langusgae
      max_low  => 2,      # maximal token frequency in the other language
      min_diff => 0.7 );  # score difference threshold

  train( { cs => $file_with_cs_text, sk => $file_with_sk_text }, %para );

=head1 Description

This module adds a blacklist classifier to a general purpose language identification tool. Related languages can easily be confused with each other and standard language detection tools do not work very well for distinguishing them. With this module one can train so-called blacklists of words for language pairs containing words that should not (or very rarely) occur in one language while being quite common in the other. These blacklists are then used to discriminate between those "confusable" related languages.

Since version 0.03 it also integrates a standard language identifier (Lingua::Identify::CLD) and can now be used for general language identification. It calls the blacklist classifier only for those languages that can be confused and for which appropriate blacklists are trained.


=head1 Settings

Module-internal variables that can be modified:

 $BLACKLISTDIR     # directory with all blacklists (default: module-share-dir)
 $LOWERCASE        # lowercase all data, yes/no (1/0), default: 1
 $TOKENIZE         # tokenize all data, yes/no (1/0), default: 1
 $ALPHA_ONLY       # don't use tokens with non-alphabetic characters, default: 1
 $MAX_LINE_LENGTH  # max line length when reading from files (default=2**16)
 $CLD_TEXT_SIZE    # text size in characters used for language ident. with CLD
 $VERBOSE          # verbose output (default=0)

Tokenization is very simple and replaces all non-alphabetic characters with a white-space character.

=cut


our $BLACKLISTDIR;
eval{ $BLACKLISTDIR = &dist_dir('Lingua-Identify-Blacklists') . '/blacklists' };

our $LOWERCASE       = 1;
our $TOKENIZE        = 1;
our $ALPHA_ONLY      = 1;
our $MAX_LINE_LENGTH = 2**16;    # limit the length of one line to be read
our $CLD_TEXT_SIZE   = 2**16;    # text size used for detecting lang with CLD
our $VERBOSE         = 0;

my %blacklists = ();  # hash of blacklists (langpair => {blacklist}, ...)
my %confusable = ();  # hash of confusable languages (lang => [other_langs])

## the compact language identifier from Google Chrome
my $CLD = new Lingua::Identify::CLD;


# load all blacklists in the gneral BLACKLISTDIR
&load_blacklists( $BLACKLISTDIR );




=head1 Exported Functions

=head2 C<$langID = identify( $text [,%options] )>

Analyses a given text and returns a language ID as the result of the classification. C<%options> can be used to change the behaviour of the classifier. Possible options are

  assumed    => $assumed_lang
  langs      => \@list_of_possible_langs
  use_margin => $score

If C<langs> are specified, it runs the classifier with blacklists for those languages (in a cascaded way, i.e. best1 = lang1 vs lang2, best2 = best1 vs lang3, ...). If C<use_margin> is specified, it runs all versus all and returns the language that wins the most (with margin=$score).

If the C<assumed> language is given, it runs the blacklist classifier for all languages that can be confused with $assumed_lang (if blacklist models exist for them).

If neither C<langs> not C<assumed> are specified, it first runs a general-purpose language identification (using Lingua::Identify::CLD and Lingua::Identify) and then checks with the blacklist classifier whether the detected language can be confused with another one. For example, CLD frequently classifies Serbian and Bosnian texts as Croatian but the blacklist classifier will detect that (and hopefully correct the decision).

=cut

sub identify{
  my $text = shift;
  my %options = @_;

  my %dic = ();
  my $total = 0;

  # run the blacklist classifier if 'langs' are specified
  if (exists $options{langs}){
      &process_string( $text, \%dic, $total, $options{text_size} );
      return &classify( \%dic, %options );
  }

  # otherwise: check if there is an 'assumed' language
  # if not: classify with CLD
  $options{assumed} = &identify_language( $text ) 
      unless (exists $options{assumed});

  # if there is an 'assumed' language:
  # check if it can be confused with others (i.e. blacklists exist)
  if (exists $confusable{$options{assumed}}){
      $options{langs} = $confusable{$options{assumed}};
      # finally: process the text and classify
      &process_string( $text, \%dic, $total );
      return &classify( \%dic, %options );
  }
  return $options{assumed};
}



=head2 C<$langID = identify_file( $filename [,%options] )>

Does the same as C<identify> but reads text from a file. It also takes the same options as the 'identify' function but allows two extra options:

  text_size  => $size,  # number of tokens to be used for classification
  every_line => 1

Using the C<every_line> option, the classifier checks every input line seperately and returns a list of language ID's.

 @langIDs = identify_file( $filename, every_line => 1, %options )

=cut



sub identify_file{
    my $file = shift;
    my %options = @_;
    
    my %dic = ();
    my $total = 0;
    my @predictions = ();
    
    my $fh     = defined $file ? open_file($file) : *STDIN;
    my $reader = File::GetLineMaxLength->new($fh);

    # mode 1: classify every line separately
    if ($options{every_line}){
	my @predictions = ();
	while (my $line = $reader->getline($MAX_LINE_LENGTH)) {
	    chomp $line;
            push( @predictions, &identify( $line, %options ) );
	}
	return @predictions;
    }

    # mode 2: classify all text together (optional: size limit)
    my $text = '';
    while (my $line = $reader->getline($MAX_LINE_LENGTH)) {

	# save text if no languages are given (for blacklists)
	unless (exists $options{langs} || exists $options{assumed}){
	    if ( length($text) < $CLD_TEXT_SIZE ){
		$text .= $line;
	    }
	}

	# prepare the data for blacklist classification
	# (TODO: is this cheaper than keeping the text in memory and
	#        processing it later when needed?)
	chomp $line;
	&process_string($line,\%dic,$total);
	if ($options{text_size}){        # use only a certain number of words
	    if ($total > $options{text_size}){
		print STDERR "use $total tokens for classification\n" 
		    if ($VERBOSE);
		last;
	    }
	}
    }

    # no languages selected?
    unless (exists $options{langs}){
	# no assumed language set
	unless (exists $options{assumed}){
	    # try to identify with the text we have saved above
	    $options{assumed} = &identify_language( $text ) 
		unless (exists $options{assumed});
	}
	if (exists $confusable{$options{assumed}}){
	    $options{langs} = $confusable{$options{assumed}};
	}
    }

    # finally: classify with blacklists
    if (exists $options{langs}){
	return &classify( \%dic, %options );
    }

    # no blacklists in this case ...
    return $options{assumed};
}



=head2 C<$langID = identify_stdin( [,%options] )>

The same as C<identify_file> but reads from STDIN

=cut


sub identify_stdin{
    return identify_file( undef, @_ );
}




=head2 C<train( \%traindata [,%options] )>

Trains classifiers by learning blacklisted words for pairwise language discrimination. Returns nothing. Blacklists are stored in C<Lingua::Identify::Blacklists::BLACKLISTDIR/>. You may have to run the process as administrator if you don't have write permissions.

C<%traindata> is a hash of training data files associated with their corresponding language IDs:

  'hr' => $croatian_text_file,
  'sr' => $serbian_text_file,
  ...

C<%options> is a hash of optional parameters that change the behaviour of the learning algorithm. Possible parameters are:

  min_high => $freq1,      # minimal token frequency in one langusgae
  max_low  => $freq2,      # maximal token frequency in the other language
  min_diff => $score,      # score difference threshold
  text_size => $size,      # maximum number of tokens to be used per text


=cut


sub train{
    my $traindata = shift;
    my %options   = @_;

    my @langs = keys %{$traindata};

    for my $s (0..$#langs){
        for my $t ($s+1..$#langs){
            print "traing blacklist for $langs[$s]-$langs[$t] ... ";
            &train_blacklist( $$traindata{$langs[$s]},$$traindata{$langs[$t]},
		    outfile  => "$BLACKLISTDIR/$langs[$s]-$langs[$t].txt",
		    %options );
            print "saved in '$BLACKLISTDIR/$langs[$s]-$langs[$t].txt'\n";
        }
    }
}


=head2 C<train_blacklist( $file1, $file2, %options )>

This function learns a blacklist of words to discriminate between the language given in $file1 and the language given in $file2. It takes the same arguments (%options) as the C<train> function above with one additional parameter:

 outfile => $output_file

Using this parameter, the blacklist will be written to the specified file. Otherwise it will be printed to STDOUT.

The function returns nothing otherwise.

=cut



sub train_blacklist{
    my ($file1,$file2,%options) = @_;

    my $min_high = exists $options{min_high} ? $options{min_high} : 10;
    my $max_low  = exists $options{min_low}  ? $options{max_low}  : 3;
    my $min_diff = exists $options{min_diff} ? $options{min_diff} : 0.8;

    my %dic1=();
    my %dic2=();

    my $total1 = &read_file($file1,\%dic1,$options{text_size});
    my $total2 = &read_file($file2,\%dic2,$options{text_size});

    if ($options{outfile}){
	mkdir dirname($options{outfile}) unless (-d dirname($options{outfile}));
        open O,">$options{outfile}" || die "cannot write to $options{outfile}\n";
        binmode(O,":encoding(UTF-8)");
    }

    foreach my $w (keys %dic1){
	next if ((!exists $dic1{$w} || $dic1{$w}<$min_high) && 
		 (!exists $dic2{$w} || $dic2{$w}<$min_high));
	next if ((exists $dic1{$w} && $dic1{$w}>$max_low) && 
		 (exists $dic2{$w} && $dic2{$w}>$max_low));

	my $c1 = exists $dic1{$w} ? $dic1{$w} : 0;
	my $c2 = exists $dic2{$w} ? $dic2{$w} : 0;

        my $s1 = $c1 * $total2;
        my $s2 = $c2 * $total1;
        my $diff = ($s1 - $s2) / ($s1 + $s2);

	if (abs($diff) > $min_diff){
            if ($options{outfile}){
                print O "$diff\t$w\t$c1\t$c2\n";
            }
            else{
                print "$diff\t$w\t$c1\t$c2\n";
            }
	}
    }
    # don't forget words that do NOT appear in dic1!!!
    foreach my $w (keys %dic2){
	next if (exists $dic1{$w});
	next if ($dic2{$w}<10);
	my $c1 = exists $dic1{$w} ? $dic1{$w} : 0;
	my $c2 = exists $dic2{$w} ? $dic2{$w} : 0;
        if ($options{outfile}){
            print O "-1\t$w\t$c1\t$c2\n";
        }
        else{
            print "-1\t$w\t$c1\t$c2\n";
        }
    }
    close O if ($options{outfile});
}

=head2 C<@langs = available_languages()>

Returns a list of languages covered by the blacklists in the BLACKLISTDIR.

=cut

sub available_languages{
    unless (keys %blacklists){
	&load_blacklists( $BLACKLISTDIR );
    }
    my %langs = ();
    foreach (keys %blacklists){
	my ($lang1,$lang2) = split(/\-/);
	$langs{$lang1}=1;
	$langs{$lang2}=1;
    }
    return keys %langs;
}


=head2 C<%lists = available_blacklists()>

Resturns a hash of available language pairs (for which blacklists exist in the system).

 %lists = ( srclang1 => { trglang1a => blacklist1a, trglang1b => blacklist1b },
            srclang2 => { trglang2a => blacklist2a, ... }
            .... )

=cut


sub available_blacklists{
    unless (keys %blacklists){
	&load_blacklists( $BLACKLISTDIR );
    }
    my %pairs = ();
    foreach (keys %blacklists){
	my ($lang1,$lang2) = split(/\-/);
	$pairs{$lang1}{$lang2} = $_;
	$pairs{$lang2}{$lang1} = $_ 
	    unless (defined $pairs{$lang2} && defined $pairs{$lang2}{$lang1});
    }
    return %pairs;
}




=head2 C<run_experiment( \@trainfiles, \@testfiles, \%options, @langs )>

This function allows to run experiments, i.e. training and evaluating classifiers for the given languages (C<@langs>). The arrays of training data and test data need to be of the same size as C<@langs>. The function prints the overall accurcy and a confusion table given the data sets and the classification. C<%options> can be used to set classifier-specific parameters.

=cut


sub run_experiment{

    use Benchmark;

    my $trainfiles = shift;
    my $evalfiles = shift;
    my $options = ref($_[0]) eq 'HASH' ? shift : {};

    my @traindata = 
	ref($trainfiles) eq 'ARRAY' ? @{$trainfiles} : split(/\s+/,$trainfiles);
    my @evaldata = 
	ref($evalfiles) eq 'ARRAY' ? @{$evalfiles} : split(/\s+/,$evalfiles);
    my @langs = @_;

    die "no languages given!\n" unless (@langs);
    die "no training nor evaluation data given!\n" 
        unless ($#traindata == $#evaldata || $#traindata == $#langs);

    my %trainset = ();
    for (0..$#langs){ $trainset{$langs[$_]} = $traindata[$_]; }

    # train blacklists

    if ($#traindata == $#langs){
        $BLACKLISTDIR = $$options{blacklist_dir} || "blacklist-experiment";
        my $t1 = new Benchmark;
        &train( \%trainset, %{$options} );
        print STDERR "training took: ". 
	    timestr(timediff(new Benchmark, $t1)).".\n";
    }

    &initialize();

    # classify test data

    if ($#evaldata == $#langs){
        print STDERR "classify ....\n";

        my $correct=0;
        my $count=0;
        my %guesses=();

        my %correct_lang=();
        my %count_lang=();

        my $t1 = new Benchmark;
        foreach my $i (0..$#langs){
            open IN,"<:encoding(UTF-8)",$evaldata[$i] || die "...";
            while (<IN>){
                chomp;
                my %dic = ();
                &process_string($_,\%dic);
                my $guess = &classify(\%dic,@langs);
                $count++;
                $count_lang{$langs[$i]}++;
                if ($guess eq $langs[$i]){
                    $correct++;
                    $correct_lang{$langs[$i]}++;
                }
                $guesses{$langs[$i]}{$guess}++;
            }
            close IN;
        }
        print STDERR "classification took: ".
            timestr(timediff(new Benchmark, $t1)).".\n";

        printf "accuracy: %6.4f\n   ",$correct/$count;
        foreach my $c (@langs){
            print "  $c";
        }
        print "\n";
        foreach my $c (@langs){
            print "$c ";
            foreach my $g (@langs){
                printf "%4d",$guesses{$c}{$g};
            }
            printf "  %6.4f",$correct_lang{$c}/$count_lang{$c};
            print "\n";
        }
    }
    system("wc -l $Lingua::Identify::Blacklists::BLACKLISTDIR/*.txt");
}


=head2 Module-internal functions

The following functions are not exported and are mainly used for internal purposes (but may be used from the outside if needed).

 initialize()                     # reset the repository of blacklists
 identify_language($text)         # return lang-ID for $text (using CLD)
 classify(\%dic,%options)         # run the classifier
 classify_cascaded(\%dic,@langs)  # run a cascade of binary classifications

 # run all versus all and return the one that wins most binary decisions
 # (a score margin is used to adjust the reliability of the decisions)

 classify_with_margin(\%dic,$margin,@langs) 

 load_blacklists($dir)                # load all blacklists available in $dir
 load_blacklist(\%list,$dir,      # load a lang-pair specific blacklist
                $lang1,$lang2)  
 read_file($file,\%dic,$max)      # read a file and count token frequencies
 process_string($string)          # process a given string (lowercasing ...)

=cut


sub initialize{ %blacklists = (); %confusable = (); }

sub identify_language{
    my ($lang, $id, $conf) = $CLD->identify( $_[0] );

    # strangely enough CLD is not really reliable for English
    # (all kinds of garbish input is recognized as English)
    # --> check with Lingua::Identify
    if ($id eq 'en'){
	$id = $id = langof( $_[0] ) ? $id : 'unknown';
    }
    return $id;
}

sub classify{
    my $dic         = shift;
    my %options     = @_;
    $options{langs} = '' unless ($options{langs});

    my @langs = ref($options{langs}) eq 'ARRAY' ? 
	@{$options{langs}} : split( /\s+/, $options{langs} ) ;

    @langs = available_languages() unless (@langs);

    return &classify_with_margin( $dic, $options{use_margin}, @langs ) 
	if ($options{use_margin});
    return &classify_cascaded( $dic, @langs );
}

sub classify_cascaded{
    my $dic = shift;
    my @langs = @_;

    my $lang1 = shift(@langs);
    foreach my $lang2 (@langs){

        # load blacklists on demand
        unless (exists $blacklists{"$lang1-$lang2"}){
            $blacklists{"$lang1-$lang2"}={};
            &load_blacklist($blacklists{"$lang1-$lang2"},
                            $BLACKLISTDIR,$lang1,$lang2);
        }
        my $list = $blacklists{"$lang1-$lang2"};

        my $score = 0;
	foreach my $w (keys %{$dic}){
	    if (exists $$list{$w}){
                $score += $$dic{$w} * $$list{$w};
                print STDERR "$$dic{$w} x $w found ($$list{$w})\n" if ($VERBOSE);
            }
        }
        if ($score < 0){
            $lang1 = $lang2;
        }
        print STDERR "select $lang1 ($score)\n" if ($VERBOSE);
    }
    return $lang1;
}


# OTHER WAY OF CLASSIFYING
# test all against all ...

sub classify_with_margin{
    my $dic = shift;
    my $margin = shift;
    my @langs = @_;

    my %selected = ();
    while (@langs){
        my $lang1 = shift(@langs);
        foreach my $lang2 (@langs){

            # load blacklists on demand
            unless (exists $blacklists{"$lang1-$lang2"}){
                $blacklists{"$lang1-$lang2"}={};
                &load_blacklist($blacklists{"$lang1-$lang2"},
                                $BLACKLISTDIR,$lang1,$lang2);
            }
            my $list = $blacklists{"$lang1-$lang2"};

            my $score = 0;
            foreach my $w (keys %{$dic}){
                if (exists $$list{$w}){
                    $score += $$dic{$w} * $$list{$w};
                    print STDERR "$$dic{$w} x $w found ($$list{$w})\n" 
                        if ($VERBOSE);
                }
            }
            next if (abs($score) < $margin);
            if ($score < 0){
                # $selected{$lang2}-=$score;
                $selected{$lang2}++;
                print STDERR "select $lang2 ($score)\n" if ($VERBOSE);
            }
            else{
                # $selected{$lang1}+=$score;
                $selected{$lang1}++;
                print STDERR "select $lang1 ($score)\n" if ($VERBOSE);
            }
        }
    }
    my ($best) = sort { $selected{$b} <=> $selected{$a} } keys %selected;
    return $best;
}


# load_all_blacklists = alias for load_blacklists

sub load_all_blacklists{ return load_blacklists(@_); }

sub load_blacklists{
    my $dir = shift || $BLACKLISTDIR;

    opendir(my $dh, $dir) || die "cannot read directory '$dir'\n";
    while(readdir $dh) {
	if (/^(.*)-(.*).txt$/){
	    $blacklists{"$1-$2"}={};
	    &load_blacklist($blacklists{"$1-$2"}, $dir, $1, $2);
	}
    }
    closedir $dh;

    # update list of confusable languages
    my %lists = &available_blacklists();
    foreach my $lang (keys %lists){
	@{$confusable{$lang}} = keys %{$lists{$lang}};
	unshift( @{$confusable{$lang}}, $lang );
    }
}


sub load_blacklist{
    my ($list,$dir,$lang1,$lang2) = @_;

    my $inverse = 0;
    if (! -e "$dir/$lang1-$lang2.txt"){
	($lang1,$lang2) = ($lang2,$lang1);
        $inverse = 1;
    }

    open F,"<:encoding(UTF-8)","$dir/$lang1-$lang2.txt" || die "...";
    while (<F>){
	chomp;
	my ($score,$word) = split(/\t/);
        $$list{$word} = $inverse ? 0-$score : $score;
    }
    close F;
}

sub open_file{
    my $file = shift;
    # allow gzipped input
    my $fh;
    if ($file=~/\.gz$/){
	open $fh,"gzip -cd < $file |" || die "cannot open file '$file'";
	binmode($fh,":encoding(UTF-8)");
    }
    else{
	open $fh,"<:encoding(UTF-8)",$file || die "cannot open file '$file'";
    }
    return $fh;
}

sub read_file{
    my ($file,$dic,$max)=@_;

    # use File::GetLineMaxLength to avoid filling the memory
    # when reading from files without new lines
    my $fh     = open_file( $file );
    my $reader = File::GetLineMaxLength->new($fh);

    my $total = 0;
    while (my $line = $reader->getline($MAX_LINE_LENGTH)) {
	chomp $line;
        &process_string($line,$dic,$total);
        if ($max){
            if ($total > $max){
                print STDERR "read $total tokens from $file\n";
                last;
            }
        }
    }
    close $fh;
    return $total;
}


# process_string($string,\%dic,\$wordcount[,$maxwords])

sub process_string{
    $_[0]=lc($_[0]) if ($LOWERCASE);
    $_[0]=~s/((\A|\s)\P{IsAlpha}+|\P{IsAlpha}+(\s|\Z))/ /gs if ($TOKENIZE);

    my @words = $ALPHA_ONLY ? 
        grep(/^\p{IsAlpha}/,split(/\s+/,$_[0])) :
        split(/\s+/,$_[0]);

    # use only $maxwords words
    splice(@words,$_[3]) if ($_[3]);

    foreach my $w (@words){${$_[1]}{$w}++;$_[2]++;}
}

1;

__END__


=head1 AUTHOR

Jörg Tiedemann, L<https://bitbucket.org/tiedemann>

=head1 BUGS

Please report any bugs or feature requests to
L<https://bitbucket.org/tiedemann/blacklist-classifier>.  I will be notified,
and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Identify::Blacklists

=head1 SEE ALSO

This module is designed for the discrimination between closely related languages. For general-purpose language identification look at L<Lingua::Identify>, L<Lingua::Identify::CLD> and L<Lingua::Ident>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jörg Tiedemann.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
