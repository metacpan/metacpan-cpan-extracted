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

    plan tests => 13 + $extra ;
};


use IO::Compress::Lzip     qw(:all);
use IO::Uncompress::UnLzip qw($UnLzipError) ;


my $CompressClass   = 'IO::Compress::Lzip';
my $UncompressClass = getInverse($CompressClass);
my $Error           = getErrorRef($CompressClass);
my $UnError         = getErrorRef($UncompressClass);

sub myLzipReadFile
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
    ok ! $fil->error(), "  no error"
       or diag "$$UnError " ;

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
        eval { $bz = new IO::Compress::Lzip(\$buffer, BlockSize100K => $value) };
        like $@,  mkErr("IO::Compress::Lzip: $err"),
            "  value $stringValue is bad";
        is $LzipError, "IO::Compress::Lzip: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (0, 10, 99999)
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "BlockSize100K => $stringValue";
        my $err = "Parameter 'BlockSize100K' not between 1 and 9, got $stringValue";
        my $bz ;
        eval { $bz = new IO::Compress::Lzip(\$buffer, BlockSize100K => $value) };
        like $@,  mkErr("IO::Compress::Lzip: $err"),
            "  value $stringValue is bad";
        is $LzipError,  "IO::Compress::Lzip: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (undef, -1, 'fred')
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "WorkFactor => $stringValue";
        my $err = "Parameter 'WorkFactor' must be an unsigned int, got '$stringValue'";
        my $bz ;
        eval { $bz = new IO::Compress::Lzip(\$buffer, WorkFactor => $value) };
        like $@,  mkErr("IO::Compress::Lzip: $err"),
            "  value $stringValue is bad";
        is $LzipError, "IO::Compress::Lzip: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (251, 99999)
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "WorkFactor => $stringValue";
        my $err = "Parameter 'WorkFactor' not between 0 and 250, got $stringValue";
        my $bz ;
        eval { $bz = new IO::Compress::Lzip(\$buffer, WorkFactor => $value) };
        like $@,  mkErr("IO::Compress::Lzip: $err"),
            "  value $stringValue is bad";
        is $LzipError,  "IO::Compress::Lzip: $err",
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
        eval { $bz = new IO::Uncompress::UnLzip(\$buffer, Small => $value) };
        like $@,  mkErr("IO::Uncompress::UnLzip: $err"),
            "  value $stringValue is bad";
        is $UnLzipError, "IO::Uncompress::UnLzip: $err",
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
    for my $check (1)#LZMA_CHECK_NONE, LZMA_CHECK_CRC32, LZMA_CHECK_CRC64, LZMA_CHECK_SHA256)
    {
        for my $extreme (0) #(0 .. 1)
        {
            for my $preset (0) #(0 .. 9)
            {
                title "$CompressClass - Check $check, Extreme $extreme, Preset $preset";
                my $lex = new LexFile my $name ;
                my $lzip ;
                SKIP:
                {
                    $lzip = new IO::Compress::Lzip($name,
                                            # Check => $check,
                                            # Extreme => $extreme,
                                            # Preset => $preset
                                            ) ;
                    skip "Not enough memory - Check $check, Extreme $extreme, Preset $preset", 5
                        if  memError($IO::Compress::Lzip::LzipError);

                    ok $lzip, "  lzip object ok";
                    isa_ok $lzip, "IO::Compress::Lzip";
                    my $status = $lzip->write($hello);
                    ok $status, "  wrote ok" ;
                    ok $lzip->close(), "  closed ok";

                    my ($s, $data) = myLzipReadFile($name);
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
        my $lzip ;
        $lzip = new IO::Compress::Lzip($name);
        ok $lzip, "  lzip object ok";
        isa_ok $lzip, "IO::Compress::Lzip";
        $lzip->write($hello);
        $lzip->close();

        my $fil = new $UncompressClass $name,
                                       Append  => 1,
                                       ;

        isa_ok $fil, "IO::Uncompress::UnLzip";
        my $data = '';
        1 while $fil->read($data) > 0;

        $fil->close ;

        is $data, $hello, " got expected";
    }
}


1;
