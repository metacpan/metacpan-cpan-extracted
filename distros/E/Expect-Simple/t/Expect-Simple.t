use Test::More tests => 6;
BEGIN { use_ok('Expect::Simple') };

#########################

my %attr = ( Prompt => 'tpt> ',
	     DisconnectCmd => 'quit',
	     Prompt => [ -re => 'tpt\s\d+> ',
			 'quit> '
		       ],
	     RawPty => 1,
	);

# test scalar Cmd argument
{
    my $res;
    my $obj = Expect::Simple->new( { %attr,
				     Cmd => "$^X t/testprog",
				   });

    $obj->send( 'a' );
    chomp( $res = $obj->before );
    is( $res, 'A', 'Cmd string a' );

    $obj->send( 'b' );
    chomp( $res = $obj->before );
    is( $res, 'B', 'Cmd string b' );

    $obj->send( 'quit' );
    chomp( $res = $obj->before );
    is( $res, 'byebye', 'Cmd string quit' );

    is ( $obj->match_str, 'quit> ', 'Cmd string quit prompt' );
}

# test array Cmd argument
{
    my $res;
    my $obj = Expect::Simple->new( { %attr,
				     Cmd => [ $^X, 't/testprog'],
				   });

    $obj->send( 'quit' );
    chomp( $res = $obj->before );
    is( $res, 'byebye', 'Cmd array quit' );
}
