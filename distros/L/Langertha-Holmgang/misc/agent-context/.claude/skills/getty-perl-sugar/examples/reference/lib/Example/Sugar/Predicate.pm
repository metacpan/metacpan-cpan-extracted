package Example::Sugar::Predicate;
use strict;
use warnings;
use Scalar::Util qw(blessed);

# Trusted, parameterless reader methods only. This is not an expression parser.
sub _reader_name {
  my ($name) = @_;
  return defined($name) && !ref($name) && $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
}
sub normalize {
  my ($predicate) = @_;
  return undef unless defined $predicate;
  return $predicate if ref($predicate) eq 'CODE';
  if (!ref $predicate) {
    die "Predicate must be a reader name, not an expression\n" unless _reader_name($predicate);
    return "$predicate";
  }
  if (ref($predicate) eq 'HASH') {
    die "An empty predicate map is not allowed\n" unless keys %$predicate;
    for my $name (keys %$predicate) {
      die "Invalid predicate reader '$name'\n" unless _reader_name($name);
      die "Predicate expectations must be scalars or undef\n" if ref $predicate->{$name};
    }
    return { %$predicate };
  }
  die "Unsupported predicate type\n";
}
sub _read {
  my ($subject, $name) = @_;
  die "Predicate subject must be an object\n" unless blessed($subject);
  die "Missing predicate reader '$name'\n" unless $subject->can($name);
  return $subject->$name();
}
sub evaluate {
  my ($predicate, $subject) = @_;
  return 1 unless defined $predicate;
  if (ref($predicate) eq 'CODE') {
    my $value = $predicate->($subject);
    die "Predicate returned a reference instead of a scalar\n" if ref $value;
    return $value ? 1 : 0;
  }
  if (!ref $predicate) {
    my $value = _read($subject, $predicate);
    die "Predicate reader returned a reference\n" if ref $value;
    return $value ? 1 : 0;
  }
  for my $name (sort keys %$predicate) {
    my $actual = _read($subject, $name);
    my $expected = $predicate->{$name};
    die "Predicate reader '$name' returned a reference\n" if ref $actual;
    return 0 if defined($actual) != defined($expected);
    return 0 if defined($actual) && "$actual" ne "$expected";
  }
  return 1;
}
sub describe {
  my ($predicate) = @_;
  return { kind => 'always' } unless defined $predicate;
  return { kind => 'opaque_callback' } if ref($predicate) eq 'CODE';
  return { kind => 'equals_all', readers => { %$predicate } } if ref($predicate) eq 'HASH';
  return { kind => 'truthy_reader', reader => $predicate };
}
1;
