#!perl

# This unit tests that the documentation examples work.

use strict;
use Test::More tests => 8;
use lib 't';
use Enumeration;
use SubClass;

# From the "DESCRIPTION" section
# (just need to make sure this doesn't barf)
my $var = new Enumeration qw(whee this is fun);

# From the "EXAMPLE" section.
#
use strict;
use warnings;
use Color ':all';
#
#
my $color = new Color(red);
my $output = "Color is currently $color\n";
is $output,  "Color is currently Color::red\n", 'doc example 1';
#
$color->set(white);
$output =    "Color is now $color\n";
is $output,  "Color is now Color::white\n", 'doc example 2';
#
$output =   "I TOLD you it's white!\n" if $color eq white;
is $output, "I TOLD you it's white!\n", 'doc example 3';
#
eval {$color->set('purple');};   # dies.
like $@, qr/\A"purple" is not an allowable value/, 'doc example 4';


# Doc says that any old character can be used as an enumeration
# constant.
use WeirdChars;
my $w = new WeirdChars '0';
is $w->bare_value, '0'   => 'weird value 0';
$w->set('%^^&$');
is $w->bare_value, '%^^&$', 'weird value %^^&$';
$w->set('---');
is $w->bare_value, '---', 'weird value ---';
$w->set('');
is $w->bare_value, '', 'weird value (empty)';
