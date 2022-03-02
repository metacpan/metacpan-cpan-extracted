package Git::Lint;

use strict;
use warnings;

use Git::Lint::Config;
use Try::Tiny;
use Module::Loader;

our $VERSION = '0.012';

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
        die "git-lint: $required is required\n"
            unless defined $opt->{$required};
    }

    if ( $opt->{check} ne 'message' && $opt->{check} ne 'commit' ) {
        die "git-lint: check must be either message or commit\n";
    }

    if ( $opt->{check} eq 'message' ) {
        die "git-lint: file is required if check is message\n"
            unless defined $opt->{file};
    }

    die 'git-lint: profile ' . $opt->{profile} . ' was not found' . "\n"
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
            die "git-lint: $exception\n";
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

=head1 ENABLING CHECKS FOR REPOS

To enable as a C<pre-commit> hook, copy the C<pre-commit> script from the C<example/hooks> directory into the C<.git/hooks> directory of the repo you want to check.

Once copied, update the path and options to match your path and preferred profile.

To enable as a C<commit-msg> hook, copy the C<commit-msg> script from the C<example/hooks> directory into the C<.git/hooks> directory of the repo you want to check.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Blaine Motsinger under the MIT license.

=head1 AUTHOR

Blaine Motsinger C<blaine@renderorange.com>

=cut
