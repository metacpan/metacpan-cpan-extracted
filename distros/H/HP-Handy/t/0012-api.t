######################################################################
#
# 0012-api.t -- Public API tests
#
# Tests new(), render_string(), render_file(), add_filter(),
# add_test(), custom delimiters, and error handling.
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

sub wf {
    my ($dir, $name, $content) = @_;
    open(APIWF, '>' . File::Spec->catfile($dir, $name)) or die $!;
    print APIWF $content;
    close APIWF;
}

my @tests = (

    # --- new() defaults ---
    sub {
        my $hp = HP::Handy->new();
        ok(ref($hp) eq 'HP::Handy', 'new: returns HP::Handy object');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->{auto_escape},  1, 'new: auto_escape default 1');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->{trim_blocks},  0, 'new: trim_blocks default 0');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->{lstrip_blocks},0, 'new: lstrip_blocks default 0');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->{template_dir}, '.', 'new: template_dir default dot');
    },

    # --- new() options ---
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        is($hp->{auto_escape}, 0, 'new: auto_escape => 0');
    },
    sub {
        my $hp = HP::Handy->new(trim_blocks => 1);
        is($hp->{trim_blocks}, 1, 'new: trim_blocks => 1');
    },
    sub {
        my $hp = HP::Handy->new(template_dir => '/tmp');
        is($hp->{template_dir}, '/tmp', 'new: template_dir set');
    },

    # --- render_string() ---
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        is($hp->render_string('hello', {}), 'hello', 'render_string: literal');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        is($hp->render_string('{{ x }}', {x=>'world'}), 'world', 'render_string: variable');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        is($hp->render_string('{{ x }}', {}), '', 'render_string: undefined var is empty');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        # vars default to {} when omitted
        my $r = $hp->render_string('hello');
        is($r, 'hello', 'render_string: vars optional');
    },

    # --- render_file() ---
    sub {
        my $d = _make_tmpdir();
        wf($d, 'hello.html', 'Hello, {{ name }}!');
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        is($hp->render_file('hello.html', {name=>'World'}), 'Hello, World!', 'render_file: basic');
    },
    sub {
        my $d = _make_tmpdir();
        wf($d, 't.html', '{{ x }}');
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        is($hp->render_file('t.html', {}), '', 'render_file: undefined var');
    },
    sub {
        my $d = _make_tmpdir();
        my $hp = HP::Handy->new(template_dir => $d, auto_escape => 0);
        my $err = '';
        eval { $hp->render_file('missing.html', {}) };
        $err = $@ if $@;
        ok($err ne '', 'render_file: missing file dies');
    },

    # --- path traversal blocked ---
    sub {
        my $hp = HP::Handy->new();
        my $err = '';
        eval { $hp->render_file('../etc/passwd', {}) };
        $err = $@ if $@;
        ok($err =~ /traversal/i || $err ne '', 'render_file: path traversal blocked');
    },

    # --- add_filter() ---
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        $hp->add_filter(double => sub { $_[0] * 2 });
        is($hp->render_string('{{ x|double }}', {x=>5}), '10', 'add_filter: custom numeric');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        $hp->add_filter(shout => sub { uc($_[0]) . '!' });
        is($hp->render_string('{{ x|shout }}', {x=>'hi'}), 'HI!', 'add_filter: custom string');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        $hp->add_filter(repeat => sub { $_[0] x ($_[1]||2) });
        is($hp->render_string('{{ x|repeat(3) }}', {x=>'ab'}), 'ababab', 'add_filter: with arg');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        my $ret = $hp->add_filter(noop => sub { $_[0] });
        ok(ref($ret) eq 'HP::Handy', 'add_filter: returns $self for chaining');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        my $err = '';
        eval { $hp->add_filter(bad => 'notaref') };
        $err = $@ if $@;
        ok($err ne '', 'add_filter: non-coderef dies');
    },

    # --- add_test() ---
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        $hp->add_test(positive => sub { defined $_[0] && $_[0] > 0 });
        is($hp->render_string('{% if x is positive %}yes{% endif %}', {x=>5}), 'yes', 'add_test: custom test true');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        $hp->add_test(positive => sub { defined $_[0] && $_[0] > 0 });
        is($hp->render_string('{% if x is positive %}yes{% else %}no{% endif %}', {x=>-1}), 'no', 'add_test: custom test false');
    },

    # --- custom delimiters ---
    sub {
        my $hp = HP::Handy->new(auto_escape=>0, var_start=>'[[', var_end=>']]');
        is($hp->render_string('[[ x ]]', {x=>'hi'}), 'hi', 'custom delimiters: var');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape=>0, block_start=>'<%', block_end=>'%>');
        is($hp->render_string('<% if 1 %>yes<% endif %>', {}), 'yes', 'custom delimiters: block');
    },

    # --- multiple render_string calls reuse object ---
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        my $r1 = $hp->render_string('{{ x }}', {x=>'A'});
        my $r2 = $hp->render_string('{{ x }}', {x=>'B'});
        is("$r1$r2", 'AB', 'reuse: two calls produce independent results');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        $hp->render_string('{% set x = 99 %}', {});
        my $r = $hp->render_string('{{ x }}', {});
        is($r, '', 'reuse: state reset between calls');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
print "# $PASS passed, $FAIL failed\n";
