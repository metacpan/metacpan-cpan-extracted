package EO::OpTwin;
use strict;
use warnings;
no strict 'refs';
use Ex::Op ();

our @LOG;
my $n = 0;

sub import {
    my $caller = caller;
    *{"${caller}::$_"} = \&{"EO::OpTwin::$_"} for qw(twin twin_all);
}

# One body, made twice: as a plain sub and as an op. The callers are
# compiled after make, so their calls to the op are the op's own.
sub twin {
    my ($body) = @_;
    $n++;
    my $plain = "EO::OpTwin::plain$n";
    my $op    = "EO::OpTwin::op$n";
    eval "package main; sub $plain { $body } 1" or die "plain: $@";
    my $code = eval "package main; sub { $body }" or die "op: $@";
    Ex::Op::make($op, $code) or die "not an op: " . Ex::Op::why_not($code) . "\n$body";
    my %call;
    for my $kind (qw(plain op)) {
        my $f = $kind eq 'plain' ? $plain : $op;
        $call{$kind} = eval qq{
            package EO::OpTwin::Caller$n;
            +{
                scalar => sub { my \$r = $f(\@_); [\$r] },
                list   => sub { my \@r = $f(\@_); [\@r] },
                void   => sub { $f(\@_); [] },
            };
        } or die "callers: $@";
    }
    return \%call;
}

# Every context, called from a sub in every context of its own.
sub twin_all {
    my ($desc, $body, @args) = @_;
    my $c = twin($body);
    for my $ctx (qw(scalar list void)) {
        for my $outer (qw(scalar list void)) {
            my %got;
            for my $kind (qw(plain op)) {
                local @LOG = ();
                my $res;
                my $err = do {
                    local $@;
                    my $f = $c->{$kind}{$ctx};
                    my $ok = eval {
                        if    ($outer eq 'scalar') { my $x = $f->(@args); $res = $x }
                        elsif ($outer eq 'list')   { my @x = $f->(@args); $res = $x[0] }
                        else                       { $f->(@args); $res = 'void' }
                        1;
                    };
                    $ok ? undef : do { (my $e = $@) =~ s{\(eval \d+\)}{(eval)}g; $e };
                };
                $got{$kind} = [$res, [@LOG], $err];
            }
            Test::More::is_deeply( $got{op}, $got{plain}, "$desc: $ctx call, from a sub in $outer context" )
                or Test::More::diag(Test::More::explain(\%got));
        }
    }
    return $c;
}

1;
