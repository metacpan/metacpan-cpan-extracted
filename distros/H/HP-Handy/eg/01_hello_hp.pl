######################################################################
#
# 01_hello_hp.pl - HP::Handy basic usage examples
#
# Run: perl eg/01_hello_hp.pl
#
# Demonstrates:
#   render_string, render_file, add_filter, add_test
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec ();

use lib 'lib';
use HP::Handy;

my $tmpl = HP::Handy->new(auto_escape => 1);

######################################################################
# Example 1: Variable substitution and filters
######################################################################
print "=== Example 1: Variables and Filters ===\n";

my $src1 = <<'TMPL';
Name: {{ name }}
Upper: {{ name | upper }}
Escaped: {{ snippet }}
Default: {{ missing | default("(none)") }}
TMPL

print $tmpl->render_string($src1, {
    name    => 'HP::Handy',
    snippet => '<script>alert(1)</script>',
});

######################################################################
# Example 2: For loop with loop variable
######################################################################
print "\n=== Example 2: For Loop ===\n";

my $src2 = <<'TMPL';
{% for item in items %}
{{ loop.index }}. {{ item }}{% if loop.last %} (last){% endif %}
{% endfor %}
TMPL

print $tmpl->render_string($src2, {
    items => [ 'Perl', 'Python', 'Ruby' ],
});

######################################################################
# Example 3: If / elif / else
######################################################################
print "\n=== Example 3: Conditional ===\n";

for my $score (95, 75, 55) {
    my $src3 = <<'TMPL';
Score {{ score }}: {% if score >= 90 %}A{% elif score >= 70 %}B{% else %}C{% endif %}
TMPL
    print $tmpl->render_string($src3, { score => $score });
}

######################################################################
# Example 4: Template inheritance (via string)
######################################################################
print "\n=== Example 4: Inheritance-style block rendering ===\n";

# In real use, base.html and child.html are files.
# Here we demonstrate block override via render_string.
my $base = <<'BASE';
<html><head><title>{% block title %}Default Title{% endblock %}</title></head>
<body>{% block content %}(no content){% endblock %}</body></html>
BASE

my $child = <<'CHILD';
{% extends "base.html" %}
{% block title %}My Custom Page{% endblock %}
{% block content %}<h1>Hello from child</h1>{% endblock %}
CHILD

# Write base to a temp file for extends to resolve
my $tmpdir = File::Spec->catfile(File::Spec->tmpdir(), "hp_eg01_$$");
mkdir($tmpdir, 0777);
open(TF, '>' . File::Spec->catfile($tmpdir, 'base.html')) or die $!;
print TF $base;
close TF;

my $tmpl2 = HP::Handy->new(template_dir => $tmpdir, auto_escape => 0);
print $tmpl2->render_string($child, {});
print "\n";

# Cleanup
unlink File::Spec->catfile($tmpdir, 'base.html');
rmdir $tmpdir;

######################################################################
# Example 5: Macro
######################################################################
print "\n=== Example 5: Macro ===\n";

my $src5 = <<'TMPL';
{% macro button(label, type="button") %}<button type="{{ type }}">{{ label }}</button>{% endmacro %}
{{ button("Submit", "submit") }}
{{ button("Cancel") }}
TMPL

print $tmpl->render_string($src5, {});
print "\n";

######################################################################
# Example 6: Custom filter
######################################################################
print "\n=== Example 6: Custom Filter ===\n";

$tmpl->add_filter('commify', sub {
    my $n = defined $_[0] ? $_[0] : '';
    my @parts;
    while ($n =~ s/(\d)(\d{3})(?=\.|,|$)/$1,$2/) {}
    $n
});

print $tmpl->render_string('{{ price | commify }}', { price => '1234567' });
print "\n";
