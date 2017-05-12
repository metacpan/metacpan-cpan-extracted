#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Benchmark qw(:all);
use FindBin '$Bin';
use Path::Tiny;

use IO::Compress::Gzip 'gzip';
use IO::Uncompress::Gunzip 'gunzip';
use Gzip::Faster;
use Compress::Raw::Zlib;

# Switch the comment on the following lines to get the long test.

#my $testinput = 'chinese';
my $testinput = 'english';

my $testtype = 'speed';

my $validate = 0;

my $showsize = 1;

# The input

my $in;

# The number of times to run the test.

my $repeat;

if ($testinput eq 'english') {
    $in = <<EOF;
To be, or not to be: that is the question:
Whether 'tis nobler in the mind to suffer
The slings and arrows of outrageous fortune,
Or to take arms against a sea of troubles,
And by opposing end them? To die: to sleep;
No more; and by a sleep to say we end
The heart-ache and the thousand natural shocks
That flesh is heir to, 'tis a consummation
Devoutly to be wish'd. To die, to sleep;
To sleep: perchance to dream: ay, there's the rub;
For in that sleep of death what dreams may come
When we have shuffled off this mortal coil,
Must give us pause: there's the respect
That makes calamity of so long life;
For who would bear the whips and scorns of time,
The oppressor's wrong, the proud man's contumely,
The pangs of despised love, the law's delay,
The insolence of office and the spurns
That patient merit of the unworthy takes,
When he himself might his quietus make
With a bare bodkin? who would fardels bear,
To grunt and sweat under a weary life,
But that the dread of something after death,
The undiscover'd country from whose bourn
No traveller returns, puzzles the will
And makes us rather bear those ills we have
Than fly to others that we know not of?
Thus conscience does make cowards of us all;
And thus the native hue of resolution
Is sicklied o'er with the pale cast of thought,
And enterprises of great pith and moment
With this regard their currents turn awry,
And lose the name of action.Soft you now!
The fair Ophelia! Nymph, in thy orisons
Be all my sins remember'd.
EOF
$repeat = 50000;

}
elsif ($testinput eq 'chinese') {
    my $path = path ("$Bin/chinese.txt");

    # Don't slurp_utf8 this because the UTF-8 flag will not survive
    # the round-trip.
    
    $in = $path->slurp ();
    $repeat = 50;
}

my $out;
my $round;

print "\$IO::Compress::Gzip::VERSION = $IO::Compress::Gzip::VERSION\n";
print "\$IO::Uncompress::Gunzip::VERSION = $IO::Uncompress::Gunzip::VERSION\n";
print "\$Compress::Raw::Zlib::VERSION = $Compress::Raw::Zlib::VERSION\n";
print "\$Gzip::Faster::VERSION = $Gzip::Faster::VERSION\n";

splitline ();

if ($showsize) {
    IO::Compress::Gzip::gzip \$in, \my $iocg;
    print "IO::Compress:Gzip size is ", length ($iocg), " bytes.\n";
    my $crz = crzdeflatevalue ($in);
    print "Compress::Raw::Zlib size is ", length ($crz), " bytes.\n";
    my $gzf = Gzip::Faster::gzip ($in);
    print "Gzip::Faster size is ", length ($gzf), " bytes.\n";
    splitline ();
}


# IO::Compress::Gzip and its partner are very slow to load, so $count
# should not be a big number.

my $count = 500;

cmpthese ($count, {
    'Load IOCG' => 'load_io_comp_gzip ()',
    'Load IOUG' => 'load_io_uncomp_gunzip ()',
    'Load CRZ' => 'load_comp_raw_zlib ();',
    'Load GF' => 'load_gzip_faster ();',
# Compare to get a comparison with just the perl interpreter.
#    'do nothing' => 'do_nothing ();',
});

splitline ();

$count = $repeat;

cmpthese ($count, {
    'IO::Compress::Gzip' => 'io_comp_gzip ()',
    'Compress::Raw::Zlib' => 'comp_raw_zlib ()',
    'Gzip::Faster' => 'gzip_faster ()',
});

splitline ();

cmpthese ($count, {
    'IO::Compress::Gzip' => 'io_comp_gzip_only ()',
    'Compress::Raw::Zlib::Deflate' => 'comp_raw_zlib_def_only ()',
    'Gzip::Faster' => 'gzip_faster_gzip_only ()',
});

splitline ();

cmpthese ($count, {
    'IO::Uncompress::Gunzip' => 'io_comp_gunzip_only ()',
    'Compress::Raw::Zlib::Inflate' => 'comp_raw_zlib_inf_only ()',
    'Gzip::Faster' => 'gzip_faster_gunzip_only ()',
});

exit;

# Just to get the size. 

sub crzdeflatevalue
{
    my $buf;
    my $deflated;
    my $dx = Compress::Raw::Zlib::Deflate->new( -WindowBits => WANT_GZIP )
        or die "Cannot create a deflation stream\n";
    ( $dx->deflate($in, $buf) == Z_OK ) ? $deflated = $buf : die "deflation failed\n";
    ( $dx->flush($buf) == Z_OK ) ? $deflated .= $buf : die "deflation failed\n";
    return $deflated;
}


sub load_io_comp_gzip
{
    system ("perl $FindBin::Bin/load_io_comp_gzip");
}

sub load_io_uncomp_gunzip
{
    system ("perl $FindBin::Bin/load_io_uncomp_gunzip");
}

sub load_comp_raw_zlib
{
    system ("perl $FindBin::Bin/load_comp_raw_zlib");
}

sub load_gzip_faster
{
    system ("perl $FindBin::Bin/load_gzip_faster");
}

sub do_nothing
{
    system ("perl $FindBin::Bin/do_nothing");
}

sub io_comp_gzip
{
    IO::Compress::Gzip::gzip \$in, \$out;
    IO::Uncompress::Gunzip::gunzip \$out, \$round;
# Comment out to get better benchmark. Uncomment to check validity.
    if ($validate) {
	die if $in ne $round;
    }
}

sub comp_raw_zlib
{
    my $buf;
    my $dx = Compress::Raw::Zlib::Deflate->new( -WindowBits => WANT_GZIP )
        or die "Cannot create a deflation stream\n";
    ( $dx->deflate($in, $buf) == Z_OK ) ? $out = $buf : die "deflation failed\n";
    ( $dx->flush($buf) == Z_OK ) ? $out .= $buf : die "deflation failed\n";
    my $ix = Compress::Raw::Zlib::Inflate->new( -WindowBits => WANT_GZIP )
        or die "Cannot create a inflation stream\n";
    $_ == Z_OK or $_ == Z_STREAM_END or die "inflation failed\n" for $ix->inflate($out, $round);
# Comment out to get better benchmark. Uncomment to check validity.
    if ($validate) {
	die if $in ne $round;
    }
}

sub gzip_faster
{
    $out = Gzip::Faster::gzip ($in);
    $round = Gzip::Faster::gunzip ($out);
# Comment out to get better benchmark. Uncomment to check validity.
    if ($validate) {
	die if $in ne $round;
    }
}

sub io_comp_gzip_only
{
    IO::Compress::Gzip::gzip \$in, \$out;
}

sub comp_raw_zlib_def_only
{
    my $buf;
    my $dx = Compress::Raw::Zlib::Deflate->new( -WindowBits => WANT_GZIP )
        or die "Cannot create a deflation stream\n";
    ( $dx->deflate($in, $buf) == Z_OK ) ? $out = $buf : die "deflation failed\n";
    ( $dx->flush($buf) == Z_OK ) ? $out .= $buf : die "deflation failed\n";
}

sub gzip_faster_gzip_only
{
    $out = Gzip::Faster::gzip ($in);
}

sub io_comp_gunzip_only
{
    IO::Uncompress::Gunzip::gunzip \$out, \$round;
}

sub comp_raw_zlib_inf_only
{
    my $copy = $out;
    my $ix = Compress::Raw::Zlib::Inflate->new( -WindowBits => WANT_GZIP )
        or die "Cannot create a inflation stream\n";
    $_ == Z_OK or $_ == Z_STREAM_END or die "inflation failed: $_\n" for $ix->inflate($copy, $round);
}

sub gzip_faster_gunzip_only
{
    my $round = Gzip::Faster::gunzip ($out);
}

sub splitline
{
    print "-" x 50;
    print "\n";
}
