package Mail::Abuse::Incident::Log;

require 5.005_62;

use Carp;
use strict;
use warnings;
use NetAddr::IP;
use Date::Parse;

use base 'Mail::Abuse::Incident';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.24 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Incident::Log - Parses generic logs into Mail::Abuse::Reports

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Incident::Log;

  my $i = new Mail::Abuse::Incident::Log;
  my $report = new Mail::Abuse::Report (incidents => [$i] );

=head1 DESCRIPTION

This class parses generic logs that include a timestamp and an IP
address in the same group of lines. Various configuration keys can
influence the way this module works, as follows:

=over

=item B<log lines>

Controls how many consecutive lines to attempt a match on. More lines
generally means more incidents parsed, but might lead to false
matches. Its default value is 5 lines, which seems to work well
enough. This should vary widely by site.

=cut

use constant LINES => 'log lines';

=pod

=item B<debug log>

When set to a true value, produces some debugging information sent
through C<warn()>.

=back

=cut

use constant DEBUG => 'debug log';

=pod

The following functions are provided for the customization of the
behavior of the class.

=cut

=over

=item C<parse($report)>

Pushes all instances of log incidents into the given report, based
on parsing of the text in the report itself.

Returns a list of objects of the same class, with the incident data
(IP address, timestamp and other information) filled.

The IP address and timestamp searching is done in a consecutive number
of lines. This number can be set with the C<log lines> variable, and
defaults to 5 lines.

This module tends to get a significant number of, potentially false,
incidents out of reports. Adjust the number of lines carefully based
on the types of complaints that your site receives.

=cut

sub _push ($$$$$$)
{
    my $self	= shift;
    my $rep	= shift;
    my $ip	= shift;
    my $date	= shift;
    my $data	= shift;
    my $subtype	= shift;
    my $ret	= shift;

    my $i = $self->new();
    $i->ip($ip);
    $i->time($date);
    $i->type("log/$subtype");
    $i->data($data || 'no data');

    return 
	if grep { $i->ip eq $_->ip 
		      and $i->time == $_->time 
			  and $i->type eq $_->type } @$ret;

    push @$ret, $i;

#    warn "_push $ip $date, ret=", scalar @$ret, "\n";

    return $i;
}

sub _add_ip ($$)
{
    my $ip = new NetAddr::IP $_[1] or return;

    for (@{$_[0]})
    {
	return if $_ == $ip;
    }
    push @{$_[0]}, $ip;
#    warn "# _add_ip $_[1], ret=", scalar @{$_[0]}, "\n";
}

sub _add_time ($$)
{
    for (@{$_[0]})
    {
	return if $_ == $_[1]->[1];
    }
    push @{$_[0]}, $_[1]->[1];
}

sub parse
{
    my $self	= shift;
    my $rep	= shift;

    my @ret = ();		# Default return
    my $count = 0;

    my $text = undef;
    my $lines = ($rep->config ? $rep->config->{&LINES} : '') || 5;
    my $debug = ($rep->config ? $rep->config->{&DEBUG} : 0);

    $lines --;

    my $subtype;

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

    return unless $$text;

    # Attempt to guess a type of log by
    # searching for keywords performing
    # score-based identification

    my %rules = (
		 'copyright'	=> qr(copyright\W+infringement
				      |rights|media|kazaa|edonkey|DMCA|BSA
				      |MPAA|RIAA|copyrighted\W+material
				      |(anti-?)?piracy)ix,
		 'virus'	=> qr(virus|worm)ix,
		 'proxy'	=> qr(proxy|socks|squid)ix,
		 'network'	=> qr(scan|ids|intrusion|firewall
				      |portscan|connection)ix,
		 'spam'		=> qr(spam|uce|ube|unsolicited|mass
				      x-virus-|e?smtp)ix,
		 );

    my %scores = map { $_ => 0 } keys %rules;
    $scores{$subtype = '*'} = 0;

    for my $r (keys %rules)
    {
	my $re = $rules{$r};
	$scores{$r} ++ while $$text =~ m/\W($re)\W/ixg;
	$scores{$r} ++ while $$text =~ m/^($re)\W/ixg;
	$scores{$r} ++ while $$text =~ m/\W($re)$/ixg;
	$scores{$r} ++ while $$text =~ m/^($re)$/ixg;
    }

    foreach (keys %scores)
    {
	$subtype = $_ if $scores{$_} > $scores{$subtype};
    }

    warn "M::A::I::Log: subtype is $subtype due to scoring\n"
	if $debug;

    my @time;			# List of timestamps
    my @addr;			# List of IP addresses

    for my $skip (0..$lines-1)
    {
	$$text =~ m!^!g;
	$$text =~ m!(([^\n]*\n){$skip,$skip})!g;

	while ($$text =~ m!^(([^\n]*\n)(([^\n]*\n){0,$lines})?)!mg)
	{

	    @time = ();
	    @addr = ();

				# Get candidate timestamps here first
				# to get rid of false matches

	    my @candidates	= ();
	    my @passed		= ();

	    my $line = $1;

	    _add_ip \@addr, $1 while $line =~ m/(\d+\.\d+\.\d+\.\d+)/g;

	    while ($line =~ m/(\d+[:-]\d+[:-]\d+T[\d:\.]+)/g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [1] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }

	    while ($line =~ m/((\w{3},\s+)?\d+\s+\w+\s+\d+\s+[\d:]+(\s[-+]?[A-Z0-9]+)?)/g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [2] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }

	    while ($line =~ m!(\d+[/-]\d+[/-]\d+\s+\d+:\d+:\d+)!g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [3] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }

	    while ($line =~ m!(\d+[/-]\w+[/-]\d+[:\s]+\d+:\d+:\d+)!g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [4] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }

	    while ($line =~ m!(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\w+\s+\d+)!g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [5] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }

	    while ($line =~ m!((\w{3}\s)?\w{3}\s+\d+\s\d+:\d+:\d+(\s\d+)?)!g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [6] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }
	    
 	    while ($line =~ m/(\w+,?\s+\d+\s+\d+\s+\d+:\d+(:\d+)?\s*((AM|PM)?\s*[-+]?[A-Z0-9]+)?)/g)
 	    {
 		my $p = str2time($1, $rep->tz) || next;
 		warn "M::A::I::Log: matched [7] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
 		push @candidates, [ $1, $p ];
 	    }

	    while ($line =~ m!(\d+/\d+)-(\d+:\d+:\d+)!g)
	    {
		my $p = str2time("$1 $2", $rep->tz) || next;
		warn "M::A::I::Log: matched [8] date $1 $2 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ "$1 $2", $p ];
	    }
	    
	    while ($line =~ m!Date: (\d+-\d+-\d+), Time: (\d+:\d+:\d+)!g)
	    {
		my $p = str2time("$1 $2", $rep->tz) || next;
		warn "M::A::I::Log: matched [9] date $1 $2 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ "$1 $2", $p ];
	    }

	    while ($line =~ m/(\d{2}\s+\w{3}\s+\d{4}\s+\d+:\d\d:\d\d(\s+[-+]?[A-Z0-9]+)?)/g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [10] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }

	    while ($line =~ m!(\d+/\w+/\d+)[:/](\d+:\d+:\d+(\s+[-+]?[\d\w]+)?)!g)
	    {
		my $p = str2time("$1 $2", $rep->tz) || next;
		warn "M::A::I::Log: matched [11] date $1 $2(" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ "$1 $2", $p ];
	    }

	    # Mar 02 2004 15:21:35

	    while ($line =~ m!(\w+ \d+ \d+ \d+:\d+:\d+)!g)
	    {
		my $p = str2time($1, $rep->tz) || next;
		warn "M::A::I::Log: matched [12] date $1 (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $1, $p ];
	    }

	    # 4Mar2004  3:30:50

	    while ($line =~ m!((\d+)(\w{3})(\d+)\s+(\d+:\d+:\d+))!g)
	    {
		my $date = "$2 $3 $4 $5";
		my $p = str2time($date, $rep->tz) || next;
		warn "M::A::I::Log: matched [13] date $date (" . 
		    scalar localtime($p) . ")\n" if $debug;
		push @candidates, [ $date, $p ];
	    }

				# @candidates contain all proto-timestamps
				# Partial matches are possible, so we must
				# choose only the longest

#	    warn "passed (before)\n";
#	    warn "-> $_\n" for @candidates;

	    for my $t (sort { length $a->[0] <=> length $b->[0] } @candidates)
	    {
		@passed = grep { index($t, $_->[0]) < 0; } @passed;
		push @passed, $t
	    }

#	    warn "passed (after)\n";
#	    warn "-> $_\n" for @passed;

	    _add_time \@time, $_ for @passed;

#  	    if (@time and @addr)
#  	    {
#  		warn "M::A::I::Log: Matches for block [$line] follows:\n"
#  		    if $debug;
#  	    }

	    for my $time (@time)
	    {
		for my $a (@addr)
		{
		    my $p = $self->_push($rep, $a, $time, 
					 $line, $subtype, \@ret);
		    warn "M::A::I::Log: add incident $a, ", 
		    scalar localtime $time, "\n"
			if $p and $debug;
		}
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

