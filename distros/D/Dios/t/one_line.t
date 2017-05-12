use Test::More tests => 1;

{
    package Thing;

    use Dios;
    method foo {"wibble"}

    ::is( Thing->foo, "wibble" );
}
