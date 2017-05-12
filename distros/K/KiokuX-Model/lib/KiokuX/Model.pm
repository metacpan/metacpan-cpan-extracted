package KiokuX::Model;
use Moose;
use MooseX::StrictConstructor;

use Carp qw(croak);

use KiokuDB;

use namespace::clean -except => 'meta';

our $VERSION = "0.02";

sub BUILD {
	my $self = shift;

	$self->directory;
}

has dsn => (
    isa => "Str",
    is  => "ro",
);

has extra_args => (
    isa => "HashRef|ArrayRef",
    is  => "ro",
	predicate => "has_extra_args",
);

has typemap => (
    isa => "KiokuDB::TypeMap",
    is  => "ro",
	predicate => "has_typemap",
);

has directory => (
    isa => "KiokuDB",
    lazy_build => 1,
    handles    => 'KiokuDB::Role::API',
);

sub _build_directory {
    my $self = shift;

	KiokuDB->connect(@{ $self->_connect_args });
}

has _connect_args => (
	isa => "ArrayRef",
	is  => "ro",
	lazy_build => 1,
);

sub _build__connect_args {
    my $self = shift;

	my @args = ( $self->dsn || croak "dsn is required" );

	if ( $self->has_typemap ) {
		push @args, typemap => $self->typemap;
	}

	if ( $self->has_extra_args ) {
		my $extra = $self->extra_args;

		if ( ref($extra) eq 'ARRAY' ) {
			push @args, @$extra;
		} else {
			push @args, %$extra;
		}
	}

	\@args;
}

sub connect {
	my ( $class, $dsn, @args ) = @_;

	$class->new( dsn => $dsn, extra_args => \@args );
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuX::Model - A simple application specific wrapper for L<KiokuDB>.

=head1 SYNOPSIS

	# start with the base class:

	KiokuX::Model->new( dsn => "bdb:dir=/var/myapp/db" );



	# later you can add convenience methods by subclassing:

	package MyApp::DB;
	use Moose;

	extends qw(KiokuX::Model);

	sub add_user {
		my ( $self, @args ) = @_;

		my $user = MyApp::User->new(@args);

		$self->txn_do(sub {
			$self->insert($user);
		});

		return $user;
	}


	# Then just use it like this:

	MyApp::DB->new( dsn => "bdb:dir=/var/myapp/db" );

	# or automatically using e.g. L<Catalyst::Model::KiokuDB>:

	$c->model("kiokudb");

=head1 DESCRIPTION

This base class makes it easy to create L<KiokuDB> database instances in your
application. It provides a standard way to instantiate and use a L<KiokuDB>
object in your apps.

As your app grows you can subclass it and provide additional convenience
methods, without changing the structure of the code, but simply swapping your
subclass for L<KiokuX::Model> in e.g. L<Catalyst::Model::KiokuDB> or whatever
you use to glue it in.

=head1 ATTRIBUTES

=over 4

=item directory

The instantiated directory.

Created using the other attributes at C<BUILD> time.

This attribute has delegations set up for all the methods of the L<KiokuDB>
class.

=item dsn

e.g. C<bdb:dir=root/db>. See L<KiokuDB/connect>.

=item extra_args

Additional arguments to pass to C<connect>.

Can be a hash reference or an array reference.

=item typemap

An optional custom typemap to add. See L<KiokuDB::Typemap> and
L<KiokuDB/typemap>.

=back

=head1 SEE ALSO

L<KiokuDB>, L<KiokuDB::Role::API>, L<Catalyst::Model::KiokuDB>

=head1 VERSION CONTROL

KiokuDB is maintained using Git. Information about the repository is available
on L<http://www.iinteractive.com/kiokudb/>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2009 Yuval Kogman, Infinity Interactive. All
    rights reserved This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=
