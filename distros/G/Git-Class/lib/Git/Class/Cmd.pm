package Git::Class::Cmd;

use Module::Find ();
use Moo; with (Module::Find::findsubmod 'Git::Class::Role');
use MRO::Compat;
use Path::Tiny;

has no_capture => (is => 'rw');

has '_git' => (
  is        => 'rw',
#  isa       => 'Str|Undef',
  init_arg  => 'exec_path',
  builder   => '_find_git',
);

# predicate doesn't work in this case
sub is_available { shift->_git ? 1 : 0 }

sub _find_git {
  my $self = shift;

  my $file = $ENV{GIT_EXEC_PATH};

  return $file if $file && -f $file;

  require Config;
  my $path_sep = $Config::Config{path_sep} || ';';

  foreach my $path ( split /$path_sep/, ($ENV{PATH} || '') ) {
    return 'git' if path($path, 'git')->is_file
                 || path($path, 'git.cmd')->is_file
                 || path($path, 'git.exe')->is_file;
  }
  return;
}

sub git {
  my $self = shift;

  unless ($self->is_available) {
    $self->_error("git binary is not available");
    return;
  }

  my %git_options;
  while(ref $_[0] eq 'HASH') {
    my $href = shift;
    %git_options = (%git_options, %{$href});
  }

  my ($options, @args) = $self->_get_options(@_);
  my $cmd = shift @args;

  $self->_execute(
    $self->_git,
    $self->_prepare_options(\%git_options),
    ($cmd ? ($cmd) : ()),
    $self->_prepare_options($options),
    @args,
  );
}

1;

__END__

=head1 NAME

Git::Class::Cmd

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Git::Class;

  my $git = Git::Class::Cmd->new;
  my $worktree = $git->clone('git://github.com/charsbar/git-class.git');

  my $captured = $git->status; # as a whole
  my @captured = $git->status; # split by "\n"

  # other interface, mainly for internal use
  my $cmd = Git::Class::Cmd->new( die_on_error => 1, verbose => 1 );
  $cmd->git( commit => { message => 'a commit message', all => '' } );

=head1 DESCRIPTION

This is a simple wrapper of a C<git> executable. The strength is that you can run a C<git> command and capture the output in a simple and more portable way than using C<open> to pipe (which is not always implemented fully).

As of this writing, most of the git commands (methods of this class) simply returns the output, but this will be changed in the near future, especially when called in the list context, where we may want sort of proccessed data like what files are affected etc.

=head1 METHODS

Most of the git commands are implemented as a role. See Git::Class::Role::* for details.

=head2 is_available

returns true if the C<git> command exists (or specified explicitly).

=head2 git

takes a git command name (whatever C<git> executable recognizes; it doesn't matter if it's implemented in this package (as a method/role) or not), and options/arguments for that.

Options may be in a hash reference (or hash references if you prefer). You don't need to care about the order and shell-quoting, and you don't need to prepend '--' to the key in this case, but you do need to set its value to a blank string(C<"">) (or C<undef>) if the option doesn't take a value. Of course you can pass option strings merged in the argument list.

Note that if you want to pass options for C<git> executable (instead of git command options), pass them as a hash reference first, before you pass a command string, and command parameters.

  $cmd->git({ git_dir => '/path/to/repo/' }, 'command', ...);

Returns a captured text in the scalar context, or split lines in the list context. If some error (or warnings?) might occur, you can see it in C<< $object->_error >>.

Note that if the C<< $object->is_verbose >>, the captured output is printed as well. This may help if you want to issue interactive commands.

If you want to trace commands, set C<GIT_CLASS_TRACE> environmental variable to true.

=head2 no_capture

is an accessor/mutator to determine if we should use Capture::Tiny to capture the output of git commands. If your web apps hang because of the capturing, set this to true to disable it.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
