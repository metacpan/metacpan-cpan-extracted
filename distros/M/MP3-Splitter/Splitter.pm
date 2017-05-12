package MP3::Splitter;

use 5.005;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MP3::Splitter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	mp3split
	mp3split_read
) ] );

@EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT_OK = qw(
	
);

$VERSION = '0.04';

# Preloaded methods go here.

use MPEG::Audio::Frame 0.04;
die "This version of MPEG::Audio::Frame unsupported"
  if 0.07 == MPEG::Audio::Frame->VERSION;

sub piece_open ($$$$$) {
  my ($fname, $piece, $track, $Xing, $opts) = @_;
  my $callback = $piece->[2] || $opts->{name_callback};
  my $name = &$callback($track, $fname, $piece, $Xing, $opts);
  local *OUT;
  die "file `$name' exists" if not $opts->{overwrite} and -f $name;
  open OUT, "> $name" or die "open `$name' for write: $!";
  binmode OUT or die;
  ($name, *OUT);		# Ouch!
}

sub make_sec ($) {
  my $t = shift;
  my ($h, $m, $s) =
    $t =~ /^(?:([\d.]+)(?:h|:(?=.*[m:])))?(?:([\d.]+)[m:])?(?:([\d.]+)s?)?$/
      or die "Unexpected format of time: `$t'";
  for my $p ($h, $m, $s) {
    next unless defined $p;
    $p =~ /^(\d+\.?|\d*\.\d+)$/ or die "Unexpected format of time: `$t'";
  }
  ($h || 0) * 3600 + ($m || 0) * 60 + ($s || 0);
}

sub MY_INF () {1e100}

sub piece_decl ($$;@) {
  my ($start, $end, %piece_opts) = @{shift()};
  my $was = shift;
  (my $rel_start, $start) = $start =~ /^(>?)(.*)/;
  (my $abs_end, $end) = $end =~ /^(=?)(.*)/;
  $start  = make_sec $start;
  $start += $was if $rel_start;
  if ($end eq 'INF') {
    if (@_) {
      $end = make_sec $_[0][0];	# Start of the next chunk
    } else {			# Go to the end of the file
      $end = MY_INF;		# Soft infinity
      $piece_opts{lax} = $end;
    }
  } else {
    $end    = make_sec $end unless $end eq MY_INF;
    $end   += $start unless $abs_end;
  }
  ($start, $end, %piece_opts);
}

sub _Xing ($) {			# Guesswork...  What is the correct \0* ?
  my $f = shift;
  my $c = $f->content;
  $c =~ /^(\0{4,}(Xing|Info))(.{112})/s or return;
  length($1)+4, $2, unpack 'N3 C100', $3; # FramesOffset, Type, Flags, Frames, Bytes, Offsets
}

sub _Xing_h ($$$$$$$) {
  my ($Xing, $frames_off, $frames, $bytes, $time, $end, $off) = @_;
  my @o;
  if ($end >= MY_INF) {		# [time, frames, pos] - know it's a final write
    # Need to interpolate
    my ($last_time, $last_frac, $i) = (0, 0);
    for $i (@$off) {
      my $this_time = $i->[0]/$time * 100;
      next if $this_time == $last_time;
      my $this_frac = $i->[2]/$bytes * 256;
      while (@o <= $this_time) {	# Fuzz ok: actually need only 99 of 100
	push @o, $last_frac
	  + ($this_frac - $last_frac)*(@o - $last_time)/($this_time - $last_time);
      }
      $last_time = $this_time;
      $last_frac = $this_frac;
    }
  } elsif (@$off) {
    @o = map int($_->[2]/$bytes*256), @$off;
  } else {			# Before writing, assume linear flow
    @o = map $_*256/100, 0..99;
  }
  @o = map { $_ > 255 ? 255 : $_ } @o[0..99];
  my $c = $Xing->content;
  substr($c, $frames_off, 108) = pack 'N2 C100', $frames, $bytes, @o;
  my $crc = $Xing->crc;
  $crc = '' unless defined $crc;
  $Xing->header() . $crc . $c;
}

sub mp3split ($;@) {
    my $f = shift;

    return unless @_;		# Nothing to do
    my %opts = ( lax => 0.02,	# close to 1/75 - tolerate terminations that early
		 verbose => 0, append => sub{''}, prepend => sub{''},
		 name_callback => sub {sprintf "%02d_%s", shift, shift},
		 after_write => sub {}, keep_Xing => 1, update_Xing => 1,
	       );
    %opts = (%opts, %{shift()}) unless 'ARRAY' eq ref $_[0];
    return unless @_;		# Nothing to do

    local *F;
    open F, $f or die("open `$f': $!");
    binmode F;

    my $frame;
    my $trk = 0;		# Before first track

    my ($frames, $piece_frames) = (0, 0);	# frames written
    my ($ttime, $ptime) = (0,0); # total and piece time

    my $piece = shift or return; # start, duration, name-callback, finish-callback, user-data
    my ($start, $end, %piece_opts) = (0, 0);
    ($start, $end, %piece_opts) = piece_decl $piece, $end, @_;
    %piece_opts = (%opts, %piece_opts);

    my ($outf, $out, $finished);	# output file and its name, etc
    my ($Xing, $Xing_off, $av_fr, $vbr, $tot_len, $frt, @off, $Xing_tell, $l);

    print STDERR "`$f'\n" if $opts{verbose};
    while ( $frame = MPEG::Audio::Frame->read(\*F) or ++$finished) {
	# Check whether it is an Xing frame
	if ( !$frames and !$finished
	     and ($Xing_off, undef, undef, my $fr, my $b) = _Xing($frame) ) {
	    $av_fr = $b/$fr;		# Average length of a frame
	    $frt = $frame->seconds;	# Depends on layer and samplerate only
	    $vbr = $av_fr/$frt/125;	# kbits is 1000 bits = 1000/8 bytes
	    $tot_len = $fr * $frt;
	    $Xing = $frame;
	    printf STDERR "VBR: %.1fkBit/sec.  Total: %.2fsec (from Xing header)\n", $vbr, $tot_len 
		if $piece_opts{verbose};
	}
	# Check what to do with this frame
	if ( $ttime > $end or $finished ) {	# Need to end the current piece
	    die "Unexpected end of piece" unless $outf;
	    my $cb = $piece_opts{append};

	    my $append =
		&$cb($f, $piece, $trk, $ttime, $ptime, $out, $frames, $piece_frames,
		 ($Xing and $piece_opts{keep_Xing}), $Xing, \%piece_opts, $outf);
	    print $outf $append or die if length $append;

	    if ($Xing and $piece_opts{keep_Xing} and $piece_opts{update_Xing}) {
		# Print actual header
		my $pos = tell $outf;
		seek $outf, 0, $Xing_tell or die;
		push @off, ([$ptime, $piece_frames, $pos]) x (100 - @off)
		  if @off < 100;
		push @off, [$ptime, $piece_frames, $pos] if $end >= MY_INF;
		print $outf _Xing_h($Xing, $Xing_off, $piece_frames,
				    $pos, $ptime, $end, \@off);
	    }

	    close $outf or die "Error closing `$out' for write: $!";
	    $cb = $piece_opts{after_write};
	    &$cb($f, $piece, $trk, $ttime, $ptime, $out, $frames, $piece_frames,
		 ($Xing and $piece_opts{keep_Xing}), $Xing, \%piece_opts);
	    undef $outf;
	    die "end of audio file before all the tracks written"
		if $finished and (@_ or $ttime < $end - $piece_opts{lax});
	    last if $finished;
	    $piece = shift or last;
	    ($start, $end, %piece_opts) = piece_decl $piece, $end, @_;
	    %piece_opts = (%opts, %piece_opts);
	}
	my $len = $frame->seconds;
	$ttime += $len;
	$ptime += $len;
	$frames++;
	next if $frames == 1 and $Xing;
	next if $ttime < $start;	# Does not intersect the next interval

	# Need to write this piece
	unless ($outf) {
	    ($out, $outf) = piece_open($f, $piece, ++$trk, $Xing, \%piece_opts);
	    $ptime = $len;
	    $piece_frames = $l = 0;
	    @off = ();
	    my $prepend = 
		&{$piece_opts{prepend}}($trk, $f, $piece, $Xing, \%piece_opts, $out, $outf);
	    print $outf $prepend or die	if length $prepend;
	    if ($Xing and $piece_opts{keep_Xing}) {	# Print estimated header
		$Xing_tell = tell $outf;
		print $outf _Xing_h($Xing, $Xing_off, ($end - $start)/$frt,
				    ($end - $start)/$frt*$av_fr, 0, 0, \@off);
		$piece_frames++;
	    }
	    printf STDERR " %2d \@ %17s (=%8s) %s\n",
		$trk, "$start-$end", $end-$start, $out if $piece_opts{verbose};
	}

	# For Xing header
	if ($end < MY_INF) {
	  my $perc = $end > $start ? int($ptime/($end-$start)*100) : -1;
	  push @off, ([$ptime, $piece_frames, tell $outf]) x ($perc - @off + 1)
	    if $perc >= @off;
	} elsif ($l * 1.01 <= $piece_frames) {
	  push @off, [$ptime, $piece_frames, tell $outf];
	  $l = $piece_frames;
	}

	# Copy frame data.
	print $outf $frame->asbin;
	$piece_frames++;
    }
}

sub mp3split_read ($$;$) {
  my ($file, $datafile, $opts, @p) = (shift, shift, shift || {});
  local(*IN, $_);
  open IN, "< $datafile" or die "Can't open `$datafile' for read: $!";
  while (<IN>) {
    next if /^\s*($|#)/;
    /^\s*(>?[\d.hms:]+)\s+(=?([\d.hms:]+|INF))?\s*($|#)/
      or die "unrecognized line: `$_'";
    push @p, [$1, defined $2 ? $2 : 'INF'];
  }
  close IN or die "Can't close `$datafile' for read: $!";
  mp3split($file, $opts, @p);
}

1;
__END__

=head1 NAME

MP3::Splitter - Perl extension for splitting MP3 files

=head1 SYNOPSIS

  use MP3::Splitter;
  # Split 2 chunks from a file: the first starts at 3sec, length 356.25sec;
  # the second starts at 389sec, preferable length 615sec, but if EOF is met
  # up to 10sec before expected end of chunk, this is not considered a failure.
  mp3split('xx.mp3', {verbose => 1}, [3, 356.25], [389, 615, lax => 10]);

  mp3split_read('xx.mp3', 'xx.list', {verbose => 1});

=head1 DESCRIPTION

The first two arguments of mp3split() is a name of an MP3 file and a reference
to a hash of options, the remaining are
descriptions of pieces.  Such a description is an array reference with the
start and duration of the piece (in seconds; or of the forms C<03h05m56.45>,
C<03h05m56.45s>, or C<03:05:56.45>; any of the hours/minutes/seconds fields
can be omited if the result is not ambiguous.  Alternatively, one
can specify the start field as a relative position w.r.t. the end of
previous piece (or start of file); to do this, prepend C<E<gt>> to the
field.  Similarly, one can put the absolute position of the end-of-the-piece
in the duration
field by prepending the time by C<=>; if this field has a special value
C<'INF'>, it is assumed to go until the start of the next piece, or until
the audio ends.  The remaining
elements of a piece description should form a hash of piece-specific
options (arbitrary user data can be stored with the key C<user>).

Similarly, mp3split_read() takes names of an MP3 file and of a file with
the description of pieces, followed by optional reference to a hash of options.
Each line of the description file should be either empty (except comments),
or have the form

  START END # OPTIONAL_COMMENT

C<START> and C<END> are exactly the same as in the description of pieces
for mp3split(); however, END may be omited (with the same meaning as C<'INF'>).
Note that this is a format of method output_blocks() of
L<Audio::FindChunks|Audio::FindChunks>.

=head2 Options

The following I<callback> options should be function references with signatures

  name_callback($pieceNum, $mp3name, $piece, $Xing, $opts); # returns file name
  prepend($pieceNum, $mp3name, $piece, $Xing, $opts,
	  $pieceFileName, $pieceFileHandle);
  append(     $mp3name, $piece, $pieceNum, $cur_total_time, $piece_time,
	      $pieceFileName, $cur_total_frames, $piece_frames,
	      $xing_written, $Xing, $opts, $pieceFileHandle);
  after_write($mp3name, $piece, $pieceNum, $cur_total_time, $piece_time,
	      $piece_name, $cur_total_frames, $piece_frames,
	      $xing_written, $Xing, $opts);

$pieceNum is 1 for the first piece to write.  The default value of C<piece_name>
callback uses the piece names of the form "03_initial_name.mp3", by default
the other callbacks are NO-OPs.  The C<prepend> and C<append> callback can
actually write data (with a buffered write) to filehandle, or return the
string to write.

If C<keep_Xing> option is true, and the initial file contained an
I<Xing> frame, an I<Xing> frame with estimated values for the number
of frames and the length of the output file is emited; if
C<update_Xing> option is true, this frame is updated to reflect actual
size of the piece (and positions of 99 intermediate moments) when the piece is
finished.  Both these options default to TRUE.

Other recognized options: C<verbose>, C<overwrite> and C<lax>; the
last one means the how early the mp3 file can end before the end of the last
chunk so that an error condition is not rised; the default is 0.02 (in sec),
use some ridiculously large value (such as C<1e100> if EOF is never an error).
If C<overwrite> is false (default), it is a fatal error if a file with the
target name exists.

=head2 EXPORT

  mp3split
  mp3split_read

=head1 EXAMPLES

The file with piece description

  0		# Copy whole file (0..INF), and update Xing header

will (when used with mp3_split_read() and default options) keep all MP3 frames
(the current implementation removes all the non-frame information from the
file; this may/should change in the future).  If Xing frame is present, it
is updated with information about actual layout of the file (length, and
positions of intermediate seek-by-percentage points).

Here is a more elaborate example of the syntax:

  0.15	0h0:0.05 # The first piece of length 0.05sec starting at 0.15sec
  0.3s	=1	 # The 2nd piece starts at 0.3sec, ends at 1sec
  >2	=1m	 # The 3rd piece starts 2 seconds after the 2nd, ends at 60sec
  >0	INF	 # The 4th piece starts where 3rd ends, ends where 5th starts
  1:15		 # Last piece starts at 1m15s and goes to the end

=head1 LIMITATIONS

The current implementation removes all the non-frame information when
extracting the chunks. this may/should change in the future.

The splitting is performed on the level of audio frames; we ignore finer
structure of audio stream ("actual" chunks of audio stream may be shared
between - up to 3 - consecutive audio frames).  This may introduce error
for up to duration of 3 frames, which is 1/25sec.

The frames are accessed via C<MPEG::Audio::Frame> module; thus the bugs
of this module may bite us as well.  In particular, until C<MPEG::Audio::Frame>
supports skipping C<RIFF> and C<ID3v1>/C<ID3v2> headers/footers, false
"syncronization marks" in this headers may confuse this module as well.

The latter limitation may be especially relevant to users of Apple software;
due to bugs in Apple's MP3 creators, the C<ID3v2> headers are not
unsyncronized; note that embedded binary data (images?) have very high
probability to contain false "syncronization marks".

=head1 SEE ALSO

L<mp3cut>, L<Audio::FindChunks>

=head1 AUTHOR

Ilya Zakharevich, E<lt>cpan@ilyaz.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Lousely based on code of C<mp3cut> by Johan Vromans <jvromans@squirrel.nl>.

Copyright (C) 2004--2006 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
