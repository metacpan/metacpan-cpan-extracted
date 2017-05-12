#
#    Report.pm - Module that compiles reports from the logs preprocessed by
#		 the fwctllog program.
#
#    This file is part of Fwctl.
#
#    Author: Francis J. Lacoste <francis@iNsu.COM>
#
#    Copyright (c) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
package Fwctl::Report;

use strict;

use vars qw( $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA );

use Symbol;
use Time::Local;
use Exporter;

use vars qw( $DATE_MANIP );

=pod

=head1 NAME

Fwctl::Report - Generates reports from fwctllog output.

=head1 SYNOPSIS

    use Fwctl::Report;

    my $report = new Fwctl::Report( options ... );

    my $src_alias_sum = $report->src_alias_summary_report;

    foreach my $r ( @$src_alias_sum ) {
	print $r->{host_ip}, " = ", $r->{count}, "\n";
    }

=head1 DESCRIPTION

The Fwctl::Report(3) module can be used to generate various reports from
the output of the B<fwctllog> program.

This module generates two kinds of report C<summary> and <report>. The
summary compiles the number of occurence for an item (source,
destination, service, etc.). The report methods will returns all the
log entry that shares the same key ( source, destination, service,
etc.)

=cut

BEGIN {
    ($VERSION) = '$Revision: 1.8 $' =~ /(Revision: ([\d.]+))/;
    @ISA = qw( Exporter );

    @EXPORT = ();

    @EXPORT_OK = ();

    %EXPORT_TAGS = ( fields => [ qw(  TIME ACTION DEVICE IF CHAIN
				      PROTO PROTO_NAME
				      SRC_IP SRC_HOST SRC_IF
				      SRC_ALIAS SRC_PORT SRC_SERV
				      DST_IP DST_HOST DST_IF
				      DST_ALIAS DST_PORT DST_SERV
				    )
				],
		    );
}



BEGIN {
    $DATE_MANIP = 0;
    eval "use Date::Manip;";
    $DATE_MANIP = 1 unless $@;
}

BEGIN {
    # Create the necessary constant
    my $i = 0;
    for my $f ( @{$EXPORT_TAGS{fields}} ) {
	eval "use constant $f => $i;";
	$i++;
    }

    Exporter::export_ok_tags( 'fields' );
};

use constant SERVICE_ALIAS_KEY =>
  sub { if ( $_[0][PROTO] == 6 || $_[0][PROTO] == 17)
	{
	    return $_[0][DST_ALIAS] . "/" . $_[0][PROTO] . "/" .
	           $_[0][DST_PORT];
	} else {
	    return $_[0][DST_ALIAS] . "/" . $_[0][PROTO] . "/" .
		   $_[0][SRC_PORT] . "/" . $_[0][DST_PORT];
	}
    };

use constant SERVICE_HOST_KEY	    =>
sub { if ( $_[0][PROTO] == 6 || $_[0][PROTO] == 17 )
      {
	  return $_[0][DST_IP] . "/" . $_[0][PROTO] . "/" . $_[0][DST_PORT];
      } else {
	  return $_[0][DST_IP] .   "/" . $_[0][PROTO] . "/" .
	         $_[0][SRC_PORT] . "/" . $_[0][DST_PORT];
      }
  };

use constant SERVICE_KEY	    =>
  sub { if ( $_[0][PROTO] == 6 || $_[0][PROTO] == 17) {
	     return $_[0][PROTO] . "/" . $_[0][DST_PORT];
	} else {
	     return $_[0][PROTO] . "/" . $_[0][SRC_PORT]."/" . $_[0][DST_PORT];
	}
    };


use constant DST_HOST_KEY   => sub { $_[0][DST_IP] };

use constant DST_ALIAS_KEY  => sub { $_[0][DST_ALIAS] };

use constant SRC_HOST_KEY   => sub { $_[0][SRC_IP] };

use constant SRC_ALIAS_KEY  => sub { $_[0][SRC_ALIAS] };

use constant SRC_HOST_SUMMARY_RECORD =>
  sub { { host_ip    => $_[0][SRC_IP],
	  host_name  => $_[0][SRC_HOST],
	  host_alias => $_[0][SRC_ALIAS],
         };
    };

use constant SRC_ALIAS_SUMMARY_RECORD =>
  sub { {
	  host_alias => $_[0][SRC_ALIAS],
         };
    };

use constant DST_ALIAS_SUMMARY_RECORD =>
  sub { { 
	  host_alias => $_[0][DST_ALIAS], 
       };
    };

use constant DST_HOST_SUMMARY_RECORD =>
  sub { { host_ip    => $_[0][DST_IP],
	  host_name  => $_[0][DST_HOST],
	  host_alias => $_[0][DST_ALIAS],
         };
    };

use constant SERVICE_SUMMARY_RECORD =>
  sub {
      my $result = { proto      => $_[0][PROTO],
		     proto_name => $_[0][PROTO_NAME],
		     dst_port   => $_[0][DST_PORT],
		     dst_serv   => $_[0][DST_SERV],
		   };
      if ( $_[0][PROTO] != 6 && $_[0][PROTO] != 17 ) {
	  $result->{src_port} = $_[0][SRC_PORT];
	  $result->{src_serv} = $_[0][SRC_SERV];
      }
      $result;
  };

use constant SERVICE_ALIAS_SUMMARY_RECORD =>
  sub {
      my $result = { host_alias => $_[0][DST_ALIAS],
		     proto      => $_[0][PROTO],
		     proto_name => $_[0][PROTO_NAME],
		     dst_port   => $_[0][DST_PORT],
		     dst_serv   => $_[0][DST_SERV],
		   };
      if ( $_[0][PROTO] != 6 && $_[0][PROTO] != 17 ) {
	  $result->{src_port} = $_[0][SRC_PORT];
	  $result->{src_serv} = $_[0][SRC_SERV];
      }
      $result;
  };

use constant SERVICE_HOST_SUMMARY_RECORD =>
  sub {
      my $result = { host_ip    => $_[0][DST_IP],
		     host_name  => $_[0][DST_HOST],
		     host_alias => $_[0][DST_ALIAS],
		     proto	=> $_[0][PROTO],
		     proto_name => $_[0][PROTO_NAME],
		     dst_port   => $_[0][DST_PORT],
		     dst_serv   => $_[0][DST_SERV],
		   };
      if ( $_[0][PROTO] != 6 && $_[0][PROTO] != 17 ) {
	  $result->{src_port} = $_[0][SRC_PORT];
	  $result->{src_serv} = $_[0][SRC_SERV];
      }
      $result;
  };

sub summary_iterator {
    my ($records, $get_key_sub, $create_record_sub ) = @_;

    my %cache = ();
    foreach my $r ( @$records ) {
	my $key = $get_key_sub->( $r );
	if ( ! exists $cache{$key} ) {
	    $cache{$key} = $create_record_sub->( $r );
	    $cache{$key}{count} = 0;
	    $cache{$key}{first} = $r->[TIME];
	}
	$cache{$key}{count}++;
	$cache{$key}{last} = $r->[TIME];
    }

    return [ sort { $b->{count} <=> $a->{count} } values %cache ];
}

sub report_iterator {
    my ( $records,  $key_sub ) = @_;

    my %cache = ();
    foreach my $r ( @$records ) {
	my $key = $key_sub->( $r );

	unless ( exists $cache{$key}) {
	    $cache{$key} = [ $key, [] ];
	}
	push @{$cache{$key}[1]}, $r;
    }
    return [ map { $_->[1] } sort { $a->[0] cmp $b->[0] } values %cache ];
}

# Removes packets that are in the same time window.
sub is_duplicate {
    my ( $self, $r ) = @_;

    my $cutoff = $self->{threshold};
    return 0 unless $cutoff > 0;
    my $window = $r->[TIME] - $cutoff;
    my $seen = 0;
    for ( my $i = $#{$self->{records}};
	  $i >= 0 && $self->{records}[$i][TIME] > $window;
	  $i--
	)
    {
	my $nr = $self->{records}[$i];
	next unless $r->[PROTO]  == $nr->[PROTO];
	next unless $r->[SRC_IP] eq $nr->[SRC_IP];
	next unless $r->[DST_IP] eq $nr->[DST_IP];
	if ( $r->[PROTO] == 6 ||
	     $r->[PROTO] == 17
	   )
	  {
	      # For TCP/UDP we only need to check the dst port
	      next unless $r->[DST_PORT] == $nr->[DST_PORT];
	  } else {
	      next unless $r->[SRC_PORT] == $nr->[SRC_PORT];
	      next unless $r->[DST_PORT] == $nr->[DST_PORT];
	  }

	# This is part of the same try
	return 1;
    }

    return 0;
}

sub parse_date {
    my $str = shift;

    if ( $DATE_MANIP) {
	my $date = ParseDate( $str ) or return undef;
	return UnixDate( $date, '%s' );
    } else {
	my ( $yearpart, $year, $month, $day, $time, $hour, $min, $sec) =
	  $str =~ /((\d\d\d?\d?|\d\d)?-?(\d\d?)-(\d\d?) ?)?((\d\d?):(\d\d?):?(\d\d?)?)?/;
	return undef unless $yearpart ||  $time;

	if ( $yearpart ) {
	    if (defined $year) {
		$year = $year > 1900 ? $year - 1900 :
				       $year < 70 ? $year + 100 : $year;
	    } else {
		$year = (localtime)[5];
	    }
	    $month = $month == 12 ? 0 : $month - 1;
	} else {
	    ($year,$month,$day ) = (localtime)[5,4,3];
	}
	unless ($time) {
	    # Midnight
	    ($hour,$min,$sec) = (0,0,0);
	}
	$sec ||= 0;
	return timelocal $sec, $min, $hour, $day, $month, $year;
    }
}

sub parse_period {
    my $str = shift;
    if ( $DATE_MANIP ) {
	my $period = ParseDateDelta( $str ) or return undef;
	return Delta_Format( $period, 0, '%st' );
    } else {
	my ( $weeks, $days, $hours, $mins, $secs ) =
	  $str =~ /(?:(\d+) ?w[eks ]*)?(?:(\d+) ?d[ays ]*)?(?:(\d+) ?h[hours ]*)?(?:(\d+) ?m[inutes ]*)?(?:(\d+) ?s[econds ]*)?/i;

	my $time = 0;

	$time += $weeks * 7  * 24 * 60 * 60 if $weeks;
	$time += $days  * 24 * 60 * 60	    if $days;
	$time += $hours * 60 * 60	    if $hours;
	$time += $mins  * 60		    if $mins;
	$time += $secs			    if $secs;

	return $time || undef;
    }
}

my $needs_and = 0;
sub parse_term {
    my ($valid_fields, $sub, $constraints ) = @_;

    # Parse assertion
    my $term = shift @$constraints;
    die "missing term\n" unless $term;

    if ( $term eq '(' ) {
	$sub .= " && " if $needs_and;
	$sub .= ' ( ';
	$needs_and = 0;
	$sub = parse_term( $valid_fields, $sub, $constraints );
	$term = shift @$constraints;
	die "missing )\n" unless $term eq ')';
	$needs_and = 1;
    } elsif ( $term eq 'not' ) {
	$sub .= " && " if $needs_and;
	$sub .= ' ! (';
	$needs_and = 0;
	$sub = parse_term( $valid_fields, $sub, $constraints );
	$sub .= ' )';
	$needs_and = 1;
    } elsif ( $term eq 'and' ) {
	$sub .= ' && ( ';
	$needs_and = 0;
	$sub = parse_term( $valid_fields, $sub, $constraints );
	$sub .= ' )';
	$needs_and = 1;
    } elsif ( $term eq 'or' ) {
	$sub .= ' || ( ';
	$needs_and = 0;
	$sub = parse_term( $valid_fields, $sub, $constraints );
	$sub .= ' )';
	$needs_and = 1;
    } elsif ( exists $valid_fields->{$term} ) {
	my $field = ' $r->[' . $valid_fields->{$term} . ']';

	$term = shift @$constraints;
	die "incomplete constraint $field\n" unless defined $term;

	$sub .= " && " if $needs_and;
	if ( $term =~ /<|>|!=|=|>=|<=/ ) {
	    my $op = $term;
	    $op = "eq" if $op eq '=';
	    $term = shift @$constraints;
	    die "incomplete constraint $field $op\n" unless defined $term;

	    # Quote term if necessary
	    $term = 'q{' . $term . '}' unless $term =~ /^\d+$/;
	    $sub .= " $field $op $term ";
	} elsif ( $term =~ m!^/.+/i?! )
	{
	    # Regular expression
	    $sub  .= " $field =~ $term ";
	} else {
	    # Comparison

	    # Quote term if necessary
	    $term = 'q{' . $term . '}' unless $term =~ /^\d+$/;

	    $sub  .= " $field eq $term ";
	}
	$needs_and = 1;
    } else {
	die "unknown field ($term)\n";
    }

    return $sub;
}

my $true    = sub { 1 };

sub build_constraints {
    my $valid_fields = shift;
    my @constraints = split /\s+/, join " ", @_;

    return $true unless @constraints;

    my $sub = 'sub { my $r = shift; return ';

    $needs_and = 0;
    while ( @constraints ) {
	$sub = parse_term( $valid_fields, $sub, \@constraints );
    }
    $sub .= ' }';

    # Compile into code ref
    $sub = eval $sub;
    die "error compiling constraints : $@\n" if $@;

    return $sub;
}

## Assumes that the records are already sorted by time.
sub read_records {
    my $self = shift;

    # Read in the data
    push @{$self->{opts}{files}}, \*STDIN unless @{$self->{opts}{files}};
  FILE:
    foreach my $file ( @{$self->{opts}{files}} ) {
	my $fh;
	if ( ref $file ) {
	    $fh = $file;
	} elsif ( $file eq "-" ) {
	    $fh = \*STDIN;
	} else {
	    $fh = gensym;
	    open $fh, $file
	      or do { warn "can't open file $file\n"; next FILE };
	}

	my $i = 0;
	while (<$fh>) {
	    chomp;
	    my @fields = split /\|/, $_;
	    if ( ! defined $self->{start}) {
		$self->{start} = $fields[TIME];
		$self->{end} = $self->{start} + $self->{period}
		  if defined $self->{period};
	    }
	    # Skip fields before the period
	    next unless $self->{start} <= $fields[TIME];

	    # Quit loop if we reach the end of the period.
	    last FILE if $self->{end} < $fields[TIME];

	    next unless $self->{constraints}->( \@fields );

	    next if $self->is_duplicate( \@fields );

	    push @{$self->{records}}, \@fields;
	}
    }
}


=pod

=head1 CREATING A NEW REPORT OBJECT

    Ex. my $report = new Fwctl::Report( start  => 'yesterday',
					period => '1 day',
					files  => [ 'log' ] );

=head2 PARAMETERS

The C<new> method accepts the following parameter :

=over

=item files

Specifies the file from which to read the F<fwctllog> output. It is an
array of file handle or file names. If this parameter is not specified
the records will be read from STDIN.

=item start

Sets the start of the report's period. If the Date::Manip(3) module is
installed, you can use any format that this module can parse. If that module
is'nt installed you must use the following format YYYY-MM-DD HH:MM:SS or any
meaningful subset of that format.

If this option is not used, the report will start with the first record.

=item end

Sets the end of the report's period. If the Date::Manip(3) module is
installed, you can use any format that this module can parse. If that module
is'nt installed you must use the following format YYYY-MM-DD HH:MM:SS or any
meaningful subset of that format.

If this option is not used, the report will end with the last record.

=item period

Sets the length of the report's period. This length is interpreted relative
to the report's start. This option has priority over the B<end> option.

If you have the Date::Manip module installed, you can use any format that this
module can parse. If that module isn't available, you can use a subset of the
following format X weeks X days X hours X mins X secs.

=item threshold

This option will removed records identical in protocol, destination
ports, source addresses and destination addressesses that appears in
the time window specified by the threshold parameters. Defaults is 120
(2 minutes). Use 0 to generates reports for all the packets.

=item limit

This parameter can be used to restrict the records over which the
report is generated. It is an expression which will be used to select
a subset of all the records. You can use the following fields :
src_ip, dst_ip, src_host, dst_host, action, device, src_port,
dst_port, src_serv, dst_serv, proto, proto_name, and the following
operator =, !=, <, >, <=, >=, /regex/, /regex/i. Those operators have
the same meaning as in perl. You can also use parentheses and the
following logic operator : or, and, not .

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = { opts	    => { @_ },
		 records    => undef,
		 start	    => undef,
		 end	    => undef,
		 period	    => undef,
		 threshold  => undef,
	       };

    # Determine start and end of the report;
    if ( $self->{opts}{start} ) {
	$self->{start} = Fwctl::Report::parse_date( $self->{opts}{start} ) 
	  or die "invalid start date format: $self->{opts}{start}\n";
    }

    if ( $self->{opts}{period} ) {
	$self->{period} = Fwctl::Report::parse_period( $self->{opts}{period}) 
	  or die "fwctlreport: invalid period delta: $self->{opts}{period}\n";
	if (  $self->{start} ) {
	    $self->{end} = $self->{start} + $self->{period};
	}
    } elsif ( $self->{opts}{end} ) {
	$self->{end} = Fwctl::Report::parse_date( $self->{opts}{end} ) 
	  or die "fwctlreport: invalid end date format: $self->{opts}{end}\n";
    } else {
	$self->{end} = time;
    }

    if ( $self->{opts}{threshold} ) {
	$self->{threshold} = Fwctl::Report::parse_period( $self->{opts}{threshold} )
	  or die "fwctlreport: invalid threshold: $self->{opts}{threshold}\n";
    } else {
	$self->{threshold} = 120; # 2 minutes
    }

    $self->{constraints} = build_constraints( {
					       action	  => ACTION,
					       device	  => DEVICE,
					       proto	  => PROTO,
					       proto_name => PROTO_NAME,
					       src_ip	  => SRC_IP,
					       src_host	  => SRC_HOST,
					       src_if	  => SRC_IF,
					       src_alias  => SRC_ALIAS,
					       src_port   => SRC_PORT,
					       src_serv   => SRC_SERV,
					       dst_ip	  => DST_IP,
					       dst_host	  => DST_HOST,
					       dst_if	  => DST_IF,
					       dst_alias  => DST_ALIAS,
					       dst_port	  => DST_PORT,
					      }, $self->{opts}{limit} );
    bless $self, $class;

    $self->read_records;

    $self;
}

=pod

=head1 METHODS

=head1 start()

Return the start of the report in seconds since epoch.

=cut

sub start {
    $_[0]->{start};
}

=pod

=head1 end()

Returns the end of the report in seconds since epoch.

=cut

sub end {
    $_[0]->{end};
}

=pod

=head1 period()

Returns the length of the report's period ( $report->end() - $report->start() )

=cut

sub period {
    $_[0]->{end} - $_[0]->{period};
}

=pod

=head1 records()

Returns an array reference to all the records read and which makes the
report's sample.

=head2 RECORD FIELDS

Each record is an array ref. You can accessed the individual fields of
the record by using the following constants. (Those can be imported by
using the C<:fields> import tag.)

=over

=item TIME

The epoch time of the log entry.

=item ACTION

The resulting action (ACCEPT,DENY,REJECT).

=item DEVICE

The physical device on which the packet was logged.

=item IF

The Fwctl(3) interface to which this device is related.

=item CHAIN

The kernel chain on which that packet was logged.

=item PROTO

The protocol number.

=item PROTO_NAME

The name of the protocol.

=item SRC_IP

The source address of the packet.

=item SRC_HOST

The source hostname.

=item SRC_IF

The Fwct(3) interface related to the source address.

=item SRC_ALIAS

The Fwctl(3) alias associated to the source address.

=item SRC_PORT

The source port of the logged packet.

=item SRC_SERV

The service name associated to the logged packet.

=item DST_IP

The destination IP of the packet.

=item DST_HOST

The destination hostname.

=item DST_IF

The Fwctl(3) interface associated with the destination address.

=item DST_ALIAS

The Fwctl(3) alias related to the destination address.

=item DST_PORT

The destination port number.

=item DST_SERV

The service name of the the destination port.

=back

=cut

sub records {
    # Copy the records
    [ @{$_[0]->{records}} ];
}

=pod

=head1 REPORTS

The following report generation methods are available :

=head2 service_summary_report()

    my $r = $report->service_summary_report();


Generates a report that shows the number of log entries for each
services. 

The resulting report is an array ref of hash reference. Each report
record's has the following fields.

=over

=item proto 

The protocol number.

=item proto_name

The protocol name.

=item dst_port

The destination port.

=item dst_serv

The destination service's name.

=item src_port

If the protocol B<is not> UDP or TCP, the source port.

=item src_serv

If the protocol B<is not> UDP or TCP, the service name associated to the 
source port.

=item count

The number of log entries matching the service.

=item first

The epoch time of the first occurence.

=item last

The epoch time of the last occurence.

=back

=cut

sub service_summary_report {
    return summary_iterator( $_[0]->{records}, SERVICE_KEY,
			     SERVICE_SUMMARY_RECORD );
}

=pod

=head2 service_report()

    my $r = $report->service_report();

Generates a report that sort the log entries by service.

The report is an array of arrays. Each elements of the report is an
array of records which shares the same service.

=cut

sub service_report {
    return report_iterator( $_[0]->{records}, SERVICE_KEY );
}

=pod

=head2 service_alias_summary_report()

    my $r = $report->service_alias_summary_report();


Generates a report that shows the number of log entries for each
destination aliases / service.

The resulting report is an array ref of hash reference. Each report
record's has the following fields.

=over

=item proto

The protocol number.

=item proto_name

The protocol name.

=item host_alias

The alias of the destination hosts.

=item dst_port

The destination port.

=item dst_serv

The destination's service name.

=item src_port

If the protocol B<is not> UDP or TCP, the source port.

=item src_serv

If the protocol B<is not> UDP or TCP, the service name associated to the 
source port.

=item count

The number of log entries.

=item first

The epoch time of the first occurence.

=item last

The epoch time of the last occurence.

=back

=cut

sub service_alias_summary_report {
    return summary_iterator( $_[0]->{records}, SERVICE_ALIAS_KEY,
			     SERVICE_ALIAS_SUMMARY_RECORD );
}

=head2 service_alias_report()

    my $r = $report->service_alias_report();

Generates a report that sort the log entries by destination alias and
service.

The report is an array of arrays. Each elements of the report is an
array of records which shares the same destination alias and service.

=cut

sub service_alias_report {
    return report_iterator( $_[0]->{records}, SERVICE_ALIAS_KEY );
}

=pod

=head2 service_host_summary_report()

    my $r = $report->service_host_summary_report();


Generates a report that shows the number of log entries for each
destination aliases / service.

The resulting report is an array ref of hash reference. Each report
record's has the following fields.

=over

=item proto

The protocol number.

=item proto_name

The protocol name.

=item host_ip

The destination host ip address.

=item host_name

The destination host name.

=item host_alias

The alias of that host.

=item dst_port

The destination port.

=item dst_serv

The destination service's name.

=item src_port

If the protocol B<is not> UDP or TCP, the source port.

=item src_serv

If the protocol B<is not> UDP or TCP, the service name associated to the 
source port.

=item count

The number of log entries.

=item first

The epoch time of the first occurence.

=item last

The epoch time of the last occurence.

=back

=cut

sub service_host_summary_report {
    return summary_iterator( $_[0]->{records}, SERVICE_HOST_KEY,
			     SERVICE_HOST_SUMMARY_RECORD );

}

=head2 service_host_report()

    my $r = $report->service_host_report();

Generates a report that sort the log entries by destination host and
service.

The report is an array of arrays. Each elements of the report is an
array of records which shares the same destination host and service.

=cut

sub service_host_report {
    return report_iterator( $_[0]->{records}, SERVICE_HOST_KEY );
}

=pod

=head2 src_alias_summary_report()

    my $r = $report->service_alias_summary_report();


Generates a report that shows the number of log entries for each
source aliases.

The resulting report is an array ref of hash reference. Each report
record's has the following fields.

=over

=item host_alias

The source alias.

=item count

The number of log entries.

=item first

The epoch time of the first occurence.

=item last

The epoch time of the last occurence.

=back

=cut

sub src_alias_summary_report {
    return summary_iterator( $_[0]->{records}, SRC_ALIAS_KEY, 
			     SRC_ALIAS_SUMMARY_RECORD );
}

=head2 src_alias_report()

    my $r = $report->src_alias_report();

Generates a report that sort the log entries by source alias.

The report is an array of arrays. Each elements of the report is an
array of records which shares the same source alias.

=cut

sub src_alias_report {
    return report_iterator( $_[0]->{records}, SRC_ALIAS_KEY );
}

=pod

=head2 src_host_summary_report()

    my $r = $report->src_host_summary_report();


Generates a report that shows the number of log entries for each
source host.

The resulting report is an array ref of hash reference. Each report
record's has the following fields.

=over

=item host_ip

The source host ip address.

=item host_name

The source host name.

=item host_alias

The alias of the source host.

=item count

The number of log entries.

=item first

The epoch time of the first occurence.

=item last

The epoch time of the last occurence.

=back

=cut

sub src_host_summary_report {
    return summary_iterator( $_[0]->{records}, SRC_HOST_KEY, 
			     SRC_HOST_SUMMARY_RECORD );

}

=head2 src_host_report()

    my $r = $report->src_host_report();

Generates a report that sort the log entries by source host.

The report is an array of arrays. Each elements of the report is an
array of records which shares the same source host.

=cut

sub src_host_report {
    return report_iterator( $_[0]->{records}, SRC_HOST_KEY );
}

=pod

=head2 dst_alias_summary_report()

    my $r = $report->dst_alias_summary_report();


Generates a report that shows the number of log entries for each
destination aliases.

The resulting report is an array ref of hash reference. Each report
record's has the following fields.

=over

=item host_alias

The destination alias.

=item count

The number of log entries.

=item first

The epoch time of the first occurence.

=item last

The epoch time of the last occurence.

=back

=cut

sub dst_alias_summary_report {
    return summary_iterator( $_[0]->{records}, DST_ALIAS_KEY, 
			     DST_ALIAS_SUMMARY_RECORD );
}

=head2 dst_alias_report()

    my $r = $report->dst_alias_report();

Generates a report that sort the log entries by destination alias.

The report is an array of arrays. Each elements of the report is an
array of records which shares the same destination alias.

=cut

sub dst_alias_report {
    return report_iterator( $_[0]->{records}, DST_ALIAS_KEY );
}

=pod

=head2 src_host_summary_report()

    my $r = $report->src_host_summary_report();


Generates a report that shows the number of log entries for each
destination hosts.

The resulting report is an array ref of hash reference. Each report
record's has the following fields.

=over

=item host_ip

The destination host ip address.

=item host_name

The destination host name.

=item host_alias

The alias of the destination hosts.

=item count

The number of log entries.

=item first

The epoch time of the first occurence.

=item last

The epoch time of the last occurence.

=back

=cut

sub dst_host_summary_report {
    return summary_iterator( $_[0]->{records}, DST_HOST_KEY, 
			     DST_HOST_SUMMARY_RECORD );

}

=head2 dst_host_report()

    my $r = $report->dst_host_report();

Generates a report that sort the log entries by destination host.

The report is an array of arrays. Each elements of the report is an
array of records which shares the same destination host.

=cut

sub dst_host_report {
    return report_iterator( $_[0]->{records}, DST_HOST_KEY );
}

1;

__END__

=pod

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@iNsu.COM>

=head1 COPYRIGHT

Copyright (c) 2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Fwctl(3) Fwctl::RuleSet(3) fwctl(8) fwctllog(8) Fwctl::Report(3)
Date::Manip(3).

=cut

