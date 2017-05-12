package Mail::TieFolder::dummy;

# warn "require";

sub TIEHASH
{
  my ($class, $folder, $rargs) = @_;
  # $rargs = "dummyargs";

  # warn ref($class);
  # warn $folder;
  # warn $rargs;

  return 0 unless ref($class) eq "Mail::TieFolder";
  return 0 unless $folder eq "dummybox";
  return 0 unless $rargs eq "dummyargs";

  my $self={};
  bless $self, $class;
  return $self;
}

1;
