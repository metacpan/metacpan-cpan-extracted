package Mail::Abuse::Incident::SpamCop;

require 5.005_62;

use Carp;
use strict;
use warnings;
use NetAddr::IP;
use Date::Parse;

use base 'Mail::Abuse::Incident';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.11 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Incident::SpamCop - Parses SpamCop reports into Mail::Abuse::Reports

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Incident::SpamCop;

  my $i = new Mail::Abuse::Incident::SpamCop;
  my $report = new Mail::Abuse::Report (incidents => [$i] );

=head1 DESCRIPTION

This class parses SpamCop incidents. See http://www.SpamCop.net/ for
more information regarding their excellent service.

The following functions are provided for the customization of the
behavior of the class.

=cut

=over

=item C<parse($report)>

Pushes all instances of SpamCop incidents into the given report, based
on parsing of the text in the report itself.

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

    if ($rep->normalized)
    {
	$text = $rep->body;
	my $xmailer = $rep->header->get('X-Mailer') || '';
	my $subject = $rep->header->get('Subject') || '';
	#warn "# Match 1.a: normalized\n";
	return unless $xmailer =~ m!http://(www\.)?spamcop.net!;
	#warn "# Match 1.b: normalized\n";
	return unless $subject =~ m!\[SpamCop!;
	#warn "# Match 1: normalized\n";
    }
    else
    {
	$text = $rep->text;
	#warn "# Match 1.a: non-normalized\n";
	return unless $$text =~ m!^X-Mailer: http://(www\.)?spamcop.net/!m
	    or $$text =~ m!^X-SpamCop-sourceip: !m;
	#warn "# Match 1.b: non-normalized\n";
	return unless $$text =~ m!^Subject: .*\[SpamCop!m;
	#warn "# Match 1.c: non-normalized\n";
	return unless $$text =~ /[-\[] SpamCop/m;
	#warn "# Match 1: non-normalized\n";
    }

    return unless $$text =~ m!This message is brief!m;

    if ($$text =~ m!Email from (\d+\.\d+\.\d+\.\d+)\s+/\s+(.+)!)
    {
	my $ip		= new NetAddr::IP $1;
	my $date	= $2;
	return unless $ip;

	#warn "# Match 2: ip=$ip date=$date\n";

	# Remove truncated timezones
	$date =~ s/\([^\)]+$//;
	$date =~ s/\[.*$//;
	# Parse the date
	$date = str2time($date, $rep->tz);
	
	my $i = $self->new();
	$i->ip($ip);
	$i->time($date);
	$i->type('spam/SpamCop');
	
	$$text =~ m!(^http://(www\.)?spamcop.net/w3m.+)\s*$!m;
	
	$i->data($1 || 'no data');
	#warn "# Created incident $i\n";
	push @ret, $i;
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

perl(1), http://www.SpamCop.net.

=cut

