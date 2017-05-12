use Test::More;

BEGIN{
        use_ok('List::Priority');
}

my $list = List::Priority->new();
isa_ok($list, 'List::Priority');

done_testing;
