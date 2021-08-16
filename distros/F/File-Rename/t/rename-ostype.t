use strict;
use warnings;
use Test::More;

plan skip_all => 'Need perl v5.14.0: no Perl::OSType' if $] < 5.014;
plan tests => 4;
require_ok 'Perl::OSType';
ok( Perl::OSType::os_type(), 'Perl::OSType::os_type' );
ok( Perl::OSType::is_os_type('Windows','MSWin32'), 'MSWin32 is Windows');
ok( !Perl::OSType::is_os_type('Windows','darwin'), 'darwin isn\'t Windows');

