#!/usr/bin/env perl
# k163: errors in a .pk8s manifest name the manifest's file and line, and
# the manifest sees none of the loader's variables.
#
# The manifest was evaluated behind one generated DSL sub per known Kind,
# so a `die` in its third line came out as "boom at (eval 273) line 1848",
# a syntax error likewise, and a warning too. The eval also ran inside
# IO::K8s::Manifest::_load_file, so the manifest saw that sub's lexicals:
# `$file`, `$k8s`, `$vars` and the collector `$m` compiled under
# `use strict` and silently reached into the loader.
#
# Approved contract:
#   * die, warn, a syntax error, a var() without value and an error IO::K8s
#     croaks with for a Kind call (a field of the wrong shape) in line N of
#     the manifest report "<file> line N";
#   * a name the #line directive cannot carry -- a double quote, a line
#     break, anything outside printable ASCII -- still gets the right line
#     number, and the "Error loading <file>:" prefix still names the file;
#   * the loader's lexicals are not visible: a manifest using $file, $m,
#     $k8s, $vars, $content or $pkg fails to compile under use strict, and
#     @_ is empty at the manifest's top level;
#   * the k160 behaviour (t/116) is unchanged.
#
# Pure local fixtures in a temporary directory -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Tiny qw(tempdir);
use lib 'lib';

use IO::K8s;
use IO::K8s::Manifest;

my $dir = tempdir();
my $k8s = IO::K8s->new;

sub pk8s {
    my ($name, $code) = @_;
    my $file = $dir->child($name);
    $file->spew_utf8($code);
    return "$file";
}

sub loader_packages { sort grep { /\A_LOADER_/ } keys %IO::K8s::Manifest:: }

# ===========================================================================
# RED: file and line of the manifest
# ===========================================================================

# Claim: a die in line 3 of the manifest reports that file and line 3.
subtest 'die reports the manifest file and line' => sub {
    my $file = pk8s('die.pk8s', <<'PK8S');
ConfigMap { name => 'a' };

die "boom";
PK8S
    throws_ok { $k8s->load($file) } qr/boom at \Q$file\E line 3\./, 'file and line 3';
};

# Claim: line numbers start at 1, not after the generated DSL code.
subtest 'an error in line 1 reports line 1' => sub {
    my $file = pk8s('first.pk8s', "die 'first';\n");
    throws_ok { $k8s->load($file) } qr/first at \Q$file\E line 1\./, 'line 1';
};

# Claim: a syntax error names the file and the line it is in.
subtest 'a syntax error reports the manifest file and line' => sub {
    my $file = pk8s('syntax.pk8s', <<'PK8S');
ConfigMap { name => 'a' };
my $x = ;
ConfigMap { name => 'b' };
PK8S
    throws_ok { $k8s->load($file) } qr/syntax error at \Q$file\E line 2\b/, 'file and line 2';
    unlike($@, qr/\(eval \d+\)/, 'no eval pseudo-file');
};

# Claim: a warning names the file and line too.
subtest 'a warning reports the manifest file and line' => sub {
    my $file = pk8s('warn.pk8s', <<'PK8S');
ConfigMap { name => 'a' };
warn "careful";
PK8S
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $k8s->load($file);
    is(scalar @warnings, 1, 'one warning');
    like($warnings[0], qr/careful at \Q$file\E line 2\./, 'file and line 2');
};

# Claim: an error IO::K8s raises for a Kind call -- a field of the wrong
# shape -- reports the manifest line of that call, not the generated Kind
# function it passed through.
subtest 'an inflation error reports the manifest line of the Kind call' => sub {
    my $file = pk8s('shape.pk8s', <<'PK8S');
ConfigMap { name => 'a' };

ConfigMap { name => 'b', data => 'x' };
PK8S
    throws_ok { $k8s->load($file) }
        qr/Cannot inflate \S+ConfigMap field data: .* at \Q$file\E line 3\./, 'file and line 3';
    unlike($@, qr/\(eval \d+\)|Manifest\.pm/, 'neither the generated code nor the loader');
};

# Claim: var() without a value reports the line that asked for it.
subtest 'a var() without value reports the manifest line' => sub {
    my $file = pk8s('var.pk8s', <<'PK8S');
ConfigMap { name => 'a' };
ConfigMap {
    name => var('nope'),
};
PK8S
    throws_ok { $k8s->load($file) } qr/'nope'.* at \Q$file\E line 3\./s, 'file and the line of the call';
};

# ===========================================================================
# Names #line cannot carry
# ===========================================================================

# Claim: a file name with a double quote, a line break or non-ASCII bytes
# (a UTF-8 name as it arrives from @ARGV) still loads, the line number is
# still right, and the prefix still names the file.
subtest 'names #line cannot carry keep the line number' => sub {
    for my $name (qq{quo"te.pk8s}, qq{new\nline.pk8s}, "caf\xc3\xa9.pk8s") {
        (my $label = $name) =~ s/\n/\\n/g;
        my $file = eval { pk8s($name, "ConfigMap { name => 'fine' };\n") };
        SKIP: {
            skip "file system refuses '$label'", 2 unless defined $file && -f $file;
            is($k8s->load($file)->[0]->metadata->name, 'fine', "$label: loads");
            pk8s($name, "ConfigMap { name => 'a' };\ndie 'odd';\n");
            throws_ok { $k8s->load($file) } qr/\AError loading \Q$file\E: odd at .*? line 2\./s,
                "$label: prefix names the file, the line is right";
        }
    }
    is_deeply([ loader_packages() ], [], 'no package left');
};

# ===========================================================================
# RED: the loader's lexicals are not visible
# ===========================================================================

# Claim: each of the loader's variables is undeclared in the manifest, so
# use strict refuses it instead of the manifest reaching into the loader.
subtest 'the loader lexicals are not visible to the manifest' => sub {
    for my $var (qw($file $m $k8s $vars $content $pkg $leaf $class $eval_code $_collector)) {
        my $file = pk8s('lex.pk8s', "ConfigMap { name => 'x' . ref(\\$var) };\n");
        throws_ok { $k8s->load($file) }
            qr/Global symbol "\Q$var\E" requires explicit package name/, "$var is undeclared";
    }
    is_deeply([ loader_packages() ], [], 'no package left');
};

# Claim: @_ at the manifest's top level is empty -- it does not carry the
# manifest's own source or the loader's arguments.
subtest '@_ is empty at the manifest top level' => sub {
    my $file = pk8s('args.pk8s', "my \$n = \@_;\nConfigMap { name => 'args-' . \$n };\n");
    my ($cm) = @{ $k8s->load($file) };
    is($cm->metadata->name, 'args-0', 'no arguments');
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: a well-formed manifest still loads, with helpers, a package
# variable and var().
subtest 'GUARD: a working manifest still loads' => sub {
    my $file = pk8s('ok.pk8s', <<'PK8S');
our $prefix = 'web';
sub name_for { $prefix . '-' . $_[0] }
ConfigMap { name => name_for('a'), data => { k => var('v', 'dflt') } };
ConfigMap { name => name_for('b') };
PK8S
    my $objs = $k8s->load($file, vars => { v => 'given' });
    is(scalar @$objs, 2, 'two objects');
    is($objs->[0]->metadata->name, 'web-a', 'helper and package variable');
    is($objs->[0]->data->{k}, 'given', 'var()');
    is_deeply([ loader_packages() ], [], 'no package left');
};

# Claim: a manifest that ends in __END__ still loads -- nothing is appended
# to its source.
subtest 'GUARD: __END__ in a manifest still works' => sub {
    my $file = pk8s('end.pk8s', "ConfigMap { name => 'e' };\n__END__\nnot perl at all {\n");
    my $objs = $k8s->load($file);
    is($objs->[0]->metadata->name, 'e', 'loaded up to __END__');
};

done_testing;
