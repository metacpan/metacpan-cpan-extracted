package Langertha::Holmgang::Sim::Linux::Logrotate;
# ABSTRACT: logrotate 3.21 (Debian 12) for the Linux simulator — reads the configuration, checks (-d), rotates (-f)

use strict;
use warnings;
use utf8;

our $VERSION = '0.002';


my $L = 'Langertha::Holmgang::Sim::Linux';
sub _l { my $n = shift; no strict 'refs'; return &{"${L}::$n"}(@_) }

my %FLAG = map { $_ => 1 } qw( compress nocompress delaycompress nodelaycompress copytruncate nocopytruncate copy nocopy
    missingok nomissingok notifempty ifempty sharedscripts nosharedscripts dateext nodateext nocreate nomail maillast mailfirst
    shred noshred renamecopy createolddir nocreateolddir noolddir dateyesterday datehourago nosharedscripts );
my %ARG = map { $_ => 1 } qw( rotate size maxsize minsize maxage olddir su compresscmd uncompresscmd compressext compressoptions
    dateformat extension start tabooext mail shredcycles addextension );
my %PERIOD = map { $_ => 1 } qw( hourly daily weekly monthly yearly );
my %SCRIPT = map { $_ => 1 } qw( postrotate prerotate firstaction lastaction preremove );
my @TABOO = qw( .rpmsave .rpmorig ~ .disabled .dpkg-old .dpkg-dist .dpkg-new .cfsaved .ucf-old .ucf-dist .ucf-new .rpmnew .swp .cfsaved .rhn-cfg-tmp-* );


sub run {
    my ( $dev, $av, $ctx ) = @_;
    my ( $debug, $force, $verbose, @conf );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-d' || $x eq '--debug' )   { $debug = 1 }
        elsif ( $x eq '-f' || $x eq '--force' )   { $force = 1 }
        elsif ( $x eq '-v' || $x eq '--verbose' ) { $verbose = 1 }
        elsif ( $x =~ /\A-[dfv]{2,}\z/ ) { $debug = 1 if $x =~ /d/; $force = 1 if $x =~ /f/; $verbose = 1 if $x =~ /v/ }
        elsif ( $x eq '-s' || $x eq '--state' || $x eq '-l' || $x eq '--log' || $x eq '-m' || $x eq '--mail' ) { shift @a }
        elsif ( $x =~ /\A--(?:state|log|mail)=/ ) { }
        elsif ( $x eq '--version' || $x eq '-V' ) { return ( _version(), 1 ) }
        elsif ( $x eq '--help' || $x eq '-?' || $x eq '--usage' ) { return ( _usage(), 1 ) }
        elsif ( $x =~ /\A-/ ) { return ( "logrotate: bad argument $x: unknown option\n" . _usage(), 1 ) }
        else { push @conf, $x }
    }
    return ( "logrotate 3.21.0 - Copyright (C) 1995-2001 Red Hat, Inc.\nThis may be freely redistributed under the terms of the GNU General Public License\n\n"
        . _usage(), 0 ) unless @conf;
    my ( @out, @logs, %seen );
    my $err = 0;
    push @out, 'warning: logrotate in debug mode does nothing except printing debug messages!  Consider using verbose mode (-v) instead if this is not what you want.', ''
        if $debug;
    for my $c (@conf) {
        $err += _read_config( $dev, $c, {}, \@logs, \@out, \%seen, 0 );
    }
    push @out, 'Reading state from file: /var/lib/logrotate/status', 'Allocating hash table for state file, size 64 entries';
    push @out, '', 'Handling ' . scalar(@logs) . ' logs';
    for my $b (@logs) {
        $err += _rotate_block( $dev, $b, $ctx, \@out, debug => $debug, force => $force );
    }
    my $show = $debug || $verbose;
    my @shown = $show ? @out : grep {/\Aerror:/} @out;
    return ( join( "\n", @shown ), $err ? 0 : 1 );
}

sub _version {
    return join "\n", 'logrotate 3.21.0', '', '    Default mail command:       /usr/bin/mail', '    Default compress command:   /bin/gzip',
        '    Default uncompress command: /bin/gunzip', '    Default compress extension: .gz', '    Default state file path:    /var/lib/logrotate/status',
        '    ACL support:                yes', '    SELinux support:            yes';
}

sub _usage {
    return join "\n", 'Usage: logrotate [-dfv?] [-d|--debug] [-f|--force] [-m|--mail=command] [-s|--state=statefile]',
        '        [--skip-state-lock] [-v|--verbose] [-l|--log=logfile] [--version] [-?|--help] [--usage]',
        '        [OPTION...] <configfile>';
}

# Liest eine Konfigurationsdatei (oder ein Verzeichnis); haengt Bloecke an @$logs.
# Rueckgabe: Zahl der Fehler.
sub _read_config {
    my ( $dev, $path, $g, $logs, $out, $seen, $depth ) = @_;
    my $err = 0;
    if ( _l( '_is_dir', $dev, $path ) && !_l( '_file_entry', $dev, $path ) ) {
        push @$out, "including $path" if $depth;
        my $names = _l( '_ls_names', $dev, $path );
        for my $n ( sort keys %$names ) {
            my ($t) = grep { my $x = $_; $x =~ s/\*\z//; $x =~ /\A\./ ? substr( $n, -length $x ) eq $x : $n eq $x } @TABOO;
            if ( $t || $n =~ /\.rhn-cfg-tmp-/ ) { push @$out, "Ignoring $n, because of " . ( $t // '.rhn-cfg-tmp-*' ) . ' ending'; next }
            next if _l( '_is_dir', $dev, "$path/$n" ) && !_l( '_file_entry', $dev, "$path/$n" );
            $err += _read_file( $dev, "$path/$n", $n, $g, $logs, $out, $seen, $depth );
        }
        return $err;
    }
    return _read_file( $dev, $path, $path, $g, $logs, $out, $seen, $depth );
}

sub _read_file {
    my ( $dev, $path, $shown, $g, $logs, $out, $seen, $depth ) = @_;
    my $e = _l( '_file_entry', $dev, $path );
    my $text = _l( '_file_text', $dev, $path );
    if ( !defined $text ) { push @$out, "error: cannot stat $path: No such file or directory"; return 1 }
    push @$out, "reading config file $shown";
    my $mode = oct( $e->{mode} // '0644' );
    if ( $mode & 022 ) { push @$out, "error: Ignoring $shown because of bad file mode - must be 0644 or 0444."; return 1 }
    if ( ( $e->{owner} // 'root' ) ne 'root' ) { push @$out, "error: Ignoring $shown because the file owner is wrong (should be root or user with uid 0)."; return 1 }
    my $err = 0;
    my ( $block, $script, $pending );
    my $n = 0;
    for my $raw ( split /\n/, $text ) {
        $n++;
        if ($script) {
            if ( $raw =~ /\A\s*endscript\s*\z/ ) { $script = undef; next }
            push @{ $block->{scripts}{$script} }, $raw;
            next;
        }
        ( my $l = $raw ) =~ s/\A\s+|\s+\z//g;
        next if $l eq '' || $l =~ /\A#/;
        my $cur = $block ? $block->{opt} : $g;
        if ($pending) {
            if ( $l eq '{' ) { $l = "$pending {"; $pending = undef }
            else { push @$out, "error: $shown:" . ( $n - 1 ) . " missing '{' after log files definition"; $err++; $pending = undef }
        }
        if ( !$block && ( $l =~ m{\A["/]} || $l =~ /\{\s*\z/ && $l !~ /\A\w+\s*\{/ ) ) {
            if ( $l !~ /\{\s*\z/ ) { $pending = $l; next }
            ( my $pats = $l ) =~ s/\s*\{\s*\z//;
            my @p = map { s/\A"|"\z//gr } split /\s+/, $pats;
            $block = { patterns => \@p, opt => { %$g }, scripts => {}, file => $shown, line => $n };
            # wie logrotate: dieselbe Datei (nach dem Aufloesen der Muster) nur in einem Block
            my %skip;
            for my $f ( map { _expand( $dev, $_ ) } @p ) {
                if ( $seen->{$f} ) { push @$out, "error: $shown:$n duplicate log entry for $f"; $err++; $skip{$f} = 1 }
                $seen->{$f} = 1;
            }
            $block->{skip} = \%skip;
            next;
        }
        if ( $l eq '}' ) {
            if ( !$block ) { push @$out, "error: $shown:$n unexpected }"; $err++; next }
            push @$logs, $block;
            $block = undef;
            next;
        }
        my ( $kw, $rest ) = $l =~ /\A(\S+)\s*(.*)\z/;
        if ( $SCRIPT{$kw} ) {
            if ( !$block ) { push @$out, "error: $shown:$n $kw outside of log file definition"; $err++; next }
            $script = $kw;
            $block->{scripts}{$kw} = [];
            next;
        }
        if ( $kw eq 'include' ) {
            if ($block) { push @$out, "error: $shown:$n include not allowed inside a log file definition"; $err++; next }
            $err += _read_config( $dev, $rest, $g, $logs, $out, $seen, $depth + 1 );
            next;
        }
        if ( $PERIOD{$kw} ) { $cur->{period} = $kw; next }
        if ( $kw eq 'create' ) {
            my @c = split /\s+/, $rest;
            if ( @c && $c[0] !~ /\A0?[0-7]{3,4}\z/ ) { push @$out, "error: $shown:$n unknown unix user $c[0]"; $err++; next }
            $cur->{create} = [@c];
            delete $cur->{nocreate};
            next;
        }
        if ( $kw eq 'rotate' ) {
            if ( $rest !~ /\A-?\d+\z/ ) { push @$out, "error: $shown:$n bad rotation count '$rest'"; $err++; next }
            $cur->{rotate} = $rest;
            next;
        }
        if ( $FLAG{$kw} ) {
            ( my $base = $kw ) =~ s/\Ano(?!tifempty)//;
            $base = 'notifempty' if $kw eq 'ifempty';
            if ( $kw eq 'ifempty' ) { delete $cur->{notifempty} }
            elsif ( $kw =~ /\Ano/ && $kw ne 'notifempty' ) { delete $cur->{$base}; delete $cur->{create} if $kw eq 'nocreate' }
            else { $cur->{$kw} = 1 }
            next;
        }
        if ( $ARG{$kw} ) { $cur->{$kw} = $rest; next }
        push @$out, "error: $shown:$n unknown option '$kw' -- ignoring line";
        $err++;
    }
    if ($pending) { push @$out, "error: $shown:$n missing '{' after log files definition"; $err++ }
    if ($script) { push @$out, "error: $shown:$n missing endscript"; $err++ }
    if ($block)  { push @$out, "error: $shown:$n missing '}' at end of file"; $err++ }
    return $err;
}

# Dateien eines Musters im Zustand (Shell-Muster * und ? im letzten Teil)
sub _expand {
    my ( $dev, $pat ) = @_;
    return ($pat) unless $pat =~ /[*?]/;
    ( my $re = quotemeta $pat ) =~ s/\\\*/[^\/]*/g;
    $re =~ s/\\\?/[^\/]/g;
    return sort grep {/\A$re\z/} keys %{ $dev->{files} || {} };
}

sub _rotate_block {
    my ( $dev, $b, $ctx, $out, %o ) = @_;
    my $opt = $b->{opt};
    my $rot = $opt->{rotate} // 1;
    my $err = 0;
    my $crit = $o{force} ? 'forced from command line' : ( $opt->{period} // 'weekly' ) eq 'daily' ? 'after 1 days'
        : ( $opt->{period} // 'weekly' ) eq 'hourly' ? 'hourly' : $opt->{period} // 'weekly';
    push @$out, '', 'rotating pattern: ' . join( ' ', @{ $b->{patterns} } ) . "  $crit ($rot rotations)";
    push @$out, 'empty log files ' . ( $opt->{notifempty} ? 'are not' : 'are' ) . ' rotated, old logs are removed';
    my @files = grep { !$b->{skip}{$_} } map { _expand( $dev, $_ ) } @{ $b->{patterns} };
    my @done;
    for my $f (@files) {
        push @$out, "considering log $f";
        my $e = _l( '_file_entry', $dev, $f );
        if ( !$e ) {
            if   ( $opt->{missingok} ) { push @$out, "  log $f does not exist -- skipping" }
            else                       { push @$out, "error: stat of $f failed: No such file or directory"; $err++ }
            next;
        }
        ( my $dir = $f ) =~ s{/[^/]+\z}{};
        my $d = ( $dev->{dirs} || {} )->{$dir} || {};
        my $dm = oct( $d->{mode} // '0755' );
        if ( !$opt->{su} && ( $dm & 002 || ( $dm & 020 && ( $d->{group} // 'root' ) ne 'root' ) ) ) {
            push @$out, "error: skipping \"$f\" because parent directory has insecure permissions (It's world writable or writable by group which is not \"root\") Set \"su\" directive in the config file to tell logrotate which user/group should be used for rotation.";
            $err++;
            next;
        }
        push @$out, '  Now: 2026-10-20 14:00', '  Last rotated at 2026-10-20 00:00';
        if ( !$o{force} ) { push @$out, '  log does not need rotating (log has been rotated at 2026-10-20 00:00, which is less than a day ago)'; next }
        if ( $opt->{notifempty} && _l( '_file_size', $e ) == 0 ) { push @$out, '  log does not need rotating (log is empty)'; next }
        push @$out, '  log needs rotating';
        push @done, $f;
    }
    return $err unless @done;
    my $shared = $opt->{sharedscripts};
    my $run = sub {
        my ( $which, $arg ) = @_;
        my $lines = $b->{scripts}{$which} or return;
        push @$out, "running $which script";
        return if $o{debug};
        for my $line (@$lines) {
            ( my $x = $line ) =~ s/\A\s+//;
            next if $x eq '' || $x =~ /\A#/;
            $x =~ s/\$1\b/$arg/g if defined $arg;
            my ( $so, $ok ) = $L->_run_inner( $dev, $x, $ctx );
            push @$out, $so if defined $so && length $so;
            if ( !$ok ) { push @$out, "error: error running shared $which script for '" . join( ' ', @{ $b->{patterns} } ) . "'"; $err++; last }
        }
    };
    $run->( 'prerotate', join ' ', @{ $b->{patterns} } ) if $shared;
    for my $f (@done) {
        $run->( 'prerotate', $f ) unless $shared;
        _rotate_one( $dev, $f, $opt, $out, $o{debug} );
        $run->( 'postrotate', $f ) unless $shared;
    }
    $run->( 'postrotate', join ' ', @{ $b->{patterns} } ) if $shared;
    return $err;
}

sub _gz { my ($e) = @_; my %n = %$e; $n{size} = _l( '_human', int( _l( '_file_size', $e ) / 10 ) + 1 ); $n{content} = ''; delete $n{open_by}; return \%n }

sub _rotate_one {
    my ( $dev, $f, $opt, $out, $debug ) = @_;
    my $rot = $opt->{rotate} // 1;
    my $files = $dev->{files};
    my $comp = $opt->{compress};
    my $delay = $comp && $opt->{delaycompress};
    push @$out, "rotating log $f, log->rotateCount is $rot", "dateext suffix '-20261020'", "glob pattern '-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'";
    push @$out, 'compressing log with: /bin/gzip' if $comp;
    # aeltere Generationen weiterschieben, die letzte faellt weg
    for ( my $i = $rot; $i >= 1; $i-- ) {
        for my $ext ( '.gz', '' ) {
            my $src = "$f.$i$ext";
            next unless exists $files->{$src};
            if ( $i == $rot ) { push @$out, "removing old log $src"; delete $files->{$src} unless $debug; next }
            my $dst = "$f." . ( $i + 1 ) . ( $ext eq '' && $comp && $i == 1 && $delay ? '.gz' : $ext );
            push @$out, "renaming $src to $dst (rotatecount $rot, logstart 1, i $i),";
            next if $debug;
            my $e = delete $files->{$src};
            $files->{$dst} = $dst =~ /\.gz\z/ && $src !~ /\.gz\z/ ? _gz( ref $e ? $e : { content => $e } ) : $e;
        }
    }
    my $one = "$f.1" . ( $comp && !$delay ? '.gz' : '' );
    my $e = _l( '_file_entry', $dev, $f );
    if ( $opt->{copytruncate} || $opt->{copy} ) {
        push @$out, "copying $f to $f.1";
        push @$out, "truncating $f" if $opt->{copytruncate};
        return if $debug;
        my %c = %$e;
        delete $c{open_by};
        $files->{$one} = $comp && !$delay ? _gz( \%c ) : \%c;
        if ( $opt->{copytruncate} ) { my %t = %$e; $t{content} = ''; $t{size} = '0'; $files->{$f} = \%t }
        return;
    }
    push @$out, "renaming $f to $f.1";
    my $cr = $opt->{create} && !$opt->{nocreate};
    my ( $m, $u, $g ) = @{ $opt->{create} || [] };
    $m //= $e->{mode} // '0644';
    $u //= $e->{owner} // 'root';
    $g //= $e->{group} // 'root';
    push @$out, sprintf( 'creating new %s mode = %04o uid = %d gid = %d', $f, oct $m, _l( '_uid', $dev, $u ), _l( '_gid', $dev, $g ) ) if $cr;
    return if $debug;
    my %r = %$e;
    $r{opened_as} = $f if defined $r{open_by};    # der Dienst schreibt weiter hierhin, bis er neu oeffnet
    delete $files->{$f};
    $files->{"$f.1"} = \%r;
    if ( $comp && !$delay ) { $files->{$one} = _gz( \%r ); delete $files->{"$f.1"} }
    $files->{$f} = { content => '', size => '0', mode => sprintf( '%04o', oct $m ), owner => $u, group => $g, mtime => 'Oct 20 14:00' } if $cr;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Logrotate - logrotate 3.21 (Debian 12) for the Linux simulator — reads the configuration, checks (-d), rotates (-f)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Logrotate::run( $dev, [ '-d', '/etc/logrotate.d/app' ], $ctx );

=head1 DESCRIPTION

Models C<logrotate> of a Debian 12 (3.21.0) on the state of a device
(L<Langertha::Holmgang::Sim::Linux>):

=over

=item * Configuration: global directives, blocks C<pattern … { … }>, C<include>
(directory: files in name order, endings like C<.dpkg-old> are
skipped), scripts C<postrotate>/C<prerotate>/C<firstaction>/C<lastaction>
up to C<endscript>. Errors like logrotate: unknown directive, missing C<{>,
missing C<}>, C<rotate> without a number, duplicate entry for the same file,
configuration file writable by group/others.

=item * C<-d>: dry run with logrotate's output, changes nothing.
C<-f>: rotates now (C<-v> shows the same output while doing so): shift older
generations and delete those beyond C<rotate>, C<copytruncate> (copy,
original emptied, the service keeps writing to the original file) or
rename (the service keeps writing to the renamed file until it reopens
it) with C<create> (new empty file with permissions), C<compress> and
C<delaycompress>, scripts run in the simulator (C<systemctl reload|restart …>
makes a service reopen its log files). Without C<-f> every file has
already been rotated today (nothing to do).

=item * C<--version>, C<--help>.

=back

Limits: the state file (F</var/lib/logrotate/status>) is not written;
C<size>, C<maxage>, C<olddir>, C<dateext> and C<mail> are read and
shown, but not evaluated.

=head2 run

  my ( $output, $ok ) = run( $device, \@args, $ctx );

C<logrotate [-d] [-f] [-v] [-s file] configuration…>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
