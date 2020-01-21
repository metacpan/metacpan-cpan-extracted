use Test::Most;

use Font::Fontconfig::Pattern;



subtest 'new_from_string' => sub {
    
    my $object;
    
    lives_ok {
        $object = Font::Fontconfig::Pattern->new_from_string(
            '/Path/to/fonts/Test Font-Semi.test: Test Font,Try Letters:foo=one'
        );
    } "creates a new object";
    
    isa_ok( $object, 'Font::Fontconfig::Pattern' );
    
    cmp_deeply(
        { %{$object} },
        {
            file => '/Path/to/fonts/Test Font-Semi.test',
            family => 'Test Font,Try Letters',
            foo => 'one',
        },
        "... and has expected internals"
    );
    
};



done_testing;
