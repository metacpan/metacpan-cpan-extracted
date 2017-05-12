package Mail::Abuse::Incident::Received;

require 5.005_62;

use Carp;
use strict;
use warnings;
use NetAddr::IP;
use Date::Parse;

use base 'Mail::Abuse::Incident';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Incident::Received - Parses Received: headers in an abuse report

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Incident::Received;

  my $i = new Mail::Abuse::Incident::Received;
  my $report = new Mail::Abuse::Report (incidents => [$i] );

=head1 DESCRIPTION

This class parses standard Received: headers included in a given abuse
report.

Entries in the configuration file can control the behavior of this
module. The following entries are recognized:

=cut

use constant DEBUG	=> 'debug received';

=pod

=over

=item B<debug received>

When set to a true value, causes some debug information to be produced
via C<warn()>.

=cut


sub _add_time ($$$)
{
    my $time = str2time($_[1], $_[2]) or return;

    for (@{$_[0]})
    {
	return if $_ == $time;
    }

    push @{$_[0]}, $time;
}

sub _add_ip ($$)
{
    my $ip = new NetAddr::IP $_[1] or return;

    for (@{$_[0]})
    {
	return if $_ == $ip;
    }

    push @{$_[0]}, $ip;
}

=pod

=back

The functions provided by this module, are described below

=over

=item C<parse($report)>

Parses all the Received: headers, creating an instance with each
combination of IP address and timestamp found.

Returns a list of objects of the same class, with the incident data
(IP address, timestamp and other information) filled.

=cut

sub parse
{
    my $self	= shift;
    my $rep	= shift;

    my @ret = ();		# Default return
    my $count = 0;

    my $text = undef;

    my $debug = $rep->config ? $rep->config->{&DEBUG} : 0;

    warn "M::A::I::Received: debug\n" if $debug;

    if ($rep->normalized) 
    { 
	$text = $rep->body; 
    }
    else 
    { 
				# Skip the report headers and focus
				# on the offender's

	if ($ {$rep->text} =~ m!^\s*\n(.*)!xms)
	{
	    my $t = $1;
	    $text = \$t;
	}
	else
	{
	    $text = $rep->text; 
	}
    }

    unless ($$text and $$text =~ m!Received: !m)
    {
	warn "M::A::I::Received: No Received: headers in sight\n"
	    if $debug;
    }

    while ($$text and $$text =~ m!^(Received: .*?)(?=([-\w]+: |^\s*$))!msg)
    {
				# Analyze this Received: header
	my $header = $1;

	warn "M::A::I::Received: Matching header [$header]\n"
	    if $debug;

	my @a = ();
	my @t = ();
				# Add numeric IP addresses
	_add_ip \@a, $1 while $header =~ m/(\d+\.\d+\.\d+\.\d+)/g;

	_add_time \@t, $1, $rep->tz 
	    while $header =~ m/((\w+,\s+)?\d+\s\w+\s\d+\s[\d:]+\s[-+]?\w+)/g;

	for my $a (@a)
	{
	    for my $t (@t)
	    {
		my $i = $self->new();
		$i->ip($a);
		$i->time($t);
		$i->type('spam/Received');
		$i->data($header);
		
		warn "M::A::I::Received: Add incident for ", $i->ip, ", ",
		$i->time, "\n" if $debug;

		push @ret, $i;
	    }
	}
    }

    return @ret;
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

