use strict;
use warnings;
use Test::More tests => 16;
use File::Temp qw(tempdir);
use File::Spec;
use Eshu;

my $dir = tempdir(CLEANUP => 1);

# Helper: write a file
sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    my $c = do { local $/; <$fh> };
    close $fh;
    return $c;
}

# 1. status = unchanged when file is already correctly indented
{
    my $f = File::Spec->catfile($dir, 'clean.pl');
    write_file($f, "sub f {\n\tmy \$x = 1;\n}\n");
    my $r = Eshu->indent_file($f);
    is($r->{status}, 'unchanged', 'unchanged: already correct');
    is($r->{lang},   'perl',      'unchanged: lang detected');
}

# 2. status = needs_fixing (dry-run default)
{
    my $f = File::Spec->catfile($dir, 'messy.pl');
    write_file($f, "sub f {\nmy \$x = 1;\n}\n");
    my $r = Eshu->indent_file($f);
    is($r->{status}, 'needs_fixing', 'dry-run: status is needs_fixing');
    is($r->{lang},   'perl',         'dry-run: lang detected');
    # file not changed
    like(read_file($f), qr/^my \$x = 1;/m, 'dry-run: file not modified');
}

# 3. status = changed with fix => 1
{
    my $f = File::Spec->catfile($dir, 'fix.c');
    write_file($f, "void f() {\nint x;\n}\n");
    my $r = Eshu->indent_file($f, fix => 1);
    is($r->{status}, 'changed', 'fix: status is changed');
    like(read_file($f), qr/^\tint x;/m, 'fix: file modified on disk');
}

# 4. diff => 1 returns diff in result
{
    my $f = File::Spec->catfile($dir, 'diffme.c');
    write_file($f, "void g() {\nint y;\n}\n");
    my $r = Eshu->indent_file($f, diff => 1);
    ok(exists $r->{diff}, 'diff: diff key present in result');
    like($r->{diff}, qr/^\+/m, 'diff: output contains added lines');
}

# 5. force lang override
{
    my $f = File::Spec->catfile($dir, 'ambiguous.txt');
    write_file($f, "sub f {\nmy \$x = 1;\n}\n");
    my $r = Eshu->indent_file($f, lang => 'perl');
    is($r->{lang}, 'perl', 'force lang: lang key reflects forced language');
    is($r->{status}, 'needs_fixing', 'force lang: file processed with forced lang');
}

# 6. status = skipped for unrecognised extension (no force lang)
{
    my $f = File::Spec->catfile($dir, 'data.csv');
    write_file($f, "a,b,c\n1,2,3\n");
    my $r = Eshu->indent_file($f);
    is($r->{status}, 'skipped', 'skipped: unrecognised extension');
    ok(defined $r->{reason}, 'skipped: reason field present');
}

# 7. status = error for non-existent file
{
    my $f = File::Spec->catfile($dir, 'no_such_file.pl');
    my $r = Eshu->indent_file($f);
    is($r->{status}, 'error', 'error: non-existent file');
    ok(defined $r->{error}, 'error: error field present');
}

# 8. status = skipped for binary file (NUL in first 8KB)
{
    my $f = File::Spec->catfile($dir, 'binary.pl');
    open my $fh, '>', $f or die;
    print $fh "sub f {\0\0\0}\n";
    close $fh;
    my $r = Eshu->indent_file($f);
    is($r->{status}, 'skipped', 'skipped: binary file');
}
