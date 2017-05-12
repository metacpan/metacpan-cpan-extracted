
=head1 NAME

Lingua::EN::MatchNames - Smart matching for human names.

=head1 SYNOPSIS

  use Lingua::EN::MatchNames;

  $score= name_eq( $firstn_0, $lastn_0, $firstn_1, $lastn_1 );

=head1 DESCRIPTION

You have two databases of person records that need to be synchronized or matched up,
but they use different keys--maybe one uses SSN and the other uses employee id.
The only fields you have to match on are first and last name.

That's what this module is for.

Just feed the first and last names to the C<name_eq()> function, and it returns
C<undef> for no possible match, and a percentage of certainty (rank) otherwise.
The ranking system isn't very scientific, and gender isn't considered, though
it probably should be.

The C<name_eq()> function, checks for: 

=over 4

=item * inconsistent case (MacHenry = Machenry = MACHENRY)

=item * inconsistent symbols (O'Brien = Obrien = O BRIEN)

=item * misspellings (Grene = Green)

=item * last name hyphenation (Smith-Curry = Curry)

=item * similar phonetics (Hanson = Hansen)

=item * nicknames (Midge = Peggy = Margaret)

=item * extraneous initials (H. Ross = Ross)

=item * extraneous suffixes (Reed, Jr. = Reed II = Reed)

=item * and more...

=back

=head2 Preliminary Tests:

  Homer Simpson HOMER SIMPOSN: 77
  Marge Simpson MIDGE SIMPSON: 81
  Brian Lalonde BRYAN LA LONDE: 82
  Brian Lalonde RYAN LALAND: 72
  Peggy MacHenry Midge Machenry: 81
  Liz Grene Elizabeth Green: 72
  Chuck Reed, Jr. Charles Reed II: 82
  Kathy O'Brien Catherine Obrien: 81
  Lizzie Hanson Lisa Hanson: 91
  H. Ross Perot Ross PEROT: 88
  Kathy Smith-Curry KATIE CURRY: 81
  Dina Johnson-Warner Dinah J-Warner: 80
  Leela Miles-Conrad Leela MilesConrad: 86
  C. Renee Smythe Cathy Smythe: 71
  Victoria (Honey) Rider HONEY RIDER: 88
  Bart Simpson El Barto Simpson: 80
  Bart Simpson Lisa Simpson: (no match)
  Arthur Dent Zaphod Beeblebrox: (no match)

=head1 WARNING

The scoring in this version is utterly arbitrary.
I made all of the numbers up.
The certainty percentages should be OK relative to each other, but
would be better if someone could give me some statistical data.

Be sure and B<test> this against your data first!
Your data may not look like my test data.

And although I hope this is useful to many, I do not provide any
kind of warranty (expressed or implied), and do not suggest the
suitability of this module to any particular purpose.  
This module probably should not be used for life support or military
purposes, and it B<must> not be used for unsolicited commercial email
or other bulk advertising.

=head1 REPOSITORY

L<https://github.com/brianary/Lingua-EN-MatchNames>

=head1 AUTHOR

Brian Lalonde, E<lt>brian@webcoder.infoE<gt>

=head1 REQUIREMENTS

Lingua::EN::NameParse,
Lingua::EN::Nickname,
Parse::RecDescent,
String::Approx, 
Text::Metaphone,
Text::Soundex

=head1 SEE ALSO

perl(1), 
L<Lingua::EN::NameParse>,
L<Lingua::EN::Nickname>,
L<String::Approx>, 
L<Text::Metaphone>,
L<Text::Soundex>

=cut

package Lingua::EN::MatchNames;
require Exporter;
use Carp;
use Lingua::EN::NameParse;
use Lingua::EN::Nickname;
use String::Approx 'amatch';
use Text::Metaphone;
use Text::Soundex;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use vars qw($debug);

$VERSION=     '1.36';
@ISA=         qw(Exporter);
@EXPORT=      qw(name_eq);
@EXPORT_OK=   qw(fname_eq lname_eq);
%EXPORT_TAGS= 
( 
  ALL => [ @EXPORT, @EXPORT_OK ],
);

sub _nparse($)
{
  local $_= shift;
  my $nparse= new Lingua::EN::NameParse( auto_clean => 1, force_case => 1 )
    or carp "Unable to set up name parser.\n$!\n";
  $nparse->parse($_);
  my %name= $nparse->components;
  return($name{given_name_1},$name{surname_1}.
    ( $name{surname_2} ? '-'.$name{surname_2} : '' ));
}

sub fname_eq
{
  my($name0,$name1,$match)= @_;
  return unless $name0 and $name1;
  return 100 if $name0 eq $name1;
  # recurse offset nicknames 
  if($name0=~ m/\((\w+)\)/) { return $match if $match= fname_eq($name1,$1); }
  if($name0=~ m/"(\w+)"/)   { return $match if $match= fname_eq($name1,$1); }
  if($name1=~ m/\((\w+)\)/) { return $match if $match= fname_eq($name0,$1); }
  if($name1=~ m/"(\w+)"/)   { return $match if $match= fname_eq($name0,$1); }
  # strip leading/trailing initial(s) (98%)
  $name0=~ s/\W*\b\w\b\W*//g; 
  $name1=~ s/\W*\b\w\b\W*//g; 
  return 98 if $name0 eq $name1;
  # recurse separate parts 
  if($name0=~ /\W/)
  { # split parts, find best match 
    my($match)= sort { $b <=> $a } map {fname_eq($name1,$_)} split /\W+/, $name0;
    return $match if $match;
  }
  elsif($name1=~ /\W/)
  { # split parts, find best match 
    my($match)= sort { $b <=> $a } map {fname_eq($name0,$_)} split /\W+/, $name1;
    return $match if $match;
  }
  # all caps, no symbols (95%)
  ($name0= uc $name0)=~ y/A-Z//cd; 
  ($name1= uc $name1)=~ y/A-Z//cd; 
  return 95 if $name0 eq $name1;
  # nickname (80%)
  return int 0.8*$match if $match= nickname_eq($name0,$name1);
  # fuzzy approx (15%)
  return 35 if amatch($name0,$name1) and amatch($name1,$name0);
  # simple trucation 
  return 10 if $name0=~ /^$name1|$name1$/ or $name1=~ /^$name0|$name0$/;
  # a single initial 
  ($name0,$name1)= @_;
  for($name0=~ m/\b(\w)\b/) { return 5 if $name1=~ /^$_/i; }
  for($name1=~ m/\b(\w)\b/) { return 5 if $name0=~ /^$_/i; }
  return;
}

sub lname_eq
{
  my($name0,$name1)= @_;
  return unless $name0 and $name1;
  return 100 if $name0 eq $name1;
  # strip trailing suffixes (95%)
  $name0=~ s/\s+([IVX]+|,.*|[JS]r\.?)\s*$//;
  $name1=~ s/\s+([IVX]+|,.*|[JS]r\.?)\s*$//;
  return 95 if $name0 eq $name1;
  # recurse hyphenated components 
  if($name0=~ /-/)
  { # split hyphenation on hyphen ONLY 
    my($match)= sort { $b <=> $a } map {lname_eq($name1,$_)} split /-/, $name0;
    return $match if $match;
  }
  elsif($name1=~ /-/)
  { # split hyphenation on hyphen ONLY 
    my($match)= sort { $b <=> $a } map {lname_eq($name0,$_)} split /-/, $name1;
    return $match if $match;
  }
  # all caps, no symbols (85%)
  ($name0= uc $name0)=~ y/A-Z//cd; 
  ($name1= uc $name1)=~ y/A-Z//cd; 
  return 85 if $name0 eq $name1;
  # metaphone (70%)
  return 70 if Metaphone($name0) eq Metaphone($name1);
  # soundex (40%)
  return 40 if soundex($name0) eq soundex($name1);
  # fuzzy approx (15%)
  return 25 if amatch($name0,$name1) and amatch($name1,$name0);
  # nonstandard 'hyphenation'/simple truncation 
  ($name0,$name1)= map {(my$n=$_)=~s/\s+([IVX]+|,.*|[JS]r\.?)\s*$//;$n=~y/A-Za-z\-//cd;$n} @_;
  return int 0.8*lname_eq($name0,$name1) if $name0=~ s/(\B[A-Z][a-z]+)/-$1/g 
    or $name1=~ s/(\B[A-Z][a-z]+)/-$1/g;
  return 10 if $name0=~ /^$name1|$name1$/i or $name1=~ /^$name0|$name0$/i;
  return;
}

sub name_eq
{
  my($nomF0,$nomL0,$nomF1,$nomL1,$Frank,$Lrank)= 
    ( @_ < 4 ? (_nparse($_[0]),_nparse($_[1])) : @_ );
  return unless $Lrank= lname_eq $nomL0, $nomL1;
  return unless $Frank= fname_eq $nomF0, $nomF1;
  return int $Lrank*0.7 + $Frank*0.3; # another ratio I just made up 
}

1
