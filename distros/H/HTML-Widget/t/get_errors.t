use strict;
use warnings;

use Test::More tests => 6;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' )->value('foo');

# With mocked basic query
{
    my $result = $w->process;

    $result->add_error( {
            name    => 'foo',
            message => 'bad foo',
            type    => 'Custom'
        } );

    $result->add_error( {
            name    => 'baz',
            message => 'Baz error',
            type    => 'OtherType'
        } );

    is_deeply( [
            new HTML::Widget::Error( {
                    type    => 'OtherType',
                    name    => 'baz',
                    message => 'Baz error'
                }
            ),
            new HTML::Widget::Error( {
                    type    => 'Custom',
                    name    => 'foo',
                    message => 'bad foo'
                }
            ),
        ],
        [ $result->errors ],
        "Errors correct with no params"
    );

    is_deeply(
        [],
        [ $result->errors( undef, 'FakeType' ) ],
        "There are no FakeType errors"
    );
    is_deeply( [
            new HTML::Widget::Error( {
                    type    => 'Custom',
                    name    => 'foo',
                    message => 'bad foo'
                } )
        ],
        [ $result->errors( undef, 'Custom' ) ],
        "Filtered returned correct type"
    );

    $result->add_error( {
            name    => 'baz',
            message => 'Baz error 2',
            type    => 'All',
        } );

    is_deeply( [
            new HTML::Widget::Error( {
                    type    => 'OtherType',
                    name    => 'baz',
                    message => 'Baz error'
                }
            ),
            new HTML::Widget::Error( {
                    type    => 'All',
                    name    => 'baz',
                    message => 'Baz error 2',
                }
            ),
        ],
        [ $result->errors('baz') ],
        "Errors correct with name provided"
    );

    is_deeply( [
            new HTML::Widget::Error( {
                    type    => 'OtherType',
                    name    => 'baz',
                    message => 'Baz error'
                }
            ),
            new HTML::Widget::Error( {
                    type    => 'All',
                    name    => 'baz',
                    message => 'Baz error 2',
                }
            ),
            new HTML::Widget::Error( {
                    type    => 'Custom',
                    name    => 'foo',
                    message => 'bad foo'
                }
            ),
        ],
        [ $result->errors ],
        "Errors correct with no params"
    );

    is_deeply( [
            new HTML::Widget::Error( {
                    type    => 'All',
                    name    => 'baz',
                    message => 'Baz error 2',
                }
            ),
        ],
        [ $result->errors( 'baz', 'All' ) ],
        "errors correct with name and type params"
    );

}
