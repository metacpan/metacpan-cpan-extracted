BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict ;
use warnings ;

use Test::More ;

BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };


    my $VERSION = '2.206';
    my @NAMES = qw(
			Compress::Raw::Lzma
			IO::Compress::Base
			IO::Uncompress::Base
			);

    my @OPT = qw(

			);

    plan tests => @NAMES + @OPT + $extra ;

    foreach my $name (@NAMES)
    {
        use_ok($name, $VERSION);
    }


    foreach my $name (@OPT)
    {
        eval " require $name " ;
        if ($@)
        {
            ok 1, "$name not available"
        }
        else
        {
            my $ver = eval("\$${name}::VERSION");
            is $ver, $VERSION, "$name version should be $VERSION"
                or diag "$name version is $ver, need $VERSION" ;
        }
    }

}

{
    # Print our versions of all modules used

    my @results = ( [ 'perl', $] ] );
    my @modules = qw(
                    IO::Compress::Base
                    IO::Compress::Zip
                    IO::Compress::Lzma
                    IO::Uncompress::Base
                    IO::Uncompress::Unzip
                    IO::Uncompress::UnLzma
                    Compress::Raw::Zlib
                    Compress::Raw::Bzip2
                    Compress::Raw::Lzma
                    );

    my %have = ();

    for my $module (@modules)
    {
        my $ver = packageVer($module) ;
        my $v = defined $ver
                    ? $ver
                    : "Not Installed" ;
        push @results, [$module, $v] ;
        $have{$module} ++
            if $ver ;
    }

    if ($have{"Compress::Raw::Lzma"})
    {
        my $ver = eval { Compress::Raw::Lzma::lzma_version_string(); } || "unknown";
        push @results, ["lzma", $ver] ;
    }

    use List::Util qw(max);
    my $width = max map { length $_->[0] } @results;

    diag "\n\n" ;
    for my $m (@results)
    {
        my ($name, $ver) = @$m;

        my $b = " " x (1 + $width - length $name);

        diag $name . $b . $ver . "\n" ;
    }

    diag "\n\n" ;
}

sub packageVer
{
    no strict 'refs';
    my $package = shift;

    eval "use $package;";
    return ${ "${package}::VERSION" };

}
