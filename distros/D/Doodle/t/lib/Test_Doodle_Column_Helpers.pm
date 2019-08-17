package Test_Doodle_Column_Helpers;

use Test::More;

use Doodle;
use Doodle::Column::Helpers;

use Data::Object 'Class', 'Doodle::Library';

has 'table';
has 'column';
has 'method';
has 'arguments';

method execute(Maybe[CodeRef] $callback) {
  my $table = $self->table;
  my $column = $self->column;
  my $method = $self->method;
  my $args = $self->arguments || [];

  can_ok "Doodle::Column::Helpers", $method;

  my $d = Doodle->new;

  my $t = $d->table($table);
  my $c = $t->column($column)->$method(@$args);

  isa_ok $c, 'Doodle::Column';

  $callback ||= fun(Column $c) { is $c->type, $method };

  $callback->($c);

  return $c;
}

1;
