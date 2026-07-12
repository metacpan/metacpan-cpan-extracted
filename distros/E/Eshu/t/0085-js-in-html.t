use strict;
use warnings;
use Test::More;
use Eshu;

# Basic script in HTML
{
	my $input = <<'END';
<html>
<head>
<script>
function init() {
console.log("hello");
}
</script>
</head>
<body>
<p>Hello</p>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<script>
			function init() {
				console.log("hello");
			}
		</script>
	</head>
	<body>
		<p>Hello</p>
	</body>
</html>
END

	my $got = Eshu->indent_html($input);
	is($got, $expected, 'script block JS indented inside HTML');
}

# Script with nested braces
{
	my $input = <<'END';
<html>
<body>
<script>
if (true) {
for (var i = 0; i < 10; i++) {
arr.push(i);
}
}
</script>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<body>
		<script>
			if (true) {
				for (var i = 0; i < 10; i++) {
					arr.push(i);
				}
			}
		</script>
	</body>
</html>
END

	my $got = Eshu->indent_html($input);
	is($got, $expected, 'script with nested JS structures');
}

# Multiple scripts
{
	my $input = <<'END';
<html>
<head>
<script>
var x = 1;
</script>
</head>
<body>
<script>
function foo() {
return x;
}
</script>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<script>
			var x = 1;
		</script>
	</head>
	<body>
		<script>
			function foo() {
				return x;
			}
		</script>
	</body>
</html>
END

	my $got = Eshu->indent_html($input);
	is($got, $expected, 'multiple script blocks');
}

# Script with attributes
{
	my $input = <<'END';
<html>
<head>
<script type="text/javascript">
function init() {
return 1;
}
</script>
</head>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<script type="text/javascript">
			function init() {
				return 1;
			}
		</script>
	</head>
</html>
END

	my $got = Eshu->indent_html($input);
	is($got, $expected, 'script with type attribute');
}

# Empty script block
{
	my $input = <<'END';
<html>
<head>
<script>
</script>
</head>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<script>
		</script>
	</head>
</html>
END

	my $got = Eshu->indent_html($input);
	is($got, $expected, 'empty script block');
}

# Script with JS strings containing HTML-like content
{
	my $input = <<'END';
<html>
<body>
<script>
var html = "<div class='test'>";
document.write(html);
</script>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<body>
		<script>
			var html = "<div class='test'>";
			document.write(html);
		</script>
	</body>
</html>
END

	my $got = Eshu->indent_html($input);
	is($got, $expected, 'JS strings with HTML content');
}

# Pre and style still verbatim, script indented
{
	my $input = <<'END';
<html>
<head>
<style>
body { color: red; }
</style>
<script>
function init() {
return 1;
}
</script>
</head>
<body>
<pre>
  preserved   spaces
</pre>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<head>
		<style>
body { color: red; }
		</style>
		<script>
			function init() {
				return 1;
			}
		</script>
	</head>
	<body>
		<pre>
  preserved   spaces
		</pre>
	</body>
</html>
END

	my $got = Eshu->indent_html($input);
	is($got, $expected, 'style verbatim, script JS-indented, pre verbatim');
}

# XML mode does NOT indent script content (no special treatment)
{
	my $input = <<'END';
<root>
<script>
content
</script>
</root>
END

	my $expected = <<'END';
<root>
	<script>
		content
	</script>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'XML mode treats script as normal element');
}

done_testing();
