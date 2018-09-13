use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

sub test_references {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $name = 'foo';
    my $code        = sub {};
    my $array_empty = [];
    my $array_data  = [ 1, 2, 3 ];
    my $hash_empty  = {};
    my $hash_data   = { foo => 11 };
    my %data = (
        'ref to empty string' => [ \'', '' ],
        'ref to ref to empty string' => [ \\'', '' ],
        'ref to 2' => [ \2, 2 ],
        'ref to empty arrayref' => [ \$array_empty, $array_empty ],
        'ref to arrayref' => [ \$array_data, $array_data ],
        'ref to empty hashref' => [ \$hash_empty, $hash_empty ],
        'ref to hashref' => [ \$hash_data, $hash_data ],
        'ref to coderef' => [ \$code, $code ],
    );
    foreach my $label (sort keys %data) {
        # printf STDERR ("CALLING SET %s", Dumper($outer));
        my ($value, $expected) = @{ $data{$label} };
        $vm->set($name, $value);
        my $got = $vm->get($name);
        # printf STDERR ("GOT %s", Dumper($got));
        is_deeply($got, $expected, "got correct data back for '$label'");
    }
}

sub test_boolean_references {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $name = 'foo';
    my %data = (
        'ref to 0' => [ \0, 0 ],
        'ref to ref to 0' => [ \\0, 0 ],
        'ref to 1' => [ \1, 1 ],
        'ref to ref to 1' => [ \\1, 1 ],
    );
    foreach my $label (sort keys %data) {
        # printf STDERR ("CALLING SET %s", Dumper($outer));
        my ($value, $expected) = @{ $data{$label} };
        $vm->set($name, $value);
        my $got = $vm->get($name);
        # printf STDERR ("GOT %s", Dumper($got));
        is(!!$got, !!$expected, "got correct boolean back for '$label'");
    }
}

sub main {
    use_ok($CLASS);

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Sortkeys = 1;
    test_references();
    test_boolean_references();
    done_testing;
    return 0;
}

exit main();
