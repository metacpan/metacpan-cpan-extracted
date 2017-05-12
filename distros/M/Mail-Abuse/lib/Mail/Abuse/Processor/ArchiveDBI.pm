package Mail::Abuse::Processor::ArchiveDBI;

require 5.005_62;

use DBI;
use strict;
use warnings;

use base 'Mail::Abuse::Processor';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

use constant REPORT_DSN		=> 'archive dsn';
use constant REPORT_USER	=> 'archive user';
use constant REPORT_PASSWORD	=> 'archive password';
use constant REPORT_COLS	=> 'archive reports columns';
use constant INCIDENT_COLS	=> 'archive incident columns';
use constant INCIDENT_FK	=> 'archive incident foreign key';
use constant DEBUG		=> 'debug archive';

my $sql_ireport = ';';		# Report insertion SQL
my $sql_iincident = ';';	# Incident insertion SQL

my $dbh;			# Our database handler
my $sth_ireport;		# Report insertion statement
my $sth_iincident;		# Incident insertion statement

my $rep_cols;
my $inc_cols;
my $inc_fks;

my @cols_rep = ();
my @cols_inc = ();

=pod

=head1 NAME

Mail::Abuse::Processor::ArchiveDBI - Assign a score to an abuse report

=head1 SYNOPSIS

  use Mail::Abuse::Processor::ArchiveDBI;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::ArchiveDBI;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class allows for the storage of index information from a
C<Mail::Abuse::Report> object and the C<Mail::Abuse::Incident> objects
it contains. The storage is done into any backend properly supported
by DBI.

B<This module can only be used once in the pipeline.> The DBI handle
used is kept in a package-local variable. This is not a problem,
usually. The database connection is disconnected upon object
destruction.

The following configuration entries control the behavior of this
module:

=over

=item B<archive dsn>

Specifies the DSN to be used to connect to the DBI datasource. See
L<DBI> for information about its format for using different backends.

=item B<archive user>

The username required for connection to the DBI datasource.

=item B<archive password>

The password required for connection to the DBI datasource.

=item B<archive reports columns>

Define which data elements from a C<Mail::Abuse::Report> object will
be stored as the columns of each row in the database. The elements are
specified as E<lt>columnE<gt>:E<lt>methodE<gt>, where B<column> is
the database column name used to denote said element and B<method> is
the accessor in the C<Mail::Abuse::Report> object.

Multiple elemnts referring to the same column can be specified, so as
to provide alternative means of accessing the data. The methods are
accessed as depicted for the option -m for L<abuso>.

Usually, you will want "store_file" (created by
L<Mail::Abuse::Processor::Store>) to be used as the primary key, and
"score" as additional data, assuming that you use
C<::Processor::Store> and C<::Processor::Score> in your local
configuration.

There are special "pseudo-elements" that can be also used on the
right-hand side. Those are:

=over

=item C<$num>

The number of incidents left within this C<Mail::Abuse::Report>
object.

=item C<$time>

The current value of the C<time()> function.

=item C<$ENV{...}>

The current value of the corresponding environment variable, which may
also be undef.

=back

=item B<archive incident columns>

Define the data elements from each C<Mail::Abuse::Incident> that will
be stored in the DBI backend. This follows the same conventions and
syntax as B<archive report columns>.

The same "pseudo-elements" are supported, however the value of C<$num>
is the current index of the incident within the abuse report.

The typical value for this would include the elements "ip", "time" and
"type". The primary key for this table, typically will be "store_file"
and "$num".

=item B<archive incidents foreign key>

Since there is a one-to-many relationship between the report table and
the incident table, this configuration directive allows for the
specification of the columns that are used as the primary key of the
reports table.

Normally, you will want this to be "store_file", which serves as a
unique identifier for the report.

=item B<debug archive>

When set to a true value, debug information will be issued using
C<warn()>.

=back

The following functions are implemented.

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and performs the
processing action required.

=cut

sub DESTROY { $dbh and $dbh->disconnect(); }

sub _decode_columns ($$)
{
    my $rep = shift;
    my $key = shift;

    my %cols = ();

    for my $spec (split(/[,\s]+/, $rep->config->{$key}))
    {
	my ($col, $element) = split(/:/, $spec, 2);
	my $r_l = $cols{$col} || [];
	push @$r_l, $element unless grep { $_ eq $element } @$r_l;
	$cols{$col} = $r_l;
    }

    return \%cols;
}

# Obtain a value from a report or incident, in short circuit
# (ie, the first element to match, wins)
sub _value ($$$)
{
    my $obj		= shift;
    my $r_spec		= shift;
    my $r_dollars	= shift;

#    warn "# _value from $obj with ", join(', ', @$r_spec), "\n";

    my $ret	= undef;
    for my $spec (@$r_spec)
    {
	if ($spec =~ /^\$(\w+)$/)
	{
	    return $r_dollars->{$1} if exists $r_dollars->{$1};
	}
	elsif ($spec =~ m/^\$ENV{([^}]+)}$/)
	{
	    return $ENV{$1};
	}

	my @things = split /\./, $spec;
 
	my $r = $obj;
	my @own = @things;

	while (defined $r and my $c = shift @own)
	{
	    if ($c =~ /^\d+$/)
	    {
		unless (ref $r eq 'ARRAY')
		{
		    warn "ArchiveDBI: Invalid type for $spec\n";
		    undef $r;
		    last;
		}
		$r = $r->[$c];
	    }
	    elsif ($c)
	    {
		if (ref $r eq 'HASH')
		{
		    $r = $r->{$c};
		}
		elsif (eval { defined $r->$c })
		{
		    no strict "refs";
		    $r = $r->$c;
		}
		else
		{
#		    warn "ArchiveDBI: Invalid type for $spec\n";
		    undef $r;
		    last;
		}
	    }
	}
	return $r if defined $r;
    }
    return;
}

sub process
{
    my $self	= shift;
    my $rep	= shift;

    # Init the database connection if not already done
    unless ($dbh)
    {
	my $DSN			= $rep->config->{&REPORT_DSN};
	my $LOGIN		= $rep->config->{&REPORT_USER};
	my $PASSWORD		= $rep->config->{&REPORT_PASSWORD};

	# Database connection using the configured parameters
	$dbh = DBI->connect($DSN, $LOGIN, $PASSWORD,
			    { 
				AutoCommit => 1,
				RaiseError => 0,
				PrintError => 1,
			    },
			    );
	
	# Obtain the columns and elements we will be storing into the
	# database for each report.

	$rep_cols	= _decode_columns $rep, REPORT_COLS;
	$inc_cols	= _decode_columns $rep, INCIDENT_COLS;
	$inc_fks	= [ split(/[,\s]+/, $rep->config->{&INCIDENT_FK}) ];

	if ($rep->config->{&DEBUG})
	{
	    warn "# Report columns:\n";
	    while (my ($c, $r_e) = each %$rep_cols)
	    {
		warn "#   $c -> [ ", join(',', @$r_e), " ]\n";
	    }
	    warn "# Incident FKs:\n";
	    warn "#   ", join(', ', @$inc_fks), "\n";
	    warn "# Incident columns:\n";
	    while (my ($c, $r_e) = each %$inc_cols)
	    {
		warn "#   $c -> [ ", join(',', @$r_e), " ]\n";
	    }
	}

	# Create the SQL statements that reflect this configuration.

	@cols_inc = (@$inc_fks, sort keys %$inc_cols);
	@cols_rep = (sort keys %$rep_cols);
	
	if (@cols_inc)
	{
	    $sql_iincident = 'INSERT INTO Incidents (';
	    $sql_iincident .= join(', ', @cols_inc);
	    $sql_iincident .= ') VALUES (';
	    $sql_iincident .= join ', ', split //, 
	    '?' x @cols_inc;
	    $sql_iincident .= ')';
	}
	
	if (@cols_rep)
	{
	    $sql_ireport = 'INSERT INTO Reports (';
	    $sql_ireport .= join(', ', @cols_rep);
	    $sql_ireport .= ') VALUES (';
	    $sql_ireport .= join ', ', split //, 
	    '?' x @cols_rep;
	    $sql_ireport .= ')';
	}

	if ($rep->config->{&DEBUG})
	{
	    warn "# Report SQL statement:\n";
	    warn "#   I: $sql_ireport\n";
	    warn "# Incident SQL statement:\n";
	    warn "#   I: $sql_iincident\n";
	}	

	# Prepare the SQL statements that insert the requested
	# information into the database

	$sth_ireport	= $dbh->prepare($sql_ireport);
	$sth_iincident	= $dbh->prepare($sql_iincident);
    }

    # Find out the information about this report that we will send to the
    # database

    my %rep_values = ();	# Hash where the values for each key 
    				# will be stored...

    $rep_values{$_} = _value $rep, 
			     $rep_cols->{$_}, 
			     { time => time, 
			       num => scalar @{$rep->incidents}} for @cols_rep;

    if ($rep->config->{&DEBUG})
    {
	warn "# Values for this report:\n";
	warn "#   $_ = " . 
	    (defined($rep_values{$_}) ? $rep_values{$_} : 'UNDEF') . "\n" 
	    for @cols_rep;
    }    

    # Perform the insertion of the report information to the database

    $sth_ireport->execute(map { $rep_values{$_} } @cols_rep);

    # Iterate over the incidents to process each one in turn
    my $num = 0;

    for my $i (@{$rep->incidents})
    {
	# Insert the incident information in the database
	my %inc_values = ();

	$inc_values{$_} = $rep_values{$_} for @$inc_fks;
	$inc_values{$_} = _value $i, $inc_cols->{$_}, 
	{ time => time, num => $num } for keys %$inc_cols;

	if ($rep->config->{&DEBUG})
	{
	    warn "# Values for incident $num:\n";
	    warn "#   $_ = " . 
		(defined($inc_values{$_}) ? $inc_values{$_} : 'UNDEF') . "\n" 
		for @cols_inc;
	}    

	$sth_iincident->execute(map { $inc_values{$_} } @cols_inc);
	$num ++;
    }

}

"All your base are belong to us";

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: ArchiveDBI.pm,v $
Revision 1.6  2006/03/22 19:15:14  lem
Remove extraneous < - Thanks to Landon Steward for pointing this out

Revision 1.5  2006/03/13 23:20:29  lem
Make errors simply display warnings but keep processing. In some
instances abuse reports can be re-fed into the pipeline. This causes
these reports to not stall processing.

Revision 1.4  2006/02/21 16:59:53  lem
Added support for $ENV{...} in the column specifications, so that a
source/class can be attached to each report.

Revision 1.3  2005/11/14 00:36:34  lem
Minor edits (typos, golfing).

Revision 1.2  2005/03/31 19:11:34  lem
undef variables properly. Slight change in the 'debug' messages.

Revision 1.1  2005/03/21 20:06:15  lem
Initial support for Mail::Abuse::Processor::ArchiveDBI


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
