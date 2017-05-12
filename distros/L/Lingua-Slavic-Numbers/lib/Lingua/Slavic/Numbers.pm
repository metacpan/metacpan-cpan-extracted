package Lingua::Slavic::Numbers;
use strict;

use Carp qw(carp);
use List::Util qw(max);
use Data::Dumper;
use Regexp::Common qw /number/;
use Exporter;
use utf8;
use vars qw( $VERSION $DEBUG @ISA @EXPORT_OK @EXPORT);
use vars qw(
	    %INFLEXIONS
	    %NUMBER_NAMES
	    %ORDINALS
	    $OUTPUT_DECIMAL_DELIMITER
	    $MINUS
	  );

use constant LANG_BG => 'bg';

use constant NO_CONJUNCTIONS => 'noconj';
use constant FEMININE_GENDER => 'fem';
use constant MASCULINE_GENDER => 'man';
use constant NEUTRAL_GENDER => 'neu';
 
$VERSION                  = 0.03;
$DEBUG                    = 0;
@ISA                      = qw(Exporter);
@EXPORT_OK                = qw( &number_to_slavic &ordinate_to_slavic LANG_BG);
@EXPORT = @EXPORT_OK;

$MINUS = ('минус');
$OUTPUT_DECIMAL_DELIMITER = ('цяло');

%INFLEXIONS =
(
 LANG_BG,
 {
  FEMININE_GENDER,
  {
   1    => 'една',
  },
  MASCULINE_GENDER,
  {
   1    => 'един',
   2    => 'два',
  },
 }
);

%NUMBER_NAMES =
 (
  LANG_BG,
  {
   0    => 'нула',
   1    => 'едно',
   2    => 'две',
   3    => 'три',
   4    => 'четири',
   5    => 'пет',
   6    => 'шест',
   7    => 'седем',
   8    => 'осем',
   9    => 'девет',
   10   => 'десет',
   11   => 'едина{10}',
   12   => 'двана{10}',
   13   => '{3}на{10}',
   14   => '{4}на{10}',
   15   => '{5}на{10}',
   16   => '{6}на{10}',
   17   => '{7}на{10}',
   18   => '{8}на{10}',
   19   => '{9}на{10}',
   20   => 'два{10}',
   30   => '{3}{10}',
   40   => '{4}{10}',
   50   => '{5}{10}',
   60   => '{6}{10}',
   70   => '{7}{10}',
   80   => '{8}{10}',
   90   => '{9}{10}',
   100  => 'сто',
   200  => '{2}ста',
   300  => '{3}ста',
   '1e3'  => 'хиляда',
   '1e4'  => '{10} хиляди',
   '1e5'  => '{100} хиляди',
   '1e6'  => 'милион',
   '1e7'  => '{10} {1e6}а',
   '1e8'  => '{100} {1e6}а',
   '1e9' => 'милиард',		   # USA English 'billion'
   '1e10'  => '{10} {1e9}а',
   '1e11'  => '{100} {1e9}а',
   '1e12' => 'трилион',		   # sometimes 'билион' in older usage
   '1e13'  => '{10} {1e12}а',
   '1e14'  => '{100} {1e12}а',
   '1e15' => 'квадрилион',
   '1e16'  => '{10} {1e15}а',
   '1e17'  => '{100} {1e15}а',
   '1e18' => 'квинтилион',
   '1e19'  => '{10} {1e18}а',
   '1e20'  => '{100} {1e18}а',
   '1e21' => 'секстилион',
   '1e22'  => '{10} {1e21}а',
  }
 );


$NUMBER_NAMES{LANG_BG()}->{"${_}00"} = "{$_}стотин" foreach qw/4 5 6 7 8 9/;
$NUMBER_NAMES{LANG_BG()}->{'1' . '0'x(3*$_)} = $NUMBER_NAMES{LANG_BG()}->{'1e'. 3*$_} foreach 1..7;

# use Data::Dumper;
# print Dumper \%NUMBER_NAMES;
my $count = 1;

%ORDINALS =
 (
  LANG_BG,
  {
   # given in male singular formal version only, inflection TODO.  Nothing above 99 yet.
   0 => 'нулев',
   1 => 'първи',
   2 => 'втори',
   3 => 'трети',
   4 => 'четвърти',
   5 => '{5}и',
   6 => '{6}и',
   7 => 'седми',
   8 => 'осми',
   9 => '{9}и',
   10 => '{10}и',
   11 => 'едина[10]',
   12 => 'двана[10]',
   13 => '{3}на[10]',
   13   => '{3}на[10]',
   14   => '{4}на[10]',
   15   => '{5}на[10]',
   16   => '{6}на[10]',
   17   => '{7}на[10]',
   18   => '{8}на[10]',
   19   => '{9}на[10]',
   20   => 'два[10]',
   30   => '{3}[10]',
   40   => '{4}[10]',
   50   => '{5}[10]',
   60   => '{6}[10]',
   70   => '{7}[10]',
   80   => '{8}[10]',
   90   => '{9}[10]',
   100 => '{100}тен',
   1000 => 'хиляден',
   10e6 => '{1e6}ен',
  }
 );

foreach my $lang (keys %ORDINALS)
{
 foreach my $val (values %{$ORDINALS{$lang}})
 {
  $val = interpolate_string($lang, $val);
 }
}

foreach my $lang (keys %NUMBER_NAMES)
{
 foreach my $val (values %{$NUMBER_NAMES{$lang}})
 {
  $val = interpolate_string($lang, $val);
 }
}

sub deb { print @_ if $DEBUG }

sub ordinate_to_slavic
{
 my $lang = shift;
 my $number = shift;
 my $options = shift @_ || {};

 unless ( exists $ORDINALS{$lang} )
 {
  carp("Ordinates for language $lang are unknown, sorry");
  return undef;
 }
 
 my $hash = $ORDINALS{$lang};

 unless ( $number >= 0 )
 {
  carp("Ordinates must not be negative");
  return undef;
 }

 unless ( int $number == $number )
 {
  carp("Ordinates can only be integers");
  return undef;
 }

 return $hash->{$number} if exists $hash->{$number};

 my $max = max(keys %$hash);
 if ($number > $max)
 {
  carp("Ordinate $number is above maximum $max and not supported, sorry");
  return undef;
 }

 if ($lang eq LANG_BG)
 {
  # we may have a partially expressible ordinate number, which in
  # Bulgarian for a number of N digits is done with N-1 numbers (not
  # ordinals) with no conjunctions, and an 'и' conjunction before the
  # last one (N) as an ordinal.  Effectively it turns out to be the
  # number without the least significant digit, then 'и', then the
  # ordinal of the least significant digit.  The exceptions should be
  # handled by $ORDINALS.

  my $out = '';
  
  my $bot = $number % 10;
  my $top = $number - $bot;
  return interpolate_string($lang, "{{$top}@{[NO_CONJUNCTIONS()]}} и [$bot]");
 }

 carp("The ordinate for $number in language '$lang' couldn't be found, sorry");
 return undef;
}

sub bulgarian_triplets
{
 my $lang = LANG_BG;
 my $hash = shift;
 my $tri = shift;
 my $options = shift @_ || {};

 my $pow = 0;
 foreach my $t (@$tri)			# this is a triplet
 {
  my $some_left = scalar @$tri > $pow/3; # true if we're not at end of @$tri yet
  # convert to scientific notation
  my $canon_power = $pow;
  my $canon_t = $t;
  if ($t =~ m/$RE{num}{real}{-sep=>'[,.]?'}{-keep}/)
  {
   $canon_power = $8 || 0;
   $canon_t = $3;
  }
  else
  {
   while ($canon_t >= 10)
   {
    $canon_t /= 10;
    $canon_power ++;
   }
  }
  
  my $canon = "${canon_t}e$canon_power";
  
  deb("Working on triplet $t (power $pow, canonical $canon)\n");
  if (exists $hash->{$canon})
  {
   $t = $hash->{$canon};
  }
  elsif ($t == 0)	# handle 0 and '000' strings
  {
   if (scalar @$tri == 1)		# is the zero the only number?
   {
    $t = 0;
    redo;
   }
   else
   {
    $t = '';				# don't do anything with uninteresting zeroes
   }
  }
  else
  {
   # try decomposing $t
   
   # get rid of scientific notation
   $t =~ s/(\d+)e(\d+)/$1 . 0 x $2/e;
   
   # first, set up the qualifier
   deb("getting qualifier and gender for $t\n");
   
   my $qualifier = '';
   my $inflexion = '';
   my $extra_а = '';

   if ($pow)
   {
    $qualifier = number_to_slavic($lang, "1e$pow");
    $inflexion = MASCULINE_GENDER;	# all but thousands are masculine
    $extra_а = 'а';			# and all have 'a' when plural (singular cases are caught by the %NUMBER_NAMES hash)
    
    if ($pow eq 3) # thousands are a special case for gender, being feminine
    {
     $qualifier = 'хиляди';
     $inflexion = FEMININE_GENDER;
     $extra_а = '';			# no extra 'a' for thousands
    }
   }

   $qualifier .= $extra_а;
   
   my @n = split //, $t;
   shift @n while 0 == $n[0];		# remove the leading zeroes
   deb("decomposing $t, result [@n]\n");
   my @inter;
   while (@n)
   {
    my $decompose_num = shift @n;
    my $decompose_pow = scalar @n;

    # grab the next digit for numbers 10 .. 20
    if (($decompose_num == 1 && scalar @n == 1) ||
	($decompose_num == 2 && scalar @n == 1 && $n[0] == 0))
    {
     $decompose_num .= shift @n;
     $decompose_pow = 0;
    }

    next unless $decompose_num;		# skip zeroes

    my $extra_и = '';
    # numbers below 21 are one word, so in cases like 1001 (хиляда и едно) a conjunction is needed
    # ditto for 100..900
    if (
	# $some_left tells us there are more triplets to come
	$some_left &&
	(
	 ($decompose_num <= 20 && scalar @n == 0) ||  # 1..20
	 (scalar @n == 2 && $n[0] == 0 && $n[1] == 0) # N00
	)
       )
    {
     $extra_и = ' ';
    }
    
    push @inter, sprintf("%s{%s%s}", $extra_и, $decompose_num, '0'x$decompose_pow);
   }

   my @inter_options = (NO_CONJUNCTIONS);
   push @inter_options, $inflexion if $inflexion;
   my $inter_options = join ':', @inter_options;
   
   $inter[-1] =~ s/({.*})/{$1$inter_options}/;

   my $inter = join(' ', @inter);
   deb("bulgarian_triplets calling interpolate_string with [$inter]\n");
   $inter = interpolate_string($lang, $inter);

   if (defined $inter)
   {
    $t = $inter;
    # add the final conjunction if requested
    $t =~ s/\s(\w+)$/ и $1/ unless $options->{NO_CONJUNCTIONS()};
    $t .= " ${qualifier}" if $qualifier; # add the qualifier
    $t =~ s/^\s+//g;		       # replace leading/ending spaces
    $t =~ s/\s+$//g;		       # replace leading/ending spaces
   }
   else
   {
    carp "Couldn't convert $canon";
   }
  }
  
  $pow+=3;
 }

 @$tri = reverse @$tri;
 
 return "@$tri";
}

sub find_known
{
 my $lang = shift;
 my $hash = shift;
 my $number = shift;
 my $options = shift @_ || {};

 foreach my $gender (FEMININE_GENDER(), MASCULINE_GENDER())
 {
  return $INFLEXIONS{$lang}->{$gender}->{$number}
   if (exists $options->{$gender} &&
       exists $INFLEXIONS{$lang}->{$gender}->{$number});
 }
 
 return $hash->{$number} if exists $hash->{$number};

 return undef;
}

sub number_to_slavic
{
 my $lang = shift;
 my $number = shift;
 my $options = shift @_ || {};

# carp("Language $lang, number $number");

 if ($number !~ m/^$RE{num}{int}$/ && $number !~ m/^$RE{num}{real}$/)
 {
  carp("Number $number doesn't appear to be a real number, sorry");
  return undef;
 }

 $number =~ s/\+//g;
 unless ( exists $NUMBER_NAMES{$lang} )
 {
  carp("Numbers for language $lang are unknown, sorry");
  return undef;
 }

 my $hash = $NUMBER_NAMES{$lang};
 
 my $max = max(keys %$hash);
 if ($number > $max)
 {
  carp("Number $number is above maximum $max and not supported, sorry");
  return undef;
 }

 return find_known($lang, $hash, $number, $options) if defined find_known($lang, $hash, $number, $options);

 return "$MINUS " . number_to_slavic($lang, $1) if $number =~ m/-\s*(.*)/;

 # normalize to scientific notation if exponent is specified, then expand
 if ($number =~ m/$RE{num}{real}{-sep=>'[,.]?'}{-keep}/)
 {
  my $power = $8;
  my $num = $3;
  if ($power)
  {   
   while ($num >= 10)
   {
    $num /= 10;
    $power++;
   }

   return find_known($lang, $hash, $number, $options) if defined find_known($lang, $hash, $number, $options);

   while ($num && int $num != $num)
   {
    $num *= 10;
    $power--;
   }
   
   $number = $num . '0' x $power;

   return find_known($lang, $hash, $number, $options) if defined find_known($lang, $hash, $number, $options);

   deb("finally, got power $power and number $num => $number\n");
  }
 }
 
 if (LANG_BG eq $lang)
 {
  # build the intepretation from the number's digits
  my @components;
  my @parts = split /[.,]/, $number, 2;
  $parts[1] ||= ''; # always provide a floating part if it doesn't come with the number

  my $n = $parts[0];
  my @n;
  while ($n)
  {
   my $old_n = $n;
   my $triplet = substr $n, -3, 3, '';
   deb("grabbing triplet from $old_n resulting in $n and $triplet\n");
   push @n, $triplet;
  }

  my $out = bulgarian_triplets($hash, \@n, $options);
  # clean spaces
  $out =~ s/^\s*//;
  $out =~ s/\s*$//;
  $out =~ s/\s+/ /g;
  # fix annoying bugs
  
  # remove leading и
  $out =~ s/^и\s+//g;
  # fix една хиляди
  $out =~ s/^една хиляди/хиляда/;
 return $out;
 }
 
 carp("The number representation of $number in language '$lang' couldn't be found, sorry");
 my $opt_string = join '//', sort keys %$options;
 $opt_string = "//$opt_string" if $opt_string;
 return "$number$opt_string";
}

#
# OO Methods
#
sub new {
 my $class  = shift;
 my $number = shift;
 my $lang   = shift;
 bless { num => $number, lang => $lang}, $class;
}

sub parse {
 my $self = shift;
 if ( $_[0] )
 {
  $self->{num} = shift;
 }
 if ( $_[1] )
 {
  $self->{lang} = shift;
 }
 $self;
}

sub get_string
{
 my $self = shift;
 return number_to_slavic($self->{lang}, $self->{num});
}

sub get_ordinate
{
 my $self = shift;
 return ordinate_to_slavic($self->{lang}, $self->{num});
}

### cperl-mode doesn't like this, so I put it at the end
sub interpolate_string
{
 my $lang = shift;
 my $data = shift;

 
 while ($data =~ m/\[$RE{num}{real}{-sep=>'[,.]?'}\]+/ || # [number]
	$data =~ m/{$RE{num}{real}{-sep=>'[,.]?'}}+/)	  # {number}
 {
  $data =~ s/{
	     {
	     $RE{num}{dec}{-sep=>'[,.]?'}{-keep}
	     }
	     ([:\w]+)?
	     }
	    /
	     number_to_slavic($lang,
			      $1,
			      { map { $_ => 1 } split(':', $11) }
			     )
	    /giex;

  $data =~ s/
	     {
	     $RE{num}{dec}{-sep=>'[,.]?'}{-keep}
	     }
	    /number_to_slavic($lang, $1)/giex;

  $data =~ s/
	     \[
	     \[
	     $RE{num}{real}{-sep=>'[,.]?'}{-keep}
	     \]
	     ([:\w]+)?
	     \]
	    /
	     ordinate_to_slavic(
				$lang,
				$1,
				{ map { $_ => 1 } split(':', $2) }
			       )
	    /giex;

  $data =~ s/
	     \[
	     $RE{num}{real}{-sep=>'[,.]?'}{-keep}
	     \]
	    /ordinate_to_slavic($lang, $1)/giex;
 }
 return $data;
}


1;

__END__

=pod

=head1 NAME

Lingua::Slavic::Numbers - Converts numeric values into their Slavic
string equivalents.  Bulgarian is supported so far.

=head1 SYNOPSIS

 # Procedural Style
 use Lingua::Slavic::Numbers qw(number_to_slavic ordinate_to_slavic);
 print number_to_slavic('bg', 345 );

 my $twenty  = ordinate_to_slavic('bg', 20 );
 print "Ordinate of 20 is $twenty";

 # OO Style
 use Lingua::Slavic::Numbers;
 # specifies default language
 my $number = Lingua::Slavic::Numbers->new( 123, Lingua:Slavic::Numbers::LANG_BG );
 print $number->get_string;
 print $number->get_ordinate;
 # override language
 print $number->get_string(Lingua:Slavic::Numbers::LANG_BG);
 print $number->get_ordinate(Lingua:Slavic::Numbers::LANG_BG);

 # default language, no number
 my $other_number = Lingua::Slavic::Numbers->new(Lingua:Slavic::Numbers::LANG_BG);
 $other_number->parse( 7340 );
 $bg_string = $other_number->get_string;

=head1 DESCRIPTION

This module converts a number into a Slavic-language cardinal or
ordinal.  Bulgarian is supported so far.

The interface tries to conform to the one defined in Lingua::EN::Number,
though this module does not provide any parse() method. Also, 
unlike Lingua::En::Numbers, you can use this module in a procedural
manner by importing the number_to_LL() function (LL=bg so far).

If you plan to use this module with greater numbers (>10e20), you can use
the Math::BigInt module:

 use Math::BigInt;
 use Lingua::Slavic::Numbers qw( number_to_slavic );

 my $big_num = new Math::BigInt '1.23e68';
 print number_to_slavic('bg', $big_num);

=head1 FUNCTION-ORIENTED INTERFACE

=head2 number_to_slavic( $lang, $number )

 use Lingua::Slavic::Numbers qw(number_to_slavic);
 my $depth = number_to_slavic('bg', 20_000 );
 my $year  = number_to_slavic('bg', 1870 );

 # in honor of Lingua::FR::Numbers, which I copied to start this
 # module, I'm using a French example
 print "Жул Верн написа ,,$depth левги под морето'' в $year.";

This function can be exported by the module.

=head2 ordinate_to_slavic( $lang, $number )
 
 use Lingua::Slavic::Numbers qw(ordinate_to_slavic);
 my $twenty  = ordinate_to_slavic('bg', 20 );
 print "Номер $twenty";

This function can be exported by the module.

=head1 CONSTANTS

Bulgarian: Lingua:Slavic::Numbers::LANG_BG ('bg')

=head1 SOURCE

Lingua::FR::Numbers for the code

=head1 BUGS

Though the module should be able to convert big numbers (up to 10**36),
I do not know how Perl handles them.

Please report any bugs or comments using the Request Tracker interface:
https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Slavic-Numbers

=head1 COPYRIGHT

Copyright 2008, Ted Zlatanov (Теодор Златанов). All Rights
Reserved. This module can be redistributed under the same terms as
Perl itself.

=head1 AUTHOR

Ted Zlatanov <tzz@lifelogs.com>

=head1 SEE ALSO

Lingua::EN::Numbers, Lingua::Word2Num

