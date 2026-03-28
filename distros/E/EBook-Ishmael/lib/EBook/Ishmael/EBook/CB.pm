package EBook::Ishmael::EBook::CB;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Which;
use List::Util qw(max);

use EBook::Ishmael::Dir;
use EBook::Ishmael::ImageID qw(image_path_id);
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::Unzip qw(safe_tmp_unzip);

# Not an ebook format itself, just a base class from which actual comic book
# archives derive themselves.

sub heuristic { 0 }

sub _images {

    my $dir = shift;

    my @img;

    for my $f (dir($dir)) {
        if (-d $f) {
            push @img, _images($f);
        } elsif (-f $f) {
            my $format = image_path_id($f);
            next if not defined $format;
            push @img, [ $f, $format ];
        }
    }

    return @img;

}

sub new {

    my $class = shift;
    my $file  = shift;

    my $self = {
        Source   => undef,
        Metadata => EBook::Ishmael::EBook::Metadata->new,
        _images  => [],
        _tmpdir  => undef,
    };

    bless $self, $class;

    my $title = (fileparse($file, qr/\.[^.]*/))[0];

    $self->{Source} = File::Spec->rel2abs($file);

    $self->{_tmpdir} = safe_tmp_unzip;
    $self->extract($self->{_tmpdir});

    @{ $self->{_images} } = _images($self->{_tmpdir});

    unless (@{ $self->{_images} }) {
        die "$self->{Source}: Found no images in comic book archive\n";
    }

    $self->{Metadata}->set_title($title);
    $self->{Metadata}->set_modified((stat $self->{Source})[9]);
    $self->{Metadata}->set_format($self->format);

    return $self;

}

sub extract {
    die sprintf "%s does not implement the extract() method\n", __PACKAGE__;
}

sub format { undef }

# Comic Book archives have no HTML
sub html {

    my $self = shift;
    my $out  = shift;

    my $html = '';

    open my $fh, '>', $out // \$html
        or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';

    print { $fh } '';

    close $fh;

    return $out // $html;

}

# ... or text of any kind
sub raw {

    my $self = shift;
    my $out  = shift;

    my $raw = '';

    open my $fh, '>', $out // \$raw
        or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';

    print { $fh } '';

    close $fh;

    return $out // $raw;

}

sub metadata {

    my $self = shift;

    return $self->{Metadata};

}

sub has_cover {

    my $self = shift;

    return !! scalar @{ $self->{_images} };

}

sub cover {

    my $self = shift;

    return (undef, undef) unless $self->has_cover;

    open my $fh, '<', $self->{_images}[0][0]
        or die "Failed to open $self->{_images}[0][0] for reading: $!\n";
    binmode $fh;
    my $img = do { local $/; readline $fh };
    close $fh;

    return ($img, $self->{_images}[0][1]);

}

sub image_num {

    my $self = shift;

    return scalar @{ $self->{_images} };

}

sub image {

    my $self = shift;
    my $n    = shift;

    if ($n >= $self->image_num) {
        return (undef, undef);
    }

    open my $fh, '<', $self->{_images}[$n][0]
        or die "Failed to open $self->{_images}[$n][0] for reading: $!\n";
    binmode $fh;
    my $img = do { local $/; readline $fh };
    close $fh;

    return ($img, $self->{_images}[$n][1]);

}

1;
