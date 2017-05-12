package FFmpeg::Command;

use warnings;
use strict;
our $VERSION = '0.19';

use base qw( Class::Accessor::Fast Class::ErrorHandler );
__PACKAGE__->mk_accessors(qw/
    input_file
    output_file
    ffmpeg
    options
    global_options
    infile_options
    outfile_options
    timeout
    stdin
    stdout
    stderr
    command
 /);

use IPC::Run qw( start );
use Carp qw( carp );

our %option = (
    format              => '-f',
    video_codec         => '-vcodec',
    bitrate             => '-b',
    frame_rate          => '-r',
    frame_size          => '-s',
    audio_codec         => '-acodec',
    audio_sampling_rate => '-ar',
    audio_bit_rate      => '-ab',
    size                => '-s',
);

our %metadata = (
    title               => 'title=',
    author              => 'author=',
    comment             => 'comment=',
);

sub new {
    my $class = shift;

    my $command;

    for my $cmd ( shift || 'ffmpeg', 'avconv' ) {
        system("$cmd -version > /dev/null 2>&1");
        my $ret = $? >> 8;
        if ( $ret == 0 || $ret == 1 ) {
            $command = $cmd;
            last;
        }
    }
    unless ( $command ) {
        carp "Can't find ffmpeg/avconv command.";
        exit 0;
    }

    my $self            =  {
        ffmpeg          => $command,
        options         => [],
        global_options  => [],
        infile_options  => [],
        outfile_options => [],
        input_file      => [],
        output_file     => '',
        timeout         => 0,
    };

    bless $self, $class;
}

sub input_options {
    my ( $self, $args ) = @_;
    $self->input_file($args->{file} || $args->{'files'});
    return;
}

sub output_options {
    my ( $self, $args ) = @_;
    $self->output_file(delete $args->{file});
    my $device = delete $args->{device};

    my %device_option = (
        ipod => {
            format              => 'mp4',
            video_codec         => 'mpeg4',
            bitrate             => 600,
            frame_size          => '320x240',
            audio_codec         => 'libfaac',
            audio_sampling_rate => 48000,
            audio_bit_rate      => 64,
        },
        psp => {
            format              => 'psp',
            video_codec         => 'mpeg4',
            bitrate             => 600,
            frame_size          => '320x240',
            audio_codec         => 'libfaac',
            audio_sampling_rate => 48000,
            audio_bit_rate      => 64,
        },
    );

    my %output_option = (
        %$args,
    );

    # if a device name was supplied, add its output options
    if( $device ) {
        %output_option = (
            %output_option,
            %{ $device_option{$device} },
        );
    }

    for ( keys %output_option ){
        if( defined $option{$_} and defined $output_option{$_} ){
            push @{ $self->outfile_options }, $option{$_}, $output_option{$_};
        }
        elsif( defined $metadata{$_} and defined $output_option{$_} ){
            push @{ $self->outfile_options }, '-metadata', $metadata{$_} . $output_option{$_};
        }
        else {
            carp "$_ is not defined and ignored.";
        }
    }

    return;
}

sub execute {
    my $self = shift;

    my @opts = map { $self->{$_}  ? $self->{$_}  : \$self->{$_} } qw/stdin stdout stderr/;
    push @opts, IPC::Run::timeout($self->timeout) if $self->timeout;

    my $cmd = $self->_compose_command;

    # store the command line so we can debug it
    $self->command( join( ' ', @$cmd ) );

    my $h = eval {
        start( $cmd, @opts )
    };

    if( $@ ){
        $self->error($@);
        return;
    }
    else {
        finish $h or do {
            $self->error($self->stderr);
            return;
        };
    }

    return 1;
}

*exec = \&execute;

sub _compose_command {
    my $self = shift;

    my $files = $self->input_file;
    $files = [ $files ] unless ref $files eq 'ARRAY';

    my $cmd = [
        $self->ffmpeg,
        '-y',
        @{ $self->global_options },
        map ( { @{ $self->infile_options }, ( '-i', $_ ) } @$files ),
        @{ $self->options },
        @{ $self->outfile_options },
    ];

    # add output file only if we have one
    push @$cmd, $self->output_file
        if $self->output_file;

    return $cmd;
}

__END__

=head1 NAME

FFmpeg::Command - A wrapper class for ffmpeg/avconv command line utility.

=head1 DESCRIPTION

A simple interface for using ffmpeg command line utility with fallback to use
the newer avconv utility if ffmpeg is not installed.

=head1 SYNOPSIS

    use FFmpeg::Command;

    my $ffmpeg = FFmpeg::Command->new('/usr/local/bin/ffmpeg');

    # Set timeout
    $ffmpeg->timeout(300);

    # ga: global  option a, gb: global  option b
    # ia: infile  option a, ib: infile  option b
    # oa: outfile option a, ob: outfile option b

    # ffmpeg -y -ga -gb -ia -ib -i filename1 -oa -ob output_file
    $ffmpeg->global_options(qw/-ga -gb/);
    $ffmpeg->infile_options(qw/-ia -ib/);
    $ffmpeg->outfile_options(qw/-oa -ob/);
    $ffmpeg->input_file('filename1');
    $ffmpeg->output_file('output_file');

    my $result = $ffmpeg->exec();
    croak $ffmpeg->errstr unless $result;

    # ffmpeg -y -i filename1 -ga -gb -ia -ib -oa -ob output_file
    $ffmpeg->options(qw/-ga -gb -ia -ib -oa -ob/);
    $ffmpeg->input_file('filename1');
    $ffmpeg->output_file('output_file');

    $ffmpeg->exec();

    # ffmpeg -y -ga -gb -ia -ib -i filename1 -ia -ib -i filename2 -oa -ob output_file
    # Infile options are adopted for every input files
    $ffmpeg->global_options(qw/-ga -gb/);
    $ffmpeg->infile_options(qw/-ia -ib/);
    $ffmpeg->outfile_options(qw/-oa -ob/);
    $ffmpeg->input_file(['filename1','filename2']);
    $ffmpeg->output_file('output_file');

    $ffmpeg->exec()

    # ffmpeg -y -ga -gb -ia1 -ib1 -i filename1 -ia2 -ib2 -i filename2 -oa -ob output_file
    # Each input file has different infile options
    $ffmpeg->options(qw/-ga -gb -ia1 -ib1 -i filename1 -ia2 -ib2 -i filename2 -oa -ob output_file/);

    $ffmpeg->exec()

    # This sample code takes a screen shot.
    $ffmpeg->input_file($input_file);
    $ffmpeg->output_file($output_file);

    $ffmpeg->options(
        '-f'       => 'image2',
        '-pix_fmt' => 'jpg',
        '-vframes' => 1,
        '-ss'      => 30,
        '-s'       => '320x240',
        '-an',
    );

    $ffmpeg->exec()

    # Below are old style example(may be obsoleted at future release)
    $ffmpeg->input_options({
        file => $input_file,
    });

    # Convert a video file into iPod playable format.
    $ffmpeg->output_options({
        file   => $output_file,
        device => 'ipod',
    });

    # This is same as above.
    $ffmpeg->output_options({
        file                => $output_file,
        format              => 'mp4',
        video_codec         => 'mpeg4',
        bitrate             => 600,
        frame_size          => '320x240',
        audio_codec         => 'libaac',
        audio_sampling_rate => 48000,
        audio_bit_rate      => 64,
    });

    # Convert a video file into PSP playable format.
    $ffmpeg->output_options({
        file  => $output_file,
        device => 'psp',
    });

    # This is same as above.
    $ffmpeg->output_options({
        file                => $output_file,
        format              => 'psp',
        video_codec         => 'mpeg4',
        bitrate             => 600,
        frame_size          => '320x240',
        audio_codec         => 'libaac',
        audio_sampling_rate => 48000,
        audio_bit_rate      => 64,
    });



=head1 METHODS

=head2 new('/usr/bin/ffmpeg')

Contructs FFmpeg::Command object.It takes a path of ffmpeg command.
You can omit this argument and this module searches ffmpeg command within PATH environment variable.

=head2 timeout()

Set command timeout.Default is 0.

=head2 input_file( @files );

Specify names of input file(s).

=head2 output_file('/path/to/output_file')

Specify output file name.

=head2 global_options( @options )

Specify ffmpeg global options.

=head2 infile_options( @options )

Specify ffmpeg infile options.

=head2 outfile_options( @options )

Specify ffmpeg outfile options.


=head2 options( @options )

Specify ffmpeg command options directly including input files and and output file.

=head2 execute()

Executes ffmpeg command with specified options.

=head2 exec()

An alias of execute()

=head2 stdout()

Get ffmpeg command output to stdout.

=head2 stderr()

Get ffmpeg command output to stderr.

=head2 input_options({ %options })

Specify input file name and input options.(Now no options are available.)

=over

=item file

a file name of input file or an anonymous list of multiple input files
(useful for merging audio and video files together).

=back

=head2 output_options({ %options })

Specify output file name and output options.

Avaiable options are:

=over

=item file

a file name of output file.

=item format

Output video format.

=item video_codec

Output video codec.

=item bitrate

Output video bitrate.

=item frame_size

Output video screen size.

=item audio_codec

Output audio code.

=item audio_sampling_rate

Output audio sampling rate.

=item audio_bit_rate

Output audio bit rate.

=item title

Set the title.

=item author

Set the author.

=item comment

Set the comment.

=back

=head1 AUTHORS

Gosuke Miyashita, C<< <gosukenator at gmail.com> >>

Munechika Sumikawa, C<< <sumikawa at sumikawa.jp> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-ffmpeg-command at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FFmpeg-Command>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FFmpeg::Command

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FFmpeg-Command>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FFmpeg-Command>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FFmpeg-Command>

=item * Search CPAN

L<http://search.cpan.org/dist/FFmpeg-Command>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Gosuke Miyashita, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
