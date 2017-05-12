package Git::Class::Worktree;

use Moo; with qw/
  Git::Class::Role::Execute
  Git::Class::Role::Cwd
/;
use MRO::Compat;
use Path::Tiny;

has no_capture => (is => 'rw');

has '_path' => (
  is       => 'rw',
#  isa      => 'Str',
  init_arg => 'path',
  required => 1,
  trigger  => sub {
    my ($self, $path) = @_;
    $self->{path} = path($path);
    chdir $path;
  },
);

has '_cmd' => (
  is         => 'rw',
#  isa        => 'Git::Class::Cmd',
  init_arg   => 'cmd',
  builder    => '_build__cmd',
  handles    => [qw(
    git
    add branch checkout commit config diff fetch init log move 
    push pull rebase reset remove show status tag
  )],
);

sub _build__cmd {
  my $self = shift;
  require Git::Class::Cmd;
  return Git::Class::Cmd->new(
    die_on_error => $self->_die_on_error,
    verbose      => $self->is_verbose,
    cwd          => $self->_path,
    no_capture   => $self->no_capture,
  );
}

sub DEMOLISH {
  my $self = shift;

  chdir $self->_cwd if $self->_cwd;
}

1;

__END__

=head1 NAME

Git::Class::Worktree

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Git::Class::Worktree;

  my $work = Git::Class::Worktree->new(path => 'path/to/somewhere');
  $work->init;
  $work->add('.');
  $work->commit;

  $work->git('ls-files'); # can run an arbitrary command

=head1 DESCRIPTION

This is another (experimental) interface to C<git> executable for convenience. Note that this will change the current directory to the path you specify when you create an object, and as of 0.03, it'll take you back to the previous current directory when you demolish the object.

=head1 METHODS

=head2 no_capture

is an accessor/mutator to determine if we should use Capture::Tiny to capture the output of git commands. If your web apps hang because of the capturing, set this to true to disable it.

=head1 INTERNAL METHODS

=head2 BUILDARGS

=head2 DEMOLISH

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
