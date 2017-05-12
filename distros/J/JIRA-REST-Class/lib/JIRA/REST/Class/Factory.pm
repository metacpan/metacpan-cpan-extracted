package JIRA::REST::Class::Factory;
use parent qw( Class::Factory::Enhanced );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A factory class for building all the other classes in L<JIRA::REST::Class|JIRA::REST::Class>.

#pod =head1 DESCRIPTION
#pod
#pod This module imports a hash of object type package names from L<JIRA::REST::Class::FactoryTypes|JIRA::REST::Class::FactoryTypes>.
#pod
#pod =cut

# we import the list of every class this factory knows how to make
#
use JIRA::REST::Class::FactoryTypes qw( %TYPES );
JIRA::REST::Class::Factory->add_factory_type( %TYPES );

use Carp;
use DateTime::Format::Strptime;

#pod =internal_method B<init>
#pod
#pod Initialize the factory object.  Just copies all the elements in the hashref that were passed in to the object itself.
#pod
#pod =cut

sub init {
    my $self = shift;
    my $args = shift;
    my @keys = keys %$args;
    @{$self}{@keys} = @{$args}{@keys};
    return $self;
}

#pod =internal_method B<get_factory_class>
#pod
#pod Inherited method from L<Class::Factory|Class::Factory/Factory_Methods>.
#pod
#pod =internal_method B<make_object>
#pod
#pod A tweaked version of C<make_object_for_type> from
#pod L<Class::Factory::Enhanced|Class::Factory::Enhanced/make_object_for_type>
#pod that calls C<init()> with a copy of the factory.
#pod
#pod =cut

sub make_object {
    my ( $self, $object_type, @args ) = @_;
    my $class = $self->get_factory_class( $object_type );
    my $obj   = $class->new( @args );
    $obj->init( $self );  # make sure we pass the factory into init()
    return $obj;
}

#pod =internal_method B<make_date>
#pod
#pod Make it easy to get L<DateTime|DateTime> objects from the factory. Parses
#pod JIRA date strings, which are in a format that can be parsed by the
#pod L<DateTime::Format::Strptime|DateTime::Format::Strptime> pattern
#pod C<%FT%T.%N%z>
#pod
#pod =cut

sub make_date {
    my ( $self, $date ) = @_;
    return unless $date;
    my $pattern = '%FT%T.%N%z';
    state $parser = DateTime::Format::Strptime->new( pattern => $pattern );
    return (
        $parser->parse_datetime( $date )
            or
            confess qq{Unable to parse date "$date" using pattern "$pattern"}
    );
}

#pod =internal_method B<factory_error>
#pod
#pod Throws errors from the factory with stack traces
#pod
#pod =cut

sub factory_error {
    my ( $class, $err, @args ) = @_;

    # start the stacktrace where we called make_object()
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::confess "$err\n", @args;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Factory - A factory class for building all the other classes in L<JIRA::REST::Class|JIRA::REST::Class>.

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This module imports a hash of object type package names from L<JIRA::REST::Class::FactoryTypes|JIRA::REST::Class::FactoryTypes>.

=head1 INTERNAL METHODS

=head2 B<init>

Initialize the factory object.  Just copies all the elements in the hashref that were passed in to the object itself.

=head2 B<get_factory_class>

Inherited method from L<Class::Factory|Class::Factory/Factory_Methods>.

=head2 B<make_object>

A tweaked version of C<make_object_for_type> from
L<Class::Factory::Enhanced|Class::Factory::Enhanced/make_object_for_type>
that calls C<init()> with a copy of the factory.

=head2 B<make_date>

Make it easy to get L<DateTime|DateTime> objects from the factory. Parses
JIRA date strings, which are in a format that can be parsed by the
L<DateTime::Format::Strptime|DateTime::Format::Strptime> pattern
C<%FT%T.%N%z>

=head2 B<factory_error>

Throws errors from the factory with stack traces

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::FactoryTypes|JIRA::REST::Class::FactoryTypes>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
