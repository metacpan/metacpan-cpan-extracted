use strict;
use warnings;

=head1 NAME

stringify.t - test of the stringify attribute on DustyDB::Key

=cut

use Test::More tests => 9;
use_ok('DustyDB');

# Declare a model
package Rot13;
use DustyDB::Object;

has key name => (
    is => 'rw',
    isa => 'Str',
    stringify => sub {
        my $ALPHA = join '', ('A' .. 'Z');
        my $alpha = join '', ('a' .. 'z');
        my $APHLA = reverse $ALPHA;
        my $aphla = reverse $alpha;

        eval "tr/$ALPHA$alpha/$APHLA$aphla/";
        $_
    },
);

package main;

my $db = DustyDB->new( path => 't/stringify.db' );
ok($db, 'Loaded the database object');
isa_ok($db, 'DustyDB');

my $rot13 = $db->model('Rot13');

is(Rot13->meta->get_attribute_map->{name}->perform_stringify('Testing'),
    'Gvhgrmt', 
    'perform_stringify works');

{
    my $rot13_thing = $rot13->create( name => 'Testing' );
    ok($rot13_thing, 'created Testing');
    is($rot13_thing->name, 'Testing', 'name is still Testing');
}

ok(defined $db->dbm->{'models'}{'Rot13'}{'Gvhgrmt'}, 'Gvhgrmt is stored');

{
    my $rot13_thing = $rot13->load( name => 'Testing' );
    ok($rot13_thing, 'loaded Testing with Testing');
    is($rot13_thing->name, 'Testing', 'name is again Testing');
}

unlink 't/stringify.db';
