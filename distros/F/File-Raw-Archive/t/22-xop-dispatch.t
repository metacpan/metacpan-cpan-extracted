#!perl
# Custom-op accessor verification: confirm the XOP rewriting in BOOT
# produces the right values for static method calls AND that dynamic
# dispatch falls through to the XSUB cleanly (the call checker bails
# when it can't tell at compile time which CV is being called).
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/xop.tar";

my $w = File::Raw::Archive->create($tar);
$w->add(
    name     => 'a.bin',
    content  => 'A' x 100,
    mode     => 0640,
    mtime    => 1700000000,
    mtime_ns => 500_000_000,
    uid      => 1234,
    gid      => 5678,
);
$w->add(name => 'd/');
$w->add(name => 'l', link_target => 'a.bin');
$w->close;

my $r = File::Raw::Archive->open($tar);

# --- Static call sites: should be XOP-rewritten ---
my $file = $r->next;

# Each accessor returns the right value via the pp_entry_accessor handler.
is($file->name,        'a.bin',     'static name');
is($file->size,        100,         'static size');
is($file->mode,        0640,        'static mode');
is($file->mtime,       1700000000,  'static mtime');
is($file->mtime_ns,    500_000_000, 'static mtime_ns');
is($file->uid,         1234,        'static uid');
is($file->gid,         5678,        'static gid');
is($file->type,        File::Raw::Archive::AE_FILE(), 'static type');
is($file->link_target, undef,       'static link_target undef');
is($file->is_sparse,   0,           'static is_sparse');

# Predicates via pp_entry_predicate.
ok( $file->is_file,    'static is_file');
ok(!$file->is_dir,     'static is_dir false on file');
ok(!$file->is_symlink, 'static is_symlink false on file');
ok(!$file->is_link,    'static is_link false on file');

$file->slurp;   # consume payload before $r->next

my $dirent = $r->next;
ok( $dirent->is_dir,     'dir: is_dir true');
ok(!$dirent->is_file,    'dir: is_file false');
is( $dirent->type, File::Raw::Archive::AE_DIR(), 'dir: type=AE_DIR');

my $sym = $r->next;
ok( $sym->is_symlink,    'sym: is_symlink true');
ok( $sym->is_link,       'sym: is_link true');
is( $sym->link_target, 'a.bin', 'sym: link_target');

# --- Dynamic dispatch: XOP shouldn't fire; XSUB path runs ---
# The compiler can't see the method name at compile time, so the call
# checker has nothing to rewrite. The standard ENTERSUB -> XSUB path
# must still produce the right answer.
$r->close;
$r = File::Raw::Archive->open($tar);
my $e = $r->next;

for my $method (qw(name size mode mtime mtime_ns uid gid type is_sparse)) {
    my $static = $e->$method;            # XOP-rewritten at compile time
    my $dynamic = $e->${\ $method };     # forces method dispatch
    is($dynamic, $static, "dynamic dispatch matches static for $method");
}

for my $pred (qw(is_file is_dir is_symlink is_link)) {
    my $static  = $e->$pred ? 1 : 0;
    my $dynamic = $e->${\ $pred } ? 1 : 0;
    is($dynamic, $static, "dynamic dispatch matches static for $pred");
}

$r->close;

# --- Call checker bails on extra args; XSUB takes over ---
# `$entry->name(99)` has an extra arg. Our checker bails (returns the
# unchanged entersubop). The XSUB then runs and either ignores the
# extras and returns the value, or croaks with a Usage message. Either
# is fine - we just have to not segfault on the unexpected call form.
$r = File::Raw::Archive->open($tar);
my $e2 = $r->next;
my $name_with_extra = eval { $e2->name(99, 'extra') };
my $extra_err = $@;
ok(defined($name_with_extra) || $extra_err,
    'extra args: XSUB returns a value or croaks (no segfault)');
if (defined $name_with_extra) {
    is($name_with_extra, 'a.bin',
        'extra args: XSUB ignored them and returned attribute');
} else {
    like($extra_err, qr/Entry|name|Usage/i,
        'extra args: croak mentions the method or Usage');
}
$r->close;

# --- Calling accessor on a non-Entry should return undef cleanly ---
my $bogus = bless [], 'File::Raw::Archive::Entry';
my $bogus_name = eval { $bogus->name };
ok(!$@, 'name on empty Entry-blessed AV does not croak');
is($bogus_name, undef, 'name on empty Entry-blessed AV returns undef');

done_testing;
