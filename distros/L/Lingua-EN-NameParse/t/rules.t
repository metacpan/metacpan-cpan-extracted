#------------------------------------------------------------------------------
# File   : rules.t - test script for Lingua::EN::NameParse.pm
# Author : Kim Ryan
#------------------------------------------------------------------------------

use strict;
use Test::Simple tests => 19;
use Lingua::EN::NameParse;

my %args =
(
    joint_names => 1
);

my $name = Lingua::EN::NameParse->new(%args);
my ($input,%props);

# Test order of rule evaluation

$input = "MR ADAM SMITH & MS DEBRA JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_John_Smith_&_Ms_Mary_Jones', 'Mr_John_Smith_&_Ms_Mary_Jones format');

$input = "MR AB SMITH & MS D.F. JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_A_Smith_&_Ms_B_Jones', 'Mr_A_Smith_&_Ms_B_Jones format');

$input = "MR AND MRS AB & D.F. JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_&_Ms_A_&_B_Smith', 'Mr_&_Ms_A_&_B_Smith format');

$input = "MR AB AND MS D.F. JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_A_&_Ms_B_Smith', 'Mr_A_&_Ms_B_Smith format');

$input = "MR AND MS D.F. JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_&_Ms_A_Smith', 'Mr_&_Ms_A_Smith format');

$input = "MR AB AND D.G. JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_A_&_B_Smith', 'Mr_A_&_B_Smith format');

$input = "ADAM SMITH & DEBRA JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'John_Smith_&_Mary_Jones', 'John_Smith_&_Mary_Jones format');

$input = "ADAM & DEBRA SMITH";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'John_&_Mary_Smith', 'John_&_Mary_Smith format');

$input = "A SMITH & D JONES ";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'A_Smith_&_B_Jones', 'A_Smith_&_B_Jones format');

$input = "MR JOHN FITZGERALD KENNEDY";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_John_Adam_Smith', 'Mr_John_Adam_Smith format');

$input = "MR JOHN F KENNEDY";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_John_A_Smith', 'Mr_John_A_Smith format');

$input = "MR TOM JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_John_Smith', 'Mr_John_Smith format');

$input = "MR AB JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'Mr_A_Smith', 'Mr_A_Smith format');

$input = "WILLIAM JEFFERSON CLINTON";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'John_Adam_Smith', 'John_Adam_Smith format');

$input = "F SCOTT FITZGERALD";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'J_Adam_Smith', 'J_Adam_Smith format');

$input = "JOHN F KENNEDY";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'John_A_Smith', 'John_A_Smith format');

$input = "TOM JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'John_Smith', 'John_Smith format');

$input = "AB JONES";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'A_Smith', 'A_Smith format');

$input = "Voltaire";
$name->parse($input);
%props = $name->properties;
ok( $props{type} eq 'John', 'John format');


