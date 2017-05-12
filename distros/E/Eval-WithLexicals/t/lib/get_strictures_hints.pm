package get_strictures_hints;

sub hints {
  local $ENV{PERL_STRICTURES_EXTRA} = 0;
  my $strictures_hints;
  my $strictures_warn;

  eval q{
    use strictures 1;
    BEGIN {
      # Find the hint value that 'use strictures 1' sets on this perl.
      $strictures_hints = $^H;
      $strictures_warn = ${^WARNING_BITS};
    };
    1;
  } or die $@;

  return ($strictures_hints, $strictures_warn);
}

1;
