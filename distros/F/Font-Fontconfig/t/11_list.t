use Test::Most;
use Test::MockModule;

use Font::Fontconfig;



subtest 'list basics' => sub {
    
    my $command_line;
    my $mocked_execute = _mock_execute(\$command_line,
        "foo.ttf: Foo:att1=bar",
        "baz.ttf: Baz:att2=qux",
    );
    
    my @patterns = Font::Fontconfig->list( );
    
    my ($listing, $include) = split q{ : }, $command_line;
    my ($command, $filters) = split q{ },   $listing, 2;
    
    is($command, 'fc-list',
        "will call 'fc-list' on the commandline"
    );
    
    is($filters, '', "does not have filters" );
    
    my $internal_attributes = join q{ }, qw/
        charset
        family
        familylang
        file
        fontformat
        foundry
        fullname
        fullnamelang
        postscriptname
        style
        stylelang
        weight
        width
    /;
    
    is($include, $internal_attributes, "does have all default includes" );
    
    cmp_deeply (
        \@patterns => [
            obj_isa('Font::Fontconfig::Pattern'),
            obj_isa('Font::Fontconfig::Pattern'),
        ],
        "creates objects from returned command-line"
    );
    
    is($patterns[0]->{family}, 'Foo',
        "object 1 is of family 'Foo'"
    );
    is($patterns[1]->{family}, 'Baz',
        "object 2 is of family 'Baz'"
    );
    
};



subtest 'list with filters' => sub {
    
    my $command_line;
    
    my $mocked_execute = _mock_execute(\$command_line);
    
    do {
        Font::Fontconfig->list( 'MyFont' );
        
        my ($listing, $include) = split q{ : }, $command_line;
        my ($command, $filters) = split q{ },   $listing, 2;
        
        is( $filters, 'MyFont',
            "will call with single font-family name"
        );
    };
    
    do {
        Font::Fontconfig->list( 'MyFont Awesome' );
        
        my ($listing, $include) = split q{ : }, $command_line;
        my ($command, $filters) = split q{ },   $listing, 2;
        
        is( $filters, 'MyFont\ Awesome',
            "will call with escaped spaces"
        );
    };
    
    TODO: {
        
        local $TODO = "not implemented yet";
        
        Font::Fontconfig->list( 'MyFont' =>
            foo => 'bar',
            foo => 'baz',
            qux => '123',
        );
        
        my ($listing, $include) = split q{ : }, $command_line;
        my ($command, $filters) = split q{ },   $listing, 2;
        
        is( $filters, 'MyFont:foo=bar:foo=baz:qux=123',
            "with combined filters"
        );
    }
    
};



sub _mock_execute {
    my $command_line_ref = shift;
    my @return_lines = @_;
    
    my $mock_mod = Test::MockModule->new( 'Font::Fontconfig' );
    
    $mock_mod->mock(
        _execute => sub {
            ${$command_line_ref} = shift;
            return @return_lines
        }
    );
    
    return $mock_mod
};



done_testing;
