#!perl
use strict;
use warnings;
use Imager;
use Imager::Fill;
use Image::CCV qw(sift);
use Getopt::Long;
use File::Glob qw(bsd_glob);
use File::Basename qw(dirname);

use vars qw($VERSION);
$VERSION = '0.10';

=head1 NAME

sift-video.pl

=head1 WARNING

This program currently does not work. It paints the keypoints onto
the resulting video, but there are far too many keypoints between
two adjactent frames.

Maybe some averaging over (say) 10 frames or something like that could
reduce the amount of data.

=cut

GetOptions (
    'b|ffmpeg:s' => \my $ffmpeg_binary,
    'f|frames:s' => \my $frames,
    'p|png-frames:s' => \my $png_frames,
);
$frames ||= 1; # one frame lookbehind
$ffmpeg_binary||= 'ffmpeg';

my $workdir;

# Get number of frames in input video

my %processed;
my @images;
my @output_images;

my $ffmpeg_out;

for my $file (@ARGV) {
    my $ffmpeg = FFmpeg::Cmd->new(
        ffmpeg => $ffmpeg_binary,
        filename => $file,
    );
    
    my @frames;
    if (! $png_frames) {
        @frames = sort $ffmpeg->to_png();
    } else {
        @frames = bsd_glob $png_frames;
        @frames = sort @frames;
    };
    warn sprintf "%d frames to process.", 0+@frames;

    my @images;
    for my $name (@frames) {
        # Process the latest frame in respect to all other frames
        warn "Processing $name\n";

        # Convert frame to grayscale
        (my $bw = $name) =~ s/\.png$/-bw.png/;
        my $input = Imager->new(
            file => $name,
        )->convert(preset=>'grey')->scale(xsize => 320)->write(
            file => $bw,
        );
        
        my $result = process_frame( $bw, \@images );
        if(! $result) {
            warn "Empty result for $bw / [@images]";
        };
        push @images, $bw;
        
        next unless $result;
        
        (my $out = $name) =~ s/\.png$/-out.png/;
        warn "Writing result to $out\n";
        $result->write( file => $out );
        push @output_images, $out;

        
        # Remove all frames that don't fit in the current processing window        
        if (@images > $frames) {
            my @remove = splice @images, 0, @images - $frames;
            #unlink @remove;
        };
        warn "Current frames: @images";
    };

    warn $output_images[0];
    my $dir = dirname $output_images[0];

    #$ffmpeg_out->combine( files => "$dir\\ffmpeg-%04d-out.png", outname => 'tmp.avi' );
    
    #unlink @frames;
    #unlink @output_images;
};

sub process_frame {
    my ($frame,$other_frames) = @_;
    
    return unless @$other_frames;
    
    my $res = Imager->new( file => $frame );
    
    # we only take the current and previous frame:
    warn "$frame <= $other_frames->[0]\n";
    my @info = sift( $frame, $other_frames->[0] );
    
    for (@info) {
        #use Data::Dumper;
        #warn Dumper $_;
        my $green = Imager::Color->new( 0, 255, 0 );
        $res->line(
            color => $green,
            x1 => $_->[0],
            y1 => $_->[1],
            x2 => $_->[0]+1,
            y2 => $_->[1]+1,
        );
    };
    
    $res
};

package FFmpeg::Cmd;
use strict;
use IPC::Open3;
use File::Temp;
use File::Spec::Functions;
use File::Glob qw(bsd_glob);

sub stream_info {
    my ($self,$filename) = @_;
    my ($child_in, $stream, $info);
    my $cmd = sprintf qq{%s -t 0 -i "%s" -},
        $self->{ffmpeg},
        $filename
    ;
    my $pid = open3 $child_in, $stream, $stream, $cmd
        or die "Couldn't spawn '$cmd': $!/$?";

    my %res;

    while (my $line = <$stream>) {
        #print ">>$line";
        if ($line =~ /\bVideo: .*/) {
            chomp $line;
            #print ">$line<\n";
            @res{qw<width height>} = ($line =~ /(\d+)x(\d+)/);
        } elsif ($line =~ /\bDuration: (\d+:\d\d:\d\d\.\d\d),/) {
            @res{qw<duration>} = ($1);
        };
    };
    \%res;
};

sub new {
    my ($class,%args) = @_;
    my $file = delete $args{filename};
    die "No file: '$file'"
        unless -f $file or $file eq '0';

    my $self = bless {
        ffmpeg   => 'ffmpeg',
        filename => $file,
        %args,
    }, $class;
    
    $self->{info} = $self->stream_info($file);
    $self
};

sub cmd {
    my ($self, @args) = @_;

    my $cmd =
        join " ", 
        $self->{ffmpeg},
        "@args",
    ;
    print "[$cmd]\n";
    system( $cmd ) == 0
        or die "Couldn't spawn [$cmd]: $! / $?";
};

sub to_png {
    my ($self, %options) = @_;
    $options{ tempdir } ||= File::Temp::tempdir();
    #$options{ framecount } ||
    
    $self->cmd(
        '-i' => $self->{filename},
        '-f' => 'image2',
        #'-ss' => '00:00:00.00',
        #'-t' => 1,
        '-r' => '59.33',
        catfile( $options{ tempdir }, 'ffmpg-%04d.png' ),
    );
    
    bsd_glob "$options{ tempdir }/*.png";
};

sub combine {
    my ($self, %options) = @_;
    $options{ tempdir } ||= File::Temp::tempdir();
    #$options{ framecount } ||
    
    $self->cmd(
        '-f' => 'image2',
        '-i' => $options{ files },
        #'-ss' => '00:00:00.00',
        #'-t' => 1,
        '-r' => '59.33',
        $options{ outname },
    );
    
    return $options{ outname }
};

1;