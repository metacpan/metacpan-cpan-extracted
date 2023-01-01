package HTTP::Throwable::Role::BoringText 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Moo::Role;

sub text_body { $_[0]->status_line }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::BoringText - provide the simplest text_body method possible

=head1 VERSION

version 0.028

=head1 OVERVIEW

This role is as simple as can be.  It provides a single method, C<text_body>,
which returns the result of calling the C<status_line> method.

This method exists so that exception classes can easily be compatible with the
L<HTTP::Throwable::Role::TextBody> role to provide a plain text body when
converted to an HTTP message.  Most of the core well-known exception types
consume this method.

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
# ABSTRACT: provide the simplest text_body method possible

#pod =head1 OVERVIEW
#pod
#pod This role is as simple as can be.  It provides a single method, C<text_body>,
#pod which returns the result of calling the C<status_line> method.
#pod
#pod This method exists so that exception classes can easily be compatible with the
#pod L<HTTP::Throwable::Role::TextBody> role to provide a plain text body when
#pod converted to an HTTP message.  Most of the core well-known exception types
#pod consume this method.
#pod
