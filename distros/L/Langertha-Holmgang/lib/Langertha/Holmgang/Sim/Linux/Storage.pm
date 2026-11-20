package Langertha::Holmgang::Sim::Linux::Storage;
# ABSTRACT: Disks and file systems on a simulated Linux server — LVM, mount, fstab, swap, mdadm

use strict;
use warnings;
use utf8;

use JSON::MaybeXS ();

our $VERSION = '0.002';


my $T = JSON::MaybeXS::true();
my $F = JSON::MaybeXS::false();
sub _lx { 'Langertha::Holmgang::Sim::Linux' }
sub _L { my $n = shift; return _lx()->can($n)->(@_) }
sub _b { _L( '_bytes', @_ ) }
sub _h { _L( '_human', @_ ) }
sub _st { $_[0]{storage} //= {} }

# --- Geräte -----------------------------------------------------------------------

# alle Geräte mit Dateisystem-Merkmalen: kanonischer Pfad => Eintrag
sub _all {
    my ($dev) = @_;
    my $s = _st($dev);
    my %d;
    $d{$_} = $s->{disks}{$_} for keys %{ $s->{disks} || {} };
    $d{$_} = $s->{md}{$_}    for keys %{ $s->{md} || {} };
    for my $vg ( keys %{ $s->{vgs} || {} } ) {
        my $lvs = $s->{vgs}{$vg}{lvs} || {};
        $d{"/dev/mapper/$vg-$_"} = $lvs->{$_} for keys %$lvs;
    }
    return \%d;
}


sub canon {
    my ( $dev, $p ) = @_;
    return undef unless defined $p;
    $p =~ s{/+\z}{};
    my $all = _all($dev);
    return $p if $all->{$p};
    if ( $p =~ m{\A/dev/([\w.-]+)/([\w.+-]+)\z} && $1 ne 'mapper' && $1 ne 'disk' ) { my $c = "/dev/mapper/$1-$2"; return $c if $all->{$c} }
    if ( $p =~ m{\A([\w.-]+)/([\w.+-]+)\z} ) { my $c = "/dev/mapper/$1-$2"; return $c if $all->{$c} }    # vg/lv
    if ( $p =~ /\A(UUID|LABEL)=["']?([^"']+)["']?\z/i || $p =~ m{\A/dev/disk/by-(uuid|label)/(.+)\z} ) {
        my ( $k, $v ) = ( lc $1, $2 );
        my ($hit) = grep { ( $all->{$_}{$k} // '' ) eq $v } sort keys %$all;
        return $hit;
    }
    return undef;
}

sub _bd { my ( $dev, $p ) = @_; my $c = canon( $dev, $p ) // return; return ( $c, _all($dev)->{$c} ) }

sub _fssize { my ($e) = @_; return _b( $e->{fssize} // $e->{size} ) }

sub _mounted_at {
    my ( $dev, $c ) = @_;
    my $m = $dev->{mounts} || {};
    return grep { defined canon( $dev, $m->{$_}{dev} ) && canon( $dev, $m->{$_}{dev} ) eq $c } sort keys %$m;
}

sub _vg_of_pv {
    my ( $dev, $pv ) = @_;
    my $s = _st($dev);
    for my $vg ( sort keys %{ $s->{vgs} || {} } ) { return $vg if grep { $_ eq $pv } @{ $s->{vgs}{$vg}{pvs} || [] } }
    return;
}

sub _vg_size {
    my ( $dev, $vg ) = @_;
    my $s = _st($dev);
    my $size = 0;
    $size += _b( $s->{disks}{$_}{size} // 0 ) for @{ $s->{vgs}{$vg}{pvs} || [] };
    my $used = 0;
    $used += _b( $_->{size} ) for values %{ $s->{vgs}{$vg}{lvs} || {} };
    return ( $size, $size - $used );
}

sub _parts { my ( $dev, $disk ) = @_; my $d = _st($dev)->{disks} || {}; return sort grep { ( $d->{$_}{parent} // '' ) eq $disk } keys %$d }

sub _gib { my ($b) = @_; return sprintf '%.2f GiB', $b / 1024**3 }
sub _g   { my ($b) = @_; my $x = $b / 1024**3; return $x == int $x ? "${x}g" : sprintf( '%.2fg', $x ) }


sub prepare {
    my ( $dev, $ctx ) = @_;
    my $s = $dev->{storage} or return;
    for my $mp ( keys %{ $dev->{mounts} || {} } ) {
        my $m = $dev->{mounts}{$mp};
        my ( $c, $e ) = _bd( $dev, $m->{dev} );
        next unless $e;
        $m->{fstype} //= $e->{fstype} if defined $e->{fstype};
        $m->{opts}   //= 'rw,relatime';
        $e->{reserved_pct} //= $m->{reserved_pct} if defined $m->{reserved_pct};
    }
    $s->{fstab_loaded} //= _L( '_file_text', $dev, '/etc/fstab' ) // '';
    # Einhaengepunkte sind Verzeichnisse, auch wenn gerade nichts eingehaengt ist
    $dev->{dirs}{$_} //= {} for grep { m{\A/.} } ( keys %{ $dev->{mounts} || {} } ), map { $_->{mp} =~ s{(?<=.)/+\z}{}r } _fstab($dev);
    return;
}

# --- fstab, mount ------------------------------------------------------------------

sub _fstab {
    my ($dev) = @_;
    my @e;
    my $n = 0;
    for my $l ( split /\n/, _L( '_file_text', $dev, '/etc/fstab' ) // '' ) {
        $n++;
        next if $l =~ /\A\s*(?:#|\z)/;
        my @f = split ' ', $l;
        push @e, { src => $f[0], mp => $f[1], type => $f[2] // 'auto', opts => $f[3] // 'defaults', line => $n };
    }
    return @e;
}

sub _merge_opts {
    my ( $old, $new ) = @_;
    my @o = grep { length && $_ ne 'defaults' } split /,/, $old // '';
    my %pair = ( ro => 'rw', rw => 'ro', exec => 'noexec', noexec => 'exec', suid => 'nosuid', nosuid => 'suid', dev => 'nodev', nodev => 'dev',
        atime => 'noatime', noatime => 'atime' );
    for my $x ( grep { length && !/\A(?:remount|defaults|nofail|noauto|auto|_netdev|user|nouser|x-.*|comment=.*)\z/ } split /,/, $new // '' ) {
        @o = grep { $_ ne $x && $_ ne ( $pair{$x} // '' ) } @o;
        push @o, $x;
    }
    unshift @o, 'rw' unless grep { $_ eq 'ro' || $_ eq 'rw' } @o;
    @o = ( ( grep { $_ eq 'ro' || $_ eq 'rw' } @o ), grep { $_ ne 'ro' && $_ ne 'rw' } @o );
    return join ',', @o;
}

sub _do_mount {
    my ( $dev, $src, $mp, $type, $opts ) = @_;
    my ( $c, $e ) = _bd( $dev, $src );
    return "mount: $mp: special device $src does not exist." unless $e;
    $mp =~ s{(?<=.)/+\z}{};
    return "mount: $mp: mount point does not exist." unless _L( '_is_dir', $dev, $mp ) || ( $dev->{dirs} || {} )->{$mp};
    my ($already) = _mounted_at( $dev, $c );
    return "mount: $mp: $src already mounted on $already." if defined $already;
    return "mount: $mp: $mp already mounted or mount point busy." if ( $dev->{mounts} || {} )->{$mp};
    my $fs = $e->{fstype};
    return "mount: $mp: wrong fs type, bad option, bad superblock on $c, missing codepage or helper program, or other error." unless $fs && $fs !~ /\A(?:swap|LVM2_member|linux_raid_member)\z/;
    return "mount: $mp: unknown filesystem type '$type'." if defined $type && $type ne 'auto' && $type ne $fs;
    # was unter dem Einhängepunkt lag, wird verdeckt; das Dateisystem bringt seine Dateien mit
    my $off = delete $e->{offline} || {};
    for my $p ( _L( '_under', $dev, $mp ) ) { $e->{hidden}{$p} = delete $dev->{files}{$p} }
    my $hid = $e->{hidden} ? { %{ $e->{hidden} } } : undef;
    delete $e->{hidden};
    for my $rel ( keys %{ $off->{files} || {} } ) { $dev->{files}{ ( $mp eq '/' ? '' : $mp ) . $rel } = $off->{files}{$rel} }
    $dev->{mounts}{$mp} = { dev => $c, size => _h( _fssize($e) ), used => $off->{used} // '100M', fstype => $fs, opts => _merge_opts( 'rw,relatime', $opts ),
        ( defined $e->{reserved_pct} ? ( reserved_pct => $e->{reserved_pct} ) : () ) };
    _st($dev)->{covered}{$mp} = $hid if $hid && %$hid;
    return undef;
}

sub _do_umount {
    my ( $dev, $mp, $lazy ) = @_;
    my $m = $dev->{mounts}{$mp};
    for my $n ( sort keys %{ $dev->{services} || {} } ) {
        my $svc = $dev->{services}{$n};
        next unless $svc->{active};
        return "umount: $mp: target is busy." if grep { $_ eq $mp || index( $_, "$mp/" ) == 0 } @{ $svc->{uses} || [] };
    }
    my ( $c, $e ) = _bd( $dev, $m->{dev} );
    my %files;
    for my $p ( _L( '_under', $dev, $mp ) ) { $files{ substr( $p, length( $mp eq '/' ? '' : $mp ) ) } = delete $dev->{files}{$p} }
    if ($e) {
        $e->{offline} = { used => $m->{used}, ( %files ? ( files => \%files ) : () ) };
        $e->{fssize} = $m->{size} if _b( $m->{size} ) != _b( $e->{size} );
        $e->{reserved_pct} = $m->{reserved_pct} if defined $m->{reserved_pct};
    }
    delete $dev->{mounts}{$mp};
    $dev->{dirs}{$mp} //= {};
    my $cov = delete( ( _st($dev)->{covered} || {} )->{$mp} ) || {};
    $dev->{files}{$_} = $cov->{$_} for keys %$cov;
    return undef;
}

sub _fstab_hint {
    my ($dev) = @_;
    my $now = _L( '_file_text', $dev, '/etc/fstab' ) // '';
    return $now ne ( _st($dev)->{fstab_loaded} // '' ) ? "mount: (hint) your fstab has been modified, but systemd still uses\n       the old version; use 'systemctl daemon-reload' to reload." : ();
}


sub mount {
    my ( $dev, $av ) = @_;
    my ( @a, $type, $opts, $all );
    my @w = @$av;
    while (@w) {
        my $x = shift @w;
        if    ( $x eq '-t' ) { $type = shift @w }
        elsif ( $x eq '-o' ) { $opts = shift @w }
        elsif ( $x =~ /\A-o(.+)\z/ ) { $opts = $1 }
        elsif ( $x eq '-a' || $x eq '--all' ) { $all = 1 }
        elsif ( $x =~ /\A-[vfnr]+\z/ || $x eq '--verbose' ) { }
        else  { push @a, $x }
    }
    my $m = $dev->{mounts} || {};
    if ( !@a && !$all ) {
        return ( join( "\n", map { "$m->{$_}{dev} on $_ type " . ( $m->{$_}{fstype} // 'ext4' ) . ' (' . ( $m->{$_}{opts} // 'rw,relatime' ) . ')' } sort keys %$m ), 1 );
    }
    my @hint = _fstab_hint($dev);
    if ($all) {
        my @err;
        for my $f ( _fstab($dev) ) {
            next if $f->{type} eq 'swap' || $f->{mp} eq 'none' || $f->{opts} =~ /(?:\A|,)noauto(?:,|\z)/;
            ( my $mp = $f->{mp} ) =~ s{(?<=.)/+\z}{};
            next if $m->{$mp};
            my $e = _do_mount( $dev, $f->{src}, $mp, $f->{type}, $f->{opts} );
            next unless defined $e;
            $e = "mount: $mp: can't find $f->{src}." if $f->{src} =~ /\A(?:UUID|LABEL)=/i && $e =~ /special device/;
            push @err, $e unless $f->{opts} =~ /(?:\A|,)nofail(?:,|\z)/;
        }
        return ( join( "\n", @hint, @err ), @err ? 0 : 1 );
    }
    if ( defined $opts && $opts =~ /(?:\A|,)remount(?:,|\z)/ ) {
        my $t = $a[-1];
        $t =~ s{(?<=.)/+\z}{};
        my ($mp) = grep { $_ eq $t || canon( $dev, $m->{$_}{dev} ) eq ( canon( $dev, $t ) // '' ) } sort keys %$m;
        return ( "mount: $t: mount point not mounted or bad option.", 0 ) unless defined $mp;
        my ( $c, $e ) = _bd( $dev, $m->{$mp}{dev} );
        # wie util-linux: Optionen aus fstab, dann die auf der Befehlszeile
        my ($f) = grep { ( $_->{mp} =~ s{(?<=.)/+\z}{}r ) eq $mp } _fstab($dev);
        my $new = _merge_opts( _merge_opts( $m->{$mp}{opts}, $f ? $f->{opts} : '' ), $opts );
        $m->{$mp}{opts} = $new if $new ne ( $m->{$mp}{opts} // '' );
        return ( '', 1 );
    }
    my ( $src, $mp );
    if ( @a == 1 ) {    # aus fstab
        my $t = $a[0] =~ s{(?<=.)/+\z}{}r;
        my ($f) = grep { ( $_->{mp} =~ s{(?<=.)/+\z}{}r ) eq $t || $_->{src} eq $t || ( canon( $dev, $_->{src} ) // '' ) eq ( canon( $dev, $t ) // '-' ) } _fstab($dev);
        return ( "mount: $t: can't find in /etc/fstab.", 0 ) unless $f;
        ( $src, $mp, $type ) = ( $f->{src}, $f->{mp}, $f->{type} );
        $opts = join ',', grep {defined} $f->{opts}, $opts;
    }
    else { ( $src, $mp ) = @a[ 0, 1 ] }
    my $e = _do_mount( $dev, $src, $mp, $type, $opts );
    $e = "mount: $mp: can't find $src." if defined $e && $src =~ /\A(?:UUID|LABEL)=/i && $e =~ /special device/;
    return ( join( "\n", @hint, defined $e ? $e : () ), defined $e ? 0 : 1 );
}


sub umount {
    my ( $dev, $av ) = @_;
    my @a = grep { !/\A-/ } @$av;
    return ( 'umount: bad usage', 0 ) unless @a;
    my @out;
    for my $t (@a) {
        ( my $x = $t ) =~ s{(?<=.)/+\z}{};
        my $m = $dev->{mounts} || {};
        my ($mp) = grep { $_ eq $x || ( canon( $dev, $m->{$_}{dev} ) // '' ) eq ( canon( $dev, $x ) // '-' ) } sort keys %$m;
        if ( !defined $mp ) { push @out, "umount: $t: not mounted."; next }
        return ( "umount: /: target is busy.", 0 ) if $mp eq '/';
        my $e = _do_umount( $dev, $mp );
        return ( $e, 0 ) if defined $e;
    }
    return ( join( "\n", @out ), @out ? 0 : 1 );
}


sub findmnt {
    my ( $dev, $av ) = @_;
    my @a = grep { !/\A-/ } @$av;
    my %o = map { $_ => 1 } grep {/\A-/} @$av;
    if ( $o{'--verify'} || $o{'-x'} ) {
        my ( @l, $err, $warn );
        my @f = _fstab($dev);
        for my $f (@f) {
            my @m;
            if ( $f->{type} eq 'swap' ) {
                push( @m, "   [E] unreachable source: $f->{src}" ), $err++ unless canon( $dev, $f->{src} ) || _L( '_file_entry', $dev, $f->{src} );
            }
            else {
                my $c = canon( $dev, $f->{src} );
                if ( !$c ) { push @m, "   [E] unreachable source: $f->{src}: No such file or directory"; $err++ }
                elsif ( $f->{type} ne 'auto' && ( _all($dev)->{$c}{fstype} // '' ) ne $f->{type} ) {
                    push @m, "   [E] $f->{type} does not match with on-disk " . ( _all($dev)->{$c}{fstype} // 'unknown' ); $err++;
                }
                if ( $f->{mp} =~ m{\A/} && !_L( '_is_dir', $dev, $f->{mp} ) ) { push @m, "   [E] target does not exist"; $err++ }
                if ( $f->{src} =~ m{\A/dev/(?:sd|vd|nvme|hd)} ) { push @m, "   [W] recommended to use UUID= instead of $f->{src}"; $warn++ }
            }
            push @l, $f->{mp}, @m if @m || $o{'--verbose'} || $o{'-v'};
        }
        push @l, '', sprintf( '0 parse errors, %d error%s, %d warning%s', $err // 0, ( $err // 0 ) == 1 ? '' : 's', $warn // 0, ( $warn // 0 ) == 1 ? '' : 's' );
        return ( join( "\n", grep {defined} @l ), $err ? 0 : 1 );
    }
    if ( $o{'-s'} || $o{'--fstab'} ) {
        my @l = sprintf( '%-20s %-40s %-6s %s', qw( TARGET SOURCE FSTYPE OPTIONS ) );
        push @l, sprintf( '%-20s %-40s %-6s %s', $_->{mp}, $_->{src}, $_->{type}, $_->{opts} ) for _fstab($dev);
        return ( join( "\n", @l ), 1 );
    }
    my $m = $dev->{mounts} || {};
    my @mps = sort keys %$m;
    if (@a) {
        my $t = $a[0] =~ s{(?<=.)/+\z}{}r;
        @mps = grep { $_ eq $t || ( canon( $dev, $m->{$_}{dev} ) // '' ) eq ( canon( $dev, $t ) // '-' ) } @mps;
        return ( '', 0 ) unless @mps;
    }
    return ( join( "\n", sprintf( '%-20s %-28s %-6s %s', qw( TARGET SOURCE FSTYPE OPTIONS ) ),
        map { sprintf '%-20s %-28s %-6s %s', $_, $m->{$_}{dev}, $m->{$_}{fstype} // 'ext4', $m->{$_}{opts} // 'rw,relatime' } @mps ), 1 );
}

# --- lsblk, blkid ------------------------------------------------------------------


sub lsblk {
    my ( $dev, $av ) = @_;
    my ( $o, $err ) = _L( '_lsblk_opts', $av );
    return ( $err, 0 ) if defined $err;
    if ( !$o ) { push @Langertha::Holmgang::Sim::Linux::GAPS, join( ' ', 'lsblk', @$av ); return ( '', 0 ) }
    my $f = $o->{f};
    my $s = _st($dev);
    my $all = _all($dev);
    my %kids;
    my $d = $s->{disks} || {};
    for my $p ( keys %$d ) { push @{ $kids{ $d->{$p}{parent} } }, $p if $d->{$p}{parent} }
    for my $vg ( keys %{ $s->{vgs} || {} } ) {
        for my $pvx ( @{ $s->{vgs}{$vg}{pvs} || [] } ) { push @{ $kids{$pvx} }, map {"/dev/mapper/$vg-$_"} sort keys %{ $s->{vgs}{$vg}{lvs} || {} } }
    }
    for my $md ( keys %{ $s->{md} || {} } ) {
        for my $mem ( keys %{ $s->{md}{$md}{members} || {} } ) { push @{ $kids{$mem} }, $md if ( $s->{md}{$md}{members}{$mem} // '' ) ne 'removed' }
    }
    my %swap = map { $_->{name} => 1 } @{ $s->{swaps} || [] };
    my %row = map { $_->{mount} => $_ } _L( '_df_rows', $dev );
    my @rows;
    my $line;
    $line = sub {
        my ( $p, $pre, $last, $depth ) = @_;
        my $e = $all->{$p} || {};
        ( my $name = $p ) =~ s{\A/dev/(?:mapper/)?}{};
        my @mp = ( _mounted_at( $dev, $p ), $swap{$p} ? '[SWAP]' : () );
        my $r = @mp && $row{ $mp[0] };
        push @rows, { name => $name, path => $p, tree => $depth ? $pre . ( $last ? '└─' : '├─' ) : '', majmin => '254:0', size => _b( $e->{size} ),
            type => $p =~ m{/mapper/} ? 'lvm' : $p =~ m{/md\d} ? ( $e->{level} // 'raid1' ) : $e->{parent} ? 'part' : 'disk', mps => \@mp,
            fstype => $e->{fstype}, label => $e->{label}, uuid => $e->{uuid}, fsavail => $r ? $r->{avail} : undef, fsuse => $r ? $r->{pct} : undef };
        my @k = sort @{ $kids{$p} || [] };
        for my $i ( 0 .. $#k ) { $line->( $k[$i], $depth ? $pre . ( $last ? '  ' : '│ ' ) : '', $i == $#k, $depth + 1 ) }
    };
    my @top = grep { !$d->{$_}{parent} } sort keys %$d;
    my ($want) = @{ $o->{dev} };
    @top = grep { $_ eq ( canon( $dev, $want ) // '' ) } keys %$all if defined $want;
    return ( "lsblk: $want: not a block device", 0 ) if defined $want && !@top;
    $line->( $_, '', 1, 0 ) for @top;
    return ( _L( '_lsblk_table', \@rows, $o ), 1 ) if $o->{table};
    my @l = $f ? sprintf( '%-20s %-11s %-6s %-37s %6s %4s %s', 'NAME', 'FSTYPE', 'LABEL', 'UUID', 'FSAVAIL', 'FSUSE%', 'MOUNTPOINTS' )
        : sprintf( '%-20s %7s %2s %6s %2s %-5s %s', 'NAME', 'MAJ:MIN', 'RM', 'SIZE', 'RO', 'TYPE', 'MOUNTPOINTS' );
    for my $r (@rows) {
        push @l, $f
            ? sprintf( '%-20s %-11s %-6s %-37s %6s %4s %s', $r->{tree} . $r->{name}, $r->{fstype} // '', $r->{label} // '', $r->{uuid} // '',
                defined $r->{fsavail} ? _h( $r->{fsavail} ) : '', defined $r->{fsuse} ? "$r->{fsuse}%" : '', join( ' ', @{ $r->{mps} } ) )
            : sprintf( '%-20s %7s %2d %6s %2d %-5s %s', $r->{tree} . $r->{name}, $r->{majmin}, 0, _h( $r->{size} ), 0, $r->{type}, join( ' ', @{ $r->{mps} } ) );
    }
    return ( join( "\n", @l ), 1 );
}


sub blkid {
    my ( $dev, $av ) = @_;
    my $all = _all($dev);
    my @want = grep { !/\A-/ } @$av;
    my @p = @want ? map { canon( $dev, $_ ) // () } @want : grep { $all->{$_}{fstype} } sort keys %$all;
    return ( '', 0 ) unless @p;
    my @l;
    for my $p (@p) {
        my $e = $all->{$p};
        next unless $e->{fstype};
        push @l, "$p: " . join( ' ', ( defined $e->{label} ? qq{LABEL="$e->{label}"} : () ), ( defined $e->{uuid} ? qq{UUID="$e->{uuid}"} : () ),
            ( $e->{fstype} =~ /ext|xfs/ ? 'BLOCK_SIZE="4096"' : () ), qq{TYPE="$e->{fstype}"} );
    }
    return ( join( "\n", @l ), @l ? 1 : 0 );
}

# --- LVM ---------------------------------------------------------------------------


sub lvm {
    my ( $dev, $av, $ctx, $prog ) = @_;
    my $s = _st($dev);
    my @a = @$av;
    if ( $prog eq 'pvs' || $prog eq 'pvdisplay' ) {
        my @l = sprintf( '  %-10s %-5s %-4s %-5s %8s %8s', qw( PV VG Fmt Attr PSize PFree ) );
        for my $p ( sort grep { ( $s->{disks}{$_}{fstype} // '' ) eq 'LVM2_member' } keys %{ $s->{disks} || {} } ) {
            my $vg = _vg_of_pv( $dev, $p ) // '';
            my $free = $vg ? ( _vg_size( $dev, $vg ) )[1] : _b( $s->{disks}{$p}{size} );
            $free = _b( $s->{disks}{$p}{size} ) if $free > _b( $s->{disks}{$p}{size} );
            push @l, sprintf( '  %-10s %-5s %-4s %-5s %8s %8s', $p, $vg, 'lvm2', $vg ? 'a--' : '---', _g( _b( $s->{disks}{$p}{size} ) ), _g($free) );
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( $prog eq 'vgs' || $prog eq 'vgdisplay' ) {
        my @l = sprintf( '  %-5s %3s %3s %3s %-6s %8s %8s', 'VG', '#PV', '#LV', '#SN', 'Attr', 'VSize', 'VFree' );
        for my $vg ( sort keys %{ $s->{vgs} || {} } ) {
            my ( $size, $free ) = _vg_size( $dev, $vg );
            my $lvs = $s->{vgs}{$vg}{lvs} || {};
            push @l, sprintf( '  %-5s %3d %3d %3d %-6s %8s %8s', $vg, scalar @{ $s->{vgs}{$vg}{pvs} || [] }, scalar( grep { !$lvs->{$_}{origin} } keys %$lvs ),
                scalar( grep { $lvs->{$_}{origin} } keys %$lvs ), 'wz--n-', _g($size), _g($free) );
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( $prog eq 'lvs' || $prog eq 'lvdisplay' ) {
        my @l = sprintf( '  %-16s %-5s %-10s %8s %-8s', qw( LV VG Attr LSize Origin ) );
        for my $vg ( sort keys %{ $s->{vgs} || {} } ) {
            my $lvs = $s->{vgs}{$vg}{lvs} || {};
            push @l, sprintf( '  %-16s %-5s %-10s %8s %-8s', $_, $vg, $lvs->{$_}{origin} ? 'swi-a-s---' : '-wi-ao----', _g( _b( $lvs->{$_}{size} ) ), $lvs->{$_}{origin} // '' )
                for sort keys %$lvs;
        }
        return ( join( "\n", @l ), 1 );
    }
    my @args = grep { !/\A-/ } @a;
    if ( $prog eq 'pvcreate' ) {
        my @o;
        for my $p (@args) {
            my $c = canon( $dev, $p );
            my $e = $c && $s->{disks}{$c};
            return ( "  No device found for $p.", 0 ) unless $e;
            return ( "  Can't open $p exclusively.  Mounted filesystem?", 0 ) if _mounted_at( $dev, $c ) || grep { _mounted_at( $dev, $_ ) } _parts( $dev, $c );
            return ( "  Cannot use $p: device is partitioned", 0 ) if _parts( $dev, $c );
            if ( defined $e->{fstype} && $e->{fstype} ne 'LVM2_member' && !grep { /\A-(?:f|ff|y|\w*f)\z/ } @a ) {
                return ( "WARNING: $e->{fstype} signature detected on $p at offset 1080. Wipe it? [y/n]: [n]\n  Aborted wiping of $e->{fstype}.\n  1 existing signature left on the device.", 0 );
            }
            return ( "  Can't initialize physical volume \"$p\" of volume group \"" . _vg_of_pv( $dev, $c ) . "\" without -ff", 0 ) if _vg_of_pv( $dev, $c );
            $e->{fstype} = 'LVM2_member';
            delete @{$e}{qw( uuid label offline fssize )};
            $e->{uuid} = _uuid( $dev, $c, 'pv' );
            push @o, "  Physical volume \"$p\" successfully created.";
        }
        return ( join( "\n", @o ), 1 );
    }
    if ( $prog eq 'vgextend' ) {
        my ( $vg, @pvs ) = @args;
        return ( "  Volume group \"" . ( $vg // '' ) . "\" not found", 0 ) unless defined $vg && $s->{vgs}{$vg};
        my @o;
        for my $p (@pvs) {
            my $c = canon( $dev, $p );
            my $e = $c && $s->{disks}{$c};
            return ( "  No device found for $p.", 0 ) unless $e;
            if ( ( $e->{fstype} // '' ) ne 'LVM2_member' ) {
                my ( $o, $ok ) = lvm( $dev, [ $p, grep {/\A-/} @a ], $ctx, 'pvcreate' );
                return ( $o, 0 ) unless $ok;
                push @o, $o;
            }
            my $other = _vg_of_pv( $dev, $c );
            return ( "  Physical volume '$p' is already in volume group '$other'", 0 ) if $other;
            push @{ $s->{vgs}{$vg}{pvs} }, $c;
        }
        push @o, "  Volume group \"$vg\" successfully extended";
        return ( join( "\n", @o ), 1 );
    }
    if ( $prog =~ /\Alv(?:extend|resize|create)\z/ ) {
        my ( $size, $ext, $name, $snap, $resize );
        my @w = @a;
        my @pos;
        while (@w) {
            my $x = shift @w;
            if    ( $x =~ /\A(?:-L|--size)(?:=?(.+))?\z/ )    { $size = $1 // shift @w }
            elsif ( $x =~ /\A(?:-l|--extents)(?:=?(.+))?\z/ ) { $ext  = $1 // shift @w }
            elsif ( $x =~ /\A(?:-n|--name)(?:=?(.+))?\z/ )    { $name = $1 // shift @w }
            elsif ( $x eq '-s' || $x eq '--snapshot' ) { $snap = 1 }
            elsif ( $x eq '-r' || $x eq '--resizefs' ) { $resize = 1 }
            elsif ( $x =~ /\A-/ ) { }
            else  { push @pos, $x }
        }
        if ( $prog eq 'lvcreate' ) {
            my $target = shift @pos // return ( '  Please specify a volume group or logical volume', 0 );
            my ( $vg, $origin );
            if ($snap) {
                my $c = canon( $dev, $target ) // return ( "  Failed to find logical volume \"$target\"", 0 );
                ( $vg, $origin ) = $c =~ m{\A/dev/mapper/([\w.]+)-(.+)\z} or return ( "  Failed to find logical volume \"$target\"", 0 );
            }
            else { $vg = $target; return ( "  Volume group \"$vg\" not found", 0 ) unless $s->{vgs}{$vg} }
            return ( '  Please specify a name.', 0 ) if !defined $name && $snap;
            $name //= 'lvol0';
            return ( "  Logical Volume \"$name\" already exists in volume group \"$vg\"", 0 ) if $s->{vgs}{$vg}{lvs}{$name};
            my ( $vsize, $free ) = _vg_size( $dev, $vg );
            my $want = defined $size ? _b( $size =~ s/i?B\z//ir ) : defined $ext && $ext =~ /\A(\d+)%FREE\z/i ? int( $free * $1 / 100 ) : 0;
            return ( '  Please specify either size or extents.', 0 ) unless $want;
            return ( sprintf( "  Volume group \"%s\" has insufficient free space (%d extents): %d required.", $vg, $free / 4194304, $want / 4194304 ), 0 ) if $want > $free;
            $s->{vgs}{$vg}{lvs}{$name} = { size => _h($want), ( $snap ? ( origin => $origin ) : () ) };
            return ( "  Logical volume \"$name\" created.", 1 );
        }
        my $target = shift @pos // return ( '  Please specify a logical volume path.', 0 );
        my $c = canon( $dev, $target ) // return ( "  Failed to find logical volume \"$target\"", 0 );
        my ( $vg, $lv ) = $c =~ m{\A/dev/mapper/([\w.]+)-(.+)\z} or return ( "  Failed to find logical volume \"$target\"", 0 );
        my $e = $s->{vgs}{$vg}{lvs}{$lv};
        my $old = _b( $e->{size} );
        my ( $vsize, $free ) = _vg_size( $dev, $vg );
        my $new;
        if ( defined $size ) {
            my ($rel) = $size =~ /\A([+-]?)/;
            ( my $v = $size ) =~ s/\A[+-]//;
            $v =~ s/i?B\z//i;
            $new = $rel eq '+' ? $old + _b($v) : $rel eq '-' ? $old - _b($v) : _b($v);
        }
        elsif ( defined $ext && $ext =~ /\A\+?(\d+)%(FREE|VG)\z/i ) { $new = $old + int( ( uc $2 eq 'FREE' ? $free : $vsize ) * $1 / 100 ) }
        else { return ( '  Please specify either size or extents but not both.', 0 ) }
        return ( "  New size given (" . int( $new / 4194304 ) . " extents) not larger than existing size (" . int( $old / 4194304 ) . " extents)", 0 )
            if $prog eq 'lvextend' && $new <= $old;
        return ( "  Insufficient free space: " . int( ( $new - $old ) / 4194304 ) . " extents needed, but only " . int( $free / 4194304 ) . " available", 0 )
            if $new - $old > $free;
        return ( "  WARNING: Reducing active and open logical volume to " . _gib($new) . ".\n  THIS MAY DESTROY YOUR DATA (filesystem etc.)\nDo you really want to reduce $vg/$lv? [y/n]: [n]\n  Logical volume $vg/$lv NOT reduced.", 0 )
            if $new < $old;
        $e->{size} = _h($new);
        my @o = ( "  Size of logical volume $vg/$lv changed from " . _gib($old) . ' (' . int( $old / 4194304 ) . ' extents) to ' . _gib($new) . ' (' . int( $new / 4194304 ) . ' extents).',
            "  Logical volume $vg/$lv successfully resized." );
        if ($resize) {
            my ($mp) = _mounted_at( $dev, $c );
            my ( $ro, $rok ) = ( $e->{fstype} // '' ) eq 'xfs' ? xfs_growfs( $dev, [ $mp // $c ] ) : resize2fs( $dev, [$c] );
            push @o, $ro;
            return ( join( "\n", @o ), $rok );
        }
        return ( join( "\n", @o ), 1 );
    }
    return ( '', 0 );
}

sub _uuid {
    my ( $dev, $c, $salt ) = @_;
    require Digest::SHA;
    my $h = Digest::SHA::sha1_hex( join '|', $dev->{hostname} // '', $c, $salt, scalar keys %{ _all($dev) } );
    return $salt eq 'pv' ? join( '-', substr( $h, 0, 6 ), substr( $h, 6, 4 ), substr( $h, 10, 4 ), substr( $h, 14, 4 ), substr( $h, 18, 4 ), substr( $h, 22, 4 ), substr( $h, 26, 6 ) )
        : join( '-', substr( $h, 0, 8 ), substr( $h, 8, 4 ), substr( $h, 12, 4 ), substr( $h, 16, 4 ), substr( $h, 20, 12 ) );
}

# --- Dateisysteme ------------------------------------------------------------------

sub _grow {
    my ( $dev, $c, $e, $to ) = @_;
    my @mp = _mounted_at( $dev, $c );
    if (@mp) { $dev->{mounts}{$_}{size} = _h($to) for @mp; delete $e->{fssize} }
    else     { if ( $to == _b( $e->{size} ) ) { delete $e->{fssize} } else { $e->{fssize} = _h($to) } }
    return @mp;
}


sub resize2fs {
    my ( $dev, $av ) = @_;
    my @a = grep { !/\A-/ } @$av;
    my ( $p, $want ) = @a;
    return ( "Usage: resize2fs [-d debug_flags] [-f] [-F] [-M] [-P] [-p] device [-b|-s|new_size] [-S RAID-stride] [-z undo_file]", 0 ) unless defined $p;
    my ( $c, $e ) = _bd( $dev, $p );
    return ( "resize2fs 1.47.0 (5-Feb-2023)\nopen: No such file or directory while opening $p", 0 ) unless $e;
    return ( "resize2fs 1.47.0 (5-Feb-2023)\nresize2fs: Bad magic number in super-block while trying to open $p\nCouldn't find valid filesystem superblock.", 0 )
        unless ( $e->{fstype} // '' ) =~ /\Aext[234]\z/;
    my @mp = _mounted_at( $dev, $c );
    my $cur = @mp ? _b( $dev->{mounts}{ $mp[0] }{size} ) : _fssize($e);
    my $to = defined $want ? _b( $want =~ s/i?B\z//ir ) : _b( $e->{size} );
    my $blocks = sub { int( $_[0] / 4096 ) };
    return ( "resize2fs 1.47.0 (5-Feb-2023)\nThe containing partition (or device) is only " . $blocks->( _b( $e->{size} ) ) . " (4k) blocks.\nYou requested a new size of " . $blocks->($to) . " blocks.\n", 0 )
        if $to > _b( $e->{size} );
    return ( "resize2fs 1.47.0 (5-Feb-2023)\nThe filesystem is already " . $blocks->($cur) . " (4k) blocks long.  Nothing to do!\n", 1 ) if $to == $cur;
    return ( "resize2fs 1.47.0 (5-Feb-2023)\nFilesystem at $c is mounted on $mp[0]; on-line resizing required\nresize2fs: On-line shrinking not supported", 0 ) if $to < $cur && @mp;
    return ( "resize2fs 1.47.0 (5-Feb-2023)\nPlease run 'e2fsck -f $p' first.\n", 0 ) if $to < $cur;
    _grow( $dev, $c, $e, $to );
    return ( "resize2fs 1.47.0 (5-Feb-2023)\n" . ( @mp ? "Filesystem at $c is mounted on $mp[0]; on-line resizing required\nold_desc_blocks = 3, new_desc_blocks = 4\n" : "Resizing the filesystem on $c to " . $blocks->($to) . " (4k) blocks.\n" )
        . "The filesystem on $c is now " . $blocks->($to) . " (4k) blocks long.\n", 1 );
}


sub xfs_growfs {
    my ( $dev, $av ) = @_;
    my ($t) = grep { !/\A-/ } @$av;
    return ( "Usage: xfs_growfs [options] mountpoint", 0 ) unless defined $t;
    $t =~ s{(?<=.)/+\z}{};
    my $m = $dev->{mounts} || {};
    my ($mp) = grep { $_ eq $t || ( canon( $dev, $m->{$_}{dev} ) // '' ) eq ( canon( $dev, $t ) // '-' ) } sort keys %$m;
    my ( $c, $e ) = defined $mp ? _bd( $dev, $m->{$mp}{dev} ) : ();
    return ( "xfs_growfs: $t is not a mounted XFS filesystem", 0 ) unless $e && ( $e->{fstype} // '' ) eq 'xfs';
    my $old = _b( $m->{$mp}{size} );
    my $new = _b( $e->{size} );
    my $info = "meta-data=$c isize=512    agcount=4, agsize=" . int( $old / 16384 ) . " blks\ndata     =                       bsize=4096   blocks=" . int( $old / 4096 ) . ", imaxpct=25";
    return ( "$info\n", 1 ) if $new <= $old;
    _grow( $dev, $c, $e, $new );
    return ( "$info\ndata blocks changed from " . int( $old / 4096 ) . ' to ' . int( $new / 4096 ), 1 );
}


sub mkfs {
    my ( $dev, $av, $ctx, $prog ) = @_;
    my @a = @$av;
    my ( $type, $force, $label, @pos );
    ($type) = $prog =~ /\Amkfs\.(\w+)\z/;
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-t' ) { $type = shift @a }
        elsif ( $x eq '-L' ) { $label = shift @a }
        elsif ( $x =~ /\A-[Ff]+\z/ ) { $force = 1 }
        elsif ( $x =~ /\A-/ ) { }
        else  { push @pos, $x }
    }
    $type //= 'ext2';
    my ($p) = @pos;
    my ( $c, $e ) = _bd( $dev, $p // '' );
    return ( "mke2fs 1.47.0 (5-Feb-2023)\nThe file " . ( $p // '' ) . " does not exist and no size was specified.", 0 ) unless $e;
    if ( _mounted_at( $dev, $c ) || grep { _mounted_at( $dev, $_ ) } _parts( $dev, $c ) ) {
        return $type eq 'xfs' ? ( "mkfs.xfs: $p contains a mounted filesystem\nUsage: mkfs.xfs", 0 ) : ( "mke2fs 1.47.0 (5-Feb-2023)\n$p contains a $e->{fstype} file system\n\tlast mounted on " . ( _mounted_at( $dev, $c ) )[0] . "\n/dev: $p is mounted; will not make a filesystem here!", 0 );
    }
    return ( "mkfs.$type: $p is apparently in use by the system; will not make a filesystem here!", 0 ) if _vg_of_pv( $dev, $c ) || grep { exists( ( $_->{members} || {} )->{$c} ) } values %{ _st($dev)->{md} || {} };
    if ( $e->{fstype} && !$force ) {
        return $type eq 'xfs' ? ( "mkfs.xfs: $p appears to contain an existing filesystem ($e->{fstype}).\nmkfs.xfs: Use the -f option to force overwrite.", 0 )
            : ( "mke2fs 1.47.0 (5-Feb-2023)\n$p contains a $e->{fstype} file system\nProceed anyway? (y,N) ", 0 );
    }
    delete @{$e}{qw( offline fssize errors reserved_pct )};
    $e->{fstype} = $type;
    $e->{uuid} = _uuid( $dev, $c, "fs-$type" );
    if ( defined $label ) { $e->{label} = $label } else { delete $e->{label} }
    $e->{reserved_pct} = 5 if $type =~ /\Aext/;
    return ( $type eq 'xfs' ? "meta-data=$p isize=512 agcount=4\ndata     = bsize=4096 blocks=" . int( _b( $e->{size} ) / 4096 ) : "mke2fs 1.47.0 (5-Feb-2023)\nCreating filesystem with " . int( _b( $e->{size} ) / 4096 ) . " 4k blocks and 6553600 inodes\nFilesystem UUID: $e->{uuid}\nWriting superblocks and filesystem accounting information: done\n", 1 );
}


sub tune2fs {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $list, $pct, $p );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-l' ) { $list = 1 }
        elsif ( $x eq '-m' ) { $pct = shift @a }
        elsif ( $x =~ /\A-m(\d+(?:\.\d+)?)\z/ ) { $pct = $1 }
        elsif ( $x !~ /\A-/ ) { $p = $x }
    }
    my ( $c, $e ) = _bd( $dev, $p // '' );
    return ( "tune2fs 1.47.0 (5-Feb-2023)\ntune2fs: No such file or directory while trying to open " . ( $p // '' ) . "\nCouldn't find valid filesystem superblock.", 0 ) unless $e;
    return ( "tune2fs 1.47.0 (5-Feb-2023)\ntune2fs: Bad magic number in super-block while trying to open $p", 0 ) unless ( $e->{fstype} // '' ) =~ /\Aext/;
    my @mp = _mounted_at( $dev, $c );
    my $size = @mp ? _b( $dev->{mounts}{ $mp[0] }{size} ) : _fssize($e);
    my $cur = @mp ? $dev->{mounts}{ $mp[0] }{reserved_pct} // $e->{reserved_pct} // 5 : $e->{reserved_pct} // 5;
    if ( defined $pct ) {
        return ( "tune2fs 1.47.0 (5-Feb-2023)\nbad reserved block ratio - $pct", 0 ) unless $pct =~ /\A\d+(?:\.\d+)?\z/ && $pct <= 50;
        $pct = 0 + $pct;
        if (@mp) { $dev->{mounts}{$_}{reserved_pct} = $pct for @mp }
        $e->{reserved_pct} = $pct;
        return ( "tune2fs 1.47.0 (5-Feb-2023)\nSetting reserved blocks percentage to $pct% (" . int( $size / 4096 * $pct / 100 ) . " blocks)", 1 );
    }
    return ( join( "\n", 'tune2fs 1.47.0 (5-Feb-2023)', "Filesystem volume name:   " . ( $e->{label} // '<none>' ), "Filesystem UUID:          " . ( $e->{uuid} // '' ),
        'Filesystem state:         ' . ( $e->{errors} ? 'not clean with errors' : 'clean' ), 'Errors behavior:          Continue',
        'Block count:              ' . int( $size / 4096 ), 'Reserved block count:     ' . int( $size / 4096 * $cur / 100 ), 'Block size:               4096' ), 1 );
}


sub fsck {
    my ( $dev, $av ) = @_;
    my ($p) = grep { !/\A-/ } @$av;
    my $dry = grep { $_ eq '-n' } @$av;
    my ( $c, $e ) = _bd( $dev, $p // '' );
    return ( "e2fsck 1.47.0 (5-Feb-2023)\ne2fsck: No such file or directory while trying to open " . ( $p // '' ), 0 ) unless $e;
    return ( "e2fsck 1.47.0 (5-Feb-2023)\n$p is mounted.\ne2fsck: Cannot continue, aborting.\n", 0 ) if _mounted_at( $dev, $c );
    return ( "fsck.$e->{fstype}: not supported here", 0 ) unless ( $e->{fstype} // '' ) =~ /\Aext/;
    if ( $e->{errors} && !$dry && grep { /\A-\w*[yp]/ } @$av ) {
        delete $e->{errors};
        return ( "e2fsck 1.47.0 (5-Feb-2023)\nPass 1: Checking inodes, blocks, and sizes\nInode 1311 has illegal block(s).  Clear? yes\nPass 2: Checking directory structure\nPass 3: Checking directory connectivity\nPass 4: Checking reference counts\nPass 5: Checking group summary information\n\n$p: ***** FILE SYSTEM WAS MODIFIED *****\n$p: 41022/6553600 files (0.4% non-contiguous), 3820112/26214400 blocks", 1 );
    }
    return ( "e2fsck 1.47.0 (5-Feb-2023)\nPass 1: Checking inodes, blocks, and sizes\nInode 1311 has illegal block(s).  Clear? no\n\n$p: ********** WARNING: Filesystem still has errors **********", 0 ) if $e->{errors};
    return ( "e2fsck 1.47.0 (5-Feb-2023)\n$p: clean, 41022/6553600 files, 3820112/26214400 blocks", 1 );
}

# --- Swap --------------------------------------------------------------------------

# frei fuer root (darf die reservierten Bloecke nutzen) auf dem Dateisystem eines Pfads
sub _root_free {
    my ( $dev, $path ) = @_;
    my $mp = _L( '_mount_of', $dev, $path ) // return 0 + 'inf';
    my ($r) = grep { $_->{mount} eq $mp } _L( '_df_rows', $dev );
    my $old = ( $dev->{files} || {} )->{$path};
    return $r ? $r->{size} - $r->{used} + ( ref $old eq 'HASH' ? _L( '_file_size', $old ) : 0 ) : 0 + 'inf';
}


sub swap {
    my ( $dev, $av, $ctx, $prog ) = @_;
    my $s = _st($dev);
    my @a = @$av;
    my @pos = grep { !/\A-/ } @a;
    my $abs = sub { _L( '_absp', $_[0] ) };
    if ( $prog eq 'fallocate' ) {
        my ($len) = join( ' ', @a ) =~ /(?:-l\s*|--length[= ])(\S+)/;
        my ($f) = grep { $_ ne ( $len // '' ) } @pos;
        return ( "fallocate: no length argument specified", 0 ) unless defined $len && defined $f;
        $f = $abs->($f);
        return ( "fallocate: fallocate failed: No space left on device", 0 ) if _b($len) > _root_free( $dev, $f );
        my $old = ( $dev->{files} || {} )->{$f};
        $dev->{files}{$f} = { size => _b($len), owner => 'root', group => 'root', mode => ref $old eq 'HASH' ? $old->{mode} // '0644' : '0644', mtime => 'Oct 20 12:00', content => '' };
        return ( '', 1 );
    }
    if ( $prog eq 'dd' ) {
        my %o = map { /\A(\w+)=(.*)\z/ ? ( $1 => $2 ) : () } @a;
        return ( '', 0 ) unless defined $o{of};
        my $bs = _b( $o{bs} // '512' );
        my $n  = $o{count} // 0;
        my $f  = $abs->( $o{of} );
        my $room = _root_free( $dev, $f );
        if ( $bs * $n > $room ) {    # schreibt bis die Platte voll ist
            my $k = int( $room / ( $bs || 1 ) );
            $dev->{files}{$f} = { size => $k * $bs, owner => 'root', group => 'root', mode => '0644', mtime => 'Oct 20 12:00', content => '' };
            return ( "dd: error writing '$o{of}': No space left on device\n$k+0 records in\n$k+0 records out\n" . ( $k * $bs ) . " bytes copied, 2.0 s, 1.4 GB/s", 0 );
        }
        $dev->{files}{$f} = { size => $bs * $n, owner => 'root', group => 'root', mode => '0644', mtime => 'Oct 20 12:00', content => '' };
        return ( "$n+0 records in\n$n+0 records out\n" . ( $bs * $n ) . " bytes copied, 3.1 s, 1.4 GB/s", 1 );
    }
    if ( $prog eq 'free' ) {
        my $h = grep {/\A-\w*h/} @a;
        my $sw = 0;
        $sw += _b( $_->{size} ) for @{ $s->{swaps} || [] };
        my $f = $h ? sub { _h( $_[0] ) . 'i' } : sub { int( $_[0] / 1024 ) };
        return ( join( "\n", sprintf( '%15s %11s %11s %11s %11s %11s', qw( total used free shared buff/cache available ) ),
            sprintf( 'Mem: %10s %11s %11s %11s %11s %11s', map { $f->( _b($_) ) } qw( 8G 6G 400M 120M 1.6G 1.5G ) ),
            sprintf( 'Swap:%10s %11s %11s', $f->($sw), $f->( $sw ? int( $sw / 4 ) : 0 ), $f->( $sw - ( $sw ? int( $sw / 4 ) : 0 ) ) ) ), 1 );
    }
    if ( $prog eq 'mkswap' ) {
        my $p = $pos[-1] // return ( 'mkswap: no device specified', 0 );
        my ( $c, $e ) = _bd( $dev, $p );
        if ($e) {
            return ( "mkswap: error: $p is mounted; will not make swapspace", 0 ) if _mounted_at( $dev, $c );
            $e->{fstype} = 'swap';
            $e->{uuid} = _uuid( $dev, $c, 'swap' );
            return ( "Setting up swapspace version 1, size = " . _gib( _b( $e->{size} ) ) . "\nno label, UUID=$e->{uuid}", 1 );
        }
        my $f = $abs->($p);
        my $fe = ( $dev->{files} || {} )->{$f};
        return ( "mkswap: cannot open $p: No such file or directory", 0 ) unless ref $fe eq 'HASH';
        $fe->{swap} = _uuid( $dev, $f, 'swap' );
        my $w = ( $fe->{mode} // '0644' ) ne '0600' ? "mkswap: $f: insecure permissions " . ( $fe->{mode} // '0644' ) . ", fix with: chmod 0600 $f\n" : '';
        return ( $w . "Setting up swapspace version 1, size = " . _gib( _b( $fe->{size} ) ) . "\nno label, UUID=$fe->{swap}", 1 );
    }
    if ( $prog eq 'swapon' ) {
        if ( !@pos || grep { $_ eq '--show' || $_ eq '-s' } @a and !grep { $_ eq '-a' } @a ) {
            return ( '', 1 ) unless @{ $s->{swaps} || [] };
            return ( join( "\n", sprintf( '%-15s %-9s %5s %4s %4s', qw( NAME TYPE SIZE USED PRIO ) ),
                map { sprintf '%-15s %-9s %5s %4s %4s', $_->{name}, $_->{name} =~ m{\A/dev/} ? 'partition' : 'file', $_->{size}, '0B', -2 } @{ $s->{swaps} } ), 1 );
        }
        my @targets = @pos;
        if ( grep { $_ eq '-a' } @a ) { push @targets, map { $_->{src} } grep { $_->{type} eq 'swap' && $_->{opts} !~ /noauto/ } _fstab($dev) }
        my @o;
        my $ok = 1;
        for my $t (@targets) {
            my ( $c, $e ) = _bd( $dev, $t );
            my ( $name, $size, $sig );
            if ($e) { ( $name, $size, $sig ) = ( $c, $e->{size}, ( $e->{fstype} // '' ) eq 'swap' ) }
            else {
                my $f = $abs->($t);
                my $fe = ( $dev->{files} || {} )->{$f};
                if ( ref $fe ne 'HASH' ) { push @o, "swapon: cannot open $t: No such file or directory"; $ok = 0; next }
                push @o, "swapon: $f: insecure permissions " . ( $fe->{mode} // '0644' ) . ", 0600 suggested." if ( $fe->{mode} // '0644' ) ne '0600';
                ( $name, $size, $sig ) = ( $f, $fe->{size}, $fe->{swap} );
            }
            next if grep { $_->{name} eq $name } @{ $s->{swaps} || [] };
            if ( !$sig ) { push @o, "swapon: $name: read swap header failed"; $ok = 0; next }
            push @{ $s->{swaps} }, { name => $name, size => _h( _b($size) ) };
        }
        return ( join( "\n", @o ), $ok );
    }
    if ( $prog eq 'swapoff' ) {
        my @t = grep { $_ ne '-a' } @pos;
        if ( grep { $_ eq '-a' } @a ) { delete $s->{swaps}; return ( '', 1 ) }
        for my $t (@t) {
            my $n = canon( $dev, $t ) // $abs->($t);
            my @k = grep { $_->{name} ne $n } @{ $s->{swaps} || [] };
            return ( "swapoff: $t: swapoff failed: Invalid argument", 0 ) if @k == @{ $s->{swaps} || [] };
            $s->{swaps} = \@k;
        }
        return ( '', 1 );
    }
    return ( '', 0 );
}

# --- Partitionen -------------------------------------------------------------------


sub part {
    my ( $dev, $av, $ctx, $prog ) = @_;
    my $s = _st($dev);
    my $d = $s->{disks} ||= {};
    my @a = @$av;
    my @pos = grep { !/\A-/ } @a;
    return ( '', 1 ) if $prog eq 'partprobe';
    if ( $prog eq 'fdisk' ) {    # nur fdisk -l; interaktiv ist eine Luecke der Simulation
        unless ( grep { $_ eq '-l' || $_ eq '--list' } @a ) { push @Langertha::Holmgang::Sim::Linux::GAPS, join( ' ', 'fdisk', @a ); return ( '', 0 ) }
        my @disks = @pos ? map { canon( $dev, $_ ) // () } @pos : grep { !$d->{$_}{parent} } sort keys %$d;
        my @l;
        for my $k (@disks) {
            my $bytes = _b( $d->{$k}{size} );
            push @l, sprintf( 'Disk %s: %s, %d bytes, %d sectors', $k, _gib($bytes), $bytes, $bytes / 512 ), 'Units: sectors of 1 * 512 = 512 bytes',
                'Sector size (logical/physical): 512 bytes / 512 bytes', 'Disklabel type: gpt', '';
            my @p = _parts( $dev, $k );
            next unless @p;
            push @l, sprintf( '%-12s %10s %10s %10s %5s %s', qw( Device Start End Sectors Size Type ) );
            my $pos = sub { $d->{ $_[0] }{start} // ( $_[0] =~ /(\d+)\z/ )[0] };
            my $start = 2048;
            for my $p ( sort { $pos->($a) <=> $pos->($b) } @p ) {
                my $sec = int( _b( $d->{$p}{size} ) / 512 );
                push @l, sprintf( '%-12s %10d %10d %10d %5s %s', $p, $start, $start + $sec - 1, $sec, _h( _b( $d->{$p}{size} ) ),
                    ( $d->{$p}{fstype} // '' ) eq 'vfat' ? 'EFI System' : ( $d->{$p}{fstype} // '' ) eq 'LVM2_member' ? 'Linux LVM' : 'Linux filesystem' );
                $start += $sec;
            }
            push @l, '';
        }
        return ( join( "\n", @l ) =~ s/\n+\z//r, 1 );
    }
    my $pname = sub { my ( $disk, $n ) = @_; return $disk =~ /\d\z/ ? "${disk}p$n" : "$disk$n" };
    my $copy = sub {
        my ( $from, $to ) = @_;
        return ( "sfdisk: cannot open $to: No such file or directory", 0 ) unless $d->{$to} && !$d->{$to}{parent};
        return ( "This disk is currently in use - repartitioning is probably a bad idea.\nUmount all file systems, and swapoff all swap partitions on this disk.\nUse the --no-reread flag to suppress this check.\nsfdisk: Use the --force flag to overrule all checks.", 0 )
            if grep { _mounted_at( $dev, $_ ) || _vg_of_pv( $dev, $_ ) || grep { ( $_->{members}{$_} // '' ) eq 'active' } values %{ $s->{md} || {} } } $to, _parts( $dev, $to );
        my @src = _parts( $dev, $from );
        my $need = 0;
        $need += _b( $d->{$_}{size} ) for @src;
        return ( "sfdisk: failed to add #1 partition: Numerical result out of range", 0 ) if $need > _b( $d->{$to}{size} );
        delete $d->{$_} for _parts( $dev, $to );
        for my $p (@src) {
            my ($n) = $p =~ /(\d+)\z/;
            $d->{ $pname->( $to, $n ) } = { size => $d->{$p}{size}, parent => $to, ( defined $d->{$p}{ptype} ? ( ptype => $d->{$p}{ptype} ) : () ) };
        }
        delete $d->{$to}{fstype};
        return ( "Checking that no-one is using this disk right now ... OK\n\n>>> Script header accepted.\nNew situation:\n" . join( "\n", map { $pname->( $to, ( $_ =~ /(\d+)\z/ )[0] ) . "  " . $d->{$_}{size} } @src )
            . "\n\nThe partition table has been altered.\nSyncing disks.", 1 );
    };
    if ( $prog eq 'sfdisk' ) {
        if ( grep { $_ eq '-d' || $_ eq '--dump' } @a ) {
            my $disk = $pos[0] // return ( 'sfdisk: no disk device specified', 0 );
            return ( "sfdisk: cannot open $disk: No such file or directory", 0 ) unless $d->{$disk};
            my @p = _parts( $dev, $disk );
            my $start = 2048;
            my @l = ( 'label: dos', 'label-id: 0x5d1e2c3f', "device: $disk", 'unit: sectors', 'sector-size: 512', '' );
            for my $p (@p) {
                my $sec = int( _b( $d->{$p}{size} ) / 512 );
                push @l, "$p : start=$start, size=$sec, type=" . ( $d->{$p}{ptype} // '83' );
                $start += $sec;
            }
            return ( join( "\n", @l ), 1 );
        }
        my $stdin = $ctx->{stdin} // '';
        my ($from) = $stdin =~ /^device:\s*(\S+)/m;
        my $to = $pos[0];
        return ( 'sfdisk: no disk device specified', 0 ) unless defined $to;
        return ( "sfdisk: failed to read script", 0 ) unless defined $from && $d->{$from};
        return $copy->( $from, $to );
    }
    if ( $prog eq 'sgdisk' ) {
        my $j = join ' ', @a;
        return ( 'The operation has completed successfully.', 1 ) if $j =~ /(?:\A|\s)(?:-G|--randomize-guids)\b/;
        if ( my ($to) = $j =~ /(?:-R|--replicate)[= ]?(\S+)/ ) {
            my ($from) = grep { $_ ne $to && $d->{$_} } @pos;
            return ( 'Problem opening for reading!', 0 ) unless defined $from;
            my ( $o, $ok ) = $copy->( $from, $to );
            return ( $ok ? 'The operation has completed successfully.' : $o, $ok );
        }
        if ( grep { $_ eq '-p' || $_ eq '--print' } @a ) { return lsblk( $dev, [ $pos[0] ] ) }
        return ( '', 0 );
    }
    if ( $prog eq 'growpart' ) {
        my ( $disk, $n ) = @pos;
        return ( 'usage: growpart disk partition', 0 ) unless defined $n;
        my $p = $pname->( $disk, $n );
        return ( "FAILED: $disk: does not exist", 0 ) unless $d->{$disk};
        return ( "FAILED: partition $n does not exist", 0 ) unless $d->{$p};
        my @p = _parts( $dev, $disk );
        my $used = 0;
        $used += _b( $d->{$_}{size} ) for @p;
        my $free = _b( $d->{$disk}{size} ) - $used - 1024**2;
        # die physisch letzte Partition (start, sonst die Nummer; Cloud-Abbilder haben z. B. 15 vorn)
        my $pos = sub { $d->{ $_[0] }{start} // ( $_[0] =~ /(\d+)\z/ )[0] };
        my ($last) = sort { $pos->($b) <=> $pos->($a) } @p;
        return ( "NOCHANGE: partition $n is size " . int( _b( $d->{$p}{size} ) / 512 ) . ". it cannot be grown", 0 ) if $free <= 0 || $last ne $p;
        my $old = _b( $d->{$p}{size} );
        $d->{$p}{size} = _h( $old + $free + 1024**2 );
        return ( "CHANGED: partition=$n start=2048 old: size=" . int( $old / 512 ) . " end=" . int( $old / 512 + 2048 ) . " new: size=" . int( _b( $d->{$p}{size} ) / 512 ) . " end=" . int( _b( $d->{$p}{size} ) / 512 + 2048 ), 1 );
    }
    return ( '', 0 );
}

# --- mdadm -------------------------------------------------------------------------

sub _mdstat {
    my ($dev) = @_;
    my $md = _st($dev)->{md} || {};
    my @l = ('Personalities : [raid1] [linear] [multipath] [raid0] [raid6] [raid5] [raid4] [raid10]');
    for my $n ( sort keys %$md ) {
        my $m = $md->{$n};
        my $mem = $m->{members} || {};
        my $i = 0;
        my @parts = map { ( my $x = $_ ) =~ s{\A/dev/}{}; $x . '[' . $i++ . ']' . ( $mem->{$_} eq 'faulty' ? '(F)' : $mem->{$_} eq 'spare' ? '(S)' : '' ) } sort keys %$mem;
        my $act = grep { $mem->{$_} eq 'active' } keys %$mem;
        my $reb = grep { $mem->{$_} eq 'rebuilding' } keys %$mem;
        ( my $short = $n ) =~ s{\A/dev/}{};
        push @l, "$short : active $m->{level} @parts", sprintf( '      %d blocks super 1.2 [%d/%d] [%s]', int( _b( $m->{size} ) / 1024 ), $m->{raid_disks}, $act,
            join( '', ('U') x $act, ('_') x ( $m->{raid_disks} - $act ) ) );
        push @l, '      [=>...................]  recovery =  8.4% (3290112/39062464) finish=12.3min speed=48412K/sec' if $reb;
        push @l, '';
    }
    push @l, 'unused devices: <none>';
    return join "\n", @l;
}



sub mdstat { return _mdstat( $_[0] ) }

sub mdadm {
    my ( $dev, $av ) = @_;
    my $s = _st($dev);
    my @a = grep { $_ ne '--manage' } @$av;
    if ( grep { $_ eq '--detail' || $_ eq '-D' } @a ) {
        my ($n) = grep { !/\A-/ } @a;
        my $m = ( $s->{md} || {} )->{ $n // '' } or return ( "mdadm: cannot open " . ( $n // '' ) . ": No such file or directory", 0 );
        my $mem = $m->{members} || {};
        my $act = grep { $mem->{$_} eq 'active' } keys %$mem;
        my $state = $act == $m->{raid_disks} ? 'clean' : ( grep { $mem->{$_} eq 'rebuilding' } keys %$mem ) ? 'clean, degraded, recovering' : 'clean, degraded';
        my $i = 0;
        return ( join( "\n", "$n:", '           Version : 1.2', "        Raid Level : $m->{level}", '        Array Size : ' . int( _b( $m->{size} ) / 1024 ),
            "      Raid Devices : $m->{raid_disks}", '     Total Devices : ' . scalar( keys %$mem ), "             State : $state", "    Active Devices : $act",
            '', '    Number   Major   Minor   RaidDevice State',
            map { sprintf( '       %d       8       %2d        %s      %s   %s', $i, $i * 16 + 1, $mem->{$_} eq 'active' ? $i++ : '-',
                { active => 'active sync', faulty => 'faulty', spare => 'spare', rebuilding => 'spare rebuilding' }->{ $mem->{$_} } // $mem->{$_}, $_ ) } sort keys %$mem ), 1 );
    }
    my ($n) = grep { m{\A/dev/md} } @a;
    my $m = ( $s->{md} || {} )->{ $n // '' } or return ( "mdadm: error opening " . ( $n // '' ) . ": No such file or directory", 0 );
    my @w = grep { $_ ne $n } @a;
    my @o;
    while (@w) {
        my $op = shift @w;
        my $d = shift @w // return ( "mdadm: No devices given.", 0 );
        my $mem = $m->{members} ||= {};
        if ( $op eq '--fail' || $op eq '-f' ) {
            return ( "mdadm: set device faulty failed for $d:  No such device", 0 ) unless exists $mem->{$d};
            $mem->{$d} = 'faulty';
            push @o, "mdadm: set $d faulty in $n";
        }
        elsif ( $op eq '--remove' || $op eq '-r' ) {
            return ( "mdadm: hot remove failed for $d: No such device or address", 0 ) unless exists $mem->{$d};
            return ( "mdadm: hot remove failed for $d: Device or resource busy", 0 ) if $mem->{$d} eq 'active' || $mem->{$d} eq 'rebuilding';
            delete $mem->{$d};
            push @o, "mdadm: hot removed $d from $n";
        }
        elsif ( $op eq '--add' || $op eq '-a' || $op eq '--re-add' ) {
            my ( $c, $e ) = _bd( $dev, $d );
            return ( "mdadm: cannot find $d: No such file or directory", 0 ) unless $e;
            return ( "mdadm: $d is already a member of $n", 0 ) if exists $mem->{$d};
            return ( "mdadm: Cannot open $d: Device or resource busy", 0 ) if _mounted_at( $dev, $c ) || _vg_of_pv( $dev, $c ) || _parts( $dev, $c ) && grep { _mounted_at( $dev, $_ ) } _parts( $dev, $c );
            return ( "mdadm: $d not large enough to join array", 0 ) if _b( $e->{size} ) < _b( $m->{member_size} // $m->{size} );
            my $act = grep { $mem->{$_} eq 'active' || $mem->{$_} eq 'rebuilding' } keys %$mem;
            $mem->{$c} = $act < $m->{raid_disks} ? 'rebuilding' : 'spare';
            $e->{fstype} = 'linux_raid_member';
            push @o, "mdadm: added $c";
        }
        else { return ( "mdadm: unknown option $op", 0 ) }
    }
    return ( join( "\n", @o ), 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Storage - Disks and file systems on a simulated Linux server — LVM, mount, fstab, swap, mdadm

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator: lsblk, blkid, findmnt, mount, umount, pvs, lvextend, resize2fs, …
  Langertha::Holmgang::Sim::Linux::Storage::prepare( $dev );       # when the case loads

=head1 DESCRIPTION

Block devices, LVM, file systems and mount points of a device of type C<linux>
(cai-platform F<docs/entwurf-evals.md> §3.3.1). The state lives under C<storage>, the
mounted file systems as before under C<mounts> (C<df>):

  storage:
    disks:                                   # disks and partitions (parent)
      /dev/vda:  { size: 40G }
      /dev/vda1: { size: 39G, parent: /dev/vda, fstype: ext4, uuid: 0b6f…, label: root }
      /dev/vdb:  { size: 100G }              # empty
    vgs:                                     # LVM: size and free from the PVs and LVs
      vg0: { pvs: [/dev/vda2], lvs: { var: { size: 20G, fstype: ext4, uuid: … }, root: { … } } }
    md:                                      # software RAID
      /dev/md0: { level: raid1, raid_disks: 2, size: 39G, members: { /dev/sda1: active, /dev/sdb1: faulty }, fstype: ext4, uuid: … }
    swaps: [ { name: /dev/vda3, size: 2G } ] # active swap
  mounts:
    /var: { dev: /dev/mapper/vg0-var, size: 20G, used: 19G, fstype: ext4, opts: "rw,relatime", reserved_pct: 5 }

A file system belongs to a device (disk, partition, LV, md) and carries there
C<fstype>, C<uuid>, C<label>, C<fssize> (default: size of the device),
C<reserved_pct>, C<errors>. When mounted, size and usage are in C<mounts>;
C<umount> stores usage and the files under the mount point on the device
(C<offline>), C<mount> brings them back — so the files vanish on
unmount and reappear on mount, also under a different
mount point.

B<Commands>: C<lsblk [-f]>, C<blkid [device]>, C<findmnt [target] [--verify] [-s]>,
C<mount> (list), C<mount -a>, C<mount [-t type] [-o opt] source target>, C<mount target>
(from fstab), C<mount -o remount,…>, C<umount>, C<pvs>, C<vgs>, C<lvs>,
C<pvdisplay|vgdisplay|lvdisplay>, C<pvcreate>, C<vgextend>, C<lvcreate -L|-l -n [-s]>,
C<lvextend|lvresize -L [+]n|-l +n%FREE [-r]>, C<resize2fs>, C<xfs_growfs>,
C<mkfs[.ext4|.xfs] [-F]>, C<mkswap>, C<swapon [-a|--show]>, C<swapoff>,
C<fallocate -l>, C<dd if=/dev/zero of= bs= count=>, C<tune2fs -l|-m>,
C<e2fsck|fsck [-f] [-y]>, C<mdadm --detail|--add|--remove|--fail>,
C<cat /proc/mdstat>, C<sfdisk -d> and C<sfdisk device> (table from the input),
C<sgdisk -R target source>, C<growpart disk n>, C<partprobe>, C<free [-h]>.

B<Like Linux>: C<lvextend> without C<-r> grows only the LV — C<df> sees it
only after C<resize2fs> or C<xfs_growfs>; C<resize2fs> on XFS and
C<xfs_growfs> on ext4 fail; a file system cannot be shrunk;
C<mkfs> refuses mounted devices and asks when a file system is present
(without C<-F> it fails); C<pvcreate> refuses devices with a file system or
partitions; C<umount> fails ("target is busy") while a running service
with C<uses> works below it; C<e2fsck> refuses mounted file systems;
C<swapon> without C<mkswap> fails, warns on permissions other than 0600; C<mount -a>
reports a changed fstab as long as systemd has not reread it.

=head2 canon

  my $path = canon( $dev, "UUID=…" );   # canonical device path or undef

Resolves device names: path, /dev/vg/lv, vg/lv, UUID=, LABEL=, /dev/disk/by-uuid/….

=head2 prepare

When the case loads: adds C<fstype> from the device to mounted file systems
and remembers the fstab systemd has loaded.

=head2 mount

C<mount> (see above).

=head2 umount

C<umount target|device> (C<-l> same as without).

=head2 findmnt

C<findmnt [target] [--verify] [-s]>.

=head2 lsblk

C<lsblk [-f] [device]>.

=head2 blkid

C<blkid [device …]>.

=head2 lvm

C<pvs>, C<vgs>, C<lvs>, C<pvdisplay>, C<vgdisplay>, C<lvdisplay>, C<pvcreate>,
C<vgextend>, C<lvcreate>, C<lvextend>, C<lvresize> (the program as the fourth
value).

=head2 resize2fs

C<resize2fs device [size]> (ext2/3/4 only).

=head2 xfs_growfs

C<xfs_growfs mountpoint|device> (mounted XFS only).

=head2 mkfs

C<mkfs[.ext4|.xfs] [-F|-f] [-L label] device>, C<mkfs -t type>.

=head2 tune2fs

C<tune2fs -l device>, C<tune2fs -m percent device>.

=head2 fsck

C<e2fsck|fsck|fsck.ext4 [-f] [-y|-p|-n] device>.

=head2 swap

C<mkswap>, C<swapon>, C<swapoff>, C<fallocate>, C<dd>, C<free> (the program as the
fourth value).

=head2 part

C<sfdisk>, C<sgdisk>, C<growpart>, C<partprobe> (the program as the fourth value).

=head2 mdadm

C<mdadm --detail md>, C<mdadm [--manage] md --add|--remove|--fail device …>,
C<cat /proc/mdstat> (via C<mdstat>).

=head2 mdstat

Content of F</proc/mdstat>.

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
