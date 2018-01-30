package Git::Repo::Commits;

use warnings;
use strict;
use Carp;
use Git;

use version; our $VERSION = qv('0.1.0'); # Work with a few files

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;


# Module implementation here
sub new {
  my $class = shift;
  my $dir = shift || croak "Need a repo directory";
  my $files_arrayref = shift;
  my ($repo_name)  = ($dir =~ m{/([^/]+)/?$} );
  my $repo = Git->repository (Directory => $dir);
  my @these_revs;
  if ( $files_arrayref ) {
    @these_revs = $repo->command('rev-list', '--all', '--', join(" ", @$files_arrayref));
  } else { 
    @these_revs = $repo->command('rev-list', '--all');
  }
  my @commit_info;
  for my $commit ( reverse @these_revs ) {
    my $commit_info = $repo->command('show', '--pretty=fuller', $commit);
    my @files = ($commit_info =~ /\+\+\+\s+b\/(.+)/g);
    my ($author) = ($commit_info =~ /Author:\s+(.+)/);
    my ($commit) = ($commit_info =~ /Commit:\s+(.+)/);
    my ($commit_date) = ($commit_info =~ /CommitDate:\s+(.+)/);
    push @commit_info, { files => \@files,
			 author => $author,
			 commit => $commit,
			 commit_date => $commit_date};
  }
  my $commits = { _repo => $dir,
		  _name => $repo_name,
		  _commits => \@commit_info,
		  _hashes => \@these_revs};
  return bless $commits, $class;

}

sub commits {
  my $self = shift;
  return $self->{'_commits'};
}

sub hashes {
  my $self = shift;
  return $self->{'_hashes'};
}

sub name {
  my $self = shift;
  return $self->{'_name'};
}
		 

1; # Magic true value required at end of module
__END__

=head1 NAME

Git::Repo::Commits - Get all commits in a repository


=head1 VERSION

This document describes Git::Repo::Commits version 0.0.7


=head1 SYNOPSIS

    use Git::Repo::Commits;

    my $commits = new Git::Repo::Commits /home/is/where/the/repo/is

  
=head1 DESCRIPTION

=head2 new $repository

Creates an object with information about all commits

=head2 commits

Returns an array with commit information, an array item per commit, in
the shape

    { author => $author,
      committer => $committer,
      commit_date => $date,
      files => \@files }

=head2 hashes

Returns an array with the hashes of all commits in the repo.

=head2 name

Returns the name of the directory, which usually is also the name of the repo. 


=head1 CONFIGURATION AND ENVIRONMENT

Git::Repo::Commits requires no configuration files or environment
variables. It might be the case that git is not installed and this
fails, but probably not. 


=head1 DEPENDENCIES

Depends on L<Git>, which should be available either from your git
installation or from CPAN.


=head2 SEE ALSO

L<Git::Raw> has an object oriented interface to repositories, including a class L<Git::Raw::Commit> to access commits. 

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-git-repo-commits@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>, or, even better, at the
L<https://github.com/JJ/perl-git-commit/issues> in GitHub.


=head1 AUTHOR

JJ  C<< <JMERELO@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, JJ C<< <JMERELO@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
