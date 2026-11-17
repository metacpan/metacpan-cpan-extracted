package Example::Sugar::Registry;
use strict;
use warnings;
use Example::Sugar::Predicate ();

my (%buckets, %keys, %sealed);
my %phase_rank = (gather => 10, analyse => 20, score => 30, render => 40);
sub phase_rank { return $phase_rank{$_[0]} }
sub _name {
  return defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
}
sub _owner {
  return defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/a;
}
sub register_step {
  my ($owner, $predicate, $label, $key, $code, @options) = @_;
  die "Invalid declaration owner\n" unless _owner($owner);
  die "Registry is sealed for $owner\n" if $sealed{$owner};
  die "Invalid step key\n" unless _name($key);
  die "Missing label for '$key'\n" unless defined($label) && !ref($label) && length($label);
  die "Step '$key' requires a coderef\n" unless ref($code) eq 'CODE';
  die "Odd option list for '$key'\n" if @options % 2;
  my (%opts, %seen);
  while (@options) {
    my ($name, $value) = splice @options, 0, 2;
    die "Unknown step option\n" unless defined($name) && !ref($name)
      && $name =~ /\A(?:phase|requires|revision)\z/;
    die "Repeated option '$name' for '$key'\n" if $seen{$name}++;
    $opts{$name} = $value;
  }
  my $phase = exists($opts{phase}) ? $opts{phase} : 'gather';
  die "Unknown phase for '$key'\n" unless defined($phase) && !ref($phase) && exists $phase_rank{$phase};
  my $requires = exists($opts{requires}) ? $opts{requires} : [];
  die "requires must be an arrayref for '$key'\n" unless ref($requires) eq 'ARRAY';
  my %dep_seen;
  for my $dep (@$requires) {
    die "Invalid dependency for '$key'\n" unless _name($dep);
    die "Repeated dependency '$dep' for '$key'\n" if $dep_seen{$dep}++;
    die "Step '$key' cannot require itself\n" if $dep eq $key;
  }
  my $revision = exists($opts{revision}) ? $opts{revision} : '1';
  die "revision must be a nonempty scalar\n" unless defined($revision) && !ref($revision) && length($revision);
  my $pred = Example::Sugar::Predicate::normalize($predicate);
  die "Duplicate step key '$key' in $owner\n" if $keys{$owner}{$key};
  # Commit only after every field is valid. Never reset an owner's bucket on import.
  my $bucket = $buckets{$owner} //= [];
  push @$bucket, {
    owner => $owner, index => scalar(@$bucket), key => $key,
    label => "$label", code => $code, predicate => $pred,
    phase => $phase, requires => [@$requires], revision => "$revision",
  };
  $keys{$owner}{$key} = 1;
  return;
}
sub entries {
  my ($owner) = @_;
  return [map { +{ %$_, requires => [@{$_->{requires}}],
    predicate => Example::Sugar::Predicate::normalize($_->{predicate}) } }
    @{$buckets{$owner} // []}];
}
sub seal_owner {
  my ($owner) = @_;
  die "Invalid declaration owner\n" unless _owner($owner);
  $sealed{$owner} = 1;
  return;
}
1;
