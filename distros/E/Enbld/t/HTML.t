#!perl

use strict;
use warnings;

use Test::More;

require_ok( 'Enbld::HTML' );

my $html = Enbld::HTML->new( do { local $/; <DATA> } );

my $list = $html->parse_version(
        '<a href="http://www.example.com/archive-\d\.\d{2}\.tar\.gz">',
        '\d\.\d{2}'
        );

ok( grep { $_ eq '1.10' } @{ $list} , 'version exists' );

my $empty = Enbld::HTML->new( '' );
my $empty_list = $empty->parse_version(
        '<a href="http://www.example.com/archive-\d\.\d{2}\.tar\.gz',
        '\d\.\d{2}'
        );

is( $empty_list, undef, q{can't parse version string} );

done_testing();

__DATA__
<html>
<body>
<a href="http://www.example.com/archive-1.00.tar.gz">archive-1.00.tar.gz</a>
<a href="http://www.example.com/archive-1.10.tar.gz">archive-1.10.tar.gz</a>
</body>
</html>
