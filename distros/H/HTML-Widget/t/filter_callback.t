use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->filter( 'Callback', 'foo' )->callback(
    sub {
        my $value = shift;
        $value =~ s/foo/bar/g;
        return $value;
    } );

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'foobar' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'barbar', 'foo value' );
}

my $w2 = HTML::Widget->new;

$w2->element( 'Textfield', 'foo' );
$w2->element( 'Textfield', 'bar' );

$w2->filter('Callback')->callback(
    sub {
        my $value = shift;
        $value =~ s/foo/bar/g;
        return $value;
    } );

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => [ 'foobar', 'foobuz' ],
            bar => [ 'barfoo', 'barbuz' ] } );

    my $f = $w2->process($query);

    is_deeply( [ $f->param('foo') ], [qw/ barbar barbuz/], 'foo values' );
    is_deeply( [ $f->param('bar') ], [qw/ barbar barbuz/], 'bar values' );
}
