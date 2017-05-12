
use strict;
use warnings;

use Test::More tests => 30;
use Test::NoWarnings;

use lib './lib';
use File::Util;

my $ftl;

# one recognized instantiation setting
$ftl = File::Util->new( use_flock => 0 );
is ref $ftl, 'File::Util',
   'new() is blessed correctly after flock toggle invocation';

is $ftl->use_flock() , 0,
   'flock off-toggle sticks after blessing';

# another recognized instantiation setting
$ftl = File::Util->new( readlimit => 1234567890 );
is ref $ftl, 'File::Util',
   'new() is blessed correctly after readlimit-set invocation';

cmp_ok $ftl->readlimit , '==', 1234567890,
   'readlimit (legacy) setting sticks after blessing';

cmp_ok $ftl->read_limit , '==', 1234567890,
   'read_limit (new-style) setting sticks after blessing';

# yet another recognized instantiation setting
$ftl = File::Util->new( abort_depth => 9876543210 );
is ref $ftl, 'File::Util',
   'new() is blessed right after abort_depth-set invocation';

cmp_ok $ftl->abort_depth, '==', 9876543210,
   'abort_depth toggle sticks after abort_depth-set invocation';

# all recognized per-instantiation settings
$ftl = File::Util->new
(
   use_flock  => 1,
   read_limit => 1111111,
   abort_depth  => 2222222
);

is ref $ftl, 'File::Util',
   'new() blessed right with multi-toggle';

is $ftl->use_flock() , 1,
   'use_flock sticks after multi-toggle';

cmp_ok $ftl->readlimit, '==', 1111111,
   'readlimit (legacy) sticks after multi-toggle blessing';

cmp_ok $ftl->read_limit, '==', 1111111,
   'read_limit (new-style) sticks after multi-toggle blessing';

cmp_ok $ftl->abort_depth, '==', 2222222,
   'abort_depth sticks after multi-toggle blessing';

# one recognized flag
$ftl = File::Util->new( '--fatals-as-warning' );

is ref $ftl, 'File::Util',
   'new() blessed right with fatals toggle';

cmp_ok $ftl->{opts}{fatals_as_warning}, '==', 1,
   'modern internal setting matches toggle';

cmp_ok $ftl->{opts}{'--fatals-as-warning'}, '==', 1,
   'classic internal setting matches toggle';

# another recognized flag
$ftl = File::Util->new( '--fatals-as-status' );

is ref $ftl, 'File::Util', 'blessed ok after classic instantiation';

is $ftl->{opts}{fatals_as_status}, 1,
   'peek at internals looks good for "fatals_as_status"';

is $ftl->{opts}{'--fatals-as-status'}, 1,
   'peek at internals looks good for "--fatals_as_status"';

# yet another recognized flag
$ftl = File::Util->new( '--fatals-as-errmsg' );

is ref $ftl, 'File::Util', 'blessed ok after classic instantiation';

is $ftl->{opts}{fatals_as_errmsg}, 1,
   'peek at internals looks good for "fatals_as_errmsg"';

is $ftl->{opts}{'--fatals-as-errmsg'}, 1,
   'peek at internals looks good for "--fatals-as-errmsg"';

# all settings and one recognized flag, using ::Modern syntax
$ftl = File::Util->new(
   {
      use_flock => 0,
      readlimit => 1111111,
      abort_depth => 2222222,
      fatals_as_status => 1,
      warn_also => 1
   }
);

is ref $ftl, 'File::Util',
   'blessed ok after modern instantiation with multiple opts';

is $ftl->use_flock(), 0,
   'flock toggle correct after modern multi-opt instantiation';

cmp_ok $ftl->readlimit(), '==', 1111111,
   'readlimit setting correct after modern multi-opt instantiation';

cmp_ok $ftl->abort_depth(), '==', 2222222,
   'abort_depth setting correct after modern multi-opt instantiation';

is $ftl->{opts}{fatals_as_status}, 1,
   'peek at internals ok for "fatals_as_status"';

is $ftl->{opts}{warn_also}, 1,
   'peek at internals ok for "warn_also"';

is $ftl->{opts}{fatals_as_warning}, undef,
   'peek at internals ok for !defined "fatals_as_warning"';

is $ftl->{opts}{fatals_as_errmsg}, undef,
   'peek at internals ok for !defined "fatals_as_errmsg"';

exit;
