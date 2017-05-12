use strict;
use warnings;
use Hoppy::Formatter::JSON;
use Test::More tests => 5;

{
    my $formatter = Hoppy::Formatter::JSON->new();
    isa_ok( $formatter, 'Hoppy::Formatter::JSON' );
    can_ok( $formatter, 'serialize' );
    can_ok( $formatter, 'deserialize' );
}

{
    my $formatter = Hoppy::Formatter::JSON->new();
    my $data  = { 'method' => 'hoge', 'params' => { 'data' => 'fuga' }, };
    my $json  = $formatter->serialize($data);
    my $data2 = $formatter->deserialize($json);
    is_deeply( $data, $data2, 'simple serialize ( and deserialize ) test' );

}

{
    my $formatter = Hoppy::Formatter::JSON->new();
    my $json = q( {"method":"hoge", "params":{"data": "fuga"}} );
    my $data = $formatter->deserialize($json);
    is_deeply(
        $data,
        {
            'params' => { 'data' => 'fuga' },
            'method' => 'hoge'
        },
        'simple deserialize test'
    );
}

