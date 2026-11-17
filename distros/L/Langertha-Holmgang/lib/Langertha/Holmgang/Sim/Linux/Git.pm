package Langertha::Holmgang::Sim::Linux::Git;
# ABSTRACT: git on simulated Linux hosts — working copy, index, commits, push to a Forgejo server with hooks

use strict;
use warnings;
use utf8;

use Digest::SHA ();
use Encode ();
use JSON::MaybeXS ();

our $VERSION = '0.001';


our @GAPS;
our $CWD;

my $J = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub _clone { my $j = JSON::MaybeXS->new( canonical => 1 ); return $j->decode( $j->encode( $_[0] ) ) }

my @DAY = qw( Thu Fri Sat Sun Mon Tue Wed );

# --- Repos, Baeume, Commits ------------------------------------------------------------

sub _repo_at {
    my ( $dev, $path ) = @_;
    my $rs = ( $dev->{git} || {} )->{repos} || {};
    return () unless defined $path;
    $path =~ s{/+\z}{} unless $path eq '/';
    for my $root ( sort { length $b <=> length $a } keys %$rs ) {
        return ( $root, $rs->{$root} ) if $path eq $root || index( $path, "$root/" ) == 0;
    }
    return ();
}

sub _text { my ($e) = @_; return ref $e eq 'HASH' ? $e->{content} // '' : $e }

# Arbeitsbaum: Dateien des Geraets unter dem Repo (relativ)
sub _work {
    my ( $dev, $root ) = @_;
    my %w;
    for my $p ( keys %{ $dev->{files} || {} } ) {
        next unless index( $p, "$root/" ) == 0;
        my $rel = substr( $p, length($root) + 1 );
        next if $rel =~ m{\A\.git(?:/|\z)};
        my $e = $dev->{files}{$p};
        next if ref $e eq 'HASH' && defined $e->{link};
        $w{$rel} = _text($e);
    }
    return \%w;
}

sub _set_work {
    my ( $dev, $root, $old, $new ) = @_;
    for my $rel ( keys %$old ) { delete $dev->{files}{"$root/$rel"} unless exists $new->{$rel} }
    for my $rel ( keys %$new ) {
        my $p = "$root/$rel";
        my $e = $dev->{files}{$p};
        if ( ref $e eq 'HASH' ) { $e->{content} = $new->{$rel} } else { $dev->{files}{$p} = $new->{$rel} }
    }
    return;
}

sub _ignore_res {
    my ($tree) = @_;
    my @re;
    for my $l ( split /\n/, $tree->{'.gitignore'} // '' ) {
        $l =~ s/\s+\z//;
        next if $l eq '' || $l =~ /\A#/;
        my $anch = $l =~ s{\A/}{};
        my $dir  = $l =~ s{/\z}{};
        ( my $re = quotemeta $l ) =~ s/\\\*\\\*/.*/g;
        $re =~ s/\\\*/[^\/]*/g;
        $re =~ s/\\\?/[^\/]/g;
        push @re, $anch || $l =~ m{/} ? qr{\A$re(?:/|\z)} : qr{(?:\A|/)$re(?:/|\z)};
    }
    return @re;
}

sub _ignored { my ( $res, $rel ) = @_; return scalar grep { $rel =~ $_ } @$res }

sub _cid {
    my ($c) = @_;
    return Digest::SHA::sha1_hex( $J->encode( [ $c->{parents}, $c->{message}, $c->{author}, $c->{date}, $c->{tree} ] ) );
}

sub _head { my ($r) = @_; return defined $r->{branch} ? ( $r->{refs}{heads} || {} )->{ $r->{branch} } : $r->{detached} }

sub _tree { my ( $r, $id ) = @_; return defined $id && $r->{commits}{$id} ? $r->{commits}{$id}{tree} : {} }

sub _index { my ($r) = @_; return $r->{index} // _clone( _tree( $r, _head($r) ) ) }

sub _ancestors {
    my ( $r, $id ) = @_;
    my %s;
    my @q = grep {defined} ($id);
    while (@q) {
        my $x = shift @q;
        next if $s{$x}++;
        push @q, @{ ( $r->{commits}{$x} || {} )->{parents} || [] };
    }
    return \%s;
}

# Commits von $from (ausschliesslich) bis $to, aelteste zuerst (nur erste Eltern)
sub _range {
    my ( $r, $from, $to ) = @_;
    my $ex = defined $from ? _ancestors( $r, $from ) : {};
    my @l;
    my %seen;
    my @q = grep {defined} ($to);
    while (@q) {
        my $x = shift @q;
        next if $seen{$x}++ || $ex->{$x};
        push @l, $x;
        push @q, @{ ( $r->{commits}{$x} || {} )->{parents} || [] };
    }
    return sort { _order( $r, $a, $b ) } @l;
}

# aelter zuerst: nach Datum, dann nach Reihenfolge des Anlegens
sub _order {
    my ( $r, $x, $y ) = @_;
    my ( $p, $q ) = ( $r->{commits}{$x}, $r->{commits}{$y} );
    return ( $p->{date} // 0 ) <=> ( $q->{date} // 0 ) || ( $p->{seq} // 0 ) <=> ( $q->{seq} // 0 ) || $x cmp $y;
}

# neueste zuerst (eigene Funktion: in den Befehlen ist $a das Argument-Array)
sub _newest_first { my ( $r, @ids ) = @_; return reverse sort { _order( $r, $a, $b ) } @ids }

sub _who {
    my ( $dev, $r ) = @_;
    my %c = ( %{ ( $dev->{git} || {} )->{config} || {} }, %{ $r->{config} || {} } );
    my $host = $dev->{hostname} // 'localhost';
    return ( $c{'user.name'} // 'root' ) . ' <' . ( $c{'user.email'} // "root\@$host" ) . '>';
}

sub _date {
    my ($dev) = @_;
    my $n = ++$dev->{git}{_clock};
    my $t = 1792832400 + 60 * $n;    # 2026-10-24 09:00 UTC, je Commit eine Minute
    return $t;
}

sub _date_text {
    my ($t) = @_;
    my @g = gmtime( $t + 7200 );
    my @mon = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    return sprintf '%s %s %d %02d:%02d:%02d %d +0200', $DAY[ int( ( $t + 7200 ) / 86400 ) % 7 ], $mon[ $g[4] ], $g[3], @g[ 2, 1, 0 ], $g[5] + 1900;
}

sub _mk_commit {
    my ( $dev, $r, %c ) = @_;
    $c{date} //= _date($dev);
    my $id = _cid( \%c );
    $c{seq} = ++$dev->{git}{_seq};
    $r->{commits}{$id} = \%c;
    return $id;
}

sub _subject { my ($m) = @_; my ($s) = split /\n/, $m // ''; return $s // '' }

sub _short { return substr( $_[0] // '', 0, 7 ) }

# Revision -> Commit-ID oder undef
sub _rev {
    my ( $r, $spec ) = @_;
    return undef unless defined $spec;
    my ( $base, $ops ) = $spec =~ /\A(.*?)((?:[~^]\d*)*)\z/;
    $base = 'HEAD' if $base eq '' || $base eq '@';
    my $id;
    if ( $base eq 'HEAD' ) { $id = _head($r) }
    elsif ( $base =~ /\A(.+)\@\{u(?:pstream)?\}\z/ || $base eq '@{u}' ) { my $b = $1 // $r->{branch}; $id = ( $r->{refs}{remotes} || {} )->{"origin/$b"} }
    elsif ( exists( ( $r->{refs}{heads} || {} )->{$base} ) ) { $id = $r->{refs}{heads}{$base} }
    elsif ( exists( ( $r->{refs}{remotes} || {} )->{$base} ) ) { $id = $r->{refs}{remotes}{$base} }
    elsif ( $base =~ m{\Aremotes/(.+)\z} && exists( ( $r->{refs}{remotes} || {} )->{$1} ) ) { $id = $r->{refs}{remotes}{$1} }
    elsif ( exists( ( $r->{refs}{tags} || {} )->{$base} ) ) { $id = $r->{refs}{tags}{$base}{commit} }
    elsif ( $base =~ /\A[0-9a-f]{4,40}\z/ ) {
        my @m = grep { index( $_, $base ) == 0 } keys %{ $r->{commits} || {} };
        $id = $m[0] if @m == 1;
    }
    return undef unless defined $id;
    while ( $ops =~ /\G([~^])(\d*)/gc ) {
        my ( $o, $n ) = ( $1, length $2 ? $2 : 1 );
        if ( $o eq '~' ) { for ( 1 .. $n ) { $id = ( $r->{commits}{$id}{parents} || [] )->[0] // return undef } }
        else { $id = ( $r->{commits}{$id}{parents} || [] )->[ $n - 1 ] // return undef }
    }
    return $id;
}

# --- Ausgabe von Unterschieden ------------------------------------------------------------

sub _lines { my ($t) = @_; return () unless defined $t && length $t; return split /\n/, $t, -1 }

sub _udiff {
    my ( $path, $old, $new ) = @_;
    my @a = _lines($old);
    my @b = _lines($new);
    pop @a if @a && $a[-1] eq '';
    pop @b if @b && $b[-1] eq '';
    # LCS (kleine Dateien)
    my @L = map { [ (0) x ( @b + 1 ) ] } 0 .. @a;
    for my $i ( reverse 0 .. $#a ) { for my $j ( reverse 0 .. $#b ) { $L[$i][$j] = $a[$i] eq $b[$j] ? $L[ $i + 1 ][ $j + 1 ] + 1 : $L[ $i + 1 ][$j] > $L[$i][ $j + 1 ] ? $L[ $i + 1 ][$j] : $L[$i][ $j + 1 ] } }
    my ( $i, $j, @o ) = ( 0, 0 );
    while ( $i < @a || $j < @b ) {
        if ( $i < @a && $j < @b && $a[$i] eq $b[$j] ) { push @o, " $a[$i]"; $i++; $j++ }
        elsif ( $j < @b && ( $i >= @a || $L[$i][ $j + 1 ] > $L[ $i + 1 ][$j] ) ) { push @o, "+$b[$j]"; $j++ }
        else { push @o, "-$a[$i]"; $i++ }
    }
    my @h = ( "diff --git a/$path b/$path", ( !defined $old ? 'new file mode 100644' : !defined $new ? 'deleted file mode 100644' : () ),
        '--- ' . ( defined $old ? "a/$path" : '/dev/null' ), '+++ ' . ( defined $new ? "b/$path" : '/dev/null' ), sprintf( '@@ -%d,%d +%d,%d @@', @a ? 1 : 0, scalar @a, @b ? 1 : 0, scalar @b ) );
    return join "\n", @h, @o;
}

sub _diff_trees {
    my ( $x, $y, $mode ) = @_;
    my @p = sort { $a cmp $b } keys %{ { %$x, %$y } };
    my @ch = grep { ( $x->{$_} // "\0none" ) ne ( $y->{$_} // "\0none" ) } @p;
    return join( "\n", @ch ) if ( $mode // '' ) eq 'name-only';
    if ( ( $mode // '' ) eq 'stat' ) {
        return '' unless @ch;
        my ( $ins, $del ) = ( 0, 0 );
        my @l = map { my $d = _udiff( $_, $x->{$_}, $y->{$_} ); my $pl = () = $d =~ /^\+(?!\+\+ )/mg; my $mi = () = $d =~ /^-(?!-- )/mg; $ins += $pl; $del += $mi;
            sprintf( ' %-30s | %3d %s', $_, $pl + $mi, ( '+' x $pl ) . ( '-' x $mi ) ) } @ch;
        return join "\n", @l, sprintf( ' %d file%s changed', scalar @ch, @ch == 1 ? '' : 's' )
            . ( $ins ? sprintf( ', %d insertion%s(+)', $ins, $ins == 1 ? '' : 's' ) : '' ) . ( $del ? sprintf( ', %d deletion%s(-)', $del, $del == 1 ? '' : 's' ) : '' );
    }
    return join "\n", map { _udiff( $_, $x->{$_}, $y->{$_} ) } @ch;
}

# --- Kommandozeile ----------------------------------------------------------------------------


sub git {
    my ( $dev, $av, $ctx, $cwd ) = @_;
    my @a = @$av;
    my $dir = $cwd;
    while ( @a && $a[0] =~ /\A-/ ) {
        my $x = shift @a;
        if    ( $x eq '-C' ) { my $d = shift @a // ''; $dir = $d =~ m{\A/} ? $d : ( $dir // '/root' ) . "/$d" }
        elsif ( $x eq '-c' ) { shift @a }
        elsif ( $x eq '--no-pager' || $x eq '-P' ) { }
        elsif ( $x eq '--version' ) { return ( 'git version 2.39.5', 1 ) }
        else { return ( "unknown option: $x\nusage: git [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>]", 0 ) }
    }
    my $verb = shift(@a) // return ( "usage: git [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>]\n           <command> [<args>]", 0 );
    $verb = 'status' if $verb eq 'st';
    if ( $verb eq 'config' && grep { $_ eq '--global' } @a ) { return _config( $dev, undef, \@a ) }
    return ( 'git version 2.39.5', 1 ) if $verb eq 'version';
    my ( $root, $r ) = _repo_at( $dev, $dir // '/root' );
    if ( !$r && ( my ( $bp, $key ) = _bare_at( $dev, $dir // '/root' ) ) ) {
        # Bare-Repo auf dem Server: lesen, Tags und Zweige setzen; kein Arbeitsbaum
        return ( 'fatal: this operation must be run in a work tree', 0 ) if $verb =~ /\A(?:status|add|rm|mv|restore|commit|checkout|switch|reset|pull|merge|rebase|cherry-pick|revert|stash|diff|clean)\z/;
        ( my $sub = "_g_$verb" ) =~ s/-/_/g;
        my $f = $verb =~ /\A(?:log|show|tag|branch|rev-parse|describe|config|update-ref|ls-tree|for-each-ref|show-ref|cat-file|ls-remote|count-objects|rev-list|merge-base|fsck)\z/ && __PACKAGE__->can($sub)
            or do { push @GAPS, "git $verb (bare)"; return ( '', 0 ) };
        my $copy = _clone($dev);
        my $s = $copy->{forgejo}{repos}{$key};
        local $s->{branch} = 'main';
        local $CWD = $dir;
        my ( $out, $ok ) = $f->( $copy, $bp, $s, \@a, $ctx );
        delete $s->{branch};
        if ($ok) { view($s); %$dev = %$copy }
        return ( $out // '', $ok );
    }
    unless ($r) {
        return ( "fatal: not a git repository (or any of the parent directories): .git", 0 ) unless $verb =~ /\A(?:clone|init|help)\z/;
        push @GAPS, "git $verb";
        return ( '', 0 );
    }
    ( my $sub = "_g_$verb" ) =~ s/-/_/g;
    my $f = $verb =~ /\A[a-z-]+\z/ && __PACKAGE__->can($sub);
    unless ($f) {
        return ( "git: '$verb' is not a git command. See 'git --help'.", 0 ) unless $verb =~ /\A(?:stash|cherry-pick|revert|bisect|blame|reflog|worktree|submodule|clean|gc|fsck|am|apply|format-patch|grep|describe|shortlog|notes|archive|bundle|clone|init|filter-branch|filter-repo|lfs|range-diff|show-ref|cat-file|symbolic-ref|update-ref|for-each-ref|merge-base|whatchanged|sparse-checkout|mergetool|difftool|gui|help|commit-tree|hash-object|ls-tree|rev-list)\z/;
        push @GAPS, "git $verb";
        return ( '', 0 );
    }
    # gescheiterte Aenderungen hinterlassen nichts
    my $copy = _clone($dev);
    my ( $croot, $cr ) = _repo_at( $copy, $root );
    local $CWD = $dir;
    my ( $out, $ok, $keep ) = $f->( $copy, $croot, $cr, \@a, $ctx );
    if ( $ok || $keep ) { %$dev = %$copy }
    return ( $out // '', $ok );
}

sub _config {
    my ( $dev, $r, $a ) = @_;
    my $global = !$r;
    my @x = grep { !/\A--(?:global|local)\z/ } @$a;
    my $c = $global ? ( $dev->{git}{config} ||= {} ) : ( $r->{config} ||= {} );
    if ( grep { $_ eq '--list' || $_ eq '-l' } @x ) {
        my %all = $global ? %$c : ( %{ ( $dev->{git} || {} )->{config} || {} }, 'core.repositoryformatversion' => 0, 'core.bare' => 'false', %$c,
            map { ( "remote.$_.url" => $r->{remotes}{$_}{url}, "remote.$_.fetch" => "+refs/heads/*:refs/remotes/$_/*" ) } sort keys %{ $r->{remotes} || {} } );
        return ( join( "\n", map {"$_=$all{$_}"} sort keys %all ), 1 );
    }
    if ( ( $x[0] // '' ) eq '--unset' ) { my $k = $x[1] // return ( 'error: wrong number of arguments', 0 ); return ( '', 0 ) unless exists $c->{$k}; delete $c->{$k}; return ( '', 1 ) }
    my $get = ( $x[0] // '' ) eq '--get' ? shift @x : undef;
    my ( $k, $v ) = @x;
    return ( 'error: key does not contain a section: ' . ( $k // '' ), 0 ) unless defined $k && $k =~ /\./;
    if ( !defined $v ) {
        my $val = $global ? $c->{$k} : $c->{$k} // ( ( $dev->{git} || {} )->{config} || {} )->{$k};
        $val //= $r->{remotes}{$1}{url} if !$global && $k =~ /\Aremote\.([^.]+)\.url\z/ && $r->{remotes}{$1};
        return defined $val ? ( $val, 1 ) : ( '', 0 );
    }
    if ( !$global && $k =~ /\Aremote\.([^.]+)\.url\z/ ) {    # steht in .git/config beim Remote
        $r->{remotes}{$1} = { url => $v, _resolve_remote( $dev, $v ) };
        return ( '', 1 );
    }
    $c->{ lc($k) =~ s/\A(user|core|push|pull|init|commit)\.(.*)\z/$1.$2/r } = $v;
    return ( '', 1 );
}

sub _g_config { my ( $dev, $root, $r, $a ) = @_; return _config( $dev, $r, $a ) }

sub _g_remote {
    my ( $dev, $root, $r, $a, $ctx ) = @_;
    my $rm = $r->{remotes} || {};
    return ( join( "\n", map { ( "$_\t$rm->{$_}{url} (fetch)", "$_\t$rm->{$_}{url} (push)" ) } sort keys %$rm ), 1 ) if grep { $_ eq '-v' } @$a;
    return ( join( "\n", sort keys %$rm ), 1 ) unless @$a;
    if ( $a->[0] eq 'get-url' ) { my $x = $rm->{ $a->[1] // '' } or return ( "error: No such remote '" . ( $a->[1] // '' ) . "'", 0 ); return ( $x->{url}, 1 ) }
    if ( $a->[0] eq 'set-url' || $a->[0] eq 'add' ) {
        my ( undef, $name, $url ) = grep { !/\A--/ } @$a;
        return ( 'usage: git remote ' . $a->[0] . ' <name> <newurl>', 0 ) unless defined $url;
        return ( "error: No such remote '$name'", 0 ) if $a->[0] eq 'set-url' && !$rm->{$name};
        return ( "error: remote $name already exists.", 0 ) if $a->[0] eq 'add' && $rm->{$name};
        $r->{remotes}{$name} = { url => $url, _resolve_remote( $dev, $url ) };
        return ( '', 1 );
    }
    if ( $a->[0] eq 'remove' || $a->[0] eq 'rm' ) {
        my $name = $a->[1] // '';
        return ( "error: No such remote: '$name'", 0 ) unless $rm->{$name};
        delete $r->{remotes}{$name};
        delete $r->{refs}{remotes}{$_} for grep { index( $_, "$name/" ) == 0 } keys %{ $r->{refs}{remotes} || {} };
        return ( '', 1 );
    }
    if ( $a->[0] eq 'show' ) {
        my $name = $a->[1] // 'origin';
        my $x = $rm->{$name} or return ( "fatal: '$name' does not appear to be a git repository\nfatal: Could not read from remote repository.", 0 );
        my ( $s, $err ) = _server( $ctx, $r, $name );
        return ( $err, 0 ) unless $s;
        my @b = sort keys %{ $s->{refs}{heads} || {} };
        my $loc = $r->{refs}{heads} || {};
        return ( join( "\n", "* remote $name", "  Fetch URL: $x->{url}", "  Push  URL: $x->{url}", '  HEAD branch: main', '  Remote branch' . ( @b > 1 ? 'es:' : ':' ),
            ( map { "    $_ " . ( exists( ( $r->{refs}{remotes} || {} )->{"$name/$_"} ) ? 'tracked' : "new (next fetch will store in remotes/$name)" ) } @b ),
            "  Local ref configured for 'git push':",
            ( map { my $l = $loc->{$_}; my $sv = $s->{refs}{heads}{$_};
                "    $_ pushes to $_ (" . ( !defined $sv ? 'create' : $l eq $sv ? 'up to date' : _ancestors( $r, $l )->{$sv} ? 'fast-forwardable' : 'local out of date' ) . ')' } grep { exists $loc->{$_} } @b ) ), 1 );
    }
    push @GAPS, "git remote @$a";
    return ( '', 0 );
}


sub virtual {
    my ( $dev, $path ) = @_;
    return undef unless defined $path && $path =~ m{\.git(?:/|\z)};
    my ( $gd, $rest, $r, $bare );
    for my $root ( keys %{ ( $dev->{git} || {} )->{repos} || {} } ) {
        next unless $path eq "$root/.git" || index( $path, "$root/.git/" ) == 0;
        ( $gd, $r ) = ( "$root/.git", $dev->{git}{repos}{$root} );
        last;
    }
    if ( !$r ) {
        my ( $bp, $key ) = _bare_at( $dev, $path ) or return undef;
        ( $gd, $r, $bare ) = ( $bp, $dev->{forgejo}{repos}{$key}, 1 );
    }
    ( $rest = substr( $path, length $gd ) ) =~ s{\A/}{};
    $rest =~ s{/\z}{};
    my $heads = $r->{refs}{heads} || {};
    my $tags  = $r->{refs}{tags} || {};
    my $rem   = $r->{refs}{remotes} || {};
    my %files = (
        HEAD        => defined $r->{branch} || $bare ? 'ref: refs/heads/' . ( $r->{branch} // 'main' ) . "\n" : ( $r->{detached} // '' ) . "\n",
        description => "Unnamed repository; edit this file 'description' to name the repository.\n",
        config      => _git_config_text( $r, $bare ),
        ( map { ( "refs/heads/$_" => "$heads->{$_}\n" ) } keys %$heads ),
        ( map { ( "refs/tags/$_" => "$tags->{$_}{commit}\n" ) } keys %$tags ),
        ( map { ( "refs/remotes/$_" => "$rem->{$_}\n" ) } keys %$rem ),
    );
    return { text => $files{$rest} } if exists $files{$rest};
    my %dirs = map { $_ => 1 } ( '', 'refs', 'refs/heads', 'refs/tags', 'objects', 'info', ( $bare ? () : ( 'hooks', 'logs' ) ), ( %$rem ? 'refs/remotes' : () ),
        map { my @p = split m{/}; map { join '/', @p[ 0 .. $_ ] } 0 .. $#p - 1 } keys %files );
    return undef unless $dirs{$rest};
    my %n;
    for my $p ( keys %files, keys %dirs ) {
        next if $p eq '';
        $n{$1} = 1 if ( $rest eq '' ? $p : index( $p, "$rest/" ) == 0 ? substr( $p, length($rest) + 1 ) : "\0" ) =~ m{\A([^/\0]+)};
    }
    return { dir => [ sort keys %n ] };
}

sub _git_config_text {
    my ( $r, $bare ) = @_;
    my $t = "[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = " . ( $bare ? 'true' : 'false' ) . "\n" . ( $bare ? '' : "\tlogallrefupdates = true\n" );
    for my $n ( sort keys %{ $r->{remotes} || {} } ) { $t .= "[remote \"$n\"]\n\turl = $r->{remotes}{$n}{url}\n\tfetch = +refs/heads/*:refs/remotes/$n/*\n" }
    for my $b ( sort keys %{ $r->{refs}{heads} || {} } ) {
        $t .= "[branch \"$b\"]\n\tremote = origin\n\tmerge = refs/heads/$b\n" if exists( ( $r->{refs}{remotes} || {} )->{"origin/$b"} );
    }
    my %sec;
    for my $k ( sort keys %{ $r->{config} || {} } ) { my ( $s, $n ) = $k =~ /\A([^.]+)\.(.+)\z/ or next; push @{ $sec{$s} }, "\t$n = $r->{config}{$k}" }
    $t .= "[$_]\n" . join( "\n", @{ $sec{$_} } ) . "\n" for sort keys %sec;
    return $t;
}


sub api {
    my ( $dev, $method, $path ) = @_;
    my $fj = $dev->{forgejo} || {};
    my $j = JSON::MaybeXS->new( canonical => 1, utf8 => 0 );
    $path =~ s/\?.*//;
    return ( 405, '{"message":"method not allowed without token"}', 'json' ) if ( $method // 'GET' ) ne 'GET';
    return ( 200, "<!DOCTYPE html>\n<html lang=\"de-DE\">\n<head><title>Forgejo: Code von example.com</title></head>\n<body>Forgejo</body>\n</html>", 'html' ) if $path eq '/' || $path eq '';
    return ( 200, '{"version":"9.0.3+gitea-1.22.0"}', 'json' ) if $path eq '/api/v1/version';
    return ( 200, '{"message":"pong"}', 'json' ) if $path =~ m{\A/api/(?:v1/)?healthz?\z};
    if ( my ( $o, $n, $sub ) = $path =~ m{\A/api/v1/repos/([^/]+)/([^/]+?)(?:\.git)?(?:/(.*))?\z} ) {
        my $s = ( $fj->{repos} || {} )->{"$o/$n"} or return ( 404, '{"errors":null,"message":"GetRepositoryByName","url":"' . ( $fj->{root_url} // '' ) . 'api/swagger"}', 'json' );
        ( my $base = $fj->{root_url} // 'https://localhost/' ) =~ s{/*\z}{/};
        ( my $host = $base ) =~ s{\Ahttps?://([^/:]+).*}{$1}s;
        $sub //= '';
        if ( $sub eq '' ) {
            return ( 200, $j->encode( { id => 1, name => $n, full_name => "$o/$n", owner => { login => $o }, private => JSON::MaybeXS::false(), empty => JSON::MaybeXS::false(),
                archived => JSON::MaybeXS::false(), default_branch => 'main', html_url => "$base$o/$n", clone_url => "$base$o/$n.git", ssh_url => "git\@$host:$o/$n.git",
                has_actions => JSON::MaybeXS::true() } ), 'json' );
        }
        if ( $sub eq 'branches' ) {
            return ( 200, $j->encode( [ map { my $id = $s->{refs}{heads}{$_}; +{ name => $_, protected => exists( ( $s->{protected} || {} )->{$_} ) ? JSON::MaybeXS::true() : JSON::MaybeXS::false(),
                commit => { id => $id, message => ( $s->{commits}{$id} || {} )->{message} // '' } } } sort keys %{ $s->{refs}{heads} || {} } ] ), 'json' );
        }
        if ( $sub eq 'tags' ) {
            return ( 200, $j->encode( [ map { +{ name => $_, commit => { sha => $s->{refs}{tags}{$_}{commit} }, message => $s->{refs}{tags}{$_}{message} // '' } } sort keys %{ $s->{refs}{tags} || {} } ] ), 'json' );
        }
        if ( $sub =~ m{\Acommits\z} ) {
            return ( 200, $j->encode( [ map { +{ sha => $_->{id}, commit => { message => $_->{message}, author => { name => $_->{author} } } } } @{ ( ( $s->{view} || {} )->{main} || {} )->{log} || [] } ] ), 'json' );
        }
        return ( 401, '{"message":"token is required","url":"' . $base . 'api/swagger"}', 'json' ) if $sub =~ m{\A(?:branch_protections|hooks|actions|keys|collaborators|teams)};
        return ( 404, '{"errors":null,"message":"not found","url":"' . $base . 'api/swagger"}', 'json' );
    }
    return ( 401, '{"message":"token is required"}', 'json' ) if $path =~ m{\A/api/v1/(?:admin|user)\b};
    return ( 404, '{"errors":null,"message":"not found"}', 'json' );
}

sub _g_cat_file {
    my ( $dev, $root, $r, $a ) = @_;
    my ($mode) = grep {/\A-[pts]\z/} @$a;
    my ($obj) = grep { !/\A-/ } @$a;
    return ( 'usage: git cat-file (-t | -s | -e | -p | <type>) <object>', 0 ) unless defined $obj;
    my $type = $mode ? substr( $mode, 1 ) : 'p';
    if ( $obj =~ /\A(.*?):(.+)\z/ ) {    # rev:pfad -> Datei
        my $id = _rev( $r, length $1 ? $1 : 'HEAD' ) // return ( "fatal: Not a valid object name $obj", 0 );
        my $t = _tree( $r, $id );
        return ( "fatal: path '$2' does not exist in '$1'", 0 ) unless exists $t->{$2};
        return ( 'blob', 1 ) if $type eq 't';
        return ( length( Encode::encode( 'UTF-8', $t->{$2} ) ), 1 ) if $type eq 's';
        return ( $t->{$2} =~ s/\n\z//r, 1 );
    }
    if ( my $tag = ( $r->{refs}{tags} || {} )->{$obj} ) {
        if ( $tag->{annotated} ) {
            return ( 'tag', 1 ) if $type eq 't';
            return ( join( "\n", "object $tag->{commit}", 'type commit', "tag $obj", 'tagger ' . ( $tag->{tagger} // '' ) . ' 1792832400 +0200', '', $tag->{message} // '' ), 1 );
        }
    }
    my $id = _rev( $r, $obj ) // return ( "fatal: Not a valid object name $obj", 0 );
    my $c = $r->{commits}{$id};
    return ( 'commit', 1 ) if $type eq 't';
    my $text = join "\n", 'tree ' . Digest::SHA::sha1_hex( 'tree:' . $id ), ( map {"parent $_"} @{ $c->{parents} || [] } ),
        "author $c->{author} $c->{date} +0200", "committer $c->{author} $c->{date} +0200", '', $c->{message};
    return ( length( Encode::encode( 'UTF-8', "$text\n" ) ), 1 ) if $type eq 's';
    return ( $text, 1 );
}

sub _g_count_objects {
    my ( $dev, $root, $r ) = @_;
    my $n = scalar keys %{ $r->{commits} || {} };
    return ( ( $n * 3 ) . ' objects, ' . ( $n * 12 ) . ' kilobytes', 1 );
}

sub _g_ls_tree {
    my ( $dev, $root, $r, $a ) = @_;
    my $rec  = grep { $_ eq '-r' || $_ eq '-rt' || $_ eq '-tr' } @$a;
    my $name = grep { $_ eq '--name-only' || $_ eq '--name-status' } @$a;
    my ( $rev, @paths ) = grep { !/\A-/ } @$a;
    return ( 'usage: git ls-tree [<options>] <tree-ish> [<path>...]', 0 ) unless defined $rev;
    my $id = _rev( $r, $rev ) // return ( "fatal: Not a valid object name $rev", 0 );
    my $t = _tree( $r, $id );
    my $blob = sub { Digest::SHA::sha1_hex( 'blob ' . length( Encode::encode( 'UTF-8', $_[0] ) ) . "\0" . Encode::encode( 'UTF-8', $_[0] ) ) };
    my $pre = @paths ? $paths[0] =~ s{/*\z}{/}r : '';
    $pre = '' if $pre eq './';
    my %e;
    for my $p ( sort keys %$t ) {
        next if length $pre && index( $p, $pre ) != 0 && $p ne ( $pre =~ s{/\z}{}r );
        if ($rec) { $e{$p} = [ 'blob', $blob->( $t->{$p} ) ]; next }
        my $rest = length $pre && index( $p, $pre ) == 0 ? substr( $p, length $pre ) : $p;
        my ($first) = split m{/}, $rest;
        my $full = ( length $pre && index( $p, $pre ) == 0 ? $pre : '' ) . $first;
        $e{$full} = $rest =~ m{/} ? [ 'tree', Digest::SHA::sha1_hex("tree:$id:$full") ] : [ 'blob', $blob->( $t->{$p} ) ];
    }
    return ( join( "\n", map { $name ? $_ : ( $e{$_}[0] eq 'tree' ? '040000' : '100644' ) . " $e{$_}[0] $e{$_}[1]\t$_" } sort keys %e ), 1 );
}

sub _g_show_ref {
    my ( $dev, $root, $r, $a ) = @_;
    my $tagsonly = grep { $_ eq '--tags' } @$a;
    my $headsonly = grep { $_ eq '--heads' || $_ eq '--branches' } @$a;
    my @l;
    push @l, map {"$r->{refs}{heads}{$_} refs/heads/$_"} sort keys %{ $r->{refs}{heads} || {} } unless $tagsonly;
    push @l, map {"$r->{refs}{remotes}{$_} refs/remotes/$_"} sort keys %{ $r->{refs}{remotes} || {} } unless $tagsonly || $headsonly;
    push @l, map {"$r->{refs}{tags}{$_}{commit} refs/tags/$_"} sort keys %{ $r->{refs}{tags} || {} } unless $headsonly;
    return ( join( "\n", @l ), @l ? 1 : 0 );
}

sub _g_for_each_ref {
    my ( $dev, $root, $r, $a ) = @_;
    my ($pat) = grep { !/\A-/ } @$a;
    my @l = map { my ( $id, $ref ) = split / /; "$id commit\t$ref" } split /\n/, ( _g_show_ref( $dev, $root, $r, [] ) )[0];
    @l = grep { ( split /\t/ )[1] =~ m{\A\Q$pat\E} } @l if defined $pat;
    return ( join( "\n", @l ), 1 );
}

# Pfad in einem Bare-Repo des Servers (forgejo-repositories/<owner>/<name>.git) -> ( pfad, schluessel )
sub _bare_at {
    my ( $dev, $path ) = @_;
    my $rs = ( $dev->{forgejo} || {} )->{repos} or return ();
    my ( $base, $o, $n ) = ( $path // '' ) =~ m{\A(.*/forgejo-repositories)/([^/]+)/([^/]+?)\.git(?:/.*)?\z} or return ();
    return $rs->{"$o/$n"} ? ( "$base/$o/$n.git", "$o/$n" ) : ();
}

sub _g_update_ref {
    my ( $dev, $root, $r, $a ) = @_;
    my @p = grep { !/\A-/ } @$a;
    if ( grep { $_ eq '-d' } @$a ) {
        my ($ref) = @p;
        ( my $n = $ref // '' ) =~ s{\Arefs/(heads|tags)/}{};
        my $kind = $1 // 'heads';
        return ( "error: cannot lock ref '$ref': unable to resolve reference '$ref'", 0 ) unless exists $r->{refs}{$kind}{$n};
        delete $r->{refs}{$kind}{$n};
        return ( '', 1 );
    }
    my ( $ref, $new ) = @p;
    return ( 'usage: git update-ref [<options>] <refname> <new-val> [<old-val>]', 0 ) unless defined $new;
    my $id = _rev( $r, $new ) // return ( "fatal: $new: not a valid SHA1", 0 );
    ( my $n = $ref ) =~ s{\Arefs/(heads|tags)/}{} or return ( "fatal: update_ref failed for ref '$ref': refusing to update ref with bad name '$ref'", 0 );
    if ( $1 eq 'tags' ) { $r->{refs}{tags}{$n} = { commit => $id } } else { $r->{refs}{heads}{$n} = $id }
    return ( '', 1 );
}

# URL eines Remotes -> Server (host) und Repo (Pfad) ueber die bekannten Namen des Geraets
sub _resolve_remote {
    my ( $dev, $url ) = @_;
    my ( $h, $path );
    if    ( $url =~ m{\Ahttps?://([^/:]+)(?::\d+)?/(.+?)(?:\.git)?/?\z} ) { ( $h, $path ) = ( $1, $2 ) }
    elsif ( $url =~ m{\A(?:ssh://)?(?:[^@/]+@)?([^:/]+)(?::\d+)?[:/](.+?)(?:\.git)?/?\z} ) { ( $h, $path ) = ( $1, $2 ) }
    else  { return () }
    my $hosts = ( $dev->{git} || {} )->{hosts} || {};    # Name -> Geraet (z. B. git.example.com -> git1)
    return ( host => $hosts->{$h} // $h, repo => $path );
}

sub _g_rev_parse {
    my ( $dev, $root, $r, $a ) = @_;
    my @out;
    my $abbrev = 0;
    for my $x (@$a) {
        if    ( $x eq '--abbrev-ref' ) { $abbrev = 1; next }
        elsif ( $x eq '--show-toplevel' ) { push @out, $root; next }
        elsif ( $x eq '--short' ) { $abbrev = 2; next }
        elsif ( $x eq '--git-dir' ) { push @out, "$root/.git"; next }
        if ( $abbrev == 1 && $x eq 'HEAD' ) { push @out, $r->{branch} // 'HEAD'; next }
        if ( $abbrev == 1 && $x =~ /\@\{u/ ) { push @out, "origin/" . ( $r->{branch} // '' ); next }
        my $id = _rev( $r, $x ) // return ( "fatal: ambiguous argument '$x': unknown revision or path not in the working tree.", 0 );
        push @out, $abbrev == 2 ? _short($id) : $id;
    }
    return ( join( "\n", @out ), 1 );
}

sub _tracking {
    my ($r) = @_;
    my $b = $r->{branch} // return ();
    my $up = ( $r->{refs}{remotes} || {} )->{"origin/$b"};
    return () unless defined $up;
    my $h = _head($r);
    my $ahead  = () = _range( $r, $up, $h );
    my $behind = () = _range( $r, $h, $up );
    return ( "origin/$b", $ahead, $behind );
}

sub _changes {
    my ( $dev, $root, $r ) = @_;
    my $head = _tree( $r, _head($r) );
    my $idx  = _index($r);
    my $w    = _work( $dev, $root );
    my @ig   = _ignore_res($w);
    my ( @staged, @unstaged, @untracked );
    for my $p ( sort keys %{ { %$head, %$idx } } ) {
        next if ( $head->{$p} // "\0" ) eq ( $idx->{$p} // "\0" );
        push @staged, [ !exists $head->{$p} ? 'new file' : !exists $idx->{$p} ? 'deleted' : 'modified', $p ];
    }
    for my $p ( sort keys %$idx ) {
        next if ( $w->{$p} // "\0" ) eq $idx->{$p};
        push @unstaged, [ exists $w->{$p} ? 'modified' : 'deleted', $p ];
    }
    for my $p ( sort keys %$w ) { push @untracked, $p unless exists $idx->{$p} || _ignored( \@ig, $p ) }
    return ( \@staged, \@unstaged, \@untracked );
}

sub _g_status {
    my ( $dev, $root, $r, $a ) = @_;
    my ( $st, $un, $ut ) = _changes( $dev, $root, $r );
    if ( grep { /\A(?:-s|--short|--porcelain(?:=v1)?|-sb)\z/ } @$a ) {
        my %m;
        $m{ $_->[1] }[0] = substr( uc $_->[0], 0, 1 ) =~ s/N/A/r for @$st;
        $m{ $_->[1] }[1] = substr( uc $_->[0], 0, 1 ) for @$un;
        my @tr = _tracking($r);
        my $ab = @tr && ( $tr[1] || $tr[2] ) ? ' [' . join( ', ', ( $tr[1] ? "ahead $tr[1]" : () ), ( $tr[2] ? "behind $tr[2]" : () ) ) . ']' : '';
        my @l = ( ( grep { /\A-\w*b/ || $_ eq '--branch' } @$a ) ? '## ' . ( $r->{branch} // 'HEAD (no branch)' ) . ( @tr ? "...$tr[0]$ab" : '' ) : () );
        push @l, map { ( $m{$_}[0] // ' ' ) . ( $m{$_}[1] // ' ' ) . " $_" } sort keys %m;
        push @l, map {"?? $_"} @$ut;
        return ( join( "\n", @l ), 1 );
    }
    my @l = defined $r->{branch} ? ("On branch $r->{branch}") : ( 'HEAD detached at ' . _short( $r->{detached} ) );
    if ( my ( $up, $ah, $be ) = _tracking($r) ) {
        push @l, $ah && $be ? ( "Your branch and '$up' have diverged,", "and have $ah and $be different commits each, respectively.", '  (use "git pull" to merge the remote branch into yours)' )
            : $ah ? ( "Your branch is ahead of '$up' by $ah commit" . ( $ah > 1 ? 's' : '' ) . '.', '  (use "git push" to publish your local commits)' )
            : $be ? ( "Your branch is behind '$up' by $be commit" . ( $be > 1 ? 's' : '' ) . ', and can be fast-forwarded.', '  (use "git pull" to update your local branch)' )
            : ("Your branch is up to date with '$up'.");
    }
    push @l, '', 'Changes to be committed:', '  (use "git restore --staged <file>..." to unstage)', map( { sprintf "\t%-12s%s", "$_->[0]:", $_->[1] } @$st ) if @$st;
    push @l, '', 'Changes not staged for commit:', '  (use "git add <file>..." to update what will be committed)', '  (use "git restore <file>..." to discard changes in working directory)',
        map( { sprintf "\t%-12s%s", "$_->[0]:", $_->[1] } @$un ) if @$un;
    push @l, '', 'Untracked files:', '  (use "git add <file>..." to include in what will be committed)', map( {"\t$_"} @$ut ) if @$ut;
    push @l, '', !@$st && !@$un ? ( @$ut ? 'nothing added to commit but untracked files present (use "git add" to track)' : 'nothing to commit, working tree clean' )
        : !@$st ? 'no changes added to commit (use "git add" and/or "git commit -a")' : () if !@$st || !@$un;
    return ( join( "\n", @l ), 1 );
}

# Pfadangaben (relativ zum Arbeitsverzeichnis) -> relative Pfade im Repo
sub _paths {
    my ( $root, $cwd, @p ) = @_;
    my @r;
    for my $x (@p) {
        my $abs = $x =~ m{\A/} ? $x : ( $cwd // $root ) . "/$x";
        1 while $abs =~ s{/\./}{/} || $abs =~ s{/[^/]+/\.\.(?:/|\z)}{/};
        $abs =~ s{/\.?\z}{};
        push @r, $abs eq $root ? '' : index( $abs, "$root/" ) == 0 ? substr( $abs, length($root) + 1 ) : undef;
    }
    return @r;
}

sub _match_paths {
    my ( $tree, $pat ) = @_;
    return grep { $pat eq '' || $_ eq $pat || index( $_, "$pat/" ) == 0 || _glob_match( $pat, $_ ) } sort keys %$tree;
}

sub _glob_match { my ( $g, $p ) = @_; return 0 unless $g =~ /[*?]/; ( my $re = quotemeta $g ) =~ s/\\\*/.*/g; $re =~ s/\\\?/./g; return $p =~ /\A$re\z/ ? 1 : 0 }

sub _g_add {
    my ( $dev, $root, $r, $a ) = @_;
    my @o = grep {/\A-/} @$a;
    my @p = grep { !/\A-/ } @$a;
    return ( "Nothing specified, nothing added.\nhint: Maybe you wanted to say 'git add .'?", 0 ) unless @p || grep { /\A(?:-A|--all|-u|--update)\z/ } @o;
    return do { push @GAPS, 'git add -p'; ( '', 0 ) } if grep { /\A(?:-p|--patch|-i|--interactive)\z/ } @o;
    my $w   = _work( $dev, $root );
    my $idx = _index($r);
    my @ig  = _ignore_res($w);
    my $all = grep { /\A(?:-A|--all)\z/ } @o;
    my $upd = grep { /\A(?:-u|--update)\z/ } @o;
    my $force = grep { /\A(?:-f|--force)\z/ } @o;
    @p = ('') if !@p;
    for my $pat ( _paths( $root, $CWD, @p ) ) {
        return ( "fatal: pathspec outside repository", 0 ) unless defined $pat;
        my @hit = _match_paths( { %$w, %$idx }, $pat );
        return ( "fatal: pathspec '$pat' did not match any files", 0 ) unless @hit || $pat eq '';
        for my $f (@hit) {
            next if $upd && !exists $idx->{$f};
            if ( exists $w->{$f} ) {
                if ( !exists $idx->{$f} && _ignored( \@ig, $f ) && !$force ) {
                    return ( "The following paths are ignored by one of your .gitignore files:\n$f\nhint: Use -f if you really want to add them.", 0 ) if $pat eq $f;
                    next;
                }
                $idx->{$f} = $w->{$f};
            }
            elsif ( exists $idx->{$f} ) { delete $idx->{$f} }
        }
    }
    $r->{index} = $idx;
    return ( '', 1 );
}

sub _g_rm {
    my ( $dev, $root, $r, $a ) = @_;
    my $cached = grep { $_ eq '--cached' } @$a;
    my $rec = grep { /\A-r|\A-rf\z|\A-fr\z/ } @$a;
    my $idx = _index($r);
    my @p = grep { !/\A-/ } @$a;
    my @out;
    for my $pat ( _paths( $root, $CWD, @p ) ) {
        my @hit = grep { exists $idx->{$_} } _match_paths( $idx, $pat // "\0" );
        return ( "fatal: pathspec '" . ( $pat // '' ) . "' did not match any files", 0 ) unless @hit;
        return ( "fatal: not removing '$pat' recursively without -r", 0 ) if !$rec && ( @hit > 1 || $hit[0] ne $pat ) && !_glob_match( $pat, $hit[0] );
        for my $f (@hit) {
            delete $idx->{$f};
            delete $dev->{files}{"$root/$f"} unless $cached;
            push @out, "rm '$f'";
        }
    }
    $r->{index} = $idx;
    return ( join( "\n", @out ), 1 );
}

sub _g_mv {
    my ( $dev, $root, $r, $a ) = @_;
    my @p = grep { !/\A-/ } @$a;
    return ( 'usage: git mv [<options>] <source>... <destination>', 0 ) unless @p == 2;
    my ( $from, $to ) = _paths( $root, $CWD, @p );
    my $idx = _index($r);
    my @hit = grep { exists $idx->{$_} } _match_paths( $idx, $from // "\0" );
    return ( "fatal: not under version control, source=$p[0], destination=$p[1]", 0 ) unless @hit;
    for my $f (@hit) {
        ( my $n = $f ) =~ s/\A\Q$from\E/$to/;
        $n = "$to/" . ( $f =~ s{.*/}{}r ) if @hit == 1 && $f eq $from && exists( { map { ( $_ =~ s{/[^/]+\z}{}r ) => 1 } keys %$idx }->{$to} );
        $idx->{$n} = delete $idx->{$f};
        my $e = delete $dev->{files}{"$root/$f"};
        $dev->{files}{"$root/$n"} = $e // $idx->{$n};
    }
    $r->{index} = $idx;
    return ( '', 1 );
}

sub _g_restore {
    my ( $dev, $root, $r, $a ) = @_;
    my $staged = grep { $_ eq '--staged' || $_ eq '-S' } @$a;
    my $idx = _index($r);
    my $head = _tree( $r, _head($r) );
    for my $pat ( _paths( $root, $CWD, grep { !/\A-/ } @$a ) ) {
        my @hit = _match_paths( { %$idx, %$head }, $pat // "\0" );
        return ( "error: pathspec '" . ( $pat // '' ) . "' did not match any file(s) known to git", 0 ) unless @hit;
        for my $f (@hit) {
            if ($staged) { if ( exists $head->{$f} ) { $idx->{$f} = $head->{$f} } else { delete $idx->{$f} } }
            elsif ( exists $idx->{$f} ) { $dev->{files}{"$root/$f"} = $idx->{$f} }
        }
    }
    $r->{index} = $idx;
    return ( '', 1 );
}

sub _g_commit {
    my ( $dev, $root, $r, $a ) = @_;
    my ( @msg, $amend, $noedit, $all, $reset, $author, $empty );
    my @x = @$a;
    while (@x) {
        my $o = shift @x;
        if    ( $o eq '-m' || $o eq '--message' ) { push @msg, shift(@x) // '' }
        elsif ( $o =~ /\A(?:-m|--message=)(.+)\z/s ) { push @msg, $1 }
        elsif ( $o =~ /\A-([a]*)m\z/ ) { $all = 1 if $1; push @msg, shift(@x) // '' }
        elsif ( $o eq '-a' || $o eq '--all' ) { $all = 1 }
        elsif ( $o eq '--amend' ) { $amend = 1 }
        elsif ( $o eq '--no-edit' ) { $noedit = 1 }
        elsif ( $o eq '--reset-author' ) { $reset = 1 }
        elsif ( $o =~ /\A--author=(.+)\z/ ) { $author = $1 }
        elsif ( $o eq '--author' ) { $author = shift @x }
        elsif ( $o eq '--allow-empty' ) { $empty = 1 }
        elsif ( $o eq '--no-verify' || $o eq '-n' || $o eq '-q' || $o eq '--quiet' || $o eq '-s' || $o eq '--signoff' ) { }
        elsif ( $o eq '-F' || $o eq '--file' ) { my $f = shift(@x) // ''; my $t = ( $dev->{files} || {} )->{ $f =~ m{\A/} ? $f : "$root/$f" }; return ( "fatal: could not read log file '$f': No such file or directory", 0 ) unless defined $t; push @msg, _text($t) =~ s/\n+\z//r }
        else { return ( "error: unknown option `" . ( $o =~ s/\A-+//r ) . "'", 0 ) }
    }
    if ($all) {
        my $w = _work( $dev, $root );
        my $idx = _index($r);
        for my $f ( keys %$idx ) { if ( exists $w->{$f} ) { $idx->{$f} = $w->{$f} } else { delete $idx->{$f} } }
        $r->{index} = $idx;
    }
    my $head = _head($r);
    my $hc = defined $head ? $r->{commits}{$head} : undef;
    if ( !@msg && !( $amend && $noedit ) ) { push @GAPS, 'git commit (Editor)'; return ( 'error: There was a problem with the editor \'editor\'.', 0 ) }
    my $idx = _index($r);
    my $parent_tree = $amend ? _tree( $r, ( $hc->{parents} || [] )->[0] ) : _tree( $r, $head );
    if ( !$amend && !$empty && $J->encode($idx) eq $J->encode( _tree( $r, $head ) ) ) {
        my ( undef, $un, $ut ) = _changes( $dev, $root, $r );
        return ( join( "\n", "On branch " . ( $r->{branch} // 'HEAD' ), @$un ? 'no changes added to commit (use "git add" and/or "git commit -a")' : @$ut ? 'nothing added to commit but untracked files present (use "git add" to track)' : 'nothing to commit, working tree clean' ), 0 );
    }
    return ( 'fatal: You have nothing to amend.', 0 ) if $amend && !$hc;
    my $msg = @msg ? join( "\n\n", @msg ) : $hc->{message};
    my $who = $author // ( $amend && !$reset ? $hc->{author} : _who( $dev, $r ) );
    $who = "$who <$who>" unless $who =~ /<.*>/;
    my $id = _mk_commit( $dev, $r, parents => $amend ? [ @{ $hc->{parents} || [] } ] : [ grep {defined} $head ], message => $msg, author => $who, tree => _clone($idx),
        ( $amend && !$reset ? ( date => $hc->{date} ) : () ) );
    if ( defined $r->{branch} ) { $r->{refs}{heads}{ $r->{branch} } = $id } else { $r->{detached} = $id }
    delete $r->{index};
    my $d = _diff_trees( $parent_tree, $idx, 'name-only' );
    my $n = () = split /\n/, $d;
    return ( '[' . ( $r->{branch} // 'detached HEAD' ) . ( defined $head || $amend ? '' : ' (root-commit)' ) . ' ' . _short($id) . '] ' . _subject($msg)
        . ( $amend ? "\n Date: " . _date_text( $r->{commits}{$id}{date} ) : '' ) . "\n $n file" . ( $n == 1 ? '' : 's' ) . ' changed', 1 );
}

# Verweise auf einen Commit wie --decorate: (HEAD -> main, origin/main, tag: v1)
sub _deco {
    my ( $r, $id ) = @_;
    my @d;
    my $h = _head($r);
    if ( defined $h && $h eq $id ) { push @d, defined $r->{branch} ? "HEAD -> $r->{branch}" : 'HEAD' }
    push @d, grep { ( $r->{refs}{heads}{$_} // '' ) eq $id && $_ ne ( defined $h && $h eq $id ? $r->{branch} // '' : "\0" ) } sort keys %{ $r->{refs}{heads} || {} };
    push @d, grep { ( $r->{refs}{remotes}{$_} // '' ) eq $id } sort keys %{ $r->{refs}{remotes} || {} };
    push @d, map {"tag: $_"} grep { ( $r->{refs}{tags}{$_}{commit} // '' ) eq $id } sort keys %{ $r->{refs}{tags} || {} };
    return @d ? ' (' . join( ', ', @d ) . ')' : '';
}

sub _ago { my ($t) = @_; my $h = int( ( 1792832400 + 3600 - $t ) / 3600 ); return $h < 1 ? 'vor wenigen Minuten' =~ s/.*/minutes ago/r : $h < 48 ? "$h hours ago" : int( $h / 24 ) . ' days ago' }

sub _fmt_commit {
    my ( $r, $id, $fmt ) = @_;
    my $c = $r->{commits}{$id};
    my ( $an, $ae ) = $c->{author} =~ /\A(.*?)\s*<(.*)>\z/;
    my %ph = ( H => $id, h => _short($id), s => _subject( $c->{message} ), an => $an // '', ae => $ae // '', ad => _date_text( $c->{date} ),
        b => ( $c->{message} =~ /\A[^\n]*\n\n(.*)\z/s ? "$1\n" : '' ), B => "$c->{message}\n", P => join( ' ', @{ $c->{parents} || [] } ),
        p => join( ' ', map { _short($_) } @{ $c->{parents} || [] } ), cn => $an // '', ce => $ae // '', cd => _date_text( $c->{date} ), n => "\n",
        ar => _ago( $c->{date} ), cr => _ago( $c->{date} ), d => _deco( $r, $id ), D => _deco( $r, $id ) =~ s/\A \((.*)\)\z/$1/r,
        aI => _iso( $c->{date} ), cI => _iso( $c->{date} ), ai => _iso( $c->{date} ), ci => _iso( $c->{date} ), T => '', t => '', '%' => '%' );
    ( my $o = $fmt ) =~ s/%(an|ae|ad|ar|aI|ai|cn|ce|cd|cr|cI|ci|[HhsbBPpndDTt%])/$ph{$1}/g;
    return $o;
}

sub _iso { my ($t) = @_; my @g = gmtime( $t + 7200 ); return sprintf '%04d-%02d-%02dT%02d:%02d:%02d+02:00', $g[5] + 1900, $g[4] + 1, @g[ 3, 2, 1, 0 ] }

sub _log_text {
    my ( $r, $ids, %o ) = @_;
    my @out;
    for my $id (@$ids) {
        my $c = $r->{commits}{$id};
        my $deco = $o{decorate} ? _deco( $r, $id ) : '';
        if ( defined $o{format} ) { push @out, _fmt_commit( $r, $id, $o{format} ); next }
        if ( $o{oneline} ) { push @out, _short($id) . $deco . ' ' . _subject( $c->{message} ); next }
        my @l = ( "commit $id$deco", ( @{ $c->{parents} || [] } > 1 ? 'Merge: ' . join( ' ', map { _short($_) } @{ $c->{parents} } ) : () ), "Author: $c->{author}", 'Date:   ' . _date_text( $c->{date} ), '',
            map( {"    $_"} split /\n/, $c->{message} ) );
        push @l, '', _diff_trees( _tree( $r, ( $c->{parents} || [] )->[0] ), $c->{tree}, 'stat' ) if $o{stat};
        push @l, '', _diff_trees( _tree( $r, ( $c->{parents} || [] )->[0] ), $c->{tree}, 'name-only' ) if $o{names};
        push @l, '', _diff_trees( _tree( $r, ( $c->{parents} || [] )->[0] ), $c->{tree} ) if $o{patch};
        push @out, join( "\n", @l ) . "\n";
    }
    return join( "\n", @out ) =~ s/\n+\z//r;
}

sub _g_log {
    my ( $dev, $root, $r, $a ) = @_;
    my ( %o, @revs, @paths );
    my @x = @$a;
    while (@x) {
        my $v = shift @x;
        if    ( $v eq '--oneline' ) { $o{oneline} = 1 }
        elsif ( $v =~ /\A-(\d+)\z/ ) { $o{n} = $1 }
        elsif ( $v eq '-n' || $v eq '--max-count' ) { $o{n} = shift @x }
        elsif ( $v =~ /\A(?:-n|--max-count=)(\d+)\z/ ) { $o{n} = $1 }
        elsif ( $v =~ /\A--(?:format|pretty)=(?:format:|tformat:)?(.*)\z/s ) { my $f = $1; $o{format} = $f eq 'oneline' ? undef : $f; $o{oneline} = 1 if $f eq 'oneline'; $o{format} = '%H%nAuthor: %an <%ae>%n%n    %s' if $f =~ /\A(?:full|fuller|medium)\z/ }
        elsif ( $v eq '--stat' ) { $o{stat} = 1 }
        elsif ( $v eq '--name-only' || $v eq '--name-status' ) { $o{names} = 1 }
        elsif ( $v eq '-p' || $v eq '--patch' ) { $o{patch} = 1 }
        elsif ( $v eq '--all' ) { $o{all} = 1 }
        elsif ( $v eq '--' ) { @paths = @x; last }
        elsif ( $v =~ /\A--decorate(?:=\w+)?\z/ ) { $o{decorate} = 1 }
        elsif ( $v =~ /\A--(?:graph|no-decorate|abbrev-commit|no-merges|first-parent|reverse|color|no-color|date=\S+)\z/ ) { $o{reverse} = 1 if $v eq '--reverse' }
        elsif ( $v =~ /\A-/ ) { return ( "fatal: unrecognized argument: $v", 0 ) }
        else { push @revs, $v }
    }
    my @ids;
    if ( $o{all} ) {
        my %s;
        my @tips = ( values %{ $r->{refs}{heads} || {} }, values %{ $r->{refs}{remotes} || {} }, map { $_->{commit} } values %{ $r->{refs}{tags} || {} } );
        @ids = grep { !$s{$_}++ } map { _range( $r, undef, $_ ) } @tips;
        @ids = _newest_first( $r, @ids );
    }
    else {
        my ( $from, $to );
        if ( @revs && $revs[0] =~ /\A(.*?)\.\.(.*)\z/ ) {
            ( $from, $to ) = ( $1, $2 );
            $from = _rev( $r, length $from ? $from : 'HEAD' ) // return ( "fatal: ambiguous argument '$revs[0]': unknown revision or path not in the working tree.", 0 );
            $to = _rev( $r, length $to ? $to : 'HEAD' ) // return ( "fatal: ambiguous argument '$revs[0]': unknown revision or path not in the working tree.", 0 );
        }
        else {
            $to = _rev( $r, $revs[0] // 'HEAD' );
            return ( "fatal: your current branch '" . ( $r->{branch} // '' ) . "' does not have any commits yet", 0 ) if !defined $to && !@revs;
            return ( "fatal: ambiguous argument '$revs[0]': unknown revision or path not in the working tree.", 0 ) unless defined $to;
        }
        @ids = reverse _range( $r, $from, $to );
    }
    if (@paths) {
        my @rel = _paths( $root, $CWD, @paths );
        @ids = grep { my $c = $r->{commits}{$_}; my $p = _tree( $r, ( $c->{parents} || [] )->[0] ); my $t = $c->{tree};
            grep { my $q = $_; grep { ( $p->{$_} // "\0" ) ne ( $t->{$_} // "\0" ) } _match_paths( { %$p, %$t }, $q // "\0" ) } @rel } @ids;
    }
    @ids = @ids[ 0 .. $o{n} - 1 ] if defined $o{n} && $o{n} =~ /\A\d+\z/ && @ids > $o{n};
    @ids = reverse @ids if $o{reverse};
    return ( _log_text( $r, \@ids, %o ), 1 );
}

sub _g_show {
    my ( $dev, $root, $r, $a ) = @_;
    my @revs = grep { !/\A-/ } @$a;
    my %o = ( patch => 1 );
    for (@$a) { if ( $_ eq '--stat' ) { %o = ( stat => 1 ) } elsif ( $_ eq '--name-only' ) { %o = ( names => 1 ) } elsif (/\A--(?:format|pretty)=(?:format:)?(.*)\z/) { $o{format} = $1; delete $o{patch} } elsif ( $_ eq '--oneline' ) { $o{oneline} = 1 } }
    my @out;
    for my $spec ( @revs ? @revs : ('HEAD') ) {
        if ( $spec =~ /\A(.*?):(.+)\z/ ) {    # rev:pfad
            my $id = _rev( $r, $1 ) // return ( "fatal: invalid object name '$1'.", 0 );
            my $t = _tree( $r, $id );
            return ( "fatal: path '$2' does not exist in '$1'", 0 ) unless exists $t->{$2};
            push @out, $t->{$2} =~ s/\n\z//r;
            next;
        }
        my $tag = ( $r->{refs}{tags} || {} )->{$spec};
        my $id = _rev( $r, $spec ) // return ( "fatal: ambiguous argument '$spec': unknown revision or path not in the working tree.", 0 );
        push @out, "tag $spec\nTagger: " . ( $tag->{tagger} // '' ) . "\n\n" . ( $tag->{message} // '' ) . "\n" if $tag && $tag->{annotated};
        push @out, _log_text( $r, [$id], %o );
    }
    return ( join( "\n", @out ), 1 );
}

sub _g_diff {
    my ( $dev, $root, $r, $a ) = @_;
    my $cached = grep { /\A--(?:cached|staged)\z/ } @$a;
    my ($mode) = map { /\A--(stat|name-only)\z/ ? $1 : () } @$a;
    my @revs = grep { !/\A-/ } @$a;
    my ( $x, $y );
    if ( @revs && $revs[0] =~ /\A(.+?)\.\.\.?(.+)\z/ ) { $x = _tree( $r, _rev( $r, $1 ) ); $y = _tree( $r, _rev( $r, $2 ) ) }
    elsif ( @revs >= 2 && defined _rev( $r, $revs[0] ) && defined _rev( $r, $revs[1] ) ) { $x = _tree( $r, _rev( $r, $revs[0] ) ); $y = _tree( $r, _rev( $r, $revs[1] ) ) }
    elsif ( @revs && defined _rev( $r, $revs[0] ) ) { $x = _tree( $r, _rev( $r, $revs[0] ) ); $y = $cached ? _index($r) : _work_tracked( $dev, $root, $r ) }
    elsif ($cached) { $x = _tree( $r, _head($r) ); $y = _index($r) }
    else { $x = _index($r); $y = _work_tracked( $dev, $root, $r ) }
    return ( _diff_trees( $x, $y, $mode ), 1 );
}

sub _work_tracked {
    my ( $dev, $root, $r ) = @_;
    my $w = _work( $dev, $root );
    my $idx = _index($r);
    return { map { exists $w->{$_} ? ( $_ => $w->{$_} ) : () } keys %$idx };
}

sub _g_ls_files {
    my ( $dev, $root, $r, $a ) = @_;
    return ( join( "\n", sort keys %{ _index($r) } ), 1 );
}

sub _g_branch {
    my ( $dev, $root, $r, $a ) = @_;
    my @p = grep { !/\A-/ } @$a;
    if ( @p && !grep { /\A-[dDm]/ } @$a ) {
        my $id = _rev( $r, $p[1] // 'HEAD' ) // return ( "fatal: not a valid object name: '$p[1]'", 0 );
        my $force = grep { $_ eq '-f' || $_ eq '--force' } @$a;
        return ( "fatal: a branch named '$p[0]' already exists", 0 ) if exists $r->{refs}{heads}{ $p[0] } && !$force;
        return ( "fatal: cannot force update the branch '$p[0]' used by worktree at '$root'", 0 ) if $force && ( $r->{branch} // '' ) eq $p[0];
        $r->{refs}{heads}{ $p[0] } = $id;
        return ( '', 1 );
    }
    if ( grep { /\A-[dD]\z/ } @$a ) {
        my $n = $p[0] // '';
        return ( "error: branch '$n' not found.", 0 ) unless exists $r->{refs}{heads}{$n};
        return ( "error: Cannot delete branch '$n' checked out at '$root'", 0 ) if ( $r->{branch} // '' ) eq $n;
        my $id = delete $r->{refs}{heads}{$n};
        return ( "Deleted branch $n (was " . _short($id) . ').', 1 );
    }
    my $v  = grep { /\A-vv?\z/ || $_ eq '--verbose' } @$a;
    my $vv = grep { $_ eq '-vv' } @$a;
    my $w = 0;
    for ( keys %{ $r->{refs}{heads} || {} } ) { $w = length if length > $w }
    my @l = map {
        my $b   = $_;
        my $cur = ( $r->{branch} // '' ) eq $b;
        my $id  = $r->{refs}{heads}{$b};
        my $up  = '';
        if ( $vv && exists( ( $r->{refs}{remotes} || {} )->{"origin/$b"} ) ) {
            my $u = $r->{refs}{remotes}{"origin/$b"};
            my $ah = () = _range( $r, $u, $id );
            my $be = () = _range( $r, $id, $u );
            $up = " [origin/$b" . ( $ah && $be ? ": ahead $ah, behind $be" : $ah ? ": ahead $ah" : $be ? ": behind $be" : '' ) . ']';
        }
        ( $cur ? '* ' : '  ' ) . ( $v ? sprintf( "%-${w}s %s%s %s", $b, _short($id), $up, _subject( $r->{commits}{$id}{message} ) ) : $b );
    } sort keys %{ $r->{refs}{heads} || {} };
    unshift @l, '* (HEAD detached at ' . _short( $r->{detached} ) . ')' unless defined $r->{branch};
    push @l, map {"  remotes/$_"} sort keys %{ $r->{refs}{remotes} || {} } if grep { /\A-(?:a|r|-all|-remotes)\z/ } @$a;
    return ( join( "\n", @l ), 1 );
}

# HEAD auf einen anderen Commit setzen und Index/Arbeitsbaum nachziehen (nur verfolgte Dateien)
sub _move_head {
    my ( $dev, $root, $r, $id, $mode ) = @_;
    my $old = _tree( $r, _head($r) );
    $r->{index} = _index($r) if $mode eq 'soft';    # der Index bleibt, wie er war
    if ( defined $r->{branch} ) { $r->{refs}{heads}{ $r->{branch} } = $id } else { $r->{detached} = $id }
    return if $mode eq 'soft';
    my $new = _tree( $r, $id );
    delete $r->{index};
    if ( $mode eq 'hard' ) {
        my $w = _work( $dev, $root );
        my %tracked = map { $_ => 1 } keys %$old;
        _set_work( $dev, $root, { map { $_ => 1 } grep { $tracked{$_} } keys %$w }, _clone($new) );
    }
    return;
}

sub _dirty {
    my ( $dev, $root, $r ) = @_;
    my ( $st, $un ) = _changes( $dev, $root, $r );
    return @$st || @$un;
}

sub _g_checkout {
    my ( $dev, $root, $r, $a ) = @_;
    my @x = @$a;
    if ( my ($i) = grep { $x[$_] eq '--' } 0 .. $#x ) { return _g_restore( $dev, $root, $r, [ @x[ $i + 1 .. $#x ] ] ) }
    my $create = grep { $_ eq '-b' || $_ eq '-c' || $_ eq '-B' } @x;
    my @p = grep { !/\A-/ } @x;
    my $name = $p[0] // return ( 'error: switch `b\' requires a value', 0 );
    if ($create) {
        return ( "fatal: a branch named '$name' already exists", 0 ) if exists $r->{refs}{heads}{$name};
        my $id = _rev( $r, $p[1] // 'HEAD' ) // return ( "fatal: '$p[1]' is not a commit and a branch '$name' cannot be created from it", 0 );
        my $dirty = _dirty( $dev, $root, $r );
        $r->{refs}{heads}{$name} = $id;
        my $old = _head($r);
        $r->{branch} = $name;
        delete $r->{detached};
        if ( $id ne ( $old // '' ) ) { return ( "error: Your local changes would be overwritten by checkout.", 0 ) if $dirty; _switch_tree( $dev, $root, $r, $old, $id ) }
        return ( "Switched to a new branch '$name'", 1 );
    }
    if ( !exists $r->{refs}{heads}{$name} && exists( ( $r->{refs}{remotes} || {} )->{"origin/$name"} ) ) {
        my $old = _head($r);
        return ( "error: Your local changes to the following files would be overwritten by checkout.\nAborting", 0 ) if _dirty( $dev, $root, $r );
        $r->{refs}{heads}{$name} = $r->{refs}{remotes}{"origin/$name"};
        $r->{branch} = $name;
        _switch_tree( $dev, $root, $r, $old, $r->{refs}{heads}{$name} );
        return ( "branch '$name' set up to track 'origin/$name'.\nSwitched to a new branch '$name'", 1 );
    }
    if ( exists $r->{refs}{heads}{$name} ) {
        return ( "Already on '$name'", 1 ) if ( $r->{branch} // '' ) eq $name;
        my $old = _head($r);
        return ( "error: Your local changes to the following files would be overwritten by checkout.\nPlease commit your changes or stash them before you switch branches.\nAborting", 0 )
            if _dirty( $dev, $root, $r ) && ( $old // '' ) ne $r->{refs}{heads}{$name};
        $r->{branch} = $name;
        delete $r->{detached};
        _switch_tree( $dev, $root, $r, $old, $r->{refs}{heads}{$name} );
        return ( "Switched to branch '$name'", 1 );
    }
    my $id = _rev( $r, $name );
    if ( defined $id ) {
        return ( "error: Your local changes would be overwritten by checkout.\nAborting", 0 ) if _dirty( $dev, $root, $r );
        my $old = _head($r);
        delete $r->{branch};
        $r->{detached} = $id;
        _switch_tree( $dev, $root, $r, $old, $id );
        return ( "Note: switching to '$name'.\n\nYou are in 'detached HEAD' state.\nHEAD is now at " . _short($id) . ' ' . _subject( $r->{commits}{$id}{message} ), 1 );
    }
    return _g_restore( $dev, $root, $r, \@p ) if grep { exists _work( $dev, $root )->{$_} } _paths( $root, $CWD, @p );
    return ( "error: pathspec '$name' did not match any file(s) known to git", 0 );
}

sub _g_switch {
    my ( $dev, $root, $r, $a ) = @_;
    return _g_checkout( $dev, $root, $r, [ map { $_ eq '-c' || $_ eq '--create' ? '-b' : $_ } grep { $_ ne '--detach' } @$a ] );
}

sub _switch_tree {
    my ( $dev, $root, $r, $old, $new ) = @_;
    my $ot = _tree( $r, $old );
    my $nt = _tree( $r, $new );
    delete $r->{index};
    my $w = _work( $dev, $root );
    _set_work( $dev, $root, { map { $_ => 1 } grep { exists $ot->{$_} } keys %$w }, _clone($nt) );
    return;
}

sub _g_reset {
    my ( $dev, $root, $r, $a ) = @_;
    my ($mode) = map { /\A--(soft|mixed|hard)\z/ ? $1 : () } @$a;
    my @p = grep { !/\A-/ } @$a;
    if ( !$mode && @p && !defined _rev( $r, $p[0] ) ) {    # reset pfad: aus dem Index nehmen
        return _g_restore( $dev, $root, $r, [ '--staged', @p ] );
    }
    $mode //= 'mixed';
    my $id = _rev( $r, $p[0] // 'HEAD' ) // return ( "fatal: ambiguous argument '$p[0]': unknown revision or path not in the working tree.", 0 );
    _move_head( $dev, $root, $r, $id, $mode );
    return ( $mode eq 'hard' ? 'HEAD is now at ' . _short($id) . ' ' . _subject( $r->{commits}{$id}{message} ) : '', 1 );
}

sub _g_tag {
    my ( $dev, $root, $r, $a ) = @_;
    my ( $ann, $msg, $del, $list, $force );
    my @p;
    my @x = @$a;
    while (@x) {
        my $o = shift @x;
        if    ( $o eq '-a' || $o eq '--annotate' ) { $ann = 1 }
        elsif ( $o eq '-s' ) { $ann = 1 }
        elsif ( $o eq '-m' ) { $msg = shift @x; $ann = 1 }
        elsif ( $o =~ /\A-m(.+)\z/s ) { $msg = $1; $ann = 1 }
        elsif ( $o eq '-am' ) { $msg = shift @x; $ann = 1 }
        elsif ( $o eq '-d' || $o eq '--delete' ) { $del = 1 }
        elsif ( $o eq '-l' || $o eq '--list' ) { $list = 1 }
        elsif ( $o eq '-f' || $o eq '--force' ) { $force = 1 }
        elsif ( $o =~ /\A-n\d*\z/ ) { $list = 1 }
        elsif ( $o =~ /\A-/ ) { return ( "error: unknown option `" . ( $o =~ s/\A-+//r ) . "'", 0 ) }
        else { push @p, $o }
    }
    my $t = $r->{refs}{tags} ||= {};
    if ( $del ) {
        my @out;
        for my $n (@p) { return ( "error: tag '$n' not found.", 0 ) unless $t->{$n}; push @out, "Deleted tag '$n' (was " . _short( $t->{$n}{commit} ) . ')'; delete $t->{$n} }
        return ( join( "\n", @out ), 1 );
    }
    if ( $list || !@p ) { return ( join( "\n", grep { !@p || _glob_match( $p[0], $_ ) || $_ eq $p[0] } sort keys %$t ), 1 ) }
    my ( $n, $rev ) = @p;
    return ( "fatal: tag '$n' already exists", 0 ) if $t->{$n} && !$force;
    my $id = _rev( $r, $rev // 'HEAD' ) // return ( "fatal: Failed to resolve '$rev' as a valid ref.", 0 );
    if ( $ann && !defined $msg ) { push @GAPS, 'git tag -a (Editor)'; return ( "error: There was a problem with the editor 'editor'.", 0 ) }
    $t->{$n} = { commit => $id, ( $ann ? ( annotated => JSON::MaybeXS::true(), message => $msg, tagger => _who( $dev, $r ) ) : () ) };
    return ( '', 1 );
}

# --- Server -----------------------------------------------------------------------------

sub _server {
    my ( $ctx, $r, $remote ) = @_;
    my $rm = ( $r->{remotes} || {} )->{ $remote // 'origin' } or return ( undef, "fatal: '" . ( $remote // 'origin' ) . "' does not appear to be a git repository\nfatal: Could not read from remote repository.\n\nPlease make sure you have the correct access rights\nand the repository exists." );
    my $srv = ( $ctx->{state} || {} )->{ $rm->{host} // '' };
    my ($h) = ( $rm->{url} // '' ) =~ m{\A(?:https?://|ssh://)?(?:[^@/]+@)?([^:/]+)};
    $srv //= _by_hosts_file( $ctx, $h );
    return ( undef, "ssh: Could not resolve hostname " . ( $h // '' ) . ": Name or service not known\nfatal: Could not read from remote repository." ) unless $srv;
    return ( undef, "ssh: connect to host $h port 22: Connection refused\nfatal: Could not read from remote repository." )
        if ( $srv->{services} || {} )->{ $rm->{service} // 'forgejo' } && !$srv->{services}{ $rm->{service} // 'forgejo' }{active};
    my $repo = ( ( $srv->{forgejo} || {} )->{repos} || {} )->{ $rm->{repo} // '' } or return ( undef, "fatal: Could not read from remote repository.\n\nPlease make sure you have the correct access rights\nand the repository exists." );
    return ( $repo, undef, $rm, $srv );
}

# Name ueber /etc/hosts des aufrufenden Geraets -> Geraet mit dieser Adresse
sub _by_hosts_file {
    my ( $ctx, $name ) = @_;
    return undef unless defined $name;
    my $st = $ctx->{state} || {};
    my $me = $st->{ $ctx->{host} // '' } or return undef;
    my $hf = ( $me->{files} || {} )->{'/etc/hosts'};
    $hf = $hf->{content} if ref $hf eq 'HASH';
    for my $l ( split /\n/, $hf // '' ) {
        my ( $ip, @names ) = split ' ', $l =~ s/#.*//r;
        next unless defined $ip && grep { $_ eq $name } @names;
        for my $d ( sort keys %$st ) {
            my $if = ( ref $st->{$d} eq 'HASH' ? $st->{$d}{interfaces} : undef ) || {};
            return $st->{$d} if grep { ( $_ =~ s{/\d+\z}{}r ) eq $ip } map { @{ $_->{addr} || [] } } values %$if;
        }
    }
    return undef;
}

# Commits des Servers in das lokale Repo uebernehmen
sub _import {
    my ( $r, $srepo, $ids ) = @_;
    for my $id (@$ids) { $r->{commits}{$id} //= _clone( $srepo->{commits}{$id} ) }
    return;
}

sub _g_fetch {
    my ( $dev, $root, $r, $a, $ctx ) = @_;
    my ($remote) = grep { !/\A-/ } @$a;
    my ( $s, $err, $rm ) = _server( $ctx, $r, $remote );
    return ( $err, 0 ) unless $s;
    my @out;
    for my $b ( sort keys %{ $s->{refs}{heads} || {} } ) {
        my $tip = $s->{refs}{heads}{$b};
        my $old = ( $r->{refs}{remotes} || {} )->{ ( $remote // 'origin' ) . "/$b" };
        next if defined $old && $old eq $tip;
        _import( $r, $s, [ _range( $s, undef, $tip ) ] );
        $r->{refs}{remotes}{ ( $remote // 'origin' ) . "/$b" } = $tip;
        push @out, defined $old ? sprintf( '   %s..%s  %-10s -> %s/%s', _short($old), _short($tip), $b, $remote // 'origin', $b ) : sprintf( ' * [new branch]      %-10s -> %s/%s', $b, $remote // 'origin', $b );
    }
    for my $tg ( sort keys %{ $s->{refs}{tags} || {} } ) {
        next if ( $r->{refs}{tags} || {} )->{$tg};
        _import( $r, $s, [ _range( $s, undef, $s->{refs}{tags}{$tg}{commit} ) ] );
        $r->{refs}{tags}{$tg} = _clone( $s->{refs}{tags}{$tg} );
        push @out, " * [new tag]         $tg -> $tg";
    }
    return ( @out ? join( "\n", "From $rm->{url}", @out ) : '', 1 );
}

# Commits $ids (aelteste zuerst) auf $onto neu aufsetzen; Konflikt -> undef
sub _replay {
    my ( $dev, $r, $ids, $onto ) = @_;
    my $tip = $onto;
    for my $id (@$ids) {
        my $c = $r->{commits}{$id};
        my $base = _tree( $r, ( $c->{parents} || [] )->[0] );
        my $tree = _clone( _tree( $r, $tip ) );
        for my $p ( keys %{ { %$base, %{ $c->{tree} } } } ) {
            my ( $b, $n, $t ) = ( $base->{$p}, $c->{tree}{$p}, $tree->{$p} );
            next if ( $b // "\0" ) eq ( $n // "\0" );
            return ( undef, $p ) if ( $t // "\0" ) ne ( $b // "\0" ) && ( $t // "\0" ) ne ( $n // "\0" );
            if ( defined $n ) { $tree->{$p} = $n } else { delete $tree->{$p} }
        }
        $tip = _mk_commit( $dev, $r, parents => [$tip], message => $c->{message}, author => $c->{author}, date => $c->{date} + 1, tree => $tree );
    }
    return ($tip);
}

sub _merge_trees {
    my ( $r, $base, $x, $y ) = @_;
    my ( $bt, $xt, $yt ) = map { _tree( $r, $_ ) } $base, $x, $y;
    my %t = %$xt;
    for my $p ( keys %{ { %$bt, %$xt, %$yt } } ) {
        my ( $b, $m, $o ) = ( $bt->{$p}, $xt->{$p}, $yt->{$p} );
        next if ( $o // "\0" ) eq ( $b // "\0" );
        next if ( $m // "\0" ) eq ( $o // "\0" );
        return ( undef, $p ) if ( $m // "\0" ) ne ( $b // "\0" );
        if ( defined $o ) { $t{$p} = $o } else { delete $t{$p} }
    }
    return ( \%t );
}

sub _base {
    my ( $r, $x, $y ) = @_;
    my $ax = _ancestors( $r, $x );
    my ($b) = grep { $ax->{$_} } map { $_ } reverse _range( $r, undef, $y );
    return $b;
}

sub _integrate {
    my ( $dev, $root, $r, $up, $how ) = @_;
    my $h = _head($r);
    my $name = $r->{branch} // 'HEAD';
    return ( 'Already up to date.', 1 ) if _ancestors( $r, $h )->{$up};
    return ( "error: cannot pull with rebase: You have unstaged changes.\nerror: please commit or stash them.", 0 ) if $how eq 'rebase' && _dirty( $dev, $root, $r );
    if ( !defined $h || _ancestors( $r, $up )->{$h} ) {
        return ( 'error: Your local changes to the following files would be overwritten by merge.', 0 ) if _dirty( $dev, $root, $r );
        _switch_tree( $dev, $root, $r, $h, $up );
        $r->{refs}{heads}{ $r->{branch} } = $up if defined $r->{branch};
        return ( 'Updating ' . _short($h) . '..' . _short($up) . "\nFast-forward", 1 );
    }
    return ( "hint: Diverging branches can't be fast-forwarded, you need to either:\nhint:\nhint: \tgit merge --no-ff\nhint:\nhint: or:\nhint:\nhint: \tgit rebase\nhint:\nhint: Disable this message with \"git config advice.diverging false\"\nfatal: Not possible to fast-forward, aborting.", 0 )
        if $how eq 'ff-only';
    my $base = _base( $r, $h, $up );
    if ( $how eq 'rebase' ) {
        my @mine = _range( $r, $base, $h );
        my ( $tip, $conf ) = _replay( $dev, $r, \@mine, $up );
        return ( "CONFLICT (content): Merge conflict in $conf\nerror: could not apply " . _short( $mine[0] ) . "...\nhint: Resolve all conflicts manually, mark them as resolved with\nhint: \"git add/rm <conflicted_files>\", then run \"git rebase --continue\".", 0 ) unless $tip;
        _switch_tree( $dev, $root, $r, $h, $tip );
        $r->{refs}{heads}{ $r->{branch} } = $tip if defined $r->{branch};
        $r->{detached} = $tip unless defined $r->{branch};
        return ( "Successfully rebased and updated refs/heads/$name.", 1 );
    }
    return ( "error: Your local changes to the following files would be overwritten by merge.", 0 ) if _dirty( $dev, $root, $r );
    my ( $tree, $conf ) = _merge_trees( $r, $base, $h, $up );
    return ( "Auto-merging $conf\nCONFLICT (content): Merge conflict in $conf\nAutomatic merge failed; fix conflicts and then commit the result.", 0 ) unless $tree;
    my $id = _mk_commit( $dev, $r, parents => [ $h, $up ], message => $how eq 'pull' ? "Merge branch '$name' of " . ( ( $r->{remotes}{origin} || {} )->{url} // 'origin' ) : "Merge remote-tracking branch '$how'", author => _who( $dev, $r ), tree => $tree );
    _switch_tree( $dev, $root, $r, $h, $id );
    $r->{refs}{heads}{ $r->{branch} } = $id if defined $r->{branch};
    return ( "Merge made by the 'ort' strategy.", 1 );
}

sub _g_pull {
    my ( $dev, $root, $r, $a, $ctx ) = @_;
    my $how = ( grep { $_ eq '--rebase' || $_ eq '-r' } @$a ) ? 'rebase' : ( grep { $_ eq '--ff-only' } @$a ) ? 'ff-only' : ( grep { $_ eq '--no-rebase' || $_ eq '--no-ff' } @$a ) ? 'pull' : undef;
    my %cfg = ( %{ ( $dev->{git} || {} )->{config} || {} }, %{ $r->{config} || {} } );
    $how //= ( $cfg{'pull.rebase'} // '' ) =~ /\A(?:true|merges)\z/ ? 'rebase' : ( $cfg{'pull.ff'} // '' ) eq 'only' ? 'ff-only' : ( $cfg{'pull.rebase'} // '' ) eq 'false' ? 'pull' : undef;
    my ( $fo, $fok ) = _g_fetch( $dev, $root, $r, [ grep { !/\A-/ } @$a ], $ctx );
    return ( $fo, 0 ) unless $fok;
    my $up = ( $r->{refs}{remotes} || {} )->{ 'origin/' . ( $r->{branch} // '' ) } // return ( "There is no tracking information for the current branch.", 0 );
    my $h = _head($r);
    if ( !defined $how ) {
        return ( join( "\n", grep {length} $fo, "hint: You have divergent branches and need to specify how to reconcile them.\nhint: You can do so by running one of the following commands sometime before\nhint: your next pull:\nhint:\nhint:   git config pull.rebase false  # merge\nhint:   git config pull.rebase true   # rebase\nhint:   git config pull.ff only       # fast-forward only\nhint:\nhint: You can replace \"git config\" with \"git config --global\" to set a default\nhint: preference for all repositories. You can also pass --rebase, --no-rebase,\nhint: or --ff-only on the command line to override the configured default per\nhint: invocation.\nfatal: Need to specify how to reconcile divergent branches." ), 0, 1 )
            if !_ancestors( $r, $up )->{$h} && !_ancestors( $r, $h )->{$up};
        $how = 'pull';
    }
    my ( $o, $ok ) = $how eq 'rebase' || grep( { $_ eq '--autostash' } @$a )
        ? _autostash( $dev, $root, $r, $a, sub { _integrate( $dev, $root, $r, $up, $how ) } )
        : _integrate( $dev, $root, $r, $up, $how );
    return ( join( "\n", grep {length} $fo, $o ), $ok, 1 );
}

sub _g_rebase {
    my ( $dev, $root, $r, $a ) = @_;
    if ( grep { /\A(?:-i|--interactive)\z/ } @$a ) { push @GAPS, 'git rebase -i'; return ( 'error: There was a problem with the editor \'editor\'.', 0 ) }
    return ( 'fatal: No rebase in progress?', 0 ) if grep { /\A--(?:abort|continue|skip)\z/ } @$a;
    my ($onto) = grep { !/\A-/ } @$a;
    $onto //= 'origin/' . ( $r->{branch} // '' );
    my $up = _rev( $r, $onto ) // return ( "fatal: invalid upstream '$onto'", 0 );
    return ( 'Current branch ' . ( $r->{branch} // 'HEAD' ) . ' is up to date.', 1 ) if _ancestors( $r, _head($r) )->{$up};
    return _autostash( $dev, $root, $r, $a, sub { _integrate( $dev, $root, $r, $up, 'rebase' ) } );
}

sub _g_merge {
    my ( $dev, $root, $r, $a ) = @_;
    my ($what) = grep { !/\A-/ } @$a;
    return ( 'fatal: No remote for the current branch.', 0 ) unless defined $what;
    my $up = _rev( $r, $what ) // return ( "merge: $what - not something we can merge", 0 );
    return _integrate( $dev, $root, $r, $up, ( grep { $_ eq '--ff-only' } @$a ) ? 'ff-only' : $what );
}

sub _g_cherry_pick {
    my ( $dev, $root, $r, $a ) = @_;
    my $x = grep { $_ eq '-x' } @$a;
    my $nocommit = grep { $_ eq '-n' || $_ eq '--no-commit' } @$a;
    return ( 'error: no cherry-pick or revert in progress', 0 ) if grep { /\A--(?:abort|continue|skip|quit)\z/ } @$a;
    if ( grep { $_ eq '-e' || $_ eq '--edit' } @$a ) { push @GAPS, 'git cherry-pick --edit'; return ( "error: There was a problem with the editor 'editor'.", 0 ) }
    my @specs = grep { !/\A-/ } @$a;
    return ( 'usage: git cherry-pick [--edit] [-n] [-m <parent-number>] [-s] [-x] [--ff] <commit>...', 0 ) unless @specs;
    return ( "error: your local changes would be overwritten by cherry-pick.\nhint: commit your changes or stash them to proceed.\nfatal: cherry-pick failed", 0 ) if _dirty( $dev, $root, $r ) && !$nocommit;
    my @ids;
    for my $sp (@specs) {
        if ( $sp =~ /\A(.+?)\.\.(.+)\z/ ) {
            my ( $f, $t ) = ( _rev( $r, $1 ), _rev( $r, $2 ) );
            return ( "fatal: bad revision '$sp'", 0 ) unless defined $f && defined $t;
            push @ids, _range( $r, $f, $t );
            next;
        }
        push @ids, _rev( $r, $sp ) // return ( "fatal: bad revision '$sp'", 0 );
    }
    my $h = _head($r);
    my $tip = $h;
    my @out;
    for my $id (@ids) {
        my $c = $r->{commits}{$id};
        return ( "error: commit $id is a merge but no -m option was given.\nfatal: cherry-pick failed", 0 ) if @{ $c->{parents} || [] } > 1;
        my $base = _tree( $r, ( $c->{parents} || [] )->[0] );
        my $tree = _clone( _tree( $r, $tip ) );
        for my $p ( keys %{ { %$base, %{ $c->{tree} } } } ) {
            my ( $b, $n ) = ( $base->{$p}, $c->{tree}{$p} );
            next if ( $b // "\0" ) eq ( $n // "\0" );
            return ( "error: could not apply " . _short($id) . '... ' . _subject( $c->{message} ) . "\nhint: After resolving the conflicts, mark them with\nhint: \"git add/rm <pathspec>\", then run\nhint: \"git cherry-pick --continue\".\nCONFLICT (content): Merge conflict in $p", 0 )
                if ( $tree->{$p} // "\0" ) ne ( $b // "\0" ) && ( $tree->{$p} // "\0" ) ne ( $n // "\0" );
            if ( defined $n ) { $tree->{$p} = $n } else { delete $tree->{$p} }
        }
        if ($nocommit) { $r->{index} = $tree; next }
        my $msg = $c->{message} . ( $x ? "\n\n(cherry picked from commit $id)" : '' );
        $tip = _mk_commit( $dev, $r, parents => [ grep {defined} $tip ], message => $msg, author => $c->{author}, tree => $tree );
        push @out, '[' . ( $r->{branch} // 'detached HEAD' ) . ' ' . _short($tip) . '] ' . _subject($msg);
    }
    if ($nocommit) { _set_work( $dev, $root, _work_tracked( $dev, $root, $r ), $r->{index} ); return ( '', 1 ) }
    _switch_tree( $dev, $root, $r, $h, $tip );
    if ( defined $r->{branch} ) { $r->{refs}{heads}{ $r->{branch} } = $tip } else { $r->{detached} = $tip }
    return ( join( "\n", @out ), 1 );
}

sub _g_revert {
    my ( $dev, $root, $r, $a ) = @_;
    my $noedit = grep { $_ eq '--no-edit' } @$a;
    my $nocommit = grep { $_ eq '-n' || $_ eq '--no-commit' } @$a;
    my @revs = grep { !/\A-/ } @$a;
    return ( 'usage: git revert [--[no-]edit] [-n] [-m <parent-number>] [-s] [-S[<keyid>]] <commit>...', 0 ) unless @revs;
    if ( !$noedit && !$nocommit ) { push @GAPS, 'git revert (Editor)'; return ( "error: There was a problem with the editor 'editor'.\nPlease supply the message using either -m or -F option.", 0 ) }
    return ( "error: your local changes would be overwritten by revert.\nhint: commit your changes or stash them to proceed.\nfatal: revert failed", 0 ) if _dirty( $dev, $root, $r ) && !$nocommit;
    my @out;
    for my $spec (@revs) {
        my $id = _rev( $r, $spec ) // return ( "fatal: bad revision '$spec'", 0 );
        my $c = $r->{commits}{$id};
        return ( "error: commit $id is a merge but no -m option was given.\nfatal: revert failed", 0 ) if @{ $c->{parents} || [] } > 1;
        my $base = _tree( $r, ( $c->{parents} || [] )->[0] );
        my $tree = _clone( $nocommit ? _index($r) : _tree( $r, _head($r) ) );
        for my $p ( keys %{ { %$base, %{ $c->{tree} } } } ) {
            my ( $old, $new ) = ( $base->{$p}, $c->{tree}{$p} );
            next if ( $old // "\0" ) eq ( $new // "\0" );
            return ( "error: could not revert " . _short($id) . '... ' . _subject( $c->{message} ) . "\nhint: after resolving the conflicts, mark the corrected paths\nhint: with 'git add <paths>' or 'git rm <paths>'\nCONFLICT (content): Merge conflict in $p", 0 )
                if ( $tree->{$p} // "\0" ) ne ( $new // "\0" );
            if ( defined $old ) { $tree->{$p} = $old } else { delete $tree->{$p} }
        }
        my $w = _work( $dev, $root );
        _set_work( $dev, $root, { map { $_ => 1 } grep { exists $base->{$_} || exists $c->{tree}{$_} } keys %$w }, { map { exists $tree->{$_} ? ( $_ => $tree->{$_} ) : () } keys %{ { %$base, %{ $c->{tree} } } } } );
        if ($nocommit) { $r->{index} = $tree; next }
        my $h = _head($r);
        my $nid = _mk_commit( $dev, $r, parents => [$h], message => 'Revert "' . _subject( $c->{message} ) . "\"\n\nThis reverts commit $id.", author => _who( $dev, $r ), tree => $tree );
        if ( defined $r->{branch} ) { $r->{refs}{heads}{ $r->{branch} } = $nid } else { $r->{detached} = $nid }
        delete $r->{index};
        push @out, '[' . ( $r->{branch} // 'detached HEAD' ) . ' ' . _short($nid) . '] Revert "' . _subject( $c->{message} ) . '"';
    }
    return ( join( "\n", @out ), 1 );
}

# stash: Eintraege (neuester zuerst) mit Basis-Commit, verfolgtem Arbeitsbaum und
# (mit -u) unverfolgten Dateien; der Index wird nicht eigens gesichert.
sub _stash_save {
    my ( $dev, $root, $r, $msg, $untracked, $only ) = @_;
    my $h = _head($r);
    my $base = _tree( $r, $h );
    my $w = _work( $dev, $root );
    my $idx = _index($r);
    # mit Pfaden (stash push -- PFAD): nur diese beiseite, alles andere bleibt, wie es ist
    my $sel = sub { my ($p) = @_; return 1 unless $only; return scalar grep { $_ eq '' || $p eq $_ || index( $p, "$_/" ) == 0 } @$only };
    my %track = map { $_ => 1 } grep { $sel->($_) } keys %{ { %$base, %$idx } };
    my %saved = map { exists $w->{$_} ? ( $_ => $w->{$_} ) : () } keys %track;
    $saved{$_} //= $idx->{$_} for grep { !exists $base->{$_} && $track{$_} } keys %$idx;    # neu im Index
    my @ig = _ignore_res($w);
    my %un = $untracked ? map { ( $_ => $w->{$_} ) } grep { !$track{$_} && $sel->($_) && !_ignored( \@ig, $_ ) } keys %$w : ();
    my $changed = grep { ( $saved{$_} // "\0" ) ne ( $base->{$_} // "\0" ) } keys %{ { %saved, %$base } };
    return undef unless $changed || %un;
    my $label = defined $msg ? 'On ' . ( $r->{branch} // '(no branch)' ) . ": $msg"
        : 'WIP on ' . ( $r->{branch} // '(no branch)' ) . ': ' . _short($h) . ' ' . _subject( ( $r->{commits}{$h} || {} )->{message} );
    $saved{$_} //= $base->{$_} for grep { !$track{$_} } keys %$base;    # nicht gewaehlt: unveraendert
    my $e = { base => $h, work => \%saved, untracked => \%un, message => $label };
    $e->{id} = Digest::SHA::sha1_hex( $J->encode($e) );
    unshift @{ $r->{stash} }, $e;
    _set_work( $dev, $root, { map { $_ => 1 } grep { $track{$_} || exists $un{$_} } keys %$w }, { map { exists $base->{$_} ? ( $_ => $base->{$_} ) : () } keys %track } );
    if ($only) {
        $idx->{$_} = $base->{$_} for grep { exists $base->{$_} } keys %track;
        delete $idx->{$_} for grep { !exists $base->{$_} } keys %track;
        $r->{index} = $idx;
        delete $r->{index} unless grep { ( $idx->{$_} // "\0" ) ne ( $base->{$_} // "\0" ) } keys %{ { %$idx, %$base } };
    }
    else { delete $r->{index} }
    return $e;
}

sub _stash_apply {
    my ( $dev, $root, $r, $e ) = @_;
    my $base = _tree( $r, $e->{base} );
    my $head = _tree( $r, _head($r) );
    my $w = _work( $dev, $root );
    my ( $st, $un ) = _changes( $dev, $root, $r );
    my %dirty = map { $_->[1] => 1 } @$st, @$un;
    my %new = %$w;
    for my $p ( sort keys %{ { %$base, %{ $e->{work} } } } ) {
        my ( $old, $mine ) = ( $base->{$p}, $e->{work}{$p} );
        next if ( $old // "\0" ) eq ( $mine // "\0" );
        return ( "error: Your local changes to the following files would be overwritten by merge:\n\t$p\nPlease commit your changes or stash them before you merge.\nAborting", 0 ) if $dirty{$p};
        my $cur = $head->{$p};
        if ( ( $cur // "\0" ) ne ( $old // "\0" ) && ( $cur // "\0" ) ne ( $mine // "\0" ) ) {
            return ( "Auto-merging $p\nCONFLICT (content): Merge conflict in $p\nThe stash entry is kept in case you need it again.", 0 );
        }
        if ( defined $mine ) { $new{$p} = $mine } else { delete $new{$p} }
    }
    for my $p ( keys %{ $e->{untracked} } ) {
        return ( "$p already exists, no checkout\nerror: could not restore untracked files from stash", 0 ) if exists $w->{$p};
        $new{$p} = $e->{untracked}{$p};
    }
    _set_work( $dev, $root, $w, \%new );
    my $idx = _index($r);
    $idx->{$_} = $e->{work}{$_} for grep { !exists $base->{$_} && defined $e->{work}{$_} } keys %{ $e->{work} };    # neue Dateien wieder im Index
    $r->{index} = $idx;
    delete $r->{index} unless grep { ( $idx->{$_} // "\0" ) ne ( $head->{$_} // "\0" ) } keys %{ { %$idx, %$head } };
    return ( '', 1 );
}

sub _stash_ref {
    my ( $r, $spec ) = @_;
    my $n = !defined $spec ? 0 : $spec =~ /\A(?:stash\@\{(\d+)\}|(\d+))\z/ ? $1 // $2 : return;
    return ( $n, ( $r->{stash} || [] )->[$n] );
}

sub _g_stash {
    my ( $dev, $root, $r, $a ) = @_;
    my @x = @$a;
    my $sub = @x && $x[0] !~ /\A-/ ? shift @x : 'push';
    my @p = grep { !/\A-/ } @x;
    if ( $sub eq 'push' || $sub eq 'save' ) {
        my $msg;
        for my $i ( 0 .. $#x ) { $msg = $x[ $i + 1 ] if $x[$i] eq '-m' || $x[$i] eq '--message' }
        $msg //= join ' ', @p if $sub eq 'save' && @p;
        my @spec = $sub eq 'push' ? grep { !defined $msg || $_ ne $msg } @p : ();
        my $only = @spec ? [ grep {defined} _paths( $root, $CWD, @spec ) ] : undef;
        my $u = grep { $_ eq '-u' || $_ eq '--include-untracked' || $_ eq '-a' || $_ eq '--all' } @x;
        my $e = _stash_save( $dev, $root, $r, $msg, $u, $only ) // return ( 'No local changes to save', 1 );
        return ( "Saved working directory and index state $e->{message}", 1 );
    }
    if ( $sub eq 'list' ) {
        my $l = $r->{stash} || [];
        return ( join( "\n", map {"stash\@{$_}: $l->[$_]{message}"} 0 .. $#$l ), 1 );
    }
    if ( $sub eq 'clear' ) { delete $r->{stash}; return ( '', 1 ) }
    my ( $n, $e ) = _stash_ref( $r, $p[0] );
    return ( defined $p[0] ? "error: $p[0] is not a valid reference" : 'No stash entries found.', 0 ) unless $e;
    if ( $sub eq 'show' ) {
        my $mode = ( grep { $_ eq '-p' || $_ eq '--patch' } @x ) ? undef : ( grep { $_ eq '--name-only' } @x ) ? 'name-only' : 'stat';
        my $base = _tree( $r, $e->{base} );
        return ( _diff_trees( $base, { %$base, %{ $e->{work} } }, $mode ), 1 );
    }
    if ( $sub eq 'apply' || $sub eq 'pop' ) {
        my ( $o, $ok ) = _stash_apply( $dev, $root, $r, $e );
        return ( $o, 0 ) unless $ok;
        splice @{ $r->{stash} }, $n, 1 if $sub eq 'pop';
        my ( $st, $un, $ut ) = _changes( $dev, $root, $r );
        return ( join( "\n", 'On branch ' . ( $r->{branch} // 'HEAD' ), 'Changes not staged for commit:', ( map {"\t$_->[0]:   $_->[1]"} @$un ),
            ( @$ut ? ( 'Untracked files:', map {"\t$_"} @$ut ) : () ),
            ( $sub eq 'pop' ? "Dropped refs/stash\@{$n} (" . $e->{id} . ')' : () ) ), 1 );
    }
    if ( $sub eq 'drop' ) { splice @{ $r->{stash} }, $n, 1; return ( "Dropped refs/stash\@{$n} ($e->{id})", 1 ) }
    push @GAPS, "git stash $sub";
    return ( '', 0 );
}

# --autostash (oder rebase.autoStash): vor dem Rebase beiseite, danach zurueck
sub _autostash {
    my ( $dev, $root, $r, $a, $run ) = @_;
    my %cfg = ( %{ ( $dev->{git} || {} )->{config} || {} }, %{ $r->{config} || {} } );
    my $on = ( grep { $_ eq '--autostash' } @$a ) ? 1 : ( grep { $_ eq '--no-autostash' } @$a ) ? 0 : ( $cfg{'rebase.autoStash'} // $cfg{'rebase.autostash'} // '' ) eq 'true';
    return $run->() unless $on && _dirty( $dev, $root, $r );
    my $e = _stash_save( $dev, $root, $r, undef, 0 );
    my ( $o, $ok, $keep ) = $run->();
    shift @{ $r->{stash} };
    my ( $ao, $aok ) = _stash_apply( $dev, $root, $r, $e );
    unshift @{ $r->{stash} }, $e unless $aok;
    return ( join( "\n", 'Created autostash: ' . _short( $e->{id} ), grep( {length} $o ),
        $aok ? 'Applied autostash.' : "Applying autostash resulted in conflicts.\nYour changes are safe in the stash.\nYou can run \"git stash pop\" or \"git stash drop\" at any time." ), $ok, $keep );
}

sub _g_rev_list {
    my ( $dev, $root, $r, $a ) = @_;
    my ( $count, $all, $n, @inc, @exc );
    my @x = @$a;
    while (@x) {
        my $v = shift @x;
        if    ( $v eq '--count' ) { $count = 1 }
        elsif ( $v eq '--all' ) { $all = 1 }
        elsif ( $v =~ /\A(?:-n|--max-count=?)(\d*)\z/ ) { $n = length $1 ? $1 : shift @x }
        elsif ( $v =~ /\A-(\d+)\z/ ) { $n = $1 }
        elsif ( $v =~ /\A--(?:no-merges|first-parent|reverse|abbrev-commit)\z/ ) { }
        elsif ( $v eq '--' ) { last }
        elsif ( $v =~ /\A-/ ) { return ( "fatal: unrecognized argument: $v", 0 ) }
        elsif ( $v =~ /\A(.*?)\.\.(.*)\z/ ) { push @exc, length $1 ? $1 : 'HEAD'; push @inc, length $2 ? $2 : 'HEAD' }
        elsif ( $v =~ /\A\^(.+)\z/ ) { push @exc, $1 }
        else { push @inc, $v }
    }
    my @tips = $all ? ( values %{ $r->{refs}{heads} || {} }, values %{ $r->{refs}{remotes} || {} }, map { $_->{commit} } values %{ $r->{refs}{tags} || {} } ) : ();
    for (@inc) { push @tips, _rev( $r, $_ ) // return ( "fatal: ambiguous argument '$_': unknown revision or path not in the working tree.", 0 ) }
    return ( "usage: git rev-list [<options>] <commit>... [--] [<path>...]", 0 ) unless @tips;
    my %ex;
    for (@exc) { my $id = _rev( $r, $_ ) // return ( "fatal: ambiguous argument '$_': unknown revision or path not in the working tree.", 0 ); %ex = ( %ex, %{ _ancestors( $r, $id ) } ) }
    my %s;
    my @ids = _newest_first( $r, grep { !$s{$_}++ && !$ex{$_} } map { _range( $r, undef, $_ ) } @tips );
    splice @ids, $n if defined $n && $n < @ids;
    return ( $count ? scalar(@ids) : join( "\n", @ids ), 1 );
}

# reflog: aus der Geschichte des Zweigs (der Simulator fuehrt kein eigenes Protokoll)
sub _g_reflog {
    my ( $dev, $root, $r, $a ) = @_;
    my @x = grep { $_ ne 'show' } @$a;
    my ($n) = map { /\A-n(\d+)\z|\A-(\d+)\z/ ? $1 // $2 : () } @x;
    my @ids = reverse _range( $r, undef, _head($r) );
    splice @ids, $n if defined $n && $n < @ids;
    my $i = 0;
    return ( join( "\n", map { my $c = $r->{commits}{$_}; _short($_) . ' HEAD@{' . $i++ . '}: ' . ( @{ $c->{parents} || [] } ? 'commit' : 'commit (initial)' ) . ': ' . _subject( $c->{message} ) } @ids ), 1 );
}

sub _g_merge_base {
    my ( $dev, $root, $r, $a ) = @_;
    my $anc = grep { $_ eq '--is-ancestor' } @$a;
    my @x = grep { !/\A-/ } @$a;
    return ( 'usage: git merge-base [-a | --all] <commit> <commit>...', 0 ) unless @x == 2;
    my @id = map { _rev( $r, $_ ) // return ( "fatal: Not a valid object name $_", 0 ) } @x;
    return ( '', _ancestors( $r, $id[1] )->{ $id[0] } ? 1 : 0 ) if $anc;
    my $b = _base( $r, @id ) // return ( '', 0 );
    return ( $b, 1 );
}

sub _g_fsck { return ( "Checking object directories: 100% (256/256), done.", 1 ) }

sub _g_describe {
    my ( $dev, $root, $r, $args ) = @_;
    my $all = grep { $_ eq '--tags' || $_ eq '--all' } @$args;
    my ($rev) = grep { !/\A-/ } @$args;
    my $id = _rev( $r, $rev // 'HEAD' ) // return ( "fatal: Not a valid object name " . ( $rev // 'HEAD' ), 0 );
    my %tag;
    for my $t ( keys %{ $r->{refs}{tags} || {} } ) { push @{ $tag{ $r->{refs}{tags}{$t}{commit} } }, $t if $all || $r->{refs}{tags}{$t}{annotated} }
    my @q = ( [ $id, 0 ] );
    my %seen;
    while (@q) {
        my ( $x, $d ) = @{ shift @q };
        next if $seen{$x}++;
        if ( $tag{$x} ) { my ($t) = sort @{ $tag{$x} }; return ( $d ? "$t-$d-g" . _short($id) : $t, 1 ) }
        push @q, map { [ $_, $d + 1 ] } @{ ( $r->{commits}{$x} || {} )->{parents} || [] };
    }
    return ( $all ? 'fatal: No names found, cannot describe anything.' : "fatal: No annotated tags can describe '$id'.\nHowever, there were unannotated tags: try --tags.", 0 );
}

sub _g_ls_remote {
    my ( $dev, $root, $r, $a, $ctx ) = @_;
    my ($remote) = grep { !/\A-/ } @$a;
    my ( $s, $err ) = _server( $ctx, $r, $remote );
    return ( $err, 0 ) unless $s;
    my @l = map {"$s->{refs}{heads}{$_}\trefs/heads/$_"} sort keys %{ $s->{refs}{heads} || {} };
    push @l, map {"$s->{refs}{tags}{$_}{commit}\trefs/tags/$_"} sort keys %{ $s->{refs}{tags} || {} };
    return ( join( "\n", @l ), 1 );
}

# Regeln des pre-receive-Hooks: erste Verletzung -> Text oder undef
sub _policy {
    my ( $srv, $s, $ids, $ref ) = @_;
    my $hook = $s->{hook};
    if ( defined $hook ) {
        my $e = ( $srv->{files} || {} )->{$hook};
        return undef unless defined $e;
        require Langertha::Holmgang::Sim::Linux;
        return undef unless Langertha::Holmgang::Sim::Linux::_can( $srv, 'git', $hook, 'x' );
    }
    for my $p ( @{ $s->{policy} || [] } ) {
        next if defined $p->{refs} && $ref !~ /$p->{refs}/;
        for my $id (@$ids) {
            my $c = $s->{_new}{$id} or next;
            my $bad = $p->{kind} eq 'message' ? $c->{message} !~ /$p->{regex}/
                : $p->{kind} eq 'author' ? $c->{author} !~ /$p->{regex}/
                : $p->{kind} eq 'path' ? scalar( grep {/$p->{regex}/} keys %{ $c->{tree} } )
                : 0;
            next unless $bad;
            my $t = $p->{text};
            $t =~ s/\{commit\}/_short($id)/ge;
            $t =~ s/\{subject\}/_subject( $c->{message} )/ge;
            $t =~ s/\{author\}/$c->{author}/g;
            return $t;
        }
    }
    return undef;
}

sub _g_push {
    my ( $dev, $root, $r, $a, $ctx ) = @_;
    my ( $force, $lease, $tags, $setup, $follow, $delete, $dry );
    my @p;
    for (@$a) {
        if    ( $_ eq '--force' || $_ eq '-f' ) { $force = 1 }
        elsif (/\A--force-with-lease/) { $lease = 1 }
        elsif ( $_ eq '--tags' ) { $tags = 1 }
        elsif ( $_ eq '--follow-tags' ) { $follow = 1 }
        elsif ( $_ eq '-u' || $_ eq '--set-upstream' ) { $setup = 1 }
        elsif ( $_ eq '-d' || $_ eq '--delete' ) { $delete = 1 }
        elsif ( $_ eq '-n' || $_ eq '--dry-run' ) { $dry = 1 }
        elsif ( $_ eq '--no-verify' || $_ eq '-q' || $_ eq '--quiet' || $_ eq '-v' ) { }
        elsif (/\A-/) { return ( "error: unknown option `" . s/\A-+//r . "'", 0 ) }
        else { push @p, $_ }
    }
    my $remote = shift(@p) // 'origin';
    my ( $s, $err, $rm, $srv ) = _server( $ctx, $r, $remote );
    return ( $err, 0 ) unless $s;
    my @specs;    # [ lokal-id, ziel-ref, art, name, erzwingen ]
    my $b = $r->{branch};
    if ( !@p && !$tags ) {
        return ( "fatal: You are not currently on a branch.", 0 ) unless defined $b;
        return ( "fatal: The current branch $b has no upstream branch.\nTo push the current branch and set the remote as upstream, use\n\n    git push --set-upstream $remote $b\n", 0 )
            unless exists( ( $r->{refs}{remotes} || {} )->{"$remote/$b"} ) || $setup;
        @p = ($b);
    }
    for my $spec (@p) {
        my $f = $spec =~ s/\A\+// ? 1 : 0;
        my ( $src, $dst ) = split /:/, $spec, 2;
        $dst //= $src;
        $src =~ s{\Arefs/(?:heads|tags)/}{} if defined $src;
        $src = $b if $src eq 'HEAD' && defined $b;
        $dst = $b if $dst eq 'HEAD' && defined $b;
        if ( $delete || ( defined $src && $src eq '' ) ) {
            ( my $n = $dst ) =~ s{\Arefs/(?:heads|tags)/}{};
            my $kind = $dst =~ m{\Arefs/tags/} ? 'tag' : $dst =~ m{\Arefs/heads/} ? 'head' : exists( ( $s->{refs}{tags} || {} )->{$n} ) && !exists( ( $s->{refs}{heads} || {} )->{$n} ) ? 'tag' : 'head';
            push @specs, [ undef, $n, $kind, $n, 1 ];
            next;
        }
        if ( ( $r->{refs}{tags} || {} )->{$src} && !exists( ( $r->{refs}{heads} || {} )->{$src} ) ) { push @specs, [ $r->{refs}{tags}{$src}{commit}, $dst =~ s{\Arefs/tags/}{}r, 'tag', $src, $f ]; next }
        my $id = _rev( $r, $src ) // return ( "error: src refspec $src does not match any\nerror: failed to push some refs to '$rm->{url}'", 0 );
        push @specs, [ $id, $dst =~ s{\Arefs/heads/}{}r, 'head', $src, $f ];
    }
    if ( $tags || $follow ) {
        for my $tg ( sort keys %{ $r->{refs}{tags} || {} } ) {
            next if $follow && !$tags && !$r->{refs}{tags}{$tg}{annotated};
            next if grep { $_->[2] eq 'tag' && $_->[1] eq $tg } @specs;
            push @specs, [ $r->{refs}{tags}{$tg}{commit}, $tg, 'tag', $tg, 0 ];
        }
    }
    my @out = ("To $rm->{url}");
    my $fail = 0;
    my $hook_msg;
    for my $sp (@specs) {
        my ( $id, $ref, $kind, $name, $f ) = @$sp;
        my $cur = $kind eq 'tag' ? ( ( $s->{refs}{tags} || {} )->{$ref} || {} )->{commit} : ( $s->{refs}{heads} || {} )->{$ref};
        if ( !defined $id ) {
            if ( !defined $cur ) { push @out, " ! [remote rejected] $ref (not found)"; $fail = 1; next }
            if ( $kind eq 'head' && exists( ( $s->{protected} || {} )->{$ref} ) ) { push @out, " ! [remote rejected] $ref (protected branch)"; $hook_msg //= "remote: \nremote: Forgejo: branch $ref is protected from deletion"; $fail = 1; next }
            next if $dry;
            if ( $kind eq 'tag' ) { delete $s->{refs}{tags}{$ref} } else { delete $s->{refs}{heads}{$ref}; delete $r->{refs}{remotes}{"$remote/$ref"} }
            push @out, " - [deleted]         $ref";
            next;
        }
        if ( defined $cur && $cur eq $id && !( $kind eq 'tag' && $r->{refs}{tags}{$name}{annotated} && !( $s->{refs}{tags}{$ref} || {} )->{annotated} ) ) { push @out, " = [up to date]      $name -> $ref" if @p; next }
        my $known = defined $cur ? exists $r->{commits}{$cur} : 1;
        my $ff = !defined $cur || $known && _ancestors( $r, $id )->{$cur};
        if ( $kind eq 'tag' && defined $cur && !$force && !$f ) { push @out, " ! [rejected]        $name -> $ref (already exists)"; $fail = 1; next }
        if ( !$ff && !$force && !$f ) {
            my $lease_ok = $lease && defined( ( $r->{refs}{remotes} || {} )->{"$remote/$ref"} ) && $r->{refs}{remotes}{"$remote/$ref"} eq $cur;
            unless ($lease_ok) {
                push @out, " ! [" . ( $lease ? 'rejected' : 'rejected' ) . "]        $name -> $ref " . ( $lease ? '(stale info)' : $known ? '(non-fast-forward)' : '(fetch first)' );
                $fail = 2;
                next;
            }
        }
        if ( !$ff && $kind eq 'head' && exists( ( $s->{protected} || {} )->{$ref} ) ) {
            push @out, " ! [remote rejected] $name -> $ref (pre-receive hook declined)";
            $hook_msg //= "remote: \nremote: Forgejo: branch $ref is protected from force push";
            $fail = 1;
            next;
        }
        my $prot = ( $s->{protected} || {} )->{$ref};
        if ( $kind eq 'head' && ref $prot eq 'HASH' && exists $prot->{push} && !$prot->{push} ) {    # nur ueber Pull-Request
            push @out, " ! [remote rejected] $name -> $ref (pre-receive hook declined)";
            $hook_msg //= "remote: \nremote: Forgejo: Not allowed to push to protected branch $ref";
            $fail = 1;
            next;
        }
        # neue Commits fuer die Hook-Regeln
        my @new = grep { !$s->{commits}{$_} } _range( $r, undef, $id );
        local $s->{_new} = { map { $_ => $r->{commits}{$_} } @new };
        if ( defined( my $why = _policy( $srv, $s, \@new, $kind eq 'tag' ? "refs/tags/$ref" : "refs/heads/$ref" ) ) ) {
            push @out, " ! [remote rejected] $name -> $ref (pre-receive hook declined)";
            $hook_msg //= join "\n", map {"remote: $_"} split /\n/, $why;
            $fail = 1;
            next;
        }
        next if $dry;
        $s->{commits}{$_} //= _clone( $r->{commits}{$_} ) for @new;
        if ( $kind eq 'tag' ) {
            $s->{refs}{tags}{$ref} = _clone( $r->{refs}{tags}{$name} );
            push @out, sprintf( ' * [new tag]         %s -> %s', $name, $ref );
        }
        else {
            $s->{refs}{heads}{$ref} = $id;
            $r->{refs}{remotes}{"$remote/$ref"} = $id;
            push @out, !defined $cur ? sprintf( ' * [new branch]      %s -> %s', $name, $ref )
                : $ff ? sprintf( '   %s..%s  %s -> %s', _short($cur), _short($id), $name, $ref )
                : sprintf( ' + %s...%s %s -> %s (forced update)', _short($cur), _short($id), $name, $ref );
            $s->{pushes}++;
        }
    }
    if ($fail) {
        unshift @out, $hook_msg if defined $hook_msg;
        push @out, "error: failed to push some refs to '$rm->{url}'";
        push @out, "hint: Updates were rejected because the remote contains work that you do not\nhint: have locally. This is usually caused by another repository pushing to\nhint: the same ref. If you want to integrate the remote changes, use\nhint: 'git pull' before pushing again.\nhint: See the 'Note about fast-forwards' in 'git push --help' for details." if $fail == 2;
        return ( join( "\n", @out ), 0, 1 );
    }
    push @out, "branch '$b' set up to track '$remote/$b'." if $setup && defined $b;
    view($s);
    return ( @out > 1 ? join( "\n", @out ) : 'Everything up-to-date', 1 );
}


sub view {
    my ($s) = @_;
    my %v;
    for my $b ( keys %{ $s->{refs}{heads} || {} } ) {
        my $tip = $s->{refs}{heads}{$b};
        my $c = $s->{commits}{$tip} or next;
        $v{$b} = { message => $c->{message}, author => $c->{author}, tree => _clone( $c->{tree} ), parents => scalar @{ $c->{parents} || [] },
            log => [ map { my $x = $s->{commits}{$_}; +{ id => $_, message => $x->{message}, author => $x->{author}, parents => scalar @{ $x->{parents} || [] } } } reverse _range( $s, undef, $tip ) ] };
    }
    $s->{view} = \%v;
    return;
}

# --- forgejo-runner -------------------------------------------------------------------------


sub runner {
    my ( $dev, $av, $ctx, $cwd, $user ) = @_;
    my @a = @$av;
    my $usage = "A runner for Forgejo Actions\n\nUsage:\n  forgejo-runner [flags]\n  forgejo-runner [command]\n\nAvailable Commands:\n"
        . "  cache-server         Start a cache server for the cache action\n  completion           Generate the autocompletion script for the specified shell\n"
        . "  create-runner-file   Create a runner file using a shared secret used to pre-register the runner on the Forgejo instance\n"
        . "  daemon               Run as a runner daemon\n  exec                 Run workflow locally.\n  generate-config      Generate an example config file\n"
        . "  help                 Help about any command\n  register             Register a runner to the server\n\nFlags:\n  -c, --config string   config file path\n  -h, --help            help for forgejo-runner\n  -v, --version         version for forgejo-runner";
    my $verb = shift(@a) // return ( $usage, 1 );
    return ( $usage, 1 ) if $verb eq '--help' || $verb eq '-h' || $verb eq 'help' && !@a;
    return ( "Register a runner to the server\n\nUsage:\n  forgejo-runner register [flags]\n\nFlags:\n  -h, --help                   help for register\n      --instance string        Forgejo instance address\n"
        . "      --labels string          Runner tags, comma separated\n      --name string            Runner name\n      --no-interactive         Disable interactive mode\n"
        . "      --token string           Runner token\n\nGlobal Flags:\n  -c, --config string   config file path", 1 ) if $verb eq 'register' && grep { $_ eq '--help' || $_ eq '-h' } @a or $verb eq 'help' && ( $a[0] // '' ) eq 'register';
    return ( 'forgejo-runner version v3.5.1', 1 ) if $verb eq '--version' || $verb eq '-v' || $verb eq 'version';
    if ( $verb eq 'generate-config' ) {
        return ( "log:\n  level: info\nrunner:\n  file: .runner\n  capacity: 1\n  timeout: 3h\n  labels: []\ncache:\n  enabled: true\ncontainer:\n  network: \"\"\n  privileged: false\n  docker_host: \"\"", 1 );
    }
    unless ( $verb eq 'register' ) { push @GAPS, "forgejo-runner $verb"; return ( '', 0 ) }
    my %o;
    while (@a) {
        my $x = shift @a;
        if    ( $x =~ /\A--(instance|token|name|labels)=(.*)\z/ ) { $o{$1} = $2 }
        elsif ( $x =~ /\A--(instance|token|name|labels)\z/ ) { $o{$1} = shift @a }
        elsif ( $x eq '--no-interactive' ) { $o{ni} = 1 }
        elsif ( $x eq '-c' || $x eq '--config' ) { $o{config} = shift @a }
        else { return ( "Error: unknown flag: $x", 0 ) }
    }
    unless ( $o{ni} ) { push @GAPS, 'forgejo-runner register (interaktiv)'; return ( 'Error opening terminal: unknown.', 0 ) }
    return ( 'level=error msg="instance address is empty"', 0 ) unless length( $o{instance} // '' );
    return ( 'level=error msg="token is empty"', 0 ) unless length( $o{token} // '' );
    ( my $want = $o{instance} ) =~ s{/+\z}{};
    my ($host) = $want =~ m{\Ahttps?://([^/:]+)};
    my ($srv) = grep { ( ( ( $ctx->{state}{$_} || {} )->{forgejo} || {} )->{root_url} // "\0" ) =~ m{\A\Q$want\E/?\z} } sort keys %{ $ctx->{state} || {} };
    return ( qq{level=error msg="Cannot ping the Forgejo instance server" error="unavailable: dial tcp: lookup } . ( $host // $want ) . ' on 127.0.0.53:53: no such host"', 0 ) unless defined $srv;
    my $fj = $ctx->{state}{$srv}{forgejo};
    return ( 'level=info msg="Registering runner, name=' . ( $o{name} // '' ) . ", instance=$o{instance}, labels=[" . ( $o{labels} // '' ) . "].\"\n"
        . 'level=fatal msg="Failed to register runner" error="unauthenticated: runner registration token not found"', 0 )
        unless grep { $_ eq $o{token} } @{ $fj->{runner_tokens} || [] };
    my $name = $o{name} // $dev->{hostname} // 'runner';
    my @labels = grep {length} split /\s*,\s*/, $o{labels} // '';
    my $id = 1 + scalar keys %{ $fj->{runners} || {} };
    $fj->{runners}{$name} = { id => $id, labels => \@labels };
    my $uuid = join '-', unpack 'A8 A4 A4 A4 A12', Digest::SHA::sha1_hex( "$srv/$name/$id" );
    my $file = ( $cwd // ( ( $user // 'root' ) eq 'root' ? '/root' : ( ( ( $dev->{users} || {} )->{$user} || {} )->{home} // "/home/$user" ) ) ) . '/.runner';
    $dev->{files}{$file} = { content => JSON::MaybeXS->new( canonical => 1, pretty => 1 )->encode( {
            WARNING => 'This file is automatically generated by act-runner. Do not edit it manually unless you know what you are doing. Removing this file will cause act runner to re-register as a new runner.',
            id => $id, uuid => $uuid, name => $name, token => substr( Digest::SHA::sha1_hex("token/$uuid"), 0, 40 ), address => $o{instance}, labels => \@labels } ) =~ s{" : }{": }gr,
        owner => $user // 'root', group => $user // 'root', mode => '0600' };
    return ( 'level=info msg="Registering runner, name=' . $name . ", instance=$o{instance}, labels=[" . join( ' ', @labels ) . "].\"\n"
        . 'level=debug msg="Successfully pinged the Forgejo instance server"' . "\n" . 'level=info msg="Runner registered successfully."', 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Git - git on simulated Linux hosts — working copy, index, commits, push to a Forgejo server with hooks

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # from the Linux simulator: git on a device with git.repos
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Git::git( $dev, \@argv, $ctx, $cwd );

=head1 DESCRIPTION

git 2.39 (Debian 12) on a Linux device (cai-platform F<docs/entwurf-evals.md> §3.3.1).
A working copy is under the device's C<git.repos>; its files are the device's
files under the repo's path:

  git:
    config: { user.name: Dev, user.email: dev@example.org }      # --global
    repos:
      /home/dev/shop:
        branch: main
        config: { user.email: … }                                # --local
        remotes: { origin: { url: git@git.example.com:shop/shop.git, host: git1, repo: shop/shop } }
        refs: { heads: { main: <id> }, remotes: { origin/main: <id> }, tags: { v1.3.0: { commit: <id>, annotated: true, message: … } } }
        commits: { <id>: { parents: [ … ], message, author: "Name <mail>", date, tree: { path: content } } }
        index: { path: content }         # missing = like HEAD

The server (e.g. Forgejo) holds the repos under C<forgejo.repos> of its
device: C<refs>, C<commits>, plus B<rules of the pre-receive hook>
(C<policy: [ { kind: message|author|path, regex, text } ]>, active when
C<hook> is missing or the hook file is executable for the user C<git>) and
B<protected branches> (C<protected: { main: {} }>: no force push). Commit IDs
are SHA-1 over parents, message, author, date and tree — deterministic.

B<Commands>: C<status [-s|--porcelain]>, C<add>, C<rm [--cached] [-r]>,
C<mv>, C<restore [--staged]>, C<commit [-a] [-m …] [--amend] [--no-edit]
[--reset-author] [--author=…] [--allow-empty]>, C<log [--oneline] [-n N]
[--format=…] [--stat] [A..B] [--all]>, C<show [--stat|--name-only]>, C<diff
[--cached] [--stat|--name-only]>, C<branch [-a] [-vv]>, C<checkout [-b]>,
C<switch [-c]>, C<reset [--soft|--mixed|--hard]>, C<tag [-a] [-m] [-d]
[-l]>, C<config [--global|--local] [--get|--unset|--list]>, C<remote -v>,
C<rev-parse>, C<ls-files>, C<fetch>, C<pull [--rebase|--ff-only|--no-rebase]>,
C<rebase UPSTREAM>, C<merge>, C<stash [push [-m …] [-u]|list|show [-p]|apply|pop|drop|clear]>
(also C<--autostash> and C<rebase.autoStash> with C<pull --rebase>/C<rebase>), C<push [--force|--force-with-lease] [--tags]
[-u] [REMOTE] [REFSPEC…]>, C<ls-remote>. Revisions: C<HEAD>, C<HEAD~N>,
C<HEAD^>, branches, C<origin/main>, tags, (short) IDs. Anything interactive
(C<rebase -i>, C<add -p>, C<commit> without C<-m>) and C<clone> are
gaps of the simulation. A conflict during rebase or merge aborts without
changing anything (like C<--abort>).

Pure functions on the state, neutral.

=head2 git

  my ( $out, $ok ) = git( $dev, \@argv, $ctx, $cwd );

=head2 virtual

  my $v = virtual( $dev, $path );   # { text => … } (file) | { dir => [ names ] } | undef

The F<.git> directory of a working copy, or a bare repo of the server, as
files (HEAD, config, refs/…, description, objects/, hooks/), derived from the
state — for the shell's C<ls>, C<cat>, C<stat>.

=head2 api

  my ( $status, $body, $type ) = api( $dev, $method, $path );

The HTTP API of a Forgejo server (read only, without a token): C</api/v1/version>,
C</api/v1/repos/O/R>, C<…/branches>, C<…/tags>, C<…/commits>; what needs a
token (protection rules, admin, Actions) answers 401.

=head2 view

  view( $server_repo );

Writes the view of every branch of the server repo to C<view.E<lt>branchE<gt>>:
C<message>, C<author>, C<tree> of the tip and C<log> (all reachable commits,
newest first, each with C<id>, C<message>, C<author>, C<parents>). For the
cases' rules (IDs depend on the path taken); rebuilt after every push.

=head2 runner

  my ( $out, $ok ) = runner( $dev, \@argv, $ctx, $cwd, $user );

C<forgejo-runner> (v3.5): C<register --no-interactive --instance URL --token T
--name N [--labels a,b]> writes the file F<.runner> into the working directory
(owned by the calling user, mode 0600) and registers the runner with the
server whose C<forgejo.root_url> matches the instance and whose
C<forgejo.runner_tokens> know the token; C<--version>, C<generate-config>.
C<daemon> and anything interactive are gaps of the simulation.

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
