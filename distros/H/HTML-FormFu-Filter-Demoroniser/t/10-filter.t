use strict;
use warnings;

use Test::More tests => 2;

use HTML::FormFu;

my $text = 'This is an em dash: –';

# utf8
{
    my $expected = "This is an em dash: â€“";

    my $form = HTML::FormFu->new;
    $form->element( 'Text' )->name( 'foo' );

    $form->filter(
        {   type  => 'Demoroniser',
            names => [ 'foo' ],
        }
    );

    $form->process( { foo => $text, } );

    is( $form->param( 'foo' ), $expected, 'demoronise (utf8)' );
}

# ascii
{
    my $expected = "This is an em dash: -";

    my $form = HTML::FormFu->new;
    $form->element( 'Text' )->name( 'foo' );

    $form->filter(
        {   type     => 'Demoroniser',
            names    => [ 'foo' ],
            encoding => 'ascii',
        }
    );

    $form->process( { foo => $text, } );

    is( $form->param( 'foo' ), $expected, 'demoronise (ascii)' );
}
