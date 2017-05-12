package FFmpeg::Stream::Helper;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use String::ShellQuote;

=head1 NAME

FFmpeg::Stream::Helper - Helper for streaming and transcoding using ffmpeg.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 SYNOPSIS

This module is for helping generate a command for ffmpeg that should be good for streaming to HTML5.

This module also does it securely by using String::ShellQuote for every definable option passed to ffmpeg.

    # Defaults Are...
    # Output: -  ((standard out))
    # Bit Rate: 2000 kbps
    # Bound: undef
    # Format: mp4
    # Log Level: quiet
    # Threads: 0
    my $fsh=FFmpeg::Stream::Helper->new;

    #sets the bit rate to 1500
    $fsh->bitRateSet('1500');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

    # Enable printing of errors.
    $fsh->loglevelSet('error');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

    # set the width bound to 800 for scaling
    # aspect will be kept
    $fsh->boundSet('800');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }    

    # Disable pretty much all error output. This is great if you are sending stuff
    # to STDOUT and what you are sending it to can't tell the difference between it
    # and STDERR
    $fsh->loglevelSet('quiet');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

    # What? No. We can't stop here. This is bat country.
    my $command=$fsh->command('/arc/video/movies/Fear and Loathing in Las Vegas.avi');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=head1 METHODS

=head2 new

Inits a new object for use.

No need for error checking. This will always succeed.

    my $fsh=FFmpeg::Stream::Helper->new;

=cut

sub new{
	my $self={
		error=>undef,
		errorString=>'',
		perror=>undef,
		errorExtra=>{
			flags=>{
				1=>'fileUNDEF',
				2=>'noFile',
				3=>'notINT',
				4=>'formatUNDEF',
				5=>'invalidFormat',
				6=>'loglevelUNDEF',
				7=>'invalidLoglevel',
				8=>'threadsUNDEF',
				9=>'threadsBadVal',
			},
		},
		output=>'-',
		bound=>undef,
		kbps=>2000,
		loglevel=>'quiet',
		threads=>'0',
		format=>'webm',
	};
	bless $self;

	return $self;
}	

=head2 bitRateGet

Returns the kilobits per second used for encoding.

    my $kbps=$fsh->boundGet;
    print "Bit Rate: ".$kbps."kbps\n"

=cut

sub bitRateGet{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}
	
	return $self->{kbps};
}

=head2 bitRateSet

This sets the bitrate.

One argument is required and that is a integer represting the kilobits per second.

    $fsh->bitRateSet('1500');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=cut

sub bitRateSet{
	my $self=$_[0];
	my $kbps=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	#makes sure it is a integer
	if ( $kbps !~ /^[0123456789]*$/ ){
		$self->{error}=3;
		$self->{errorstring}='"'.$kbps.'" is not a integer';
		$self->warn;
		return undef;
	}

	$self->{kbps}=$kbps;

	return 1;
}

=head2 boundGet

Returns the current width bound for scaling the video.

    my $bound=$fsh->boundGet;
    if ( ! defined( $bound ) ){
        print "No bound set.\n";
    }else{
        print "Bound: ".$bound."\n"
    }

=cut

sub boundGet{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}
	
	return $self->{bound};
}

=head2 boundSet

Sets a new bound. The bound is the maximum size the width can be while keeping aspect when it is scaled.

One argument is taken and that is the integer to use found bounding.

If undef is specified, then no scaling will be done.

    #calls it with a the bound being undef, removing it
	$fsh->boundSet;

    #sets it to 900px
    $fsh->boundSet('900');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=cut

sub boundSet{
	my $self=$_[0];
	my $bound=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	#removes the bound if it is undefined
	if ( ! defined( $bound ) ){
		$self->{bound}=undef;
		return 1;
	}

	#makes sure it is a integer
	if ( $bound !~ /^[0123456789]*$/ ){
		$self->{error}=3;
		$self->{errorstring}='"'.$bound.'" is not a integer';
		$self->warn;
		return undef;
	}

	$self->{bound}=$bound;
	
	return 1;
}

=head2 command

The command to run ffmpeg with the specified options.

One argument is taken and that is the file name to run it for.

Escaping it is not needed as String::ShellQuote is used for
that as well as any of the other values being passed to it.

    my $command=$fsh->command('/arc/video/movies/Fear and Loathing in Las Vegas.avi');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=cut
	
sub command{
	my $self=$_[0];
	my $file=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	#make sure we havea file
	if ( ! defined( $file ) ){
		$self->{error}=1;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	#make sure the file exists
	if ( ! -f $file ){
		$self->{error}=2;
		$self->{errorString}='"'.$file.'" does not exist or not a file';
		$self->warn;
		return undef;
	}

	#only include the bound if it is defined
	my $bound='';
	if ( defined( $self->{bound} ) ){
		$bound=' -vf scale='.shell_quote($self->{bound}).':-1 ';
	}

	my $command='';

	if ( $self->{format} eq 'webm' ){
		$command='ffmpeg -i '.shell_quote($file).
			' -loglevel '.shell_quote($self->{loglevel}).
			$bound.
			' -f webm -c:v libvpx -maxrate '.$self->{kbps}.'k -preset superfast -threads 0'.
			' '.shell_quote($self->{output});
	}else{
		# ffmpeg -ss %o -i %s -async 1 -b %bk -s %wx%h -ar 44100 -ac 2 -v 0 -f flv -vcodec libx264 -preset superfast -threads 0 -
		$command='ffmpeg -i '.shell_quote($file).
			' -async 1 -b '.shell_quote($self->{kbps}).'k '.
			' -ar 44100 -ac 2 -v 0 -f '.shell_quote($self->{format}).
			' -loglevel '.shell_quote($self->{loglevel}).
			$bound.
			' -vcodec libx264 -preset superfast -threads '.shell_quote($self->{threads}).
			' -g 52 -movflags frag_keyframe+empty_moov'.
			' '.shell_quote($self->{output});

	}
	return $command;
}

=head2 formatGet

Returns the current format to be used.

    my $format=$fsh->formatGet;
    print "Format: ".$format."\n";

=cut

sub formatGet{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{format};
}

=head2 formatSet

Sets the new format to use.

One argument is required and that is the format to use. The following are supported.

    mp4
    webm
    ogg

    $fsh->formatSet('webm');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=cut

sub formatSet{
	my $self=$_[0];
	my $format=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	#makes sure we have a format
	if ( ! defined( $format ) ){
		$self->{error}=4;
		$self->{errorString}='No format specified';
		$self->warn;
		return undef;
	}

	#makes sure we have a valid format
	if (
		( $format ne 'mp4' ) &&
		( $format ne 'webm' ) &&
		( $format ne 'ogg' )
		){
		$self->{error}=5;
		$self->{errorString}='"'.$format.'" is not a valid format';
		$self->warn;
		return undef;
	}
	
	$self->{format}=$format;
	
	return 1;
}

=head2 loglevelGet

Returns what it is currently set to output to.

    my $output=$fsh->outputGet;
    print "Output: ".$output."\n";

=cut
	
sub loglevelGet{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{output};
}

=head2 loglevelSet

This sets the -loglevel for ffmpeg. Please see the man for that for the value.

One argument is taken and that is the -loglevel to use.

Currently it only recognizes the text version, which are as below.

    quiet
    panic
    fatal
    error
    warning
    info
    verbose
    debug
    trace


    $fsh->loglevelSet('panic');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=cut

sub loglevelSet{
	my $self=$_[0];
	my $loglevel=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	#makes sure we have a -loglevel defined
	if ( ! defined( $loglevel ) ){
		$self->{error}=6;
		$self->{errorString}='Loglevel is undefined.';
		$self->warn;
		return undef;
	}
	
	#makes sure we have a valid -loglevel
	if (
		( $loglevel ne 'quiet' ) &&
		( $loglevel ne 'panic' ) &&
		( $loglevel ne 'fatal' ) &&
		( $loglevel ne 'fatal' ) &&
		( $loglevel ne 'error' ) &&
		( $loglevel ne 'warning' ) &&
		( $loglevel ne 'info' ) &&
		( $loglevel ne 'verbose' ) &&
		( $loglevel ne 'debug' ) &&
		( $loglevel ne 'trace' )
		){
		$self->{error}=7;
		$self->{errorString}='"'.$loglevel.'" is not a valid -loglevel';
		$self->warn;
		return undef;
	}

	$self->{loglevel}=$loglevel;
	
	return 1;
}

=head2 presetsGet

Return the current x264 -preset value.

    my $output=$fsh->outputGet;
    print "Output: ".$output."\n";

=cut
	


=head2 outputGet

Returns what it is currently set to output to.

    my $output=$fsh->outputGet;
    print "Output: ".$output."\n";

=cut
	
sub outpubGet{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{output};
}

=head2 outputSet

The file to output to. If not specified, "-" will be used.

One argument is required and that is the what it should output to.

There is no need to escape anything as that is handled by String::ShellQuote.

    #output to STDOUT
    $fsh->outputSet('-');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

    #output to '/tmp/Fear and Loathing in Las Vegas.mp4'
    $fsh->outputSet('/tmp/Fear and Loathing in Las Vegas.mp4');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=cut
	
sub outpubSet{
	my $self=$_[0];
	my $output=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	if ( ! defined( $output ) ){
		$self->{error}=1;
		$self->{errorString}='No file specified';
		$self->warn;
		return undef;
	}

	$self->{output}=$output;
	
	return 1;
}

=head2 threadsGet

Gets the number of threads to use.

    my $threads=$fsh->threadsGet;
    if ( ( $threads eq '0' ) || ( $threads eq 'auto' ) ){
        print "The number of threads will automatically be determined.\n";
    }else{
        print $threads." threads will be used for this.\n";
    }

=cut

sub threadsGet{
	my $self=$_[0];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	return $self->{threads};
}

=head2 threadsSet

Sets the number of threads to use for encoding.

One argument is taken and that is a integeer representing the number of threads.

'auto' may also be specified and should be the same as '0'. If either are specified,
ffmpeg will choose the best thread count.

    $fsh->threadsSet('0');
    if ( $fsh->error ){
        warn('error:'.$fsh->error.': '.$fsh->errorString);
    }

=cut

sub threadsSet{
	my $self=$_[0];
	my $threads=$_[1];
	
	#blank any previous errors
	if(!$self->errorblank){
		return undef;
	}

	# 
	if ( ! defined( $threads ) ){
		$self->{error}=8;
		$self->{errorString}='Nothing specified for threads.';
		$self->warn;
		return undef;
	}

	if ( ( $threads ne 'auto' ) &&
		 ( $threads !~ /[0123456789]*/ ) ){
		$self->{error}=9;
		$self->{errorString}='"'.$threads.'" is not a valid value for -threads';
		$self->warn;
		return undef;
	}
	
	$self->{threads}=$threads;
	
	return 1;
}

=head1 ERROR CODES/FLAGS

=head2 1/fileUNDEF

No file specified.

=head2 2/noFile

File does not exist or is not a file.

=head2 3/notINT

Not an integer.

=head2 4/formatUNDEF

Format is undef.

=head2 5/invalidFormat

Not a valid format. Must be one of the ones below.

    mp4
    webm
    ogg

The default is mp4.

=head2 6/loglevelUNDEF

Nothing specified to use for -loglevel.

=head2 7/invalidLoglevel

Not a valid -loglevel value.

The ones recognized by name are as below.

    quiet
    panic
    fatal
    error
    warning
    info
    verbose
    debug
    trace

Please see the ffmpeg man for descriptions.

=head2 8/threadsUNDEF

No value specified for what to use for -threads.

=head2 9/threadsBadVal

A bad value has been specified for threads. It needs to match one of the ones below.

    /^auto$/
    /[0123456789]*/

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ffmpeg-stream-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FFmpeg-Stream-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FFmpeg::Stream::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FFmpeg-Stream-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FFmpeg-Stream-Helper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FFmpeg-Stream-Helper>

=item * Search CPAN

L<http://search.cpan.org/dist/FFmpeg-Stream-Helper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of FFmpeg::Stream::Helper
