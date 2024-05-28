package Dist::Zilla::Role::ArchiveBuilder 6.032;
# ABSTRACT: something that builds archives

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

requires 'build_archive';

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role have their C<build_archive> method called
#pod when it is time to build the archive.
#pod
#pod =method build_archive
#pod
#pod This method takes three arguments, and returns a L<Path::Tiny> instance
#pod containing the path to the archive.
#pod
#pod =over 4
#pod
#pod =item archive_basename
#pod
#pod This is the name of the archive (including C<-TRIAL> if appropriate) without
#pod the format extension (that is the C<.tar.gz> part).  The plugin implementing
#pod this role should add the appropriate full path including extension as the
#pod returned L<Path::Tiny> instance.  Not including the extension allows the
#pod plugin to choose its own format.
#pod
#pod =item built_in
#pod
#pod This is a L<Path::Tiny> where the distribution has been built.
#pod
#pod =item dist_basename
#pod
#pod This method will return the dist's basename (e.g. C<Dist-Name-1.01> as a
#pod L<Path::Tiny>.  The basename is used as the top-level directory in the
#pod tarball.  It does not include C<-TRIAL>, even if building a trial dist.
#pod
#pod =back
#pod
#pod =cut

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ArchiveBuilder - something that builds archives

=head1 VERSION

version 6.032

=head1 DESCRIPTION

Plugins implementing this role have their C<build_archive> method called
when it is time to build the archive.

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

=head1 METHODS

=head2 build_archive

This method takes three arguments, and returns a L<Path::Tiny> instance
containing the path to the archive.

=over 4

=item archive_basename

This is the name of the archive (including C<-TRIAL> if appropriate) without
the format extension (that is the C<.tar.gz> part).  The plugin implementing
this role should add the appropriate full path including extension as the
returned L<Path::Tiny> instance.  Not including the extension allows the
plugin to choose its own format.

=item built_in

This is a L<Path::Tiny> where the distribution has been built.

=item dist_basename

This method will return the dist's basename (e.g. C<Dist-Name-1.01> as a
L<Path::Tiny>.  The basename is used as the top-level directory in the
tarball.  It does not include C<-TRIAL>, even if building a trial dist.

=back

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
