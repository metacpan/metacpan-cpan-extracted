package List::ToHash;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.02';
our @EXPORT_OK = qw/to_hash/;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

List::ToHash - List to hash which have unique keys

=head1 SYNOPSIS

  use List::ToHash qw/to_hash/;
  my @users = (
      {
          id => 1,
          value => 'foo',
      },
      {
          id => 2,
          value => 'bar',
      },
  );
  my $x = to_hash { $_->{id} } @users;
  # {
  #     "1" => {
  #        "id" => 1,
  #        "value" => "foo"
  #     },
  #     "2" => {
  #        "id" => 2,
  #        "value" => "bar"
  #     }
  # };

=head1 DESCRIPTION

List::ToHash provides fast conversion list to hash by using lightweight callback API.

C<map> is so simple and good for readability. I usually use this in this situation.

  my $x = +{map { ($_->{id} => $_) } @users};

C<List::Util::reduce> is a little tricky however it works faster than C<map>.

  my $x = List::Util::reduce { $a->{$b->{id}} = $b; $a } ({}, @ARRAY);

C<for> is lame... Look, it spends two lines.

  my $x = {};
  $x->{$_->{id}} = $_ for @users;

C<List::ToHash::to_hash> is a quite simple way, more faster.

  my $x = List::ToHash::to_hash { $_->{id} } @users;

=head2 BENCHMARK

List::ToHash is the fastest module in this benchmark C<eg/bench.pl>.

  Benchmark: running for, map, reduce, to_hash for at least 3 CPU seconds...
         for:  3 wallclock secs ( 3.18 usr +  0.01 sys =  3.19 CPU) @ 19303.13/s (n=61577)
         map:  3 wallclock secs ( 3.13 usr +  0.02 sys =  3.15 CPU) @ 13437.46/s (n=42328)
      reduce:  3 wallclock secs ( 3.20 usr +  0.02 sys =  3.22 CPU) @ 18504.66/s (n=59585)
     to_hash:  4 wallclock secs ( 3.12 usr +  0.01 sys =  3.13 CPU) @ 26635.78/s (n=83370)
             Rate     map  reduce     for to_hash
  map     13437/s      --    -27%    -30%    -50%
  reduce  18505/s     38%      --     -4%    -31%
  for     19303/s     44%      4%      --    -28%
  to_hash 26636/s     98%     44%     38%      --

=head1 FUNCTIONS

=over 4

=item my $hashref = to_hash { ... } @list;

Returns the hash reference of given C<@list> for which have the key returned by the block.

    my $id_to_user_row = to_hash { $_->{id} } @user_rows;

=back

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
