package Git::TagVersion::Cmd::Command;

use Moose;

our $VERSION = '1.01'; # VERSION
# ABSTRACT: base class for all git-tag-version subcommands

extends 'MooseX::App::Cmd::Command';

use Git::TagVersion;

has 'fetch' => (
  is => 'rw', isa => 'Bool', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => 'f',
  documentation => 'fetch remote refs first',
);

has 'repo' => (
  is => 'ro', isa => 'Str', default => '.',
  traits => [ 'Getopt' ],
  cmd_aliases => 'r',
  documentation => 'path to git repository',
);

has 'tag_version' => (
  is => 'ro', isa => 'Git::TagVersion', lazy => 1,
  traits => [ 'NoGetopt' ],
  default => sub {
    my $self = shift;
    return Git::TagVersion->new(
      fetch => $self->fetch,
      root => $self->repo,
    );
  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion::Cmd::Command - base class for all git-tag-version subcommands

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
