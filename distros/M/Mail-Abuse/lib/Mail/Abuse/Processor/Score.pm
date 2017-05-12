package Mail::Abuse::Processor::Score;

require 5.005_62;

use Carp;
use strict;
use warnings;

use base 'Mail::Abuse::Processor';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

use constant REPORT	=> 'score report text';
use constant INCIDENT	=> 'score incident type';
use constant MINIMUM	=> 'score minimum value';
use constant MAXIMUM	=> 'score maximum value';
use constant DEBUG	=> 'debug score';

=pod

=head1 NAME

Mail::Abuse::Processor::Score - Assign a score to an abuse report

=head1 SYNOPSIS

  use Mail::Abuse::Processor::Score;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::Score;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class allows for the computation of a score value, that can be
stored in the C<Mail::Abuse::Report> object itself. The score can be
used by other processes for different purposes, such as priorizing
incident handling, noise rejection and filtering, etc.

The way in which the score is calculated is controlled by the
following configuration entries:

=over

=item B<score report text: E<lt>valueE<gt> E<lt>regexpE<gt> ...>

Can accept multiple (value, regexp) pairs, where value is a numeric
constant that will be added to the "current" score of a report and
regexp is a Perl regular expression that contains no
whitespace. Spaces in the regular expression must be written in terms
of C<\s>.

Each regexp will be matched in sequence over the unprocessed text of
the report, and if it matches, the corresponding value will be added
to the report's score. Negative values cause the score to decrease, as
expected.

=item B<score incident type: E<lt>valueE<gt> E<lt>regexpE<gt> ...>

Can accept multiple (score, regexp) pairs just as in B<score report
text>, but what will be matched is the type of each incident already
in the report.

=item B<score minimum value: E<lt>valueE<gt>>

Enforce this value as the minimum score for a report.

=item B<score maximum value: E<lt>valueE<gt>>

Enforce this value as the maximum score for a report.

=item B<debug score>

When set to a true value, debug information will be issued using
C<warn()>.


=back

In the case where no configuration entry matches or is specified, the
score will be set to zero.

The following functions are implemented.

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and performs the
processing action required.

=cut

sub _decode_args ($$)
{
    my $rep	= shift;
    my $code	= shift;
    my (@tuples) = split(/\s+/, $rep->config->{$code} || '');
    return unless @tuples;

    die "'$code' specified with an odd number of paramenters.\n"
	if (@tuples % 2);
    
    my @ret = ();

    while (@tuples)
    {
	my $score	= shift @tuples;
	my $regexp	= shift @tuples;
	$regexp = qr/$regexp/m;

	push @ret, [ $regexp, $score ];
    }

    @ret;
}

sub process
{
    my $self	= shift;
    my $rep	= shift;

    # Set default score of the report
    $rep->score(0);

    # Obtain the arguments in our config file
    my @rep_regexps = _decode_args $rep, &REPORT;
    my @inc_regexps = _decode_args $rep, &INCIDENT;

    if ($rep->config->{&DEBUG})
    {
	if (@rep_regexps)
	{
	    warn "Score: rep_regexps is\n";
	    warn "  $_->[0]: $_->[1]\n" for @rep_regexps;
	}
	else
	{
	    warn "Score: No regexps for reports specified\n";
	}
	if (@inc_regexps)
	{
	    warn "Score: inc_regexps is\n";
	    warn "  $_->[0]: $_->[1]\n" for @inc_regexps;
	}
	else
	{
	    warn "Score: No regexps for incidents specified\n";
	}
    }

    # We'll work on the unprocessed (un-normalized text)
    my $r_text = $rep->text;

    for my $r (@rep_regexps)
    {
	next unless ${$r_text} =~ m/$r->[0]/;
	$rep->score($rep->score + $r->[1]);
    }

    # Iterate through all the incidents
    for my $i (@{$rep->incidents})
    {
	for my $r (@inc_regexps)
	{
	    next unless $i->type;
	    next unless $i->type =~ m/$r->[0]/;
	    $rep->score($rep->score + $r->[1]);
	}
    }

    # Enforce the minimum and maximum
    if (defined $rep->config->{&MAXIMUM})
    {
	$rep->score($rep->config->{&MAXIMUM})
	    if $rep->score > $rep->config->{&MAXIMUM};
    }

    if (defined $rep->config->{&MINIMUM})
    {
	$rep->score($rep->config->{&MINIMUM})
	    if $rep->score < $rep->config->{&MINIMUM};
    }
}

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: Score.pm,v $
Revision 1.3  2005/03/22 16:07:31  lem
Implemented minimum and maximum scores

Revision 1.2  2005/03/16 22:24:42  lem
Add m to regexps.

Revision 1.1  2005/03/16 22:13:23  lem
Added Mail::Abuse::Processor::Score to calculate scores for the abuse reports


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
