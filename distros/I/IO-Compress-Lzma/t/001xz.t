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

use Test::More ;
use CompTestUtils;

BEGIN 
{ 
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 486 + $extra ;
};


#use IO::Compress::Xz     qw($XzError) ;
use IO::Compress::Xz     qw(:all);
use IO::Uncompress::UnXz qw($UnXzError) ;


my $CompressClass   = 'IO::Compress::Xz';
my $UncompressClass = getInverse($CompressClass);
my $Error           = getErrorRef($CompressClass);
my $UnError         = getErrorRef($UncompressClass);

sub myXzReadFile
{
    my $filename = shift ;
    my $init = shift ;

    my $fil = new $UncompressClass $filename,
                                    -Strict   => 1,
                                    -Append   => 1
                                    ;
    my $data = '';
    $data = $init if defined $init ;
    1 while $fil->read($data) > 0;
    my $status = $fil->error() . "" ;
    #ok ! $fil->error(), "  no error" 
    #    or diag "$$UnError " ;

    $fil->close ;
    return ($status, $data) ;
}

sub memError
{
    my $err = shift ;
    #my $re = "(" . LZMA_MEM_ERROR . "|" . LZMA_MEMLIMIT_ERROR . ")";
    #my $re .= LZMA_MEM_ERROR;
    my $re = "(Memory usage limit was reached|Cannot allocate memory)";
    return $err =~/$re/ ;
}


if(0)
{

    title "Testing $CompressClass Errors";

    my $buffer ;

    for my $value (undef, -1, 'fred')
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "BlockSize100K => $stringValue";
        my $err = "Parameter 'BlockSize100K' must be an unsigned int, got '$stringValue'";
        my $bz ;
        eval { $bz = new IO::Compress::Xz(\$buffer, BlockSize100K => $value) };
        like $@,  mkErr("IO::Compress::Xz: $err"),
            "  value $stringValue is bad";
        is $XzError, "IO::Compress::Xz: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (0, 10, 99999)
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "BlockSize100K => $stringValue";
        my $err = "Parameter 'BlockSize100K' not between 1 and 9, got $stringValue";
        my $bz ;
        eval { $bz = new IO::Compress::Xz(\$buffer, BlockSize100K => $value) };
        like $@,  mkErr("IO::Compress::Xz: $err"),
            "  value $stringValue is bad";
        is $XzError,  "IO::Compress::Xz: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (undef, -1, 'fred')
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "WorkFactor => $stringValue";
        my $err = "Parameter 'WorkFactor' must be an unsigned int, got '$stringValue'";
        my $bz ;
        eval { $bz = new IO::Compress::Xz(\$buffer, WorkFactor => $value) };
        like $@,  mkErr("IO::Compress::Xz: $err"),
            "  value $stringValue is bad";
        is $XzError, "IO::Compress::Xz: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (251, 99999)
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "WorkFactor => $stringValue";
        my $err = "Parameter 'WorkFactor' not between 0 and 250, got $stringValue";
        my $bz ;
        eval { $bz = new IO::Compress::Xz(\$buffer, WorkFactor => $value) };
        like $@,  mkErr("IO::Compress::Xz: $err"),
            "  value $stringValue is bad";
        is $XzError,  "IO::Compress::Xz: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

}


if(0)
{
    title "Testing $UncompressClass Errors";

    my $buffer ;

    for my $value (-1, 'fred')
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "Small => $stringValue";
        my $err = "Parameter 'Small' must be an int, got '$stringValue'";
        my $bz ;
        eval { $bz = new IO::Uncompress::UnXz(\$buffer, Small => $value) };
        like $@,  mkErr("IO::Uncompress::UnXz: $err"),
            "  value $stringValue is bad";
        is $UnXzError, "IO::Uncompress::UnXz: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

}

{
    title "Testing $CompressClass and $UncompressClass";

    my $hello = <<EOM ;
hello world
this is a test
EOM


    # This set of tests can exhaust the memory on a syetem,
    # so be forgiving if it runs out.
    for my $check (LZMA_CHECK_NONE, LZMA_CHECK_CRC32, LZMA_CHECK_CRC64, LZMA_CHECK_SHA256)
    {
        for my $extreme (0 .. 1)
        {
            for my $preset (0 .. 9)
            {
                title "$CompressClass - Check $check, Extreme $extreme, Preset $preset";
                my $lex = new LexFile my $name ;
                my $xz ;
                SKIP:
                {
                    $xz = new IO::Compress::Xz($name, 
                                               Check => $check,
                                               Extreme => $extreme,
                                               Preset => $preset
                                              ) ;
                    skip "Not enough memory - Check $check, Extreme $extreme, Preset $preset", 5
                        if  memError($IO::Compress::Xz::XzError);
                    
                    ok $xz, "  xz object ok";
                    isa_ok $xz, "IO::Compress::Xz";
                    my $status = $xz->write($hello);
                    ok $status, "  wrote ok" ;
                    ok $xz->close(), "  closed ok";

                    my ($s, $data) = myXzReadFile($name);
                    skip "Not enough memory to read with $UncompressClass", 1
                        if  memError($s);
                    is $data, $hello, "  got expected content";
                }
            }
        }
    }

    {
        title "$UncompressClass ";
        my $lex = new LexFile my $name ;
        my $xz ;
        $xz = new IO::Compress::Xz($name);
        ok $xz, "  xz object ok";
        isa_ok $xz, "IO::Compress::Xz";
        $xz->write($hello);
        $xz->close();

        my $fil = new $UncompressClass $name,
                                       Append  => 1,
                                       ;

        isa_ok $fil, "IO::Uncompress::UnXz";
        my $data = '';
        1 while $fil->read($data) > 0;

        $fil->close ;

        is $data, $hello, " got expected";
    }
}


1;




