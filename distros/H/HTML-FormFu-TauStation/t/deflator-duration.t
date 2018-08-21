use strict;
use warnings;

use Test::More tests => 2;

use HTML::FormFu;
use DateTime::Duration::TauStation;
use DateTime::Format::TauStation;

my $form = HTML::FormFu->new(
    { tt_args => { INCLUDE_PATH => 'share/templates/tt/xhtml' } } );

my $dur1 = DateTime::Format::TauStation->parse_duration('D123.45/67:890 GCT');
my $dur2 = DateTime::Format::TauStation->parse_duration('D1.4/6:8 GCT');

$form->element('Text')->name('foo')->default($dur1);
$form->element('Text')->name('bar')->default($dur2);

$form->deflator('TauStation::Duration');

$form->process;

like( $form->get_field('foo'), qr|value="D123.45/67:890 GCT"| );
like( $form->get_field('bar'), qr|value="D1.4/06:008 GCT"| );
