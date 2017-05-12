package IronMan::Schema::ResultSet::Post;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use DateTime;

=head2 posts_for_day

posts_for_day($datetime)

Returns a resultset containing all posts for a particular date.

=cut

sub posts_for_day {
    my ($self, $dt_day) = @_;
      
	my $day_start = $dt_day->clone()->truncate( 'to' => 'day');
	
	my $day_end = $day_start->clone()->add( 'days' => 1 )->subtract( 'seconds' => 1 );
	
    return $self->posts_for_daterange($day_start, $day_end);
}

=head2 posts_for_month

posts_for_month($datetime)

Returns a resultset containing all posts for a particular month.

=cut

sub posts_for_month {
    my ($self, $dt_month) = @_;
      
    my $month_start = $dt_month->clone()->truncate( 'to' => 'month');

	my $month_end = $month_start->clone()->add( 'months' => 1 )->subtract( 'seconds' => 1 );

    return $self->posts_for_daterange($month_start, $month_end);
}

=head2 posts_for_daterange

posts_for_daterange($datetime_start,$datetime_end)

Returns a resultset containing all posts between two datetime objects.

=cut

sub posts_for_daterange {
    my ($self, $dt_start, $dt_end ) = @_;

	my $dt_parser = $self->result_source->storage->datetime_parser;
   
	return $self->search({
	   'posted_on' => { '-between' => [ map $dt_parser->format_datetime($_), $dt_start, $dt_end ] },
	},{
	    'order_by' => \'posted_on DESC',
    });
    
}

1;
