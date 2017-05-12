package Mail::Abuse::Filter::Time;

require 5.005_62;

use Carp;
use strict;
use warnings;

use Date::Manip;

use base 'Mail::Abuse::Filter';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Filter::Time - Filter incidents according to how old they are

=head1 SYNOPSIS

  use Mail::Abuse::Filter::Time;
  my $f = new Mail::Abuse::Filter::Time;

  $report->filter([$f]);

=head1 DESCRIPTION

Removes those events from a C<Mail::Abuse::Report> that are older than
a given threshold, which can be specified in the configuration file
for the abuse report.

The following configuration keys are recognized:

=over

=item B<filter before>

Incidents older than the specified time will be removed from the
report and not considered. The time can be specified as a specific
date or as a time delta according to the specifications in
L<Date::Manip>.

If this is not specified, the default is to ignore incidents that
happened more than 96 hours in the past (ie, "96 hours ago").

=item B<filter after>

Incidents newer than the specified time will be removed from the
report and not considered. Normally, this time specification should be
specified as a relative date (ie, "in 48 hours" which is the
default). This is useful to discard events that occur in the future.

=item B<filter local timezone>

If specified, assume this timezone for the conversion of the
dates. Defaults to UTC.

=item B<debug time filter>

When set to a true value, causes this module to emit debugging
messages via C<warn()>. Of course, defaults to a false value.

=back

The following methods are implemented in this class.

=over

=item C<criteria($report, $incident)>

This function receives a C<Mail::Abuse::Report> and a
C<Mail::Abuse::Incident> object. It returns a true value if the
incident should be handled or false otherwise. This function will be
generally called by the C<Mail::Abuse::Report> object when requested
to filter its events.

=cut

sub criteria
{
    my $self	= shift;
    my $rep	= shift;
    my $inc	= shift;

#    warn "criteria self: ", ref $self, "\n";
#    warn "criteria rep: ", ref $rep, "\n";
#    warn "criteria inc: ", ref $inc, "\n";

    unless ($self->before)
    {
	my $date_before;
	my $date_after;

	Date_Init("TZ=" . ($rep->config->{'filter local timezone'} || 'UTC'));

	eval 
	{
	    if (ref $rep->config->{'filter before'} eq 'ARRAY')
	    {
		$date_before = 
		    ParseDate(join(' ', 
				   @{$rep->config->{'filter before'}}));
	    }
	    else {
		$date_before = 
		    ParseDate($rep->config->{'filter before'} 
			      || "96 hours ago");
	    }

	    if (ref $rep->config->{'filter after'} eq 'ARRAY')
	    {
		$date_after = 
		    ParseDate(join(' ', 
				   @{$rep->config->{'filter after'}}));
	    }
	    else {
		$date_after = 
		    ParseDate($rep->config->{'filter after'} 
			      || "in 48 hours");
	    }
	};

	warn "Parsing said: $@" if $@ and $rep->config->{'debug time filter'};
	die "Filter::Time: Cannot parse 'filter before' date\n" 
	    unless $date_before;
	die "Filter::Time: Cannot parse 'filter after' date\n" 
	    unless $date_after;
	$self->before(UnixDate($date_before, '%s'));
	$self->after(UnixDate($date_after, '%s'));
	die "Filter::Time: Times before the epoch are not supported" 
	    if $self->before < 0;
	
	warn "Filter::Time: Removing incidents older than ", $self->before, 
	"\n" if $rep->config->{'debug time filter'};
	warn "Filter::Time: Removing incidents newer than ", $self->after, 
	"\n" if $rep->config->{'debug time filter'};
    }

    if ($inc->time and $self->before and $inc->time < $self->before)
    {
	warn "Filter::Time - discard before ", $inc->time, "\n" 
	    if $rep->config->{'debug time filter'};
	$rep->filtered(0) unless $rep->filtered;
	$rep->filtered($rep->filtered + 1);
	return;
    }
    elsif ($inc->time and $self->after and $inc->time > $self->after)
    {
	warn "Filter::Time - discard after ", $inc->time, "\n" 
	    if $rep->config->{'debug time filter'};
	$rep->filtered(0) unless $rep->filtered;
	$rep->filtered($rep->filtered + 1);
	return;
    }

    warn "Filter::Time - accept ", $inc->time, "\n" 
	if $rep->config->{'debug time filter'};
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
