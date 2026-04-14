package Developer::Dashboard::CLI::Skills;

use strict;
use warnings;

our $VERSION = '2.35';

use Getopt::Long qw(GetOptionsFromArray);
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;

# run_skills_command(%args)
# Dispatches the lightweight dashboard skills helper command.
# Input: command name under "command" and remaining argv array reference under
# "args".
# Output: prints JSON or table output to STDOUT and returns the process exit
# code, or dies with a usage message when the arguments are invalid.
sub run_skills_command {
    my (%args) = @_;
    my $command = $args{command} || die "Missing command name\n";
    my $argv    = $args{args}    || die "Missing command arguments\n";
    die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';

    my @argv = @{$argv};
    my $action = shift @argv || '';
    my $manager = Developer::Dashboard::SkillManager->new( paths => _build_paths() );

    if ( $action eq 'install' ) {
        my $git_url = shift @argv || die "Usage: dashboard skills install <git-url>\n";
        my $result = $manager->install($git_url);
        print json_encode($result);
        return $result->{error} ? 1 : 0;
    }
    if ( $action eq 'uninstall' ) {
        my $repo_name = shift @argv || die "Usage: dashboard skills uninstall <repo-name>\n";
        my $result = $manager->uninstall($repo_name);
        print json_encode($result);
        return $result->{error} ? 1 : 0;
    }
    if ( $action eq 'update' ) {
        my $repo_name = shift @argv || die "Usage: dashboard skills update <repo-name>\n";
        my $result = $manager->update($repo_name);
        print json_encode($result);
        return $result->{error} ? 1 : 0;
    }
    if ( $action eq 'enable' ) {
        my $repo_name = shift @argv || die "Usage: dashboard skills enable <repo-name>\n";
        my $result = $manager->enable($repo_name);
        print json_encode($result);
        return $result->{error} ? 1 : 0;
    }
    if ( $action eq 'disable' ) {
        my $repo_name = shift @argv || die "Usage: dashboard skills disable <repo-name>\n";
        my $result = $manager->disable($repo_name);
        print json_encode($result);
        return $result->{error} ? 1 : 0;
    }
    if ( $action eq 'list' ) {
        my $output = 'json';
        GetOptionsFromArray( \@argv, 'o|output=s' => \$output );
        my $skills = $manager->list();
        if ( $output eq 'json' ) {
            print json_encode( { skills => $skills } );
            return 0;
        }
        if ( $output eq 'table' ) {
            print _skills_table($skills);
            return 0;
        }
        die "Usage: dashboard skills list [-o json|table]\n";
    }
    if ( $action eq 'usage' ) {
        my $output = 'json';
        GetOptionsFromArray( \@argv, 'o|output=s' => \$output );
        my $repo_name = shift @argv || die "Usage: dashboard skills usage <repo-name> [-o json|table]\n";
        my $usage = $manager->usage($repo_name);
        if ( $output eq 'json' ) {
            print json_encode($usage);
            return $usage->{error} ? 1 : 0;
        }
        if ( $output eq 'table' ) {
            die $usage->{error} . "\n" if $usage->{error};
            print _usage_table($usage);
            return 0;
        }
        die "Usage: dashboard skills usage <repo-name> [-o json|table]\n";
    }
    if ( $action eq '_exec' ) {
        require Developer::Dashboard::SkillDispatcher;
        my $skill_name = shift @argv || die "Usage: dashboard <skill-name>.<command> [args...]\n";
        my $skill_cmd  = shift @argv || die "Usage: dashboard <skill-name>.<command> [args...]\n";
        my $dispatcher = Developer::Dashboard::SkillDispatcher->new();
        my $result = $dispatcher->dispatch( $skill_name, $skill_cmd, @argv );
        if ( $result->{error} ) {
            print STDERR $result->{error}, "\n";
            return 1;
        }
        print $result->{stdout} if $result->{stdout};
        print STDERR $result->{stderr} if $result->{stderr};
        return $result->{exit_code} || 0;
    }

    die "Unknown skills action: $action\nUsage: dashboard skills [install|uninstall|update|enable|disable|list|usage]\n";
}

# _build_paths()
# Builds the lightweight path registry used by the skills helper.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object.
sub _build_paths {
    my $home = $ENV{HOME} || '';
    return Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
    );
}

# _skills_table($skills)
# Renders one skills list payload as a human-readable table.
# Input: array reference of skill metadata hashes.
# Output: formatted text string.
sub _skills_table {
    my ($skills) = @_;
    my @rows = map {
        [
            $_->{name},
            _tick( $_->{enabled} ),
            $_->{cli_commands_count} || 0,
            $_->{pages_count} || 0,
            $_->{docker_services_count} || 0,
            $_->{collectors_count} || 0,
            $_->{indicators_count} || 0,
        ]
    } @{ $skills || [] };
    return _render_table(
        [ 'Repo', 'Enabled', 'CLI', 'Pages', 'Docker', 'Collectors', 'Indicators' ],
        \@rows,
    );
}

# _usage_table($usage)
# Renders one detailed skill usage payload as sectioned tables.
# Input: skill usage hash reference.
# Output: formatted text string.
sub _usage_table {
    my ($usage) = @_;
    my $text = '';
    $text .= "Skill: $usage->{name}\n";
    $text .= "Enabled: " . _tick( $usage->{enabled} ) . "\n";
    $text .= "Path: $usage->{path}\n";
    $text .= "Config Root: $usage->{config}{root}\n";
    $text .= "Config File: $usage->{config}{file}\n";
    $text .= "Docker Root: $usage->{docker}{root}\n\n";

    $text .= "CLI Commands\n";
    $text .= _render_table(
        [ 'Command', 'Hooks', 'Hook Count', 'Path' ],
        [
            map {
                [ $_->{name}, _tick( $_->{has_hooks} ), $_->{hook_count} || 0, $_->{path} ]
            } @{ $usage->{cli} || [] }
        ],
    );
    $text .= "\nPages\n";
    $text .= _render_table(
        [ 'Type', 'Entry' ],
        [
            ( map { [ 'page', $_ ] } @{ $usage->{pages}{entries} || [] } ),
            ( map { [ 'nav',  $_ ] } @{ $usage->{pages}{nav_entries} || [] } ),
        ],
    );
    $text .= "\nDocker Services\n";
    $text .= _render_table(
        [ 'Service', 'Files' ],
        [
            map { [ $_->{name}, join ', ', @{ $_->{files} || [] } ] } @{ $usage->{docker}{services} || [] }
        ],
    );
    $text .= "\nCollectors\n";
    $text .= _render_table(
        [ 'Name', 'Qualified', 'Indicator', 'Schedule' ],
        [
            map {
                [
                    $_->{name},
                    $_->{qualified_name},
                    _tick( $_->{has_indicator} ),
                    defined $_->{interval} ? 'interval=' . $_->{interval} : ( $_->{schedule} || '' ),
                ]
            } @{ $usage->{collectors} || [] }
        ],
    );
    return $text;
}

# _render_table($header, $rows)
# Formats a rectangular data set as a padded text table.
# Input: header array reference and row array reference.
# Output: text string ending in a newline.
sub _render_table {
    my ( $header, $rows ) = @_;
    my @rows = @{ $rows || [] };
    my @widths = map { length _plain_text($_) } @{ $header || [] };
    for my $row (@rows) {
        for my $idx ( 0 .. $#{$row} ) {
            my $value = defined $row->[$idx] ? $row->[$idx] : '';
            my $width = length _plain_text($value);
            $widths[$idx] = $width if !defined $widths[$idx] || $width > $widths[$idx];
        }
    }

    my @lines;
    push @lines, _format_row( $header, \@widths );
    push @lines, _format_row( [ map { '-' x $widths[$_] } 0 .. $#widths ], \@widths );
    push @lines, map { _format_row( $_, \@widths ) } @rows;
    return join( "\n", @lines ) . "\n";
}

# _format_row($row, $widths)
# Pads one table row to the requested column widths.
# Input: row array reference and width array reference.
# Output: padded row text.
sub _format_row {
    my ( $row, $widths ) = @_;
    my @cells;
    for my $idx ( 0 .. $#{$widths} ) {
        my $value = defined $row->[$idx] ? $row->[$idx] : '';
        my $plain = _plain_text($value);
        push @cells, $value . ( ' ' x ( $widths->[$idx] - length($plain) ) );
    }
    return join '  ', @cells;
}

# _tick($value)
# Converts a boolean-like value into a colored tick or cross marker.
# Input: scalar truthy or falsey value.
# Output: UTF-8 checkmark/cross string with ANSI color.
sub _tick {
    my ($value) = @_;
    return $value ? "\e[32m✓\e[0m" : "\e[31m✗\e[0m";
}

# _plain_text($value)
# Removes ANSI color escapes from one display string.
# Input: scalar value.
# Output: plain string without ANSI escapes.
sub _plain_text {
    my ($value) = @_;
    $value = '' if !defined $value;
    $value =~ s/\e\[[0-9;]*m//g;
    return $value;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::Skills - lightweight skills helper dispatch

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Skills qw(run_skills_command);
  run_skills_command(command => 'skills', args => \@ARGV);

=head1 DESCRIPTION

Implements the staged C<dashboard skills> helper so the public entrypoint can
hand off skill management to a dedicated Perl module instead of embedding the
action parsing inline.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the command runtime behind C<dashboard skills>. It owns the CLI parsing for skill install, update, uninstall, enable, disable, list, and usage; prints canonical JSON by default; renders optional table output for human inspection; and handles the internal dotted-command handoff used by C<dashboard E<lt>repo-nameE<gt>.E<lt>commandE<gt>>.

=head1 WHY IT EXISTS

It exists because the skill lifecycle contract grew beyond a single inline branch. Keeping that contract in one dedicated module makes it easier to evolve the CLI, preserve JSON output guarantees, keep disabled-skill semantics consistent across management commands, and route dotted skill command execution without restoring a separate singular helper.

=head1 WHEN TO USE

Use this file when changing the public C<dashboard skills ...> verbs, the JSON payloads returned by C<list> or C<usage>, or the human-facing table output used for quick inspection in a terminal.

=head1 HOW TO USE

Call C<run_skills_command> with the public helper name and argv array reference. The module builds a lightweight path registry, constructs a skill manager, dispatches the requested action, and prints either canonical JSON or sectioned tables depending on C<-o json> or C<-o table>. The default output for C<list> and C<usage> is JSON. The thin C<dashboard> switchboard also routes dotted skill execution through this helper with an internal action so the public execution contract stays C<dashboard E<lt>repo-nameE<gt>.E<lt>commandE<gt>>.

=head1 WHAT USES IT

It is used by the staged C<skills> private helper, by dotted skill command dispatch from the public switchboard, by CLI smoke and skill lifecycle tests, and by contributors verifying how disabled skills remain installed yet drop out of runtime lookup.

=head1 EXAMPLES

  dashboard skills list
  dashboard skills list -o table
  dashboard skills usage example-skill
  dashboard skills usage example-skill -o table
  dashboard skills disable example-skill
  dashboard skills enable example-skill

=for comment FULL-POD-DOC END

=cut
