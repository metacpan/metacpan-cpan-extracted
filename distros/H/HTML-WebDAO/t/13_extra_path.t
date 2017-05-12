package TestContainer;
use strict;
use warnings;
use HTML::WebDAO::Container;
use base 'HTML::WebDAO::Container';

1;

package TestTraverse;
use strict;
use warnings;
use HTML::WebDAO::Component;
use base 'HTML::WebDAO::Component';

sub test {
    my $self = shift;
    return $self;
}

sub return1 {
    my $self = shift;
    return 1;
}

sub index_x {
    my $self = shift;
    return $self;
}

1;

package main;
use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 15;
#use Test::More qw(no_plan);

BEGIN {
    use_ok('HTML::WebDAO::Store::Abstract');
    use_ok('HTML::WebDAO::SessionSH');
    use_ok('HTML::WebDAO::Engine');
    use_ok('HTML::WebDAO::Container');
}

my $ID = "extra";
ok my $store_ab = ( new HTML::WebDAO::Store::Abstract:: ), "Create store";
ok my $session = ( new HTML::WebDAO::SessionSH:: store => $store_ab ),
  "Create session";
$session->U_id($ID);

my $eng = new HTML::WebDAO::Engine:: session => $session;

our $sess = $eng->_session;
our $eng1 = $eng;

sub path2obj {
    my $path = shift;
    my @path = grep { $_ } @{ $sess->call_path($path) };
    return $eng1->_get_object_by_path( \@path );
}

$eng->register_class(
    'HTML::WebDAO::Container' => 'testmain',
    'TestTraverse'            => 'traverse',
    'TestContainer'           => 'testcont'
);

#test traverse

my $main = $eng->_createObj( 'main2', 'testmain' );
$eng->_add_childs($main);
isa_ok my $trav_obj = $eng->_createObj( 'traverse', 'traverse' ),
  'TestTraverse', 'create traverse object';
$main->_add_childs($trav_obj);
$trav_obj->__extra_path( [ 1, 2, 3 ] );
my $traverse_url = $trav_obj->url_method('test');
isa_ok $eng->resolve_path( $sess, $traverse_url ), 'TestTraverse',
  "resolve_path1 $traverse_url";
my $traverse_url1 = $trav_obj->url_method();
isa_ok $eng->resolve_path( $sess, $traverse_url1 ), 'TestTraverse',
  "resolve_path2 $traverse_url1";
isa_ok my $t_cont1 = $eng->_createObj( 'test_cont', 'testcont' ),
  'TestContainer', 'test containter';
$t_cont1->__extra_path( [ 1, 2, 3 ] );
isa_ok my $comp = $eng->_createObj( 'el1', 'traverse' ), 'TestTraverse',
  'create elem';
$t_cont1->_add_childs($comp);
$eng->_add_childs($t_cont1);
my $t_url = $comp->url_method('return1');
is $eng->resolve_path( $sess, $t_url )->html, 1, "test resolve $t_url";
isa_ok my $comp1 = $eng->_createObj( 'el_extra', 'traverse' ), 'TestTraverse',
  'create elem with extra1';
$comp1->__extra_path( [ 'extra1', 'extra2' ] );
$t_cont1->_add_childs($comp1);
my $t_url2 = $comp1->url_method('return1');
is $eng->resolve_path( $sess, $t_url2 )->html, 1, "test resolve $t_url2";
my $t_url3 = $comp1->url_method();
isa_ok $eng->resolve_path( $sess, $t_url3 ), 'TestTraverse',
  "test resolve $t_url3";

