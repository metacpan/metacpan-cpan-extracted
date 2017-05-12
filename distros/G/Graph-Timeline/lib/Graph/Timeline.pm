package Graph::Timeline;

use strict;
use warnings;

use Date::Calc;

our $VERSION = '1.5';

sub new {
    my ($class) = @_;

    die "Timeline->new() takes no arguments" if scalar(@_) != 1;

    my $self = {};

    $self->{_pool} = ();

    return bless $self, $class;
}

sub add_interval {
    die "Timeline->add_interval() expected HASH as parameter" unless scalar(@_) % 2 == 1;

    my ( $self, %data ) = @_;

    %data = $self->_lowercase_keys(%data);
    $self->_required_keys( 'add_interval', \%data, (qw/start end label/) );
    $self->_valid_keys( 'add_interval', \%data, (qw/start end label group id url/) );

    $data{type} = 'interval';

    $self->_add_to_pool(%data);
}

sub add_point {
    die "Timeline->add_point() expected HASH as parameter" unless scalar(@_) % 2 == 1;

    my ( $self, %data ) = @_;

    %data = $self->_lowercase_keys(%data);
    $self->_required_keys( 'add_point', \%data, (qw/start label/) );
    $self->_valid_keys( 'add_point', \%data, (qw/start label group id/) );

    $data{type} = 'point';
    $data{end}  = $data{start};

    $self->_add_to_pool(%data);
}

sub window {
    my ( $self, %data ) = @_;

    # Default values for our parameters

    $self->{_window_start} = undef;
    $self->{_window_end}   = undef;

    $self->{_window_start_in} = undef;
    $self->{_window_end_in}   = undef;

    $self->{_window_span} = undef;

    $self->{_window_callback} = undef;

    %data = $self->_lowercase_keys(%data);
    $self->_valid_keys( 'window', \%data, (qw/start end start_in end_in span callback/) );

    # Additional validation

    if ( $data{span} ) {
        die "Timeline->window() 'span' can only be defined with a 'start' and 'end'" unless $data{start} and $data{end};
    }

    if ( $data{callback} ) {
        die "Timeline->window() 'callback' can only be a CODE reference" unless ref( $data{callback} ) eq 'CODE';
    }

    foreach my $key ( keys %data ) {
        $self->{"_window_$key"} = $data{$key};
    }
}

sub data {
    my ($self) = @_;

    die "Timeline->data() takes no arguments" if scalar(@_) != 1;

    # Set the start and end, this make things easier

    my $start = ( $self->{_window_start} ? $self->{_window_start} : '0000/00/00T00:00:00' );
    my $end   = ( $self->{_window_end}   ? $self->{_window_end}   : '9999/99/99T23:59:59' );

    my @results;

    if ( $self->{_window_start} ) {
        my $x;
        $x->{start}       = $self->{_window_start};
        $x->{start_start} = $self->{_window_start};
        $x->{start_end}   = $self->{_window_start};

        $x->{end}       = $self->{_window_start};
        $x->{end_start} = $self->{_window_start};
        $x->{end_end}   = $self->{_window_start};

        $x->{type} = 'marker';

        push( @results, $x );
    }

    if ( $self->{_window_end} ) {
        my $x;
        $x->{start}       = $self->{_window_end};
        $x->{start_start} = $self->{_window_end};
        $x->{start_end}   = $self->{_window_end};

        $x->{end}       = $self->{_window_end};
        $x->{end_start} = $self->{_window_end};
        $x->{end_end}   = $self->{_window_end};

        $x->{type} = 'marker';

        push( @results, $x );
    }

    foreach my $record ( @{ $self->{_pool} } ) {
        if ( $record->{start} lt $start ) {
            if ( $record->{end} lt $start ) {
                next;
            }
            elsif ( $record->{end} lt $end ) {
                next unless $self->{_window_end_in};
            }
            else {
                next unless $self->{_window_span};
            }
        }
        elsif ( $record->{start} lt $end ) {
            if ( $record->{end} gt $end ) {
                next unless $self->{_window_start_in};
            }
        }
        else {
            next;
        }

        if ( $self->{_window_callback} ) {
            next unless &{ $self->{_window_callback} }($record);
        }

        if ( $record->{start} lt $start ) {
            $record->{start}       = $start;
            $record->{start_start} = $start;
            $record->{start_end}   = $start;
        }

        if ( $record->{end} gt $end ) {
            $record->{end}       = $end;
            $record->{end_start} = $end;
            $record->{end_end}   = $end;
        }

        push( @results, $record );
    }

    return @results;
}

sub _add_to_pool {
    my ( $self, %data ) = @_;

    my @newpool;
    my $todo = 1;

    %data = $self->_set_range( 'start', %data );
    %data = $self->_set_range( 'end',   %data );

    $data{group} = '--unknown--' unless $data{group};

    foreach my $record ( @{ $self->{_pool} } ) {
        if ( $todo and $record->{start} gt $data{start} ) {
            push @newpool, \%data;
            $todo = undef;
        }
        push @newpool, $record;
    }

    push @newpool, \%data if $todo;

    $self->{_pool} = \@newpool;
}

sub _valid_keys {
    my ( $self, $caller, $data, @keys ) = @_;

    my @testkeys = keys %{$data};
    my %validkeys = map { $_ => $_ } @keys;

    foreach my $key (@testkeys) {
        die "Timeline->$caller() invalid key '$key' passed as data" unless $validkeys{$key};
    }

    foreach my $key ( (qw/start end/) ) {
        if ( $data->{$key} ) {
            $data->{$key} = $self->_today() if $data->{$key} eq 'present';
            die "Timeline->$caller() invalid date for '$key'" unless $self->_date_valid( $data->{$key} );
        }
    }

    if ( $data->{start} and $data->{end} ) {
        die "Timeline->$caller() 'start' and 'end' are in the wrong order" if $data->{start} gt $data->{end};
    }
}

sub _date_valid {
    my ( $self, $date ) = @_;

    my ( $date_part, $time_part ) = split( 'T', $date );
    my ( $year,  $month,   $day )     = split( '[\/-]', $date_part );

    ## Check the date first

    $month = '01' unless $month;
    $day   = '01' unless $day;

    return unless $year  =~ m/^\d+$/;
    return unless $month =~ m/^\d+$/;
    return unless $day   =~ m/^\d+$/;

    my $valid;
    eval { $valid = Date::Calc::check_date( $year, $month, $day ); };

    return unless $valid;

    ## Check the optional time part

    if ($time_part) {
		my ( $hours, $minutes, $seconds ) = split( ':',  $time_part );

        return unless 0 <= $hours   and $hours <= 23;
        return unless 0 <= $minutes and $minutes <= 59;
        return unless 0 <= $seconds and $seconds <= 59;
    }

    return 1;
}

sub _required_keys {
    my ( $self, $caller, $data, @keys ) = @_;

    foreach my $key (@keys) {
        die "Timeline->$caller() missing key '$key'" unless $data->{$key};
    }
}

sub _lowercase_keys {
    my ( $self, %data ) = @_;

    my %newdata = map { lc($_) => $data{$_} } keys %data;

    return %newdata;
}

sub _today {
    my ( $year, $month, $day ) = ( localtime() )[ 5, 4, 3 ];

    $year  += 1900;
    $month += 1;

    return sprintf( "%4d/%02d/%02d", $year, $month, $day );
}

sub _set_range {
    my ( $self, $label, %record ) = @_;

    my ( $date_part, $time_part ) = split( 'T', $record{$label} );
    my ( $year,  $month,   $day )     = split( '[\/-]', $date_part );

    if ($day) {
        $record{"${label}_start"} = $date_part;
        $record{"${label}_end"}   = $date_part;
    }
    elsif ($month) {
        $record{"${label}_start"} = "$year/$month/01";
        $record{"${label}_end"} = "$year/$month/" . Date::Calc::Days_in_Month( $year, $month );
    }
    else {
        $record{"${label}_start"} = "$year/01/01";
        $record{"${label}_end"}   = "$year/12/31";
    }

	if($time_part) {
    $record{"${label}_start"} .= "T" . $time_part;
    $record{"${label}_end"}   .= "T" . $time_part;
	}
	else {
    $record{"${label}_start"} .= "T00:00:00";
    $record{"${label}_end"}   .= "T23:59:59";
}

    return %record;
}

1;

=head1 NAME

Graph::Timeline - Render timeline data

=head1 VERSION

This document refers to verion 1.5 of Graph::Timeline, released September 29, 2009

=head1 SYNOPSIS

This class takes a list of events and processes them so that they can be rendered in 
various graphical formats by subclasses of this class.

=head1 DESCRIPTION

=head2 Overview

The purpose of this class is to organise the data that will be used to render a timeline. Events fall into two types.
Intervals, which has a start and an end. For example Albert Einstein was born on 1879/03/14 and died on 1955/04/18, this would be 
stored as an interval. His works were publicly burned by the Nazi's on 1933/05/10 for being 'of un-German spirit', I guess 
being Jewish didn't help either. So this event would be marked as a point.

You feed events into the class using add_interval( ) and add_point( ), then use window( ) to select which events you want to 
render and then call data( ) to get the relevant events. This last bit will be done in the subclass.

=head2 Constructors and initialisation

=over 4

=item new( )

The constructor takes no arguments and just initialises a few basic variables.

=back

=head2 Public methods

=over 4

=item add_interval( HASH )

Inserts an event that has a start and an end point into the list at the corrct position. The
hash contains the following keys, some of which are required.

=over 4

=item start [ REQUIRED ]

The start date for the interval in the for 'YYYY/MM/DD' or the word 'present' which will be converted into todays date.
Dates in the format YYYY will be taken to span YYYY/01/01 until YYYY/12/31 and dates of the format YYYY/MM will span 
YYYY/MM/01 until YYYY/MM/xx where xx is the last day of MM in YYYY.

=item end [ REQUIRED ]

The start end for the interval in the for 'YYYY/MM/DD' or the word 'present' which will be converted into todays date.
Dates in the format YYYY will be taken to span YYYY/01/01 until YYYY/12/31 and dates of the format YYYY/MM will span 
YYYY/MM/01 until YYYY/MM/xx where xx is the last day of MM in YYYY.

=item label [ REQUIRED ]

The text string that will be displayed when the event is rendered

=item id [ OPTIONAL ]

A unique id for the render, Graph::Timeline does not validate this field for uniqueness

=item group [ OPTIONAL ]

A string is used to group related events together, Graph::Timeline does not validate this field

=back

=item add_point( HASH )

The same as add_interval( ) except that the event occurs on just one day and therefore does not require an end date. Interval and point events are rendered differently.

=item window( HASH )

Set up the data to be selected from the event pool. To reset the defaults just call without any parameters.

=over 4

=item start

Select only record that start on or after this date. Takes a valid date or the word 'present' which is 
translated to the current date.

=item end

Select only record that end on or before this date. Takes a valid date or the word 'present' which is 
translated to the current date.

=item start_in

If end is set then include records that start before the end date but ends after the end date.

=item end_in

If start is set then include records that start before the start date but end after the start date.

=item span

If start and end are both set then additionally report events that start before the start date and end
after the end date.

=item callback

A code reference to provide additionaly custom filtering. The callback will be passed a hash reference with the 
following keys: start, end, label, group, id and type ('interval' and 'point').

=back

=item data( )

This returns a list of the events from the pool that got passed the parameters from the window( ) method.

=back

=head2 Private methods

=over 4

=item _add_to_pool

Used to add the event into the pool which is sorted by start date

=item _valid_keys

Validate that the keys supplied in the hash are valid

=item _date_valid

Validate a date

=item _required_keys

Check that the required keys have been supplied in the hash

=item _lowercase_keys

Lowercase the keys in a hash

=item _today

Return todays date for use with the 'present' word

=item _set_range

Set the xxx_start and xxx_end values from the xxx data

=back

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Timeline->new() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if 
some arguments were supplied.

=item Timeline->add_interval() expected HASH as parameter

The parameter is a hash describing an event

=item Timeline->add_point() expected HASH as parameter

The parameter is a hash describing an event

=item Timeline->window() 'span' can only be defined with a 'start' and 'end'

To define 'span' then you must also define 'start' and 'end'

=item Timeline->window() 'callback' can only be a CODE reference

You must pass a code reference for the callback 

=item Timeline->data() takes no arguments

When the method is called it requires no arguments. This message is given if 
some arguments were supplied.

=item Timeline->add_interval() invalid key '...' passed as data

The only valid keys are 'start', 'end', 'label', 'group' and 'id'. Something else was supplied.

=item Timeline->add_interval() invalid date for '...'

The date supplied for '...' is invalid

=item Timeline->add_interval() 'start' and 'end' are in the wrong order

The values for 'start' and 'end' are in the wrong order

=item Timeline->add_interval() missing key '...'

A required key was not supplied. Required keys are 'start', 'end' and 'label'

=item Timeline->add_point() invalid key '...' passed as data

The only valid keys are 'start', 'label', 'group' and 'id'. Something else was supplied.

=item Timeline->add_point() invalid date for '...'

The date supplied for '...' is invalid

=item Timeline->add_point() missing key '...'

A required key was not supplied. Required keys are 'start' and 'label'

=item Timeline->window() invalid key '...' passed as data

The only valid keys are 'start', 'end', 'start_in', 'end_in', 'span' and 'callback'. Something else was supplied.

=item Timeline->window() invalid date for '...'

The date supplied for '...' is invalid

=item Timeline->window() 'start' and 'end' are in the wrong order

The values for 'start' and 'end' are in the wrong order

=back

=head1 BUGS

None

=head1 FILES

See the Timeline.t file in the test directory

=head1 SEE ALSO

Graph::Timeline::GD - Use GD to render the timeline

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2003, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
