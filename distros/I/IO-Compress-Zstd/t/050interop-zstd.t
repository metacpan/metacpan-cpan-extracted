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

my $Zstd ;
my $UnZstd ;

use CompTestUtils;

my $shortContent = "hello world";

my $longContent = <<EOM ;
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.
EOM

sub ExternalZstdWorks
{
    my $lex = new LexFile my $outfile;
    my $content = "hello world";

    writeWithZstd($outfile, $content)
        or return 0;
    
    my $got ;
    readWithZstd($outfile, $got)
        or return 0;

    if ($content ne $got)
    {
        diag "Uncompressed content is wrong";
        return 0 ;
    }

    return 1 ;
}


sub readWithZstd
{
    my $file = shift ;

    my $lex = new LexFile my $outfile;

    if ( system("$UnZstd <$file >$outfile") == 0 )
    {
        $_[0] = readFile($outfile);
        return 1 
    }

    diag "'$UnZstd' failed: \$?=$? \$!=$!";
    return 0 ;
}


sub getZstdInfo
{
    my $file = shift ;
}

sub writeWithZstd
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    my $lex = new LexFile my $infile;
    writeFile($infile, $content);

    unlink $file ;
    my $comp = "$Zstd -c $options <$infile >$file" ;

    return 1 
        if system($comp) == 0 ;

    diag "'$comp' failed: \$?=$? \$!=$!";
    return 0 ;
}


BEGIN {

    # Check external zstd is available
    my $zstd = 'zstd';
    my $unzstd = 'unzstd';
    for my $dir (reverse split ":", $ENV{PATH})
    {
        $Zstd = File::Spec->catfile($dir, $zstd)
            if -x File::Spec->catfile($dir, $zstd) ;
        $UnZstd = File::Spec->catfile($dir, $unzstd)
            if -x File::Spec->catfile($dir, $unzstd) ;            
    }

    plan(skip_all => "Cannot find zstd")
        if ! $Zstd ;

    plan(skip_all => "Cannot find unzstd")
        if ! $UnZstd ;

    # Handle spaces in path to zstd 
    $Zstd = "\"$Zstd\"" if defined $Zstd && $Zstd =~ /\s/;    
    $UnZstd = "\"$UnZstd\"" if defined $UnZstd && $UnZstd =~ /\s/;    

    plan(skip_all => "$zstd doesn't work as expected")
        if ! ExternalZstdWorks();

    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 16 + $extra ;

    use_ok('IO::Compress::Zstd', qw(:all)) ;
    use_ok('IO::Uncompress::UnZstd', qw(:all)) ;

}

# Use short & long content to trigger sroring & compression respectively.
for my $content ($shortContent, $longContent)
{
    title "Test interop with $Zstd" ;

    my $file;
    my $file1;
    my $lex = new LexFile $file, $file1;
    my $got;

    is writeWithZstd($file, $content), 1, "  writeWithZstd ok";

    ok unzstd($file => \$got), "  unzstd ok" ;
    is $got, $content, "  got expected content";


    ok zstd(\$content => $file1), "  zstd ok";
    $got = '';
    is readWithZstd($file1, $got), 1, "readWithZstd returns 0";
    is $got, $content, "got content";
}

