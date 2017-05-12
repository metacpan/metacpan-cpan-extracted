package HTML::MobileJp::Filter::Role;
use Any::Moose '::Role';

has config => (
    is      => 'rw',
    isa     => 'Maybe[HashRef]',
    default => sub { {} },
);

has mobile_agent => (
    is  => 'rw',
    isa => 'HTTP::MobileAgent',
);

requires 'filter';

sub BUILD {
    my $self = shift;
    
    $self->config({
        %{ $self->meta->get_attribute('config')->default->() },
        %{ $self->config || {} },
    });

    $self->init;
}

sub init { }

1;
