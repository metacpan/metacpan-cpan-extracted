package Test::Evo::Benchmark;
use Evo;
use parent 'Exporter';
use Test::More;
use Carp 'croak';

use Benchmark 'timeit';

our @EXPORT = qw(faster_ok);

sub faster_ok {
  my %args = @_;

  $args{$_} or croak "define $_ option" for qw(iters fn expect);
  my ($iters, $fn, $expect, $diag) = @args{qw(iters fn expect diag)};


  my $t = timeit($iters, $fn);
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  if ($t->cpu_a) {
    my $perf = $iters / $t->cpu_a;
    do { diag timestr $t; diag $perf } if $diag;
    ok $perf > $expect, "$perf > $expect";
  }
  else {
    fail "too few itreations $iters";
  }

  $t;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Evo::Benchmark

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
