package Git::Class;

use Moo; extends 'Git::Class::Cmd';

our $VERSION = '0.15';

1;

__END__

=head1 NAME

Git::Class - a simple git wrapper to capture output

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Git::Class;

  my $git = Git::Class::Cmd->new;
  my $worktree = $git->clone('git://github.com/charsbar/git-class.git');
  $worktree->add('myfile');
  $worktree->commit({ message => 'a commit message' });
  $worktree->push;

  my $captured = $worktree->status; # as a whole
  my @captured = $worktree->status; # split by "\n"

=head1 DESCRIPTION

This is a simple wrapper of a C<git> executable. The strength is that you can run a C<git> command and capture the output in a simple and more portable way than using C<open> to pipe (which is not always implemented fully).

As of this writing, most of the git commands simply returns the output, but this will be changed in the near future, especially when called in the list context, where we may want sort of proccessed data like what files are affected etc.

=head1 SEE ALSO

L<Git::Class::Cmd>

L<Git::Class::Worktree>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
