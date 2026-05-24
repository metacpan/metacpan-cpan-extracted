######################################################################
#
# 0008-inheritance.t -- Template inheritance, include, and macro tests
#
# Tests {% extends %}, {% block %}, {% include %}, {% macro %}
# All tests use a closure array for dynamic plan count.
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec;
use HP::Handy;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c?($PASS++,print "ok $T - $n\n"):($FAIL++,print "not ok $T - $n\n") }
sub is { my($g,$e,$n)=@_; $T++;
    defined($g) && "$g" eq "$e"
        ? ($PASS++, print "ok $T - $n\n")
        : ($FAIL++, print "not ok $T - $n  (got='".( defined $g?$g:'undef')."', exp='$e')\n") }

# Perl 5.005_03 compatible temp directory (no File::Temp)
my @_tmpdirs;
my $_tmpdir_seq = 0;
sub _make_tmpdir {
    my $base = File::Spec->tmpdir();
    my $dir;
    my $try = 0;
    while ($try < 100) {
        $_tmpdir_seq++;
        $dir = File::Spec->catfile($base,
            "hpt_$$" . "_" . $_tmpdir_seq . "_" . $try);
        last if mkdir($dir, 0700);
        $try++;
    }
    die "cannot create tmpdir under $base: $!" unless defined $dir && -d $dir;
    push @_tmpdirs, $dir;
    return $dir;
}
END {
    for my $d (reverse @_tmpdirs) {
        next unless defined $d && -d $d;
        opendir(RMDIR_DH, $d) or next;
        my @entries = grep { $_ ne '.' && $_ ne '..' } readdir(RMDIR_DH);
        closedir(RMDIR_DH);
        unlink File::Spec->catfile($d, $_) for @entries;
        rmdir $d;
    }
}

# Helper: write file
sub wf {
    my ($dir, $name, $content) = @_;
    my $path = File::Spec->catfile($dir, $name);
    open(INHWF, "> $path") or die "cannot write $path: $!";
    print INHWF $content;
    close INHWF;
}

# Helper: render_string with auto_escape off
sub rs {
    my ($tmpl, $vars) = @_;
    $vars = {} unless defined $vars;
    my $hp = HP::Handy->new(auto_escape => 0);
    my $r = $hp->render_string($tmpl, $vars);
    return defined $r ? $r : '';
}

# Helper: render_file from tmpdir
sub rf {
    my ($dir, $file, $vars) = @_;
    $vars = {} unless defined $vars;
    my $hp = HP::Handy->new(template_dir => $dir, auto_escape => 0);
    my $r = $hp->render_file($file, $vars);
    return defined $r ? $r : '';
}

my @tests = (

    # --- block (standalone, no extends) ---
    sub { is(rs('{% block b %}hello{% endblock %}'),       '',      'block standalone: stripped') },
    sub { is(rs('A{% block b %}x{% endblock %}B'),         'AB',    'block standalone: outer text preserved') },
    sub { is(rs("A{% block b %}x{% endblock %}B"),         'AB',    'block standalone: no whitespace added') },

    # --- extends + block ---
    sub {
        my $d = _make_tmpdir();
        wf($d, 'base.html', 'HEAD{% block body %}default{% endblock %}TAIL');
        wf($d, 'child.html', '{% extends "base.html" %}{% block body %}CHILD{% endblock %}');
        is(rf($d, 'child.html'), 'HEADCHILDTAIL', 'extends: basic block override');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'base.html', '{% block title %}Default{% endblock %}|{% block body %}Body{% endblock %}');
        wf($d, 'child.html', '{% extends "base.html" %}{% block title %}MyPage{% endblock %}');
        is(rf($d, 'child.html'), 'MyPage|Body', 'extends: partial override keeps default block');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'base.html', 'X{% block a %}A{% endblock %}Y{% block b %}B{% endblock %}Z');
        wf($d, 'child.html', '{% extends "base.html" %}{% block a %}AA{% endblock %}{% block b %}BB{% endblock %}');
        is(rf($d, 'child.html'), 'XAAYBBZ', 'extends: two blocks overridden');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'base.html', '<title>{% block title %}Default{% endblock %}</title>');
        wf($d, 'child.html', '{% extends "base.html" %}{% block title %}{{ page }}{% endblock %}');
        is(rf($d, 'child.html', {page=>'Home'}), '<title>Home</title>', 'extends: block contains variable');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'base.html', 'H{% block content %}DEFAULT{% endblock %}F');
        wf($d, 'child.html', '{% extends "base.html" %}{% block content %}{% for x in items %}{{ x }}{% endfor %}{% endblock %}');
        is(rf($d, 'child.html', {items=>['a','b','c']}), 'HabcF', 'extends: block with for loop');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'base.html', 'H{% block body %}{% endblock %}F');
        wf($d, 'mid.html',  '{% extends "base.html" %}{% block body %}M{% block inner %}I{% endblock %}{% endblock %}');
        wf($d, 'leaf.html', '{% extends "mid.html" %}{% block inner %}LEAF{% endblock %}');
        is(rf($d, 'leaf.html'), 'HMLEAFF', 'extends: three-level inheritance');
    },

    # --- include ---
    sub {
        my $d = _make_tmpdir();
        wf($d, 'header.html', '<header>TOP</header>');
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        is($hp->render_string('{% include "header.html" %}BODY', {}), '<header>TOP</header>BODY', 'include: basic');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'nav.html', 'NAV:{{ title }}');
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        is($hp->render_string('{% include "nav.html" %}', {title=>'HOME'}), 'NAV:HOME', 'include: parent context passed');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'part.html', '[PART]');
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        is($hp->render_string('A{% include "part.html" %}B', {}), 'A[PART]B', 'include: inline between text');
    },
    sub {
        my $d = _make_tmpdir();
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        is($hp->render_string('A{% include "missing.html" ignore missing %}B', {}), 'AB', 'include: ignore missing');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'item.html', '{{ loop.index }}:{{ item }}');
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        my $r = $hp->render_string('{% for item in items %}{% include "item.html" %}{% endfor %}', {items=>['a','b','c']});
        is($r, '1:a2:b3:c', 'include: inside for loop');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 'a.html', 'A{% include "b.html" %}A');
        wf($d, 'b.html', 'B');
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        is($hp->render_file('a.html', {}), 'ABA', 'include: nested include');
    },

    # --- macro ---
    sub { is(rs('{% macro hi() %}Hello{% endmacro %}{{ hi() }}'),              'Hello',    'macro: no-arg') },
    sub { is(rs('{% macro greet(name) %}Hi {{ name }}{% endmacro %}{{ greet("World") }}'), 'Hi World', 'macro: one arg') },
    sub { is(rs('{% macro add(a, b) %}{{ a + b }}{% endmacro %}{{ add(3, 4) }}'),          '7',        'macro: two numeric args') },
    sub { is(rs('{% macro f(x, sep="-") %}{{ x }}{{ sep }}{% endmacro %}{{ f("A") }}'),    'A-',       'macro: default arg used') },
    sub { is(rs('{% macro f(x, sep="-") %}{{ x }}{{ sep }}{% endmacro %}{{ f("A","+") }}'),'A+',       'macro: default arg overridden') },
    sub {
        my $s = '{% macro rep(s, n) %}{% for i in range(n) %}{{ s }}{% endfor %}{% endmacro %}{{ rep("ab", 3) }}';
        is(rs($s), 'ababab', 'macro: for loop inside macro');
    },
    sub {
        my $s = '{% macro item(label, url) %}<a href="{{ url }}">{{ label }}</a>{% endmacro %}' .
                '{% for x in nav %}{{ item(x.label, x.url) }}{% endfor %}';
        my $vars = {nav=>[{label=>'Home',url=>'/'},{label=>'About',url=>'/about'}]};
        is(rs($s, $vars), '<a href="/">Home</a><a href="/about">About</a>', 'macro: called in for loop');
    },
    sub {
        my $s = '{% macro bold(t) %}<b>{{ t }}</b>{% endmacro %}' .
                '{% macro p(t) %}<p>{{ bold(t) }}</p>{% endmacro %}{{ p("X") }}';
        is(rs($s), '<p><b>X</b></p>', 'macro: macro calling macro');
    },
    sub {
        my $s = '{% macro sum(a, b, c) %}{{ a + b + c }}{% endmacro %}{{ sum(1, 2, 3) }}';
        is(rs($s), '6', 'macro: three args');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
print "# $PASS passed, $FAIL failed\n";
