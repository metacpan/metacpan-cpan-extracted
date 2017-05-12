package Log::Reproducible;
use strict;
use warnings;
use Cwd;
use File::Path 'make_path';
use File::Basename;
use File::Spec;
use File::Temp ();
use IPC::Open3;
use List::MoreUtils 'first_index';
use POSIX qw(strftime difftime ceil floor);
use Config;
use YAML::Old qw(Dump LoadFile);    # YAML::XS & YAML::Syck aren't working properly

# TODO: Add tests for conflicting module checker
# TODO: Add verbose (or silent) option
# TODO: Standalone script that can be used upstream of any command line functions
# TODO: Auto-build README using POD

our $VERSION = '0.12.4';

=head1 NAME

Log::Reproducible - Effortless record-keeping and enhanced reproducibility. Set it and forget it... until you need it!

=head1 AUTHOR

Michael F. Covington <mfcovington@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016, Michael F. Covington.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.10.0. For more details,
see the full text of the licenses in the file LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

sub _check_for_known_conflicting_modules {
    my @known_conflicts = @_;

    # Only check for conflicts if Module::Loaded is available (i.e. >= 5.9.4)
    eval "use Module::Loaded";
    return if $@;
    require Module::Loaded;

    my @loaded_conflicts;
    for (@known_conflicts) {
        push @loaded_conflicts, $_ if defined is_loaded($_);
    }

    if (@loaded_conflicts) {
        my $conflict_warning = <<EOF;

KNOWN CONFLICT WARNING:
A module that accesses '\@ARGV' has been loaded before @{[__PACKAGE__]}.
This module is known to create a conflict with @{[__PACKAGE__]} functionality.
To avoid any conflicts, we strongly recommended changing your script such
that @{[__PACKAGE__]} is imported before the following module(s):

EOF
        $conflict_warning .= "    $_\n" for sort @loaded_conflicts;
        print STDERR "$conflict_warning\n";
    }
}

sub _check_for_potentially_conflicting_modules {
    my $code = do { open my $fh, '<', $0 or return; local $/; <$fh> };
    my ($code_to_test) = $code =~ /(\A .*?) use \s+ @{[__PACKAGE__]}/sx;
    return unless defined $code_to_test;    # Required for standalone perlr
    my ( $temp_fh, $temp_filename ) = File::Temp::tempfile();
    print $temp_fh $code_to_test;

    local ( *CIN, *COUT, *CERR );
    my $perl = $Config{perlpath};
    my $cmd  = "$perl -MO=Xref,-r $temp_filename";
    my $pid  = open3( \*CIN, \*COUT, \*CERR, $cmd );

    my $re
        = '((?:'
        . join( '|' => map { /^(?:\.[\\\/]?)?(.*)$/; "\Q$1" } @INC )
        . ')[\\\/]?\S+?)(?:\.\S+)?\s+(\S+)';
    my %argv_modules;

    for (<COUT>) {
        next unless /\@\s+ARGV/;
        my ( $module_path, $object_path ) = /$re/;

        # Get overlap between end of module path and beginning of object path
        $module_path =~ s|[\\\/]|::|g;
        my @object_path_steps = split /::/, $object_path;
        for my $step ( 0 .. $#object_path_steps ) {
            my $module_name = join "::", @object_path_steps[ 0 .. $step ];
            if ( $module_path =~ /$module_name$/ ) {
                $argv_modules{$module_name} = 1;
                last;
            }
        }
    }

    waitpid $pid, 0;
    File::Temp::unlink0( $temp_fh, $temp_filename )
        or warn "Error unlinking file $temp_filename safely";

    my @warn_modules = sort keys %argv_modules;

    if (@warn_modules) {
        my $conflict_warning = <<EOF;

POTENTIAL CONFLICT WARNING:
A module that accesses '\@ARGV' has been loaded before @{[__PACKAGE__]}.
To avoid potential conflicts, we recommended changing your script such
that @{[__PACKAGE__]} is imported before the following module(s):

EOF
        $conflict_warning .= "    $_\n" for sort @warn_modules;
        print STDERR "$conflict_warning\n";
    }
}

BEGIN {
    _check_for_known_conflicting_modules( '', '' );    # Add when discovered
    _check_for_potentially_conflicting_modules();
}

sub import {
    my ( $pkg, $custom_repro_opts ) = @_;
    _reproducibility_is_important($custom_repro_opts);
}

sub _reproducibility_is_important {
    my $custom_repro_opts = shift;

    my $repro_opts     = _parse_custom_repro_opts($custom_repro_opts);
    my $dir            = $$repro_opts{dir};
    my $full_prog_name = $0;
    my $argv_current   = \@ARGV;
    _set_dir( \$dir, $$repro_opts{reprodir}, $argv_current );
    make_path $dir;

    my $current = {};
    my ( $prog, $prog_dir )
        = _parse_command( $current, $full_prog_name, $$repro_opts{repronote},
        $argv_current );
    my ( $repro_file, $start ) = _set_repro_file( $current, $dir, $prog );
    _get_current_state( $current, $prog_dir );

    my $reproduce_opt = $$repro_opts{reproduce};
    my $warnings = [];
    if ( $$current{'COMMAND'} =~ /\s-?-$reproduce_opt\s+(\S+)/ ) {
        my $old_repro_file = $1;
        $$current{'COMMAND'}
            = _reproduce_cmd( $current, $prog, $old_repro_file, $repro_file,
            $dir, $argv_current, $warnings, $start );
    }
    _archive_cmd( $current, $repro_file );
    _exit_code( $repro_file, $start );
}

sub _parse_custom_repro_opts {
    my $custom_repro_opts = shift;

    my %default_opts = (
        dir       => undef,
        reprodir  => 'reprodir',
        reproduce => 'reproduce',
        repronote => 'repronote'
    );

    if ( !defined $custom_repro_opts ) {
        return \%default_opts;
    }
    elsif ( ref($custom_repro_opts) eq 'HASH' ) {
        for my $opt ( keys %default_opts ) {
            $$custom_repro_opts{$opt} = $default_opts{$opt}
                unless exists $$custom_repro_opts{$opt};
        }
        return $custom_repro_opts;
    }
    else {
        $default_opts{dir} = $custom_repro_opts;
        return \%default_opts;
    }
}

sub _set_dir {
    my ( $dir, $reprodir_opt, $argv_current ) = @_;
    my $cli_dir = _get_repro_arg( $reprodir_opt, $argv_current );

    if ( defined $cli_dir ) {
        $$dir = $cli_dir;
    }
    elsif ( !defined $$dir ) {
        if ( defined $ENV{REPRO_DIR} ) {
            $$dir = $ENV{REPRO_DIR};
        }
        else {
            my $cwd = getcwd;
            $$dir = "$cwd/repro-archive";
        }
    }
}

sub _parse_command {
    my ( $current, $full_prog_name, $repronote_opt, $argv_current ) = @_;
    $$current{'NOTE'} = _get_repro_arg( $repronote_opt, $argv_current );
    for (@$argv_current) {
        $_ = "'$_'" if /\s/;
    }
    my ( $prog, $prog_dir ) = fileparse $full_prog_name;
    $$current{'COMMAND'} = join " ", $prog, @$argv_current;
    return $prog, $prog_dir;
}

sub _get_repro_arg {
    my ( $repro_opt, $argv_current ) = @_;
    my $repro_arg;
    my $argv_idx = first_index { $_ =~ /^-?-$repro_opt$/ } @$argv_current;
    if ( $argv_idx > -1 ) {
        $repro_arg = $$argv_current[ $argv_idx + 1 ];
        splice @$argv_current, $argv_idx, 2;
    }
    return $repro_arg;
}

sub _set_repro_file {
    my ( $current, $dir, $prog ) = @_;
    my $start = _now();
    $$current{'STARTED'} = $$start{'when'};
    my $repro_file = "$dir/rlog-$prog-" . $$start{'timestamp'};
    _is_file_unique( \$repro_file );
    return $repro_file, $start;
}

sub _now {
    my %now;
    my @localtime = localtime;
    $now{'timestamp'} = strftime "%Y%m%d.%H%M%S",               @localtime;
    $now{'when'}      = strftime "at %H:%M:%S on %a %b %d, %Y", @localtime;
    $now{'seconds'}   = time();
    return \%now;
}

sub _is_file_unique {
    my $file = shift;
    return if !-e $$file;

    my ( $base, $counter ) = $$file =~ /(.+\d{8}\.\d{6})(?:\.(\d{3}$))?/;
    if ( defined $counter ) {
        $counter++;
    }
    else {
        $counter = "001";
    }
    $$file = "$base.$counter";
    _is_file_unique($file);
}

sub _reproduce_cmd {
    my ( $current, $prog, $old_repro_file, $repro_file, $dir, $argv_current,
        $warnings, $start )
        = @_;

    my ( $raw_archived_state, $has_been_reproduced )
        = LoadFile($old_repro_file);

    # Convert array of single-key hashes to single multi-key hash
    my %archived_state;
    for (@$raw_archived_state) {
        my (@keys) = keys %$_;
        die "Something is wrong..." if scalar @keys != 1;
        $archived_state{ $keys[0] } = $$_{ $keys[0] };
    }

    my $cmd = $archived_state{'COMMAND'};

    my ( $archived_prog, @archived_argv )
        = $cmd =~ /((?:\'[^']+\')|(?:\"[^"]+\")|(?:\S+))/g;
    @$argv_current = @archived_argv;
    print STDERR "Reproducing archive: $old_repro_file\n";
    print STDERR "Reproducing command: $cmd\n";
    _validate_prog_name( $archived_prog, $prog, @archived_argv );
    _validate_archived_info( \%archived_state, $current, $warnings );
    my $diff_file
        = _summarize_warnings( $warnings, $old_repro_file, $repro_file, $dir,
        $prog, $start );
    _add_warnings_to_current_state( $current, $warnings, $old_repro_file,
        $diff_file );
    _log_reproduction_event( $old_repro_file, $repro_file, $current,
        $has_been_reproduced );
    return $cmd;
}

sub _log_reproduction_event {
    my ( $old_repro_file, $new_repro_file, $current, $has_been_reproduced )
        = @_;

    open my $old_repro_fh, ">>", $old_repro_file
        or die "Cannot open $old_repro_file for appending: $!";

    print $old_repro_fh "---\n- REPRODUCED AS:\n"
        unless defined $has_been_reproduced;
    print $old_repro_fh "    - $new_repro_file $$current{'STARTED'}\n";

    close $old_repro_fh;
}

sub _archive_cmd {
    my ( $current, $repro_file ) = @_;

    open my $repro_fh, ">", $repro_file
        or die "Cannot open $repro_file for writing: $!";
    _dump_yaml_to_archive( $current, $repro_fh );
    close $repro_fh;
    print STDERR "Created new archive: $repro_file\n";
}

sub _get_current_state {
    my ( $current, $prog_dir ) = @_;
    _archive_version($current);
    _git_info( $current, $prog_dir );
    _perl_info($current);
    _dir_info( $current, $prog_dir );
    _env_info($current);
}

sub _archive_version {
    my $current = shift;
    $$current{'ARCHIVE VERSION'} = "@{[__PACKAGE__]} $VERSION";
}

sub _git_info {
    my ( $current, $prog_dir ) = @_;

    my $devnull = File::Spec->devnull();
    return if `git --version 2> $devnull` eq '';

    my $original_dir = getcwd;
    chdir $prog_dir;

    my $gitbranch = `git rev-parse --abbrev-ref HEAD 2>&1`;
    return if $gitbranch =~ /fatal: Not a git repository/;
    chomp $gitbranch;

    my $gitlog = `git log -n1 --oneline`;
    chomp $gitlog;

    my @status = `git status --short`;
    chomp @status;

    my $diffstaged = `git diff --cached`;
    my $diff       = `git diff`;

    $$current{'GIT'} = [
        { 'BRANCH'        => $gitbranch },
        { 'COMMIT'        => $gitlog },
        { 'STATUS'        => \@status },
        { 'DIFF (STAGED)' => $diffstaged },
        { 'DIFF'          => $diff }
    ];
    chdir $original_dir;
}

sub _perl_info {
    my $current = shift;
    my $path    = $Config{perlpath};
    my $version = sprintf "v%vd", $^V;
    my $modules = _loaded_perl_module_versions();
    $$current{'PERL'} = [
        { 'VERSION' => $version },
        { 'PATH'    => $path },
        { 'INC'     => [@INC] },
        { 'MODULES' => [@$modules] }
    ];
}

sub _loaded_perl_module_versions {
    my $code_to_test = do { open my $fh, '<', $0 or return; local $/; <$fh> };
    my ($package) = @{ [__PACKAGE__] };
    $code_to_test =~ s/use\s+$package[^;]*;//g;
    my ( $temp_fh, $temp_filename ) = File::Temp::tempfile();
    print $temp_fh $code_to_test;

    local ( *CIN, *COUT, *CERR );
    my $perl = $Config{perlpath};
    my $cmd  = "$perl -MO=Xref $temp_filename";
    my $pid  = open3( \*CIN, \*COUT, \*CERR, $cmd );
    my %loaded_modules;
    for (<COUT>) {
        next unless my ($mod) = $_ =~ /^\s*Package\s*([^\s]+)\s*$/;
        next if $mod =~ /[()]/;
        next unless $mod =~ /\w/;
        $loaded_modules{$mod} = 1;
    }
    waitpid $pid, 0;
    File::Temp::unlink0( $temp_fh, $temp_filename )
        or warn "Error unlinking file $temp_filename safely";

    my @module_versions;
    my $NOWARN = 0;
    $SIG{'__WARN__'} = sub { warn $_[0] unless $NOWARN };
    for my $mod ( sort keys %loaded_modules ) {
        $NOWARN = 1;
        eval "require $mod";
        next if $@;
        eval "$mod->VERSION";
        my $version = $@ ? "?" : $mod->VERSION;
        $NOWARN = 0;
        next unless defined $version;
        push @module_versions, "$mod $version";
    }
    $NOWARN = 0;
    return \@module_versions;
}

sub _dir_info {
    my ( $current, $prog_dir ) = @_;

    my $cwd     = getcwd;
    my $abs_dir = Cwd::realpath($prog_dir);

    $$current{'WORKING DIR'} = $cwd;
    $$current{'SCRIPT DIR'}
        = $abs_dir eq $prog_dir
        ? $abs_dir
        : { 'ABSOLUTE' => $abs_dir, 'RELATIVE' => $prog_dir };
}

sub _env_info {
    my $current = shift;
    $$current{'ENV'} = \%ENV;
}

sub _dump_yaml_to_archive {
    my ( $current, $repro_fh ) = @_;

    local $YAML::UseBlock = 1;    # Force short multi-line notes to span lines

    my @to_yaml = (
        { 'COMMAND' => $$current{'COMMAND'} },
        { 'NOTE'    => $$current{'NOTE'} },
    );
    if ( exists $$current{'REPRODUCTION'} ) {
        push @to_yaml, { 'REPRODUCTION' => $$current{'REPRODUCTION'} };
    }
    push @to_yaml, { 'STARTED'         => $$current{'STARTED'} },
                   { 'WORKING DIR'     => $$current{'WORKING DIR'} },
                   { 'SCRIPT DIR'      => $$current{'SCRIPT DIR'} },
                   { 'ARCHIVE VERSION' => $$current{'ARCHIVE VERSION'} },
                   { 'PERL'            => $$current{'PERL'} };
    if ( exists $$current{'GIT'} ) {
        push @to_yaml, { 'GIT' => $$current{'GIT'} };
    }
    push @to_yaml, { 'ENV' => $$current{'ENV'} };

    print $repro_fh Dump [@to_yaml];
}

sub _add_warnings_to_current_state {
    my ( $current, $warnings, $old_repro_file, $diff_file ) = @_;

    $diff_file
        = "Text::Diff needs to be installed to create summary of archive vs. current differences"
        unless defined $diff_file;
    my @warning_messages = map { $$_{message} } @$warnings;
    if ( scalar @warning_messages > 0 ) {
        $$current{'REPRODUCTION'} = [
            { 'REPRODUCED ARCHIVE' => $old_repro_file },
            { 'WARNINGS'           => [@warning_messages] },
            { 'DIFF FILE'          => $diff_file }
        ];
    }
    else {
        $$current{'REPRODUCTION'} = [
            { 'REPRODUCED ARCHIVE' => $old_repro_file },
            { 'WARNINGS'           => 'NONE' },
        ];
    }
}

sub _dump_yaml_to_archive_manually {
    my ( $title, $comment, $repro_fh ) = @_;
    print $repro_fh "- $title: $comment\n";
}

sub _add_exit_code_preamble {
    my $repro_fh = shift;
    print $repro_fh _divider_message();
    print $repro_fh _divider_message(
        "IF EXIT CODE IS MISSING, SCRIPT WAS CANCELLED OR IS STILL RUNNING!");
    print $repro_fh _divider_message(
        "TYPICALLY: 0 == SUCCESS AND 255 == FAILURE");
    print $repro_fh _divider_message();
    print $repro_fh "- EXITCODE: ";    # line left incomplete until exit
}

sub _divider_message {
    my $message = shift;
    my $width   = 80;
    if ( defined $message ) {
        my $msg_len = length($message) + 2;
        my $pad     = ( $width - $msg_len ) / 2;
        $message
            = $pad > 1
            ? join " ", "#" x ceil($pad), $message, "#" x floor($pad)
            : "# $message #";
    }
    else {
        $message = "#" x $width;
    }
    return "$message\n";
}

sub _validate_prog_name {
    my ( $archived_prog, $prog, @args ) = @_;
    local $SIG{__DIE__} = sub { warn @_; exit 1 };
    die <<EOF if $archived_prog ne $prog;
Current ($prog) and archived ($archived_prog) program names don't match!
If this was expected (e.g., filename was changed), please re-run as:

    perl $prog @args

EOF
}

sub _validate_archived_info {
    my ( $archived_state, $current, $warnings ) = @_;

    _compare_archive_current_string( $archived_state, $current,
        'ARCHIVE VERSION', $warnings );
    for my $group (qw(PERL GIT)) {
        _compare_archive_current_array( $archived_state, $current, $group,
            $warnings );
    }
    _compare_archive_current_hash( $archived_state, $current, 'ENV',
        $warnings );
}

sub _compare_archive_current_string {
    my ( $archive, $current, $key, $warnings ) = @_;

    my $arc_string = $$archive{$key};
    my $cur_string = $$current{$key};
    if ( $arc_string ne $cur_string ) {
        _raise_warning( $warnings, $key, \$arc_string, \$cur_string );
    }
}

sub _compare_archive_current_hash {
    my ( $archive, $current, $key, $warnings ) = @_;

    my @arc_array
        = map {"$_: $$archive{$key}{$_}"} sort keys %{ $$archive{$key} };
    my @cur_array
        = map {"$_: $$current{$key}{$_}"} sort keys %{ $$current{$key} };
    if ( join( "", @arc_array ) ne join( "", @cur_array ) ) {
        _raise_warning( $warnings, $key, \@arc_array, \@cur_array );
    }
}

sub _compare_archive_current_array {
    my ( $archive, $current, $group, $warnings ) = @_;

    for ( 0 .. $#{ $$archive{$group} } ) {
        my %archive_subgroup;
        my %current_subgroup;
        my ( $arc_key, $too_many_ak ) = keys %{ $$archive{$group}->[$_] };
        my ( $cur_key, $too_many_ck ) = keys %{ $$current{$group}->[$_] };

        die "Something is wrong..."
            if $arc_key ne $cur_key
            || defined $too_many_ak
            || defined $too_many_ck;

        $archive_subgroup{$arc_key} = $$archive{$group}->[$_]{$arc_key};
        $current_subgroup{$cur_key} = $$current{$group}->[$_]{$cur_key};

        if (   !ref( $archive_subgroup{$arc_key} )
            && !ref( $current_subgroup{$cur_key} ) )
        {
            if ( $archive_subgroup{$arc_key} ne $current_subgroup{$cur_key} )
            {
                _raise_warning(
                    $warnings,
                    "$group $cur_key",
                    \$archive_subgroup{$arc_key},
                    \$current_subgroup{$cur_key}
                );
            }
        }
        elsif (ref( $archive_subgroup{$arc_key} ) eq "ARRAY"
            && ref( $current_subgroup{$cur_key} ) eq "ARRAY" )
        {
            if (join( "", @{ $archive_subgroup{$arc_key} } ) ne
                join( "", @{ $current_subgroup{$cur_key} } ) )
            {
                _raise_warning(
                    $warnings,
                    "$group $cur_key",
                    $archive_subgroup{$arc_key},
                    $current_subgroup{$cur_key}
                );
            }
        }
        else {
            die "Something is wrong...";
        }
    }
}

sub _raise_warning {
    my ( $warnings, $item, $archive, $current ) = @_;

    push @$warnings,
        {
        message => "Archived and current $item do NOT match",
        archive => $archive,
        current => $current
        };
}

sub _summarize_warnings {
    my ( $warnings, $old_repro_file, $repro_file, $dir, $prog, $start ) = @_;
    my $diff_file;
    if (@$warnings) {
        print STDERR "\n";
        for my $alert (@$warnings) {
            print STDERR "WARNING: $$alert{message}\n";
        }
        print STDERR <<EOF;

There are inconsistencies between the archived and current conditions.
These differences might affect reproducibility. A summary can be found at:
EOF
        $diff_file
            = _repro_diff( $warnings, $old_repro_file, $repro_file, $dir,
            $prog, $start );
        _do_or_die();
    }
    return $diff_file;
}

sub _repro_diff {
    my ( $warnings, $old_repro_file, $repro_file, $dir, $prog, $start ) = @_;

    eval "use Text::Diff";
    if ($@) {
        print STDERR
            "  Uh oh, you need to install Text::Diff to see the summary! (http://www.cpan.org/modules/INSTALL.html)\n";
        return;
    }
    require Text::Diff;

    my ($old_timestamp) = $old_repro_file =~ /-(\d{8}\.\d{6}(?:\.\d{3})?)$/;
    my $new_timestamp = $$start{'timestamp'};

    my $diff_file = "$dir/rdiff-$prog-$old_timestamp.vs.$new_timestamp";
    _is_file_unique( \$diff_file );
    open my $diff_fh, ">", $diff_file;
    print $diff_fh <<HEAD;
The following inconsistencies between archived and current conditions were found when
reproducing a run from an archive. These have the potential to affect reproducibility.
------------------------------------------------------------------------------------------
Archive: $old_repro_file
Current: $repro_file
------------------------------------------------------------------------------------------
Note: This file is often best viewed with word wrapping disabled
------------------------------------------------------------------------------------------

HEAD
    for my $alert (@$warnings) {
        my $diff = diff( $$alert{archive}, $$alert{current},
            { STYLE => "Table" } );
        print $diff_fh $$alert{message}, "\n";
        print $diff_fh $diff, "\n";
    }
    close $diff_fh;
    print STDERR "  $diff_file\n";
    return $diff_file;
}

sub _do_or_die {
    print STDERR "Do you want to continue? (y/n) ";
    my $response = <STDIN>;
    if ( $response =~ /^Y(?:ES)?$/i ) {
        return;
    }
    elsif ( $response =~ /^N(?:O)?$/i ) {
        print STDERR "Better luck next time...\n";
        exit;
    }
    else {
        _do_or_die();
    }
}

sub _exit_code {
    our ( $repro_file, $start ) = @_;

    open my $repro_fh, ">>", $repro_file
        or die "Cannot open $repro_file for appending: $!";
    _add_exit_code_preamble($repro_fh);
    close $repro_fh;

    END {
        return unless defined $repro_file;
        my $finish = _now();
        my $elapsed = _elapsed( $$start{'seconds'}, $$finish{'seconds'} );
        open my $repro_fh, ">>", $repro_file
            or die "Cannot open $repro_file for appending: $!";
        print $repro_fh "$?\n";    # This completes EXITCODE line
        _dump_yaml_to_archive_manually( "FINISHED", $$finish{'when'},
            $repro_fh );
        _dump_yaml_to_archive_manually( "ELAPSED", $elapsed, $repro_fh );
        close $repro_fh;
    }
}

sub _elapsed {
    my ( $start_seconds, $finish_seconds ) = @_;

    my $secs = difftime $finish_seconds, $start_seconds;
    my $mins = int $secs / 60;
    $secs = $secs % 60;
    my $hours = int $mins / 60;
    $mins = $mins % 60;

    return join ":", map { sprintf "%02d", $_ } $hours, $mins, $secs;
}

1;
