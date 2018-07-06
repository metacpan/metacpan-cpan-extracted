use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output qw/ output_from /;

my $CLASS = 'JavaScript::V8::XS';

sub test_console {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my @targets = qw/ stdout stderr /;
    my %funcs = (
        log       => 0,
        debug     => 0,
        trace     => 0,
        info      => 0,
        dir       => 1,
        warn      => 1,
        error     => 1,
        exception => 1,
    );
    my @texts = (
        q<'Hello Gonzo'>,
        q<'this is a string', 1, [], {}>,
    );
    foreach my $text (@texts) {
        my $expected = $text;
        $expected =~ s/[',]//g;
        $expected = quotemeta($expected);

        foreach my $func (sort keys %funcs) {
            my $target = $funcs{$func};
            my ($full, $empty) = ($target, 1 - $target);
            my $js = "console.$func($text)";
            my @output = output_from(sub { $vm->eval($js); });
            like($output[$full], qr/$expected/, "got correct $targets[$full] from $func for <$text>");
            is($output[$empty], '', "got empty $targets[$empty] from $func for <$text>");
        }
    }
}

sub test_assert {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my %values = (
        true => '',
        false => 'AssertionError',
    );
    foreach my $value (sort keys %values) {
        my $expected = $values{$value};
        my $js = "console.assert($value, '$value')";
        my ($out, $err) = output_from(sub { $vm->eval($js); });
        like($out, qr/$expected/, "got expected contents for assert in stdout for $value");
        is($err, '', "got empty stderr for assert for $value");
    }
}

sub main {
    use_ok($CLASS);

    test_console();
    test_assert();
    done_testing;
    return 0;
}

exit main();
