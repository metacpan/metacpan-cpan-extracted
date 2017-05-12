package DustyDB::Object;
our $VERSION = '0.06';

use Moose;
use Moose::Util;
use Moose::Util::MetaRole;

use DustyDB::Record;
use DustyDB::Meta::Class;
use DustyDB::Meta::Attribute;
use DustyDB::Meta::Instance;

use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    as_is => [ 'key' ],
    also  => 'Moose',
);

=head1 NAME

DustyDB::Object - use this class to declare a model to store

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  package Song;
  use DustyDB::Object;

  has key title => ( is => 'rw', isa => 'Str', required => 1 );
  has artist => ( is => 'rw', isa => 'Str' );

=head1 DESCRIPTION

This is a special L<Moose> extension that causes any module that uses it to become a model that may be stored in DustyDB. The class will automatically be given the methods and attributes of the L<DustyDB::Record> role. The meta-class will gain an additional meta-class role, L<DustyDB::Meta::Class>, containing the low-level storage routines. Finally, all the attributes will have additional features added through L<DustyDB::Meta::Attribute>, such as the ability to assign an encoder and decoder subroutine.

=begin Pod::Coverage

  init_meta

=end Pod::Coverage

=cut

sub init_meta {
    my ($class, %options) = @_;

    Moose->init_meta(%options);

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => $options{for_class},
        metaclass_roles           => [ 'DustyDB::Meta::Class' ],
        attribute_metaclass_roles => [ 'DustyDB::Meta::Attribute' ],
        instance_metaclass_roles  => [ 'DustyDB::Meta::Instance' ],
    );

    Moose::Util::apply_all_roles($options{for_class}, 'DustyDB::Record');

    return $options{for_class}->meta;
}

=head1 METHODS

=head2 key

  has key foo => ( is => 'rw', isa => 'Str' );

This provides some sugar for defining the key fields of your model. The above is essentially the same as:

  has foo => ( is => 'rw', isa => 'Str', traits => [ 'DustyDB::Key' ] );

=cut

sub key($%) {
    my ($column, %params) = @_;
    if ($params{traits}) {
        push @{ $params{traits} }, 'DustyDB::Key';
    }
    else {
        $params{traits} = [ 'DustyDB::Key' ];
    }
    return ($column, %params);
}

1;