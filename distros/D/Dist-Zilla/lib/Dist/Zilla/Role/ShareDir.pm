package Dist::Zilla::Role::ShareDir 6.011;
# ABSTRACT: something that picks a directory to install as shared files

use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

use namespace::autoclean;

# Must return a hashref with any of the keys 'dist' and 'module'.  The 'dist'
# must be a scalar with a directory to include and 'module' must be a hashref
# mapping module names to directories to include.  If there are no directories
# to include, it must return undef.
requires 'share_dir_map';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ShareDir - something that picks a directory to install as shared files

=head1 VERSION

version 6.011

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
