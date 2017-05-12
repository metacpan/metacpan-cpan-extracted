use strict;
use warnings;
use Test::More tests => 5;
use File::Spec;
use Devel::Unplug;
use lib 't/lib';

sub is_unplugged($;$) {
    my ( $list, $desc ) = @_;
    $desc ||= join( ', ', @$list );
    my @unp = Devel::Unplug::unplugged();
    is_deeply [ sort @unp ], [ sort @$list ], $desc;
}

Devel::Unplug::unplug( 'Some::Module', qr{^Other::} ) for 1 .. 2;
is_unplugged [ 'Some::Module', qr{^Other::} ], "unplugged";
Devel::Unplug::insert( 'Some::Module' );
is_unplugged [ 'Some::Module', qr{^Other::} ], "insert 1";
Devel::Unplug::insert( qr{^Other::} );
is_unplugged [ 'Some::Module', qr{^Other::} ], "insert 2";
Devel::Unplug::insert( 'Some::Module' );
is_unplugged [qr{^Other::}], "insert 3";
Devel::Unplug::insert( qr{^Other::} );
is_unplugged [], "insert 4";
