use strict;
use warnings;

my $warnings;
BEGIN { $SIG{__WARN__} = sub {
    $warnings++ if($_[0] =~ /^Devel::Hide/)
} }
my %args;
BEGIN {
    %args = map {
         my($k, $v) = split(/:/, $_);
        $k => [split(//, $v)]
    } @ARGV;
}

# the command line had -MDevel::Hide=-quiet so
# the warning this generates should be suppressed
use Devel::Hide 'Q';

use Test::More tests => 2 + @{$args{try}};

ok($ENV{PERL5OPT} =~ /\bMlib=t\b/, "PERL5OPT is added to, not overwritten: $ENV{PERL5OPT}");

foreach my $try (@{$args{try}}) {
    eval "require $try";
    if(!grep { $_ eq $try } @{$args{moan}}) {
        ok(!$@, "nothing moaned about loading $try");
    } else {
        like($@, qr/^Can't locate $try\.pm/, "correctly moaned about loading $try");
    }
}

ok(!$warnings, "suppressed warnings");
