use strict;
use warnings;
use Test::More;
use Eshu;

# Switch statement
{
	my $input = <<'END';
switch (action) {
case 'add':
result = a + b;
break;
case 'sub':
result = a - b;
break;
default:
result = 0;
break;
}
END

	my $expected = <<'END';
switch (action) {
	case 'add':
	result = a + b;
	break;
	case 'sub':
	result = a - b;
	break;
	default:
	result = 0;
	break;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'switch statement');
}

# Try/catch/finally
{
	my $input = <<'END';
try {
doSomething();
} catch (e) {
handleError(e);
} finally {
cleanup();
}
END

	my $expected = <<'END';
try {
	doSomething();
} catch (e) {
	handleError(e);
} finally {
	cleanup();
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'try/catch/finally');
}

# Class definition
{
	my $input = <<'END';
class Animal {
constructor(name) {
this.name = name;
}
speak() {
return `${this.name} makes a noise.`;
}
}
END

	my $expected = <<'END';
class Animal {
	constructor(name) {
		this.name = name;
	}
	speak() {
		return `${this.name} makes a noise.`;
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'class definition');
}

# Chained method calls
{
	my $input = <<'END';
fetch('/api')
.then(response => {
return response.json();
})
.then(data => {
console.log(data);
})
.catch(err => {
console.error(err);
});
END

	my $expected = <<'END';
fetch('/api')
.then(response => {
		return response.json();
	})
.then(data => {
		console.log(data);
	})
.catch(err => {
		console.error(err);
	});
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'chained method calls with callbacks');
}

# Destructuring
{
	my $input = <<'END';
const {
a,
b,
c,
} = obj;
END

	my $expected = <<'END';
const {
	a,
	b,
	c,
} = obj;
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'object destructuring');
}

# Mixed comments and strings
{
	my $input = <<'END';
function complex() {
/* start */
var x = "string with // and /* stuff */";
// line comment with { braces }
var y = `template with // and /* stuff */`;
/* block
 * comment { }
 */
return [x, y];
}
END

	my $expected = <<'END';
function complex() {
	/* start */
	var x = "string with // and /* stuff */";
	// line comment with { braces }
	var y = `template with // and /* stuff */`;
	/* block
	* comment { }
	*/
	return [x, y];
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'mixed comments and strings');
}

# Deeply nested
{
	my $input = <<'END';
function a() {
if (true) {
for (var i = 0; i < 10; i++) {
while (running) {
doWork();
}
}
}
}
END

	my $expected = <<'END';
function a() {
	if (true) {
		for (var i = 0; i < 10; i++) {
			while (running) {
				doWork();
			}
		}
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'deeply nested structures');
}

# Range option
{
	my $input = <<'END';
function foo() {
  bar();
  baz();
}
END

	my $got = Eshu->indent_js($input, range_start => 2, range_end => 3);
	# Lines 2-3 re-indented, lines 1 and 4 preserved
	like($got, qr/function foo\(\) \{/, 'range: line 1 preserved');
	like($got, qr/\tbar\(\);/, 'range: line 2 re-indented');
	like($got, qr/\tbaz\(\);/, 'range: line 3 re-indented');
}

done_testing();
