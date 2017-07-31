package HBase::JSONRest::Scanner;

use strict;
use warnings;

use URI::Escape;
use Time::HiRes qw(time);
use Data::Dumper;

# new
sub new {
    my $class  = shift;
    my $params = shift;

    die "HBase handle required!"
        unless ($params->{hbase} and (ref $params->{hbase}));

    my $hbase = $params->{hbase};

    my $limit = $params->{atatime} || 1;

    my $self = {
        hbase    => $hbase,

        table    => $params->{table},

        startrow => $params->{startrow},

        endrow   => $params->{endrow},

        starttime => $params->{starttime}, # server's default is 0

        endtime  => $params->{endtime}, # server's default is Long.MAX_VALUE

        maxversions => $params->{maxversions}, # server's default is 1

        prefix   => $params->{prefix},

        limit    => $limit,

        last_key_from_previous_batch => undef,

        batch_no => 0,

        EOF        => 0,
    };

    return bless $self, $class;
}

# get_next_batch
sub get_next_batch {

    my $self = shift;

    $self->{_last_batch_time_start} = time;

    my $table  = $self->{table};
    my $prefix = $self->{prefix};
    my $limit  = $self->{limit};
    my $hbase  = $self->{hbase};

    my $last_key_from_previous_batch;

    # Three ways of scanning are supported:
    #
    #   I.   Provide a prefix and scan all rows with that prefix
    #   II.  Provide startrow and endrow. Scan is inclusive for
    #        startrow and exclusive for endrow.
    #   III. Provide just startrow - scan entire table, batch by batch.
    #
    # All of these are converted to startrow and end_condition under
    # the hood. Difference is only in user API.

    # First Batch
    if ($self->{batch_no} == 0) {

        # Case I:
        if ((defined $prefix) && !$self->{startrow} && !$self->{endrow}) {

            my $first_row = $self->_get_first_row_of_prefix();

            # no rows for specified prefix
            return undef if (!$first_row && !$first_row->{row});

            $self->{startrow} = $first_row->{row};
            $self->{end_condition_type} = 'PREFIX';
        }
        # Case II:
        # case no prefix, startrow exists, endrow exists
        elsif ((!defined $prefix) && $self->{startrow} && $self->{endrow}){
            # $self->{startrow} allready assigned
            $self->{end_condition_type} = 'ENDROW';
        }
        # Case III:
        # only firs_key specified, scan untill the end of the table
        elsif ((!defined $prefix) && $self->{startrow} && !$self->{endrow}){
            # $self->{startrow} allready assigned
            $self->{end_condition_type} = 'NONE';
        }
        # Forbiden cases:
        #   case prefix and startrow/endrow
        elsif ((defined $prefix) && ($self->{startrow} || $self->{endrow})){
            die "Can not use prefix and startrow/endrow at the same time!";
        }
        #   case no params
        elsif ((!defined $prefix) && !$self->{startrow}) {
            die "Must specify either prefix or startrow!";
        }
        else {
            die "Unknown query case!";
        }

        # SCAN FOR FIRST BATCH
        my $rows = $self->_scan_raw({
            table      => $self->{table},
            startrow   => $self->{startrow}, # <- inclusive
            starttime  => $self->{starttime},
            endtime    => $self->{endtime},
            maxversions=> $self->{maxversions},
            limit      => $limit,
        });
        $self->{last_batch_time} = time - $self->{_last_batch_time_start};
        $self->{batch_no}++;

        if (!$hbase->{last_error}) {

            if ($rows && @$rows) {

                $self->_filter_rows_beyond_last_key($rows);

                # return what is left, if something is left after filter
                if ($rows && @$rows) {
                    $self->{last_key_from_previous_batch} = $rows->[-1]->{row};
                    return $rows;
                }
                else {
                    $self->{last_key_from_previous_batch} = undef;
                    $self->{EOF} = 1;
                    return [];
                }
            }
            else {
                $self->{last_key_from_previous_batch} = undef;
                $self->{EOF} = 1;
                return [];
            }
        }
        else {
            die "Error while trying to get the first key of a prefix!" . Dumper($hbase->{last_error});
        }
    }
    # Next Batch
    else {
        # no more records, last batch was empty or it was the last batch
        if (!$self->{last_key_from_previous_batch} || $self->{EOF}) {
            return undef;
        }

        $last_key_from_previous_batch = $self->{last_key_from_previous_batch};
        $self->{last_key_from_previous_batch} = undef;

        # Use last row from previous batch as start row for the next scan, but
        # make an exclude-start-row scan type.

        my $next_batch = $self->_scan_raw({
            table     => $table,
            startrow  => $last_key_from_previous_batch,
            exclude_startrow_from_result => 1,
            starttime  => $self->{starttime},
            endtime    => $self->{endtime},
            maxversions=> $self->{maxversions},
            limit     => $limit,
        });

        $self->{last_batch_time} = time - $self->{_last_batch_time_start};
        $self->{batch_no}++;

        if (!$hbase->{last_error}) {

            if ($next_batch && @$next_batch) {

                $self->_filter_rows_beyond_last_key($next_batch);

                # return what is left, if something is left after filter
                if ($next_batch && @$next_batch) {
                    $self->{last_key_from_previous_batch} = $next_batch->[-1]->{row};
                    return $next_batch;
                }
                else {
                    $self->{last_key_from_previous_batch} = undef;
                    $self->{EOF} = 1;
                    return [];
                }
            }
            else {
                $self->{last_key_from_previous_batch} = undef;
                $self->{EOF} = 1;
                return [];
            }
        }
        else {
            die "Scanner error while trying to get next batch!"
                . Dumper($hbase->{last_error});
        }
    }
}

# _get_first_row_of_prefix
sub _get_first_row_of_prefix {
    my $self = shift;

    my $prefix = $self->{prefix};
    my $hbase  = $self->{hbase};
    my $table  = $self->{table};

    # use prefix as the first row with limit 1 - returns the first row with given prefix
    my $rows = $self->_scan_raw({
        table     => $table,
        startrow  => $prefix,
        limit     => 1,
    });

    die "Should be only one first row!"
        if ( scalar @$rows > 1);

    return undef unless $rows->[0];

    my $first_row = $rows->[0];

    return $first_row;
}

# _scan_raw (uses passed paremeters instead of instance parameters)
sub _scan_raw {
    my $self   = shift;
    my $params = shift;

    my $hbase = $self->{hbase};
    $hbase->{last_error} = undef;

    my $scan_uri = _build_scan_uri($params);

    my $rows = $hbase->_get_tiny($scan_uri);

    return $rows;
}

sub _build_scan_uri {
    my $params = shift;

    #
    #    request parameters:
    #
    #    1. startrow - The start row for the scan.
    #    2. endrow   - The end row for the scan.
    #    4. starttime, endtime - To only retrieve columns within a specific range of version timestamps, both start and end time must be specified.
    #    5. maxversions - To limit the number of versions of each column to be returned.
    #    6. limit       - The number of rows to return in the scan operation.

    my $table       = $params->{table};
    my $limit       = $params->{limit}       || 1;

    # optional
    my $startrow    = $params->{startrow}    || "";
    my $endrow      = $params->{endrow}      || "";
    my $starttime   = $params->{starttime}; # server's default is 0
    my $endtime     = $params->{endtime}; # server's default is Long.MAX_VALUE
    my $maxversions = $params->{maxversions}; # server's default is 1

    # not supported yet:
    my $columns     = $params->{columns}     || "";

    # option to do scans with exclusion of first row. Usefull when
    # scanning for the next batch based on the last key from previous
    # batch. By default this option is false.
    my $exclude_startrow = $params->{exclude_startrow_from_result} || 0;

    my $uri;

    if ($exclude_startrow) {
        $startrow = uri_escape($startrow) . uri_escape(chr(0));
    }
    else {
        $startrow = uri_escape($startrow);
    }
    $uri
        = "/"
        . uri_escape($table)
        . "/"
        . '*?'
        . "startrow="   . $startrow
        . "&limit="     . $limit
    ;

    $uri .= "&starttime=" . $starttime if defined $starttime;
    $uri .= "&endtime=" . $endtime if defined $endtime;
    $uri .= "&maxversions=" . $maxversions if defined $maxversions;

    return $uri;
}

sub _filter_rows_beyond_last_key {
    my $self = shift;
    my $rows = shift;

    my $last_retrieved_row = $rows->[-1]->{row};

    if ($self->{end_condition_type} eq 'PREFIX') {
        my $prefix_end = $self->{prefix} . chr(255);
        if ($last_retrieved_row gt $prefix_end) {
            # need to filter out surpluss of rows
            @$rows = grep { $_->{row} le $prefix_end } @$rows;
            # also mark EOF
            $self->{EOF} = 1;
            if ($rows && @$rows) {
                my $last_retrieved_valid_row = $rows->[-1]->{row};
                $self->{last_key_from_previous_batch} = $last_retrieved_valid_row;
            }
            return;
        }
    }
    elsif ($self->{end_condition_type} eq 'ENDROW') {
        if ($last_retrieved_row ge $self->{endrow}) {
            # need to filter out surpluss of rows
            @$rows = grep { $_->{row} lt $self->{endrow} } @$rows;
            # also mark EOF
            $self->{EOF} = 1;
            if ($rows && @$rows) {
                my $last_retrieved_valid_row = $rows->[-1]->{row};
                $self->{last_key_from_previous_batch} = $last_retrieved_valid_row;
            }
            return;
        }
    }
    elsif ($self->{end_condition_type} eq 'NONE') {
        return;
    }
    else {
        die 'Unknown end_condition_type!';
    }
}

1;

__END__

=encoding utf8

=head1 NAME

HBase::JSONRest::Scanner - Simple client for HBase stateless REST scanners

=head1 SYNOPSIS

A simple scanner:

    use HBase::JSONRest;

    my $hbase = HBase::JSONRest->new(host => 'my-rest-host');

    my $table       = 'name of table to scan';
    my $prefix      = 'key prefix to scan';
    my $batch_size  = 100; # rows per one batch

    my $scanner = HBase::JSONRest::Scanner->new({
        hbase   => $hbase,
        table   => $table,
        prefix  => $prefix,
        atatime => $batch_size,
    });

    my $rows;
    while ($rows = $scanner->get_next_batch()) {
        print STDERR "got "
            . @$rows . " rows in "
            . sprintf("%.3f", $scanner->{last_batch_time}) . " seconds\n\n";
        print STDERR "first key in batch ==> " . $rows->[0]->{row} . "\n";
        print STDERR "last key in batch  ==> " . $rows->[-1]->{row} . "\n";
    }

=head1 DESCRIPTION

Simple client for HBase stateless REST scanners.

=head1 METHODS

=head2 new

Constructor. Cretes an HBase stateless REST scanner object.

    my $scanner = HBase::JSONRest::Scanner->new({
        hbase   => $hbase,
        table   => $table,
        prefix  => $prefix,
        atatime => $batch_size,
    });

=head2 get_next_batch

Gets the next batch of records

    while ($rows = $scanner->get_next_batch()) {
        ...
    }

=cut

