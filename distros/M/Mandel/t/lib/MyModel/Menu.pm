package MyModel::Menu;
use Mandel::Document 'menu';

field 'soup';

our @INITIALIZE;

sub initialize {
  @INITIALIZE = @_;
}

1;
