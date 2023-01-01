package HTTP::Throwable::Role::Status::MethodNotAllowed 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Type::Utils qw(subtype as where enum);
use Types::Standard qw(ArrayRef);
use List::Util 1.45 qw[ uniq ];

use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

my $method_enum_type = enum "HttpThrowableTypeMethod" => [ qw[
    OPTIONS GET HEAD
    POST PUT DELETE
    TRACE CONNECT
] ];

# TODO: Consider adding a coersion to upper-case lower-cased strings and to
# uniq the given input.  -- rjbs, 2011-02-21
my $method_list_type = subtype "HttpThrowableTypeMethodList",
    as ArrayRef[ $method_enum_type ],
    where { (scalar uniq @{$_}) == (scalar @{$_}) };

sub default_status_code { 405 }
sub default_reason      { 'Method Not Allowed' }

has 'allow' => (
    is       => 'ro',
    isa      => $method_list_type,
    required => 1
);

around 'build_headers' => sub {
    my $next    = shift;
    my $self    = shift;
    my $headers = $self->$next( @_ );
    push @$headers => ('Allow' => join "," => @{ $self->allow });
    $headers;
};


no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::MethodNotAllowed - 405 Method Not Allowed

=head1 VERSION

version 0.028

=head1 DESCRIPTION

The method specified in the Request-Line is not allowed for the
resource identified by the Request-URI. The response MUST include
an Allow header containing a list of valid methods for the requested
resource.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 allow

This is an ArrayRef of HTTP methods, it is required and the HTTP
methods will be type checked to ensure validity and uniqueness.

=head1 SEE ALSO

HTTP Methods - L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html>

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <cpan@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 405 Method Not Allowed

#pod =head1 DESCRIPTION
#pod
#pod The method specified in the Request-Line is not allowed for the
#pod resource identified by the Request-URI. The response MUST include
#pod an Allow header containing a list of valid methods for the requested
#pod resource.
#pod
#pod =attr allow
#pod
#pod This is an ArrayRef of HTTP methods, it is required and the HTTP
#pod methods will be type checked to ensure validity and uniqueness.
#pod
#pod =head1 SEE ALSO
#pod
#pod HTTP Methods - L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html>
#pod
#pod
