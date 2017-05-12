sub {
  my ($yaml) = @_;
  @{ $yaml->{branches}->{only} } = map { ( $_ eq 'build/master' ) ? 'builds' : $_ } @{ $yaml->{branches}->{only} };
};
