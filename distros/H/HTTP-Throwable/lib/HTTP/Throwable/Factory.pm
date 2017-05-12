package HTTP::Throwable::Factory;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Factory::VERSION = '0.026';
use strict;
use warnings;

use HTTP::Throwable::Variant;

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => [
    http_throw     => Sub::Exporter::Util::curry_method('throw'),
    http_exception => Sub::Exporter::Util::curry_method('new_exception'),
  ],
};
use Module::Runtime;


sub throw {
    my $factory = shift;
    my $ident   = (! ref $_[0]) ? shift(@_) : undef;
    my $arg     = shift || {};

    $factory->class_for($ident, $arg)->throw($arg);
}

sub new_exception {
    my $factory = shift;
    my $ident   = (! ref $_[0]) ? shift(@_) : undef;
    my $arg     = shift || {};

    $factory->class_for($ident, $arg)->new($arg);
}

sub core_roles {
    return qw(
        HTTP::Throwable
    );
}

sub extra_roles {
    return qw(
        HTTP::Throwable::Role::TextBody
    );
}

sub roles_for_ident {
    my ($self, $ident) = @_;

    Carp::confess("roles_for_ident called with undefined ident")
      unless defined $ident;

    Carp::confess("roles_for_ident called with empty ident string")
      unless length $ident;

    return "HTTP::Throwable::Role::Status::$ident";
}

sub roles_for_no_ident {
    my ($self, $ident) = @_;

    return qw(
        HTTP::Throwable::Role::Generic
        HTTP::Throwable::Role::BoringText
    );
}

sub base_class { () }

sub class_for {
    my ($self, $ident) = @_;

    my @roles;
    if (defined $ident) {
        if ($ident =~ /\A[0-9]{3}\z/) {
          @roles = $self->roles_for_status_code($ident);
        } else {
          @roles = $self->roles_for_ident($ident);
        }
    } else {
        @roles = $self->roles_for_no_ident;
    }

    Module::Runtime::use_module($_) for @roles;

    my $class = HTTP::Throwable::Variant->build_variant(
        superclasses => [ $self->base_class ],
        roles        => [
          $self->core_roles,
          $self->extra_roles,
          @roles
        ],
    );

    return $class;
}

my %lookup = (
    300 => 'MultipleChoices',
    301 => 'MovedPermanently',
    302 => 'Found',
    303 => 'SeeOther',
    304 => 'NotModified',
    305 => 'UseProxy',
    307 => 'TemporaryRedirect',

    400 => 'BadRequest',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'NotFound',
    405 => 'MethodNotAllowed',
    406 => 'NotAcceptable',
    407 => 'ProxyAuthenticationRequired',
    408 => 'RequestTimeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'LengthRequired',
    412 => 'PreconditionFailed',
    413 => 'RequestEntityTooLarge',
    414 => 'RequestURITooLong',
    415 => 'UnsupportedMediaType',
    416 => 'RequestedRangeNotSatisfiable',
    417 => 'ExpectationFailed',

    500 => 'InternalServerError',
    501 => 'NotImplemented',
    502 => 'BadGateway',
    503 => 'Status::ServiceUnavailable',
    504 => 'GatewayTimeout',
    505 => 'HTTPVersionNotSupported',
);

sub roles_for_status_code {
    my ($self, $code) = @_;

    my $ident = $lookup{$code};
    return $self->roles_for_ident($ident);
}

1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Factory - a factory that throws HTTP::Throwables for you

=head1 VERSION

version 0.026

=head1 OVERVIEW

L<HTTP::Throwable> is a role that makes it easy to build exceptions that, once
thrown, can be turned into L<PSGI>-style HTTP responses.  Because
HTTP::Throwable and all its related roles are, well, roles, they can't be
instantiated or thrown directly.  Instead, they must be built into classes
first.  HTTP::Throwable::Factory takes care of this job, building classes out
of the roles you need for the exception you want to throw.

You can use the factory to either I<build> or I<throw> an exception of either a
I<generic> or I<specific> type.  Building and throwing are very similar -- the
only difference is whether or not the newly built object is thrown or returned.
To throw an exception, use the C<throw> method on the factory.  To return it,
use the C<new_exception> method.  In the examples below, we'll just use
C<throw>.

To throw a generic exception -- one where you must specify the status code and
reason, and any other headers -- you pass C<throw> a hashref of arguments that
will be passed to the exception class's constructor.

  HTTP::Throwable::Factory->throw({
      status_code => 301,
      reason      => 'Moved Permanently',
      additional_headers => [
        Location => '/new',
      ],
  });

To throw a specific type of exception, include an exception type identifier,
like this:

  HTTP::Throwable::Factory->throw(MovedPermanently => { location => '/new' });

The type identifier is (by default) the end of a role name in the form
C<HTTP::Throwable::Role::Status::IDENTIFIER>.  The full list of such included
roles is given in L<the HTTP::Throwable docs|HTTP::Throwable/WELL-KNOWN TYPES>.

=head2 Exports

You can import routines called C<http_throw> and C<http_exception> that work
like the C<throw> and C<new_exception> methods, respectively, but are not
called as methods.  For example:

  use HTTP::Throwable::Factory 'http_exception';

  builder {
      mount '/old' => http_exception('Gone'),
  };

=head1 SUBCLASSING

One of the big benefits of using HTTP::Throwable::Factory is that you can
subclass it to change the kind of exceptions it provides.

If you subclass it, you can change its behavior by overriding the following
methods -- provided in the order of likelihood that you'd want to override
them, most likely first.

=head2 extra_roles

This method returns a list of role names that will be included in any class
built by the factory.  By default, it includes only
L<HTTP::Throwable::Role::TextBody> to satisfy HTTP::Throwable's requirements
for methods needed to build a body.

This is the method you're most likely to override in a subclass.

=head2 roles_for_ident

=head2 roles_for_status_code

=head2 roles_for_no_ident

This methods convert the exception type identifier to a role to apply.  For
example, if you call:

  Factory->throw(NotFound => { ... })

...then C<roles_for_ident> is called with "NotFound" as its argument.
C<roles_for_status_code> is used if the string is three ASCII digits.

If C<throw> is called I<without> a type identifier, C<roles_for_no_ident> is
called.

By default, C<roles_for_ident> returns C<HTTP::Throwable::Role::Status::$ident>
and C<roles_for_no_ident> returns L<HTTP::Throwable::Role::Generic> and
L<HTTP::Throwable::Role::BoringText>.

=head2 base_class

This is the base class that will be subclassed and into which all the roles
will be composed.  By default, it is L<Moo::Object>, the universal base Moo
class.

=head2 core_roles

This method returns the roles that are expected to be applied to every
HTTP::Throwable exception.  This method's results might change over time, and
you are encouraged I<B<not>> to alter it.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: a factory that throws HTTP::Throwables for you

#pod =head1 OVERVIEW
#pod
#pod L<HTTP::Throwable> is a role that makes it easy to build exceptions that, once
#pod thrown, can be turned into L<PSGI>-style HTTP responses.  Because
#pod HTTP::Throwable and all its related roles are, well, roles, they can't be
#pod instantiated or thrown directly.  Instead, they must be built into classes
#pod first.  HTTP::Throwable::Factory takes care of this job, building classes out
#pod of the roles you need for the exception you want to throw.
#pod
#pod You can use the factory to either I<build> or I<throw> an exception of either a
#pod I<generic> or I<specific> type.  Building and throwing are very similar -- the
#pod only difference is whether or not the newly built object is thrown or returned.
#pod To throw an exception, use the C<throw> method on the factory.  To return it,
#pod use the C<new_exception> method.  In the examples below, we'll just use
#pod C<throw>.
#pod
#pod To throw a generic exception -- one where you must specify the status code and
#pod reason, and any other headers -- you pass C<throw> a hashref of arguments that
#pod will be passed to the exception class's constructor.
#pod
#pod   HTTP::Throwable::Factory->throw({
#pod       status_code => 301,
#pod       reason      => 'Moved Permanently',
#pod       additional_headers => [
#pod         Location => '/new',
#pod       ],
#pod   });
#pod
#pod To throw a specific type of exception, include an exception type identifier,
#pod like this:
#pod
#pod   HTTP::Throwable::Factory->throw(MovedPermanently => { location => '/new' });
#pod
#pod The type identifier is (by default) the end of a role name in the form
#pod C<HTTP::Throwable::Role::Status::IDENTIFIER>.  The full list of such included
#pod roles is given in L<the HTTP::Throwable docs|HTTP::Throwable/WELL-KNOWN TYPES>.
#pod
#pod =head2 Exports
#pod
#pod You can import routines called C<http_throw> and C<http_exception> that work
#pod like the C<throw> and C<new_exception> methods, respectively, but are not
#pod called as methods.  For example:
#pod
#pod   use HTTP::Throwable::Factory 'http_exception';
#pod
#pod   builder {
#pod       mount '/old' => http_exception('Gone'),
#pod   };
#pod
#pod =head1 SUBCLASSING
#pod
#pod One of the big benefits of using HTTP::Throwable::Factory is that you can
#pod subclass it to change the kind of exceptions it provides.
#pod
#pod If you subclass it, you can change its behavior by overriding the following
#pod methods -- provided in the order of likelihood that you'd want to override
#pod them, most likely first.
#pod
#pod =head2 extra_roles
#pod
#pod This method returns a list of role names that will be included in any class
#pod built by the factory.  By default, it includes only
#pod L<HTTP::Throwable::Role::TextBody> to satisfy HTTP::Throwable's requirements
#pod for methods needed to build a body.
#pod
#pod This is the method you're most likely to override in a subclass.
#pod
#pod =head2 roles_for_ident
#pod
#pod =head2 roles_for_status_code
#pod
#pod =head2 roles_for_no_ident
#pod
#pod This methods convert the exception type identifier to a role to apply.  For
#pod example, if you call:
#pod
#pod   Factory->throw(NotFound => { ... })
#pod
#pod ...then C<roles_for_ident> is called with "NotFound" as its argument.
#pod C<roles_for_status_code> is used if the string is three ASCII digits.
#pod
#pod If C<throw> is called I<without> a type identifier, C<roles_for_no_ident> is
#pod called.
#pod
#pod By default, C<roles_for_ident> returns C<HTTP::Throwable::Role::Status::$ident>
#pod and C<roles_for_no_ident> returns L<HTTP::Throwable::Role::Generic> and
#pod L<HTTP::Throwable::Role::BoringText>.
#pod
#pod =head2 base_class
#pod
#pod This is the base class that will be subclassed and into which all the roles
#pod will be composed.  By default, it is L<Moo::Object>, the universal base Moo
#pod class.
#pod
#pod =head2 core_roles
#pod
#pod This method returns the roles that are expected to be applied to every
#pod HTTP::Throwable exception.  This method's results might change over time, and
#pod you are encouraged I<B<not>> to alter it.
