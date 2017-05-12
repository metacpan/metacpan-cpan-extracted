package Mail::Abuse::Incident::MyNetWatchman;

require 5.005_62;

use Carp;
use strict;
use warnings;
use NetAddr::IP;
use Date::Parse;

use base 'Mail::Abuse::Incident';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Incident::MyNetWatchman - Parses MyNetWatchman reports into Mail::Abuse::Reports

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Incident::MyNetWatchman;

  my $i = new Mail::Abuse::Incident::MyNetWatchman;
  my $report = new Mail::Abuse::Report (incidents => [$i] );

=head1 DESCRIPTION

This class parses MyNetWatchman incidents. See
http://www.MyNetWatchman.com/ for more information regarding their
excellent service.

The following functions are provided for the customization of the
behavior of the class.

=cut

=over

=item C<parse($report)>

Pushes all instances of MyNetWatchman incidents into the given report, based
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
	return unless defined $rep->header->get('Subject');
	return unless $rep->header->get('Subject') =~ 
	    m!myNetWatchman Incident!;
    }
    else
    {
	$text = $rep->text;
	return unless $$text =~ m!^Subject: myNetWatchman Incident!m;
    }

    return unless $$text =~ m!myNetWatchman Incident \[\d+\] Src:!m;

				# Better guess at the timezone

    my $source = '';

    $$text =~ m!Time Zone: ([-+\d\w]+)! 
	and $rep->tz($1);
    $$text =~ m!Source IP: (\d+\.\d+\.\d+\.\d+)! 
	and $source = new NetAddr::IP $1;

    return unless $source;

    while ($$text =~ 
	   m!^(([^\n,]+, )?([^\n,]+), [^\n,]+, [^\n,]+, [^\n,]+, ([^\n,]+), [^\n,]+, [^\n,]+)$!gm)
    {
	my $data = $1;
	my $type = $4;
	my $date = str2time($3, $rep->tz);

	next unless defined $date;

	my $i = $self->new();
	$i->ip($source);
	$i->time($date);
	$i->type("mynetwatchman/$type");
	$i->data($data || 'no data');
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

perl(1), http://www.MyNetWatchman.com.

=cut

