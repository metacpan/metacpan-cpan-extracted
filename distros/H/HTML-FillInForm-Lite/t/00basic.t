#!perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;

BEGIN{ use_ok('HTML::FillInForm::Lite'); }

#BEGIN{
#	# import utilities
#
#	no strict 'refs';
#	foreach my $f(qw(get_name get_type get_id get_value)){
#		*$f = \&{'HTML::FillInForm::Lite::_' . $f};
#	}
#}


my $s = q{<input type="text" name="foo" value="bar" id="baz" />};

#is get_type($s), "text", "(1)_get_type()";
#is get_name($s), "foo",  "(1)_get_name()";
#is get_id  ($s), "baz",  "(1)_get_id()";
#is get_value($s),"bar",  "(1)_get_value()";

$s = q{<input type='text' name='foo' value='bar' id='baz' />};

#is get_type($s), "text", "(2)_get_type()";
#is get_name($s), "foo",  "(2)_get_name()";
#is get_id  ($s), "baz",  "(2)_get_id()";
#is get_value($s),"bar",  "(2)_get_value()";

$s =~ s/\s+/\n/g;

#is get_type($s), "text", "(3)_get_type()";
#is get_name($s), "foo",  "(3)_get_name()";
#is get_id  ($s), "baz",  "(3)_get_id()";
#is get_value($s),"bar",  "(3)_get_value()";

$s = q{<INPUT TYPE="text" NAME="foo" VALUE="bar" ID=baz"/>};

#is get_type($s), "text", "(4)_get_type()";
#is get_name($s), "foo",  "(4)_get_name()";
#is get_id  ($s), "baz",  "(4)_get_id()";
#is get_value($s),"bar",  "(4)_get_value()";

$s = q{<input type=text name=foo value=bar id=baz />};

#is get_type($s), "text", "(5)_get_type()";
#is get_name($s), "foo",  "(5)_get_name()";
#is get_id  ($s), "baz",  "(5)_get_id()";
#is get_value($s),"bar",  "(5)_get_value()";

$s = q{<input value="&lt;&gt;" />};

#is get_value($s), '&lt;&gt;', "get raw data";


eval{
	HTML::FillInForm::Lite->new(foo => 'bar');
};
like $@, qr/unknown option/i, "Error: unknown option for new()";

eval{
	HTML::FillInForm::Lite->fill([], {}, foo => 'bar');
};
like $@, qr/unknown option/i, "Error: unknown option for fill()";

eval{
	HTML::FillInForm::Lite->fill(undef, {});
};
like $@, qr/no source/i, "Error: no source suplied";

eval{
	HTML::FillInForm::Lite->fill('foo', undef);
};

like $@, qr/no data/i, "Error: no data suplied";

eval{
	HTML::FillInForm::Lite->fill('no_such_file', {});
};
like $@, qr/cannot open/i, "Error: cannot open file";

eval{
	HTML::FillInForm::Lite->fill({}, \$s);
};
like $@, qr/Not a SCALAR/i, "Error: bad arguments";

# Cannot use '%s' as form object

eval{
	HTML::FillInForm::Lite->fill(\$s, \$s);
};
like $@, qr/cannot use/i, "Error: cannot use SCALAR ref as form data";

eval{
	HTML::FillInForm::Lite->fill(\$s, *GLOB);
};
like $@, qr/cannot use/i, "Error: cannot use GLOB as form data";

eval{
	HTML::FillInForm::Lite->fill(\$s, \*GLOB);
};
like $@, qr/cannot use/i, "Error: cannot use GLOB ref as form data";

eval{
	HTML::FillInForm::Lite->fill(\$s, "foo");
};
like $@, qr/cannot use/i, "Error: cannot use string as form data";

eval{
	HTML::FillInForm::Lite->fill(\$s, 0);
};
like $@, qr/cannot use/i, "Error: cannot use 0 as form data";

