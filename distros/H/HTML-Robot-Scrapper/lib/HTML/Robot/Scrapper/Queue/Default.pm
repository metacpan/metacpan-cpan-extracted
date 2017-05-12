package HTML::Robot::Scrapper::Queue::Default;
use Moose;
extends 'HTML::Robot::Scrapper::Queue::Array';

has robot   => ( is => 'rw', );
has engine  => ( is => 'rw', );

1;
