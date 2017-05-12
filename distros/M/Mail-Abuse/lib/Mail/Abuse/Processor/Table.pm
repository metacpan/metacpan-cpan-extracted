package Mail::Abuse::Processor::Table;

require 5.005_62;

use Carp;
use strict;
use warnings;
use PerlIO::gzip;
use IO::File;
use NetAddr::IP;
use Tie::NetAddr::IP;

use base 'Mail::Abuse::Processor';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

our %Table = ();

=pod

=head1 NAME

Mail::Abuse::Processor::Table - Match incidents to users using a static table

=head1 SYNOPSIS

  use Mail::Abuse::Processor::Table;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::Table;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class matches incidents to 

=over

=item B<debug table>

If set to a true value, causes this module to emit debugging info
using C<warn()>.

=cut

use constant DEBUG	=> 'debug table';

=pod

=item B<table location>

The path of a file where the information table is to be found. The
file consists on columns separated by whitespace and should have the
following format:

    IP-range  var=value;var=value;...
    IP-range  var=value;var=value;...
    IP-range  var1.var2=value;var=value;...

B<IP-range> should be an IP subnet in any format that can be
understood by C<NetAddr::IP>. Tipically, this should be CIDR location,
for readability. The following example:

    10.0.0.0 foo=bar;baz=camel;fumble.foo=pivot

Would yield the following structure as result when a match occurs:

    { foo => 'bar', baz = 'camel', fumble => { foo = 'pivot' }}

These values should not be changed, as currently they are references
to the actual data read.

On the last column, a number of variables and its values can be
specified. Multiple tuples can be separated by a ';' character. The
dot in the name can be used in place of the C<-E<gt>> operator, to
easily create hashrefs. These hashrefs are stored in the
C<Mail::Abuse::Incident> object that is passed to the C<process()>
method.

Comments are delimited by a '#' character, which causes the text up to
the end of line to be ignored.

=cut

use constant LOCATION	=> 'table location';

=pod

=back

The following functions are implemented.

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and, for each
C<Mail::Abuse::Incident> collected, perform a lookup in the given
table, attempting to match it by IP address.

If a match is found, all the supplied hashrefs are introduced in the
C<Mail::Abuse::Incident> under the key C<table>. 

=cut
    ;

sub _parse_table ($)
{
    my $loc = shift;

    return if %Table;		# do nothing if this is populated

    my $fh = new IO::File;

    unless ($fh->open($loc, '<:gzip(autopop)'))
    {
	die "M::A::P::Table: Failed to open table $loc: $!\n";
    }

    while (my $line = <$fh>)
    {
	chomp $line;
	$line =~ s/^\s+//;
	$line =~ s/#.*$//;	# Get rid of comments and ignore blanks
	next if $line =~ /^\s*$/;

	my ($spec, $data) = split /\s+/, $line, 2;
	
	next unless $spec = new NetAddr::IP $spec;

	my $hash = {};

	for my $tuple (split /;/, $data)
	{
	    my $where = $hash;
	    my ($var, $val) = split /=/, $tuple, 2;
	    my @keys = split /\./, $var;
	    my $last = pop @keys;
	    for my $item (@keys)
	    {
		$where->{$item} = {} unless $where->{$item};
		$where = $where->{$item};
	    }
	    $where->{$last} = $val;
	}
	$Table{$spec} = $hash;
    }

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

    my $loc	= $rep->config->{&LOCATION};
    my $debug	= $rep->config->{&DEBUG};
    my $fh;

    unless ($loc and -f $loc)	# Bail out if given garbage detail path
    {
	warn "M::A::P::Table: ", &LOCATION, 
	" does not point to a valid file\n";
	return;
    }

    _parse_table $loc;

    return if @{$rep->incidents} == 0;

    for my $i (@{$rep->incidents})
    {
	if (my $result = $Table{$i->ip})
	{			# Match!
	    $i->table({}) unless $i->table;
	    $i->table->{$_} = $result->{$_} for keys %$result;
	}
    }
    return 1;
}

tie %Table, 'Tie::NetAddr::IP';

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: Table.pm,v $
Revision 1.2  2005/11/05 23:20:37  lem
Replaced IO::Zlib with PerlIO::gzip.

Revision 1.1  2004/02/05 22:41:50  lem
Added Mail::Abuse::Processor::Table, which requires
Tie::NetAddr::IP. This module will allow for matching 'fixed' address
ranges against the incidents. This can be easily used to map customer
data for relatively static connections, such as Frame-Relay or
similar.


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
