#!perl
use strict;
use warnings;
use Test::More 0.96;

use 5.006;

use File::stat::Extra;
use Cwd;
use File::Spec;

my $testfile = "corpus/testfile";
my $testlink;

if (defined eval { &{"Fcntl::S_IFLNK"} } && eval { symlink('',''); 1 }) {
    # Create symlink
    $testlink = "corpus/testlink.tmp";
    symlink "testfile", "$testlink" or die "Couldn't create symlink $testlink for $testfile: $!";
}

END {
    # Remove symlink
    unlink("$testlink") or die "Unable to remove $testlink: $!" if $testlink && -l "$testlink";
}

sub diagnose {
    my $txt = "";

    for my $st (@_) {
        if (ref $st) {
            $txt .= sprintf("File=%s, dev=%d, ino=%d,\nmode=%06o (type=%06o, perms=%06o),\nnlink=%d, uid=%s, gid=%s, rdev=%s, size=%d,\natime=%s, mtime=%s, ctime=%s,\nblksize=%d, blocks=%d\n",
                            $st->file, $st->dev, $st->ino, $st->mode, $st->filetype, $st->permissions, $st->nlink,
                            $st->uid, $st->gid, $st->rdev, $st->size,
                            scalar localtime($st->atime), scalar localtime($st->mtime), scalar localtime($st->ctime),
                            $st->blksize || 0, $st->blocks || 0);
            $txt .= 'Object=' . join('', explain($st));
        } else {
            $txt .= $st;
        }
    }
    return diag($txt);
}

sub main_tests {
    my $file = shift;
    my $type = shift;

    $type = $type ? " ($type)" : "";

    open FH, "<$file" or die "Unable to open $file$type";

    my $st      = stat($file);
    my @st      = stat($file);
    my @_st     = CORE::stat($file);

    my $stfh    = stat(FH);
    my @stfh    = stat(FH);
    my @_stfh   = CORE::stat(FH);

    my $st_fh   = stat(*FH);
    my @st_fh   = stat(*FH);
    my @_st_fh  = CORE::stat(*FH);

    my $lst     = lstat($file);
    my @lst     = lstat($file);
    my @l_st    = CORE::lstat($file);

    is_deeply \@st,     \@_st,     "List context should return same result as original stat for file$type";
    is_deeply \@stfh,   \@_stfh,   "List context should return same result as original stat for file handle$type";
    is_deeply \@st_fh,  \@_st_fh,  "List context should return same result as original stat for *file handle$type";
    is_deeply \@lst,    \@l_st,    "List context should return same result as original lstat for file$type";

    is_deeply [
        $st->dev, $st->ino, $st->mode, $st->nlink,
        $st->uid, $st->gid, $st->rdev, $st->size,
        $st->atime, $st->mtime, $st->ctime,
        $st->blksize, $st->blocks
    ], \@_st, "Accessors should return same results as original stat of file$type";

    is_deeply [
        $lst->dev, $lst->ino, $lst->mode, $lst->nlink,
        $lst->uid, $lst->gid, $lst->rdev, $lst->size,
        $lst->atime, $lst->mtime, $lst->ctime,
        $lst->blksize, $lst->blocks
    ], \@l_st, "Accessors return same results as original lstat of file$type";

    is $st->permissions, $_st[2] & 07777, "Permissions Ok$type";
    is $st->filetype,  $_st[2] & 0770000, "Type Ok$type";

    is $st->file, File::Spec->rel2abs($file), "File$type points to same file (relative)";
    is $st->target, Cwd::abs_path($testfile), "Target$type points to same file (absolute)";
}

plan tests => 4;

subtest "Main tests on a file" => sub { main_tests($testfile); };

SKIP: {
    skip 'symlinks not supported by OS', 1 if !$testlink;

    subtest 'Main tests on a link' => sub { main_tests($testlink, 'symlink'); };
}

subtest 'Filetests on a file and directory' => sub {
    my $st  = stat($testfile);
    my $lst = lstat($testfile);
    my $std = stat('corpus');

    ok(-f $testfile,   'testfile is a regular file (normal filetest)');
    ok($st->isRegular, 'testfile is a regular file (object)') or diagnose($st);
    ok(!$st->isLink,   'testfile is not a link (stat, object)') or diagnose($st);
    ok(!$lst->isLink,  'testfile is not a link (lstat, object)') or diagnose($lst);

    ok(-d 'corpus',    'corpus is a directory (normal filetest)');
    ok($std->isDir,    'corpus is a directory (object)') or diagnose($std);

    ok(!$st->isPipe,   'testfile is not a pipe (object)') or diagnose($st);
    ok(!$st->isSocket, 'testfile is not a socket (object)') or diagnose($st);
    ok(!$st->isBlock,  'testfile is not a block (object)') or diagnose($st);
    ok(!$st->isChar,   'testfile is not a char (object)') or diagnose($st);

  SKIP: {
        skip 'filetests not overloadable on Perl < v5.12.0', 8 if $^V < 5.012;

        ok(-d $std,          'corpus is a directory (object filetest)') or diagnose($std);

        ok(-f $st,           'testfile is a regular file (object filetest)') or diagnose($st);
        ok(!-t $st,          'testfile is not connected to a tty (object filetest)') or diagnose($st);
        ok(-T $st,           'testfile is a text file (object filetest)') or diagnose($st);
        ok(-B $st,           'testfile is a binary file (object filetest)') or diagnose($st);

        ok(defined $st->[2], '-t is cached') or diagnose($st);
        ok(defined $st->[3], '-T is cached') or diagnose($st);
        ok(defined $st->[4], '-B is cached') or diagnose($st);
    }

  SKIP: {
        skip 'symlinks not supported by OS', 4 if !$testlink;

        my $stl = stat($testlink);
        my $lstl = lstat($testlink);

        ok(-l $testlink,  'testlink is a link (normal filetest)');
        ok(!$stl->isLink, 'testlink is not a link (stat, object)') or diagnose($stl);
        ok($lstl->isLink, 'testlink is a link (lstat, object)') or diagnose($lstl);

      SKIP: {
            skip 'filetests not overloadable on Perl < v5.12.0', 1 if $^V < 5.012;

            ok(-l $lstl,      'testlink is a link (lstat, object filetest)') or diagnose($lstl);
        }
    }
};

subtest 'File / link equality tests' => sub {
    my $st  = stat($testfile);
    my $lst = lstat($testfile);

    cmp_ok($st, '==', $lst,  'testfile represents the same file (stat vs lstat, numeric)') or diagnose($st, $lst);
    cmp_ok($st, 'eq', $lst,  'testfile represents the same file (stat vs lstat, string)')  or diagnose($st, $lst);

  SKIP: {
        skip 'symlinks not supported by OS', 4 if !$testlink;

        my $stl = stat($testlink);
        my $lstl = lstat($testlink);

        cmp_ok($st, '==', $stl,  'testfile and resolved testlink represent the same file (numeric)')
            or diagnose($st, $stl);
        cmp_ok($st, 'eq', $stl,  'testfile and resolved testlink represent the same file (string)')
            or diagnose($st, $stl);
        cmp_ok($st, '!=', $lstl, 'testfile and unresolved testlink do not represent the same file (numeric)')
            or diagnose($st, $lstl);
        cmp_ok($st, 'ne', $lstl, 'testfile and unresolved testlink do not represent the same file (string)')
            or diagnose($st, $lstl);
    }
};
