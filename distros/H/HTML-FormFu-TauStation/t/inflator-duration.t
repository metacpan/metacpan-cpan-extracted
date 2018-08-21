use strict;
use warnings;

use Test::More tests => 4;

use HTML::FormFu;

my $form = HTML::FormFu->new;

$form->element('Text')->name('foo');
$form->element('Text')->name('bar');

$form->inflator('TauStation::Duration');

# Valid
{
    $form->process(
        {   foo => 'D123.45/67:890 GCT',
            bar => 'D1.2/3:4 GCT',
        } );

    isa_ok( $form->params->{foo}, 'DateTime::Duration::TauStation' );
    isa_ok( $form->params->{bar}, 'DateTime::Duration::TauStation' );
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
