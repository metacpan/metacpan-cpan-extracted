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

BEGIN {

    plan(skip_all => "IO::Compress::Zstd not available" )
        unless eval { require IO::Compress::Zstd;
                      require IO::Uncompress::UnZstd;
                      1
                    } ;

    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 3 + $extra ;

}


SKIP:
{
    title "Check long content isn't truncated";

    # https://github.com/pmqs/IO-Compress-Zstd/issues/1

    # $ zstdcat setup.zst | cksum -
    # 1769531523 17204641 -

    # $ zstdcat setup.zst | wc
    # 213003  907461 17204641

    # $ zstdcat setup.zst | md5sum
    # 3f5b564eea6aa4bb39ebecad0b98d70b  -

    my $filename = 't/files/setup.zst';

    # Don't distribute file on CPAN
    skip "test file not available", 9
        unless -e $filename ;

    eval { require Digest::MD5 }
    or skip "Digest::MD5 not available";


    my $IN = new IO::Uncompress::UnZstd $filename
        or die "cannot open '$filename': $!\n";

    my $length = 0;
    my $md5 = Digest::MD5->new ;

    while (<$IN>)
    {
        $length += length($_);
        $md5->add($_);
    }

    is $length, 17204641, "Length matches";
    is $md5->hexdigest, '3f5b564eea6aa4bb39ebecad0b98d70b', 'MD5 checksums match'
}
