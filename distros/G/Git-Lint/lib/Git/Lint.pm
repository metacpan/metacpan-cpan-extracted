package Git::Lint;

use strict;
use warnings;

use Git::Lint::Config;
use Try::Tiny;
use Module::Loader;

our $VERSION = '1.000';

my $config;

sub new {
    my $class = shift;
    my $self  = { issues => undef };

    bless $self, $class;

    $config = Git::Lint::Config->load();

    return $self;
}

sub config {
    my $self = shift;
    return $config;
}

sub run {
    my $self = shift;
    my $opt  = shift;

    foreach my $required (qw{profile check}) {
        die "$required is required\n"
            unless defined $opt->{$required};
    }

    if ( $opt->{check} ne 'message' && $opt->{check} ne 'commit' ) {
        die "check must be either message or commit\n";
    }

    if ( $opt->{check} eq 'message' ) {
        die "file is required if check is message\n"
            unless defined $opt->{file};
    }

    die 'profile ' . $opt->{profile} . ' was not found' . "\n"
        unless exists $self->config->{profiles}{ $opt->{check} }{ $opt->{profile} };

    my $check = lc $opt->{check};
    $check = ucfirst $check;

    my $loader = Module::Loader->new;

    my @issues;
    foreach my $module ( @{ $self->config->{profiles}{ $opt->{check} }{ $opt->{profile} } } ) {
        my $class = q{Git::Lint::Check::} . $check . q{::} . $module;
        try {
            $loader->load($class);
        }
        catch {
            my $exception = $_;
            die "$exception\n";
        };
        my $plugin = $class->new();

        # TODO: this would be better to be named the same method
        my $input = ( $opt->{check} eq 'commit' ? $class->diff() : $class->message( file => $opt->{file} ) );

        # ensure the plugins don't manipulate the original input
        my @lines = @{$input};
        push @issues, $plugin->check( \@lines );
    }

    foreach my $issue (@issues) {
        if ( $opt->{check} eq 'commit' ) {
            push @{ $self->{issues}{ $issue->{filename} } }, $issue->{message};
        }
        else {
            push @{ $self->{issues} }, $issue->{message};
        }
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Git::Lint - lint git commits and messages

=head1 SYNOPSIS

 use Git::Lint;

 my $lint = Git::Lint->new();
 $lint->run({ check => 'commit', profile => 'default' });
 $lint->run({ check => 'message', file => 'file_path', profile => 'default' });

 git-lint [--check commit] [--check message <message_file>]
          [--profile <name>]
          [--version] [--help]

=head1 DESCRIPTION

C<Git::Lint> is a pluggable framework for linting git commits and messages.

For the commandline interface to C<Git::Lint>, see the documentation for L<git-lint>.

For adding check modules, see the documentation for L<Git::Lint::Check::Commit> and L<Git::Lint::Check::Message>.

=head1 CONSTRUCTOR

=over

=item new

Returns a reference to a new C<Git::Lint> object.

=back

=head1 METHODS

=over

=item run

Loads the check modules as defined by C<profile>.

C<run> expects the following arguments:

B<profile>

The name of a defined set of check modules to run.

B<check>

Either C<commit> or C<message>.

B<file>

If C<check> is C<message>, C<file> is required.

=item config

Returns the L<Git::Lint::Config> object created by C<Git::Lint>.

=back

=head1 INSTALLATION

To install C<Git::Lint>, download the latest release, then extract.

 tar xzvf Git-Lint-0.008.tar.gz
 cd Git-Lint-0.008

or clone the repo.

 git clone https://github.com/renderorange/Git-Lint.git
 cd Git-Lint

Generate the build and installation tooling.

 perl Makefile.PL

Then build, test, and install.

 make
 make test && make install

C<Git::Lint> can also be installed using L<cpanm>.

 cpanm Git::Lint

=head1 CONFIGURATION

Configuration is done through C<git config> files (F<~/.gitconfig> or F</repo/.git/config>).

Only one profile, C<default>, is defined internally. C<default> contains all check modules by default.

The C<default> profile can be overridden through C<git config> files (F<~/.gitconfig> or F</repo/.git/config>).

To set the default profile to only run the C<Whitespace> commit check:

 [lint "profiles.commit"]
     default = Whitespace

Or set the default profile to C<Whitespace> and the fictional commit check, C<Flipdoozler>:

 [lint "profiles.commit"]
     default = Whitespace, Flipdoozler

Additional profiles can be added with a new name and list of checks to run.

 [lint "profiles.commit"]
     default = Whitespace, Flipdoozler
     hardcore = Other, Module, Names

Message check profiles can also be defined.

 [lint "profiles.message"]
     # override the default profile to only contain SummaryLength, SummaryEndingPeriod, and BlankLineAfterSummary
     default = SummaryLength, SummaryEndingPeriod, BlankLineAfterSummary
     # create a summary profile with specific modules
     summary = SummaryEndingPeriod, SummaryLength

An example configuration is provided in the C<examples> directory of this project.

Configuration is required.  If no configuration exists, an error will be printed to STDERR, but the action allowed to complete.

 blaine@base ~/git/test (master *) $ git add test
 blaine@base ~/git/test (master +) $ git commit
 git-lint: [error] configuration setup is required. see the documentation for instructions.
 [master 894b6d0] test
  1 file changed, 1 insertion(+), 1 deletion(-)
 blaine@base ~/git/test (master) $

=head1 ADDING NEW CHECK MODULES

C<git-lint> can be configured to load check modules from a local directory using the C<localdir> configuration setting.

To load modules from a local directory, add the lint C<config> setting, with C<localdir> key and directory location to the git config file.

 [lint "config"]
     localdir = /home/blaine/tmp/git-lint/lib

In this example, we're adding a new commit check, C<Flipdoozler>.  Create the local directory and path for the new module.

 $ mkdir -p /home/blaine/tmp/git-lint/lib/Git/Lint/Check/Commit

Then add the new check module.

 $ vi /home/blaine/tmp/git-lint/lib/Git/Lint/Check/Commit/Flipdoozler.pm
 package Git::Lint::Check::Commit::Flipdoozler;
 ...

Update the commit check profile to use the new module.

 [lint "profiles.commit"]
     default = Whitespace, IndentTabs, MixedIndentTabsSpaces, Flipdoozler

C<git-lint> will now warn for the check contained in Flipdoozler.

 blaine@base ~/git/test (master +) $ git commit
 git-lint: [commit] test - Flipdoozler (line 18)
 blaine@base ~/git/test (master +) $

=head1 ENABLING CHECKS FOR REPOS

To enable as a C<pre-commit> hook, copy the C<pre-commit> script from the C<example/hooks> directory into the C<.git/hooks> directory of the repo you want to check.

Once copied, update the path and options to match your path and preferred profile.

To enable as a C<commit-msg> hook, copy the C<commit-msg> script from the C<example/hooks> directory into the C<.git/hooks> directory of the repo you want to check.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Blaine Motsinger under the MIT license.

=head1 AUTHOR

Blaine Motsinger C<blaine@renderorange.com>

=cut
