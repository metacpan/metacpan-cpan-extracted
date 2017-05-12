package Device::CableModem::Zoom5341;

use strict;
use warnings;

our $VERSION = '1.10';
our @ISA = qw();


# We'll do this OO
sub new
{
	my ($class, %parameters) = @_;

	my $self = {
		# Config
		modem_addr => '192.168.100.1',

		# Runtime data
		conn_html  => undef,
		conn_stats => undef,

		# Overrides
		%parameters,
	};


	bless $self, $class;
	return $self;
}


# Stuff for grabbing the pages from the modem
use Device::CableModem::Zoom5341::Fetch;

# Parsing the HTML
use Device::CableModem::Zoom5341::Parse;

# Returning stats to the user
use Device::CableModem::Zoom5341::Get;



1;
__END__

=head1 NAME

Device::CableModem::Zoom5341 - Read info from Zoom 5341 cable modem

=head1 SYNOPSIS

  use Device::CableModem::Zoom5341;
  my $cm = Device::CableModem::Zoom5341->new;

=head1 DESCRIPTION

This module lets you automate grabbing various information (primarily,
signal stats) from the Zoom 5341 DOCSIS 3 cable modem.  It's built
against the 'G' model, and presumably works with the H as well.  It does
I<not> work with the 'J' model.

=head1 USAGE

=head2 Instantiation

First you need an object to work with

  # Create an object with the defaults
  my $cm = Device::CableModem::Zoom5341->new;

  # Set your modem's IP
  my $cm = Device::CableModem::Zoom5341->new(modem_addr => '10.0.0.1');
  my $cm = Device::CableModem::Zoom5341->new(modem_addr => 'gateway.my.net');

Bare IP's, names from F</etc/hosts>, or DNS hostnames are all acceptable
here.  Without explicit specification, it defaults to C<192.168.100.1>,
which is the default for this model (and most cable modems, actually).

=head3 Odd behavior

B<Note:> The Zoom will generally have two addresses; the C<192.168.100.1>
internal, and an external address (visible on the Status page, under
'Cable Modem IP Information').  It's been the author's experience with
his 5341 that it's often I<incredibly> slow at responding on the internal
address, especially if it hasn't been hit recently.  And by 'incredibly
slow', I mean many minutes, and generally many timeouts and retries,
before it gets around to answering.

However, using the external IP, it usually answers relatively quickly,
without timeouts.  So it may serve you best to look up the IP with your
browser, and use that in your scripts, if it's stable.

=head2 Simple Stats

  my $downstream_stats = $cm->get_down_stats;
  my $upstream_stats   = $cm->get_up_stats;

The direct approach is just to grab all the downstream and/or upstream
stats in a block.  These methods return a hashref with a handful of keys
for the various stat types.  The values for each key is an arrayref
containing the values for each channel available.  Channels that aren't
in use are undef or simply not present.

An example would help:

  $downstream_stats = {
    freq  => [12345,         23456,     34567,     45678], # Hz
    snr   => [35.8,           36.5,      38.9,      36.2], # dB
    power => [8.6,             5.4,       5.7,       3.2], # dBmV
    mod   => ['256 QAM', '256 QAM', '256 QAM', '256 QAM']
  }

This shows there are 4 bonded downstream channels connected.  The third
channel, for instance is at 34,567 Hz, with 256 QAM modulation, coming in
at a power of 5.7 dBmV with a signal-to-noise ratio of 38.9 dB.

The stats upstream are a little different

  $upstream_stats = {
    chanid => [1,    undef, undef, undef],
    freq   => [4321, undef, undef, undef], # Hz
    bw     => [345,  undef, undef, undef], # Hz
    power  => [45,   undef, undef, undef]  # dBmV
  }

Here we see that we only have a single active upstream channel.  It's at
4321 Hz, with a bandwidth of 345 Hz, and we're shouting at 45 dBmV.

Note: Don't mistake the 'bandwidth' value there as referring to a data
rate.  It's the signal width of the channel.

=head2 More Precise Stats

Of course, sometimes you may want only one or two bits of info, and it's
simpler to just grab what you want.

  my $dfreq  = $cm->get_down_freq;
  my $dmod   = $cm->get_down_mod;
  my $dpower = $cm->get_down_power;
  my $dsnr   = $cm->get_down_snr;

In these cases, you're getting just the arrayrefs.

  $dfreq  = [12345, 23456, 34567, 45678];
  # etc

And similarly for the upstream

  my $uchanid = $cm->get_up_chanid;
  my $ufreq   = $cm->get_up_freq;
  my $ubw     = $cm->get_up_bw;
  my $upower  = $cm->get_up_power;

  $uchanid = [1, undef, undef, undef];

=head2 Fetching From The Modem

The info isn't actually fetched from the modem when you instantiate the
object.  The page is grabbed, parsed, and cached automatically when you
make the first stat request.

  my $cm = Device::CableModem::Zoom5341->new;
  my $dpower = $cm->get_down_power; # Auto-fetched during this

And that HTML and parsed data is kept around and re-used when you make
later C<$cm-E<gt>get_whatever> calls.  So there's no significant overhead to
making lots of C<get_>'s; they're just method calls, not network data
traffic.

Usually, that's all you need.  However, you may want to cause a fetch
yourself sometimes.  So you can do that:

  $cm->fetch_connection;   # Does the fetch and caches up the HTML

If you're just running a one-time grab, you won't need to do that.
However, if you're instead doing a long-running program that needs to
refresh the data, you'll need to run C<-E<gt>fetch_connection> any time you
want to pull new data instead of just returning the stuff you've got from
last time.

For instance, if you have your own functions to store stats in a database
of some kind, and you want to pull numbers every 5 minutes continually,
you could make a loop something like:

  my $cm = Device::CableModem::Zoom5341->new;
  while(1)
  {
    $cm->fetch_connection;
    store_downstream_stats($cm->get_down_stats);
    store_upstream_stats($cm->get_up_stats);
    sleep(5 * 60);
  }

=head2 Additional Internals

There are various other methods available internally, but you shouldn't
need to poke at them yourself.  In particular, the tests in the
distribution have a lot of knowledge of the internals, so anything in
there that isn't described here is probably coloring outside the lines.
Don't go there.

If you poke under the covers anyway, any demons you wind up accidentally
summoning are your own problem.  Consider yourself forewarned.
Forewarned is forearmed, and you'd look pretty silly with four arms, so
you should probably stick with this documented API.

=head1 MISSING FEATURES

There are various bits of information available through the web interface
that this module doesn't support fetching.  In fact, I haven't written
fetching for anything except the DOCSIS network stats (up- and
down-stream signal information).  Stuff like software version, assigned
IP's, log messages, and the like are available.  Maybe someday I'll have
a need for them and add in the support.

=head1 SUPPORTED VERSIONS

This module has been tested by the author with 5.8 and later versions.  I
don't know any specific reason it wouldn't work with 5.6 if you tried,
but I haven't.

=head1 AUTHOR

Matthew Fuller, C<< <fullermd@over-yonder.net> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Matthew Fuller

This software is distributed under a 2-clause BSD license.  See the
LICENSE file in the distribution for details.

=cut
