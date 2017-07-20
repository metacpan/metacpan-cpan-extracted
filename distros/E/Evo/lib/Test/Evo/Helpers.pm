package Test::Evo::Helpers;
use Evo '-Export *';

sub test_memory ($count, $limit, $code) : Export {
  require Memory::Stats;
  my $stats = Memory::Stats->new;
  {
    $stats->start;
    $code->() for 1 .. $count;
  }
  $stats->stop;
  my $consumed = $stats->usage;
  die "consumed $consumed bytes, threshold is: $limit" if $limit && $stats->usage > $limit;
  $consumed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Evo::Helpers

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
