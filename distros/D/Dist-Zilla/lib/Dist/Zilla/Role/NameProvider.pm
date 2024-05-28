package Dist::Zilla::Role::NameProvider 6.032;
# ABSTRACT: something that provides a name for the dist

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role must provide a C<provide_name> method that
#pod will be called when setting the dist's name.
#pod
#pod If a NameProvider offers a name but one has already been set, an
#pod exception will be raised.  If C<provide_name> returns undef, it will be
#pod ignored.
#pod
#pod =cut

requires 'provide_name';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::NameProvider - something that provides a name for the dist

=head1 VERSION

version 6.032

=head1 DESCRIPTION

Plugins implementing this role must provide a C<provide_name> method that
will be called when setting the dist's name.

If a NameProvider offers a name but one has already been set, an
exception will be raised.  If C<provide_name> returns undef, it will be
ignored.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
