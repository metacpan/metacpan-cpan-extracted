use strict;
use warnings;
use utf8;
use Test::More tests => 3;
use HTML::FillInForm::Lite;

my $fill = HTML::FillInForm::Lite->new();

# required
is($fill->fill(\<<'__INPUT__', {x => 1}), <<'__EXPECTED__');
<input type="text" name="x" required>
__INPUT__
<input type="text" name="x" required value="1" >
__EXPECTED__

# selected
is($fill->fill(\<<'__INPUT__', {x => 3}), <<'__EXPECTED__');
<select name="x">
<option value="1" selected="selected">1</option>
<option value="2">2</option>
<option value="3">3</option>
</select>
__INPUT__
<select name="x">
<option value="1">1</option>
<option value="2">2</option>
<option value="3" selected="selected">3</option>
</select>
__EXPECTED__

# readonly
is($fill->fill(\<<'__INPUT__', {x => 3}), <<'__EXPECTED__');
<input type="text" name="x" readonly>
__INPUT__
<input type="text" name="x" readonly value="3" >
__EXPECTED__

