#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;


use HTML::FillInForm::Lite;

my $o = HTML::FillInForm::Lite->new(decode_entity => 1);

my $s = <<'EOT';
<input type="radio" value="&#60;bar&#62;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "radio with HTML entities (numeric)";

$s = <<'EOT';
<input type="radio" value="&#x3c;bar&#x3e;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "radio with HTML entities (hex numeric)";


$s = <<'EOT';
<input type="checkbox" value="&#60;bar&#62;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "checkbox with HTML entities (numeric)";


$s = <<'EOT';
<select name="foo">
<option value="&#60;bar&#62;">ok</option>
</select>
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select with value, with HTML entities (numeric)";


$s = <<'EOT';
<select name="foo">
<option>&#60;bar&#62;</option>
</select>
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select without values, with HTML entities (numeric)";


$s = <<'EOT';
<input type="radio" value="&lt;bar&gt;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "radio with HTML entities";

$s = <<'EOT';
<input type="radio" value="&lt;bar&gt;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "checkbox with HTML entities";

$s = <<'EOT';
<select name="foo">
<option value="&lt;bar&gt;">ok</option>
</select>
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select with value, with HTML entities";

$s = <<'EOT';
<select name="foo">
<option>&lt;bar&gt;</option>
</select>
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select without values, with HTML entities";

$o = HTML::FillInForm::Lite->new(decode_entity => 0);

$s = <<'EOT';
<select name="foo">
<option>&lt;bar&gt;</option>
</select>
EOT

like $o->fill(\$s, { foo => '&lt;bar&gt;' }), qr/selected/, 'decode_entity => 0';

like $o->fill(\$s, { foo => '<bar>' }, decode_entity => 1), qr/selected/, 'decode_entity => 1 (overrided)';

unlike $o->fill(\$s, { foo => '<bar>'}, decode_entity => sub{ 'hoge' }), qr/selected/, 'decode_entity => sub{ ... }';

$s = <<'EOT';
<select name="foo">
<option>&foobar;</option>
</select>
EOT

like $o->fill(\$s, {foo => '&foobar;'}, decode_entity => 1), qr/selected/, 'undefined entity';
