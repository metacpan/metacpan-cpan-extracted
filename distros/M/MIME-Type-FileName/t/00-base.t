# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
BEGIN { use_ok('MIME::Type::FileName') };
use warnings;
use strict;

my $mimetype = MIME::Type::FileName::guess ("my-file.xls");
is ($mimetype, 'application/vnd.ms-excel');

$mimetype = MIME::Type::FileName::guess ("my-file.blah");
is ($mimetype, 'application/octet-stream');

$mimetype = MIME::Type::FileName::guess ("MYFILE.XLS");
is ($mimetype, 'application/vnd.ms-excel');

$mimetype = MIME::Type::FileName::guess ("MYFILE.FOOBLAH");
is ($mimetype, 'application/octet-stream');

$mimetype = MIME::Type::FileName::guess ("MYFILE.FOOBLAH.XLS");
is ($mimetype, 'application/vnd.ms-excel');

Test::More::done_testing();
