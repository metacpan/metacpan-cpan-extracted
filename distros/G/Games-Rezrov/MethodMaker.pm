package Games::Rezrov::MethodMaker;

use strict;

my %TOTALS;

sub import {
  my ($package, @names) = @_;

  my $caller = scalar caller();
  my $buffer = sprintf "\{ package %s;\n", $caller;
  my $type = 0;

  my $count = 0;
  if (ref $names[0]) {
    my $ref = shift @names;
    if (ref $ref eq "ARRAY") {
      $type = 1;
      $count = $ref->[0] || 0;
#      printf STDERR "%s sc: $count\n", scalar caller;
    } else {
      die "huh?";
    }
  }

  if ($type == 1) {
    #
    # blessed array style
    # 
      foreach (@names) {
	$buffer .= sprintf '
sub %s {
	return(defined $_[1] ? $_[0]->[%d] = $_[1] : $_[0]->[%d]);
       }
', $_, $count, $count;
      $count++;
      }
  } else {
    #
    # blessed hash style
    # 
    foreach (@names) {
      $buffer .= sprintf '
  sub %s {
	  return(defined $_[1] ? $_[0]->{"%s"} = $_[1] : $_[0]->{"%s"});
	 }
', $_, $_, $_;
    }
}
  $buffer .= "\n\}\n";

#print STDERR $buffer;
  eval $buffer;

  $TOTALS{$caller} = $count;
  
  die "yikes: $buffer" if $@;
}

sub get_count {
  # return count of methods built; for array style, returns next
  # available index
  return $TOTALS{scalar caller()};
}

1;
