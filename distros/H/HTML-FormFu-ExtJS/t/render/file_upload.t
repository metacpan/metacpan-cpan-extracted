use Test::More tests => 1;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->elements({type => "File", name => "file"});

like($form->render, qr/fileUpload/);
