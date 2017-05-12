use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';
use Test::More skip_all => 'duktape v2.0 does not support file/io functions';

my $NONEXISTENT_FILE = '/this/file/doesnt/exist';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub test_peval_file {
    my $rc = $duk->peval_file($NONEXISTENT_FILE);
    printf("rc: %ld\n", $rc);
    printf("result: %s\n", $duk->safe_to_string(-1));

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_peval_file_noresult {

    my $rc = $duk->peval_file_noresult($NONEXISTENT_FILE);
    printf("rc: %ld\n", $rc);

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_pcompile_file {

    my $rc = $duk->pcompile_file(0, $NONEXISTENT_FILE);
    printf("rc: %ld\n", $rc);
    printf("result: %s\n", $duk->safe_to_string(-1));

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

TEST_SAFE_CALL($duk, \&test_peval_file, 'test_peval_file');
TEST_SAFE_CALL($duk, \&test_peval_file_noresult, 'test_peval_file_noresult');
TEST_SAFE_CALL($duk, \&test_pcompile_file, 'test_pcompile_file');

test_stdout();

__DATA__
*** test_peval_file (duk_safe_call)
rc: 1
result: Error: no sourcecode
final top: 1
==> rc=0, result='undefined'
*** test_peval_file_noresult (duk_safe_call)
rc: 1
final top: 0
==> rc=0, result='undefined'
*** test_pcompile_file (duk_safe_call)
rc: 1
result: Error: no sourcecode
final top: 1
==> rc=0, result='undefined'
