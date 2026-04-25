package Developer::Dashboard::CLI::Suggest;

use strict;
use warnings;

our $VERSION = '3.14';

use File::Basename qw(basename);
use File::Spec;
use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform qw(is_runnable_file);
use Developer::Dashboard::SkillManager;

# new(%args)
# Creates a command suggestion helper that can inspect built-ins, custom CLI
# commands, and installed skills across DD-OOP-LAYERS.
# Input: optional path registry and skill manager objects.
# Output: suggestion helper object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || Developer::Dashboard::PathRegistry->new(
        home            => $ENV{HOME},
        workspace_roots => [],
        project_roots   => [],
    );
    my $manager = $args{manager} || Developer::Dashboard::SkillManager->new( paths => $paths );
    return bless {
        paths   => $paths,
        manager => $manager,
    }, $class;
}

# unknown_command_message($command)
# Builds the stderr guidance shown when the public dashboard switchboard receives
# an unknown top-level command token.
# Input: mistyped command string.
# Output: formatted human-readable guidance string.
sub unknown_command_message {
    my ( $self, $command ) = @_;
    my @suggestions = $self->top_level_suggestions($command);
    my $message = "Unknown dashboard command '$command'.\n";
    if (@suggestions) {
        $message .= "\nDid you mean:\n";
        $message .= join '', map { "  dashboard $_\n" } @suggestions;
    }
    return $message . "\n";
}

# unknown_skill_command_message($skill_name, $command)
# Builds the stderr guidance shown when dotted skill dispatch fails because the
# skill is missing, disabled, or the command tail cannot be resolved.
# Input: skill repository name string and command-tail string.
# Output: formatted human-readable guidance string.
sub unknown_skill_command_message {
    my ( $self, $skill_name, $command ) = @_;
    my $skill_path = $self->{manager}->get_skill_path( $skill_name, include_disabled => 1 );
    if ( !$skill_path ) {
        my @suggestions = $self->skill_command_suggestions( "$skill_name.$command" );
        my $message = "Skill '$skill_name' not found.\n";
        if (@suggestions) {
            $message .= "\nDid you mean:\n";
            $message .= join '', map { "  dashboard $_\n" } @suggestions;
        }
        return $message . "\n";
    }

    if ( !$self->{manager}->is_enabled($skill_name) ) {
        return "Skill '$skill_name' is disabled.\n\nEnable it with:\n  dashboard skills enable $skill_name\n";
    }

    my @suggestions = $self->skill_command_suggestions( $command, $skill_name );
    my $message = "Command '$command' not found in skill '$skill_name'.\n";
    if (@suggestions) {
        $message .= "\nDid you mean:\n";
        $message .= join '', map { "  dashboard $_\n" } @suggestions;
    }
    return $message . "\n";
}

# top_level_suggestions($command)
# Returns the closest top-level dashboard command suggestions for one mistyped
# public command token.
# Input: mistyped command string.
# Output: ordered list of suggested command names without the dashboard prefix.
sub top_level_candidates {
    my ($self) = @_;
    return $self->_top_level_candidates;
}

# top_level_suggestions($command)
# Returns the closest top-level dashboard command suggestions for one mistyped
# public command token.
# Input: mistyped command string.
# Output: ordered list of suggested command names without the dashboard prefix.
sub top_level_suggestions {
    my ( $self, $command ) = @_;
    return map { $_->{value} } $self->_rank_candidates( $command, [ $self->_top_level_candidates ] );
}

# skill_command_suggestions($command, $skill_name)
# Returns the closest dotted skill command suggestions either for one concrete
# skill or across all installed skills when the skill name is unknown.
# Input: mistyped command-tail string plus optional skill repository name.
# Output: ordered list of dotted skill command strings.
sub skill_commands {
    my ( $self, $skill_name ) = @_;
    my @entries = $skill_name ? $self->_skill_command_entries($skill_name) : $self->_all_skill_command_entries;
    return map { $_->{full} } @entries;
}

# skill_command_suggestions($command, $skill_name)
# Returns the closest dotted skill command suggestions either for one concrete
# skill or across all installed skills when the skill name is unknown.
# Input: mistyped command-tail string plus optional skill repository name.
# Output: ordered list of dotted skill command strings.
sub skill_command_suggestions {
    my ( $self, $command, $skill_name ) = @_;
    my @candidates = $skill_name
      ? map { $_->{full} } $self->_skill_command_entries($skill_name)
      : map { $_->{full} } $self->_all_skill_command_entries;
    my $query = $skill_name ? "$skill_name.$command" : $command;
    return map { $_->{value} } $self->_rank_candidates( $query, \@candidates );
}

# _top_level_candidates()
# Enumerates the canonical top-level dashboard command names that users can run
# through the public switchboard.
# Input: none.
# Output: ordered list of command name strings.
sub _top_level_candidates {
    my ($self) = @_;
    my %seen;
    my @candidates = ();

    for my $name ( Developer::Dashboard::InternalCLI::helper_names() ) {
        next if $seen{$name}++;
        push @candidates, $name;
    }
    for my $alias ( sort keys %{ Developer::Dashboard::InternalCLI::helper_aliases() } ) {
        my $canonical = Developer::Dashboard::InternalCLI::helper_aliases()->{$alias};
        next if $seen{$canonical}++;
        push @candidates, $canonical;
    }
    for my $root ( $self->{paths}->cli_roots ) {
        next if !-d $root;
        opendir my $dh, $root or die "Unable to read $root: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' && $_ ne 'dd' && $_ !~ /\.d\z/ } readdir $dh ) {
            my $path = File::Spec->catfile( $root, $entry );
            my $logical = _logical_command_name($entry);
            next if !$logical;
            next if $seen{$logical}++;
            next if !( -d $path || is_runnable_file( File::Spec->catfile( $root, $logical ) ) );
            push @candidates, $logical;
        }
        closedir $dh;
    }

    return @candidates;
}

# _all_skill_command_entries()
# Enumerates every installed dotted skill command including nested
# skills/<repo>/skills/<repo>/... command trees.
# Input: none.
# Output: ordered list of hash refs containing full dotted command strings.
sub _all_skill_command_entries {
    my ($self) = @_;
    my @entries;
    for my $skill_root ( $self->{paths}->installed_skill_roots( include_disabled => 1 ) ) {
        push @entries, $self->_skill_command_entries( basename($skill_root) );
    }
    return @entries;
}

# _skill_command_entries($skill_name)
# Enumerates every dotted command exposed by one installed skill, including
# nested repeated skills/<repo> trees.
# Input: skill repository name string.
# Output: ordered list of hash refs containing full dotted command strings.
sub _skill_command_entries {
    my ( $self, $skill_name ) = @_;
    my $skill_root = $self->{manager}->get_skill_path( $skill_name, include_disabled => 1 );
    return () if !$skill_root;
    return $self->_collect_skill_commands( $skill_root, $skill_name );
}

# _collect_skill_commands($skill_root, $prefix)
# Recursively scans one installed skill root for runnable CLI entries and
# nested installed skills.
# Input: absolute skill root path string and dotted command prefix.
# Output: ordered list of hash refs containing full dotted command strings.
sub _collect_skill_commands {
    my ( $self, $skill_root, $prefix ) = @_;
    my @entries;
    my $cli_root = File::Spec->catdir( $skill_root, 'cli' );
    if ( -d $cli_root ) {
        opendir my $dh, $cli_root or die "Unable to read $cli_root: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' && $_ !~ /\.d\z/ } readdir $dh ) {
            my $logical = _logical_command_name($entry);
            next if !$logical;
            next if !is_runnable_file( File::Spec->catfile( $cli_root, $logical ) );
            push @entries, { full => "$prefix.$logical" };
        }
        closedir $dh;
    }

    my $nested_root = File::Spec->catdir( $skill_root, 'skills' );
    if ( -d $nested_root ) {
        opendir my $dh, $nested_root or die "Unable to read $nested_root: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' && -d File::Spec->catdir( $nested_root, $_ ) } readdir $dh ) {
            push @entries, $self->_collect_skill_commands( File::Spec->catdir( $nested_root, $entry ), "$prefix.$entry" );
        }
        closedir $dh;
    }

    return @entries;
}

# _rank_candidates($query, \@candidates)
# Scores candidate command strings against one mistyped user token and keeps the
# closest matches in deterministic order.
# Input: query string and array reference of candidate strings.
# Output: ordered list of hash refs containing value and score.
sub _rank_candidates {
    my ( $self, $query, $candidates ) = @_;
    return () if !defined $query || $query eq '';
    my @scored;
    my %seen;
    for my $candidate ( @{ $candidates || [] } ) {
        next if !defined $candidate || $candidate eq '' || $seen{$candidate}++;
        my $score = _candidate_score( $query, $candidate );
        next if !defined $score;
        push @scored, { value => $candidate, score => $score };
    }
    @scored = sort {
             $a->{score} <=> $b->{score}
          || length( $a->{value} ) <=> length( $b->{value} )
          || $a->{value} cmp $b->{value}
    } @scored;
    splice @scored, 5 if @scored > 5;
    return @scored;
}

# _candidate_score($query, $candidate)
# Computes a fuzzy-match score for one mistyped command against one candidate,
# rejecting matches that are too distant to be useful.
# Input: user query string and one candidate command string.
# Output: numeric score or undef when the candidate is too far away.
sub _candidate_score {
    my ( $query, $candidate ) = @_;
    my $normalized_query = _normalize_token($query);
    my $normalized_candidate = _normalize_token($candidate);
    return 0 if $normalized_query eq $normalized_candidate;
    return 1 if index( $normalized_candidate, $normalized_query ) == 0;

    my $distance = _levenshtein_distance( $normalized_query, $normalized_candidate );
    my $threshold = int( ( length($normalized_query) > length($normalized_candidate) ? length($normalized_query) : length($normalized_candidate) ) / 2 ) + 1;
    return if $distance > $threshold;
    return $distance + 2;
}

# _normalize_token($value)
# Normalizes a command token before fuzzy matching by lowercasing and removing
# punctuation that should not dominate typo scoring.
# Input: command string.
# Output: normalized string.
sub _normalize_token {
    my ($value) = @_;
    $value = lc( $value // '' );
    $value =~ s/[^a-z0-9]+//g;
    return $value;
}

# _levenshtein_distance($left, $right)
# Computes the edit distance between two normalized strings without introducing
# an extra non-core dependency.
# Input: two normalized strings.
# Output: integer edit distance.
sub _levenshtein_distance {
    my ( $left, $right ) = @_;
    my @left  = split //, $left;
    my @right = split //, $right;
    my @dist = ( 0 .. scalar @right );

    for my $i ( 1 .. scalar @left ) {
        my $previous = $dist[0];
        $dist[0] = $i;
        for my $j ( 1 .. scalar @right ) {
            my $current = $dist[$j];
            my $cost = $left[ $i - 1 ] eq $right[ $j - 1 ] ? 0 : 1;
            my $delete = $dist[$j] + 1;
            my $insert = $dist[ $j - 1 ] + 1;
            my $replace = $previous + $cost;
            my $best = $delete < $insert ? $delete : $insert;
            $best = $replace if $replace < $best;
            $dist[$j] = $best;
            $previous = $current;
        }
    }

    return $dist[-1];
}

# _logical_command_name($entry)
# Converts one staged runnable filename into the logical dashboard command token
# users type on the command line.
# Input: directory entry name.
# Output: logical command name string.
sub _logical_command_name {
    my ($entry) = @_;
    return '' if !defined $entry || $entry eq '';
    $entry =~ s/\.(?:pl|go|java|ps1|cmd|bat|sh|bash)\z//i;
    return $entry;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::Suggest - fuzzy command suggestions for dashboard typos

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Suggest;
  my $suggest = Developer::Dashboard::CLI::Suggest->new();
  print $suggest->unknown_command_message('dcoekr');

=head1 DESCRIPTION

Builds typo guidance for unknown top-level dashboard commands and dotted skill
commands by scanning built-ins, layered custom commands, and installed skills.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module centralizes typo suggestions for the public dashboard switchboard and dotted skill dispatch. It gathers built-in helpers, layered custom CLI commands, and installed skill commands, then ranks the nearest matches so error messages can give users a likely correction instead of only dumping generic help text.

=head1 WHY IT EXISTS

It exists because unknown-command handling belongs in reusable library code rather than inlined string assembly inside the public entrypoint and skill dispatcher. Keeping fuzzy matching here makes the typo contract testable and keeps the switchboard thin.

=head1 WHEN TO USE

Use this file when changing unknown-command stderr output, command discovery, dotted skill suggestions, or the ranking behavior for typo guidance.

=head1 HOW TO USE

Construct it with C<new>, then call C<unknown_command_message> for a mistyped public command or C<unknown_skill_command_message> for a dotted skill dispatch failure. The returned text is meant to be printed to stderr before the usual usage/help output.

=head1 WHAT USES IT

It is used by the public C<dashboard> switchboard for unknown top-level commands, by the skill dispatcher for dotted skill lookup failures, and by CLI regression tests that pin the user-facing typo guidance.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::CLI::Suggest -e 'print Developer::Dashboard::CLI::Suggest->new->unknown_command_message("dcoekr")'

Preview the top-level typo guidance from a source checkout.

Example 2:

  perl -Ilib -MDeveloper::Dashboard::CLI::Suggest -e 'print Developer::Dashboard::CLI::Suggest->new->unknown_skill_command_message("alpha-skill","run-tset")'

Preview the dotted skill typo guidance for one installed skill.

Example 3:

  prove -lv t/05-cli-smoke.t t/19-skill-system.t

Run the focused regression tests that cover the user-facing suggestion contract.

Example 4:

  prove -lr t

Recheck the suggestion behavior inside the full repository suite before release.

=for comment FULL-POD-DOC END

=cut
