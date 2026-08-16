#!perl
use strict;
use warnings;
use Test::More;
use Eshu;

# The two indenter bugs found through Template::Stencil's pretty goldens
# (and later Punk::DevError): a same-line <script ...></script> swallowed
# the rest of the document, and an unmatched closer dragged every later
# closer one level left. Both fixed by the open-element stack.

# ---- same-line script: the rest of the document survives ----------------------
{
	my $input = <<'END';
<html>
<head>
<script src="x"></script>
</head>
<body>
<p>hi</p>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<script src="x"></script>
	</head>
	<body>
		<p>hi</p>
	</body>
</html>
END

	is(Eshu->indent_html($input), $expected,
	   'a same-line <script></script> does not swallow the document');
}

# inline pairs with content after them on the same line, and <style>
{
	my $input = <<'END';
<div>
<script>a()</script><p>inline after</p>
<style>.x{}</style>
</div>
END

	my $expected = <<'END';
<div>
	<script>a()</script><p>inline after</p>
	<style>.x{}</style>
</div>
END

	is(Eshu->indent_html($input), $expected,
	   'inline verbatim pairs leave the rest of the line live');
}

# a multi-line script still collects and closes as before
{
	my $input = <<'END';
<div>
<script>
var x = 1;
</script>
</div>
END

	my $got = Eshu->indent_html($input);
	like($got, qr/\tvar x = 1;/,   'multi-line script content indented');
	like($got, qr/\t<\/script>\n<\/div>/, 'and the closes line up');
}

# ---- unmatched closer: later closers keep their column ------------------------
{
	my $input = <<'END';
<html>
<head>
<title>t</title>
</span>
</head>
<body>
<p>hi</p>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<title>t</title>
		</span>
	</head>
	<body>
		<p>hi</p>
	</body>
</html>
END

	is(Eshu->indent_html($input), $expected,
	   'an unmatched closer does not drag later closers left');
}

# ---- implied closes: the outer closer pops through ----------------------------
{
	my $input = <<'END';
<ul>
<li>one
<li>two
</ul>
<p>after</p>
END

	my $got = Eshu->indent_html($input);
	like($got, qr/^<\/ul>/m,      '</ul> pops back to its <ul>');
	like($got, qr/^<p>after<\/p>/m, 'and what follows starts level');
}

# case-insensitive pairing still holds through the stack
{
	my $input = <<'END';
<DIV>
<p>x</p>
</div>
END

	my $expected = <<'END';
<DIV>
	<p>x</p>
</div>
END

	is(Eshu->indent_html($input), $expected,
	   'closers pair case-insensitively');
}

done_testing;
