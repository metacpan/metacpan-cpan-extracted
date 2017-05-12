package Mail::Abuse::Filter::IP;

require 5.005_62;

use Carp;
use strict;
use warnings;

use NetAddr::IP;

use base 'Mail::Abuse::Filter';

use constant DEBUG	=> 'debug ip filter';
use constant WITHIN	=> 'source ip within';
use constant OUTSIDE	=> 'source ip outside';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Filter::IP - Filter incidents according to its origin IP

=head1 SYNOPSIS

  use Mail::Abuse::Filter::IP;
  my $f = new Mail::Abuse::Filter::IP;

  $report->filter([$f]);

=head1 DESCRIPTION

Removes those events from a C<Mail::Abuse::Report> whose origin does
not match the rules enforced by this module. The actual rules must be
specified in the configuration file for the abuse report.

The following configuration keys are recognized:

=over

=item B<source ip within>

If specified, the source IP address must fall within the subnets given
as aguments to this configuration keys. Multiple subnets can be
specified by separating them with whitespace or commas.

If left unspecified, this field defaults to "0/0", which matches any
source IP address.

Subnets can be written in any format supported by L<NetAddr::IP>.

=item B<source ip outside>

If specified, the source IP address must not lie within the subnets
specified. Subnets can be separated with spaces or commas.

=item B<debug ip filter>

Set to a true value to see various debugging messages.

=back

The following methods are implemented in this class.

=over

=item C<criteria($report, $incident)>

This function receives a C<Mail::Abuse::Report> and a
C<Mail::Abuse::Incident> object. It returns a true value if the
incident should be handled or false otherwise. This function will be
generally called by the C<Mail::Abuse::Report> object when requested
to filter its events.

The key C<filtered> in the C<Mail::Abuse::Report> object will be
incremented for each incident removed.

=cut

sub criteria
{
    my $self	= shift;
    my $rep	= shift;
    my $inc	= shift;

    if (!$self->within and $rep->config->{&WITHIN})
    {
#  	unless (ref $rep->config->{&WITHIN} eq 'ARRAY')
#  	{
#  	    $rep->config->{&WITHIN} = [ $rep->config->{&WITHIN} ];
#  	}
	$self->within([]);
	for my $ip (map { new NetAddr::IP $_ } 
		    split m/[\s,]+/, $rep->config->{&WITHIN})
	{
	    unless ($ip)
	    {
		die "Filter::IP: Please check your '", &WITHIN, 
		"' clause for errors\n";
	    }
	    warn "Filter::IP: Adding $ip to 'within' clause\n"
		if $rep->config->{&DEBUG};
	    push @{$self->within}, $ip;
	}
	warn "Filter::IP: 'within' clause contains ", scalar @{$self->within},
	" subnets\n" if $rep->config->{&DEBUG};
    }

    if (!$self->outside and $rep->config->{&OUTSIDE})
    {
#  	unless (ref $rep->config->{&OUTSIDE} eq 'ARRAY')
#  	{
#  	    $rep->config->{&OUTSIDE} = [ $rep->config->{&OUTSIDE} ];
#  	}
	$self->outside([]);
	for my $ip (map { new NetAddr::IP $_ } 
		    split /[\s,]+/, $rep->config->{&OUTSIDE})
	{
	    unless ($ip)
	    {
		die "Filter::IP: Please check your '", &OUTSIDE, 
		"' clause for errors\n";
	    }
	    warn "Filter::IP: Adding $ip to 'outside' clause\n"
		if $rep->config->{&DEBUG};
	    push @{$self->outside}, $ip;
	}
	warn "Filter::IP: 'outside' clause contains ", 
	scalar @{$self->outside}, " subnets\n" 
	    if $rep->config->{&DEBUG};
    }

    if ($self->within)
    {
	if (grep 
	    { 
		my $c = $_->contains($inc->ip);
		warn "Filter::IP: (within) $_ contains " . $inc->ip . "\n"
		    if $c and $rep->config->{&DEBUG};
		$c;
	    } @{$self->within})
	{
	    warn "Filter::IP: 'within' clause allows " . $inc->ip . "\n"
		if $rep->config->{&DEBUG};
	}
	else
	{
	    warn "Filter::IP: 'within' clause denies " . $inc->ip . "\n"
		if $rep->config->{&DEBUG};
	    $rep->filtered(0) unless $rep->filtered;
	    $rep->filtered($rep->filtered + 1);
	    return;
	}
    }

    if ($self->outside)
    {
	if (grep 
	    { 
		my $c = $_->contains($inc->ip);
		warn "Filter::IP: (outside) $_ contains " . $inc->ip . "\n"
		    if $c and $rep->config->{&DEBUG};
		$c;
	    } @{$self->outside})
	{
	    warn "Filter::IP: 'outside' clause denies " . $inc->ip . "\n"
		if $rep->config->{&DEBUG};
	    return;
	}
	else
	{
	    warn "Filter::IP: 'outside' clause allows " . $inc->ip . "\n"
		if $rep->config->{&DEBUG};
	}
    }

    return $inc;
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
