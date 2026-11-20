package Langertha::Holmgang::Sim::Linux::Backup;
# ABSTRACT: Backup and restore on a simulated Linux server — tar, rsync, restic, sha256sum

use strict;
use warnings;
use utf8;

use Digest::SHA ();
use JSON::MaybeXS ();
use POSIX ();
use Time::Local ();

our $VERSION = '0.002';


my $T = JSON::MaybeXS::true();
sub _lx { 'Langertha::Holmgang::Sim::Linux' }
sub _L { my $n = shift; return _lx()->can($n)->(@_) }

sub _cwd { $Langertha::Holmgang::Sim::Linux::CWD_DIR }

sub _abs {
    my ($p) = @_;
    return $p if $p =~ m{\A/};
    my $c = _cwd() // '/root';
    $p =~ s{\A\./}{};
    return $p eq '.' ? $c : ( $c eq '/' ? "/$p" : "$c/$p" );
}

sub _now_text { 'Oct 20 12:00' }

# Kopie eines Eintrags; erhalten (-a/-p, tar/restic als root) oder neu (root, umask 022)

sub copy_entry {
    my ( $e, $keep ) = @_;
    my %n = ref $e eq 'HASH' ? %$e : ( content => $e );
    delete @n{qw( open_by tar )} if !$n{tar};
    delete $n{open_by};
    unless ($keep) {
        $n{owner} = 'root';
        $n{group} = 'root';
        $n{mode}  = sprintf '%04o', oct( $n{mode} // '0644' ) & ~022;
        $n{mtime} = _now_text();
    }
    return \%n;
}

sub _entry { my ( $dev, $p ) = @_; my $e = ( $dev->{files} || {} )->{$p}; return undef unless defined $e; return ref $e eq 'HASH' ? $e : { content => $e } }

sub _put {
    my ( $dev, $path, $e ) = @_;
    my $old = ( $dev->{files} || {} )->{$path};
    if ( ref $old eq 'HASH' && $old->{open_by} ) { $e = { %$e, open_by => $old->{open_by} } }
    $dev->{files}{$path} = $e;
    return;
}

# --- tar ---------------------------------------------------------------------------

sub _tar_glob {
    my ($g) = @_;
    ( my $re = quotemeta $g ) =~ s/\\\*/.*/g;
    $re =~ s/\\\?/./g;
    return qr/\A$re(?:\/.*)?\z/;
}

# --exclude wie GNU tar (nicht verankert): das Muster passt auf den ganzen Namen oder auf
# ein Stueck ab einer Komponente (cache trifft daten/cache und alles darunter)
sub _tar_excluded {
    my ( $rel, @ex ) = @_;
    my @seg = split m{/}, $rel;
    for my $x (@ex) {
        ( my $pat = $x ) =~ s{\A(?:\./|/+)}{};    # wie das Mitglied: ohne ./ und fuehrendes /
        $pat =~ s{/+\z}{};
        my $re = _tar_glob($pat);
        return 1 if grep { join( '/', @seg[ $_ .. $#seg ] ) =~ $re } 0 .. $#seg;
    }
    return 0;
}


sub tar {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my ( $mode, $file, $dir, $strip, $verbose, $keep, $stdout, $remove, @lists, @ex, @mem );
    my $first = 1;
    while (@a) {
        my $x = shift @a;
        if ( $first && $x =~ /\A[a-zA-Z]+\z/ && $x =~ /[cxt]/ ) { $x = "-$x" }
        $first = 0;
        if    ( $x =~ /\A--(create|extract|get|list)\z/ ) { $mode = { create => 'c', extract => 'x', get => 'x', list => 't' }->{$1} }
        elsif ( $x =~ /\A--file=(.+)\z/ )                { $file = $1 }
        elsif ( $x eq '--file' )                          { $file = shift @a }
        elsif ( $x =~ /\A--directory=(.+)\z/ )           { $dir = $1 }
        elsif ( $x eq '--directory' || $x eq '-C' )       { $dir = shift @a }
        elsif ( $x =~ /\A--strip-components=(\d+)\z/ )   { $strip = $1 }
        elsif ( $x =~ /\A--exclude=(.+)\z/ )             { push @ex, $1 }
        elsif ( $x eq '--exclude' )                       { push @ex, shift @a }
        elsif ( $x eq '--keep-old-files' )                { $keep = 1 }
        elsif ( $x eq '--to-stdout' )                     { $stdout = 1 }
        elsif ( $x eq '--verbose' )                       { $verbose = 1 }
        elsif ( $x =~ /\A--files-from=(.+)\z/ )          { push @lists, $1 }
        elsif ( $x eq '--files-from' )                    { push @lists, shift @a }
        elsif ( $x eq '--remove-files' )                  { $remove = 1 }
        elsif ( $x =~ /\A--/ ) { }
        elsif ( $x =~ /\A-([a-zA-Z]+)\z/ ) {
            my @f = split //, $1;
            while ( defined( my $c = shift @f ) ) {
                if    ( $c =~ /[cxt]/ ) { $mode = $c }
                elsif ( $c eq 'v' )     { $verbose = 1 }
                elsif ( $c eq 'k' )     { $keep = 1 }
                elsif ( $c eq 'O' )     { $stdout = 1 }
                elsif ( $c eq 'f' )     { $file = @f ? join( '', splice @f ) : shift @a }
                elsif ( $c eq 'C' )     { $dir = shift @a }
                elsif ( $c eq 'T' )     { push @lists, @f ? join( '', splice @f ) : shift @a }
            }
        }
        else { push @mem, $x }
    }
    return ( "tar: You must specify one of the '-Acdtrux', '--delete' or '--test-label' options\nTry 'tar --help' or 'tar --usage' for more information.", 0 ) unless $mode;
    return ( "tar: Refusing to read archive contents from terminal (missing -f option?)\ntar: Error is not recoverable: exiting now", 0 ) unless defined $file;
    $file = _abs($file);
    for my $l (@lists) {    # -T liste | --files-from=liste (- = Eingabe): ein Mitglied je Zeile
        my $t = $l eq '-' ? $ctx->{stdin} // '' : _L( '_file_text', $dev, _abs($l) );
        return ( "tar: $l: Cannot open: No such file or directory\ntar: Error is not recoverable: exiting now", 0 ) unless defined $t;
        push @mem, grep { length } split /\n/, $t;
    }
    if ( $mode eq 'c' ) {
        return ( "tar: Cowardly refusing to create an empty archive\nTry 'tar --help' or 'tar --usage' for more information.", 0 ) unless @mem;
        my %m;
        my @o;
        # Mitglieder heissen wie angegeben (relativ zu -C bzw. dem aktuellen Verzeichnis), ohne fuehrendes /
        my $base = defined $dir ? _abs($dir) : _cwd() // '/root';
        for my $arg (@mem) {
            my $p = $arg =~ m{\A/} ? $arg : ( $base eq '/' ? '' : $base ) . '/' . ( $arg =~ s{\A\./?}{}r );
            $p =~ s{(?<=.)/+\z}{};
            my @f = _entry( $dev, $p ) ? ($p) : _L( '_under', $dev, $p );
            return ( "tar: $arg: Cannot stat: No such file or directory\ntar: Exiting with failure status due to previous errors", 0 ) unless @f;
            ( my $name = $arg ) =~ s{\A/+}{};
            $name =~ s{/+\z}{};
            for my $f (@f) {
                my $rel = $name . substr( $f, length $p );
                $rel =~ s{\A/}{};
                next if _tar_excluded( $rel, @ex );
                $m{$rel} = copy_entry( _entry( $dev, $f ), 1 );
                push @o, $rel if $verbose;
            }
        }
        # Groesse: die Mitglieder plus Kopf (ungepackt gerechnet; ein leeres Archiv zeigt ls nicht als 0)
        my $sum = 10240;
        $sum += _L( '_file_size', $_ ) for values %m;
        _put( $dev, $file, { tar => \%m, owner => 'root', group => 'root', mode => '0644', mtime => _now_text(), content => '', size => $sum } );
        if ($remove) {    # --remove-files: die Quellen nach dem Packen entfernen
            for my $arg (@mem) {
                my $p = $arg =~ m{\A/} ? $arg : ( $base eq '/' ? '' : $base ) . '/' . ( $arg =~ s{\A\./?}{}r );
                _L( '_rm', $dev, [ '-rf', $p =~ s{(?<=.)/+\z}{}r ] );
            }
        }
        return ( join( "\n", ( grep { m{\A/} } @mem ) ? "tar: Removing leading `/' from member names" : (), @o ), 1 );
    }
    my $ar = _entry( $dev, $file );
    return ( "tar: $file: Cannot open: No such file or directory\ntar: Error is not recoverable: exiting now", 0 ) unless $ar;
    my $members = $ar->{tar};
    return ( "tar: This does not look like a tar archive\ntar: Exiting with failure status due to previous errors", 0 ) unless ref $members eq 'HASH';
    my @names = sort keys %$members;
    if ( $ar->{corrupt} ) {
        my @half = @names[ 0 .. int( $#names / 2 ) ];
        return ( join( "\n", ( $mode eq 't' ? @half : () ), 'gzip: stdin: unexpected end of file', 'tar: Unexpected EOF in archive',
            'tar: Error is not recoverable: exiting now' ), 0 );
    }
    my @want = map { s{\A/+}{}r } @mem;
    my @sel;
    my %hit;
    for my $n (@names) {
        next if _tar_excluded( $n, @ex );
        if (@want) {
            my ($w) = grep { my $x = $_ =~ s{/+\z}{}r; $n eq $x || index( $n, "$x/" ) == 0 } @want;
            next unless defined $w;
            $hit{$w} = 1;
        }
        push @sel, $n;
    }
    my @miss = grep { !$hit{$_} } @want;
    my $err = @miss ? join( "\n", ( map {"tar: $_: Not found in archive"} @miss ), 'tar: Exiting with failure status due to previous errors' ) : undef;
    if ( $mode eq 't' ) {
        my @l = $verbose ? map { my $e = $members->{$_}; sprintf '%s %s/%s %8d 2026-%s %s', _L( '_mode_text', oct( $e->{mode} // '0644' ) ), $e->{owner} // 'root', $e->{group} // 'root',
            _L( '_file_size', $e ), _date( $e->{mtime} ), $_ } @sel : @sel;
        return ( join( "\n", @l, defined $err ? $err : () ), defined $err ? 0 : 1 );
    }
    if ($stdout) { return ( join( '', map { $members->{$_}{content} // '' } @sel ) =~ s/\n\z//r . ( defined $err ? "\n$err" : '' ), defined $err ? 0 : 1 ) }
    my $base = defined $dir ? _abs($dir) : _cwd() // '/root';
    return ( "tar: $base: Cannot open: No such file or directory\ntar: Error is not recoverable: exiting now", 0 ) unless _L( '_is_dir', $dev, $base ) || $base =~ m{\A/(?:tmp|root|srv|var|etc|opt|home|restore|mnt)\b};
    my @o;
    for my $n (@sel) {
        my @seg = split m{/}, $n;
        next if $strip && @seg <= $strip;
        my $rel = join '/', @seg[ ( $strip // 0 ) .. $#seg ];
        my $to = ( $base eq '/' ? '' : $base ) . "/$rel";
        if ( $keep && _entry( $dev, $to ) ) { push @o, "tar: $rel: Cannot open: File exists"; $err //= 'tar: Exiting with failure status due to previous errors'; next }
        _put( $dev, $to, copy_entry( $members->{$n}, 1 ) );
        $dev->{dirs}{$_} //= {} for grep { !_L( '_is_dir', $dev, $_ ) } _parents($to);
        push @o, $n if $verbose;
    }
    return ( join( "\n", @o, defined $err ? $err : () ), defined $err ? 0 : 1 );
}

sub _parents { my ($p) = @_; my @s = split m{/}, $p; return map { join '/', @s[ 0 .. $_ ] } 1 .. $#s - 1 }

sub _date {
    my ($m) = @_;
    my %mon = ( Jan => '01', Feb => '02', Mar => '03', Apr => '04', May => '05', Jun => '06', Jul => '07', Aug => '08', Sep => '09', Oct => '10', Nov => '11', Dec => '12' );
    return '10-20 12:00' unless defined $m && $m =~ /\A(\w{3})\s+(\d+)\s+(\d+:\d+)\z/;
    return sprintf '%s-%02d %s', $mon{$1} // '10', $2, $3;
}


sub gzip {
    my ( $dev, $av ) = @_;
    my ($f) = grep { !/\A-/ } @$av;
    return ( '', 0 ) unless grep { $_ eq '-t' || $_ eq '--test' } @$av;    # nur Pruefen ist nachgebildet
    my $e = _entry( $dev, _abs( $f // '' ) ) or return ( "gzip: $f: No such file or directory", 0 );
    return ( "gzip: $f: unexpected end of file", 0 ) if $e->{corrupt};
    return ( '', 1 );
}

# --- sha256sum -----------------------------------------------------------------------

sub _sha {
    my ($e) = @_;
    return $e->{sha256} if defined $e->{sha256};
    return Digest::SHA::sha256_hex( _L( '_digest_bytes', $e, $e->{content} ) );    # ohne Inhalt: Daten des Eintrags
}


sub sha256sum {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my $check = grep { $_ eq '-c' || $_ eq '--check' } @a;
    my $quiet = grep { $_ eq '--quiet' } @a;
    my @f = grep { !/\A-/ } @a;
    my ( @l, $ok, $bad );
    $ok = 1;
    if ($check) {
        for my $lf (@f) {
            my $t = _L( '_file_text', $dev, _abs($lf) );
            return ( "sha256sum: $lf: No such file or directory", 0 ) unless defined $t;
            for my $line ( split /\n/, $t ) {
                my ( $h, $p ) = $line =~ /\A([0-9a-f]{64})\s+\*?(.+?)\s*\z/ or next;
                my $path = $p =~ m{\A/} ? $p : do { ( my $d = _abs($lf) ) =~ s{/[^/]*\z}{}; _cwd() ? _abs($p) : "$d/$p" };
                my $e = _entry( $dev, $path );
                if    ( !$e )                 { push @l, "sha256sum: $p: No such file or directory", "$p: FAILED open or read"; $ok = 0 }
                elsif ( _sha($e) eq $h )      { push @l, "$p: OK" unless $quiet }
                else                          { push @l, "$p: FAILED"; $bad++; $ok = 0 }
            }
        }
        push @l, "sha256sum: WARNING: $bad computed checksum" . ( $bad == 1 ? '' : 's' ) . ' did NOT match' if $bad;
        return ( join( "\n", @l ), $ok );
    }
    for my $p (@f) {
        my $e = _entry( $dev, _abs($p) );
        if ( !$e ) { push @l, "sha256sum: $p: No such file or directory"; $ok = 0; next }
        push @l, _sha($e) . "  $p";
    }
    return ( join( "\n", @l ), $ok );
}

# --- rsync ---------------------------------------------------------------------------

sub _loc {
    my ( $dev, $ctx, $spec ) = @_;
    if ( $spec =~ /\A(?:([\w.-]+)@)?([\w.-]+):(.*)\z/ && $spec !~ m{\A/} ) {
        my ( $h, $p ) = ( $2, $3 );
        my $d = ( $ctx->{state} || {} )->{$h};
        return ( undef, undef, "ssh: Could not resolve hostname $h: Name or service not known" ) unless ref $d eq 'HASH';
        return ( $d, length $p ? ( $p =~ m{\A/} ? $p : "/root/$p" ) : '/root' );
    }
    return ( $dev, _abs($spec) );
}

sub _ex_match {
    my ( $rel, $pats ) = @_;
    for my $p (@$pats) {
        my $q = $p;
        my $anch = $q =~ s{\A/}{};
        $q =~ s{/+\z}{};
        ( my $re = quotemeta $q ) =~ s/\\\*\\\*/.*/g;
        $re =~ s/\\\*/[^\/]*/g;
        $re =~ s/\\\?/[^\/]/g;
        return 1 if $anch ? $rel =~ /\A$re(?:\/|\z)/ : $rel =~ /(?:\A|\/)$re(?:\/|\z)/;
    }
    return 0;
}


sub rsync {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my ( %o, @ex, @args );
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A--exclude=(.+)\z/ ) { push @ex, $1 }
        elsif ( $x eq '--exclude' ) { push @ex, shift @a }
        elsif ( $x eq '--delete' || $x =~ /\A--delete-(?:after|before|during|delay)\z/ ) { $o{delete} = 1 }
        elsif ( $x eq '--delete-excluded' ) { $o{delete} = $o{delexcl} = 1 }
        elsif ( $x eq '--dry-run' ) { $o{n} = 1 }
        elsif ( $x eq '--archive' ) { $o{a} = 1 }
        elsif ( $x eq '--recursive' ) { $o{r} = 1 }
        elsif ( $x eq '-e' || $x eq '--rsh' ) { shift @a }
        elsif ( $x =~ /\A--/ ) { }
        elsif ( $x =~ /\A-([a-zA-Z]+)\z/ ) { $o{$_} = 1 for split //, $1 }
        else  { push @args, $x }
    }
    return ( "rsync: [Receiver] error: need at least a source and a destination\nrsync error: syntax or usage error (code 1) at main.c(1678) [Receiver=3.2.7]", 0 ) unless @args >= 2;
    my $dst_spec = pop @args;
    my $rec  = $o{a} || $o{r};
    my $keep = $o{a} || ( $o{p} && $o{o} && $o{g} && $o{t} );
    my ( $dd, $dp, $de ) = _loc( $dev, $ctx, $dst_spec );
    return ( "$de\nrsync: connection unexpectedly closed (0 bytes received so far) [sender]\nrsync error: unexplained error (code 255) at io.c(231) [sender=3.2.7]", 0 ) if $de;
    $dp =~ s{(?<=.)/+\z}{};
    my ( @out, %sent );
    my $err;
    for my $s (@args) {
        my $slash = $s =~ m{/\z};
        my ( $sd, $sp, $se ) = _loc( $dev, $ctx, $s );
        return ( "$se\nrsync: connection unexpectedly closed (0 bytes received so far) [Receiver]\nrsync error: unexplained error (code 255) at io.c(231) [Receiver=3.2.7]", 0 ) if $se;
        $sp =~ s{(?<=.)/+\z}{};
        my @files;
        if ( _entry( $sd, $sp ) ) {
            ( my $b = $sp ) =~ s{.*/}{};
            my $to = _L( '_is_dir', $dd, $dp ) || $dst_spec =~ m{/\z} || @args > 1 ? "$dp/$b" : $dp;
            push @files, [ $sp, $to, $b ];
        }
        elsif ( _L( '_is_dir', $sd, $sp ) ) {
            if ( !$rec ) { push @out, "skipping directory $sp"; next }
            ( my $b = $sp ) =~ s{.*/}{};
            my $root = $slash ? $dp : ( $dp eq '/' ? '' : $dp ) . "/$b";
            for my $f ( _L( '_under', $sd, $sp ) ) {
                my $rel = substr( $f, length($sp) + 1 );
                my $xrel = $slash ? $rel : "$b/$rel";
                next if _ex_match( $xrel, \@ex );
                push @files, [ $f, "$root/$rel", $xrel ];
            }
            $sent{$root} = { map { $_->[1] => 1 } @files } if $o{delete};
            $sent{$root}{__root} = $slash ? '' : $b if $o{delete};
        }
        else {
            push @out, "rsync: [sender] change_dir \"$sp\" failed: No such file or directory (2)";
            $err = 1;
            next;
        }
        for my $f (@files) {
            my ( $from, $to, $rel ) = @$f;
            push @out, $rel if $o{v} || $o{n};
            next if $o{n};
            my $e = copy_entry( _entry( $sd, $from ), $keep );
            if ( !$keep && $o{p} ) { $e->{mode} = _entry( $sd, $from )->{mode} if ref _entry( $sd, $from ) eq 'HASH' && defined _entry( $sd, $from )->{mode} }
            _put( $dd, $to, $e );
        }
    }
    if ( $o{delete} ) {
        for my $root ( sort keys %sent ) {
            my $have = $sent{$root};
            for my $f ( _L( '_under', $dd, $root ) ) {
                next if $have->{$f};
                my $rel = substr( $f, length($root) + 1 );
                my $xrel = length $have->{__root} ? "$have->{__root}/$rel" : $rel;
                next if !$o{delexcl} && _ex_match( $xrel, \@ex );
                push @out, "deleting $rel" if $o{v} || $o{n};
                delete $dd->{files}{$f} unless $o{n};
            }
        }
    }
    unshift @out, 'sending incremental file list' if $o{v} || $o{n};
    push @out, '', 'sent 1,024 bytes  received 64 bytes  2,176.00 bytes/sec', 'total size is 4,096  speedup is 3.76' . ( $o{n} ? ' (DRY RUN)' : '' ) if $o{v} || $o{n};
    push @out, 'rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1338) [sender=3.2.7]' if $err;
    return ( join( "\n", @out ), $err ? 0 : 1 );
}

# --- restic --------------------------------------------------------------------------

sub _repo {
    my ( $dev, $ctx, $spec ) = @_;
    my ( $d, $p );
    if ( $spec =~ /\Asftp:(?:[\w.-]+@)?([\w.-]+):(.+)\z/ ) {
        $d = ( $ctx->{state} || {} )->{$1};
        return ( undef, "Fatal: unable to open repository at $spec: unable to start the sftp session, error: EOF" ) unless ref $d eq 'HASH';
        $p = $2;
    }
    else { ( $d, $p ) = ( $dev, _abs($spec) ) }
    $p =~ s{(?<=.)/+\z}{};
    my $r = ( $d->{restic_repos} || {} )->{$p};
    return ( undef, "Fatal: repository does not exist: unable to open config file: stat $p/config: no such file or directory\nIs there a repository at the following location?\n$spec" ) unless $r;
    return ($r);
}

sub _ts { my ($t) = @_; my @f = $t =~ /(\d+)/g; return Time::Local::timegm( $f[5] // 0, $f[4] // 0, $f[3] // 0, $f[2], $f[1] - 1, $f[0] ) }

# Filter --host/--path/--tag; a filter not given selects all
sub _sel {
    my ( $snaps, %f ) = @_;
    $f{$_} ||= [] for qw( host path tag );
    return grep {
        my $s = $_;
        ( !@{ $f{host} } || grep { $_ eq $s->{host} } @{ $f{host} } )
            && ( !@{ $f{path} } || grep { my $p = $_; grep { $_ eq $p } @{ $s->{paths} || [] } } @{ $f{path} } )
            && ( !@{ $f{tag} } || grep { my $t = $_; grep { $_ eq $t } @{ $s->{tags} || [] } } @{ $f{tag} } )
    } @$snaps;
}

sub _find_snap {
    my ( $r, $id, %f ) = @_;
    my @s = sort { $a->{time} cmp $b->{time} } _sel( $r->{snapshots} || [], %f );
    return $s[-1] if $id eq 'latest';
    my @m = grep { index( $_->{id}, $id ) == 0 } @{ $r->{snapshots} || [] };
    return @m == 1 ? $m[0] : undef;
}

sub _snap_line {
    my ($s) = @_;
    my @p = @{ $s->{paths} || [] };
    my @l = sprintf( '%-9s %-20s %-11s %-11s %s', substr( $s->{id}, 0, 8 ), $s->{time}, $s->{host}, join( ',', @{ $s->{tags} || [] } ), shift(@p) // '' );
    push @l, map { ( ' ' x 54 ) . $_ } @p;
    return @l;
}

# Aufbewahrung wie restic (internal/restic/snapshot_policy.go): neueste zuerst
sub _policy {
    my ( $list, $keep ) = @_;
    my @s = sort { $b->{time} cmp $a->{time} } @$list;
    my %fn = (
        last    => sub { $_[0]{id} },
        hourly  => sub { POSIX::strftime( '%Y%m%d%H', gmtime _ts( $_[0]{time} ) ) },
        daily   => sub { POSIX::strftime( '%Y%m%d',   gmtime _ts( $_[0]{time} ) ) },
        weekly  => sub { POSIX::strftime( '%G%V',     gmtime _ts( $_[0]{time} ) ) },
        monthly => sub { POSIX::strftime( '%Y%m',     gmtime _ts( $_[0]{time} ) ) },
        yearly  => sub { POSIX::strftime( '%Y',       gmtime _ts( $_[0]{time} ) ) },
    );
    my %cnt  = map { $_ => $keep->{$_} } grep { defined $keep->{$_} } keys %fn;
    my %last = ();
    my ( @k, @r );
    return ( \@s, [] ) unless %cnt;
    for my $sn (@s) {
        my $kp;
        for my $rule ( sort keys %cnt ) {
            next unless $cnt{$rule};
            my $v = $fn{$rule}->($sn);
            next if defined $last{$rule} && $last{$rule} eq $v;
            $last{$rule} = $v;
            $cnt{$rule}-- if $cnt{$rule} > 0;
            $kp = 1;
        }
        push @{ $kp ? \@k : \@r }, $sn;
    }
    return ( \@k, \@r );
}


sub restic {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my %env = %{ $Langertha::Holmgang::Sim::Linux::SHENV || {} };
    my ( $repo, $pwf, $cmd, %f, %keep, @rest, %o, @inc, @exc );
    $f{$_} = [] for qw( host path tag );
    $repo = $env{RESTIC_REPOSITORY};
    $pwf  = $env{RESTIC_PASSWORD_FILE};
    while (@a) {
        my $x = shift @a;
        my $val = sub { $x =~ /\A--[\w-]+=(.*)\z/ ? $1 : shift @a };
        if    ( $x =~ /\A(?:-r|--repo)(?:=|\z)/ ) { $repo = $val->() }
        elsif ( $x =~ /\A(?:-p|--password-file)(?:=|\z)/ ) { $pwf = $val->() }
        elsif ( $x =~ /\A--(host|path|tag)(?:=|\z)/ ) { my $k = $1; push @{ $f{$k} }, split /,/, $val->() }
        elsif ( $x =~ /\A--keep-(last|hourly|daily|weekly|monthly|yearly)(?:=|\z)/ ) { my $k = $1; $keep{$k} = $val->() }
        elsif ( $x =~ /\A(?:-t|--target)(?:=|\z)/ ) { $o{target} = $val->() }
        elsif ( $x =~ /\A(?:-i|--include)(?:=|\z)/ ) { push @inc, $val->() }
        elsif ( $x =~ /\A(?:-e|--exclude)(?:=|\z)/ ) { push @exc, $val->() }
        elsif ( $x =~ /\A--group-by(?:=|\z)/ ) { $o{group} = $val->() }
        elsif ( $x eq '--prune' ) { $o{prune} = 1 }
        elsif ( $x eq '--dry-run' || $x eq '-n' ) { $o{dry} = 1 }
        elsif ( $x eq '--remove-all' ) { $o{all} = 1 }
        elsif ( $x =~ /\A-/ ) { }
        elsif ( !defined $cmd ) { $cmd = $x }
        else { push @rest, $x }
    }
    return ( "restic is a backup program which allows saving multiple revisions of files and\ndirectories in an encrypted repository stored on different backends.\n\nUsage:\n  restic [command]", 0 ) unless defined $cmd;
    return ( 'restic 0.14.0 compiled with go1.19.8 on linux/amd64', 1 ) if $cmd eq 'version';
    return ( 'Fatal: Please specify repository location (-r or --repository-file)', 0 ) unless defined $repo;
    my ( $r, $e ) = _repo( $dev, $ctx, $repo );
    return ( $e, 0 ) unless $r;
    if ( !defined $pwf || _abs($pwf) ne ( $r->{password_file} // '' ) ) {
        return ( "Fatal: Load(<password>): open " . _abs($pwf) . ": no such file or directory", 0 ) if defined $pwf && !_entry( $dev, _abs($pwf) );
        return ( "Fatal: an empty password is not allowed by default. Pass the flag `--insecure-no-password` to restic to disable this check", 0 ) unless defined $pwf;
        return ( "Fatal: wrong password or no key found", 0 );
    }
    if ( $r->{lock} && $cmd !~ /\A(?:unlock|snapshots|ls|dump|cat|stats)\z/ ) {
        my $l = $r->{lock};
        return ( "repository is already locked by PID $l->{pid} on $l->{host} by root (UID 0, GID 0)\nlock was created at $l->{time} (12h29m55s ago)\nstorage ID 8a1b2c3d\nthe `unlock` command can be used to remove stale locks", 0 );
    }
    my @snaps = @{ $r->{snapshots} || [] };
    if ( $cmd eq 'snapshots' ) {
        my @s = sort { $a->{time} cmp $b->{time} } _sel( \@snaps, %f );
        my $hr = '-' x 74;
        return ( join( "\n", sprintf( '%-9s %-20s %-11s %-11s %s', 'ID', 'Time', 'Host', 'Tags', 'Paths' ), $hr, ( map { _snap_line($_) } @s ), $hr,
            scalar(@s) . ' snapshots' ), 1 );
    }
    if ( $cmd eq 'unlock' ) {
        delete $r->{lock} if $r->{lock};
        return ( 'successfully removed 1 locks', 1 );
    }
    if ( $cmd eq 'check' ) { return ( "using temporary cache in /tmp/restic-check-cache-1\ncreated new cache in /tmp/restic-check-cache-1\nload indexes\ncheck all packs\ncheck snapshots, trees and blobs\nno errors were found", 1 ) }
    if ( $cmd eq 'stats' ) {
        return ( "repository 3c1f2e9a opened (version 2, compression level auto)\nscanning...\nStats in restore-size mode:\n     Snapshots processed:  " . scalar(@snaps)
            . "\n        Total File Count:  " . ( 0 + map { keys %{ $_->{files} || {} } } @snaps ) . "\n              Total Size:  $r->{size}", 1 );
    }
    if ( $cmd eq 'ls' || $cmd eq 'dump' || $cmd eq 'restore' ) {
        my $id = shift(@rest) // return ( "Fatal: no snapshot ID specified", 0 );
        my $s = _find_snap( $r, $id, %f ) or return ( "Fatal: invalid id \"$id\": no matching ID found for prefix \"$id\"", 0 );
        my %files = %{ $s->{files} || {} };
        if ( $cmd eq 'ls' ) {
            my ($under) = @rest;
            my @n = sort grep { !defined $under || $_ eq $under || index( $_, "$under/" ) == 0 } keys %files;
            return ( join( "\n", "snapshot " . substr( $s->{id}, 0, 8 ) . " of [@{ $s->{paths} || [] }] at $s->{time}):", @n ), 1 );
        }
        if ( $cmd eq 'dump' ) {
            my $p = shift(@rest) // return ( 'Fatal: no file and no snapshot ID specified', 0 );
            my $fe = $files{$p} or return ( "Fatal: cannot dump file: path \"$p\" not found in snapshot", 0 );
            return ( ( ref $fe ? $fe->{content} // '' : $fe ) =~ s/\n\z//r, 1 );
        }
        return ( 'Fatal: Please specify a directory to restore to (--target)', 0 ) unless defined $o{target};
        my $tg = _abs( $o{target} );
        my $match = sub {
            my ( $p, $pats ) = @_;
            for my $q (@$pats) {
                ( my $re = quotemeta( $q =~ s{/+\z}{}r ) ) =~ s/\\\*/[^\/]*/g;
                return 1 if $p =~ /\A$re(?:\/|\z)/ || $p =~ /(?:\A|\/)$re\z/;
            }
            return 0;
        };
        my $n = 0;
        for my $p ( sort keys %files ) {
            next if @inc && !$match->( $p, \@inc );
            next if @exc && $match->( $p, \@exc );
            _put( $dev, ( $tg eq '/' ? '' : $tg ) . $p, copy_entry( $files{$p}, 1 ) );
            $n++;
        }
        return ( "Fatal: there are no files to restore", 0 ) if !$n && @inc;
        return ( "repository 3c1f2e9a opened (version 2, compression level auto)\nrestoring <Snapshot " . substr( $s->{id}, 0, 8 ) . " of [@{ $s->{paths} || [] }] at $s->{time} by root\@$s->{host}> to $tg\nSummary: Restored $n files/dirs", 1 );
    }
    if ( $cmd eq 'forget' ) {
        my @l;
        my %gone;
        if (@rest) {
            for my $id (@rest) {
                my $s = _find_snap( $r, $id, %f ) or return ( "Fatal: invalid id \"$id\": no matching ID found for prefix \"$id\"", 0 );
                $gone{ $s->{id} } = 1;
                push @l, "removed snapshot " . substr( $s->{id}, 0, 8 );
            }
        }
        else {
            return ( 'no policy was specified, no snapshots will be removed', 1 ) unless %keep;
            for my $k ( values %keep ) { return ( "Fatal: invalid argument \"$k\"", 0 ) unless $k =~ /\A\d+\z/ }
            my @by = split /,/, $o{group} // 'host,paths';
            my %grp;
            for my $s ( _sel( \@snaps, %f ) ) {
                my $key = join '|', map { $_ eq 'host' ? $s->{host} : $_ eq 'paths' ? join( ',', sort @{ $s->{paths} || [] } ) : $_ eq 'tags' ? join( ',', sort @{ $s->{tags} || [] } ) : '' } @by;
                push @{ $grp{$key} }, $s;
            }
            push @l, 'Applying Policy: keep ' . join( ', ', map {"$keep{$_} $_ snapshots"} sort keys %keep );
            for my $g ( sort keys %grp ) {
                my ( $k, $rm ) = _policy( $grp{$g}, \%keep );
                push @l, "snapshots for (" . join( ', ', map { my $i = $_; $i } @by ) . " [$g]):", "keep " . scalar(@$k) . ' snapshots:',
                    ( map { _snap_line($_) } sort { $a->{time} cmp $b->{time} } @$k ),
                    ( @$rm ? ( 'remove ' . scalar(@$rm) . ' snapshots:', map { _snap_line($_) } sort { $a->{time} cmp $b->{time} } @$rm ) : () ), '';
                $gone{ $_->{id} } = 1 for @$rm;
            }
        }
        unless ( $o{dry} ) {
            my $free = 0;
            $free += _L( '_bytes', $_->{unique} // 0 ) for grep { $gone{ $_->{id} } } @snaps;
            $r->{snapshots} = [ grep { !$gone{ $_->{id} } } @snaps ];
            $r->{prunable} = _L( '_human', _L( '_bytes', $r->{prunable} // 0 ) + $free ) if $free;
            push @l, _prune($r) if $o{prune};
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( $cmd eq 'prune' ) { return ( _prune($r), 1 ) }
    if ( $cmd eq 'backup' ) {
        return ( 'Fatal: nothing to backup, please specify source files/dirs', 0 ) unless @rest;
        my %files;
        my @paths = map { _abs($_) =~ s{(?<=.)/+\z}{}r } @rest;
        for my $p (@paths) {
            my @fs = _entry( $dev, $p ) ? ($p) : _L( '_under', $dev, $p );
            return ( "Fatal: unable to save snapshot: lstat $p: no such file or directory", 0 ) unless @fs;
            $files{$_} = copy_entry( _entry( $dev, $_ ), 1 ) for @fs;
        }
        for my $x (@exc) { delete $files{$_} for grep { index( $_, $x =~ s{/+\z}{}r ) == 0 } keys %files }
        my $id = substr( Digest::SHA::sha256_hex( JSON::MaybeXS->new( canonical => 1 )->encode( [ \%files, scalar @snaps ] ) ), 0, 8 );
        push @{ $r->{snapshots} }, { id => $id, time => '2026-10-20 12:00:00', host => $dev->{hostname} // $ctx->{host}, paths => [ sort @paths ], tags => [], files => \%files };
        return ( "repository 3c1f2e9a opened (version 2, compression level auto)\nusing parent snapshot " . ( @snaps ? substr( $snaps[-1]{id}, 0, 8 ) : '' )
            . "\n\nFiles:           " . scalar( keys %files ) . " new,     0 changed,     0 unmodified\nAdded to the repository: 12.204 MiB\n\nsnapshot $id saved", 1 );
    }
    return ( "Error: unknown command \"$cmd\" for \"restic\"\nRun 'restic --help' for usage.", 0 );
}

sub _prune {
    my ($r) = @_;
    my $p = _L( '_bytes', $r->{prunable} // 0 );
    my $s = _L( '_bytes', $r->{size} // 0 );
    $r->{size} = _L( '_human', $s - $p > 0 ? $s - $p : 0 ) if $p;
    delete $r->{prunable};
    return "loading indexes...\nfinding data that is still in use for snapshots\nsearching used packs...\ncollecting packs for deletion and repacking\nto delete: " . _L( '_human', $p ) . "\ndone";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Backup - Backup and restore on a simulated Linux server — tar, rsync, restic, sha256sum

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator: tar, rsync, restic, sha256sum, gzip -t
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Backup::tar( $dev, \@argv, $ctx );

=head1 DESCRIPTION

Backup and restore tools on a device of type C<linux>
(cai-platform F<docs/entwurf-evals.md> §3.3.1). Files are entries under C<files> with
content (or a fixed size), C<owner>, C<group>, C<mode>, C<mtime>
(C<"Oct 19 23:30">).

B<tar> archive: a file entry with C<tar> — the members with a relative path
(GNU tar strips the leading C</>), one file entry per member;
C<corrupt: true> makes a damaged archive:

  /var/backups/etc-2026-10-19.tar.gz: { size: 2M, mtime: "Oct 19 23:30", sha256: "…",
      tar: { etc/nginx/nginx.conf: { content: "…", owner: root, group: root, mode: "0644", mtime: "Oct 01 10:00" } } }

Commands: C<tar -c|-x|-t [-z|-j|-J] [-v] -f archive [-C dir] [--strip-components=N]
[--exclude=pattern] [-k] [-O] [-T list|--files-from=list] [--remove-files] [member …]> (bundled like C<xzvf>; as root
with owner, mode and time; without C<-C> into the current directory, default
F</root>), C<rsync [-a|-r|-p|-o|-g|-t|-v|-n|-h|-P] [--delete] [--exclude=pattern]
source … dest> (local and C<host:path> to another device; a trailing slash on
the source = contents instead of the directory), C<sha256sum [-c list] file …>
(checksum from the entry's C<sha256>, else from the content), C<gzip -t>.

B<restic>: repositories live on the device that holds them:

  restic_repos:
    /srv/restic/web1:                       # local (-r /srv/…) or sftp:host:/srv/… from another device
      password_file: /root/.restic-pass     # the file --password-file or RESTIC_PASSWORD_FILE must name
      size: 41G                             # used
      prunable: 0                           # set by the simulator: data of forgotten snapshots until prune
      lock: { host: web1, pid: 4711, time: "2026-10-19 23:30:05" }   # optional, stale
      snapshots: [ { id: 4f2a9c1e, time: "2026-10-19 23:30:02", host: web1, paths: [/etc, /srv/www],
                     tags: [], unique: 1.2G, files: { /etc/x: { … } } } ]

C<restic -r repo --password-file f snapshots|ls|restore|dump|forget|prune|check|
unlock|backup|stats> with C<--host>, C<--path>, C<--tag>, C<--target>,
C<--include>, C<--exclude>, C<--keep-last|hourly|daily|weekly|monthly|yearly N>,
C<--group-by>, C<--prune>, C<--dry-run>. C<forget> computes retention like
restic (per group of host and paths, newest first, per rule one snapshot per
day/week/month); forgotten data is freed only by C<prune> (or C<--prune>).

=head2 copy_entry

  my $new = copy_entry( $entry, $preserve );

Copy of a file entry: preserved (owner, mode, time) or new (root, mode minus umask 022, now).

=head2 tar

C<tar> (see above).

=head2 gzip

C<gzip -t>.

=head2 sha256sum

C<sha256sum [-c list] file ...>.

=head2 rsync

C<rsync> (see above).

=head2 restic

C<restic> (see above).

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
