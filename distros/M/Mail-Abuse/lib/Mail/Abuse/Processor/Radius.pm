package Mail::Abuse::Processor::Radius;

require 5.005_62;

use Carp;
use strict;
use warnings;
use PerlIO::gzip;
use IO::File;
use File::Find;
use Date::Parse;

my $Debug = 0;			# Global debug flag

use base 'Mail::Abuse::Processor';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

our @Ignore = (qw/NAS-IP-Address/);

=pod

=head1 NAME

Mail::Abuse::Processor::Radius - Match incidents to users using RADIUS detail files

=head1 SYNOPSIS

  use Mail::Abuse::Processor::Radius;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::Radius;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class attempts to find users associated with incidents by
analyzing Radius detail files according to the specifications of the
configuration file. Compressed detail files (ending in .gz) will be
uncompressed and processed on the fly.

The following configuration keys control the behavior of this module.

=over

=item B<debug radius>

If set to a true value, causes this module to emit debugging info
using C<warn()>.

=cut

use constant DEBUG	=> 'debug radius';

=pod

=item B<radius detail type>

The type or format of the RADIUS detail file to be expected. The
values can be any of the following.

=over

=item B<livingston>

A standard format derived from the venerable Livingston Radius server,
one of the earliest RADIUS server. Most Radius servers can produce
output in this format, which is why this is the default.

=back

Hopefully, other format will be added when needed.

=cut

use constant TYPE	=> 'radius detail type';

my %Dispatch = (
		'livingston'	=> \&_livingston_parser,
		);

=pod

=item B<radius detail location>

The path of a file or directory where the accounting details are
kept. If pointed to a directory, a recursive lookup will occur and all
files found will be analyzed.

If pointed to a single file, only that particular file will be
analyzed.

By default, the directory C</var/raddb/details> will be used if none
is specified. This seems to be a quite common default.

Since the specified path will be traversed completely, it is a good
idea to remove old detail files to keep the response times short. It
is never a good idea to let this code loose in a hierarchy containing
5 years of detail records.

=cut

use constant LOCATION	=> 'radius detail location';

=pod

=back

The following functions are implemented.

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and, for each
C<Mail::Abuse::Incident> collected, perform a lookup in the given
detail files.

If the user is found, all the Radius detail entries are placed in the
incident, so that other modules can use this information. New entries
are to be accessed like in the following example:

    $incident->radius->{'User-Name'};
    $incident->radius->{'Caller-Id'};

Where each key is the actual entry in the detail record.

=cut

sub _livingston_parser
{
    my $self	= shift;
    my $rep	= shift;
    my $file	= shift;
    my $fh	= shift;

    warn "# _livingston_parser $file with ", scalar @{$rep->incidents}, "\n"
	if $Debug;

    my $record;
    
    while (<$fh>)
    {
#	warn "# $_";
				# The following code collects each record
				# into $record for subsequent parsing
	$record .= $_ if /^\w+/ .. /^\s*$/;
	if (/^\s*$/)
	{
	    warn "# RECORD\n" if $Debug;

				# We only want to deal with Stop
				# records...

	    unless ($record =~ m/^\s*Acct-Status-Type = Stop/im)
	    {
		warn "# Not a stop record\n" if $Debug;
		$record = '';
		next;
	    }

				# Find (and cache) which incidents
				# can match this CDR

	    my @match	= ();	# Incidents that match the IP on this CDR
	    my @addrs	= ();	# Addresses gathered from the CDR

	    my $netmask	= 32;	# Default

	    $netmask = $2 
		if $record =~ m/^\s*Framed-(IP-)?Netmask = ([^\n]+)/mi;

	    while ($record =~ m/^\s*([-\w]+) = (\d+\.\d+\.\d+\.\d+)/mg)
	    {
		my $key = $1;
		my $val = $2;

		warn "# P: $key = $val\n" if $Debug;

		next if grep { $key eq $_ } @Ignore;
		
		if ($key =~ /Framed/)
		{
		    push @addrs, NetAddr::IP->new($val, $netmask);
		}
		else
		{
		    push @addrs, NetAddr::IP->new($val);
		}
	    }

	    if ($Debug)
	    {
		warn "# addr $_\n" for @addrs;
		warn "# iaddr $_\n" for map { $_->ip } @{$rep->incidents};
		warn "# itime $_\n" for map { $_->time } @{$rep->incidents};
	    }

	    for my $i (@addrs)
	    {
		push @match, grep { $_->time } 
		grep { $i->contains($_->ip) } @{$rep->incidents};
	    }

	    unless (@match)
	    {
		warn "# No matching IP\n" if $Debug;
		$record = '';
		next;
	    }
				# Get the CDR timestamp

	    unless ($record =~ m/^([^\n]+)/)
	    {
		warn "# No timestamp\n" if $Debug;
		$record = '';
		next;
	    }
	    my $stamp = str2time($1);

				# Adjust stamp according to the accounting
				# delay, if present

	    $stamp -= $1 if $record =~ m/^\s*Acct-Delay-Time = (\d+)/mi;

	    unless ($record =~ m/^\s*Acct-Session-Time = (\d+)/mi)
	    {
		warn "# No Acct-Session-Time\n" if $Debug;
		$record = '';
		next;
	    }

	    my $length = $1;

	    for my $i (@match)
	    {
		if ($i->time >= $stamp
		    and $i->time <= $stamp + $length)
		{
		    $i->radius({});
		    while ($record =~ m/^\s*([-\w]+) = (.+)$/mg)
		    {
			$i->radius->{$1} = $2;
		    }
		}
	    }

	    $record = '';
	}
    }

    return;
}

sub _dispatch
{
    my $self	= shift;
    my $rep	= shift;
    my $type	= shift;
    my $file	= shift;

    return unless -f $file;
    warn "M::A::P::Radius: Processing $file\n" 
	if $Debug;
    my $fh = new IO::File;
    unless ($fh->open($file, "<:gzip(autopop)"))
    {
	warn "M::A::P::Radius: Open of $file failed: $!\n";
	return;
    }
    $Dispatch{$type}->($self, $rep, $file, $fh);
    $fh->close;
}

sub process
{
    my $self	= shift;
    my $rep	= shift;

    unless ($rep->config or ref $rep->config ne 'HASH')
    {
	warn "Invalid or no config";
	return;
    }

    my $type	= lc $rep->config->{&TYPE} || 'livingston';
    my $loc	= $rep->config->{&LOCATION} || '/var/raddb/details';
    $Debug	= $rep->config->{&DEBUG};

    unless (-d $loc or -f _)	# Bail out if given garbage detail path
    {
	warn "M::A::P::Radius: ", &LOCATION, 
	" does not point to a valid directory or file\n";
	return;
    }

    unless (grep { $type eq $_ } keys %Dispatch)
    {
	warn "M::A::P::Radius: '$type' is not a valid '", &TYPE, "'\n";
	return;
    }

				# Empty reports need no further action
    
    return if @{$rep->incidents} == 0;

    if (-f $loc)
    {
	$self->_dispatch($rep, $type, $loc);
    }
    elsif (-d $loc)
    {
	find
	    ({
		wanted		=> sub
		{
		    $self->_dispatch($rep, $type, $File::Find::name);
		},
		follow		=> 1,
		no_chdir	=> 1,
		untaint		=> 1,
		untaint_skip	=> 1,
	    }, $loc);
    }
    else
    {
	warn "M::A::P::Radius: Don't know how to deal with ", &LOCATION, "\n";
	return;
    }
    return 1;
}

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkn
	Mail::Abuse
	-v
	0.01

=back


=head1 LICENSE AND WARRANTY

This code and all accompanying software comes with NO WARRANTY. You
use it at your own risk.

This code and all accompanying software can be used freely under the
same terms as Perl itself.

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
