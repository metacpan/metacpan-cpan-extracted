use strict;
use warnings;

=head1 NAME

encode_decode.t - test of the encode/decode attributes on DustyDB::Filter

=cut

use Test::More tests => 11;
use_ok('DustyDB');

# Declare a model
package Rot13;
use DustyDB::Object;

sub rot13 {
    my $ALPHA = join '', ('A' .. 'Z');
    my $alpha = join '', ('a' .. 'z');
    my $APHLA = reverse $ALPHA;
    my $aphla = reverse $alpha;

    eval "tr/$ALPHA$alpha/$APHLA$aphla/";
    $_
}

has key name => (
    is     => 'rw',
    isa    => 'Str',
    encode => \&rot13,
    decode => \&rot13,
);

package main;

my $db = DustyDB->new( path => 't/encode_decode.db' );
ok($db, 'Loaded the database object');
isa_ok($db, 'DustyDB');

my $rot13 = $db->model('Rot13');

is(Rot13->meta->get_attribute_map->{name}->perform_encode('Testing'),
    'Gvhgrmt', 
    'perform_encode works');
is(Rot13->meta->get_attribute_map->{name}->perform_decode('Testing'),
    'Gvhgrmt', 
    'perform_decode works');

{
    my $rot13_thing = $rot13->create( name => 'Testing' );
    ok($rot13_thing, 'created Testing');
    is($rot13_thing->name, 'Testing', 'name is still Testing');
}

ok(defined $db->dbm->{'models'}{'Rot13'}{'Testing'}, 'key is Testing');
is($db->dbm->{'models'}{'Rot13'}{'Testing'}{'name'}, 'Gvhgrmt', 
    'Gvhgrmt is stored');

{
    my $rot13_thing = $rot13->load( name => 'Testing' );
    ok($rot13_thing, 'loaded Testing with Testing');
    is($rot13_thing->name, 'Testing', 'name is again Testing');
}

unlink 't/encode_decode.db';
