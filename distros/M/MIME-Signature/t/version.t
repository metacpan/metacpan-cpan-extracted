#!perl -T
use 5.006;
use strict;
use warnings;
use Path::Tiny qw(path);
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

plan tests => 4;

use_ok('MIME::Signature');
ok MIME::Signature::__test_version(), 'version mismatch in POD';

ok open( my $changes, '<', 'Changes' ), 'open Changes';
$/ = '';
( undef, my $newest ) = <$changes>;
like $newest, qr/^\Q$MIME::Signature::VERSION\E\s/,
  'Changes file is up to date';

done_testing;
