package Games::Lacuna::Task::Action::Upgrade;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose  -traits => 'Deprecated';
extends qw(Games::Lacuna::Task::Action);

__PACKAGE__->meta->make_immutable;
no Moose;
1;