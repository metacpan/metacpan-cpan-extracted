use lib 't';
use strict;
#use warnings;
use bytes;

use Test::More ;
use CompTestUtils;

BEGIN {

    eval { require IO::String ;  import IO::String; 1 }
        or plan(skip_all => "IO::String not installed");

    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 4 + $extra ;
}


sub run
{

    my $CompressClass   = identify();
    my $UncompressClass = getInverse($CompressClass);
    my $Error           = getErrorRef($CompressClass);
    my $UnError         = getErrorRef($UncompressClass);
    my $TopFuncName     = getTopFuncName($CompressClass);
    my $Func            = getTopFuncRef($CompressClass);
    my $FuncInverse     = getTopFuncRef($UncompressClass);

    {
        use IO::String;
        #use IO::Scalar;
        #use IO::Wrap;
        #use IO::All;
        
        my $content = "hello world" ;
        my $string = $content;
        my $StrFH = new IO::String $string;

        #my $StrFH = new IO::Scalar \$string;
        #my $fh = new IO::String $string;
        #my $StrFH = wraphandle($fh);

        #my $lex = new LexFile my $filename ;
        #writeFile($filename, $content);
        #my $StrFH = io "$filename";

        ok $StrFH, "Created IO::String Object";

        my $outStr;
        my $out = \$outStr;
        ok $Func->($StrFH, $out), "Compressed"
            or diag $$Error ;

        my $got;
        ok $FuncInverse->($out, \$got), "Uncompressed"
            or diag $$UnError ;
        is $got, $content, "got expected content";
    }



#    if (0)
#    {
#        my $content = "hello world" ;
#        my $string = $content;
#        my $StrFH = new IO::String $string;
#
#        use File::Copy qw(cp);
#        #my $lex = new LexFile my $filename ;
#        #my $filename = "/tmp/freddy";
#        my $lex1 = new LexFile my $filename, my $filename1, my $filename2 ;
#        writeFile($filename1, "hello moto\n");
#
#        my $x =  $CompressClass->new($filename); 
#        cp $StrFH, $x;
#
#        #my $y =  $UncompressClass->new($filename1); 
#        #cp $y => $filename2;
#
#        #is readFile($filename2), "hello moto\n", "expected content";
#    }
}
 
1;

__END__


sub readWithBzip2
{
    my $file = shift ;

    my $comp = "$BZIP2 -dc" ;

    open F, "$comp $file |";
    local $/;
    $_[0] = <F>;
    close F;

    return $? ;
}

sub getBzip2Info
{
    my $file = shift ;
}

sub writeWithBzip2
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    unlink $file ;
    my $bzip2 = "$BZIP2 -c $options >$file" ;

    open F, "| $bzip2" ;
    print F $content ;
    close F ;

    return $? ;
}


{
    title "Test interop with $BZIP2" ;

    my $file = 'a.bz2';
    my $file1 = 'b.bz2';
    my $lex = new LexFile $file, $file1;
    my $content = "hello world\n" ;
    my $got;

    is writeWithBzip2($file, $content), 0, "writeWithBzip2 ok";

    bunzip2 $file => \$got ;
    is $got, $content;


    bzip2 \$content => $file1;
    $got = '';
    is readWithBzip2($file1, $got), 0, "readWithBzip2 returns 0";
    is $got, $content, "got content";
}


