##------------------------------------------------------------------------
##  Package: Info.pm
##   Author: Benjamin R. Ginter, Allen Day
##   Notice: Copyright (c) 2001 Benjamin R. Ginter, Allen Day
##  Purpose: Extract information about MPEG files.
## Comments: None
##      CVS: $Id: Info.pm,v 1.10 2002/02/13 08:27:51 synaptic Exp $
##------------------------------------------------------------------------

package MPEG::Info;

require 5.005_62;
use strict;
use warnings;
use vars qw($VERSION @ISA);

use Video::Info;
use Video::Info::Magic;

use MPEG::Info::Constants;

use MPEG::Info::Audio;
use MPEG::Info::Video;
#use MPEG::Info::System;  ## The next version will use this.  Let's release.

use constant DEBUG => 0;

@ISA = qw( Video::Info );

our %FIELDS = ( version => 1,
		size    => 0,
		);

for my $datum ( keys %FIELDS ) {
    no strict "refs"; ## to register new methods in package
    *$datum = sub {
        shift; ## XXX: ignore calling class/object
        $FIELDS{$datum} = shift if @_;
        return $FIELDS{$datum};
    }
}

our $VERSION = '1.00';

$| = 1;


1;

##------------------------------------------------------------------------
## Override superclass constructor
##------------------------------------------------------------------------
sub new {
    my $proto = shift;
    my $class = ref( $proto ) || $proto;
    my $self = { 
	offset              => 0,
#	size                => 0,
	audio_system_header => 0,
	video_system_header => 0,
#	version             => 1,
		 @_, };
    bless( $self, $class );

    ## TODO: Can these be loaded dynamically?
    ## e.g. If we have a file that contains only video, how can we avoid
    ##      compiling MPEG::Info::Audio?  Would this involve calling the
    ##      object method MPEG::Info::Audio::is_audio() before require()?
    $self->{audio} = MPEG::Info::Audio->new();
    $self->{video} = MPEG::Info::Video->new();
    # $self->{system} = MPEG::Info::System->new();
    
    ## this hyphen stuff is kind of retarded :)
    ## doesn't this date back to some perl4 thing?
    $self->handle( $self->{-file} );
    
    return $self;
}

##------------------------------------------------------------------------
## probe()
##
## Probe the file for content type
##------------------------------------------------------------------------
sub probe {
    print "probe()\n" if DEBUG;
    my $self      = shift;
    $self->size( -s $self->{-file} );

    if ( $self->parse_system ) {
	  print "MPEG Audio/Video\n" if DEBUG;
	  $self->acodec($self->audio->acodecraw);
	  return 1;
    }
    elsif ( $self->audio->parse ) {
	  print "MPEG Audio Only\n" if DEBUG;
	  $self->acodec($self->audio->acodecraw);
	  $self->astreams(1); #are you sure? could be multiple audio...
	  $self->vstreams(0);
	  return 1;
    }
    elsif ( $self->video->parse ) {
	  print "MPEG Video Only\n" if DEBUG;
	  $self->vstreams(1); #are you sure? could be multiple video...
	  $self->astreams(0);
	  $self->vcodec( 'MPEG1' ) if $self->vcodec eq '';
	  return 1;
    }

    return 0;
}

sub audio { $_[0]->{audio} };
sub video { $_[0]->{video} };


##------------------------------------------------------------------------
## parse_system()
##
## Parse a system stream
##------------------------------------------------------------------------
sub parse_system {
    my $self   = shift;
    my $fh     = $self->handle;
    my $offset = 0;

    my ( $pack_start, $pack_len, $pack_head, $packet_size, $packet_type );
    # print '-' x 74, "\n", "Parse System\n", '-' x 74, "\n";

    ## Get the first sequence start code (ssc)
    if ( !$self->next_start_code( PACK_PKT ) ) {
	print "Couldn't find packet start code\n" if DEBUG;
	return 0;
    }

    $offset = $self->{last_offset};

    # print "Found system stream start code at $self->{last_offset} $self->{offset}\n";

    if ( $self->{last_offset} > 0 ) {
        print "Warning: junk at the beginning!\n" if DEBUG;
    }

    # print "Beginning Search for system packets (audio/video)\n";

    while ( $offset <= $self->size ) {
	# print '-' x 20, '[ LOOP ]', '-' x 20, "\n";
	# print " OFFSET: $self->{offset} $offset\n";
	
	my $code = $self->next_start_code( undef, $offset );

	$offset = $self->{last_offset};
	#  printf( "Found marker '%s' (0x%02x) at %d\n", 
        #       $STREAM_ID->{$code},
        #       $code, 
        #	$offset );

	if ( $code == VIDEO_PKT || $code == AUDIO_PKT ) {
	    # print "Audio or Video @ $offset\n";
	    last;
	}

	## if this is a padding packet
	elsif ( $code == PADDING_PKT ) {
	    # print "\t\tFound Padding Packet at $offset\n";
	    $offset += $self->grab( 2, $offset + 4 );
	    # print "Skipped to $offset\n";
	    next;
	}

	## if this is a PACK
	elsif ( $code == PACK_PKT ) {
	    $self->{muxrate} = $self->get_mux_rate( $offset + 4);
	    $offset += 12;
	    next;
#	    System->muxrate = ReadPACKMuxRate(offset + 4);
#	    offset += 12;   ## standard pack length
#		continue;
	}
	
	## No more guessing
	elsif ( $code != SYS_PKT ) {
	    # printf( "1: Unhandled packet encountered '%s' ( 0x%02x ) at offset %d\n", 
	    #	    $STREAM_ID->{$code},
	    #	    $code, 
	    #	    $offset );
	    $offset += 4;
	    next;
	}

	## It has to be a system packet
	## print "Expecting PACK system start packet\n";

	## Check for variable length PACK in mpeg2
	my $real_offset = $offset;
	if ( !$self->next_start_code( PACK_PKT, 0 ) ) {
	    print "Can't find system sequence start code!\n" if DEBUG;
	    return 0;
	}
	
	# printf "Found start of pack marker at %d.\n", $self->{last_offset};

	## Found a PACK before system packet, compute it's size (mpeg1 != mpeg2)
	$pack_start = $self->{last_offset};
	$pack_len   = 0;
	$pack_head  = $self->get_byte( $pack_start + 4 );

	# printf "pack_head: 0x%02x 0x%02x 0x%02x\n", $pack_head, $pack_head & 0xf0, $pack_head & 0xc0;
	if ( ( $pack_head & 0xF0 ) == 0x20 ) {
	  $self->vcodec('MPEG1');
	    print "MPEG1\n" if DEBUG;
	    $pack_len = 12;
	}
	else {
	    if ( ( $pack_head & 0xC0 ) == 0x40 ) {
		## new mpeg2 pack : 14 bytes + stuffing
		  $self->vcodec('MPEG2');
		print "MPEG2\n" if DEBUG;
		$pack_len = 14 + $self->get_byte( $pack_start + 13 ) & 0x07;
	    }
	    else {
		## whazzup?!
		printf "Weird pack encountered! 0x%02x\n", $pack_head if DEBUG;
		$pack_len = 12;
	    }
	}

	if ( $pack_start + $pack_len != $offset ) {
	    print "FATAL: The PACK Start offset + length don't match the current offset!\n" if DEBUG;
	    print "FATAL: $pack_start + $pack_len != $offset\n" if DEBUG;
## While we should be dying here, it doesn't seem to hurt if we don't?
# ??	    die;
	}

	## let's go
	if ( !$self->parse_system_packet( $offset, $pack_start ) ) {
	    print "Strange number of packets!\n" if DEBUG;
	    die;
	}

	# print "\n", '-' x 74, "\nResume Parse System\n", '-' x 74, "\n";

	$packet_size = $self->grab( 2, $offset + 4 );
	$packet_type = $self->get_byte( $offset + 12 );
	# print "Packet Size: $packet_size\n";
	# printf "Packet Type: $packet_type '%s' (0x%02x)\n", 
	#    $STREAM_ID->{$packet_type},
	#    $packet_type;

	my $byte = $self->get_byte( $offset + 15 );
	# printf "Fetched: '%s' (0x%02x)\n", $STREAM_ID->{$byte}, $byte;
	if ( $byte == AUDIO_PKT || $byte == VIDEO_PKT ) {
	    # print "System packet with both audio and video\n";
	    $packet_type = VIDEO_PKT;
	}
       
	## I've never seen a pack with a leading audio packet though
	## that might be because i force the packet type to VIDEO.  
	## Man, a spec would be so nice. :)
	## 
	## TODO: Actually fetch the audio and video header and use 
	##       the stored data when parsing the audio and video.

	my $audio_header_len = 0;
	my $video_header_len = 0;

	if ( $packet_type == AUDIO_PKT ) {
	    ## check for multiple audio system packet headers
	    # print "Audio\n";
	    
	    if ( $self->{audio_system_header} != 0 ) {
		print "Warning: two or more audio system headers encountered ( $offset )\n" if DEBUG;
		undef $self->{audio_system_header};
	    }

	    seek $fh, $offset - $pack_len, 0;
	    $audio_header_len = $pack_len + 4 + 2 + $packet_size;
	    
	    if ( read( $fh, $self->{audio_system_header}, $audio_header_len ) != $audio_header_len ) {
		print "Couldn't read the audio system header\n" if DEBUG;
		return 0;
	    }

	}
	elsif ( $packet_type == VIDEO_PKT ) {
	    ## check for multiple video system packet headers
	    if ( $self->{video_system_header} != 0 ) {
		print "Warning: two or more video system headers encountered ( $offset )\n" if DEBUG;
		undef $self->{audio_system_header};
	    }

	    $video_header_len = $pack_len + 6 + $packet_size;

	    ## keep track of the initial timestamp
	    if ( $pack_len == 12 ) {
		$self->{initial_ts} = $self->read_ts( $offset - $pack_len, 0 );
	    }
	    else {
		$self->{initial_ts} = $self->read_ts( $offset - $pack_len, 1 );
	    }
	    
	    seek $fh, $offset - $pack_len, 0;

	    if ( read( $fh, $self->{video_system_header}, $video_header_len ) != $video_header_len ) {
		print "Couldn't read the video system header\n" if DEBUG;
		return 0;
	    }
	}
	else {
	    printf "Unknown system packet '%s', %x @ $offset\n", $STREAM_ID->{$packet_type},
	                                                         $packet_type if DEBUG;
	    return 0;
	}

	$offset += 4;
    }

    ## okay, this is a miracle but we have what we wanted here

    ## hey wait, are we really ok?
    # print "\n\nVerifying video_system_header exists...";
    if ( !$self->{video_system_header} ) {
	# print "Didn't find any video system header in this mpeg system file\n";
	return 0;
    }
    # print "OK\n";

    ## okay, let's go on and find the video and audio infos

    ## video!
    # print "1. Finding sequence start code...";
    if ( !$self->next_start_code( SEQ_HEAD, $offset ) ) {
	print "Didn't find any video sequence header in this MPEG system file!\n" if DEBUG;
	return 0;
    }
    # print "OK ($offset $self->{offset} $self->{last_offset})\n";

    # print "Parsing Video at offset $offset\n";
    ## mmm k, we have the video sequence header
    if ( !$self->video->parse( $offset ) ) {
	print "parse_system: call to parse_video() failed\n" if DEBUG;
	return 0;
    }
    # print "OK\n";

    ## now get the pack and the packet header just before the video sequence
    if ( !$self->next_start_code( PACK_PKT, 0 ) ) {
	print "Didn't find any PACK before video sequence\n" if DEBUG;
	return 0;
    }
    # print "Got previous PACK: $offset $self->{offset} $self->{last_offset}\n";

    ## pack doesn't necessarily precede video sequence
    # print "Getting next\n";
    if ( !$self->next_start_code( VIDEO_PKT, $self->{last_offset} ) ) {
	print "Couldn't find video start code!\n" if DEBUG;
	die;
    }
    # print "Got VIDEO start code: $offset $self->{offset} $self->{last_offset}\n";

    my $main_offset = $offset;
    print "Finding audio\n" if DEBUG;
    if ( $self->next_start_code( AUDIO_PKT, $offset ) ) {
	print "Found it\n" if DEBUG;
	my $audio_offset = $self->skip_packet_header( $self->{last_offset} );
	# print "AUDIO OFFSET: $audio_offset $self->{last_offset} \n";
	
	AUDIO: while ( !$self->audio->parse( $audio_offset ) ) {
	    ## mm, audio packet doesn't begin with FFF
	    while ( $audio_offset < $self->size - 10 ) {
		if ( $self->audio->parse( $audio_offset ) ) {
		    last AUDIO;
		}
		
		$audio_offset++; ## is this ok?
	    }
	}
	# print "Parsed audio OK!\n";

    }        

## hrm, what is this
#      $offset = $self->{last_offset};
#      print "\tSearching for video stop code at $offset $self->{offset}\n";
#      while ( 1 ) {
#    	if ( $self->next_start_code( SEQ_HEAD, $offset ) ) {
#    	    print "\t\tFound video stop code 0x000001b3 at $offset $self->{last_offset}\n";
#   	    last;
#    	}
#    	$offset += 4;
#      }

    ## seek the file duration by fetching the last PACK
    ## and reading its timestamp
    ## Grab 13 bytes because a PACK is at least 12 bytes

    if ( $self->next_start_code( PACK_PKT, $self->size - 2500 ) ) {
	# print "Found final PACK at $self->{last_offset}\n";
    }
    # $self->{last_offset} = 2530997;
    my $byte = $self->get_byte( $self->{last_offset} + 4 );
    # printf "0x%02x 0x%02x 0x%02x\n", $byte, $byte & 0xF0, $byte & 0xC0;
  
    ## see if it's a standard MPEG1
    if ( $byte & 0xF0 == 0x20 ) {
	$self->duration( $self->read_ts( 1, $self->{last_offset} + 4 ) );
    }
    ## no?
    else {
	## Is it MPEG2?
	if ( $byte & 0xC0 == 0x40 ) {
	    print "TS: ", $self->read_ts( 2, $self->{last_offset} + 4 ), "\n" if DEBUG;
	}
	## try mpeg1 anyway
	else {
	    $self->duration( $self->read_ts( 1, $self->{last_offset} + 4) );
	}
    }
    

    return 1;
}

##------------------------------------------------------------------------
## parse_system_packet()
##
## Parse a system packet
##------------------------------------------------------------------------
sub parse_system_packet {
    my $self         = shift;
    my $packet_start = shift;
    my $pack_start   = shift;

    if ( !defined $packet_start || !defined $pack_start ) {
	die "parse_system_packet( packet_start, pack_start )\n";
    }

    # print "\n", '-' x 74, "\nParse System Packet\n", '-' x 74, "\n";

    my $size = $self->grab( 2, $packet_start + 4 );

    $size -= 6; ## ??
    
    ## TODO: Check if there's already a system packet
    if ( $size % 3 != 0 ) {
	return 0;
    }
    # else {
    #	printf("%d streams found\n", $size/3);
    # }

    for ( my $i = 0; $i < $size / 3; $i++ ) {
	my $code = $self->get_byte( $packet_start + 12 + $i * 3 );
	
	if ( ( $code & 0xf0 ) == AUDIO_PKT ) {
	    # print "Audio Stream\n";
	    $self->{astreams}++;
	}
	elsif ( ( $code & 0xf0 ) == VIDEO_PKT || ( $code & 0xf0 ) == 0xD0 ) {
	    # print "Video Stream\n";
	    $self->{vstreams}++;
	}
    }

    $self->astreams( $self->{astreams} );
    $self->vstreams( $self->{vstreams} );
    # print "\t", $self->astreams, " audio\n";
    # print "\t", $self->vstreams, " video\n";

    return 1;
}

##------------------------------------------------------------------------
## parse_user_data()
##
## Parse user data (usually encoder version, etc.)
##
## TODO: Can we use this for annotating video?
##------------------------------------------------------------------------
sub parse_user_data {
    my $self   = shift;
    my $offset = shift;

    # print "\n", '-' x 74, "\nParse User Data\n", '-' x 74, "\n";

    $self->next_start_code( undef, $offset + 1 );
    
    my $all_printable = 1;
    my $size          = $self->{last_offset} - $offset - 4;

    return 0 if $size <= 0;
    
    for ( my $i = $offset + 4; $i < $self->{last_offset}; $i++ ) {
	my $char = $self->get_byte( $i );
	if ( $char < 0x20  &&  $char != 0x0A  && $char != 0x0D ) {
	    $all_printable = 0;
	    last;
	}
    }
    
    if ( $all_printable ) {
	my $data;

	for ( my $i = 0; $i < $size; $i++ ) {
	    $data .= chr( $self->get_byte( $offset + 4 + $i ) );
	    
	}
	$self->{userdata} = $data;
	$self->comments( $data );
	# print $data, "\n";
    }
    
    return 1;
}

##------------------------------------------------------------------------
## parse_extension()
##
## Parse extensions to MPEG.. hrm, I need some examples to really test
## this. 
##------------------------------------------------------------------------
sub parse_extension {
    my $self   = shift;
    my $offset = ( shift ) + 4;
    
    my $code = $self->get_byte( $offset ) >> 4;
    
    if ( $code == 1 ) {
	return $self->parse_seq_ext( $offset );
    }
    elsif ( $code == 2 ) {
	return $self->parse_seq_display_ext( $offset );
    }
    else {
	die "Unknown Extension: $code\n";
    }
}

##------------------------------------------------------------------------
## parse_seq_ext()
##
## This stuff gets stored in the hashref $self->{sext}.  It will also
## modify width, height, vrate, and fps
##------------------------------------------------------------------------
sub parse_seq_ext {
    my $self   = shift;
    my $offset = shift;
    
    ## We are an MPEG-2 file
    $self->version( 2 );

    my $byte1 = $self->get_byte( $offset + 1 );
    my $byte2 = $self->get_byte( $offset + 2 );

    ## Progressive scan mode?
    if ( $byte1 & 0x08 ) {
	$self->{sext}->{progressive} = 1;
    }
    
    ## Chroma format
    $self->{sext}->{chroma_format} = ( $byte1 & 0x06 ) >> 1;

    ## Width
    my $hsize = ( $byte1 & 0x01 ) << 1;
    $hsize   |= ( $byte2 & 80 ) >> 7;
    $hsize  <<= 12;
    return 0 if !$self->{vstreams};
    $self->{width} |= $hsize;
    
    ## Height
    $self->{height} |= ( $byte2 & 0x60 ) << 7;;
    
    ## Video Bitrate
    my $bitrate = ( $byte2 & 0x1F ) << 7;
    $bitrate   |= ( $self->get_byte( $offset + 3 ) & 0xFE ) >> 1;
    $bitrate  <<= 18;
    $self->{vrate} |= $bitrate;

    ## Delay
    if ( $self->get_byte( $offset + 5 ) & 0x80 ) {
	$self->{sext}->{low_delay} = 1;
    }
    else {
	$self->{sext}->{low_delay} = 0;
    }

    ## Frame Rate
    my $frate_n = ( $self->get_byte( $offset + 5 ) & 0x60 ) >> 5;
    my $frate_d = ( $self->get_byte( $offset + 5 ) & 0x1F );
    
    $frate_n++; 
    $frate_d++;
    
    $self->{fps} = ( $self->{fps} * $frate_n ) / $frate_d;
    
    return 1;
}

##------------------------------------------------------------------------
## parse_seq_display_ext()
## 
## man, some specs would be nice
##------------------------------------------------------------------------
sub parse_seq_display_ext {
    my $self   = shift;
    my $offset = shift;
    
    my @codes = ();
    
    for ( 0..4 ) {
	push @codes, $self->get_byte( $offset + $_ );
    }

    $self->{dext}->{video_format} = ( $codes[0] & 0x0E ) >> 1;
    
    if ( $codes[0] & 0x01 ) {
	$self->{dext}->{colour_prim}   = $codes[1];
	$self->{dext}->{transfer_char} = $codes[2];
	$self->{dext}->{matrix_coeff}  = $codes[3];
	$offset += 3;
    }
    else {
	$self->{dext}->{color_prim}    = 0;
	$self->{dext}->{transfer_char} = 0;
	$self->{dext}->{matrix_coeff}  = 0;
    }

    $self->{dext}->{h_display_size} = $codes[1] << 6;
    $self->{dext}->{h_display_size} |= ( $codes[2] & 0xFC ) >> 2;
    
    $self->{dext}->{v_display_size} = ( $codes[2] & 0x01 ) << 13;
    $self->{dext}->{v_display_size} |= $codes[3] << 5;
    $self->{dext}->{v_display_size} |= ( $codes[4] & 0xF8 ) >> 3;

    return 1;
}

##------------------------------------------------------------------------
## next_start_code()
##
## Find the next sequence start code
##------------------------------------------------------------------------
sub next_start_code {
    my $self       = shift;
    my $start_code = shift;
    my $offset     = shift;
    my $debug      = shift || 0;

    my $fh         = $self->handle;

    $offset = $self->{offset} if !defined $offset;
    my $skip = 4;
    if ( !$offset ) {
	$skip = 1 if !defined $offset;
    }

#    print "Bytes Per Iteration: $skip\n" if $debug;
#    print "Got $start_code $offset $debug\n" if defined $start_code && $debug;

    print "Seeking to $offset\n" if $offset != $self->{offset} && DEBUG;
    seek $fh, $offset, 0;

    # die "CALLER: ", ref( $self ), " OFFSET: $offset\n";
    while ( $offset <= $self->size - 4 ) {
	# print "Grabbing 4 bytes from $offset\n";
	my $code = $self->grab( 4, $offset );
	my ( $a, $b, $c, $d ) = unpack( 'C4', pack( "N", $code ) );

	# printf "Found 0x%02x\n", $d;
	if ( $a == 0x00 && $b == 0x00 && $c == 0x01 ) {
	    if ( defined $start_code ) {
		if ( ref( $start_code ) eq 'ARRAY' ) {
		    foreach my $sc ( @$start_code ) {
			if ( $sc == $d ) {
			    print "Got it @ $offset!\n" if DEBUG;
			    $self->{last_offset} = $offset;
			    return 1;
			}
		    }
		} 
		else {
		    if ( $d == $start_code ) {
			print "Got it @ $offset!\n" if DEBUG;
			$self->{last_offset} = $offset;
			return 1;
		    }
		}
	    }
	    else {
		$self->{last_offset} = $offset;
		return $d;
	    }
	}
#	else {
#	    printf "Skipping 0x%02x 0x%02x 0x%02x 0x%02x @ offset %d\n", $a, $b, $c, $d, $offset;
#	}
	
	$offset++;
    }

    return 0 if defined $start_code;

    die "No More Sequence Start Codes Found!\n";
}

##------------------------------------------------------------------------
## get_mux_rate()
##
## Calculate the mux rate
##------------------------------------------------------------------------
sub get_mux_rate {
    my $self   = shift;
    my $offset = shift || $self->{offset};

    my $muxrate = 0;

    my $byte = $self->get_byte( $offset );

    if ( ( $byte & 0xC0 ) == 0x40 ) {
	$muxrate  = $self->get_byte( $offset + 6 ) << 14;
	$muxrate |= $self->get_byte( $offset + 7 ) << 6;
	$muxrate |= $self->get_byte( $offset + 8 ) >> 2;
    }
    else {
	## maybe mpeg1
	if ( ( $byte & 0xf0 ) != 0x20 ) {
	    print "Weird pack header while parsing muxrate (offset ", $offset, ")\n" if DEBUG;
	    # die;
	}

	$muxrate  = ( $self->get_byte( $offset + 5 ) & 0x7f ) << 15;
	$muxrate |=   $self->get_byte( $offset + 6 ) << 7;
	$muxrate |=   $self->get_byte( $offset + 7 ) >> 1;
    }
    
    $muxrate *= 50;
    return $muxrate;
}

##------------------------------------------------------------------------
## grab()
##
## Grab n bytes from current offset
##------------------------------------------------------------------------
sub grab {
    my $self   = shift;
    my $bytes  = shift || 1;
    my $offset = shift;
    my $debug  = shift || 0;

    my $data;
    my $fh     = $self->handle or die "Can't get filehandle: $!\n";

    $offset = $self->{offset} if !defined $offset;

    # print "GRAB: $fh $offset $bytes (called from ", ref( $self ), ")\n";

    ## Would it be good to cache the bytes we've read to avoid the penalty
    ## of a seek() and read() at the expense of memory?

    # print "grab: seeking to $offset to grab $bytes bytes\n";
    if ( tell( $fh ) != $offset ) {
	seek( $fh, $offset, 0 );
    }
    
    read( $fh, $data, $bytes );

    my $type;

    if ( $bytes == 1 ) {
	$type = 'C';
	# return unpack( 'C', $data );
    }
    elsif ( $bytes == 2 ) {
	$type = 'n';
	# return unpack( 'n', $data );
    }
    elsif ( $bytes == 4 ) {
	$type = 'N';
	# return unpack( 'N', $data );
    }
    else {
	return $data;
    }

    $data = unpack( $type, $data );
#      if ( defined $START_CODE->{ $data } ) {
#  	print "START CODE: $START_CODE->{ $data }\n";
#      }
#      elsif ( defined $STREAM_ID->{$data} ) {
#  	print "STREAM ID: $STREAM_ID->{ $data }\n";
#      }

    return $data;
}

##------------------------------------------------------------------------
## get_byte()
##
## Return a byte from the specified offset
##------------------------------------------------------------------------
sub get_byte {
    my $self = shift;
    return $self->grab( 1, shift );
}

##------------------------------------------------------------------------
## skip_packet_header()
##
## Skip a packet header
##------------------------------------------------------------------------
sub skip_packet_header {
    my $self   = shift;
    my $offset = shift;

    if ( $self->version == 1 ) {
	## skip startcode and packet size
	$offset += 6;

	## remove stuffing bytes
	my $byte = $self->get_byte( $offset );

	while ( $byte & 0x80 ) {
	    $byte = $self->get_byte( ++$offset );
	}

	## next two bytes are 01
	if ( ( $byte & 0xC0 ) == 0x40 ) {
	    $offset += 2;
	}
	
	$byte = $self->get_byte( $offset );

	if ( $byte & 0xF0 == 0x20 ) {
	    $offset += 5;
	}
	elsif ( $byte & 0xF0 == 0x30 ) {
	    $offset += 10;
	}
	else {
	    $offset++;
	}
	
	return $offset;
    }
    elsif ( $self->version == 2 ) {
	## this is a PES, easyer
	## offset + 9 is the header length (-9)
	return $offset + 9 + ( $self->get_byte + 8 );
    }
    else {
	return $offset + 10;
    }
}

##------------------------------------------------------------------------
## read_ts()
##
## Read an MPEG-1 or MPEG-2 timestamp
##------------------------------------------------------------------------
sub read_ts {
    my $self   = shift;
    my $type   = shift;
    my $offset = shift;

    my $ts = 0;

    if ( $type == 1 ) {
	my $highbit   = (   $self->get_byte( $offset     ) >> 3  ) & 0x01;
	my $low4bytes = ( ( $self->get_byte( $offset     ) >> 1  ) & 0x30 ) << 30;
	$low4bytes   |= (   $self->get_byte( $offset + 1 ) << 22 );
	$low4bytes   |= ( ( $self->get_byte( $offset + 2 ) >> 1  ) << 15 );
	$low4bytes   |= (   $self->get_byte( $offset + 3 ) << 7  );
	$low4bytes   |= (   $self->get_byte( $offset + 4 ) >> 1  );

	$ts = $highbit * ( 1 << 16 );
	$ts += $low4bytes;
	$ts /= 90000;
    }
    elsif ( $type == 2 ) {
	print "Define mpeg-2 timestamps\n" if DEBUG;
    }
    return $ts;

}

##------------------------------------------------------------------------
## get_header()
##
## Grab the four bytes we need for the header
##------------------------------------------------------------------------
sub get_header {
    my $self = shift;

    ## we only need these four bytes
    ## should do this differently though :|
    return [ $self->get_byte( $self->{offset} ), 
	     $self->get_byte( $self->{offset} + 1 ),
	     $self->get_byte( $self->{offset} + 2 ),
	     $self->get_byte( $self->{offset} + 3 ) ];
    
}

##------------------------------------------------------------------------
## vframes()
## this is just calculated given fps and duration.  MPEG doesn't contain
## this information in the file directly
##------------------------------------------------------------------------
sub vframes(){
  my $self = shift;
  return int($self->duration * $self->fps) if $self->duration;
  return 0;
}


# Preloaded methods go here.

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

MPEG::Info - Basic MPEG bitstream attribute parser.

=head1 SYNOPSIS

  use strict;
  use MPEG::Info;

  my $video = MPEG::Info->new( -file => $filename );
  $video->probe();

  print $file->type;          ## MPEG

  ## Audio information
  print $file->acodec;        ## MPEG Layer 1/2
  print $file->acodecraw;     ## 80
  print $file->achans;        ## 1
  print $file->arate;         ## 128000 (bits/sec)
  print $file->astreams       ## 1

  ## Video information
  printf "%0.2f", $file->fps  ## 29.97
  print $file->height         ## 240
  print $file->width          ## 352
  print $file->vstreams       ## 1
  print $file->vcodec         ## MPEG1
  print $file->vframes        ## 529
  print $file->vrate          ## 1000000 (bits/sec)

  

=head1 DESCRIPTION

The Moving Picture Experts Group (MPEG) is a working group in 
charge of the development of standards for coded representation 
of digital audio and video.

MPEG audio and video clips are ubiquitous but using Perl to 
programmatically collect information about these bitstreams 
has to date been a kludge at best.  

This module parses the raw bitstreams and extracts information 
from the packet headers.  It supports Audio, Video, and System 
(multiplexed audio and video) packets so it can be used on nearly
every MPEG you encounter.

=head1 METHODS

MPEG::Info is a derived class of Video::Info, a factory module 
C<designed to meet your multimedia needs for many types of files>.  

=over 4

=item new( -file => FILE )

Constructor.  Requires the -file argument and returns an MPEG::Info object.

=item probe()

Parses the bitstreams in the FILE provided to the constructor.  
Returns 1 on success or 0 if the FILE could not be parsed as a valid
MPEG audio, video, or system stream.

=back

=head1 INHERITED METHODS

These methods are inherited from Video::Info.  While Video::Info may have
changed since this documentation was written, they are provided here
for convenience.

=item type()

Returns the type of file.  This should always be MPEG.

=item comments()

Returns the contents of the userdata MPEG extension.  This often contains
information about the encoder software.

=head2 Audio Methods

=over 4

=item astreams()

Returns the number of audio bitstreams in the file.  Usually 0 or 1.


=item acodec()

Returns the audio codec 


=item acodecraw()

Returns the hexadecimal audio codec.


=item achans()

Returns the number of audio channels.


=item arate()

Returns the audio rate in bits per second.

=back


=head2 Video Methods

=over 4

=item vstreams()

Returns the number of video bitstreams in the file.  Usually 0 or 1.

=item fps()

Returns the floating point number of frames per second.

=item height()

Returns the number of vertical pixels (the video height).

=item width()

Returns the number of horizontal pixels (the video width).

=item vcodec()

Returns the video codec (e.g. MPEG1 or MPEG2).

=item vframes()

Returns the number of video frames.

=item vrate()

Returns the video bitrate in bits per second.

=back


=head1 EVIL DIRECT ACCESS TO CLASS DATA

So you secretly desire to be the evil Spock, eh?  Well rub your goatee and
read on.

There are some MPEG-specific attributes that don't yet fit nicely
into Video::Info.  I am documenting them here for the sake of
completeness.  

Note that if you use these, you may have to make changes when 
new versions of this package are released.  There will be elegant
ways to access them in the future but we wanted to get this out there.


=over 4

These apply to audio bitstreams:

=item version

The MPEG version.  e.g. 1, 2, or 2.5

=item layer

The MPEG layer.  e.g. 1, 2, 3.

=item mode

The audio mode.  This is one of:

  Mono
  Stereo
  Dual Channel
  Intensity stereo on bands 4-31/32
  Intensity stereo on bands 8-31/32
  Intensity stereo on bands 12-31/32
  Intensity stereo on bands 16-31/32
  Intensity stereo off, M/S stereo off
  Intensity stereo on, M/S stereo off
  Intensity stereo off, M/S stereo on
  Intensity stereo on, M/S stereo on


=item emphasis

The audio emphasis, if any.

  No Emphasis
  50/15us
  Unknown
  CCITT J 17
  Undefined

=item sampling

The sampling rate (e.g. 22050, 44100, etc.)


=item protect

The value of the protection bit.  This is used to indicate copying
is prohibited but is different than copyright().


These apply to video:

=item aspect 

The aspect ratio if the ratio falls into one of the defined standards.
Otherwise, it's Reserved.

  Forbidden
  1/1 (VGA)
  4/3 (TV)
  16/9 (Large TV)
  2.21/1 (Cinema)
  Reserved


=head1 EXPORT

None.

=head1 AUTHORS

Benjamin R. Ginter, <bginter@asicommunications.com>

Allen Day, <allenday@ucla.edu>

=head1 COPYRIGHT

Copyright (c) 2001-2002 Benjamin R. Ginter, Allen Day

=head1 LICENSE

QPL 1.0 ("free for non-commercial use")

=head1 SEE ALSO

Video::Info
RIFF::Info
ASF::Info

=cut
