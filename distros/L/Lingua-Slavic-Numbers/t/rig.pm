sub rig
{
 my $data = shift @_;
 my $func = shift @_;

 foreach my $number (sort keys %$data)
 {
  my $test_string = $data->{$number};
  my $answer = $func->($number);

  ok( $answer, $test_string );
  if ($answer ne $test_string)
  {
   binmode STDOUT, ':utf8';
   print number_to_bg( $number ), " ??? ", $test_string, "\n";
  }
 }
}
