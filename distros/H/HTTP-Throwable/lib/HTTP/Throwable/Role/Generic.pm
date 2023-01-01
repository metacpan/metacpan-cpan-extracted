package HTTP::Throwable::Role::Generic 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Carp qw(confess);

use Moo::Role;

with 'HTTP::Throwable';

sub default_status_code {
    confess "generic HTTP::Throwable must be given status code in constructor";
}

sub default_reason {
    confess "generic HTTP::Throwable must be given reason in constructor";
}

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Generic - a generic built-by-hand exception

=head1 VERSION

version 0.028

=head1 DESCRIPTION

This role is used (for boring internals-related reasons) when you throw an
exception with no special roles mixed in.

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

# ABSTRACT: a generic built-by-hand exception

#pod =head1 DESCRIPTION
#pod
#pod This role is used (for boring internals-related reasons) when you throw an
#pod exception with no special roles mixed in.
#pod
