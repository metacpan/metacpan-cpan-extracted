BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;
use bytes;

use File::Spec ;
use Test::More ;

my $LZF ;

use CompTestUtils;

my $shortContent = "hello world";

my $longContent = <<EOM ;
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.
EOM

sub ExternalLzfWorks
{
    my $lex = new LexFile my $outfile;
    my $content = "hello world";

    writeWithLzf($outfile, $content)
        or return 0;

    my $got ;
    readWithLzf($outfile, $got)
        or return 0;

    if ($content ne $got)
    {
        diag "Uncompressed content is wrong";
        return 0 ;
    }

    return 1 ;
}


sub readWithLzf
{
    my $file = shift ;

    my $lex = new LexFile my $outfile;

    my $comp = "$LZF -d" ;

    if ( system("$comp <$file >$outfile") == 0 )
    {
        $_[0] = readFile($outfile);
        return 1
    }

    diag "'$comp' failed: $?";
    return 0 ;
}


sub getLzfInfo
{
    my $file = shift ;
}

sub writeWithLzf
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    my $lex = new LexFile my $infile;
    writeFile($infile, $content);

    unlink $file ;
    my $comp = "$LZF -c $options <$infile >$file" ;

    return 1
        if system($comp) == 0 ;

    diag "'$comp' failed: $?";
    return 0 ;
}


BEGIN {

    # Check external lzf is available
    my $name = 'lzf';
    for my $dir (reverse split ":", $ENV{PATH})
    {
        $LZF = File::Spec->catfile($dir,$name)
            if -x File::Spec->catfile($dir,$name) ;
    }

    plan(skip_all => "Cannot find lzf")
        if ! $LZF ;

    # Handle spaces in path to lzf
    $LZF = "\"$LZF\"" if defined $LZF && $LZF =~ /\s/;

    plan(skip_all => "$name doesn't work as expected")
        if ! ExternalLzfWorks();

    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 16 + $extra ;

    use_ok('IO::Compress::Lzf', qw(:all)) ;
    use_ok('IO::Uncompress::UnLzf', qw(:all)) ;

}

# Use short & long content to trigger sroring & compression respectively.
for my $content ($shortContent, $longContent)
{
    title "Test interop with $LZF" ;

    my $file;
    my $file1;
    my $lex = new LexFile $file, $file1;
    my $got;

    is writeWithLzf($file, $content), 1, "  writeWithLzf ok";

    ok unlzf($file => \$got), "  unlzf ok" ;
    is $got, $content, "  got expected content";


    ok lzf(\$content => $file1), "  lzf ok";
    $got = '';
    is readWithLzf($file1, $got), 1, "readWithLzf returns 0";
    is $got, $content, "got content";
}
