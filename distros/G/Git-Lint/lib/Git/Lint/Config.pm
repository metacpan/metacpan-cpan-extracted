package Git::Lint::Config;

use strict;
use warnings;

use Module::Loader;
use List::MoreUtils ();
use Git::Lint::Command;

our $VERSION = '1.000';

sub load {
    my $class = shift;
    my $self  = { profiles => undef };

    $self->{profiles}{commit}{default}  = [];
    $self->{profiles}{message}{default} = [];

    bless $self, $class;

    my $user_config = $self->user_config();

    # add user defined config settings
    if ( exists $user_config->{config} ) {
        $self->{config} = $user_config->{config};
    }

    # if localdir is defined, add it into INC to load modules from
    if ( exists $self->{config} && defined $self->{config}{localdir} ) {
        if ( -d $self->{config}{localdir} ) {
            push @INC, $self->{config}{localdir};
        }
        else {
            warn "git-lint: [warn] configured localdir $self->{config}{localdir} isn't a readable directory\n";
        }
    }

    # all check modules are added to the default profile
    my $loader        = Module::Loader->new;
    my $namespace     = 'Git::Lint::Check::Commit';
    my @commit_checks = List::MoreUtils::apply {s/$namespace\:\://g} $loader->find_modules( $namespace, { max_depth => 1 } );

    if (@commit_checks) {
        $self->{profiles}{commit}{default} = \@commit_checks;
    }

    $namespace = 'Git::Lint::Check::Message';
    my @message_checks = List::MoreUtils::apply {s/$namespace\:\://g} $loader->find_modules( $namespace, { max_depth => 1 } );

    if (@message_checks) {
        $self->{profiles}{message}{default} = \@message_checks;
    }

    # user defined profiles override internally defined profiles
    foreach my $check ( keys %{ $user_config->{profiles} } ) {
        foreach my $profile ( keys %{ $user_config->{profiles}{$check} } ) {
            $self->{profiles}{$check}{$profile} = $user_config->{profiles}{$check}{$profile};
        }
    }

    return $self;
}

sub user_config {
    my $self = shift;

    my @git_config_cmd = (qw{ git config --get-regexp ^lint });

    my ( $stdout, $stderr, $exit ) = Git::Lint::Command::run( \@git_config_cmd );

    # if there is no user config, the git config command above will return 1
    # but without stderr.
    if ( $exit && !$stderr ) {
        die "configuration setup is required. see the documentation for instructions.\n";
    }

    # if there was an error, propagate that up.
    if ( $exit && $stderr ) {
        die "$stderr\n";
    }

    my %parsed_config = ();

    # load check profiles
    foreach my $line ( split( /\n/, $stdout ) ) {
        next unless $line =~ /^lint\.profiles\.(\w+)\.(\w+)\s+(.+)$/;
        my ( $check, $profile, $value ) = ( $1, $2, $3 );

        my @values = List::MoreUtils::apply {s/^\s+|\s+$//g} split( /,/, $value );
        push @{ $parsed_config{profiles}{$check}{$profile} }, @values;
    }

    # load other config settings
    foreach my $line ( split( /\n/, $stdout ) ) {
        if ( $line =~ /^lint\.config\.localdir\s+(.+)$/ ) {
            my ($value) = ($1);
            $parsed_config{config}{localdir} = $value;
        }
    }

    return \%parsed_config;
}

1;

__END__

=pod

=head1 NAME

Git::Lint::Config - configuration for L<Git::Lint>

=head1 SYNOPSIS

 use Git::Lint::Config;

 my $config   = Git::Lint::Config->load();
 my $profiles = $config->{profiles};

=head1 DESCRIPTION

C<Git::Lint::Config> defines and loads settings for L<Git::Lint>.

=head1 CONSTRUCTOR

=head2 load

Loads check modules and user config, then returns the C<Git::Lint::Config> object.

=head1 METHODS

=head2 user_config

Reads, parses, and returns the user config settings from C<git config>.

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

=cut
