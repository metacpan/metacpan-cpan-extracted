package EBook::Ishmael::EBook::Text;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use Encode qw(decode);
use File::Basename;
use File::Spec;

use EBook::Ishmael::CharDet;
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::HTML qw(text2html);

# Use -T to check if file is a text file. EBook.pm's ebook_id() makes sure
# to use the Text heuristic last, so that it doesn't incorrectly identify other
# plain text ebook formats as just text.
sub heuristic {

    my $class = shift;
    my $file  = shift;

    return -T $file;

}

sub new {

    my $class = shift;
    my $file  = shift;
    my $enc   = shift;

    my $self = {
        Source   => undef,
        Metadata => EBook::Ishmael::EBook::Metadata->new,
        Encode   => $enc,
    };

    bless $self, $class;

    $self->{Source} = File::Spec->rel2abs($file);

    $self->{Metadata}->set_title(basename($self->{Source}));
    $self->{Metadata}->set_modified((stat $self->{Source})[9]);
    $self->{Metadata}->set_format('Text');

    return $self;

}

sub html {

    my $self = shift;
    my $out  = shift;

    my $html = text2html($self->raw);

    if (defined $out) {
        open my $wh, '>', $out
            or die "Failed to open $out for writing: $!\n";
        binmode $wh, ':utf8';
        print { $wh } $html;
        close $wh;
        return $out;
    } else {
        return $html;
    }

}

sub raw {

    my $self = shift;
    my $out  = shift;

    open my $rh, '<', $self->{Source}
        or die "Failed to open $self->{Source} for reading: $!\n";
    binmode $rh;
    my $raw = do { local $/; <$rh> };
    close $rh;

    if (not defined $self->{Encode}) {
        $self->{Encode} = chardet($raw) // 'ASCII';
    }
    $raw = decode($self->{Encode}, $raw);

    if (defined $out) {
        open my $wh, '>', $out
            or die "Failed to open $out for writing: $!\n";
        binmode $wh, ':utf8';
        print { $wh } $raw;
        close $wh;
        return $out;
    } else {
        return $raw;
    }

}

sub metadata {

    my $self = shift;

    return $self->{Metadata};

}

sub has_cover { 0 }

sub cover { (undef, undef) }

sub image_num { 0 }

sub image { (undef, undef) }

1;
