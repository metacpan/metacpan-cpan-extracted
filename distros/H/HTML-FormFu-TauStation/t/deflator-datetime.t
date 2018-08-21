use strict;
use warnings;

use Test::More tests => 2;

use HTML::FormFu;
use DateTime::Calendar::TauStation;
use DateTime::Format::TauStation;

my $form = HTML::FormFu->new(
    { tt_args => { INCLUDE_PATH => 'share/templates/tt/xhtml' } } );

my $dt1 = DateTime::Format::TauStation->parse_datetime('123.45/67:890 GCT');
my $dt2 = DateTime::Calendar::TauStation->catastrophe;

$form->element('Text')->name('foo')->default($dt1);
$form->element('Text')->name('bar')->default($dt2);

$form->deflator('TauStation::DateTime');

$form->process;

like( $form->get_field('foo'), qr|value="123.45/67:890 GCT"| );
like( $form->get_field('bar'), qr|value="000.00/00:000 GCT"| );
