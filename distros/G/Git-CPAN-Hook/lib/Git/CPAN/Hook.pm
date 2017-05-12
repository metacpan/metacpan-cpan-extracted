package Git::CPAN::Hook;

use strict;
use warnings;
use Git::Repository;

our $VERSION = '0.03';

# the list of CPAN.pm methods we will replace
my %cpan;
my %hook = (
    'CPAN::Distribution::install'   => \&_install,
    'CPAN::HandleConfig::neatvalue' => \&_neatvalue,
);
my @keys = qw( __HOOK__ );

# if we were called from within CPAN.pm's configuration
_TSR_CPAN() if $INC{'CPAN.pm'};

#
# some private utilities
#
sub _TSR_CPAN {
    require CPAN;

    # actually replace the code in CPAN.pm
    _replace( $_ => $hook{$_} ) for keys %hook;

    # install our keys in CPAN.pm's config
    $CPAN::HandleConfig::keys{$_} = undef for @keys;
}

sub _replace {
    my ( $fullname, $meth ) = @_;
    my $name = ( split /::/, $fullname )[-1];
    no strict 'refs';
    no warnings 'redefine';
    $cpan{$name} = \&{$fullname};
    *$fullname = $meth;
}

sub _commit_all {
    my ($r, @args) = @_;

    # git add . fails on an empty repository for git between 1.5.3 and 1.6.3.2
    return if ! eval { $r->run( add => '.' ); 1; };

    # git status --porcelain exists only since git 1.7.0
    $r->run( commit => @args )
        if $r->version_lt('1.7.0')
        ? $r->run('status') !~ /^nothing to commit/m
        : $r->run( status => '--porcelain' );
}

sub import {
    my ($class) = @_;
    my $pkg = caller;

    # always export everything
    no strict 'refs';
    *{"$pkg\::$_"} = \&$_ for qw( install init uninstall );
}

#
# exported methods for repository setup
#

sub init {
    my ($path) = @_ ? @_ : @ARGV;

    # make this directory a Git repository
    Git::Repository->run( init => { cwd => $path } );
    my $r = Git::Repository->new( work_tree => $path );

    # activate it for Git::CPAN::Hook
    $r->run( qw( config cpan-hook.active true ) );

    # create an initial commit if needed (e.g. for local::lib)
    _commit_all( $r => -m => 'Initial commit' );

    # setup ignore list
    my $ignore = File::Spec->catfile( $path, '.gitignore' );
    open my $fh, '>>', $ignore or die "Can't open $ignore for appending: $!";
    print $fh "$_\n" for qw( .packlist perllocal.pod );
    close $fh;

    # git add won't accept an absolute path before 1.5.5
    $r->run( add => '.gitignore' );
    $r->run( commit => '-m', 'Basic files in an empty CPAN directory' );

    # tag as the empty root commit
    $r->run( tag => '-m', 'empty CPAN install, configured', 'empty' );
}

#
# exported methods for CPAN.pm hijacking
#

sub install {
    _TSR_CPAN;
    CPAN::HandleConfig->load();
    $CPAN::Config->{__HOOK__} = sub { };
    CPAN::HandleConfig->commit();
}

sub uninstall {
    _TSR_CPAN;
    CPAN::HandleConfig->load();
    delete $CPAN::Config->{$_} for @keys;
    CPAN::HandleConfig->commit();
}

#
# our replacements for some CPAN.pm methods
#

# commit after a successful install
sub _install {
    my $dist = $_[0];
    my @rv   = $cpan{install}->(@_);

    # do something only after a successful install
    if ( !$dist->{install}{FAILED} ) {
        __PACKAGE__->commit( $dist->{ID} );
    }

    # return what's expected
    return @rv;
}

# make sure we always get loaded
sub _neatvalue {
    my $nv = $cpan{neatvalue}->(@_);

    # CPAN's neatvalue just stringifies coderefs, which we then replace
    # with some code to hook us back in CPAN for next time
    return $nv =~ /^CODE/
        ? 'do { require Git::CPAN::Hook; sub { } }'
        : $nv;
}

#
# core methods, available to all CPAN clients
#
sub commit {
    my ( $class, $dist ) = @_;

    # assume distributions are always installed somewhere in @INC
    for my $inc ( grep -e, @INC ) {
        my $r = eval { Git::Repository->new( work_tree => $inc ); };
        next if !$r;    # not a Git repository

        # do not commit in random directories!
        next if $r->run(qw( config --bool cpan-hook.active )) ne 'true';

        # commit step
        _commit_all( $r => -m => $dist );
    }
}

1;

__END__

=head1 NAME

Git::CPAN::Hook - Commit each install done by CPAN.pm in a Git repository

=head1 SYNOPSIS

    # install the hooks in CPAN.pm
    $ perl -MGit::CPAN::Hook -e install

    # put your local::lib under Git control
    $ perl -MGit::CPAN::Hook -e init ~/perl5

    # use CPAN.pm / cpan as usual
    # every install will create a commit in the current branch

    # uninstall the hooks from CPAN.pm's config
    $ perl -MGit::CPAN::Hook -e uninstall

=head1 DESCRIPTION

C<Git::CPAN::Hook> adds Git awareness to the CPAN.pm module installer.
Once the hooks are installed in CPAN.pm's configuration, each and every
module installation will result in a commit being done in the installation
directory/repository.

All the setup you need is described in the L<SYNOPSIS>. Read further
if you are interested in the gory details.


=head2 Rationale

This module is a proof of concept.

Then I want to experiment with a repository of installed stuff, especially
several versions of the same distribution. And then start doing fancy
things like uninstalling a single distribution, testing my modules against
different branches (each test environment is only a "C<git checkout>" away!),
creating a full install from scratch by applying "install patches", etc.

There are two parts to maintaining a CPAN installation as a Git repository:

=over 4

=item

First, one needs to generate file sets from each newly installation.

The first step to that is done by C<commit>. However, a Git commit is
attached to the full tree of files, not just those there were just
installed. Some extra work is needed.

=item

Once a distribution can be isolated in the repository, one needs to be
able to perform all the operations that allow the addition or removal
of already installed distribution, the creation of new branches with a
set of individual installs, etc.

At some point in the future, I plan to ship a command-line tool to
help managing such a CPAN repository.

=back

If this proves useful in any way, it shouldn't be too hard to port to
CPAN clients that support hooks and plugins. It might be a little more
difficult to use the I<terminate and stay resident> approach I used
on CPAN.pm on other clients, as they probably have a san^Hfer configuration
file format.


=head2 Configuration

C<Git::Repository::Hook> is called by your CPAN client after each
installation, to perform a commit in the installation directory.

Because C<Git::CPAN::Hook> doesn't know I<a priori> where your CPAN
client has installed the files, it processes C<@INC> looking for Git
repositories. To avoid unexpected commits in development repositories,
your CPAN repository must have been I<activated>.

This is done by setting the following configuration in your repository:

    [cpan-hook]
        active = true

For simplicity, C<Git::CPAN::Hook> should ignore F<.packlist> files,
as well as F<perllocal.pod>.

    $ perl -le 'print for qw( .packlist perllocal.pod )' >> .gitignore

The whole point of having your CPAN installation under Git control is
to have multiple branches. They should all start with the basic, empty
directory (basically, containing only the F<.gitignore> file). This
initial commit will be tagged C<empty>.

This is a lot of setup, so there is a one line shortcut (assuming the
directory you want to track is F<~/perl5>:

    $ perl -MGit::CPAN::Hook -e init ~/perl5


=head2 Hooking C<Git::CPAN::Hook> in C<CPAN.pm>

Because C<CPAN.pm> is ubiquitous, it was the initial target client for
C<Git::CPAN::Hook>. Because it doesn't support hooks, hook support had
to be hacked in.

This is done by adding some code to activate the hooks in the
configuration file of C<CPAN.pm>, which happens to be a Perl script
that is C<eval>'ed. C<;-)>

Again, there is a shortcut to install the hook:

    $ perl -MGit::CPAN::Hook -e install

and to uninstall it:

    $ perl -MGit::CPAN::Hook -e uninstall


=head1 INTEGRATION WITH OTHER CPAN CLIENTS

C<Git::CPAN::Hook> currently only explicitely supports C<CPAN.pm>.
It shouldn't be too hard to integrate with any CPAN client that supports
plugins.

=head1 METHODS

The following methods are available to write plugins/wrappers/hooks for
your CPAN client.

=head2 commit( $dist )

Browse all directories in C<@INC>, looking for an "active" repository
(i.e. with the Git configuration C<cpan-hook.active> item set to
C<true>), with local changes, and commit them with C<$dist> as the
log message. C<$dist> is expected to be the full distribution name,
e.g. C<B/BO/BOOK/Git-CPAN-Hook-0.02.tar.gz>.

This method is meant to be called right after the installation of an
individual distribution, so that newly added/modified files will be
committed to the repository.


=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 HISTORY AND ACKNOWLEDGEMENTS

The initial idea for this module comes from a conversation
between Andy Armstrong, Tatsuhiko Miyagawa, brian d foy and myself
(each having his own goal in mind) at the Perl QA Hackathon 2010 in Vienna.

My own idea was that it would be neat to install/uninstall distributions
using Git to store the files, so that I could later develop some tools
to try all kinds of crazy combinations of modules versions and installations.
I already saw myself bisecting on a branch with all versions of a given
dependency...

To do that and more, I needed a module to control Git from within Perl.
So I got distracted into writing C<Git::Repository>.

At the Perl QA Hackathon 2011 in Amsterdam, the discussion came up again
with only Andy Armstrong and myself, this time. He gently motivated me
into "just doing it", and after a day of experimenting, I was able to
force C<CPAN.pm> to create a commit after each individual installation.

=head1 TODO

Here are some of the items on my list:

=over 4

=item

Make it possible for other CPAN installers that have the ability to use
hooks to use Git::CPAN::Hook.

=item

Some command-line tool for easy manipulation of installed distributions.

=item

It would be great to say: "go forth on BackPAN and install all versions
of distribution XYZ, with all its dependencies, and make me a branch
with all these, so that I can bisect my own module to find which is the
oldest version that works with it".

Or something like that.

=item

Turn any installed distribution into a tagged parentless commit that
can be simply "applied" onto any branch (i.e. find a way to create a
minimal C<tree> object for it).

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-git-cpan-hook at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GIT-CPAN-Hook>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::CPAN::Hook

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-CPAN-Hook>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-CPAN-Hook>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-CPAN-Hook>

=item * Search CPAN

L<http://search.cpan.org/dist/Git-CPAN-Hook/>

=back

=head1 COPYRIGHT

Copyright 2011 Philippe Bruhat (BooK).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

