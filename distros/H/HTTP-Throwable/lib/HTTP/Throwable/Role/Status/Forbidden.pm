package HTTP::Throwable::Role::Status::Forbidden 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 403 }
sub default_reason      { 'Forbidden' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::Forbidden - 403 Forbidden

=head1 VERSION

version 0.028

=head1 DESCRIPTION

The server understood the request, but is refusing to fulfill it.
Authorization will not help and the request SHOULD NOT be repeated.
If the request method was not HEAD and the server wishes to make
public why the request has not been fulfilled, it SHOULD describe
the reason for the refusal in the entity. If the server does not
wish to make this information available to the client, the status
code 404 (Not Found) can be used instead.

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

# ABSTRACT: 403 Forbidden

#pod =head1 DESCRIPTION
#pod
#pod The server understood the request, but is refusing to fulfill it.
#pod Authorization will not help and the request SHOULD NOT be repeated.
#pod If the request method was not HEAD and the server wishes to make
#pod public why the request has not been fulfilled, it SHOULD describe
#pod the reason for the refusal in the entity. If the server does not
#pod wish to make this information available to the client, the status
#pod code 404 (Not Found) can be used instead.
#pod
#pod
