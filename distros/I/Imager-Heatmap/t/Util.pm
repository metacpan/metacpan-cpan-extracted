package t::Util;
use strict;
use warnings;
use File::Spec;
use File::Basename qw/ dirname /;

use parent 'Exporter';
our @EXPORT = qw/ hmap sample_data load_image /;

use Imager::Heatmap;

our $RESOURCES_DIR = File::Spec->catdir(dirname(__FILE__), 'resources');

sub hmap {
    return Imager::Heatmap->new( xsize => 300, ysize => 300 );
}

sub sample_data {
    my $src_file = shift;

    my $src_path = File::Spec->catfile($RESOURCES_DIR, $src_file);
    open my $fh, '<', $src_path or die "Can't open file $src_path: $!";

    my @insert_datas;
    while (my $line = <$fh>) {
        chomp $line;
        push @insert_datas, [ split /\s/, $line ];
    }

    return @insert_datas;
}

sub load_image {
    my $img_file = shift;

    return Imager->new(file => File::Spec->catfile($RESOURCES_DIR, $img_file));
}

1;
