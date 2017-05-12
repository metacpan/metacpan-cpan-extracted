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

    plan tests => 4 + $extra ;
};


use IO::Compress::Lzma     qw($LzmaError) ;
use IO::Uncompress::UnLzma qw($UnLzmaError) ;


my $CompressClass   = 'IO::Compress::Lzma';
my $UncompressClass = getInverse($CompressClass);
my $Error           = getErrorRef($CompressClass);
my $UnError         = getErrorRef($UncompressClass);

sub myLzmaReadFile
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

    $fil->close ;
    return $data ;
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
        eval { $bz = new IO::Compress::Lzma(\$buffer, BlockSize100K => $value) };
        like $@,  mkErr("IO::Compress::Lzma: $err"),
            "  value $stringValue is bad";
        is $LzmaError, "IO::Compress::Lzma: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (0, 10, 99999)
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "BlockSize100K => $stringValue";
        my $err = "Parameter 'BlockSize100K' not between 1 and 9, got $stringValue";
        my $bz ;
        eval { $bz = new IO::Compress::Lzma(\$buffer, BlockSize100K => $value) };
        like $@,  mkErr("IO::Compress::Lzma: $err"),
            "  value $stringValue is bad";
        is $LzmaError,  "IO::Compress::Lzma: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (undef, -1, 'fred')
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "WorkFactor => $stringValue";
        my $err = "Parameter 'WorkFactor' must be an unsigned int, got '$stringValue'";
        my $bz ;
        eval { $bz = new IO::Compress::Lzma(\$buffer, WorkFactor => $value) };
        like $@,  mkErr("IO::Compress::Lzma: $err"),
            "  value $stringValue is bad";
        is $LzmaError, "IO::Compress::Lzma: $err",
            "  value $stringValue is bad";
        ok ! $bz, "  no bz object";
    }

    for my $value (251, 99999)
    {
        my $stringValue = defined $value ? $value : 'undef';
        title "WorkFactor => $stringValue";
        my $err = "Parameter 'WorkFactor' not between 0 and 250, got $stringValue";
        my $bz ;
        eval { $bz = new IO::Compress::Lzma(\$buffer, WorkFactor => $value) };
        like $@,  mkErr("IO::Compress::Lzma: $err"),
            "  value $stringValue is bad";
        is $LzmaError,  "IO::Compress::Lzma: $err",
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
        eval { $bz = new IO::Uncompress::UnLzma(\$buffer, Small => $value) };
        like $@,  mkErr("IO::Uncompress::UnLzma: $err"),
            "  value $stringValue is bad";
        is $UnLzmaError, "IO::Uncompress::UnLzma: $err",
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
    $hello = $hello x 1000 ;

    {
        title "$CompressClass";
        my $lex = new LexFile my $name ;
        my $bz ;
        $bz = new IO::Compress::Lzma($name)
            or diag $IO::Compress::Lzma::LzmaError ;
        ok $bz, "  lzma object ok";
        $bz->write($hello);
        $bz->close($hello);

        #is myLzmaReadFile($name), $hello, "  got expected content";
        ok myLzmaReadFile($name) eq $hello, "  got expected content";
    }

    # TODO - add filter tests
#    for my $value ( 1 .. 9 )
#    {
#        title "$CompressClass - BlockSize100K => $value";
#        my $lex = new LexFile my $name ;
#        my $bz ;
#        $bz = new IO::Compress::Lzma($name, BlockSize100K => $value)
#            or diag $IO::Compress::Lzma::LzmaError ;
#        ok $bz, "  bz object ok";
#        $bz->write($hello);
#        $bz->close($hello);
#
#        is myLzmaReadFile($name), $hello, "  got expected content";
#    }
#
#    for my $value ( 0 .. 250 )
#    {
#        title "$CompressClass - WorkFactor => $value";
#        my $lex = new LexFile my $name ;
#        my $bz ;
#        $bz = new IO::Compress::Lzma($name, WorkFactor => $value);
#        ok $bz, "  bz object ok";
#        $bz->write($hello);
#        $bz->close($hello);
#
#        is myLzmaReadFile($name), $hello, "  got expected content";
#    }
#
#    for my $value ( 0 .. 1 )
#    {
#        title "$UncompressClass - Small => $value";
#        my $lex = new LexFile my $name ;
#        my $bz ;
#        $bz = new IO::Compress::Lzma($name);
#        ok $bz, "  bz object ok";
#        $bz->write($hello);
#        $bz->close($hello);
#
#        my $fil = new $UncompressClass $name,
#                                       Append  => 1,
#                                       Small   => $value ;
#
#        my $data = '';
#        1 while $fil->read($data) > 0;
#
#        $fil->close ;
#
#        is $data, $hello, " got expected";
#    }
}


1;




