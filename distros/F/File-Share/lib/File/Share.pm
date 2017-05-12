use strict; use warnings;
package File::Share;
our $VERSION = '0.25';

use base 'Exporter';
our @EXPORT_OK   = qw[
    dist_dir
    dist_file
    module_dir
    module_file
    class_dir
    class_file
];
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
    ALL => [ @EXPORT_OK ],
);

use File::ShareDir();
use Cwd qw[abs_path];
use File::Spec();

sub dist_dir {
    my ($dist) = @_;
    (my $inc = $dist) =~ s!(-|::)!/!g;
    $inc .= '.pm';
    my $path = $INC{$inc} || '';
    $path =~ s/$inc$//;
    $path = Cwd::realpath( File::Spec->catfile($path,'..') );
    if ($path and
        -d "$path/lib" and
        -e "$path/share"
    ) {
        return abs_path "$path/share";
    }
    else {
        return File::ShareDir::dist_dir($dist);
    }
}

sub dist_file {
    my ($dist, $file) = @_;
    my $dir = dist_dir($dist);
    return File::Spec->catfile( $dir, $file );
}

sub module_dir {
    die "File::Share::module_dir not yet supported";
}

sub module_file {
    die "File::Share::module_file not yet supported";
}

1;
