package Developer::Dashboard::CLI::Complete;

use strict;
use warnings;

our $VERSION = '5.51';

use Developer::Dashboard::Collector;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::CLI::Help ();
use Developer::Dashboard::CLI::TableHelpers qw(build_paths);
use Developer::Dashboard::CLI::Suggest;
use Developer::Dashboard::CLI::Ticket ();

# complete(%args)
# Returns shell-completion candidates for one dashboard command line snapshot.
# Input: array reference of words and the active completion word index.
# Output: ordered list of completion candidate strings.
sub complete {
    my (%args) = @_;
    my $words = $args{words} || die "Missing completion words\n";
    my $index = defined $args{index} ? $args{index} : die "Missing completion index\n";
    die "Completion words must be an array reference\n" if ref($words) ne 'ARRAY';

    my @words = @{$words};
    my $current = defined $words[$index] ? $words[$index] : '';
    my $suggest = Developer::Dashboard::CLI::Suggest->new();

    my @candidates;
    if ( $index <= 1 ) {
        @candidates = (
            $suggest->top_level_candidates,
            $suggest->skill_commands,
        );
    }
    elsif ( ( $words[1] || '' ) eq 'help' ) {
        @candidates = _help_target_candidates( \@words, $index );
    }
    elsif ( ( $words[1] || '' ) eq 'workspace' && $index == 2 && $current !~ /^-/ ) {
        my $provider = $args{ticket_sessions} || \&_ticket_sessions;
        @candidates = (
            _workspace_path_alias_candidates(),
            $provider->(),
        );
    }
    elsif (
        ( $words[1] || '' ) =~ /\A(?:restart|stop)\z/
        && ( $words[2] || '' ) eq 'collector'
        && $index == 3
      )
    {
        my $provider = $args{collector_names} || \&_collector_names;
        @candidates = $provider->();
    }
    elsif (
        ( $words[1] || '' ) =~ /\A(?:log|logs)\z/
        && ( $words[2] || '' ) eq 'collector'
        && $index == 3
      )
    {
        my $provider = $args{collector_names} || \&_collector_names;
        @candidates = $provider->();
    }
    elsif ( ( $words[1] || '' ) eq 'docker' && ( $words[2] || '' ) eq 'development' && $index == 3 ) {
        @candidates = qw(enable disable);
    }
    else {
        @candidates = _subcommand_candidates( $words[1] || '' );
    }

    if ( $current =~ /^-/ && $index >= 2 ) {
        my ( $command, $action ) = _option_context( \@words, $index );
        push @candidates, Developer::Dashboard::CLI::Help::options_for( $command, $action );
    }
    push @candidates, qw(-h --help) if $index <= 1 && $current =~ /^-/;
    push @candidates, 'help' if $index <= 1 || $current =~ /^h/i;

    my %seen;
    return grep { !$seen{$_}++ } grep { $current eq '' || index( $_, $current ) == 0 } @candidates;
}

# _help_target_candidates($words, $index)
# Returns public command or action names after the global `dashboard help` prefix.
# Input: command-line words array reference and active word index.
# Output: ordered help target candidates for the current nested namespace.
sub _help_target_candidates {
    my ( $words, $index ) = @_;
    if ( $index == 2 ) {
        return (
            Developer::Dashboard::CLI::Help::command_names(),
            sort keys %{ Developer::Dashboard::CLI::Help::aliases() },
        );
    }
    my $namespace = $words->[2] || '';
    my $action;
    for my $position ( 3 .. $index - 1 ) {
        my $token = $words->[$position];
        next if !defined $token || $token eq '' || $token =~ /^-/;
        my @actions = Developer::Dashboard::CLI::Help::actions_for($namespace);
        last if !grep { $_ eq $token } @actions;
        my $nested = "$namespace $token";
        my @nested_actions = Developer::Dashboard::CLI::Help::actions_for($nested);
        if (@nested_actions) {
            $namespace = $nested;
            $action = undef;
        }
        else {
            $action = $token;
        }
    }
    return Developer::Dashboard::CLI::Help::actions_for(
        defined $action ? "$namespace $action" : $namespace,
    );
}

# _option_context($words, $index)
# Finds the deepest catalogued command/action before the active option word.
# Input: command-line words array reference and active word index.
# Output: command name and optional action name for option completion.
sub _option_context {
    my ( $words, $index ) = @_;
    return () if ref($words) ne 'ARRAY' || $index < 2;
    my $command_word = defined $words->[1] ? $words->[1] : '';
    my $command = Developer::Dashboard::CLI::Help::aliases()->{$command_word}
      || $command_word;
    my $namespace = $command;
    my $action;
    for my $position ( 2 .. $index - 1 ) {
        my $token = $words->[$position];
        next if !defined $token || $token eq '' || $token =~ /^-/;
        my @actions = Developer::Dashboard::CLI::Help::actions_for($namespace);
        last if !grep { $_ eq $token } @actions;
        my $nested = "$namespace $token";
        my @nested_actions = Developer::Dashboard::CLI::Help::actions_for($nested);
        if (@nested_actions) {
            $namespace = $nested;
            $action = undef;
        }
        else {
            $action = $token;
        }
    }
    return ( $namespace, $action );
}

# _skill_path_alias_candidates($skill_name)
# Returns configured and Folder.pm aliases qualified by one skill name.
# Input: exact installed skill name typed before the final dot.
# Output: sorted fully qualified path-alias completion candidates.
sub _skill_path_alias_candidates {
    my ($skill_name) = @_;
    return if !defined $skill_name || $skill_name eq '';

    my $paths = build_paths();
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $configured = $config->path_aliases;

    require Developer::Dashboard::CLI::Paths;
    my $folder = Developer::Dashboard::CLI::Paths::_skill_folder_path_aliases(
        paths      => $paths,
        skill_name => $skill_name,
    );

    my $prefix = $skill_name . '.';
    my %names = map { index( $_, $prefix ) == 0 ? ( $_ => 1 ) : () } keys %{$configured};
    $names{$_} = 1 for keys %{$folder};
    return sort keys %names;
}

# _workspace_path_alias_candidates()
# Returns configured and Folder.pm path aliases for workspace-argument
# completion, keeping those path names out of the top-level command namespace.
# Input: none.
# Output: sorted list of configured or skill-provided path alias names.
sub _workspace_path_alias_candidates {
    my $paths = build_paths();
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $configured = $config->path_aliases || {};

    require Developer::Dashboard::CLI::Paths;
    my $folder = Developer::Dashboard::CLI::Paths::_skill_folder_path_aliases(
        paths => $paths,
    );

    my %names = map { $_ => 1 } keys %{$configured};
    $names{$_} = 1 for keys %{$folder};
    return sort keys %names;
}

# _subcommand_candidates($command)
# Returns static second-level completion candidates for supported built-in
# dashboard commands.
# Input: resolved first dashboard subcommand string.
# Output: ordered list of candidate strings.
sub _subcommand_candidates {
    my ($command) = @_;
    return Developer::Dashboard::CLI::Help::actions_for($command);
}

# _ticket_sessions()
# Returns the current tmux session names for dashboard ticket completion.
# Input: none.
# Output: ordered list of session name strings.
sub _ticket_sessions {
    return Developer::Dashboard::CLI::Ticket::list_sessions();
}

# _collector_names()
# Returns the union of configured and persisted collector names for completion.
# Input: none.
# Output: ordered list of collector name strings.
sub _collector_names {
    my $home = $ENV{HOME} || '';
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ grep { -d } map { "$home/$_" } qw(projects src work) ],
        project_roots   => [ grep { -d } map { "$home/$_" } qw(projects src work) ],
    );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new(
        files => $files,
        paths => $paths,
    );
    my $collector = Developer::Dashboard::Collector->new( paths => $paths );

    my %seen;
    my @names;
    for my $job ( @{ $config->collectors } ) {
        my $name = ref($job) eq 'HASH' ? $job->{name} : undef;
        next if !defined $name || $name eq '' || $seen{$name}++;
        push @names, $name;
    }
    for my $status ( $collector->list_collectors ) {
        my $name = ref($status) eq 'HASH' ? $status->{name} : undef;
        next if !defined $name || $name eq '' || $seen{$name}++;
        push @names, $name;
    }
    return @names;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::Complete - shell completion candidates for dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Complete;
  my @candidates = Developer::Dashboard::CLI::Complete::complete(
      words => [ 'dashboard', 'do' ],
      index => 1,
  );

=head1 DESCRIPTION

Builds completion candidates for dashboard subcommands, built-in second-level
actions, option flags, global help targets, dotted skill commands, and
workspace path aliases. Commands and aliases are separated by argument
position so dotted path names do not appear among command candidates.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module centralizes shell-completion candidate generation for C<dashboard>
and the C<d2> shortcut. It exposes top-level built-ins, layered custom
commands, dotted installed skill commands, and nested built-in actions through
one reusable API. Command and option candidates are read from the shared help
catalog; global C<dashboard help> completion follows the same nested action
tree. Docker completion lists C<compose>, C<list>, C<enable>, C<disable>, and
C<development>, then offers C<enable> and C<disable> after
C<docker development>. Workspace names and configured or skill-provided path
aliases are queried only for positional completion; option completion does not
invoke the tmux session provider or path alias providers.

=head1 WHY IT EXISTS

It exists because shell completion should not hardcode command lists inside the
generated shell snippets. Keeping completion discovery in Perl lets the shell
bootstrap ask the live DD-OOP-LAYERS runtime what commands and skills are
available. Dotted skill-command candidates are kept separate from path aliases;
path aliases are offered after C<workspace>, where they are valid targets.
After a command name, the help catalog provides valid public actions and
recognized option spellings, avoiding a second shell-side inventory.

=head1 WHEN TO USE

Use this file when changing shell completion behavior, the exposed subcommand
lists, or the interaction between tab completion and installed skills.

=head1 HOW TO USE

Call C<complete(words =E<gt> \@words, index =E<gt> $n)> with the command-line
snapshot the shell provided. The returned list is meant to be printed one entry
per line by the private completion helper.

=head1 WHAT USES IT

It is used by the private C<dashboard complete> helper, by generated bash and
zsh shell bootstraps, and by shell-smoke regression tests that pin the tab
completion contract.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::CLI::Complete -e 'print join qq(\n), Developer::Dashboard::CLI::Complete::complete(words => [qw(dashboard do)], index => 1)'

Preview top-level completion candidates from a source checkout.

Example 2:

  perl -Ilib -MDeveloper::Dashboard::CLI::Complete -e 'print join qq(\n), Developer::Dashboard::CLI::Complete::complete(words => [qw(dashboard docker co)], index => 2)'

Preview second-level completion candidates for one built-in command.

Example 3:

  perl -Ilib -MDeveloper::Dashboard::CLI::Complete -e 'print join qq(\n), Developer::Dashboard::CLI::Complete::complete(words => [qw(d2 docker development)], index => 3)'

Preview the nested Docker development actions.

Example 4:

  prove -lv t/05-cli-smoke.t

Run the focused shell-completion regression tests.

Example 5:

  prove -lr t

Recheck completion behavior inside the full repository suite before release.

Example 6:

  dashboard complete 3 dashboard api add -

Print option candidates for the API add action, including long options, short
aliases, and the explicit help flags.

=for comment FULL-POD-DOC END

=cut
