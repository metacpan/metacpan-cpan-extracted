use v5.40;
use Test2::V0;
use utf8;

use Minima::View::PlainText;

my $view = Minima::View::PlainText->new;

# Empty
is( $view->render, '', 'render valid content without data' );

# UTF-8
my $s = 'áèîõü';
utf8::encode($s);
is( $view->render('áèîõü'), $s, 'encodes UTF-8' );

done_testing;
