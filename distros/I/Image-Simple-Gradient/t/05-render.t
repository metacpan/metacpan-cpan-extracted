#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Image::Simple::Gradient' ) || print "Bail out!
";
}
require_ok( 'Image::Simple::Gradient' );

my $image = Image::Simple::Gradient->new({
  color_begin => 'FF0000', 
  color_end => '0000FF', 
  direction => 'up', 
  height => 100,
  width => 200,
  });
cmp_ok($image->height, '==', 100, '100 px height');
cmp_ok($image->width, '==', 200, '100 px width');
cmp_ok($image->direction, 'eq' , 'up', 'Image direction: up');

write_test( $image->render_gradient(), 'test.jpg' );

diag( "Testing Image::Simple::Gradient $Image::Simple::Gradient::VERSION, Perl $], $^X" );

sub write_test {
  my ($im, $filename) = @_;
  local *FH;
  fail("could not render image") if not defined $im;

  if (open FH, "> $filename") {
    binmode FH;
    my $IO = fileno(FH);
    unless (ok(print FH $im, $filename)) {
      print "# error writing file\n";
    }     
    undef $IO;
    close FH;
    unlink($filename);
  }
  else {
    fail("could not open $filename: $!");
  }
}

