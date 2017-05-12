package View::bullet;

use base qw(HTML::Seamstress);

my $file = 'html/bullet.html';

sub new {
  
  __PACKAGE__->new_from_file($file);

}

sub render {

  my $tree = shift;
  my $model = shift;

  my $li = $tree->look_down(class => 'nums');

  $tree->iter($li => @$model) ;

  return $tree;
}

1;

