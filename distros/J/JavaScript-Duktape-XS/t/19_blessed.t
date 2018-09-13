use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_blessed {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my %types = (
        bibo =>  { inner => 1, outer => 1 },
        bino =>  { inner => 1, outer => 0 },
        nibo =>  { inner => 0, outer => 1 },
        nino =>  { inner => 0, outer => 0 },
    );
    my $name = 'data';
    foreach my $type (sort keys %types) {
        my $spec = $types{$type};

        my $inner = [0, 1, 2];
        bless $inner, 'Inner' if $spec->{inner};

        my $outer = { name => 'gonzo', building => 10 };
        $outer->{inner} = $inner;
        bless $outer, 'Outer' if $spec->{outer};

        # printf STDERR ("CALLING SET %s", Dumper($outer));
        $vm->set($name, $outer);
        my $got = $vm->get($name);
        # printf STDERR ("GOT %s", Dumper($got));
        is_deeply($got, $outer, "got correct data back for $type");
    }
}

sub main {
    use_ok($CLASS);

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Sortkeys = 1;
    test_blessed();
    done_testing;
    return 0;
}

exit main();
