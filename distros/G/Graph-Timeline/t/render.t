#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use_ok('Graph::Timeline::GD');

################################################################################
# Create a new object
################################################################################

my $x = Graph::Timeline::GD->new();

isa_ok( $x, 'Graph::Timeline::GD' );

################################################################################
# Add some data
################################################################################

$x->add_interval( label => 'Pius VI',     start => '1717/12/25', end => '1799/08/28', group => 'popes' );
$x->add_interval( label => 'Pius VII',    start => '1742/04/14', end => '1823/07/20', group => 'popes' );
$x->add_interval( label => 'Leo XII',     start => '1760/08/22', end => '1829/02/10', group => 'popes' );
$x->add_interval( label => 'Pius VIII',   start => '1761/11/20', end => '1830/11/20', group => 'popes' );
$x->add_interval( label => 'Gregory XVI', start => '1765/09/18', end => '1846/06/01', group => 'popes' );
$x->add_interval( label => 'Pius IX',     start => '1792/05/13', end => '1878/02/07', group => 'popes' );
$x->add_interval( label => 'Leo XIII',    start => '1810/03/02', end => '1903/07/20', group => 'popes' );
$x->add_interval( label => 'Pius X',      start => '1835/06/02', end => '1914/08/20', group => 'popes' );
$x->add_interval( label => 'Benedict XV', start => '1854/11/21', end => '1922/01/22', group => 'popes' );
$x->add_interval( label => 'Pius XI',     start => '1857/05/31', end => '1939/02/10', group => 'popes' );
$x->add_interval( label => 'Pius XII',    start => '1876/03/02', end => '1958/10/09', group => 'popes' );
$x->add_interval( label => 'John XXIII',  start => '1881/11/25', end => '1963/06/03', group => 'popes' );
$x->add_interval( label => 'Paul VI',     start => '1897/09/26', end => '1978', group => 'popes' );
$x->add_interval( label => 'John Paul I', start => '1912', end => '1978/09/28', group => 'popes' );

$x->add_point( label => 'Peter Hickman born',    start => '1961/04/22' );
$x->add_point( label => 'Spitnik 1 launched',    start => '1957/10/04' );
$x->add_point( label => 'Explorer 1 launched',   start => '1958/01/31' );
$x->add_point( label => 'Yuri Gagarin in space', start => '1961/04/12' );
$x->add_point( label => 'Elvis Presley dies',    start => '1977/08/16' );
$x->add_point( label => 'Albert Einstein born',  start => '1879/03/14' );
$x->add_point( label => 'Albert Einstein dies',  start => '1955/04/18' );
$x->add_point( label => 'Nazi Book Burnings',    start => '1933/05/10' );

################################################################################
# Fail a few tests first
################################################################################

$x->window();

eval { $x->render(); };
like( $@, qr/^Timeline::GD->render\(\) one of 'pixelsperday', 'pixelspermonth' or 'pixelsperyear' must be defined /, 'Missing arguments' );

eval { $x->render('dummy'); };
like( $@, qr/^Timeline::GD->render\(\) expected HASH as parameter at /, 'Missing arguments' );

eval { $x->render( pixelspersecond => 1 ); };
like( $@, qr/^Timeline->render\(\) invalid key 'pixelspersecond' passed as data /, 'Missing arguments' );

eval { $x->render( pixelsperday => 1, pixelsperyear => 1 ); };
like( $@, qr/^Timeline::GD->render\(\) only one of 'pixelsperday', 'pixelspermonth' or 'pixelsperyear' can be defined /, 'Missing arguments' );

################################################################################
# Render the image
################################################################################

foreach my $type (qw/pixelsperday pixelspermonth pixelsperyear/) {
    my $image = $x->render( $type => 1 );
}

my $image = $x->render( pixelsperyear => 30, border => 2 );

################################################################################
# Fail to render the image
################################################################################

$x->window( start => '1500/01/01', end => '1500/12/31' );

eval { $x->render( pixelsperyear => 30, border => 2 ); };
like( $@, qr/^Timeline::GD->render\(\) there is no data to render /, 'Failed to render' );

# vim: syntax=perl:
