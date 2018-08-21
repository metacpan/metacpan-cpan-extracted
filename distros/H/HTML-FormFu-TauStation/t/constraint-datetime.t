use strict;
use warnings;

use Test::More tests => 4;

use HTML::FormFu;

my $form = HTML::FormFu->new;

$form->element('Text')->name('foo');
$form->element('Text')->name('bar');

$form->constraint('TauStation::DateTime');

# Valid
{
    $form->process(
        {   foo => '123.45/67:890 GCT',
            bar => '1.2/3:4 GCT',
        } );

    ok( $form->valid('foo'), 'foo valid' );
    ok( $form->valid('bar'), 'bar valid' );
}

# invalid
{
    $form->process(
        {   foo => '123.45/67:890',
            bar => 'whatever GCT',
        } );

    ok( ! $form->valid('foo'), 'correctly invalid - missing GCT' );
    ok( ! $form->valid('bar'), 'correctly invalid - random string' );
}
