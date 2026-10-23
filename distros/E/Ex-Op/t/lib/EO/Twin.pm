package EO::Twin;
use strict;
use warnings;
no strict 'refs';
use B ();
use Exporter ();

our $BASE = 'EO::Basic';

sub import {
    my $class  = shift;
    my $caller = caller;
    *{"${caller}::$_"} = \&{"EO::Twin::$_"} for @_;
}

my $n = 0;
sub fresh { 'EO::T' . ++$n }

sub imp {
    my ($mod, $pkg, @list) = @_;
    local $@;
    my $ok = eval "package $pkg; ${mod}->import(\@list); 1";
    return $ok ? undef : $@;
}

sub imp_w {
    my ($mod, $pkg, @list) = @_;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    my $err = imp($mod, $pkg, @list);
    return ($err, \@warn);
}

sub _code {
    my ($cv) = @_;
    my $b = B::svref_2object($cv);
    my $name = $b->GV->STASH->NAME . '::' . $b->GV->NAME;
    $name =~ s/^(EO::\w+?)X\b/$1/;
    return $name . (defined &$cv ? '' : ' (stub)');
}

sub describe {
    my ($pkg) = @_;
    my %out;
    for my $name (sort keys %{"${pkg}::"}) {
        next if $name =~ /::$/ && $name ne 'Other::';
        next if $name eq 'BEGIN';
        if ($name eq 'Other::') {
            my $sub = describe("${pkg}::Other");
            $out{"Other::$_"} = $sub->{$_} for keys %$sub;
            next;
        }
        my $glob = \*{"${pkg}::$name"};
        my @have;
        push @have, 'CODE='   . _code(*{$glob}{CODE})         if *{$glob}{CODE};
        push @have, 'SCALAR=' . ${ *{$glob}{SCALAR} }          if defined ${ *{$glob}{SCALAR} };
        push @have, 'ARRAY='  . join(',', @{ *{$glob}{ARRAY} }) if *{$glob}{ARRAY} && @{ *{$glob}{ARRAY} };
        push @have, 'HASH='   . join(',', %{ *{$glob}{HASH} })  if *{$glob}{HASH} && %{ *{$glob}{HASH} };
        $out{$name} = join ' ', @have if @have;
    }
    return \%out;
}

# Exporter keeps a spec list in a hash, so the order of its error lines and
# of its "Import add" names is the hash's. Those are compared as sets.
sub _norm {
    my ($err) = @_;
    return undef unless defined $err;
    $err =~ s/(EO::\w+?)X\b/$1/g;
    $err =~ s/EO::T\d+\b/EO::T/g;
    $err =~ s/ at (?:\(eval \d+\)|\S+) line \d+\.?\n?/ at FILE line N.\n/g;
    my @lines = split /\n/, $err;
    s/^\s+(?=")// for @lines;
    my @bad = sort grep { /is not (?:exported|implemented)/ } @lines;
    @lines = map { /is not (?:exported|implemented)/ ? shift @bad : $_ } @lines;
    s/^(Import (?:add|del): )(.*?)(  at FILE)/$1 . join(' ', sort split ' ', $2) . $3/e for @lines;
    return join "\n", @lines;
}

# Exporter before 5.70 sets its own $SIG{__WARN__}, so its warnings and the
# lines of its error cannot be caught. There only death is compared.
our $QUIET = !eval { Exporter->VERSION('5.70'); 1 };

sub twin_is {
    my ($desc, @list) = @_;
    my ($pa, $pb) = (fresh(), fresh());
    my ($ea, $wa) = imp_w($BASE,       $pa, @list);
    my ($eb, $wb) = imp_w("${BASE}X",  $pb, @list);
    if ($QUIET) {
        ($ea, $eb) = map { defined $_ ? 'died' : undef } $ea, $eb;
        ($wa, $wb) = ([], []);
    }
    Test::More::is_deeply(
        [_norm($ea), [map { _norm($_) } @$wa], describe($pa)],
        [_norm($eb), [map { _norm($_) } @$wb], describe($pb)],
        "same as Exporter: $desc",
    );
    return ($ea, describe($pa), $wa);
}

1;
