package Developer::Dashboard::CLI::Complete;

use strict;
use warnings;

our $VERSION = '4.03';

use Developer::Dashboard::Collector;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
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
    elsif ( ( $words[1] || '' ) =~ /\A(?:workspace|ticket)\z/ && $index == 2 ) {
        my $provider = $args{ticket_sessions} || \&_ticket_sessions;
        @candidates = $provider->();
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
    else {
        @candidates = _subcommand_candidates( $words[1] || '' );
    }

    my %seen;
    return grep { !$seen{$_}++ } grep { !defined $current || $current eq '' || index( $_, $current ) == 0 } @candidates;
}

# _subcommand_candidates($command)
# Returns static second-level completion candidates for supported built-in
# dashboard commands.
# Input: resolved first dashboard subcommand string.
# Output: ordered list of candidate strings.
sub _subcommand_candidates {
    my ($command) = @_;
    return qw(install enable disable uninstall list usage) if $command eq 'skills' || $command eq 'skill';
    return qw(compose list enable disable) if $command eq 'docker';
    return qw(list resolve add del locate project-root) if $command eq 'path';
    return qw(web collector) if $command eq 'restart' || $command eq 'stop' || $command eq 'log' || $command eq 'logs';
    return qw(set list refresh-core) if $command eq 'indicator';
    return qw(write-result status list job output inspect log run start stop restart) if $command eq 'collector';
    return qw(init show) if $command eq 'config';
    return qw(add-user list-users remove-user) if $command eq 'auth';
    return qw(new save list show encode decode urls render source) if $command eq 'page';
    return qw(run) if $command eq 'action';
    return qw(logs workers) if $command eq 'serve';
    return qw(bash zsh sh ps powershell pwsh) if $command eq 'shell';
    return ();
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
        workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
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
actions, and dotted skill commands.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module centralizes shell-completion candidate generation for C<dashboard>
and the C<d2> shortcut. It exposes top-level built-ins, layered custom
commands, dotted installed skill commands, and selected built-in second-level
subcommands through one reusable API.

=head1 WHY IT EXISTS

It exists because shell completion should not hardcode command lists inside the
generated shell snippets. Keeping completion discovery in Perl lets the shell
bootstrap ask the live DD-OOP-LAYERS runtime what commands and skills are
available.

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

  prove -lv t/05-cli-smoke.t

Run the focused shell-completion regression tests.

Example 4:

  prove -lr t

Recheck completion behavior inside the full repository suite before release.

=for comment FULL-POD-DOC END

=cut
