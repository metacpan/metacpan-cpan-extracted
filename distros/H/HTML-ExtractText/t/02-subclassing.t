#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

package Test0::Foo;
use parent 'HTML::ExtractText';

our @ReturnData;

sub _extract {
    my ( $self, $dom, $selector, $what ) = @_;

    @ReturnData = @{[@_]};
    $ReturnData[3] = {%{$ReturnData[3]}};
}

package main;

{
    my $ext = Test0::Foo->new;
    can_ok($ext,
        qw/new  extract  error  last_results  separator
            ignore_not_found _process _extract/
    );
    isa_ok($ext, 'Test0::Foo');

    $ext->extract({foo => 'div'}, '<div>ber</div><p>X<div>boorr</div>');

    my ( $obj, $dom ) = splice @Test0::Foo::ReturnData, 0, 2;

    isa_ok( $obj, 'Test0::Foo' );
    isa_ok( $dom, 'Mojo::DOM' );

    is $dom->find('p')->map('all_text')->compact->join("\n"),
        'X',
        'Mojo::DOM object is loaded with correct HTML';

    cmp_deeply
        \@Test0::Foo::ReturnData,
        [
            'foo',
            {foo => 'div'},
        ],
        '_extract method got the goods';

}

package Test1::Foo;
use parent 'HTML::ExtractText';
sub _process { return ref; }

package main;

{
    my $ext = Test1::Foo->new;
    can_ok($ext,
        qw/new  extract  error  last_results  separator
            ignore_not_found _process _extract/
    );
    isa_ok($ext, 'Test1::Foo');
    $ext->extract({foo => 'div'}, '<div>ber</div>');
    cmp_deeply
        +{ %$ext },
        { foo => 'Mojo::DOM' },
        '_process method got the goods';

}

done_testing();