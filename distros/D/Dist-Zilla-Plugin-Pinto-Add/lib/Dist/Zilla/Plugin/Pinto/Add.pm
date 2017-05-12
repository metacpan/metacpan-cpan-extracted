# ABSTRACT: Ship your dist to a Pinto repository

package Dist::Zilla::Plugin::Pinto::Add;

#------------------------------------------------------------------------------

use Moose;
use MooseX::Types::Moose qw(Str ArrayRef Bool);

use IPC::Run;
use File::Which;

use version;

#------------------------------------------------------------------------------

our $VERSION = '0.088'; # VERSION

#------------------------------------------------------------------------------

with qw( Dist::Zilla::Role::Releaser Dist::Zilla::Role::BeforeRelease );

#------------------------------------------------------------------------------

sub mvp_multivalue_args { return qw(roots) }
sub mvp_aliases { return { root => 'roots' } }

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => Str,
    predicate  => 'has_author',
);


has recurse => (
    is         => 'ro',
    isa        => Bool,
    predicate  => 'has_recurse',
);


has stack     => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_stack'
);


has authenticate => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has username => (
    is        => 'ro',
    isa       => Str,
    default   => sub { $ENV{PINTO_USERNAME} || $ENV{USER} || $ENV{LOGIN} || $ENV{USERNAME} || $ENV{LOGNAME} },
    lazy      => 1,
);


has password => (
    is        => 'ro',
    isa       => Str,
    default   => sub { $ENV{PINTO_PASSWORD} || shift->_ask_for_password },
    lazy      => 1,
);


has pinto_exe => (
    is        => 'ro',
    isa       => Str,
    default   => \&_find_pinto_executable,
    lazy      => 1,
);


has roots => (
    is        => 'ro',
    isa       => ArrayRef[Str],
    default   => sub { [ $ENV{PINTO_REPOSITORY_ROOT} || shift->log_fatal('must specify a root') ] },
    lazy      => 1,
);


has live_roots => (
    is        => 'ro',
    isa       => ArrayRef[Str],
    writer    => '_set_live_roots',
    default   => sub { [] },
    init_arg  => undef,
);

#------------------------------------------------------------------------------

our $MINIMUM_PINTO_VERSION = version->parse('0.098');

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $pinto_exe = $self->pinto_exe
        or $self->log_fatal("unable to find pinto in your PATH");

    my $pinto_version = $self->_installed_pinto_version
        or $self->log_fatal("unable to determine the version of pinto at $pinto_exe");

    $pinto_version >= $MINIMUM_PINTO_VERSION
        or $self->log_fatal("need version $MINIMUM_PINTO_VERSION of pinto.  You only have $pinto_version");

    return $self;
}

#------------------------------------------------------------------------------

sub before_release {
    my ($self) = @_;

    my @live_roots;
    for my $root ( @{ $self->roots } ) {

        my @args = (
            -root => $root,
            $self->authenticate ? (-username => $self->username) : (),
            $self->authenticate ? (-password => $self->password) : (),
        );

        $self->log("checking if repository at $root is available");
        my ($ok, $output) = $self->_run_pinto( nop => @args );

        if (not $ok) {
            $self->log("repository at $root is not available");
            my $abort = $self->zilla->chrome->prompt_yn('Abort release? ', {default => 'Y'});
            $self->log_fatal('Aborting') if $abort; # dies!
            next;
        }

        push @live_roots, $root;
    }

    $self->log_fatal('none of your repositories are available') if not @live_roots;
    $self->_set_live_roots(\@live_roots);

    return $self;
}

#------------------------------------------------------------------------------

sub release {
    my ($self, $archive) = @_;

    for my $root ( @{ $self->live_roots } ) {

        $self->log("adding $archive to repository at $root");
        my @args = $self->_generate_pinto_args($root, $archive);
        my ($ok, $output) = $self->_run_pinto( add => @args );

        $ok ? $self->log("added $archive to $root ok")
            : $self->log_fatal("failed to add $archive to $root: $output");
    }

    return 1;
}

#------------------------------------------------------------------------------

sub _generate_pinto_args {
    my ($self, $root, $archive) = @_;

    my @recurse_opt = $self->has_recurse
        ? ($self->recurse ? qw(-recurse) : qw(-no-recurse))  : ();

    return (
        -root     => $root,
        -message  => "Added " . $archive->basename,

        $self->authenticate ? (-username => $self->username) : (),
        $self->authenticate ? (-password => $self->password) : (),
        $self->has_stack    ? (-stack    => $self->stack)    : (),
        @recurse_opt,

        $archive,
    );

}

#------------------------------------------------------------------------------

sub _ask_for_password {
    my ($self) = @_;

    my $prompt = sprintf 'Pinto password for %s: ', $self->username;
    my $password = $self->zilla->chrome->prompt_str($prompt, { noecho => 1 });

    return $password;
}

#------------------------------------------------------------------------------

sub _run_pinto {
    my ($self, @args) = @_;

    local $ENV{PINTO_NO_COLOR} = 1;
    local $ENV{PINTO_PAGER} = local $ENV{PAGER} = undef;

    s/^-/--/ for @args;

    my $output = my $input = '';
    my @cmd = ($self->pinto_exe, @args);
    my $timeout = IPC::Run::timeout(300);
    my $ok = IPC::Run::run(\@cmd, \$input, \$output, \$output, $timeout);
    return ($ok, $output);
}

#------------------------------------------------------------------------------

sub _find_pinto_executable {
    my ($class) = @_;

    return File::Which::which('pinto');
}

#------------------------------------------------------------------------------

sub _installed_pinto_version {
    my ($class) = @_;

    my $pinto_exe = $class->_find_pinto_executable;
    my ($pinto_version) = (qx($pinto_exe --version) =~ m/version ([\d\._v]+) /);
    return version->parse($pinto_version);
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=for :stopwords Jeffrey Ryan Thalhammer cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::Pinto::Add - Ship your dist to a Pinto repository

=head1 VERSION

version 0.088

=head1 SYNOPSIS

  # In your dist.ini
  [Pinto::Add]
  root          = http://pinto.example.com  ; optional. defaults to PINTO_REPOSITORY_ROOT
  author        = YOU                       ; optional. defaults to PINTO_AUTHOR_ID
  stack         = stack_name                ; optional. defaults to repository setting
  recurse       = 0                         ; optional. defaults to repository setting
  pinto_exe     = /path/to/pinto            ; optional. defaults to searching PATH
  username      = you                       ; optional. defaults to PINTO_USERNAME
  password      = secret                    ; optional. will prompt if needed
  authenticate  = 1                         ; optional. defaults to 0

  # Then run the release command
  dzil release

=head1 DESCRIPTION

This is a release-stage plugin for L<Dist::Zilla> that will ship your
distribution releases to a local or remote L<Pinto> repository.

Before building the release, all repositories are checked for connectivity. If
a repository is not responding you will be prompted to skip it or abort the
entire release.  If none of the repositories are responding, then the release
will be aborted.  Any errors encountered while shipping to the remaining
repositories will also cause the rest of the release to abort.

B<IMPORTANT:> You need to install L<Pinto> to make this plugin work.  It ships
separately so you can decide how you want to install it.  Peronally, I
recommend installing Pinto as a stand-alone application as described in
L<Pinto::Manual::Installing> and then setting the C<PINTO_HOME> environment
variable accordingly.  But you can also just install Pinto from CPAN using the
usual tools.

=for Pod::Coverage before_release release mvp_multivalue_args

=head1 CONFIGURATION

The following configuration parameters can be set in the C<[Pinto::Add]>
section of the F<dist.ini> file for your distribution.  Defaults for most
paramters can be set via environment variables or via the repository
configuration.

=over 4

=item root = REPOSITORY

Specifies the root of the Pinto repository you want to ship to.  It can be
either a path to a local repository or a URI where L<pintod> is listening. If
not specified, it defaults to the C<PINTO_REPOSITORY_ROOT> environment
variable.  You can ship to multiple repositories by specifying the C<root>
parameter multiple times.  See also L</"USING MULTIPLE REPOSITORIES">.

=item authenticate = 0|1

Indicates that authentication is required for communicating with the
repository.  If true, you will be prompted for a C<password> unless it is
provided as described below.  Default is false.

=item author = NAME

Specifies your identity as a module author.  It must be two or more
alphanumeric characters and it will be forced to UPPERCASE. If not specified,
it defaults to either the C<PINTO_AUTHOR_ID> environment variable, or else
your PAUSE ID (if you have one configured in F<~/.pause>), or else the
C<username> parameter.

=item password = PASSWORD

Specifies the password to use for authentication.  If not specified, it
defaults to the C<PINTO_PASSWORD> environment variable, or else you will be
prompted to enter a password.  If your repository does require authentication,
then you must also set the C<authenticate> parameter to 1.  For security
reasons, I do not recommend putting your password in the F<dist.ini> file.

=item recurse = 0|1

If true, Pinto will recursively pull all the distributions required to satisfy
the prerequisites for the distribution you are adding.  If false, Pinto will
add the distribution only.  If not specified, the default behavior is
determined by the repository configuration.

=item stack = NAME

Specifies which stack in the repository to put the released distribution into.
If not specified, it defaults to the stack that is currently marked as the
default within the repository.

=item username = NAME

Specifies the username for server authentication.  If not specified, it
defaults to the C<PINTO_USERNAME> environment variable, or else your current
shell login.

=item pinto_exe = PATH

Specifies the full path to your C<pinto> executable.  If not specified, your
C<PATH> will be searched.

=back

=head1 USING MULTIPLE REPOSITORIES

You can ship your distribution to multiple repositories by specifying multiple
the C<root> paramter multiple times in your F<dist.ini> file.  In that case,
the remaining parameters (e.g. C<stack>, C<author>, C<authenticate>) will
apply to all the repositories.

However, the recommended way to release to multiple repositories is to have
multiple C<[Pinto::Add / NAME]> blocks in your F<dist.ini> file.  This allows
you to set attributes for each repository independently (at the expense of
possibly having to duplicating some information).

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::Pinto::Add

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Plugin-Pinto-Add>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Pinto-Add>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Dist-Zilla-Plugin-Pinto-Add>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Pinto-Add>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Pinto-Add>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Pinto::Add>

=back

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #pinto then talk to this person for help: thaljef.

=back

=head2 Bugs / Feature Requests

L<https://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add/issues>

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add>

  git clone git://github.com/thaljef/Dist-Zilla-Plugin-Pinto-Add.git

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
