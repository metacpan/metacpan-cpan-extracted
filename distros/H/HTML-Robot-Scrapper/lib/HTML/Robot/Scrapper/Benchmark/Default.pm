package HTML::Robot::Scrapper::Benchmark::Default;
use Moose;
use DateTime;
use Data::Printer;
use Time::HiRes qw(gettimeofday tv_interval);

=head2 DESCRIPTION

The Benchmark class should provide complete subrouting stats with 

- subroutine stack tree

- subrouting timings and totals

- print in catalyst style

* Its not implemented yet.. help is welcome


=cut

has [ qw/robot engine/ ] => ( is => 'rw', );
has 'values' => ( is => 'rw' );

sub BUILD {
    my ( $self ) = @_;
    $self->values({});
}

sub method_start {
    my ( $self, $method, $label ) = @_;
    my $values = $self->values;
    $values->{ $method } = {
#     start => DateTime->now(),
      start => [gettimeofday],
    };
    $self->values( $values );
}

sub method_finish {
    my ( $self, $method, $label ) = @_;
    my $values = $self->values;
#   $values->{ $method }->{ finish  }  = DateTime->now();
    $values->{ $method }->{ finish  }  = [gettimeofday];
#   $values->{ $method }->{ duration } = $values->{ $method }->{ finish } - $values->{ $method }->{ start } ;
    $values->{ $method }->{ duration } = tv_interval ( $values->{ $method }->{ start }, $values->{ $method }->{ finish } ); ;
    my $text = ( $label ) ? $label : $method;
    warn " => ". $text . ": ". $values->{ $method }->{ duration } . ' seconds';
    $self->values( $values );
}

1;
