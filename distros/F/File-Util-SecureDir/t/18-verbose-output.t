########################################################################
# housekeeping
########################################################################
use v5.36;

use File::Temp  qw( tempdir );
use Test::More;

BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

# verbose and debug report on STDERR.  The #! code chooses nothing, so
# the first filter_dirs latches the default: that call runs under
# verbose so the latch message can be seen.  This file ends in
# other_no_write.

use File::Util::SecureDir;

my $secure  = File::Util::SecureDir->new;
my $root    = tempdir( CLEANUP => 1 );

my $mkdir
= sub( $name, $mode )
{
    my $dir = catdir $root, $name;

    mkdir $dir or BAIL_OUT "Failed mkdir '$dir': $!";
    chmod $mode, $dir;

    $dir
};

# STDERR text written while $code runs.

my $capture
= sub( $code )
{
    my $text = '';

    {
        local *STDERR;

        open STDERR, '>', \$text
        or BAIL_OUT "Failed capturing STDERR: $!";

        $code->();
    }

    $text
};

my $good    = $mkdir->( 'good', 0755 );
my $bad     = $mkdir->( 'bad',  0777 );

########################################################################
# silent by default
########################################################################

$secure->verbose( 0 );
$secure->debug( 0 );

########################################################################
# verbose: the latch and the rejections, not the acceptances
########################################################################

$secure->verbose( 1 );

my $text = $capture->( sub { $secure->filter_dirs( $good, $bad ) } );

like $text, qr{ \A File::Util::SecureDir: \s other_no_write $ }xm
, 'verbose: the latch reports the filter name';

like $text, qr{ ^ File::Util::SecureDir: \s other_no_write: \s reject
                 \s '\Q$bad\E' $ }xm
, 'verbose: a rejected directory is reported';

unlike $text, qr{ accept }x, 'verbose: an accepted directory is not reported';

########################################################################
# debug: every decision, and the debugger flag
########################################################################

$secure->verbose( 0 );
$secure->debug( 1 );

$text = $capture->( sub { $secure->filter_dirs( $good, $bad ) } );

like $text, qr{ ^ File::Util::SecureDir: \s other_no_write: \s accept
                \s '\Q$good\E' $ }xm
, 'debug: an accepted directory is reported';

like $text, qr{ ^ File::Util::SecureDir: \s other_no_write: \s reject
                \s '\Q$bad\E' $ }xm
, 'debug: a rejected directory is reported';

{
    no warnings 'once';

    is $DB::single, 1, 'debug: $DB::single is set by filter_dirs';

    $DB::single = 0;
}

########################################################################
# both off again: silent
########################################################################

$secure->debug( 0 );

$text = $capture->( sub { $secure->filter_dirs( $good, $bad ) } );

is $text, '', 'verbose and debug off: nothing is written to STDERR';

done_testing;
