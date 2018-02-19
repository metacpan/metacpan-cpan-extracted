package Dist::Zilla::Role::FileFinder 6.011;
# ABSTRACT: something that finds files within the distribution

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod A FileFinder plugin locates files within the distribution.  This role exists so
#pod that sets of files can be easily described in one configuration section and
#pod then used by one or more other plugin.
#pod
#pod Plugins implementing this role must provide a C<find_files> method which will
#pod be called with no arguments and must return an arrayref of files.  (This
#pod arrayref should not be re-used, as it may be altered once returned.)
#pod
#pod For example, imagine a simple glob-like FileFinder that expects configuration
#pod like this:
#pod
#pod   [Glob / RootModules]
#pod   glob = *.pm
#pod
#pod This sets up a FileFinder named "RootModules" which will contain all F<pm>
#pod files in the root directory.
#pod
#pod Another plugin that knows how to use FileFinder plugins might be configured
#pod like this:
#pod
#pod   [ModuleRelocator]
#pod   finder = RootModules
#pod   relocate_to = attic
#pod
#pod Finders may operate on any rules they like, checking file size, content, name,
#pod or other properties.  They should re-perform their "finding" on each call to
#pod C<find_files> as the files in the distribution may have changed.
#pod
#pod =cut

requires 'find_files';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::FileFinder - something that finds files within the distribution

=head1 VERSION

version 6.011

=head1 DESCRIPTION

A FileFinder plugin locates files within the distribution.  This role exists so
that sets of files can be easily described in one configuration section and
then used by one or more other plugin.

Plugins implementing this role must provide a C<find_files> method which will
be called with no arguments and must return an arrayref of files.  (This
arrayref should not be re-used, as it may be altered once returned.)

For example, imagine a simple glob-like FileFinder that expects configuration
like this:

  [Glob / RootModules]
  glob = *.pm

This sets up a FileFinder named "RootModules" which will contain all F<pm>
files in the root directory.

Another plugin that knows how to use FileFinder plugins might be configured
like this:

  [ModuleRelocator]
  finder = RootModules
  relocate_to = attic

Finders may operate on any rules they like, checking file size, content, name,
or other properties.  They should re-perform their "finding" on each call to
C<find_files> as the files in the distribution may have changed.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
