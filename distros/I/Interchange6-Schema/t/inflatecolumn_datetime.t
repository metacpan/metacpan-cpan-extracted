#! perl

use warnings;
use strict;

use File::Spec;
use Test::More;

my ( $dir, $fh, @files );

$dir = File::Spec->catdir( 'lib', 'Interchange6', 'Schema', 'Result' );
opendir( $fh, $dir ) or die;
@files = grep { /\.pm$/ } readdir($fh);
closedir($fh);

plan tests => scalar @files;

foreach my $file (@files) {
    my ( $path, $text );
    $path = File::Spec->catdir( $dir, $file );
    {
        open ( my $fh, $path ) or die;
        local $/ = undef;
        $text = <$fh>;
        close ($fh);
    }
    if ( $text =~ m/{.*?data_type.*?=>.*?"(date(time)*|timestamp)"/si ) {
        if ( $text =~ m/components.+InflateColumn::DateTime/s ) {
            pass "$file loads component InflateColumn::DateTime";
        }
        else {
            fail "$file has $1 without component InflateColumn::DateTime";
        }
    }
    else {
        pass "No datetime in $file";
    }
}
