# -*- Mode: Perl; -*-

use strict;
use Test;
BEGIN { plan tests => 8 }

use HTML::FillInForm;

my $form = <<EOF;
<FORM name="foo1">
<INPUT TYPE="TEXT" NAME="foo1" value="nada">
</FORM>
<FORM name="foo2">
<INPUT TYPE="TEXT" NAME="foo2" value="nada">
</FORM>
<FORM>
<INPUT TYPE="TEXT" NAME="foo3" value="nada">
</FORM>
<FORM id="foo4">
<INPUT TYPE="TEXT" NAME="foo4" value="nada">
</FORM>
EOF
  ;
  
my %fdat = (
  foo1 => 'bar1',
  foo2 => 'bar2',
  foo3 => 'bar3',
  foo4 => 'bar4',
);

my $output = HTML::FillInForm->fill( \$form, \%fdat,
  target => 'foo2',
);

my @v = $output =~ m/<input .*?value="(.*?)"/ig;
ok($v[0], 'nada');
ok($v[1], 'bar2');
ok($v[2], 'nada');
ok($v[3], 'nada');

my $output2 = HTML::FillInForm->fill( \$form, \%fdat,
  target => 'foo4',
);

my @v2 = $output2 =~ m/<input .*?value="(.*?)"/ig;
ok($v2[0], 'nada');
ok($v2[1], 'nada');
ok($v2[2], 'nada');
ok($v2[3], 'bar4');
