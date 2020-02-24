package Lingua::Jspell;

use warnings;
use strict;

use 5.008001;

use POSIX qw(locale_h);
setlocale(LC_CTYPE, "pt_PT");
use locale;

use base 'Exporter';
our @EXPORT_OK = (qw.onethat verif nlgrep setstopwords
                     onethatverif any2str hash2str isguess.);

our %EXPORT_TAGS = (basic => [qw.onethat verif onethatverif
                                 any2str hash2str isguess.],
                    greps => [qw.nlgrep setstopwords.]);
# use Data::Dumper;
use File::Spec::Functions;
use Lingua::Jspell::ConfigData;
use Lingua::Jspell::EAGLES;
use IPC::Open3;
use YAML qw/LoadFile/;
use Data::Compare;

=head1 NAME

=encoding utf8

Lingua::Jspell - Perl interface to the Jspell morphological analyser.

=cut

our $VERSION = '1.94';
our $JSPELL;
our $JSPELLLIB;
our $MODE = { nm => "af", flags => 0 };
our $DELIM = '===';
our %STOP =();

BEGIN {
    delete @ENV{qw(IFS CD PATH ENV BASH_ENV)};  # Make %ENV safer

    my $EXE = "";
    if ($^O eq "MSWin32") {
      $ENV{PATH} = "blib\\usrlib";
      $EXE=".exe" ;

      my $dllpath = Lingua::Jspell::ConfigData->config("libdir");
      $ENV{PATH} = join(";", $dllpath, $ENV{PATH});
    }

    local $_;

    $JSPELL = catfile("blib","bin","jspell$EXE");
    $JSPELL = Lingua::Jspell::ConfigData->config("jspell") unless -x $JSPELL;

    die "jspell binary cannot be found!\n" unless -x $JSPELL;

    local $.;
    open X, "$JSPELL -vv|" or die "Can't execute $JSPELL";
    while (<X>) {
        if (/LIBDIR = "([^"]+)"/) {
            $JSPELLLIB = $1;
        }
    }
    close X;
    die "Can't find out jspell lib dir" unless $JSPELLLIB;
}

=head1 SYNOPSIS

    use Lingua::Jspell;

    my $dict = Lingua::Jspell->new( "dict_name");
    my $dict = Lingua::Jspell->new( "dict_name" , "personal_dict_name");

    $dict->rad("gatinho");      # list of radicals (gato)

    $dict->fea("gatinho");      # list of possible analysis

    $dict->der("gato");         # list of derivated words

    $dict->flags("gato");       # list of roots and flags

=head1 FUNCTIONS


=head2 new

Use to open a dictionary. Pass it the dictionary name and optionally a
personal dictionary name. A new jspell dictionary object will be
returned.

=cut

sub new {
  my ($self, $dr, $pers, $flag);
  local $/="\n";
  my $class = shift;

  $self->{dictionary}  = shift;
  $self->{pdictionary} = shift ||
    (defined($ENV{HOME})?"$ENV{HOME}/.jspell.$self->{dictionary}":"");

  $pers = $self->{pdictionary}?"-p $self->{pdictionary}":"";
  $flag = defined($self->{'undef'})?$self->{'undef'}:"-y";

  ## Get yaml info ----------------------------------
  my $yaml_file = _yaml_file($self->{dictionary});
  if (-f $yaml_file) {
      $self->{yaml} = LoadFile($yaml_file);
  } else {
      $self->{yaml} = {};
  }


  my $js = "$JSPELL -d $self->{dictionary} -a $pers -W 0 $flag -o'%s!%s:%s:%s:%s'";
  local $.;
  $self->{pid} = open3($self->{DW},$self->{DR},$self->{DE},$js) or die $!;
		
  binmode($self->{DW},":encoding(iso-8859-1)");
  if ($^O ne "MSWin32") {
      binmode($self->{DR},":encoding(iso-8859-1)");
  }
  else {
      binmode($self->{DR},":crlf:encoding(iso-8859-1)");
  }
  $dr = $self->{DR};
  my $first_line = <$dr>;
  die "Can't execute jspell with supplied dictionaries ($js)" unless $first_line && $first_line =~ /International Jspell/;

  $self->{mode} ||= $MODE;
  my $dw = $self->{DW};
  print $dw _mode($self->{mode});

  if ($first_line  =~ /Jspell/) {
      return bless $self, $class # amen
  }
  else {
      return undef
  }
}

=head2 nearmatches

This method returns a list of analysis for words that are near-matches
to the supplied word. Note that although a word might exist, this
method will compute the near-matches as well.

  @nearmatches = $dictionary->nearmatches('cavale');

To compute the list of words to analyze, the method uses a list of
equivalence classes that are present on the C<< SNDCLASSES >> section
of dictionaries yaml files.

It is also possible to specify a list of user-defined classes. These
are supplied as a filename that contains, per line, the characters
that are equivalent (with spaces separating them):

   ch   x
   ss   ç

This example says that if a word uses C<ch>, then it can be replaced
by C<x> for near-matches calculation. The inverse is also true.

If these rules are stored in a file named C<classes.txt>, you can
supply this list with:

  @nearmatches = $dictionary->nearmatches('chaile', rules => 'classes.txt');

=cut

sub nearmatches {
    my ($dict, $word, %ops) = @_;
    my %classes;
    if ($ops{rules}) {
        -f $ops{rules} or die "Can't find file $ops{rules}";
        local $.;
        open RULES, $ops{rules} or die "Can't open file $ops{rules}";
        my @rules;
        while(<RULES>) {
            chomp;
            push @rules, [split /\s+/];
        }
        close RULES;
        %classes = _expand_classes(@rules);
    } else {
        if (exists($dict->{yaml}{META}{SNDCLASSES})) {
            %classes = _expand_classes(@{ $dict->{yaml}{META}{SNDCLASSES} });
        } else {
            warn "No snd classes defined\n";
        }
    }

    my @words = ();
    for my $c (keys %classes) {
        my @where;
        my $l = length($c);
        push @where, pos($word)-$l while $word =~ /$c/g;
        for my $i (@where) {
            my $o = $word;
            substr($o,$i,length($c), $classes{$c});
            push @words, $o if $o ne $word;
        }
    }

    my $current_mode = $dict->setmode;
    $dict->setmode({flags => 0, nm => "cc" });

    my @nms;
    for my $w (@words) {
        my @analysis = map { $_->{guess}||=$w; $_ } $dict->fea($w);
        push @nms, @analysis;
    }

    @nms = grep { $_->{guess} ne $word } @nms;
    # This one is not a guess
    push @nms, $dict->fea($word);

    @nms = _remove_dups(@nms);

    $dict->setmode($current_mode);
    return @nms;
}

sub _remove_dups {
    my @new;
    while (my $struct = shift @_) {
        push @new, $struct unless grep { Compare($_,$struct) } @new;
    }
    @new;
}

sub _expand_classes { map { _expand_class($_) } @_ }

sub _expand_class {
    my @class = @{ $_[0] };
    my %subs;
    for my $c (@class) {
        my @other = grep { $_ ne $c } @class;
        for (@other) {
            $subs{$c} = $_;
        }
    }
    %subs
}

=head2 setmode

   $dict->setmode({flags => 0, nm => "off" });

=over 4

=item af

(add flags) Enable parcial near misses, by using rules not officially
associated with the current word.  Does not give suggestions by
changing letters on the original word.  (default option)

=item full

(add flags and change characters) Enable near misses, try to use rules
where they are not applied, try to give suggestions by swapping
adjacent letters on the original word.

=item cc

(change characters) Enable parcial near misses, by swapping adjacent,
inserting or modifying letters on the original word.  Does not use
rules not associated with the current word.

=item off

Disable near misses at all.

=back

=cut

sub setmode {
  my ($self, $mode) = @_;

  my $dw = $self->{DW};
  if (defined($mode)) {
    $self->{mode} = $mode;
    print $dw _mode($mode);
  } else {
    return $self->{mode};
  }
}

=head2 fea

Returns a list of analisys of a word. Each analisys is a list of
attribute value pairs. Attributes available: CAT, T, G, N, P, ....

  @l = $dic->fea($word)
  @l = $dic->fea($word,{...att. value pair restriction})

If a restriction is provided, just the analisys that verify 
it are returned.

=cut


sub fea {
    my ( $self, $w, $res ) = @_;

    local $/ = "\n";

    my @r = ();
    my ( $a, $rad, $cla, $flags );

    if ( $w =~ /\!/ ) {
        @r = ( +{ CAT => 'punct', rad => '!' } );
    }
    else {
        my ( $dw, $dr ) = ( $self->{DW}, $self->{DR} );

        local $.;

        print $dw " $w\n";
        $a = <$dr>;

        for ( ; ( $a ne "\n" ); $a = <$dr> ) {    # l^e as respostas
            for ($a) {
                chop;
                my ( $lixo, $clas );
                if   (/(.*?) :(.*)/) { $clas = $2; $lixo = $1 }
                else                 { $clas = $_; $lixo = "" }

                for ( split( /[,;] /, $clas ) ) {
                    ( $rad, $cla ) = m{(.+?)\!:*(.*)$};

                    # $cla undef quando nada preenchido...

                    if ($cla) {
                        if   ( $cla =~ s/\/(.*)$// ) { $flags = $1 }
                        else                         { $flags = "" }

                        $cla =~ s/:+$//g;
                        $cla =~ s/:+/,/g;

                        my %ana = ();
                        my @attrs = split /,/, $cla;
                        for (@attrs) {
                            if (m!=!) {
                                $ana{$`} = $';
                            }
                            else {
                                print STDERR
                                    "** WARNING: Feature-structure parse error: $cla (for word '$w')\n";
                            }
                        }

                        $ana{"flags"} = $flags if $flags;

                        if ( $lixo =~ /^&/ ) {
                            $rad =~ s/(.*?)= //;
                            $ana{"guess"}   = lc($1);
                            $ana{"unknown"} = 1;
                        }
                        if ( $rad ne "" ) {
                            push( @r, +{ "rad" => $rad, %ana } );
                        }
                    }
                    else {
                        @r = ( +{ CAT => "?", rad => $rad } );
                    }
                }
            }
        }
    }
    if ($res) {
        return ( grep { verif( $res, $_ ) } @r );
    }
    else { return @r; }
}

=head2 flags

returns the set of morphological flag associated with the word.
Each flag is related with a set of morphological rules.

 @f = flags("gato")

=cut

sub flags {
  my $self = shift;
  my $w = shift;
  my ($a,$dr);
  local $/="\n";

  local $.;

  print {$self->{DW}} "\$\"$w\n";
  $dr = $self->{DR};
  $a = <$dr>;

  chop $a;
  return split(/[# ,]+/,$a);
}

=head2 rad

Returns the list of all possible radicals/lemmas for the supplied word.

  @l = $dic->rad($word)

=cut

sub rad {
  my $self = shift;
  my $word = shift;

  return () if $word =~ /\!/;

  my %rad = ();
  my $a_ = "";
  local $/ = "\n";
  local $.;
  
  my ($dw,$dr) = ($self->{DW},$self->{DR});

  print $dw " $word\n";

  
  for ($a_ = <$dr>; $a_ ne "\n"; $a_ = <$dr>) {
    chop $a_;
    %rad = ($a_ =~ m/(?: |:)([^ =:,!]+)(\!)/g ) ;
  }

  return (keys %rad);
}


=head2 der

Returns the list of all possible words using the word as radical.

  @l = $dic->der($word);

=cut

sub der {
    my ($self, $w) = @_;
    my @der = $self->flags($w);
    my %res = ();
    my $command;

    local $/ = "\n";
    local $.;
    my $pid = open3(\*WR, \*RD, \*ERROR, "$JSPELL -d $self->{dictionary} -e -o \"\"") or die "Can't execute jspell.";
    print WR join("\n",@der),"\n";
    print WR "\032" if ($^O =~ /win32/i);
    close WR;
    while (<RD>) {
        chomp;
        s/(=|, | $)//g;
        for(split) { $res{$_}++; }
    }
    close RD;
    close ERROR;
    waitpid $pid, 0;
	
    my $irrcomm;
    my $irr_file = _irr_file($self->{dictionary});

    local $.;
    if (open IRR, $irr_file) {
        while (<IRR>) {
            next unless /^\Q$w\E=/;
            chomp;
            for (split(/[= ]+/,$_)) { $res{$_}++; }
        }
        close IRR;
    }
    return keys %res;
}

=head2 onethat

Returns the first Feature Structure from the supplied list that
verifies the Feature Structure Pattern used.

  %analysis = onethat( { CAT=>'adj' }, @features);

  %analysis = onethat( { CAT=>'adj' }, $pt->fea("espanhol"));

=cut

sub onethat {
    my ($a, @b) = @_;
    for (@b) {
        return %$_ if verif($a,$_);
    }
    return () ;
}

=head2 verif

Returns a true value if the second Feature Structure verifies the
first Feature Structure Pattern.

   if (verif( $pattern, $feature) )  { ... }

=cut

sub verif {
    my ($a, $b) = @_;
    for (keys %$a) {
        return 0 if (!defined($b->{$_}) || $a->{$_} ne $b->{$_});
    }
    return 1;
}

=head2 nlgrep

  @line = $d->nlgrep( word , files);
  @line = $d->nlgrep( [word1, wordn] , files);

or with options to set a max number of entries, rec. separator, or tu use
radtxt files format.

  @line = $d->nlgrep( {max=>100, sep => "\n", radtxt=>0} , pattern , files);

=cut

sub nlgrep {
  my ($self ) = shift;
  # max=int, sep:str, radtxt:bool
  my %opt = (max=>10000, sep => "\n",radtxt=>0);
  %opt = (%opt,%{shift(@_)}) if ref($_[0]) eq "HASH";

  my $p = shift;

  if(!ref($p) && $p =~ /[ ()*,]/){ 
     $p = [map {/\w/ ? ($_):()} split(/[\- ()*\|,]/,$a)];}

  my $p2 ;

  if(ref($p) eq "ARRAY"){
    if($opt{radtxt}){
      my @pat =  @$p ;
      $p2 = sub{ my $x=shift; 
                 for(@pat){ return 0 unless $x =~ /\b(?:$_)\b/i;}
                 return 1; };
    }
    else {
      my @pat =  map {join("|",($_,$self->der($_)))} @$p ;
      $p2 = sub{ my $x=shift; 
                 for(@pat){ return 0 unless $x =~ /\b(?:$_)\b/i;}
                 return 1; }
    }
  }
  else {
    my $pattern = $opt{radtxt} ? $p : join("|",($p,$self->der($p)));
    $p2 = sub{ $_[0] =~ /\b(?:$pattern)\b/i };
  }

  my @file_list=@_;
  local $/=$opt{sep};

  my @res=();
  my $n = 0;
  for(@file_list) {
    local $.;
    open(F,$_) or die("cant open $_\n");
    while(<F>) {
      if ($p2->($_)) {
        chomp;
        s/$DELIM.*//g if $opt{radtxt};
        push(@res,$_);
        last if $n++ == $opt{max};
      }
    }
    close F;
    last if $n == $opt{max};
  }
  return @res;
}

=head2 setstopwords

=cut

sub setstopwords {
    $STOP{$_} = 1 for @_;
}

=head2 eagles 

=cut
sub eagles {
  my ($dict, $palavra, @ar) = @_;

  map {
    my $fea = $_;
    map { $_ . ":$fea->{rad}" } Lingua::Jspell::EAGLES::_cat2eagles(%$fea)
  } $dict->fea($palavra, @ar);
}

# NOTA: Esta funcao é específica da língua TUGA!
sub _cat2small {
  my %b = @_;
  #  no warnings;

  $b{CAT} ||= "HEY!";
  $b{G}   ||= "";
  $b{N}   ||= "";
  $b{P}   ||= "";
  $b{T}   ||= "";

  if ($b{CAT} eq 'art') {
    # Artigos: o léxico já prevê todos...
    # por isso, NUNCA SE DEVE CHEGAR AQUI!!!
    return "ART";
    # 16 tags

  } elsif ($b{CAT} eq 'card') {
    # Numerais cardinais:
    return "DNCNP";
    # o léxico já prevê os que flectem (1 e 2); o resto é tudo neutro plural.

  } elsif ($b{CAT} eq 'nord') {
    # Numerais ordinais:
    return "\UDNO$b{G}$b{N}";

  } elsif ($b{CAT} eq 'ppes' || $b{CAT} eq 'prel' ||
           $b{CAT} eq 'ppos' || $b{CAT} eq 'pdem' ||
           $b{CAT} eq 'pind' || $b{CAT} eq 'pint') {
    # Pronomes:
    if ($b{CAT} eq 'ppes') {
      # Pronomes pessoais
      $b{CAT} = 'PS';
    } elsif ($b{CAT} eq 'prel') {
      # Pronomes relativos
      $b{CAT} = 'PR';
    } elsif ($b{CAT} eq 'ppos') {
      # Pronomes possessivos
      $b{CAT} = 'PP';
    } elsif ($b{CAT} eq 'pdem') {
      # Pronomes demonstrativos
      $b{CAT} = 'PD';
    } elsif ($b{CAT} eq 'pint') {
      # Pronomes interrogativos
      $b{CAT} = 'PI';
    } elsif ($b{CAT} eq 'pind') {
      # Pronomes indefinidos
      $b{CAT} = 'PF';
    }

    $b{G} = 'N' if $b{G} eq '_';
    $b{N} = 'N' if $b{N} eq '_';

    # $b{C} esta por inicializar... oops!? vou por como C para já
    $b{C} = "C";
    return "\U$b{CAT}$b{'C'}$b{G}$b{'P'}$b{N}";
    #                        $b{'C'}: caso latino.

  } elsif ($b{CAT} eq 'nc') {
    # Nomes comuns:
    $b{G} = 'N' if $b{G} eq '_' || $b{G} eq '';
    $b{N} = 'N' if $b{N} eq '_' || $b{N} eq '';
    $b{GR} ||= '' ;
    $b{GR}= 'd' if $b{GR} eq 'dim';
    return "\U$b{CAT}$b{G}$b{N}$b{GR}";

  } elsif ($b{CAT} eq 'np') {
    # Nomes próprios:
    $b{G} = 'N' if $b{G} eq '_' || $b{G} eq '';
    $b{N} = 'N' if $b{N} eq '_' || $b{N} eq '';
    return "\U$b{CAT}$b{G}$b{N}";

  } elsif ($b{CAT} eq 'adj') {
    # Adjectivos:
    $b{G} = 'N' if $b{G} eq '_';
    $b{G} = 'N' if $b{G} eq '2';
    $b{N} = 'N' if $b{N} eq '_';
    $b{GR} ||= '' ;
  	$b{GR} = 'd' if $b{GR} eq 'dim';
    #    elsif ($b{N} eq ''){
    #      $b{N} = 'N';
    #    }
    return "\UJ$b{G}$b{N}$b{GR}";

  } elsif ($b{CAT} eq 'a_nc') {
    # Adjectivos que podem funcionar como nomes comuns:
    $b{G} = 'N' if $b{G} eq '_';
    $b{G} = 'N' if $b{G} eq '2';
    $b{N} = 'N' if $b{N} eq '_';
    $b{GR} ||= '' ;
	  $b{GR} = 'd' if $b{GR} eq 'dim';
    #    elsif ($b{N} eq ''){
    #      $b{N} = 'N';
    #    }
    return "\UX$b{G}$b{N}$b{GR}";

  } elsif ($b{CAT} eq 'v') {
    # Verbos:

    # formas nominais:
    if ($b{T} eq 'inf') {
      # infinitivo impessoal
      $b{T} = 'N';

    } elsif ($b{T} eq 'ppa') {
      # Particípio Passado
      $b{T} = 'PP';

    } elsif ($b{T} eq 'g') {
      # Gerúndio
      $b{T} = 'G';

    } elsif ($b{T} eq 'p') {
      # modo indicativo: presente (Hoje)
      $b{T} = 'IH';

    } elsif ($b{T} eq 'pp') {
      # modo indicativo: pretérito Perfeito
      $b{T} = 'IP';

    } elsif ($b{T} eq 'pi') {
      # modo indicativo: pretérito Imperfeito
      $b{T} = 'II';

    } elsif ($b{T} eq 'pmp') {
      # modo indicativo: pretérito Mais-que-perfeito
      $b{T} = 'IM';

    } elsif ($b{T} eq 'f') {
      # modo indicativo: Futuro
      $b{T} = 'IF';

    } elsif ($b{T} eq 'pc') {
      # modo conjuntivo (Se): presente (Hoje)
      $b{T} = 'SH';

    } elsif ($b{T} eq 'pic') {
      # modo conjuntivo (Se): pretérito Imperfeito
      $b{T} = 'SI';

    } elsif ($b{T} eq 'fc') {
      # modo conjuntivo (Se): Futuro
      $b{T} = 'PI';

    } elsif ($b{T} eq 'i') {
      # modo Imperativo: presente (Hoje)
      $b{T} = 'MH';

    } elsif ($b{T} eq 'c') {
      # modo Condicional: presente (Hoje)
      $b{T} = 'CH';

    } elsif ($b{T} eq 'ip') {
      # modo Infinitivo (Pessoal ou Presente): 
      $b{T} = 'PI';

      # Futuro conjuntivo? Só se tiver um "se" antes! -> regras sintácticas...
      # modo&tempo não previstos ainda...

    } else {
      $b{T} = '_UNKNOWN';
    }

    # converter 'P=1_3' em 'P=_': provisório(?)!
    $b{P} = "";
    $b{P} = '_' if $b{P} eq '1_3'; # único sítio com '_' como rhs!!!

     
    if ($b{T} eq "vpp") { return "\U$b{CAT}$b{T}$b{G}$b{P}$b{N}"; }
    else                { return "\U$b{CAT}$b{T}$b{P}$b{N}";      }


    #                               Género, só para VPP.
    # +/- 70 tags

  } elsif ($b{CAT} eq 'prep') {
    # Preposições¹:
    return "\UP";

  } elsif ($b{CAT} eq 'adv') {
    # Advérbios²:
    return "\UADV";

  } elsif ($b{CAT} eq 'con') {
    # Conjunções²:
    return "\UC";

  } elsif ($b{CAT} eq 'in') {
    # Interjeições¹:
    return "\UI";

    # ¹: não sei se a tag devia ser tão atómica, mas para já não há confusão!

  } elsif ($b{CAT} =~ m/^cp(.*)/) {
    # Contracções¹:
    $b{G} = 'N' if $b{G} eq '_';
    $b{N} = 'N' if $b{N} eq '_';
    return "\U&$b{G}$b{N}";

    # ²: falta estruturar estes no próprio dicionário...
    # Palavras do dicionário com categoria vazia ou sem categoria,
    # palavras não existentes ou sequências aleatórias de caracteres:

  } elsif (defined($b{CAT}) && $b{CAT} eq '') {
    return "\UUNDEFINED";

  } else {   # restantes categorias (...?)
    return "\UUNTREATED";
  }
}

=head2 new_featags

=cut

sub new_featags {
    my ($self, $word) = @_;
    if (exists($self->{yaml}{META}{TAG})) {
        my $rules = $self->{yaml}{META}{TAG};
        return map { $self->_compact($rules, $_) } $self->fea($word);
    } else {
        warn "Dictionary without a YAML file, or without rules for fea-compression\n";
        return undef;
    }
}

sub _compact {
    my ($self,$rules, $fs) = @_;
    my $tag;
    if (ref($rules) eq "HASH") {
        my ($key) = (%$rules);

        if (exists($fs->{$key})) {
            $tag = $self->_compact_id($key, $fs->{$key});
            if (exists($rules->{$key}{$fs->{$key}})) {
                $tag.$self->_compact($rules->{$key}{$fs->{$key}}, $fs);
            }
            elsif (exists($rules->{$key}{'-'})) {
                $tag.$self->_compact($rules->{$key}{'-'}, $fs);
            }
            else {
                $tag
            }
        }
        else {
            ""
        }
    }
    elsif (ref($rules) eq "ARRAY") {
        for my $cat (@$rules) {
            $tag .= $self->_compact($cat, $fs);
        }
        $tag
    }
    elsif (!ref($rules)) {
        if ($rules && exists($fs->{$rules})) {
            $self->_compact_id($rules, $fs->{$rules})
        } else {
            ""
        }
    }
}

sub _compact_id {
    my ($self, $cat, $id) = @_;
    if (exists($self->{yaml}{"$cat-TAG"}{$id})) {
        return $self->{yaml}{"$cat-TAG"}{$id}
    } else {
        return $id
    }
}


=head2 featags

Given a word, returns a set of analysis. Each analysis is a morphosintatic tag

 @l= $pt->featags("lindas") 
   JFS , ...
 @l= $pt->featags("era",{CAT=>"v"})   ## with a constraint


=cut

sub featags{
  my ($self, $palavra,@Ar) = @_;
  return (map {_cat2small(%$_)} ($self->fea($palavra,@Ar)));
}

=head2 featagsrad

Given a word, returns a set of analysis. Each analysis is a morphosintatic tag
and the lemma information

 @l= $pt->featagsrad("lindas") 
   JFS:lindo , ...
 @l= $pt->featagsrad("era",{CAT=>"v"})   ## with a constraint

=cut

sub featagsrad{
  my ($self, $palavra,@Ar) = @_;

  return (map {_cat2small(%$_).":$_->{rad}"} ($self->fea($palavra,@Ar)));
}


=head2 onethatverif

Given a pattern feature structure and a list of analysis (feature
structures), returns a true value is there is one analysis that
verifies the pattern.

 # onethatverif( cond:fs , conj:fs-set) :: bool
 #     exists x in conj: verif(cond , x)

 if(onethatverif({CAT=>"adj"},$pt->fea("linda"))) {
    ...
 }

=cut

sub onethatverif {
  my ($a, @b) = @_;
  for (@b) {
    return 1 if verif($a,$_);
  }
  return 0 ;
}

=head2 mkradtxt

=cut

sub mkradtxt {
  my ($self, $f1, $f2) = @_;
  local $.;
  open F1, $f1 or die "Can't open '$f1'\n";
  open F2, "> $f2" or die "Can't create '$f2'\n";
  while(<F1>) {
    chomp;
    print F2 "$_$DELIM";
    while (/((\w|-)+)/g) {
      print F2 " ",join(" ",$self->rad($1)) unless $STOP{$1}
    }
    print F2 "\n";
  }
  close F1;
  close F2;
}

=head2 isguess

 Lingua::Jspell::isguess(@ana)

returns True if list of analisys are near 
misses (unknown attribut is 1).

=cut

sub isguess{
 my @a=@_;
 return @a &&  $a[0]{unknown}; 
}

=head2 any2str

 Lingua::Jspell::any2str($ref)
 Lingua::Jspell::any2str($ref,$indentation)
 Lingua::Jspell::any2str($ref,"compact")

=cut

sub any2str {
  my ($r, $i) = @_;
  $i ||= 0;
  if (not $r) {return ""}
  if (ref $i) { any2str([@_]);}
  elsif ($i eq "compact") {
    if (ref($r) eq "HASH") {
      return "{". hash2str($r,$i) . "}"
    } elsif (ref($r) eq "ARRAY") {
      return "[" . join(",", map (any2str($_,$i), @$r)) . "]" 
    } else {
      return "$r"
    }
  } elsif ($i eq "f1") {
    if (ref($r) eq "HASH") {
      return "{". hash2str($r,"f1") . "}"
    } elsif (ref($r) eq "ARRAY") {
      return "[ " . join("  ,\n  ", map (any2str($_,"compact"), @$r)) . "]" 
    } else {
      return "$r"
    }
  } else {
    my $ind = ($i >= 0)? (" " x $i) : "";
    if (ref($r) eq "HASH") {
      return "$ind {". hash2str($r,abs($i)+3) . "}"
    } elsif (ref($r) eq "ARRAY") {
      return "$ind [\n" . join("\n", map (any2str($_,abs($i)+3), @$r)) . "]"
    } else {
      return "$ind$r"
    }
  }
}

=head2 hash2str

=cut

sub hash2str {
  my ($r, $i) = @_;
  my $c = "";
  if ($i eq "compact") {
    for (keys %$r) {
      $c .= any2str($_,$i). "=". any2str($r->{$_},$i). ",";
    }
    chop($c);
  } elsif ($i eq "f1") {
    for (keys %$r) {
      $c .= "\n  ", any2str($_,"compact"). "=". any2str($r->{$_},"compact"). "\n";
    }
    chop($c);
  } else {
    for (keys %$r) {
      $c .= "\n". any2str($_,$i). " => ". any2str($r->{$_},-$i);
    }
  }
  return $c;
}

=head1 AUTHOR

Jose Joao Almeida, C<< <jj@di.uminho.pt> >>
Alberto Simões, C<< <ambs@di.uminho.pt> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lingua-jspell@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Jspell>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Projecto Natura

This program is free software; licensed under GPL.

=cut

sub _yaml_file {
  my $dic_file = shift;
  if ($dic_file =~ m!\.hash$!) {
    # we have a local dictionary
    $dic_file =~ s/\.hash/.yaml/;
  } else {
    $dic_file = "$JSPELLLIB/$dic_file.yaml"
  }
  return $dic_file;
}

sub _mode {
    my $m = shift;
    my $r="";
    if ($m->{nm}) {
        if ($m->{nm} eq "af")              ### af = GPy --> Gym
          { $r .= "\$G\n\$m\n\$y\n" }
        elsif ($m->{nm} eq "full")         ### full = GYm
          { $r .= "\$G\n\$Y\n\$m\n" }
        elsif ($m->{nm} eq "cc")           ### cc = GPY
          { $r .= "\$G\n\$P\n\$Y\n" }
        elsif ($m->{nm} eq "off")          ### off = gPy
          { $r .= "\$g\n\$P\n\$y\n" }
        else {}
    }
    if ($m->{flags})          {$r .= "\$z\n"}
    else                      {$r .= "\$Z\n"}
    return $r;
}


sub _irr_file {
  my $irr_file = shift;
  if ($irr_file =~ m!\.hash$!) {
    # we have a local dictionary
    $irr_file =~ s/\.hash/.irr/;
  } else {
    $irr_file = "$JSPELLLIB/$irr_file.irr"
  }
  return $irr_file;
}




'\o/ yay!'; # End of Lingua::Jspell

__END__
