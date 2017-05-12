=head1 NAME

Linux::DVB - interface to (some parts of) the Linux DVB API

=head1 SYNOPSIS

 use Linux::DVB;

=head1 DESCRIPTION

This module provides an interface to the Linux DVB API. It is a straightforward
translation of the C API. You should read the Linux DVB API description to make
any sense of this module. It can be found here:

   http://www.linuxtv.org/docs/dvbapi/dvbapi.html

All constants from F<frontend.h> and F<demux.h> are exported by their C
name and by default.

Noteworthy differences to the C API: unions and sub-structs are usually
translated into flat perl hashes, i.e C<struct.u.qam.symbol_rate>
becomes C<< $struct->{symbol_rate} >>.

Noteworthy limitations of this module include: No interface to the video,
audio and net devices. If you need this functionality bug the author.

=cut

package Linux::DVB;

use Fcntl ();

BEGIN {
   $VERSION = '1.03';
   @ISA = qw(Exporter);

   require XSLoader;
   XSLoader::load __PACKAGE__, $VERSION;

   require Exporter;

   my %consts = &_consts;
   my $consts;
   while (my ($k, $v) = each %consts) {
      push @EXPORT, $k;
      $consts .= "sub $k(){$v}\n";
   }
   eval $consts;
}

sub new {
   my ($class, $path, $mode) = @_;

   my $self = bless { path => $path, mode => $mode }, $class;
   sysopen $self->{fh}, $path, $mode | &Fcntl::O_NONBLOCK
      or die "$path: $!";
   $self->{fd} = fileno $self->{fh};

   $self;
}

sub fh { $_[0]{fh} }
sub fd { $_[0]{fd} }

sub blocking {
   fcntl $_[0]{fh}, &Fcntl::F_SETFL, $_[1] ? 0 : &Fcntl::O_NONBLOCK;
}

package Linux::DVB::Frontend;

@ISA = qw(Linux::DVB);

=head1 Linux::DVB::Frontend CLASS

=head2 SYNOPSIS

 my $fe = new Linux::DVB::Frontend $path, $writable;

 my $fe = new Linux::DVB::Frontend
             "/dev/dvb/adapter0/frontend0", 1;

 $fe->fh; # filehandle
 $fe->fd; # fileno
 $fe->blocking (0); # or 1

 $fe->{name}
 $fe->{type}
 $fe->frontend_info->{name}

 $fe->status & FE_HAS_LOCK
 print $fe->ber, $fe->snr, $fe->signal_strength, $fe->uncorrected;

 my $tune = $fe->parameters;
 $tune->{frequency};
 $tune->{symbol_rate};

=over 4

=cut

sub new {
   my ($class, $path, $mode) = @_;
   my $self = $class->SUPER::new ($path, $mode ? &Fcntl::O_RDWR : &Fcntl::O_RDONLY);

   %$self = ( %$self, %{ $self->frontend_info } );
   
   $self;
}

=item $fe->set (parameter => value, ...)

Sets frontend parameters. All values are stuffed into the
C<dvb_frontend_parameters> structure without conversion and passed to
FE_SET_FRONTEND.

Returns true on success.

All modes:

  frequency         =>
  inversion         =>

QPSK frontends:

  symbol_rate       =>
  fec_inner         =>

QAM frontends:

  symbol_rate       =>
  modulation        =>

QFDM frontends:

  bandwidth         =>
  code_rate_HP      =>
  code_rate_LP      =>
  constellation     =>
  transmission_mode =>

=cut

sub set             {
   my ($self) = shift;
   _set $self->{fd}, { @_ }, $self->{type}
}

=item $fe->parameters

Calls FE_GET_FRONTEND and returns a hash reference that contains the same keys
as given to the C<set> method.

Example:

  Data::Dumper::Dumper $fe->get
  
  {
    frequency   => 426000000, # 426 Mhz
    inversion   => 0,         # INVERSION_OFF
    symbol_rate => 6900000,   # 6.9 MB/s
    modulation  => 3,         # QAM_64
  }

=cut

sub parameters      { _get   ($_[0]{fd}, $_[0]{type}) }
sub get             { _get   ($_[0]{fd}, $_[0]{type}) } # unannounced alias
sub event           { _event ($_[0]{fd}, $_[0]{type}) }

=item $ok = $fe->diseqc_reset_overload

If the bus has been automatically powered off due to power overload, this
call restores the power to the bus. The call requires read/write access
to the device. This call has no effect if the device is manually powered
off. Not all DVB adapters support this call.

=item $ok = $fe->diseqc_voltage (13|18)

Set the DiSEqC voltage to either 13 or 18 volts.

=item $ok = $fe->diseqc_tone (1|0)

Enables (1) or disables (0) the DiSEqC continuous 22khz tone generation.

=item $ok = $fe->diseqc_send_burst (0|1)

Sends a 22KHz tone burst of type SEC_MINI_A (0) or SEC_MINI_B (1).

=item $ok = $fe->diseqc_cmd ($command)

Sends a DiSEqC command ($command is 3 to 6 bytes of binary data).

=item $reply = $fe->diseqc_reply ($timeout)

Receives a reply to a DiSEqC 2.0 command and returns it as a binary octet
string 0..4 bytes in length (or C<undef> in the error case).

=cut

package Linux::DVB::Demux;

@ISA = qw(Linux::DVB);

=back

=head1 Linux::DVB::Demux CLASS

=head2 SYNOPSIS

 my $dmx = new Linux::DVB::Demux
             "/dev/dvb/adapter0/demux0";

 $fe->fh; # filehandle
 $fe->fd; # fileno
 $fe->blocking (1); # non-blocking is default

 $dmx->buffer (16384);
 $dmx->sct_filter ($pid, "filter", "mask", $timeout=0, $flags=DMX_CHECK_CRC);
 $dmx->pes_filter ($pid, $input, $output, $type, $flags=0);
 $dmx->start; 
 $dmx->stop; 

=over 4

=cut

sub new {
   my ($class, $path) = @_;
   my $self = $class->SUPER::new ($path, &Fcntl::O_RDWR);
   
   $self;
}

sub start      { _start      ($_[0]{fd}) }
sub stop       { _stop       ($_[0]{fd}) }

sub sct_filter { _filter     ($_[0]{fd}, @_[1, 2, 3, 4, 5]) }
sub pes_filter { _pes_filter ($_[0]{fd}, @_[1, 2, 3, 4, 5]) }
sub buffer     { _buffer     ($_[0]{fd}, $_[1]) }

package Linux::DVB::Decode;

=back

=head1 Linux::DVB::Decode CLASS

=head2 SYNOPSIS

   $si_decoded_hashref = Linux::DVB::Decode::si $section_data;

=over 4

=cut

=item $hashref = Linux::DVB::Decode::si $section_data

Tries to parse the string inside C<$section_data> as an SI table and
return it as a hash reference.  Only the first SI table will be returned
as hash reference, and the C<$section_data> will be modified in-place by
removing the table data.

The way to use this function is to append new data to your
C<$section_data> and then call C<Linux::DVB::Decode::si> in a loop until
it returns C<undef>. Please ntoe, however, that the Linux DVB API will
return only one table at a time from sysread, so you can safely assume
that every sysread will return exactly one (or zero in case of errors) SI
table.

Here is an example of what to expect:

  {
    'segment_last_section_number' => 112,
    'table_id' => 81,
    'service_id' => 28129,
    'original_network_id' => 1,
    'section_syntax_indicator' => 1,
    'current_next_indicator' => 1,
    'events' => [
                  {
                    'running_status' => 0,
                    'start_time_hms' => 2097152,
                    'event_id' => 39505,
                    'free_CA_mode' => 0,
                    'start_time_mjd' => 53470,
                    'descriptors' => [
                                       {
                                         'event_name' => 'Nachrichten',
                                         'text' => '',
                                         'ISO_639_language_code' => 'deu',
                                         'type' => 77
                                       },
                                       {
                                         'programme_identification_label' => 337280,
                                         'type' => 105
                                       },
                                       {
                                         'raw_data' => '22:0010.04#00',
                                         'type' => 130
                                       }
                                     ],
                    'duration' => 1280
                  },
                  {
                    'running_status' => 0,
                    'start_time_hms' => 2098432,
                    'event_id' => 39506,
                    'free_CA_mode' => 0,
                    'start_time_mjd' => 53470,
                    'descriptors' => [
                                       {
                                         'event_name' => 'SR 1 - Nachtwerk',
                                         'text' => '',
                                         'ISO_639_language_code' => 'deu',
                                         'type' => 77
                                       },
                                       {
                                         'programme_identification_label' => 337285,
                                         'type' => 105
                                       },
                                       {
                                         'raw_data' => '22:0510.04#00',
                                         'type' => 130
                                       }
                                     ],
                    'duration' => 87296
                  }
                ],
    'last_table_id' => 81,
    'section_number' => 112,
    'last_section_number' => 176,
    'version_number' => 31,
    'transport_stream_id' => 1101
  }


=item $text = Linux::DVB::Decode::text $data

Converts text found in DVB si tables into perl text. Only iso-8859-1..-11
and UTF-16 is supported, other encodings (big5 etc. is not. Bug me if you
need this).

=cut

sub text($) {
   use Encode;

   for ($_[0]) {
      s/^([\x01-\x0b])// and $_ = decode sprintf ("iso-8859-%d", 4 + ord $1), $_;
      # 10 - pardon you???
      s/^\x11// and $_ = decode "utf16-be", $_;
      # 12 ksc5601, DB
      # 13 db2312, DB
      # 14 big5(?), DB
      s/\x8a/\n/g;
      #s/([\x00-\x09\x0b-\x1f\x80-\x9f])/sprintf "{%02x}", ord $1/ge;
      s/([\x00-\x09\x0b-\x1f\x80-\x9f])//ge;
   }
}

=item %Linux::DVB::Decode::nibble_to_genre

A two-level hash mapping genre nibbles to genres, e.g.

   $Linux::DVB::Decode::nibble_to_genre{7}{6}
   => 'film/cinema'

=cut

our %nibble_to_genre = (
     0x1 => {
              0x0 => 'Movie/Drama (general)',
              0x1 => 'Movie - detective/thriller',
              0x2 => 'Movie - adventure/western/war',
              0x3 => 'Movie - science fiction/fantasy/horror',
              0x4 => 'Movie - comedy',
              0x5 => 'Movie - soap/melodrama/folkloric',
              0x6 => 'Movie - romance',
              0x7 => 'Movie - serious/classical/religious/historical movie/drama',
              0x8 => 'Movie - adult movie/drama',
            },
     0x2 => {
              0x0 => 'News/Current Affairs (general)',
              0x1 => 'news/weather report',
              0x2 => 'news magazine',
              0x3 => 'documentary',
              0x4 => 'discussion/interview/debate',
            },
     0x3 => {
              0x0 => 'Show/Game Show (general)',
              0x1 => 'game show/quiz/contest',
              0x2 => 'variety show',
              0x3 => 'talk show',
            },
     0x4 => {
              0x0 => 'Sports (general)',
              0x1 => 'special events (Olympic Games, World Cup etc.)',
              0x2 => 'sports magazines',
              0x3 => 'football/soccer',
              0x4 => 'tennis/squash',
              0x5 => 'team sports (excluding football)',
              0x6 => 'athletics',
              0x7 => 'motor sport',
              0x8 => 'water sport',
              0x9 => 'winter sports',
              0xA => 'equestrian',
              0xB => 'martial sports',
            },
     0x5 => {
              0x0 => 'Childrens/Youth (general)',
              0x1 => "pre-school children's programmes",
              0x2 => 'entertainment programmes for 6 to 14',
              0x3 => 'entertainment programmes for 10 to 16',
              0x4 => 'informational/educational/school programmes',
              0x5 => 'cartoons/puppets',
            },
     0x6 => {
              0x0 => 'Music/Ballet/Dance (general)',
              0x1 => 'rock/pop',
              0x2 => 'serious music or classical music',
              0x3 => 'folk/traditional music',
              0x4 => 'jazz',
              0x5 => 'musical/opera',
              0x6 => 'ballet',
            },
     0x7 => {
              0x0 => 'Arts/Culture (without music, general)',
              0x1 => 'performing arts',
              0x2 => 'fine arts',
              0x3 => 'religion',
              0x4 => 'popular culture/traditional arts',
              0x5 => 'literature',
              0x6 => 'film/cinema',
              0x7 => 'experimental film/video',
              0x8 => 'broadcasting/press',
              0x9 => 'new media',
              0xA => 'arts/culture magazines',
              0xB => 'fashion',
            },
     0x8 => {
              0x0 => 'Social/Policical/Economics (general)',
              0x1 => 'magazines/reports/documentary',
              0x2 => 'economics/social advisory',
              0x3 => 'remarkable people',
            },
     0x9 => {
              0x0 => 'Education/Science/Factual (general)',
              0x1 => 'nature/animals/environment',
              0x2 => 'technology/natural sciences',
              0x3 => 'medicine/physiology/psychology',
              0x4 => 'foreign countries/expeditions',
              0x5 => 'social/spiritual sciences',
              0x6 => 'further education',
              0x7 => 'languages',
            },
     0xA => {
              0x0 => 'Leisure/Hobbies (general)',
              0x1 => 'tourism/travel',
              0x2 => 'handicraft',
              0x3 => 'motoring',
              0x4 => 'fitness & health',
              0x5 => 'cooking',
              0x6 => 'advertizement/shopping',
              0x7 => 'gardening',
            },
     0xB => {
              0x0 => '(original language)',
              0x1 => '(black & white)',
              0x2 => '(unpublished)',
              0x3 => '(live broadcast)',
            },
);

=item ($sec,$min,$hour) = Linux::DVB::Decode::time $hms

=item ($mday,$mon,$year) = Linux::DVB::Decode::date $mjd

=item ($sec,$min,$hour,$mday,$mon,$year) = Linux::DVB::Decode::datetime $mjd, $hms

=item $sec = Linux::DVB::Decode::time_linear $hms

=item $sec = Linux::DVB::Decode::datetime_linear $mjd, $hms

Break down a "DVB time" (modified julian date + bcd encoded seconds) into
it's components (non-C<_linear>) or into a seconds count (C<_linear>
variants) since the epoch (C<datetime_linear>) or the start of the day
(C<time_linear>).

The format of the returns value of the date and datetime functions is
I<not> compatible with C<Time::Local>. Use the C<_linear> functions
instead.

Example:

   my $time = Linux::DVB::Decode::datetime_linear $mjd, $hms
   printf "Starts at %s\n",
      POSIX::strftime "%Y-%m-%d %H:%M:%S",
         localtime $time;

=cut

sub time($) {
   my ($time) = @_;

   # Time is in UTC, 24 bit, every nibble one digit in BCD from right to left
   my $hour   = sprintf "%02x", ($time >> 16) & 0xFF;
   my $minute = sprintf "%02x", ($time >>  8) & 0xFF;
   my $second = sprintf "%02x", ($time      ) & 0xFF;

   ($second, $minute, $hour)
}

sub date($) {
   my ($mjd) = @_;

   # Date is given in Modified Julian Date
   # Decoding routines taken from ANNEX C, ETSI EN 300 468 (DVB SI)
   my $y_ = int (($mjd - 15078.2) / 365.25);
   my $m_ = int (($mjd - 14956.1 - int ($y_ * 365.25)) / 30.6001);
   my $day = $mjd - 14956 - int ($y_ * 365.25) - int ($m_ * 30.6001);
   my $k = $m_ == 14 or $m_ == 15 ? 1 : 0;
   my $year = $y_ + $k + 1900;
   my $month = $m_ - 1 - $k * 12;

   ($day, $month, $year)
}

sub datetime($$) {
   (Linux::DVB::Decode::time $_[1], date $_[0])
}

sub time_linear($) {
   my ($s, $m, $h) = Linux::DVB::Decode::time $_[0];

   (($h * 60) + $m * 60) + $s
}

sub datetime_linear($$) {
   my ($sec, $min, $hour, $mday, $mon, $year) =
      Linux::DVB::Decode::datetime $_[0], $_[1];

   require Time::Local;
   Time::Local::timegm ($sec, $min, $hour, $mday, $mon - 1, $year)
}

=back

=head1 AUTHORS

 Marc Lehmann <schmorp@schmorp.de>, http://home.schmorp.de/
 Magnus Schmidt, eMail at http://www.27b-6.de/email.php

=cut

1
