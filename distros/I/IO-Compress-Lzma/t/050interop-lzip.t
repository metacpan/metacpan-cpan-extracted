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

my $LZIP ;

sub ExternalLzipWorks
{
    my $lex = new LexFile my $outfile;
    my $content = qq {
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut tempus odio id
 dolor. Camelus perlus.  Larrius in lumen numen.  Dolor en quiquum filia
 est.  Quintus cenum parat.
};

    writeWithLzip($outfile, $content)
        or return 0;

    my $got ;
    readWithLzip($outfile, $got)
        or return 0;

    if ($content ne $got)
    {
        diag "Uncompressed content is wrong";
        return 0 ;
    }

    return 1 ;
}

sub readWithLzip
{
    my $file = shift ;

    my $lex = new LexFile my $outfile;

    my $comp = "$LZIP -dc" ;

    if (system("$comp $file >$outfile") == 0 )
    {
        $_[0] = readFile($outfile);
        return 1 ;
    }

    diag "'$comp' failed: $?";
    return 0 ;
}

sub writeWithLzip
{
    my $file = shift ;
    my $content = shift ;
    my $options = shift || '';

    my $lex = new LexFile my $infile;
    writeFile($infile, $content);

    unlink $file ;
    my $comp = "$LZIP -c $options $infile >$file" ;

    return 1
        if system($comp) == 0  ;

    diag "'$comp' failed: $?";
    return 0 ;
}

BEGIN
{

    # Check external lzip is available
    my $name = $^O =~ /mswin/i ? 'lzip.exe' : 'lzip';
    my $split = $^O =~ /mswin/i ? ";" : ":";

    for my $dir (reverse split $split, $ENV{PATH})
    {
        $LZIP = File::Spec->catfile($dir,$name)
            if -x File::Spec->catfile($dir,$name);
    }

    # Handle spaces in path to lzip
    $LZIP = "\"$LZIP\"" if defined $LZIP && $LZIP =~ /\s/;

    plan(skip_all => "Cannot find $name")
        if ! $LZIP ;

    plan(skip_all => "$name doesn't work as expected")
        if ! ExternalLzipWorks();

    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 12 + $extra ;

    use_ok('IO::Compress::Lzip',     ':all') ;
    use_ok('IO::Uncompress::UnLzip', ':all') ;

}

{
    title "Test interop with $LZIP" ;

    my ($file, $file1);
    my $lex = new LexFile $file, $file1;
    my $content = "hello world\n" ;
    my $got;

    ok writeWithLzip($file, $content), "writeWithLzip ok";

    unlzip $file => \$got ;
    is $got, $content;


    lzip \$content => $file1;
    $got = '';
    ok readWithLzip($file1, $got), "readWithLzip returns 0";
    is $got, $content, "got content";
}

{
    title "Test interop with $LZIP - empty file" ;

    my ($file, $file1);
    my $lex = new LexFile $file, $file1;
    my $content = "" ;
    my $got;

    ok writeWithLzip($file, $content), "writeWithLzip ok";

    unlzip $file => \$got ;
    is $got, $content;


    lzip \$content => $file1;
    $got = '';
    ok readWithLzip($file1, $got), "readWithLzip returns 0";
    is $got, $content, "got content";
}
