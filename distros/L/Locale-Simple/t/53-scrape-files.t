use strict;
use warnings;
use Test::More;

use Test::InDistDir;
use Capture::Tiny 'capture';
use Cwd 'getcwd';
use Digest::MD5 'md5_hex';
use File::Path 'make_path';
use File::Temp 'tempdir';
use Locale::Simple::Scraper 'scrape';

# The scraper names every file by its path relative to the directory it was
# started in: in the #: lines of the .pot, in the file field of the perl,
# json and yaml outputs, and as the input of --md5. The directory name may
# hold characters that mean something in a regex. A symlink pointing nowhere
# is skipped, and the files after it are still read.

my $start = getcwd;

sub write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
    return;
}

sub scrape_in {
    my ( $dir, @argv ) = @_;
    chdir $dir or die "Cannot chdir to $dir: $!";
    my ( $out, $err, $ok ) = capture {
        eval { scrape(@argv); 1 };
    };
    chdir $start or die "Cannot chdir back to $start: $!";
    return ( $out, $err, $ok );
}

sub scrape_entries {
    my ( $dir, @argv ) = @_;
    my ( $out, $err, $ok ) = scrape_in( $dir, @argv, '--output', 'perl' );
    my $VAR1;
    eval $out if $ok;
    return [ sort { $a->{msgid} cmp $b->{msgid} } @{ $VAR1 || [] } ];
}

# Spelled so that t/50, which scrapes this file, finds no calls in it.
my $func = lc 'L';

# The directory name holds characters that mean something in a regex.
my $dir = tempdir( CLEANUP => 1 ) . "/ls+scrape(dir)";
make_path("$dir/sub/deeper");
write_file( "$dir/sub/one.pl",        qq{$func("Path one");\n} );
write_file( "$dir/sub/deeper/two.pl", qq{\n\n$func("Path two");\n} );
write_file( "$dir/top.pl",            qq{$func("Path top");\n} );

my @relative = ( 'sub/deeper/two.pl', 'sub/one.pl', 'top.pl' );

{
    my ( $out, $err, $ok ) = scrape_in( $dir, '--output', 'po' );
    ok( $ok, 'po output: scrape runs' ) or diag $err;
    my @refs = sort map { split ' ' } $out =~ /^#: (.*)$/mg;
    is_deeply(
        \@refs,
        [ 'sub/deeper/two.pl:3', 'sub/one.pl:1', 'top.pl:1' ],
        'po output: #: lines carry paths relative to the start directory'
    ) or diag $out;
    unlike( $out, qr/\Q$dir\E/, 'po output: the start directory does not appear' );
}

{
    my @files = map { $_->{file} } @{ scrape_entries($dir) };
    is_deeply( [ sort @files ], \@relative, 'perl output: file is the relative path' );
}

{
    my @files = map { $_->{file} } @{ scrape_entries( $dir, '--md5' ) };
    is_deeply(
        [ sort @files ],
        [ sort map { md5_hex($_) } @relative ],
        '--md5: file is the MD5 of the relative path'
    );
}

{
    my @files = map { $_->{file} } @{ scrape_entries( $dir, '--ignore', '^sub/' ) };
    is_deeply( \@files, ['top.pl'], '--ignore with ^ matches the relative path' );
}

{
    # Extra extensions add up over repeated options and comma lists alike.
    my $exts = tempdir( CLEANUP => 1 );
    write_file( "$exts/a.foo", qq{$func("Ext foo");\n} );
    write_file( "$exts/b.bar", qq{$func("Ext bar");\n} );
    write_file( "$exts/c.baz", qq{$func("Ext baz");\n} );
    write_file( "$exts/d.qux", qq{$func("Ext qux");\n} );
    is_deeply(
        [ map { $_->{file} } @{ scrape_entries( $exts, '--pl', 'foo', '--pl', 'bar,baz' ) } ],
        [ 'b.bar', 'c.baz', 'a.foo' ],
        '--pl given twice: the extensions of both are read'
    );
}

SKIP: {
    my $symlinks = eval { symlink( '', '' ); 1 };
    skip 'no symlinks on this system', 2 unless $symlinks;

    # The dangling symlink sorts first, so a scrape that stops there reads
    # nothing.
    my $links = tempdir( CLEANUP => 1 );
    make_path("$links/sub");
    write_file( "$links/sub/z-good.pl", qq{$func("Good file");\n} );
    write_file( "$links/top.pl",        qq{$func("Link target");\n} );
    symlink( 'nowhere.pl', "$links/sub/a-dangling.pl" ) or die "Cannot symlink: $!";

    # Relative to the link this is sub/top.pl, which does not exist; relative
    # to the start directory, top.pl does.
    symlink( 'top.pl', "$links/sub/b-dangling-here.pl" ) or die "Cannot symlink: $!";

    # Relative to the link this is top.pl; relative to the start directory,
    # ../top.pl does not exist.
    symlink( '../top.pl', "$links/sub/c-link.pl" ) or die "Cannot symlink: $!";

    my ( $out, $err, $ok ) = scrape_in( $links, '--output', 'perl', '--only', '^sub/' );
    ok( $ok, 'dangling symlinks: scrape runs' ) or diag $err;
    my $VAR1;
    eval $out if $ok;
    is_deeply(
        [ sort map { "$_->{msgid} in " . ( $_->{file} =~ m{(sub/.*)} )[0] } @{ $VAR1 || [] } ],
        [ 'Good file in sub/z-good.pl', 'Link target in sub/c-link.pl' ],
        'dangling symlinks are skipped, the files after them and a working relative link are read'
    ) or diag $err;
}

done_testing;
