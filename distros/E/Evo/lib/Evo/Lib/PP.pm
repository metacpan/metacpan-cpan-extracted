package Evo::Lib::PP;
use Evo '-Export *; Carp croak';

sub eval_want : Export {
  my ($want, $fn) = (shift, pop);
  if (!defined $want) {
    eval { $fn->(@_); 1 } or return;
    return sub { };
  }
  elsif (!$want) {
    my $res;
    eval { $res = $fn->(@_); 1 } or return;
    return sub {$res};
  }
  else {
    my @res;
    eval { @res = $fn->(@_); 1 } or return;
    return sub {@res};
  }
}

sub try : prototype(&$;$) : Export {
  my ($try, $catch, $fin) = @_;
  my $call = eval_want wantarray, $try;
  $call = eval_want wantarray, my $e = $@, $catch if !$call && $catch;
  if ($call) {  # in normal way we are here, so separate this branch to avoid copying $@ before fin
    $fin->() if $fin;
    return $call->();
  }
  $e = $@;
  $fin->() if $fin;
  die $e;
}

sub uniq : Export {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub strict_opts ($hash, @other) : Export {
  croak 'Usage strict_opts($hash, qw(key1 key2))'
    . 'or strict_opts($hash, ["key1", "key2"], $level)'
    if !@other || (ref $other[0]) && @other > 2;
  my ($level, @keys);
  if (ref $other[0]) {
    @keys = (shift @other)->@*;
    $level = @other ? shift(@other) : 1;
  }
  else {
    @keys  = @other;
    $level = 1;
  }

  my %opts = %$hash;
  my @opts = map { delete $opts{$_} } @keys;
  if (my @remaining = keys %opts) {
    local $Carp::CarpLevel = $level;
    croak "Unknown options: ", join ',', @remaining;
  }
  @opts;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Lib::PP

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
