use strict;
use Test::More;


{
    package Foo;

    use lib 't/lib';

    use Test::More;
    use Test::Exception;
    use Dios;

    method formalize($text, :$justify = "left", :$case) {
        my %params;
        $params{text}           = $text;
        $params{justify}        = $justify;
        $params{case}           = $case if defined $case;

        return \%params;
    }

    ::is_deeply( Foo->formalize( "stuff" ), { text => "stuff", justify => "left" } );

#line 24
    throws_ok { Foo->formalize( "stuff", wibble => 23 ) }
              qr{},
            'simple named parameter error okay';

#    method foo( :$arg! ) {
#        return $arg;
#    }
#
#    is( Foo->foo( arg => 42 ), 42 );
##line 30
#    throws_ok { foo() } required_error('Foo', '$arg', 'foo', LINE => 30),
#            'simple named parameter error okay';

}

done_testing();
