package View::bullet::text;


use base qw(View::bullet);
use Data::Dumper;
use HTML::FormatText;

my $file = 'html/bullet.html';

sub new {
  __PACKAGE__->new_from_file($file);
}

sub render {

  my $tree = shift;
  my $model = shift;

  my $tree = $tree->SUPER::render($model);

  my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 80);
  my $text = $formatter->format($tree);
  return $text;
}

1;

