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
use CompTestUtils;

my $LZMA ;
my $UNLZMA ;

sub ExternalLzmaWorks
{
    my $lex = new LexFile my $outfile;
    my $content = qq {
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.
};

    writeWithLzma($outfile, $content)
        or return 0;
    
    my $got ;
    readWithLzma($outfile, $got)
        or return 0;

    if ($content ne $got)
    {
        diag "Uncompressed content is wrong";
        return 0 ;
    }

    return 1 ;
}

sub readWithLzma
{
    my $file = shift ;

    my $lex = new LexFile my $outfile;

    my $comp = "$UNLZMA -c " ;

    if (system("$comp <$file >$outfile") == 0 )
    {
        $_[0] = readFile($outfile);
        return 1 ;
    }

    diag "'$comp' failed: $?";
    return 0 ;
}

sub writeWithLzma
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    my $lex = new LexFile my $infile;
    writeFile($infile, $content);

    unlink $file ;
    my $comp = "$LZMA -c $options $infile >$file" ;

    return 1 
        if system($comp) == 0  ;

    diag "'$comp' failed: $?";
    return 0 ;
}

BEGIN 
{

    # Check external lzma is available
    my $nameLZ = $^O =~ /mswin/i ? 'lzma.exe' : 'lzma';
    my $nameUNLZ = $^O =~ /mswin/i ? 'unlzma.exe' : 'unlzma';
    my $split = $^O =~ /mswin/i ? ";" : ":";

    for my $dir (reverse split $split, $ENV{PATH})    
    {
        $LZMA = File::Spec->catfile($dir,$nameLZ)
            if -x File::Spec->catfile($dir,$nameLZ);

        $UNLZMA = File::Spec->catfile($dir,$nameUNLZ)
            if -x File::Spec->catfile($dir,$nameUNLZ);
    }

    # Handle spaces in path to lzma 
    $LZMA = "\"$LZMA\"" if defined $LZMA && $LZMA =~ /\s/;    
    $UNLZMA = "\"$UNLZMA\"" if defined $UNLZMA && $UNLZMA =~ /\s/;    

    plan(skip_all => "Cannot find $nameLZ")
        if ! $LZMA ;

    plan(skip_all => "Cannot find $nameUNLZ")
        if ! $UNLZMA ;

    plan(skip_all => "$nameLZ doesn't work as expected")
        if ! ExternalLzmaWorks();
    
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 12 + $extra ;

    use_ok('IO::Compress::Lzma',     ':all') ;
    use_ok('IO::Uncompress::UnLzma', ':all') ;

}

{
    title "Test interop with $LZMA" ;

    my ($file, $file1);
    my $lex = new LexFile $file, $file1;
    my $content = "hello world\n" ;
    my $got;

    ok writeWithLzma($file, $content), "writeWithLzma ok";

    unlzma $file => \$got ;
    is $got, $content;


    lzma \$content => $file1;
    $got = '';
    ok readWithLzma($file1, $got), "readWithLzma returns 0";
    is $got, $content, "got content";
}

{
    title "Test interop with $LZMA - empty file" ;

    my ($file, $file1);
    my $lex = new LexFile $file, $file1;
    my $content = "" ;
    my $got;

    ok writeWithLzma($file, $content), "writeWithLzma ok";

    unlzma $file => \$got ;
    is $got, $content;


    lzma \$content => $file1;
    $got = '';
    ok readWithLzma($file1, $got), "readWithLzma returns 0";
    is $got, $content, "got content";
}


