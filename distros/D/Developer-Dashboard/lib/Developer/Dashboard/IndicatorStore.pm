package Developer::Dashboard::IndicatorStore;

use strict;
use warnings;
use utf8;

our $VERSION = '2.02';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Fcntl qw(:flock);
use File::Spec;
use Time::HiRes qw(time);

use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::Platform qw(command_in_path);

my $STATUS_ICONS = {
    ok => {
        yes     => '&#x2705;',
        running => '&#x2705;',
        secure  => '&#x2705;',
        ok      => '&#x2705;',
        clean   => '&#x2705;',
    },
    error => {
        wrong     => '&#x1F6A8;',
        stopped   => '&#x1F6A8;',
        paused    => '&#x1F6A8;',
        insecure  => '&#x1F6A8;',
        reloading => '&#x1F6A8;',
        missing   => '&#x1F6A8;',
        error     => '&#x1F6A8;',
        dirty     => '&#x1F6A8;',
        down      => '&#x1F6A8;',
    },
};

my $PROMPT_STATUS_ICONS = {
    ok => {
        yes     => '✅',
        running => '✅',
        secure  => '✅',
        ok      => '✅',
        clean   => '✅',
    },
    error => {
        wrong     => '🚨',
        stopped   => '🚨',
        paused    => '🚨',
        insecure  => '🚨',
        reloading => '🚨',
        missing   => '🚨',
        error     => '🚨',
        dirty     => '🚨',
        down      => '🚨',
    },
};

# new(%args)
# Constructs the file-backed indicator store.
# Input: paths object.
# Output: Developer::Dashboard::IndicatorStore object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    return bless { paths => $paths }, $class;
}

# set_indicator($name, %data)
# Writes indicator state to the file-backed indicator store.
# Input: indicator name plus state fields such as label, icon, and status, and
# optional internal preserve fields used when config sync must not clobber a
# newer live status update.
# Output: saved indicator hash reference.
sub set_indicator {
    my ( $self, $name, %data ) = @_;
    my $dir  = $self->{paths}->indicator_dir($name);
    my $file = File::Spec->catfile( $dir, 'status.json' );
    my $lock = File::Spec->catfile( $dir, '.lock' );
    my $preserve_fields = delete $data{_preserve_existing_fields};
    my @preserve_existing = ref($preserve_fields) eq 'ARRAY' ? @{$preserve_fields} : ();

    open my $lock_fh, '>>', $lock or die "Unable to open $lock: $!";
    flock( $lock_fh, LOCK_EX ) or die "Unable to lock $lock: $!";
    my $existing = $self->_read_indicator_file($file) || {};

    for my $field (@preserve_existing) {
        next if !exists $existing->{$field};
        $data{$field} = $existing->{$field};
    }

    $data{name}       = $name;
    $data{updated_at} = time if !exists $data{updated_at};

    my $tmp = "$file.pending";
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode( \%data );
    close $fh;
    $self->{paths}->secure_file_permissions($tmp);

    unlink $file if -f $file;
    rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
    $self->{paths}->secure_file_permissions($file);

    return \%data;
}

# get_indicator($name)
# Loads a single indicator state record.
# Input: indicator name string.
# Output: indicator hash reference or undef when missing.
sub get_indicator {
    my ( $self, $name ) = @_;
    for my $file ( $self->_indicator_file_candidates($name) ) {
        my $item = $self->_read_indicator_file($file);
        return $item if $item;
    }
    return;
}

# list_indicators()
# Lists all valid stored indicators ordered by prompt priority.
# Input: none.
# Output: sorted list of indicator hash references.
sub list_indicators {
    my ($self) = @_;
    my %items;
    for my $root ( $self->{paths}->indicators_roots ) {
        next if !-d $root;
        opendir my $dh, $root or next;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            next if $items{$entry};
            my $item = eval { $self->get_indicator($entry) };
            $items{$entry} = $item if $item;
        }
        closedir $dh;
    }

    return sort { ($a->{priority} || 999) <=> ($b->{priority} || 999) || $a->{name} cmp $b->{name} } values %items;
}

# sync_collectors($jobs)
# Seeds or refreshes indicator records declared by collector config without
# clobbering live status from previous collector runs.
# Input: array reference of collector job hash references.
# Output: array reference of indicator hashes that were written.
sub sync_collectors {
    my ( $self, $jobs ) = @_;
    return [] if ref($jobs) ne 'ARRAY';
    return [] if !@{$jobs};

    my @written;
    my %active_collectors;
    for my $job ( @{$jobs} ) {
        next if ref($job) ne 'HASH';
        next if ref( $job->{indicator} ) ne 'HASH';
        next if !defined $job->{name} || $job->{name} eq '';

        $active_collectors{ $job->{name} } = 1;
        my $name = $job->{indicator}{name} || $job->{name} || next;
        my $existing = eval { $self->get_indicator($name) } || {};
        my $label = defined $job->{indicator}{label} && $job->{indicator}{label} ne ''
          ? $job->{indicator}{label}
          : $name;
        my %candidate = (
            %{$existing},
            %{ $job->{indicator} },
            name           => $name,
            label          => $label,
            status         => defined $existing->{status} && $existing->{status} ne '' ? $existing->{status} : 'missing',
            collector_name => $job->{name},
            managed_by_collector => 1,
            prompt_visible => exists $job->{indicator}{prompt_visible}
              ? $job->{indicator}{prompt_visible}
              : exists $existing->{prompt_visible}
              ? $existing->{prompt_visible}
              : 1,
        );
        if ( !$self->_indicator_matches( $existing, \%candidate ) ) {
            push @written, $self->set_indicator(
                $name,
                %candidate,
                _preserve_existing_fields => [ qw(status updated_at stale) ],
            );
        }
    }

    for my $indicator ( $self->list_indicators ) {
        next if ref($indicator) ne 'HASH';
        next if !$indicator->{managed_by_collector};
        my $collector_name = $indicator->{collector_name} || '';
        next if $collector_name eq '';
        next if $active_collectors{$collector_name};
        $self->delete_indicator( $indicator->{name} );
        push @written, { %{$indicator}, deleted => 1 };
    }

    return \@written;
}

# delete_indicator($name)
# Removes one persisted indicator record and its directory when present.
# Input: indicator name string.
# Output: true when cleanup completes.
sub delete_indicator {
    my ( $self, $name ) = @_;
    return 1 if !defined $name || $name eq '';
    for my $dir ( map { File::Spec->catdir( $_, $name ) } $self->{paths}->indicators_roots ) {
        my $file = File::Spec->catfile( $dir, 'status.json' );
        unlink $file if -f $file;
        rmdir $dir if -d $dir;
    }
    return 1;
}

# _indicator_file_candidates($name)
# Returns candidate indicator status files across every runtime layer in lookup
# order from deepest to home.
# Input: indicator name string.
# Output: ordered list of file path strings.
sub _indicator_file_candidates {
    my ( $self, $name ) = @_;
    return map { File::Spec->catfile( $_, $name, 'status.json' ) } $self->{paths}->indicators_roots;
}

# mark_stale($name, %opts)
# Marks a stored indicator as stale for prompt/dashboard display.
# Input: indicator name and optional replacement status.
# Output: updated indicator hash reference or undef when missing.
sub mark_stale {
    my ( $self, $name, %opts ) = @_;
    my $item = $self->get_indicator($name) || return;
    $item->{stale} = 1;
    $item->{status} = $opts{status} if defined $opts{status};
    return $self->set_indicator( $name, %$item );
}

# is_stale($item, %opts)
# Checks whether an indicator should be treated as stale.
# Input: indicator hash reference and optional max_age threshold.
# Output: boolean stale flag.
sub is_stale {
    my ( $self, $item, %opts ) = @_;
    return if ref($item) ne 'HASH';
    return 1 if $item->{stale};
    my $max_age = defined $opts{max_age} ? $opts{max_age} : 300;
    return if !$item->{updated_at};
    return ( time - $item->{updated_at} ) > $max_age ? 1 : 0;
}

# refresh_core_indicators(%args)
# Refreshes the built-in generic indicators from local machine state.
# Input: optional cwd to resolve project-related state.
# Output: array reference of updated indicator records.
sub refresh_core_indicators {
    my ( $self, %args ) = @_;
    my $cwd   = $args{cwd} || $self->{paths}->current_project_root || $self->{paths}->home;
    my $items = [];

    my $docker_ok = command_in_path('docker') ? 1 : 0;
    push @$items, $self->set_indicator(
        'docker',
        alias          => '🐳',
        label          => 'Docker',
        icon           => '🐳',
        page_status_icon => $docker_ok ? '&#x1F7E2;' : '&#x1F534;',
        status         => $docker_ok ? 'ok' : 'missing',
        priority       => 20,
        prompt_visible => 1,
    );

    my $project = $self->{paths}->project_root_for($cwd);
    push @$items, $self->set_indicator(
        'project',
        label          => $project || '(no-project)',
        icon           => 'P',
        status         => $project ? 'ok' : 'none',
        priority       => 50,
        prompt_visible => 0,
    );

    my $git_status = 'none';
    if ($project) {
        my $old = cwd();
        chdir $project or die "Unable to chdir to $project: $!";
        my ( $stdout, $stderr, $inside_exit ) = capture {
            system( 'git', 'rev-parse', '--is-inside-work-tree' );
            return $? >> 8;
        };
        my $inside_work_tree = $inside_exit == 0 && $stdout =~ /^\s*true\s*$/m ? 1 : 0;
        if ($inside_work_tree) {
            my ( undef, undef, $dirty_exit ) = capture {
                system( 'git', 'diff', '--quiet', '--ignore-submodules', 'HEAD', '--' );
                return $? >> 8;
            };
            $git_status = $dirty_exit == 0 ? 'clean' : 'dirty';
        }
        chdir $old or die "Unable to restore cwd to $old: $!";
    }
    push @$items, $self->set_indicator(
        'git',
        label          => $git_status eq 'dirty' ? 'Git*' : 'Git',
        icon           => 'G',
        status         => $git_status,
        priority       => 30,
        prompt_visible => 0,
    );

    return $items;
}

# page_header_items()
# Builds the older top-of-page status payload from stored indicators.
# Input: none.
# Output: list of hashes with prog, alias, and status fields.
sub page_header_items {
    my ($self) = @_;
    my @items;
    for my $indicator ( sort { $a->{name} cmp $b->{name} } $self->list_indicators ) {
        next if exists $indicator->{prompt_visible} && !$indicator->{prompt_visible};
        my $alias = defined $indicator->{alias} && $indicator->{alias} ne ''
          ? $indicator->{alias}
          : defined $indicator->{icon} && $indicator->{icon} ne ''
          ? $indicator->{icon}
          : defined $indicator->{label} && $indicator->{label} ne ''
          ? $indicator->{label}
          : $indicator->{name};
        push @items, {
            prog   => $indicator->{name},
            alias  => $alias,
            status => $self->_page_status_icon($indicator),
        };
    }
    return @items;
}

# page_header_payload()
# Builds the older `/system/status` response payload shape.
# Input: none.
# Output: hash reference with array, hash, and status maps.
sub page_header_payload {
    my ($self) = @_;
    my @array = $self->page_header_items;
    my %hash  = map { $_->{prog} => { %$_ } } @array;
    return {
        array  => \@array,
        hash   => \%hash,
        status => $STATUS_ICONS,
    };
}

# prompt_status_icon($indicator)
# Resolves the prompt status glyph for one indicator record.
# Input: indicator hash reference.
# Output: plain-text status glyph or empty string.
sub prompt_status_icon {
    my ( $self, $indicator ) = @_;
    return $self->_status_icon_for( $indicator, $PROMPT_STATUS_ICONS );
}

# _page_status_icon($indicator)
# Resolves the page-header status icon for one indicator record.
# Input: indicator hash reference.
# Output: HTML entity or plain icon string.
sub _page_status_icon {
    my ( $self, $indicator ) = @_;
    return '' if ref($indicator) ne 'HASH';
    return $indicator->{page_status_icon} if defined $indicator->{page_status_icon} && $indicator->{page_status_icon} ne '';
    return $self->_status_icon_for( $indicator, $STATUS_ICONS );
}

# _indicator_matches($existing, $candidate)
# Compares persisted and candidate indicator fields to avoid rewriting files on
# every dashboard prompt render.
# Input: existing and candidate indicator hash references.
# Output: boolean true when the stored record already matches.
sub _indicator_matches {
    my ( $self, $existing, $candidate ) = @_;
    return 0 if ref($existing) ne 'HASH' || ref($candidate) ne 'HASH';
    for my $key ( qw(name label alias icon status priority prompt_visible page_status_icon collector_name managed_by_collector) ) {
        my $left  = exists $existing->{$key}  ? $existing->{$key}  : undef;
        my $right = exists $candidate->{$key} ? $candidate->{$key} : undef;
        $left  = '' if !defined $left;
        $right = '' if !defined $right;
        return 0 if $left ne $right;
    }
    return 1;
}

# _read_indicator_file($file)
# Reads and decodes one indicator status file when it exists.
# Input: absolute indicator status file path.
# Output: indicator hash reference or undef when the file is missing.
sub _read_indicator_file {
    my ( $self, $file ) = @_;
    return if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode(<$fh>);
}

# _status_icon_for($indicator, $map)
# Maps indicator status strings to either page-header or prompt glyphs.
# Input: indicator hash reference and icon lookup map.
# Output: resolved glyph string or the indicator icon as a fallback.
sub _status_icon_for {
    my ( $self, $indicator, $map ) = @_;
    return '' if ref($indicator) ne 'HASH';
    my $status = defined $indicator->{status} ? lc $indicator->{status} : '';
    return $map->{ok}{$status}    if exists $map->{ok}{$status};
    return $map->{error}{$status} if exists $map->{error}{$status};
    return defined $indicator->{icon} ? $indicator->{icon} : '';
}

1;

__END__

=head1 NAME

Developer::Dashboard::IndicatorStore - file-backed indicator state for Developer Dashboard

=head1 SYNOPSIS

  my $store = Developer::Dashboard::IndicatorStore->new(paths => $paths);
  $store->set_indicator('docker', status => 'ok');

=head1 DESCRIPTION

This module stores small status indicators that are consumed by prompt
rendering and dashboard views. It also provides a small built-in refresh path
for core generic indicators.

=head1 METHODS

=head2 new, set_indicator, get_indicator, list_indicators

Construct and manage the indicator store.

=head2 mark_stale, is_stale, refresh_core_indicators, page_header_items, page_header_payload

Handle stale state and refresh built-in generic indicators.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file persists and retrieves indicator state across runtime updates.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::IndicatorStore> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::IndicatorStore -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
