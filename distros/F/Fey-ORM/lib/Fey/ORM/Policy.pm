package Fey::ORM::Policy;

use strict;
use warnings;

our $VERSION = '0.47';

use Fey::Object::Policy;

{
    my @subs;

    BEGIN {
        @subs = qw(
            Policy
            transform_all
            matching
            inflate
            deflate
            has_one_namer
            has_many_namer
        );
    }

    use Sub::Exporter -setup => {
        exports => \@subs,
        groups  => { default => \@subs },
    };
}

## no critic (Subroutines::ProhibitSubroutinePrototypes)

# I could use MooseX::ClassAttribute and add a class attribute to the
# calling class, but really, that class doesn't need to use Moose,
# since it's just a name we can use to find the associated policy
# object.
{
    my %Policies;

    sub Policy {
        my $caller = shift;

        return $Policies{$caller} ||= Fey::Object::Policy->new();
    }
}

sub transform_all {
    my $class = caller();

    $class->Policy()->add_transform( {@_} );
}

sub matching (&) {
    return ( matching => $_[0] );
}

sub inflate (&) {
    return ( inflate => $_[0] );
}

sub deflate (&) {
    return ( deflate => $_[0] );
}

sub has_one_namer (&) {
    my $class = caller();

    $class->Policy()->set_has_one_namer( $_[0] );
}

sub has_many_namer (&) {
    my $class = caller();

    $class->Policy()->set_has_many_namer( $_[0] );
}

1;

# ABSTRACT: Declarative policies for Fey::ORM using classes

__END__

=pod

=head1 NAME

Fey::ORM::Policy - Declarative policies for Fey::ORM using classes

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::Policy;

  use strict;
  use warnings;

  use Fey::ORM::Policy;
  use Lingua::EN::Inflect qw( PL_N );

  transform_all
         matching { $_[0]->type() eq 'date' }

      => inflate  { return unless defined $_[1];
                    return DateTime::Format::Pg->parse_date( $_[1] ) }

      => deflate  { defined $_[1] && ref $_[1]
                      ? DateTime::Format::Pg->format_date( $_[1] )
                      : $_[1] };

  transform_all
         matching { $_[0]->name() eq 'email_address' }

      => inflate  { return unless defined $_[1];
                    return Email::Address->parse( $_[1] ) }

      => deflate  { defined $_[1] && ref $_[1]
                      ? Email::Address->as_string
                      : $_[1] };

  has_one_namer  { my $name = $_[0]->name();
                   my @parts = map { lc } ( $name =~ /([A-Z][a-z]+)/g );

                   return join q{_}, @parts; };

  has_many_namer { my $name = $_[0]->name();
                   my @parts = map { lc } ( $name =~ /([A-Z][a-z]+)/g );

                   $parts[-1] = PL_N( $parts[-1] );

                   return join q{_}, @parts; };

  package User;

  use Fey::ORM::Table;

  has_policy 'MyApp::Policy';

  has_table ...;

=head1 DESCRIPTION

This module allows you to declare a policy for your
L<Fey::ORM::Table>-using classes.

A policy can define transform rules which can be applied to matching
columns, as well as a naming scheme for has_one and has_many
methods. This allows you to spare yourself some drudgery, and allows
you to consolidate decisions (like "all date type columns return a
C<DateTime> object") in a single place.

=head1 FUNCTIONS

This module exports a bunch of sugar functions into your namespace so
you can define your policy in a declarative manner:

=head2 transform_all

This should be followed by a C<matching> sub reference, and one of an
C<inflate> or C<deflate> sub.

=head2 matching { ... }

This function takes a subroutine reference that will be called and
passed a L<Fey::Column> object as its argument. This sub should look
at the column and return true if the associated inflate/deflate should
be applied to the column.

Note that the matching subs are checked in the order they are defined
by C<transform_all()>, and the first one wins.

=head2 inflate { ... }

An inflator sub for the associated transform. See L<Fey::ORM::Table>
for more details on transforms.

=head2 deflate { ... }

A deflator sub for the associated transform. See L<Fey::ORM::Table>
for more details on transforms.

=head2 has_one_namer { ... }

A subroutine reference which will be used to generate a name for
C<has_one()> methods when a name is not explicitly provided.

This sub will receive the foreign table as its first argument, and the
associated FK object as the second argument. In most cases, the foreign table
will probably be sufficient to generate a name.

=head2 has_many_namer { ... }

Just like the C<has_one_namer()>, but is called for naming
C<has_many()> methods.

=head2 Policy

This methods returns the L<Fey::Object::Policy> object for your policy
class. This method allows L<Fey::ORM::Table> to go get a policy object
from a policy class name.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
