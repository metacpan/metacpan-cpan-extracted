package Foo;
use Drogo::Dispatch( import_drogo_methods => 1 );
use strict;
use Foo::bar;

sub index :Index
{
    my $self = shift;

    $self->print('howdy friend');
}

sub beaver :Action { shift->print('unicorns') }

sub waffle :ActionMatch
{
    my $self = shift;
    $self->print(join('/', $self->post_args));
}

sub error        { shift->status(404) }
sub bad_dispatch { shift->error       }

sub waffles :ActionRegex('har/(.*)/roop')
{
    my $self = shift;
    my ($a) = $self->post_args;
    $self->print($a);
}

1;
