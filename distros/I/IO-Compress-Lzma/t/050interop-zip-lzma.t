BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;

use File::Spec ;
use Test::More ;
use CompTestUtils;

BEGIN {
    #plan(skip_all => "temp disabled until IO::Compress::RawLzma is ready")
    #    if 1;

    plan(skip_all => "needs Perl 5.6 or better - you have Perl $]" )
        if $] < 5.006 ;    
}
use bytes;
use warnings;

my $P7ZIP ='7z';


sub ExternalP7ZipWorks
{
    my $lex = new LexFile my $outfile;
    my $content = qq {
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.
};

    writeWithP7Zip($outfile, $content, "-mm=Lzma")
        or return 0;
    
    my $got ;
    readWithP7Zip($outfile, $got)
        or return 0;

    if ($content ne $got)
    {
        diag "Uncompressed content is wrong";
        return 0 ;
    }

    return 1 ;
}

sub readWithP7Zip
{
    my $file = shift ;

    my ($outfile, $stderr) ;
    my $lex = new LexFile $outfile, $stderr;

    my $comp = "$P7ZIP" ;

    if ( system("$comp e -tZip -so $file >$outfile 2>$stderr") == 0 )
    {
        $_[0] = readFile($outfile);
        return 1 
    }

    my $bad =  readFile($stderr);
    diag "'$comp' failed: $? [$bad]";
    return 0 ;
}

sub writeWithP7Zip
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    my $lex = new LexFile my $infile;
    writeFile($infile, $content);

    unlink $file ;
    my $comp = "$P7ZIP a -tZip $options $file $infile >/dev/null" ;

    return 1 
        if system($comp) == 0 ;

    diag "'$comp' failed: $?";
    return 0 ;
}

sub testWithP7Zip
{
    my $file = shift ;

    my $lex = new LexFile my $outfile;

    my $status = ( system("$P7ZIP t -tZip $file >$outfile 2>/dev/null") == 0 ) ;
    
    $_[0] = readFile($outfile);

    return $status ;
}


sub memError
{
    my $err = shift ;
    #my $re = "(" . LZMA_MEM_ERROR . "|" . LZMA_MEMLIMIT_ERROR . ")";
    #my $re .= LZMA_MEM_ERROR;
    my $re = "(Memory usage limit was reached|Cannot allocate memory)";
    return $err =~/$re/ ;
}

BEGIN {

    # Check external 7za exists
    my $p7zip = '7z';
    for my $dir (reverse split ":", $ENV{PATH})
    {
        $P7ZIP = "$dir/$p7zip"
            if -x "$dir/$p7zip" ;

    }

    plan(skip_all => "Cannot find $p7zip")
        if ! $P7ZIP ;

    plan(skip_all => "$p7zip don't work as expected")
        if ! ExternalP7ZipWorks();

    
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 575 + $extra ;

    use_ok('IO::Compress::Zip',     ':all') ;
    use_ok('IO::Uncompress::Unzip', ':all') ;

}


{
    title "Test interop with $P7ZIP" ;

    my $file ;
    my $file1;
    my $file2;
    my $lex = new LexFile $file, $file1, $file2;

    my @content = ("", qq {
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.

 Hello World
});
    my $got;

    #for my $method (qw(Copy Deflate Bzip2 LZMA))
    for my $content (@content)
    {
        for my $method (qw(LZMA))
        {
            title "unzip with Method $method";
            ok writeWithP7Zip($file, $content, "-mm=$method"), "  writeWithP7Zip ok";

            $got = '';
            ok readWithP7Zip($file, $got), "  readWithP7Zip ok";
            is $got, $content, "  got content";

            $got = '';
            ok unzip($file => \$got), "  unzipped ok" ;
            is $got, $content, "  got content with unzip";
        }
    }

    for my $content (@content)
    {
        #for my $method (ZIP_CM_STORE, ZIP_CM_DEFLATE, ZIP_CM_BZIP2, ZIP_CM_LZMA)
        for my $method (ZIP_CM_LZMA)
        {
            for my $streamed (1, 0)
            {
                for my $preset (0 .. 9)
                {
                    for my $extreme (0, 1)
                    {
                      SKIP:
                      {
                        title "zip with Method $method, Streamed $streamed, Preset $preset, Extreme $extreme";
                        my $status = zip(\$content => $file1, 
                                                    Name => "fred", 
                                                    Preset => $preset,
                                                    Extreme => $extreme,
                                                    Stream => $streamed,
                                                    Method => $method);

                       skip "Not enough memory - Preset $preset, Extreme $extreme, Preset $preset", 6
                            if memError($ZipError);

                        ok $status, "zip ok"
                           or diag $ZipError;

                        $got = '';
                        ok unzip($file1 => \$got), "unzipped"
                            or diag $UnzipError ;
                        is $got, $content, "  got content with unzip";

                        $got = '';
                        ok readWithP7Zip($file1, $got), "  readWithP7Zip ok";
                        is $got, $content, "  got content";

                        ok testWithP7Zip($file1, $got), "  testWithP7Zip ok"
                         or diag "  got $got";
                      }
                    }
                }
            }
        }
    }
}


