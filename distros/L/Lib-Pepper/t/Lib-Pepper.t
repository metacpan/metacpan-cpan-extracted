# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Lib-Pepper.t'

use strict;
use warnings;

use Test::More tests => 9;

# Test module loading
BEGIN {
    use_ok('Lib::Pepper');
    use_ok('Lib::Pepper::Constants', qw(:all));
}

# Test that constants are defined
ok(defined PEP_OPERATION_TRANSACTION, 'PEP_OPERATION_TRANSACTION constant defined');
ok(defined PEP_CURRENCY_EUR, 'PEP_CURRENCY_EUR constant defined');
ok(defined PEP_FUNCTION_RESULT_SUCCESS, 'PEP_FUNCTION_RESULT_SUCCESS constant defined');
ok(defined PEP_TERMINAL_TYPE_MOCK, 'PEP_TERMINAL_TYPE_MOCK constant defined');

# Test helper functions
ok(Lib::Pepper::isValidHandle(12345), 'isValidHandle returns true for non-invalid handle');
ok(!Lib::Pepper::isValidHandle(PEP_INVALID_HANDLE), 'isValidHandle returns false for invalid handle');
ok(Lib::Pepper::isSuccess(PEP_FUNCTION_RESULT_SUCCESS), 'isSuccess recognizes success code');

diag("Lib::Pepper version: $Lib::Pepper::VERSION");
diag("Successfully loaded all modules and constants");
