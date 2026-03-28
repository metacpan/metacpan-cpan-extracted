use strict;
use warnings;
use Test::More;
use Eshu;

# <pre> block passes through verbatim
{
	my $input = <<'END';
<html>
<body>
<pre>
  exactly   as   is
    no  re-indent
</pre>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<body>
		<pre>
  exactly   as   is
    no  re-indent
		</pre>
	</body>
</html>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'pre block content passed through verbatim');
}

# <script> block gets JS-indented
{
	my $input = <<'END';
<html>
<head>
<script>
var x = 1;
  if (x) {
      console.log(x);
  }
</script>
</head>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<script>
			var x = 1;
			if (x) {
				console.log(x);
			}
		</script>
	</head>
</html>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'script block content indented as JS');
}

# <style> block passes through
{
	my $input = <<'END';
<html>
<head>
<style>
body {
  color: red;
}
</style>
</head>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<style>
body {
  color: red;
}
		</style>
	</head>
</html>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'style block content passed through verbatim');
}

# Verbatim only in HTML mode — XML mode treats normally
{
	my $input = <<'END';
<root>
<pre>
content
</pre>
</root>
END

	my $expected = <<'END';
<root>
	<pre>
		content
	</pre>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'XML mode does not treat pre as verbatim');
}

done_testing();
