package Dist::Zilla::Role::FileGatherer 6.032;
# ABSTRACT: something that gathers files into the distribution

use Moose::Role;
with 'Dist::Zilla::Role::Plugin',
     'Dist::Zilla::Role::FileInjector';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod A FileGatherer plugin is a special sort of
#pod L<FileInjector|Dist::Zilla::Role::FileInjector> that runs early in the build
#pod cycle, finding files to include in the distribution.  It is expected to call
#pod its C<add_file> method to add one or more files to inclusion.
#pod
#pod Plugins implementing FileGatherer must provide a C<gather_files> method, which
#pod will be called during the build process.
#pod
#pod =cut

requires 'gather_files';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::FileGatherer - something that gathers files into the distribution

=head1 VERSION

version 6.032

=head1 DESCRIPTION

A FileGatherer plugin is a special sort of
L<FileInjector|Dist::Zilla::Role::FileInjector> that runs early in the build
cycle, finding files to include in the distribution.  It is expected to call
its C<add_file> method to add one or more files to inclusion.

Plugins implementing FileGatherer must provide a C<gather_files> method, which
will be called during the build process.

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
