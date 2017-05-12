###########################################
package GitMeta;
###########################################
use strict;
use warnings;
use Sysadm::Install qw(:all);

our $VERSION = "0.05";

###########################################
sub new { 
###########################################
  my($class, %options) = @_;

  my $self = { %options };
  bless $self, $class;
}

###########################################
sub expand { 
###########################################
  die "You need to implement 'expand'";
}

###########################################
sub param_check { 
###########################################
  my($self, @params) = @_;

  for my $param (@params) {
    if(! exists $self->{ $param }) {
      die "Parameter $param missing";
    }
  }
}

###########################################
sub health_check {
###########################################

    # Check if we have git in $PATH
    my( $stdout, $stderr, $rc ) = tap "git", "--version";

    if( $rc ) {
        die "git not found in path";
    }
}

1;

__END__

=head1 NAME

GitMeta - Clone/update many Git repositories using Meta repos

=head1 SYNOPSIS

      # use the command line interface
    gitmeta-update gitmeta-repo-loc meta.gmf /local/git/repo/dir

=head1 DESCRIPTION

GetMeta allows you to work on dozens of git repositories hosted on different
servers, and update all of your local copies with a single command. It defines
a new syntax, called GMF (git meta format), to configure many different
remote git repository locations and provides a script, C<gitmeta-update>, 
to create local copies of all of these repos or updates them if they 
already exist. This is useful to 

=over 4

=item *

periodically update your local clones while you have an Internet connection
going so they're up-to-date later when you're offline.

=item *

move to a new system and create clones of all of your favorite git
repos with a single command.

=back

=head2 SIMPLE EXAMPLE

For example, if you want to follow the Perl core developers on
perl5.git.perl.org and also the Log4perl project on Github, simply put these
lines into a new file C<myrepos.gmf>:

    # myrepos.gmf

    # Log4perl project
    - git://github.com/mschilli/log4perl.git

    # Perl core development
    - git://perl5.git.perl.org/perl.git

Then, if you run

    gitmeta-update myrepos.gmf ~/my-git-repos

the script will create clones of theses repos in the directory
C<~/my-git-repos> (it will ask to create it if it doesn't exist yet) or
update them if they're already cloned but out-of-date:

    Updating git://perl5.git.perl.org/perl.git
    ...
    Updating git://github.com/mschilli/log4perl.git
    ...

If you look your local C<~/my-git-repos> directory, you now have clones of 
both projects, ready to use:

    $ ls ~/my-git-repos
    log4perl
    perl
    
=head2 REMOTE GITMETA REPOS

Having the meta configuration C<myrepos.gmf> local on your box is nice
for testing, but it's much more powerful to store it in a new repo 
somewhere on the Net, e.g. C<github.com/mschilli/gitmeta-test> (this actually
exists for your testing pleasure). Now, wherever you are, simply call

    gitmeta-update git://github.com/mschilli/gitmeta-test \
      myrepos.gmf ~/my-git-repos

and the script will go out and fetch the git meta configuration from github, 
process each entry, and create or update the corresponding repositories
in your local git repo directory (C<~/my-git-repos>).

=head2 ADVANCED EXAMPLE

If you want to follow all repositories of a given user (like yourself)
on Github, or you want to clone all repositories in a given directory
on your hosting service, it would be tiresome to constantly update
your .gmf file when you create new repositories or remove retired ones.

This is why GitMeta offers additional modules to automate this:

=over 4

=item C<GitMeta::Github>

Expands to all git repos of a given user on Github. Put

    # All github projects of user 'mschilli'
    -
        type: Github
        user: mschilli

in your .gmf file (note the peculiar YAML syntax requiring
indentation and an empty - line to define an array entry referencing
a hash) then C<gitmeta-update> will fetch
a list of all Github projects of user C<user> and
add them to the processing list, before it starts cloning/updating
those repos.

=item C<GitMeta::SshDir>

Expands to all git repos in the given directory on a server via 
ssh. If you put

    # All projects in directory 'projects' 
    # on some host via git/SSH
    -
        type: SshDir
        host: username@hoster.com
        dir:  projects

in your .gmf, then C<gitmeta-update> will fetch a list of all
repositories in the given directory on the given host and add 
them to the processing list. Requires
ssh keys to be set up or you'll be prompted for your password.

=item C<GitMeta::GMF>

You guessed it: You can refer to other .gmf files in other gitmeta
repos, which C<gitmeta-update> will dutifully follow. If you put

    -
        type: GMF
        repo: user@devhost.com:git/gitmeta
        gmf_path: privdev.gmf

in your .gmf file, C<gitmeta-update> will fetch the .gmf file 
C<privdev.gmf> from user@devhost.com:git/gitmeta, process its
directives and add the results to the processing list.

This mechanism allows you to group repos into several meta repos
and retrieve them separately or combined. For example, if you have
your private repositories in 
C<user@devhost.com:git/gitmeta/priv.gmf> and your public repos
in 
C<user@devhost.com:git/gitmeta/pub.gmf>, you can write a .gmf file
that fetches them all at once:

    # all.gmf
    -
        type: GMF
        repo: user@devhost.com:git/gitmeta
        gmf_path: priv.gmf
    -
        type: GMF
        repo: user@devhost.com:git/gitmeta
        gmf_path: pub.gmf

If you put that file in user@devhost.com:git/gitmeta as well, all you need
to do is run

    gitmeta-update user@devhost.com:git gitmeta/all.gmf ~/local-dir

to get all repos created/updated.

=back

To combine all of the above, let's say that you're following several 
projects on Github.com, another
set of git repositories located on a private hosting service, the
perl core development on C<perl5.git.perl.org>, and another git meta
definition in another gitmeta repo. You define the following
.gmf file (in YAML format):

    # gitmeta.gmf

    # Perl core development
    - git://perl5.git.perl.org/perl.git
    
    # All github projects of user 'mschilli'
    -
        type: Github
        user: mschilli

    # All projects in directory 'projects' 
    # on some host via git/SSH
    -
        type: SshDir
        host: username@hoster.com
        dir:  projects

    # Private Project via git/SSH
    - username@private.server.com:git/private-project.git

    # Another .gmf file somewhere in another gitmeta repo
    -
        type: GMF
        repo: user@devhost.com:git/gitmeta
        gmf_path: privdev.gmf

Note that in order to update a local repository, gitsync will fetch
the remote changes, but won't merge them into the local clone. This
is because there might be merge conflicts and when updating dozens
of repos in one quick run, you don't want to be interrupted to
resolve a conflicted merge.

So, in git parlance, C<gitsync> performs a C<git fetch>, not a C<git pull>.
The updates will therefore be available in your locally defined
remote branches, and if you want to merge them into the local branches,
you need to run a C<git merge> (you don't need an Internet connection for 
that, so you can do this later), e.g. use

    git merge origin/master

to merge the changes in the 'master' branch of the 'origin' remote into 
the local branch you're currently on (presumably 'master' as well).

=head1 TROUBLESHOOTING

Make sure that 'git' is in your PATH.

=head1 FIRST PUBLICATION

This module was first published in the German edition of Linux Magazin
in August 2010:

    http://www.linux-magazin.de/Heft-Abo/Ausgaben/2010/08/Ueberall-Projekte

An English translation is available here:

    http://www.linux-magazine.com/w3/issue/118/050-055_perl.pdf

=head1 LEGALESE

Copyright 2010-2011 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
