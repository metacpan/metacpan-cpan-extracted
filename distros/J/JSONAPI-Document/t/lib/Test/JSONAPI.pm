package Test::JSONAPI;

use Moo;
extends 'JSONAPI::Document';

use Test::JSONAPI::Schema;
use Test::DBIx::Class qw(:resultsets);

has schema => (
	is => 'ro',
	isa => sub {
		die "$_[0] is not an instance of 'Test::JSONAPI::Schema'" unless ref($_[0]) eq 'Test::JSONAPI::Schema';
	},
	lazy => 1,
	builder => '_build_schema'
);

sub _build_schema {
    fixtures_ok 'basic' => 'Installed the basic fixtures';
    return Schema;
}

__PACKAGE__->meta->make_immutable();
1;
