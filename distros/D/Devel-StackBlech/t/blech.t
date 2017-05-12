#!perl
use Test::More tests => 4;
use IPC::Run ();
use File::Basename ();

my $test_dir = File::Basename::dirname( __FILE__ );
my $blech_pl = "$test_dir/blech.pl";

# Expect something like the following:
#
# PERL_SI=0x95cc630
# LOOP my_op=0x96f6c90
# EVAL old_eval_root=0x0 retop=0x963ee18
# SUB cv=0x95ebb70 retop=0x95f5910
#
IPC::Run::run(
    [ $^X, '-Mblib', $blech_pl ],
    '>', \ my $blech
);

my $HEX = '[0-9a-f]';

like( $blech, qr/^PERL_SI=0x$HEX+$/m, "Found PERL_SI" );
like( $blech, qr/^LOOP/m, "Found LOOP my_op" );
like( $blech, qr/^EVAL/m, "Found EVAL old_eval_root" );
like( $blech, qr/^SUB/m, "Found SUB cv" );
