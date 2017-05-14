package Games::Rezrov::InlinedPrivateMethod;
# create array-inlined versions of private method calls.
# MNE 5/12/99

use strict;

sub new {
  my ($package, %options) = @_;

  my $caller = scalar caller();
  my $count = $options{"-start"} || 0;
  die "need -names" unless $options{"-names"};
  my %names;
  foreach (@{$options{"-names"}}) {
    die "need leading _ for $_ in $caller!" unless /^_/;
    $names{$_} = 1;
  }

  my $code = "";
  my $fh;
  do {
    no strict 'refs';
    die "eek" unless $caller;
    eval '$fh = \*' . $caller . '::DATA';
    # yech, what's the "clean" syntax for this?
    die $@ if $@;

#    $fh = \*{$caller::DATA};
    # fails
  };
  while (<$fh>) {
    $code .= $_;
  }
  
  my %seen;
#  while ($code =~ /(->([A-Z_\d]+)\((.*?)\))/g) {
#  while ($code =~ /(->([A-Z_\d]+)\((.*)\))/g) {
  # .* = BROKEN
  my $char;
  while ($code =~ /(->(_\w+)\()/g) {
    my ($full, $var) = ($1, $2);
    next unless exists $names{$var};
    my $start = pos($code);
    my $end = $start;
    my $depth=1;
    while (1) {
      # find code between the appropriately nested paren
      # FIX ME: QUOTED ('s
      $char = substr($code, $end, 1);
      if ($char eq '(') {
	$depth++;
      } elsif ($char eq ')') {
	last if --$depth == 0;
      }
      $end++;
    }
    my $value = substr($code, $start, $end - $start);
    $full .= $value . ")";
#    printf STDERR "full: %s ... value: %s\n", $full, $value;
    my $index;
    if (exists $seen{$var}) {
      $index = $seen{$var};
    } else {
      $index = $seen{$var} = $count++;
    }
    if (length $value) {
      # setting
      $code =~ s/\Q$full\E/->[$index] = $value/;
    } else {
      # referring
      $code =~ s/\Q$full\E/->[$index]/;
    }
    die "xxx: $1" unless length $2;
  }

  if (scalar keys %seen != scalar keys %names) {
    foreach (keys %names) {
      die "hmm, never saw reference to $_ in $caller..." unless exists $seen{$_};
    }
  }

#  print STDERR $code;
  if ($options{"-manual"}) {
    # user wants to manipulate/eval code themselves
    return \$code;
  } else {
    # wrap code in caller's package
    $code = sprintf("\{ package %s;\n", $caller) . $code . "\n\}\n";
    eval $code;
    die "eval error: $@" if $@;
  }
}

1;
