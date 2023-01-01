package HTTP::Throwable::Role::Redirect 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Types::Standard qw(Str);

use Moo::Role;

has 'location' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

around 'build_headers' => sub {
    my $next    = shift;
    my $self    = shift;
    my $headers = $self->$next( @_ );
    push @$headers => ('Location' => $self->location);

    return $headers;
};

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Redirect - an exception that is a redirect

=head1 VERSION

version 0.028

=head1 OVERVIEW

This is an extremely simple method used by most of the 3xx series of
exceptions.  It adds a C<location> attribute that will be provided as the
Location header when the exception is converted to an HTTP message.

Note that "MultipleChoices," the 300 status code is I<not> currently a
redirect, as its Location header is optional.  This may change in the future of
the semantics of this role are refined.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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
# ABSTRACT: an exception that is a redirect

#pod =head1 OVERVIEW
#pod
#pod This is an extremely simple method used by most of the 3xx series of
#pod exceptions.  It adds a C<location> attribute that will be provided as the
#pod Location header when the exception is converted to an HTTP message.
#pod
#pod Note that "MultipleChoices," the 300 status code is I<not> currently a
#pod redirect, as its Location header is optional.  This may change in the future of
#pod the semantics of this role are refined.
