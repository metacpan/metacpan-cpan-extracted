# Test the new "object" behaviour.

# This tests:
# * Copy literals, don't use read-only scalars.
# * User-defined booleans
# ** Correct object name in user-defined booleans
# ** Copy literals and user-defined booleans interplay
# ** Deletion of user-defined booleans
# * Detect hash collisions

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use JSON::Parse;

#   ____                    _ _ _                 _     
#  / ___|___  _ __  _   _  | (_) |_ ___ _ __ __ _| |___ 
# | |   / _ \| '_ \| | | | | | | __/ _ \ '__/ _` | / __|
# | |__| (_) | |_) | |_| | | | | ||  __/ | | (_| | \__ \
#  \____\___/| .__/ \__, | |_|_|\__\___|_|  \__,_|_|___/
#            |_|    |___/                               
#

my $jp = JSON::Parse->new ();
$jp->copy_literals (1);
my $stuff = '{"hocus":true,"pocus":false,"focus":null}';
my $out = $jp->run ($stuff);
eval {
    $out->{pocus} = "bad city";
};
ok (! $@, "Can modify literals without error");

$jp->copy_literals (0);
my $stuff2 = '{"hocus":true,"pocus":false,"focus":null}';
my $out2 = $jp->run ($stuff);
eval {
    $out2->{pocus} = "bad city";
};
ok ($@, "Can't modify literals without error");
note ($@);

# User-defined booleans
package Ba::Bi::Bu::Be::Bo;

# https://metacpan.org/source/MAKAMAKA/JSON-PP-2.27300/lib/JSON/PP.pm#L1390

$Ba::Bi::Bu::Be::Bo::true = do { bless \(my $dummy = 1), "JSON::PP::Boolean" };
$Ba::Bi::Bu::Be::Bo::false = do { bless \(my $dummy = 0), "JSON::PP::Boolean" };
$Ba::Bi::Bu::Be::Bo::null = do { bless \(my $dummy), "JSON::PP::Boolean" };

sub true {$Ba::Bi::Bu::Be::Bo::true;}
sub false {$Ba::Bi::Bu::Be::Bo::false;}
sub null {$Ba::Bi::Bu::Be::Bo::null;}

1;
package main;

# $jpub = j-son p-arser with u-ser b-ooleans

my $jpub = JSON::Parse->new ();
my $jpub1 = $jpub->run ($stuff);
eval {
    $jpub1->{hocus} = "bad city";
};
ok ($@, "got error altering literals with default JSON::Parse object");

# Use the same things all the people on CPAN do, switching off the
# warnings.

$jpub->set_true ($Ba::Bi::Bu::Be::Bo::true);
$jpub->no_warn_literals (1);
$jpub->set_false ($Ba::Bi::Bu::Be::Bo::false);
$jpub->no_warn_literals (0);
$jpub->set_null ($Ba::Bi::Bu::Be::Bo::null);
my $jpub2 = $jpub->run ($stuff);
eval {
    $jpub2->{hocus} = "bad city";
};
ok (! $@, "Values are not read-only with user-defined true/false values");

my $jpub3 = $jpub->run ($stuff);
like (ref $jpub3->{hocus}, qr/JSON::PP::Boolean/, "true value correct type");
like (ref $jpub3->{pocus}, qr/JSON::PP::Boolean/, "false value correct type");
like (ref $jpub3->{focus}, qr/JSON::PP::Boolean/, "null value correct type");

# Now test the same thing after switching on copy_literals.

$jpub->no_warn_literals (1);
$jpub->copy_literals (1);
$jpub->no_warn_literals (0);
my $jpub4 = $jpub->run ($stuff);
like (ref $jpub4->{hocus}, qr/JSON::PP::Boolean/, "true value correct type even with copy-literals");
like (ref $jpub4->{pocus}, qr/JSON::PP::Boolean/, "false value correct type even with copy-literals");
like (ref $jpub4->{focus}, qr/JSON::PP::Boolean/, "null value correct type even with copy-literals");

# Now delete all our user-defined booleans

$jpub->delete_true ();
$jpub->delete_false ();
$jpub->delete_null ();

# Test the objects have gone.

my $jpub5 = $jpub->run ($stuff);
unlike (ref $jpub5->{hocus}, qr/JSON::PP::Boolean/, "User true deleted");
unlike (ref $jpub5->{pocus}, qr/JSON::PP::Boolean/, "User false deleted");
unlike (ref $jpub5->{focus}, qr/JSON::PP::Boolean/, "User null deleted");

# Now test that copy-literals is still working.

my $jpub6 = $jpub->run ($stuff);
eval {
    $jpub6->{hocus} = "bad city";
};
ok (! $@, "Values are not read-only, copy literals still works");

# Finally switch off copy-literals and check that things are back to
# the default behaviour.

$jpub->copy_literals (0);
my $jpub7 = $jpub->run ($stuff);
unlike (ref $jpub7->{hocus}, qr/JSON::PP::Boolean/, "User true deleted");
unlike (ref $jpub7->{pocus}, qr/JSON::PP::Boolean/, "User false deleted");
unlike (ref $jpub7->{focus}, qr/JSON::PP::Boolean/, "User null deleted");
eval {
    $jpub7->{hocus} = "bad city";
};
ok ($@, "Values are read-only again");
# Check it's the right error, "Modification of a readonly value".
like ($@, qr/Modification/, "Error message looks good");
note ($@);

# Check that this doesn't make a warning, we want the user to be able
# to set "null" to "undef".

my $warning;
$SIG{__WARN__} = sub { $warning = "@_"; };
$jpub->set_true (undef);
ok ($warning, "Warning on setting true to non-true value");
$jpub->set_true (0);
ok ($warning, "Warning on setting true to non-true value");
$jpub->set_true ('');
ok ($warning, "Warning on setting true to non-true value");
$warning = undef;
$jpub->set_false (undef);
ok (! $warning, "no warning when setting user-defined false");
$warning = undef;
$jpub->set_false (0);
ok (! $warning, "no warning when setting user-defined false");
$warning = undef;
$jpub->set_false ('');
ok (! $warning, "no warning when setting user-defined false");
$warning = undef;
# https://www.youtube.com/watch?v=g4ouPGGLI6Q
$jpub->set_false ('Yodeadodoyodeadodoyodeadodoyodeadodoyodeadodoyodeadodoyo-bab-baaaaa Ahhhhhh-aaahhhh-aaaaaa-aaaaAAA! Ohhhhhh-ooohhh-oooooo-oooOOO!');
ok ($warning, "warning when setting user-defined false to a true value");
note ($warning);
$warning = undef;
$jpub->set_null (undef);
$jpub->set_null (0);
$jpub->set_null ('');
ok (! $warning, "no warning when setting user-defined null");

#  ____       _            _               _ _ _     _                 
# |  _ \  ___| |_ ___  ___| |_    ___ ___ | | (_)___(_) ___  _ __  ___ 
# | | | |/ _ \ __/ _ \/ __| __|  / __/ _ \| | | / __| |/ _ \| '_ \/ __|
# | |_| |  __/ ||  __/ (__| |_  | (_| (_) | | | \__ \ | (_) | | | \__ \
# |____/ \___|\__\___|\___|\__|  \___\___/|_|_|_|___/_|\___/|_| |_|___/
#                                                                     
#

my $stuff3 = '{"hocus":1,"pocus":2,"hocus":3,"focus":4}';

my $jp3 = JSON::Parse->new ();
eval {
    $jp3->run ($stuff3);
};
ok (!$@, "Did not detect collision in default setting");

$jp3->detect_collisions (1);
eval {
    $jp3->run ($stuff3);
};
ok ($@, "Detected collision");
note ($@);

$jp3->detect_collisions (0);
eval {
    $jp3->run ($stuff3);
};
ok (!$@, "Did not detect collision after reset to 0");

SKIP: {
    eval "require 5.14;";
    if ($@) {
	skip "diagnostics_hash requires perl 5.14 or later", 1;
    }
    #  ____  _                             _   _        _               _     
    # |  _ \(_) __ _  __ _ _ __   ___  ___| |_(_) ___  | |__   __ _ ___| |__  
    # | | | | |/ _` |/ _` | '_ \ / _ \/ __| __| |/ __| | '_ \ / _` / __| '_ \ 
    # | |_| | | (_| | (_| | | | | (_) \__ \ |_| | (__  | | | | (_| \__ \ | | |
    # |____/|_|\__,_|\__, |_| |_|\___/|___/\__|_|\___| |_| |_|\__,_|___/_| |_|
    #                |___/                                                    
    
    my $jp4 = JSON::Parse->new ();
    $jp4->diagnostics_hash (1);
    eval {
	$jp4->run ("{{{{{");
    };
    ok (ref $@ eq 'HASH', "Got hash diagnostics");
};

done_testing ();
