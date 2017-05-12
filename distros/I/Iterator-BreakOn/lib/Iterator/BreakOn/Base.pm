package Iterator::BreakOn::Base;
use strict;
use warnings;
use Carp;
use utf8;
use English '-no_match_vars';

use List::MoreUtils qw(uniq first_index);

use Iterator::BreakOn::X;
use Iterator::BreakOn::Event;

# Source: $Id$ 
# Author: $Author$
# Date: $Date$ 

our $VERSION = '0.3';

my %_defaults = (
    datasource          =>  undef,
    getmethod           =>  'get',  # method name for read single values 
    _check_get_method   =>  0,      # internal switch 
    eod                 =>  0,      # end of data switch 
    equeue              =>  [],     # event queue for dispatch
    rec_current         =>  undef,  # current item 
    rec_next            =>  undef,  # next item (for internal use only)
    break_before        =>  [],     # field list for break_before events
                                    # (ordered)
    break_after         =>  [],     # field list for break_after events
                                    # (ordered)
    fields              =>  [],
    code                =>  {},     # event's code
    private             =>  undef,  # reference a private data 
);

#
#   Public methods
#

sub new {
    my  $class  =   shift;
    my  $self   =   { %_defaults };

    bless $self, $class;

    return $self->init(@_);
}

sub init {
    my  $self   =   shift;
    my  %values =   @_;

    ## get the datasource parameter
    if (not defined($self->{datasource} = $values{datasource})) {
        Impresor::BreakOn::X::missing->throw( parameter => 'datasource' );
    }

    ## get the method name 
    if (defined($values{getmethod})) {
        $self->{getmethod} = $values{getmethod};
    }

    ## get the break before change 
    if (defined($values{break_before})) {
        $self->_read_breaks_array( 'before', @{$values{break_before}});
    }

    ## get the break after change
    if (defined($values{break_after})) {
        $self->_read_breaks_array( 'after', @{$values{break_after}});
    }

    ## get a list of fields
    $self->{fields} = [ uniq( @{$self->{break_before}},
                              @{$self->{break_after}}) ];

    ## on the first, last and every item
    foreach my $field qw(on_first on_last on_every) {
        if (defined $values{$field}) {
            $self->{code}->{$field} = $values{$field};
        }
    }

    ## save the private data if exists
    if (defined $values{private}) {
        $self->{private} = $values{private};
    }

    return $self;
}

sub reset {
    my  $self   =   shift;

    # clean the event queue
    $self->{equeue} = [];

    # clean the value copies
    $self->{rec_current} = undef;
    $self->{rec_next} = undef;

    return $self;
}

sub run {
    my  $self   =   shift;

    ## reset the iterator
    $self->reset();

    return $self->_next_event( 'NONE' );
}

sub next {
    my  $self   =   shift;

    if ($self->_next_event( 'on_every')) {
        return $self->{rec_current};
    }
    else {
        return;
    }
}

sub next_event {
    my  $self   =   shift;

    return $self->_next_event( 'ALL' );
}

sub item {
    my  $self   =   shift;

    return $self->{rec_current};
}

sub current_values {
    my  $self   =   shift;
    my  %values =   ();

    if ($self->{rec_current} and $self->{rec_current}->can('getall')) {
        %values = $self->{rec_current}->getall();
    }

    return wantarray ? %values : \%values;
}

sub private {
    my  $self   =   shift;

    return $self->{private};
}

#
#   Private methods
#

sub _next_event {
    my  $self       =   shift;
    my  $stop_on    =   shift || 'NONE';

    ITEMS:
    ## read the next item 
    while (1) {
        EVENTS:
        ## read the event queue 
        while (my $event = $self->_shift()) {
            ## if we must stop on all events or this event is the stop
            ## return the event without process it
            if ($stop_on eq 'ALL' or $stop_on eq $event->name()) {
                return $event;
            }
            else {
                ## process the event and get the next
                $self->_process_event( $event );
            }
        }

        ## checking the state 
        if ($self->{eod}) {
            return;
        }

        ## read the next item
        if (not $self->_read_next_item()) {
            ## empty events queue and empty records: end of data 
            return;
        }
    }

    return;
}

sub _process_event {
    my  $self   =   shift;
    my  $event  =   shift;
    my  $name   =   $event->name();

    ## return if we don't have code for the event
    if (not $self->{code}->{$name}) {
        return;
    }

    ## switch on event type 
    if ($name =~ m{on_first|on_last|on_every}xms) {
        ## call to dispatch code without parameters
        $self->{code}->{$name}->( $self );
    }
    elsif ($name =~ m{^(before|after)_}xms) {
        ## call to dispatch code with field name and value 
        $self->{code}->{$name}->( $self, $event->field(), $event->value() );
    }

    return;
}

sub _read_next_item {
    my  $self           =   shift;

    ## try read the next item ...
    $self->{rec_next} = $self->_load_item( );

    #
    #   Special cases 
    #

    ## is the first item ? 
    if (not $self->{rec_current}) {
        ## is a empty list ? 
        if (not $self->{rec_next}) {
            ## yes, only the first and last events
            $self->_first_events()->_last_events();
        }
        else {
            # move the next item to the current, push the initial and
            # the break_before events, and the on_every 
            $self->_next_to_current()->
                   _first_events()->
                   _push_all_breaks( 'before' )->
                   _push_on_every();
        }
    }
    ###   is the last item ? 
    elsif (not $self->{rec_next}) {
        ## end of data: break_after and last events
        $self->_push_all_breaks( 'after' )->_last_events();
    }
    else {
        ## build the break_after events
        $self->_cmp_fields( 'after', $self->{break_after});

        ## build the break_before events
        $self->_cmp_fields( 'before', $self->{break_before});

        ## every record event
        $self->_next_to_current()->_push_on_every();
    }

    return $self;
}

sub _next_to_current {
    my  $self   =   shift;

    $self->{rec_current} = $self->{rec_next};

    return $self;
}

sub _cmp_fields {
    my  $self       =   shift;
    my  $when       =   shift;          # after | before 
    my  $fields_ref =   shift;          # fields names 
    my  @events     =   ();

    ## loop around the fields list
    my $raise_event = 0;
    my $get = $self->{getmethod};
    foreach my $field_name (@{ $fields_ref }) {
        my  $current    =   $self->{rec_current}->$get($field_name);
        my  $next       =   $self->{rec_next}->$get($field_name);

        ## if the values are differents (as strings) 
        if ($raise_event or "${current}" ne "${next}") {
            ## add the event to the list 
            push(@events, $self->_build_break_event( $when, $field_name ));
            $raise_event = 1;
        }
    }

    ## add the events if not empty
    if (@events) {
        if ($when eq 'after') {
            @events = reverse @events;
        }
        $self->_push( @events );
    }

    return $self;
}

sub _load_item {
    my  $self       =   shift;

    ## retrieve the next item in the datasource
    my $item = eval {
            $self->{datasource}->next();
        };

    ## checking fatal errors        
    if ($EVAL_ERROR) {
        Iterator::BreakOn::X::datasource->throw();
    }

    # checking ever the new item and only once the user supplied get method 
    if (defined $item) {
        if (not $self->{_check_get_method}) {
            if (not $item->can( $self->{getmethod} )) {
                Iterator::BreakOn::X::getmethod->throw( 
                        get_method => $self->{getmethod}
                    );
            }
            $self->{_check_get_method} = 1;
        }
    }

    return $item;
}

=begin comments

This private method add events to the object internal queue. Receive a list of
events and each event is a hash reference with the following attributes:

=over

=item name

=item field

=item value

=back

Return the object reference for use in chained calls.

=end comments

=cut

sub _push {
    my  $self           =   shift;

    ## loop around the events list
    foreach my $event (@_) {
        my $event_object = Iterator::BreakOn::Event->new( $event );

        ## add to the list of events            
        push(@{ $self->{equeue} }, $event_object );
    }

    return $self;
}

sub _shift {
    my  $self       =   shift;

    if (@{ $self->{equeue} }) {
        my $event = shift @{ $self->{equeue} };

        return $event;
    }
    else {
        return undef;
    }
}

sub _push_on_every {
    my  $self   =   shift;

    return $self->_push( { name => 'on_every' } );
}

sub _push_all_breaks {
    my  $self       =   shift;
    my  $when       =   shift;      # after or before

    return $self->_push( $self->_build_all_breaks( $when ) );
}

sub _build_all_breaks {
    my  $self       =   shift;
    my  $when       =   shift;      # after or before
    my  @breaks     =   ();

    # on every field name for the break 
    foreach my $field_name (@{ $self->{"break_${when}"} }) {
        # push the event             
        push( @breaks, $self->_build_break_event( $when, $field_name ) );
    }
    
    return $when eq 'after' ? reverse @breaks : @breaks;
}

sub _build_break_event {
    my  $self   =   shift;
    my  $when   =   shift;      # after or before
    my  $field  =   shift;      # field name 
    my  $value  =   $self->_get_field_value( $when, $field );

    return {    name  => "${when}_${field}",
                field => $field,
                value => $value   };
}

sub _get_field_value {
    my  $self   =   shift;
    my  $when   =   shift;
    my  $field  =   shift;

    my  $from   =   $when eq 'after' ? 'rec_current' : 'rec_next';
    my  $value  =   $self->{$from} ? $self->{$from}->get($field) : undef;

    return $value;
}

sub _first_events {
    my  $self   =   shift;

    ## push the event for the first item
    return $self->_push( { 'name' => 'on_first' } );
}

sub _last_events {
    my  $self   =   shift;

    ## push the event for the last item
    $self->_push( { name => 'on_last' } );

    ## and set the state
    $self->{eod} = 1;

    return $self;
}

sub _read_breaks_array {
    my  $self       =   shift;
    my  $when       =   shift;
    my  @breaks     =   @_;

    BREAKS:
    while (@breaks) {
        # take the field name and a hipotetical code reference from the next
        # item
        my $field = shift @breaks;
        my $code  = ref($breaks[0]) eq 'CODE' ? shift @breaks : undef;

        # save the order in the break fields
        push(@{ $self->{ "break_${when}" } }, $field);

        # save the code for that event
        my $event = "${when}_${field}";

        # using a default closure if the value is not defined
        if (not defined($code)) {
            $code = sub {
                        return $event;
                    };
        }

        # in a hash table 
        $self->{code}->{ $event } = $code;
    }

    return $self;
}

1;
__END__
=pod

=head1 NAME

Iterator::BreakOn::Base - Base class for iterator with flow breaks

=head1 SYNOPSIS

    package MyIterator;
    use qw(Iterator::BreakOn::Base);

    1;

=head1 DESCRIPTION

This module is a base class for build iterators with flow breaks. Provides
methods for create and proccess the iterators.

=head1 SUBROUTINES/METHODS

=head2 new( )

This method create a new package object. The parameters are:

=over

=item  * datasource

Object reference with a I<next> method supported. That method return a data
object with a I<get> method for read the values.

=item  * getmethod 

This is the method name for read individual values. The default value is
I<get> in I<Base> module and 'get_column' in this module.

=item   * private

Reference to arbitrary data to save in the object. Useful for later recover
his value through C<private> method.

=back

The following atributes can be a list of fields followed for an optional code
reference.  The order of the fields is significant.

=over

=item  * break_before

=item  * break_after

=back

These attributes must contain a code reference.

=over 

=item  * on_first

=item  * on_last

=item  * on_every

=back

=head2 init( )

This method initialize the object attributes.

=head2 reset( )

This method reset the event queue of the object.

=head2 run( )

    $iter->run();

        
=head2 next( )

    while (my $item_ref = $iter->next()) {
        # do something ...
    }

This method returns the next item in the data source after process the other
events in the queue.

=head2 next_event( )

    while (my $event = $iter->next_event()) {
        if ($event->name() eq 'on_last') {
            # end of data reached
            ...
        }
        ...
    }

This method return the next event in the data source. For each item readed the
event name is 'on_every'.

The event is an object with the following attributes:

=over

=item name

The event name can be I<on_first>, I<on_last>, I<on_every>, I<before_XXXX> or
I<after_XXXX>.

=item field

This is the field name if the event is I<before> or I<after>.

=item value

Field value when the event was raised.

=back

=head2 item( )

Returns a reference to the current item in the iterator.

=head2 current_values( )

Calls to the optional getall method on the current item in the iterator, and returns a
hash with fields and values.

=head2 private( )

Returns a reference to the private data save in the object.

=head1 DIAGNOSTICS

A list of every error and warning message that the module
can generate.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author.
Patches are welcome.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - Victor Moral

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
