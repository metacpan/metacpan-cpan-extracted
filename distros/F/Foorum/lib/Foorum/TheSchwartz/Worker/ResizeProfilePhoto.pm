package Foorum::TheSchwartz::Worker::ResizeProfilePhoto;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/base_path/;
use Image::Magick;
use File::Copy ();
use File::Spec;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema    = schema();
    my $base_path = base_path();

    # get upload from db
    my $upload_id = shift @args;
    if ( $upload_id !~ /^\d+$/ ) {
        return $job->failed("Wrong upload_id: $upload_id");
    }
    my $upload
        = $schema->resultset('Upload')->find( { upload_id => $upload_id } );
    unless ($upload) {
        return $job->failed("No upload for $upload_id");
    }

    # get file dir
    my $directory_1 = int( $upload_id / 3200 / 3200 );
    my $directory_2 = int( $upload_id / 3200 );
    my $file        = abs_path(
        File::Spec->catfile(
            $base_path,   'root',
            'upload',     $directory_1,
            $directory_2, $upload->filename
        )
    );

    # resize photo
    my $p = new Image::Magick;
    $p->Read($file);
    $p->Scale( geometry => '120x120' );
    $p->Sharpen( geometry => '0.0x1.0' );
    $p->Set( quality => '75' );

    my ( $width, $height, $size ) = $p->Get( 'width', 'height', 'filesize' );

    my $tmp_file = $file . '.tmp';
    $p->Write($tmp_file);

    File::Copy::move( $tmp_file, $file );

    # update db
    $schema->resultset('UserProfilePhoto')->search(
        {   type  => 'upload',
            value => $upload_id,
        }
        )->update(
        {   width  => int($width),
            height => int($height),
        }
        );
    $size /= 1024;    # I want K
    ($size) = ( $size =~ /^(\d+\.?\d{0,1})/ );    # float(6,1)
    $upload->update( { filesize => $size } );

    $job->completed();
}

sub max_retries {3}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::ResizeProfilePhoto - resize profile photo in cron job

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

Since L<Image::Magick> is a bit heavy to load into httpd, we move use Image::Magick; in this cron job.

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
