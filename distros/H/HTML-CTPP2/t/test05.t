# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-CTPP2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('HTML::CTPP2') };

use strict;
use Data::Dumper;

my $T = new HTML::CTPP2();
ok( ref $T eq "HTML::CTPP2", "Create object.");

$T -> parse_template("examples/syntax-error.tmpl");

my $Error = $T -> get_last_error();

#warn sprintf("ERROR: 0x%08X; In file `%s`, line %d, pos %d: %s; IP 0x%08X\n", $Error-> {'error_code'},
#                                                                        $Error-> {'template_name'},
#                                                                        $Error-> {'line'},
#                                                                        $Error-> {'pos'},
#                                                                        $Error-> {'error_str'},
#                                                                        $Error-> {'ip'});
#warn Dumper ($Error);

ok ($Error -> {'pos'}          == 14 &&
    $Error -> {'line'}         == 2 &&
    $Error-> {'template_name'} eq 'examples/syntax-error.tmpl' &&
    $Error-> {'error_code'}    == 0x04000011 &&
    $Error-> {'error_str'}     eq 'expected at least one space symbol'&&
    $Error-> {'ip'}            == 0);
