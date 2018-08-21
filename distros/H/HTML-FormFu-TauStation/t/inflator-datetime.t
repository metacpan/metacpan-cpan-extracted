use strict;
use warnings;

use Test::More tests => 4;

use HTML::FormFu;

my $form = HTML::FormFu->new;

$form->element('Text')->name('foo');
$form->element('Text')->name('bar');

$form->inflator('TauStation::DateTime');

# Valid
{
    $form->process(
        {   foo => '123.45/67:890 GCT',
            bar => '1.2/3:4 GCT',
        } );

    isa_ok( $form->params->{foo}, 'DateTime::Calendar::TauStation' );
    isa_ok( $form->params->{bar}, 'DateTime::Calendar::TauStation' );
}

# invalid
{
    $form->process(
        {   foo => '123.45/67:890',
            bar => 'whatever GCT',
        } );

        ok( ! defined $form->params->{foo} );
        ok( ! defined $form->params->{bar} );
}
