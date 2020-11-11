package Dist::Zilla::Plugin::ExecDir 6.017;
# ABSTRACT: install a directory's contents as executables

use Moose;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [ExecDir]
#pod   dir = scripts
#pod
#pod If no C<dir> is provided, the default is F<bin>.
#pod
#pod =cut

has dir => (
  is   => 'ro',
  isa  => 'Str',
  default => 'bin',
);

with 'Dist::Zilla::Role::ExecFiles';
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ExecDir - install a directory's contents as executables

=head1 VERSION

version 6.017

=head1 SYNOPSIS

In your F<dist.ini>:

  [ExecDir]
  dir = scripts

If no C<dir> is provided, the default is F<bin>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
