use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;
use JSON::PP;

my $CLASS = 'JavaScript::V8::XS';

sub test_boolean {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $name = 'foo';
    my $data = { name => 'gonzo', male => JSON::PP::true, plant => JSON::PP::false };
    my $more = { human => JSON::PP::true, mineral => JSON::PP::false };
    # printf STDERR ("CALLING SET %s", Dumper($data));
    $vm->set($name, $data);
    foreach my $key (keys %$more) {
        $vm->eval(sprintf("%s.%s = %s", $name, $key, $more->{$key} ? 'true' : 'false'));
        $data->{$key} = $more->{$key};
    }
    my $got = $vm->get($name);
    # printf STDERR ("GOT %s", Dumper($got));
    is_deeply($got, $data, "got correct boolean conversions");
}

sub main {
    use_ok($CLASS);

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Sortkeys = 1;
    test_boolean();
    done_testing;
    return 0;
}

exit main();
