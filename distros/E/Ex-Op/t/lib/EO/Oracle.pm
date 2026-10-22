package EO::Oracle;
use strict;
use warnings;
no strict 'refs';
use B ();
use Symbol ();
use Exporter ();
use Ex::Op ();

my %FLAG = (SCALAR => 0x10, ARRAY => 0x20, HASH => 0x40, CODE => 0x80);
my $N = 0;
my $T = 0;

# Two packages from one body: E on Exporter, X on Ex::Op. $style is
# 'import' (use Exporter 'import' / use Ex::Op) or 'isa' (@ISA).
sub build {
    my ($style, $body) = @_;
    $N++;
    my %pkg;
    for my $kind (qw(E X)) {
        my $pkg = "Ora::$kind$N";
        my $mod = $kind eq 'E' ? 'Exporter' : 'Ex::Op';
        my $use = $style eq 'isa'   ? "our \@ISA = ('$mod');"
                : $kind eq 'E'      ? "use Exporter 'import';"
                :                     "use Ex::Op;";
        my $src = "package $pkg;\n$use\n$body\n1;";
        eval $src or die "building $pkg: $@";
        $pkg{$kind} = $pkg;
    }
    return \%pkg;
}

sub norm {
    my ($s, $from, $to) = @_;
    return undef unless defined $s;
    $s =~ s/\Q$from\E\b/PKG/g;
    $s =~ s/\Q$to\E\b/TGT/g;
    $s =~ s/ at (?:\(eval \d+\)|\S+) line \d+\.?\n?/ at FILE line N.\n/g;
    my @lines = split /\n/, $s;
    my @bad = sort grep { /is not (?:exported|implemented)/ } @lines;
    @lines = map { /is not (?:exported|implemented)/ ? shift @bad : $_ } @lines;
    s/^(Import (?:add|del): )(.*?)(  at FILE)/$1 . join(' ', sort split ' ', $2) . $3/e for @lines;
    return join "\n", @lines;
}

sub _same {
    my ($to, $from, $name, $type) = @_;
    my $tg = ${"${to}::"}{$name};
    return undef unless $tg && ref \$tg eq 'GLOB';
    my $have = *{$tg}{$type};
    return undef unless $have;
    if ($type eq 'SCALAR') {
        return undef unless defined $$have || exists ${"${from}::"}{$name};
    }
    my $fg = ${"${from}::"}{$name};
    my $src = ($fg && ref \$fg eq 'GLOB') ? *{$fg}{$type} : undef;
    my $what = ($src && $src == $have) ? 'PKG' : 'other';
    $what .= ' (stub)' if $type eq 'CODE' && !defined &$have;
    return $what;
}

sub slots {
    my ($to, $from, $prefix) = @_;
    $prefix //= '';
    my %out;
    for my $name (sort keys %{"${to}::"}) {
        next if $name eq 'BEGIN' || $name eq '__ANON__';
        if ($name =~ /::$/) {
            my $sub = slots("${to}::" . substr($name, 0, -2), "${from}::" . substr($name, 0, -2),
                            "$prefix$name");
            %out = (%out, %$sub);
            next;
        }
        my $glob = ${"${to}::"}{$name};
        next unless ref \$glob eq 'GLOB';
        my $flags = B::svref_2object(\*{"${to}::$name"})->GvFLAGS;
        my @have;
        for my $type (qw(CODE SCALAR ARRAY HASH)) {
            my $what = _same($to, $from, $name, $type);
            next unless defined $what;
            next if $what eq 'other' && $type ne 'CODE' && !($flags & $FLAG{$type});
            push @have, "$type=$what" . (($flags & $FLAG{$type}) ? '+imported' : '');
        }
        $out{"$prefix$name"} = join ' ', @have if @have;
    }
    return \%out;
}

sub _stash {
    my ($pkg) = @_;
    return [ sort grep {
        my $g = ${"${pkg}::"}{$_};
        $_ ne 'BEGIN'
            && !(ref \$g eq 'GLOB' && B::svref_2object(\$g)->CVGEN)
    } keys %{"${pkg}::"} ];
}

sub run {
    my ($pkgs, @list) = @_;
    my %out;
    for my $kind (qw(E X)) {
        my $from = $pkgs->{$kind};
        my $to   = 'Ora::T' . ++$T;
        my @warn;
        my $err;
        {
            local $SIG{__WARN__} = sub { push @warn, $_[0] };
            local $@;
            my $ok = eval "package $to; ${from}->import(\@list); 1";
            $err = $ok ? undef : $@;
        }
        $out{$kind} = {
            error    => norm($err, $from, $to),
            warnings => [ map { norm($_, $from, $to) } @warn ],
            slots    => slots($to, $from),
            exporter => _stash($from),
        };
        Symbol::delete_package($to);
    }
    return \%out;
}

sub show {
    my ($v) = @_;
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Terse    = 1;
    return Data::Dumper::Dumper($v);
}

sub same {
    my ($r) = @_;
    return show($r->{E}) eq show($r->{X});
}

1;
