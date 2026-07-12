use strict;
use warnings;
use Test::More tests => 15;
use Eshu;

# ── C: real-world patterns ────────────────────────────────────────────────

# Typedef struct with function pointer members
{
    my $in = <<'END';
typedef struct {
int width;
int height;
void (*draw)(struct Widget *);
void (*destroy)(struct Widget *);
} Widget;
END
    my $exp = <<'END';
typedef struct {
	int width;
	int height;
	void (*draw)(struct Widget *);
	void (*destroy)(struct Widget *);
} Widget;
END
    is(Eshu->indent_c($in), $exp, 'C: typedef struct with function pointers');
}

# Nested ternary and macro usage
{
    my $in = <<'END';
int clamp(int v, int lo, int hi) {
return v < lo ? lo
: v > hi ? hi
: v;
}
END
    my $exp = <<'END';
int clamp(int v, int lo, int hi) {
	return v < lo ? lo
	: v > hi ? hi
	: v;
}
END
    is(Eshu->indent_c($in), $exp, 'C: nested ternary continuation lines');
}

# ── Perl: real-world patterns ─────────────────────────────────────────────

# Moose-style accessor generation
{
    my $in = <<'END';
package Animal;
use strict;
use warnings;
for my $attr (qw(name age species)) {
no strict 'refs';
*{"Animal::$attr"} = sub {
my ($self, $val) = @_;
$self->{$attr} = $val if @_ > 1;
return $self->{$attr};
};
}
1;
END
    my $exp = <<'END';
package Animal;
use strict;
use warnings;
for my $attr (qw(name age species)) {
	no strict 'refs';
	*{"Animal::$attr"} = sub {
		my ($self, $val) = @_;
		$self->{$attr} = $val if @_ > 1;
		return $self->{$attr};
	};
}
1;
END
    is(Eshu->indent_pl($in), $exp, 'Perl: dynamic accessor generation with nested subs');
}

# Dispatch table
{
    my $in = <<'END';
my %cmd = (
add => sub {
my ($a, $b) = @_;
return $a + $b;
},
mul => sub {
my ($a, $b) = @_;
return $a * $b;
},
);
END
    my $exp = <<'END';
my %cmd = (
	add => sub {
		my ($a, $b) = @_;
		return $a + $b;
	},
	mul => sub {
		my ($a, $b) = @_;
		return $a * $b;
	},
);
END
    is(Eshu->indent_pl($in), $exp, 'Perl: dispatch table with anonymous subs');
}

# ── XS: real-world patterns ───────────────────────────────────────────────

# XSUB with INIT section
{
    my $in = <<'END';
MODULE = Foo  PACKAGE = Foo

int
add(a, b)
    int a
    int b
INIT:
    if (a < 0 || b < 0) {
        croak("negative args");
    }
CODE:
    RETVAL = a + b;
OUTPUT:
    RETVAL
END
    my $out = Eshu->indent_xs($in);
    like($out, qr/\tINIT:/,    'XS: INIT label indented');
    like($out, qr/\tCODE:/,    'XS: CODE label indented');
    like($out, qr/\tOUTPUT:/,  'XS: OUTPUT label indented');
}

# ── XML: real-world patterns ──────────────────────────────────────────────

# XSLT stylesheet
{
    my $in = <<'END';
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<html>
<body>
<xsl:apply-templates/>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
END
    my $out = Eshu->indent_xml($in);
    like($out, qr/^\t<xsl:template/m, 'XML/XSLT: template tag indented');
    like($out, qr/^\t\t<html>/m,      'XML/XSLT: html tag double-indented');
}

# ── CSS: real-world patterns ──────────────────────────────────────────────

# Media query + custom properties
{
    my $in = <<'END';
:root {
--color-primary: #333;
--spacing-md: 16px;
}
@media (max-width: 768px) {
.container {
padding: var(--spacing-md);
font-size: 14px;
}
}
END
    my $exp = <<'END';
:root {
	--color-primary: #333;
	--spacing-md: 16px;
}
@media (max-width: 768px) {
	.container {
		padding: var(--spacing-md);
		font-size: 14px;
	}
}
END
    is(Eshu->indent_css($in), $exp, 'CSS: :root custom props + media query');
}

# ── JavaScript: real-world patterns ───────────────────────────────────────

# Async/await with try/catch
{
    my $in = <<'END';
async function fetchUser(id) {
try {
const resp = await fetch(`/api/users/${id}`);
if (!resp.ok) {
throw new Error(`HTTP ${resp.status}`);
}
return await resp.json();
} catch (err) {
console.error('fetch failed:', err);
return null;
}
}
END
    my $exp = <<'END';
async function fetchUser(id) {
	try {
		const resp = await fetch(`/api/users/${id}`);
		if (!resp.ok) {
			throw new Error(`HTTP ${resp.status}`);
		}
		return await resp.json();
	} catch (err) {
		console.error('fetch failed:', err);
		return null;
	}
}
END
    is(Eshu->indent_js($in), $exp, 'JS: async/await with try/catch');
}

# Class with private field and method
{
    my $in = <<'END';
class Counter {
#count = 0;
constructor(start = 0) {
this.#count = start;
}
increment() {
this.#count++;
return this;
}
get value() {
return this.#count;
}
}
END
    my $exp = <<'END';
class Counter {
	#count = 0;
	constructor(start = 0) {
		this.#count = start;
	}
	increment() {
		this.#count++;
		return this;
	}
	get value() {
		return this.#count;
	}
}
END
    is(Eshu->indent_js($in), $exp, 'JS: class with private field and accessor');
}

# ── POD: real-world patterns ──────────────────────────────────────────────

# Full module POD skeleton
{
    my $in = <<'END';
=head1 NAME

Foo::Bar - does something useful

=head1 SYNOPSIS

    use Foo::Bar;
    my $obj = Foo::Bar->new(x => 1);
    print $obj->value;

=head1 DESCRIPTION

A helpful module.

=head2 new

    my $obj = Foo::Bar->new(%args);

Constructor. Accepts key/value pairs.

=head1 AUTHOR

Someone

=cut
END
    my $out = Eshu->indent_pod($in);
    like($out, qr/^=head1 NAME/m,     'POD: =head1 at col 0');
    like($out, qr/^\tuse Foo::Bar;/m, 'POD: verbatim block indented');
    like($out, qr/^=head2 new/m,      'POD: =head2 at col 0');
}
