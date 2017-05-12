#------------------------------------------------------------------------------
# Test script for Lingua::EN::NameParse.pm
# Author : Kim Ryan
#------------------------------------------------------------------------------

use strict;
use Test::Simple tests => 12;
use Lingua::EN::NameParse qw(clean case_surname);

my $input;

# Test case_surname subroutine
$input = "BIG BROTHER & THE HOLDING COMPANY";
ok(case_surname($input) eq 'Big Brother & The Holding Company','case_surname');

my %args =
(
  salutation      => 'Dear',
  sal_default     => 'Friend',
  auto_clean      => 1,
  initials        => 2,
  allow_reversed  => 1,
  joint_names     => 1,
  extended_titles => 1

);

my $name = Lingua::EN::NameParse->new(%args);

$input = "MR AB MACHLIN";
$name->parse($input);
ok( $name->case_all eq 'Mr AB Machlin','Mac prefix exception');

$input = "MR AB MACHLIN & JANE O'BRIEN";
$name->parse($input);
ok( $name->case_all eq "Mr AB Machlin & Jane O'Brien" ,'name casing');

$input = "john smith";
$name->parse($input);
ok( $name->salutation eq 'Dear Friend' ,'default salutation');

$input = "DR. A.B.C. FEELGOOD";
$name->parse($input);
ok( $name->salutation(sal_type => 'title_plus_surname') eq 'Dear Dr Feelgood' ,'title_plus_surname salutation');

$input = "DR ANDREW FEELGOOD";
$name->parse($input);
ok( $name->salutation(sal_type => 'given_name') eq 'Dear Andrew' ,'given_name salutation');

$input = "Estate Of The Late Lieutenant Colonel AB Van Der Heiden Jnr";
$name->parse($input);
my %comps = $name->components;
ok ( ($comps{precursor} eq 'Estate Of The Late' and
   $comps{title_1} eq 'Lieutenant Colonel' and
   $comps{initials_1} eq 'AB' and
   $comps{surname_1} eq 'Van Der Heiden' and
   $comps{suffix} eq 'Jnr'),
   'component extraction');

# Test properties
$input = "m/s de de silva";
$name->parse($input);
my %props = $name->properties;
ok( ($props{number} == 1 and $props{type} eq 'Mr_A_Smith','properties'),'properties');

# Test non matching
$input = "PROF A BRAIN & ASSOCIATES";
$name->parse($input);
%comps = $name->components;
ok( $comps{non_matching} eq '& Associates','non matching');

$input = '   Bad Na89me!';
ok( clean($input) eq 'Bad Name','cleaning');

$input = "de silva, m/s de";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_A_Smith','reverse order');

my $lc_prefix = 1;
ok( case_surname("DE SILVA-O'SULLIVAN",$lc_prefix) eq "de Silva-O'Sullivan" ,'lower casing of surname prefix');
