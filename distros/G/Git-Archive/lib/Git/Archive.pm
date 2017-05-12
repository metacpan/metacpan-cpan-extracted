package Git::Archive;

use strict;
use v5.10.0;
our $VERSION = '0.10';
use IPC::Cmd qw/can_run/;

use Git::Repository;

sub commit {
    my $self = shift;
    # Get passed-in arguments correctly into hash
    my $args = ref $_[0] eq 'HASH' ? shift @_ : {@_};

    # Check for mandatory args
    ## First, make sure we have an error sub defined
    my $error =  $args->{error}
              || sub {
                  my ($args, $error) = @_;
                  print STDERR "[ERROR] $error\n";
                  return 1;
                  };

    ## Now throw errors if necessary
    unless ( $args->{msg} ) {
        return $error->( $args,'No commit message supplied');
        }
    unless ( $args->{files} || $args->{all_tracked} || $args->{all_dirty} ) {
        return $error->( $args,'No files specified to commit');
        }
    unless ( can_run( 'git' ) ) {
        return $error->( $args,'Git does not appear to be installed');
        }

    # Seems all is well with args. Check if the environment is sane
    ## Is the current or passed-in directory a git repo?
    my $repo = $self->_get_repo( $args );
    unless ( $repo ) { return $error->( $args, $args->{error} ) }

    ## Are there files already staged?
    if ( $repo->run( qw/diff --cached --name-only/ ) ) {
        return $error->( $args,'Repo already has staged files');
        }

    ## Populate name & email if not already done
    unless ( $repo->run( 'config', 'user.email' ) ) {
        system( $repo->run( 'config', 'user.email', '"git.user@example.com"' ) );
        }
    unless ( $repo->run( 'config', 'user.name' ) ) {
        system( $repo->run( 'config', 'user.name', '"Automated Commit"' ) );
        }

    # Looks like we're good to go. Let's commit!
    my $files = $self->_commit( $args, $repo ) || [];
    unless ( @{$files} ) {
        return $error->( $args, $args->{error} );
        }
    # We've got a new commit. Do we need to worry about a remote?
    my $do_remote;
    $do_remote = $self->_handle_remote( $args, $repo ) if $args->{use_remote};
    return $error->( $args, $args->{error} ) if $do_remote;;

    # Looks like we made it! Run the success sub if appropriate
    $args->{success}->( $args ) if $args->{success};

    return 0;
    }

sub _filenames {
    my ( $self, $args ) = @_;

    unless ( ref $args->{files} eq 'ARRAY' ) {
        my $files = $args->{files};
        $files =~ s/\s+/ /;
        return [ split ' ', $files ];
        }
    return $args->{files};
    }

sub _get_repo {
    my ($self, $args) = @_;
    $args->{git_dir} ||= './';
    unless (-e $args->{git_dir}) {
        $args->{error} = "Unable to initialise git directory:\nNo such directory";
        return;
        }
    unless (-e $args->{git_dir}.'/.git') {
        $args->{error} = "Unable to initialise git directory:\nNo .git found";
        return;
        }
    my $repo;
    my $options = {};
    if ( my $sudo = $args->{sudo} ) {
        $options = { git => [ 'sudo', '-u', $args->{sudo}, 'git' ] };
        }
    eval { $repo = Git::Repository->new( work_tree => $args->{git_dir}, $options ); };
    unless ($@) {
        return $repo;
        }
    $args->{error} = "Unable to initialise git directory:\n" . $@;
    return;
    }

sub _commit {
    my ($self, $args, $repo) = @_;

    my $files; # To record what files we intend to commit

    if ( $args->{files} ) {
        ## We have a list of specified files to commit
        $files = $self->_filenames( $args );
        eval { $repo->run( 'add', @{$files} ); };
        ## Do we need to make sure all the files had changes to stage?
        if ( $args->{check_all_staged} ) {
            my @staged = $repo->run( qw/diff --cached --name-only/ );
            unless ( @staged == @{$files} ) {
                # Numerical equality is Good Enough for now
                $repo->run( reset => 'HEAD' ); # Unstage the files, it's all gone wrong!
                $args->{error} = 'Some files not staged when "check_all_staged" specified';
                return;
                }
            }
        # Files staged and ready to go. Commit time
        $repo->run( commit => '-m "' . $args->{msg} . '"' );
        }
    elsif ( $args->{all_tracked} ) {
        ## We want to commit any modified tracked files
        my @status = $repo->run( status => '-s' );
        my @staged;
        unless ( @staged = grep { $_ !~ m/^\?\?/ } @status ) {
            $args->{error} = 'No modified files to commit';
            return;
            }
        $files = [map { $_ =~ s/^\s*\S+\s+(\S+)/$1/ } @staged];
        $repo->run( commit => '-a', '-m "' . $args->{msg} . '"' );
        }
    elsif ( $args->{all_dirty} ) {
        ## We want to commit all files in their current state
        my @status = $repo->run( status => '-s' );
        unless ( @status ) {
            $args->{error} = 'No modified files to commit';
            return;
            }
        $files = [map { $_ =~ s/^\s*\S+\s+(\S+)/$1/; $_ } @status];
        eval { $repo->run( 'add', @{$files} ); };
        $repo->run( commit => '-m "' . $args->{msg} . '"' );
        }

    return $files;
    }

sub _handle_remote {
    my ($self, $args, $repo) = @_;
    # We have a commit. Hopefully, the remote repo has nothing we don't.
    # But since it may well have, we need to:
    # Pull, and hope it doesn't fail
    # Then push, and hope it doesn't fail
    my $remote = $args->{use_remote};
    my $pull = $repo->run( pull => $remote );
    if ( $pull =~ /Automatic merge failed/ ) {
        # Damn, the pull didn't work.
        # Quick, pretend it never happened!
        $repo->run( merge => '--abort' );
        # Actually, we should probably 'fess up
        $args->{error} = 'Unable to push to remote: Cannot pull';
        return 1;
        }
    # Ok, we managed a pull. Hopefully we can now push
    my $push = $repo->run( push => $remote );
    if ( $push =~ /\[rejected\]/ ) {
        # We failed. Maybe somebody managed to push?
        # (in the tiny amount of time they had to work with)
        # Possibly we should try to push multiple times, but CBA -
        # "fail once, shout for help" seems far saner.
        $args->{error} = 'Unable to push to remote: Rejected';
        return 1;
        }
    return;
    }

1;

__END__

=encoding utf-8

=head1 NAME

Git::Archive - For automated file archiving with Git

=head1 SYNOPSIS

  use Git::Archive;
  Git::Archive->commit({ msg => "Committing files", files => [qw/foo bar/] });

=head1 DESCRIPTION

When you want to have code maintain a file archive by committing changes to a Git repo,
you don't have the luxury of being lazy and simply telling the code to do:

  git pull
  git commit changes
  git push

Many little things can go wrong:

=over

=item What if files are already staged when your code goes to commit its changes?

=item What if there are conflicts on pull?

=item What if the world ends?

=back

This is a module that helps you not have to care about such questions!
(Two out of three ain't bad)

The goal is to allow you to simply call the commit method, and know that you'll get
a useful error and safe recovery to a working state, whatever goes wrong.

=head2 Arguments:

=head3 msg

Commit message. This one is mandatory.

=head3 files

List of filenames to commit. Necessary unless you specify all_tracked or all_dirty.
Can be either a string of space-separated filenames, or an arrayref of filename strings.
If any of the filenames will contain a space, you must use the arrayref option.
Otherwise, use whichever you prefer.

=head3 error

Default behaviour for errors is to just dump them to STDERR.

If you want something more exciting (like email!) supply a subref here.

=head4 Error sub arguments:

=over

=item $args

Hashref, mostly the arguments you passed in when calling the commit method

=item $error

String containing the actual error message

=back

=head3 success

If you want to execute some code upon successful commit supply the function here

=head4 Success sub arguments:

=over

=item $args

Hashref, mostly the arguments you passed in when calling the commit method

=back

=head3 all_tracked

If you want to simply commit all tracked files, set this to be true

=head3 all_dirty

If you want to commit all changes in the directory, tracked or not, set this to be true

=head3 use_remote

If you want to push to a remote, set this to the name of the remote
(You'll typically want this to be 'origin')

=head3 check_all_staged

If you want to make sure every file supplied in the 'files' arg is staged before committing,
set this to be true: It will then throw an error if the file was unchanged/doesn't exist

=head3 git_dir

If you want to use a directory other than the current one as your repo, specify it here

Note: If your git-controlled dir is ./foo and you want to commit the file ./foo/bar/baz
then ( git_dir => './foo', files => 'bar/baz' )

=head3 sudo

If you want to call git as a different user via sudo, specify that user here

=head1 AUTHOR

Dominic Humphries E<lt>dominic@oneandoneis2.comE<gt>

=head1 COPYRIGHT

Copyright 2013 Dominic Humphries

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Git::Repository

=cut
