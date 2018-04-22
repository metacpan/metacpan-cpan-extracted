package Dist::Zilla::Role::FilePruner 6.012;
# ABSTRACT: something that removes found files from the distribution

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing FilePruner have their C<prune_files> method called once
#pod all the L<FileGatherer|Dist::Zilla::Role::FileGatherer> plugins have been
#pod called.  They are expected to (optionally) remove files from the list of files
#pod to be included in the distribution.
#pod
#pod =cut

requires 'prune_files';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::FilePruner - something that removes found files from the distribution

=head1 VERSION

version 6.012

=head1 DESCRIPTION

Plugins implementing FilePruner have their C<prune_files> method called once
all the L<FileGatherer|Dist::Zilla::Role::FileGatherer> plugins have been
called.  They are expected to (optionally) remove files from the list of files
to be included in the distribution.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
