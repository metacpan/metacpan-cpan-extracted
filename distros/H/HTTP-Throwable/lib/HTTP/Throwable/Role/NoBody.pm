package HTTP::Throwable::Role::NoBody 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Moo::Role;

sub body { return }

sub body_headers {
    my ($self, $body) = @_;

    return [
        'Content-Length' => 0,
    ];
}

sub as_string { $_[0]->status_line }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::NoBody - an exception with no body

=head1 VERSION

version 0.028

=head1 OVERVIEW

This is a very simple role, implementing the required C<as_string>, C<body>,
and C<body_headers> for L<HTTP::Throwable>.

When an HTTP::Throwable exception uses this role, its PSGI response will have
no entity body.  It will report a Content-Length of zero.  It will stringify to
its status line.

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
# ABSTRACT: an exception with no body

#pod =head1 OVERVIEW
#pod
#pod This is a very simple role, implementing the required C<as_string>, C<body>,
#pod and C<body_headers> for L<HTTP::Throwable>.
#pod
#pod When an HTTP::Throwable exception uses this role, its PSGI response will have
#pod no entity body.  It will report a Content-Length of zero.  It will stringify to
#pod its status line.
