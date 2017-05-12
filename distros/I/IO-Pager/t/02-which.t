use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();
use Env qw( PAGER );

use IO::Pager;

my $pager;

# Find anything that looks like a pager, unspecified
$PAGER = undef;
$pager = IO::Pager::find_pager();
ok $pager, 'Undefined PAGER';

# Find anything that looks like a pager 2, this is redundant
$PAGER = '';
$pager = IO::Pager::find_pager();
ok $pager, 'Blank PAGER';

# Find anything that looks like a pager 3, bad initial setting
$PAGER = 'asdfghjk666';
$pager = IO::Pager::find_pager();
isnt $pager, 'asdfghjk666', 'PAGER does not exist';

# Perl is sure to be present, pretend it's a pager specified w/ absolute path
$PAGER = perl_path();
$pager = IO::Pager::find_pager();
is $pager, perl_path(), 'PAGER referred by its full-path';

# Perl is sure to be present, pretend it's a pager specified w/o path
SKIP: {
  skip_no_file_which();
  $PAGER = perl_exe();
  skip_not_in_path($PAGER);
  $pager = IO::Pager::find_pager();
  like $pager, qr/perl/i, 'PAGER is referred by its executable name';
}

# Verify that options set in the PAGER variable are preserved
$PAGER = perl_path().' -w';
$pager = IO::Pager::find_pager();
is $pager, perl_path().' -w', 'PAGER with options';

done_testing;
