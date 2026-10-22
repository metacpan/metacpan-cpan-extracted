#!perl
use 5.010;
use strict;
use warnings;
no warnings 'redefine';
use Benchmark qw(cmpthese);

# Ex::Op's import against Exporter's, the same lists, into one package
# again and again (the same subs, so no new globs and no warnings).

my @names = map { "f$_" } 1 .. 10;
for my $kind (qw(EO X)) {
    my $pkg = "Bench::$kind";
    my $use = $kind eq 'EO' ? 'use Ex::Op;' : "use Exporter 'import';";
    my $subs = join '', map { "sub $_ { '$_' }\n" } @names;
    eval qq{
        package $pkg;
        $use
        our \@EXPORT      = qw(f1 f2);
        our \@EXPORT_OK   = qw(@names);
        our %EXPORT_TAGS = (half => [qw(f1 f2 f3 f4 f5)]);
        $subs
        1;
    } or die $@;
}

my %cases = (
    'ten names' => [ @names ],
    'a tag'     => [ ':half' ],
    'a pattern' => [ '/^f1/' ],
    '@EXPORT'   => [ ],
);

for my $case ('ten names', 'a tag', 'a pattern', '@EXPORT') {
    my @list = @{ $cases{$case} };
    print "\n$case\n";
    cmpthese(-3, {
        'Ex::Op' => sub { package Bench::Into; Bench::EO->import(@list) },
        'Exporter'   => sub { package Bench::Into; Bench::X->import(@list) },
    });
}
