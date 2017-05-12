package HTML::Robot::Scrapper::Log::Base;
use Moose;

has robot => ( is => 'rw', );
has engine => ( is => 'rw', );

sub write {
    my ( $self ) = @_;
}

1;
