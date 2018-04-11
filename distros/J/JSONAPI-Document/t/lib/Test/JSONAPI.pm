package Test::JSONAPI;

use Moo;
extends 'JSONAPI::Document';

use Test::JSONAPI::Schema;
use Test::DBIx::Class qw(:resultsets);
use File::Spec;

has schema => (
    is => 'ro',
    isa => sub {
        die "$_[0] is not an instance of 'Test::JSONAPI::Schema'" unless ref($_[0]) eq 'Test::JSONAPI::Schema';
    },
    lazy => 1,
    builder => '_build_schema'
);

has '+data_dir' => (
    required => 0,
    is => 'lazy',
);

sub _build_data_dir {
    my $filename = File::Spec->rel2abs(__FILE__);
    $filename =~ s|lib/.+||;
    $filename .= 'share/';
    return $filename;
}

sub _build_schema {
    fixtures_ok 'basic' => 'Installed the basic fixtures';
    return Schema;
}

sub DESTROY {
	my ($self) = @_;
	$self->chi->clear();
}

__PACKAGE__->meta->make_immutable();
1;
