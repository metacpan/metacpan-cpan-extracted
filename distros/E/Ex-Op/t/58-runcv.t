#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

# Perl names the variable in an "uninitialized" warning by looking up the
# running sub's pad. A frameless call lends the op to that lookup, or the
# name came from the caller's pad, and could crash.

my $n = 0;
sub twin_warn {
    my ($body, $caller, @args) = @_;
    no strict 'refs';
    $n++;
    my $plain = eval "package main; no strict 'vars'; sub { $body }" or die $@;
    my $code  = eval "package main; no strict 'vars'; sub { $body }" or die $@;
    Ex::Op::make("EO::Runcv::op$n", $code) or die Ex::Op::why_not($code);
    *{"EO::Runcv::plain$n"} = $plain;
    my %got;
    for my $kind (qw(plain op)) {
        my $src = $caller;
        $src =~ s/F\(/EO::Runcv::$kind$n(/g;
        my $f = eval "package main; $src" or die "$src: $@";
        my @w;
        local $SIG{__WARN__} = sub { push @w, $_[0] };
        my $r = eval { $f->(@args) };
        s/\(eval \d+\)/(eval)/g for @w;
        $got{$kind} = [$r, \@w, $@];
    }
    return \%got;
}
my @cases = (
    [ 'an uninitialised second parameter',
      'my ($x, $y) = @_; $y . "!"',
      'sub { my ($p, $q, $long_lexical_name) = (1, 2, 3); my $r = F(1); $r }' ],
    [ 'an uninitialised parameter in arithmetic',
      'my ($x) = @_; $x + 1',
      'sub { my $r = F(undef); $r }' ],
    [ 'from a sub compiled in a string eval',
      'my ($x) = @_; $x + 1',
      'eval q{ sub { my @pad = (1) x 3; my $r = F(undef); $r } }' ],
    [ 'a lexical in the body',
      'my ($x) = @_; my $t; $t . $x',
      'sub { my ($a1, $b1, $c1, $d1) = (1, 2, 3, 4); my $r = F("v"); $r }' ],
    [ 'a die after the warning',
      'my ($x) = @_; my $s = "<" . $x; die "$s\n"',
      'sub { my $r = F(undef); $r }' ],
);

for my $case (@cases) {
    my ($desc, $body, $caller) = @$case;
    my $got = twin_warn($body, $caller);
    is_deeply( $got->{op}, $got->{plain}, "$desc: the same value, warnings and error as a plain sub" )
        or diag explain $got;
}

BEGIN {
    Ex::Op::make(inner_op => sub { my ($x) = @_; $x . '.' });
    Ex::Op::make(outer_op => sub { my ($x, $y) = @_; inner_op($y) . $x });
}
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $r = sub { my ($p, $q) = (1, 2); my $v = outer_op('a'); $v }->();
    is( $r, '.a', 'an op calling an op with an uninitialised argument' );
    is( scalar @w, 1, '... one warning' );
    like( $w[0], qr/^Use of uninitialized value \$x in concatenation/, '... naming the inner op\'s own parameter' );
}

sub who_called { (caller(1))[3] // 'none' }
BEGIN {
    my $quiet = eval q{ no warnings; sub { my ($x) = @_; main::who_called() } } or die $@;
    my $loud  = eval q{ use warnings; sub { my ($x) = @_; main::who_called() } } or die $@;
    my $partial = eval q{ use warnings; no warnings 'uninitialized'; sub { my ($x) = @_; main::who_called() } } or die $@;
    Ex::Op::make(quiet_op => $quiet);
    Ex::Op::make(loud_op => $loud);
    Ex::Op::make(partial_op => $partial);
}
sub calls_quiet   { my $r = quiet_op(1); $r }
sub calls_loud    { my $r = loud_op(1); $r }
sub calls_partial { my $r = partial_op(1); $r }
is( calls_loud(), 'main::__ANON__', 'a body that could warn "uninitialized" is lent to the lookup: caller from it sees the op' );
is( calls_quiet(), 'main::calls_quiet', 'a body with no warnings is not: caller from it sees the op\'s caller' );
is( calls_partial(), 'main::calls_partial', '... nor one with every warning but "uninitialized"' );

{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    BEGIN { Ex::Op::make(quiet_add => eval q{ no warnings; sub { my ($x, $y) = @_; $x + $y } }) }
    my $r = sub { my ($p, $q) = (1, 2); my $v = quiet_add(undef, 2); $v }->();
    is( $r, 2, 'an op with warnings off, called with undef, runs' );
    is( scalar @w, 0, '... and warns nothing' );
}

done_testing;
