package Example::Sugar::Schema;
use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();
our @EXPORT_OK = qw(str num int_ bool arr obj nullable enum_);
sub _copy { return JSON::PP->new->allow_nonref->decode(JSON::PP->new->allow_nonref->encode($_[0])) }
sub _options {
  my ($allowed, @pairs) = @_;
  die "Odd schema option list\n" if @pairs % 2;
  my (%out, %seen);
  while (@pairs) {
    my ($key, $value) = splice @pairs, 0, 2;
    die "Unknown schema option\n" unless defined($key) && !ref($key) && exists $allowed->{$key};
    die "Repeated schema option '$key'\n" if $seen{$key}++;
    $out{$allowed->{$key}} = $value;
  }
  return \%out;
}
sub _typed {
  my ($type, $allowed, @pairs) = @_;
  my $opts = _options($allowed, @pairs);
  for my $key (keys %$opts) {
    my $v = $opts->{$key};
    die "Schema option '$key' must be a scalar\n" unless defined($v) && !ref($v);
    if ($key =~ /\A(?:minLength|maxLength|minItems|maxItems)\z/) {
      die "Schema option '$key' must be a nonnegative integer\n" unless $v =~ /\A\d+\z/;
      $opts->{$key} = 0 + $v;
    } elsif ($key =~ /\A(?:minimum|maximum)\z/) {
      die "Schema option '$key' must be a finite JSON number\n" unless $v =~ /\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\z/;
      my $n = 0 + $v;
      die "Schema option '$key' overflows\n" if "$n" =~ /inf|nan/i;
      $opts->{$key} = $n;
    } else {
      $opts->{$key} = "$v";
    }
  }
  for my $bounds ([qw(minLength maxLength)], [qw(minItems maxItems)], [qw(minimum maximum)]) {
    my ($lo, $hi) = @$bounds;
    die "Inverted schema bounds\n" if exists($opts->{$lo}) && exists($opts->{$hi}) && $opts->{$lo} > $opts->{$hi};
  }
  return { type => $type, %$opts };
}
sub str { return _typed('string', {min=>'minLength',max=>'maxLength',pattern=>'pattern',description=>'description'}, @_) }
sub num { return _typed('number', {min=>'minimum',max=>'maximum',description=>'description'}, @_) }
sub int_ { return _typed('integer', {min=>'minimum',max=>'maximum',description=>'description'}, @_) }
sub bool { return _typed('boolean', {description=>'description'}, @_) }
sub arr {
  my ($items, @options) = @_;
  die "Array items must be a schema hashref\n" unless ref($items) eq 'HASH';
  return { %{_typed('array', {min=>'minItems',max=>'maxItems',description=>'description'}, @options)}, items => _copy($items) };
}
sub obj {
  my ($properties, @options) = @_;
  die "Object properties must be a hashref\n" unless ref($properties) eq 'HASH';
  die "Each property must be a schema hashref\n" if grep { ref($_) ne 'HASH' } values %$properties;
  my $opts = _options({required=>'required',additional=>'additionalProperties',description=>'description'}, @options);
  my $required = exists($opts->{required}) ? $opts->{required} : [];
  die "required must be an arrayref\n" unless ref($required) eq 'ARRAY';
  my %seen;
  for my $key (@$required) {
    die "Invalid required property\n" unless defined($key) && !ref($key) && exists($properties->{$key});
    die "Duplicate required property '$key'\n" if $seen{$key}++;
  }
  my $additional = exists($opts->{additionalProperties}) ? $opts->{additionalProperties} : 0;
  die "additional must be 0 or 1\n" unless defined($additional) && !ref($additional) && "$additional" =~ /\A[01]\z/;
  if (exists $opts->{description}) {
    die "description must be a scalar\n" unless defined($opts->{description}) && !ref($opts->{description});
  }
  return { type=>'object', properties=>_copy($properties), required=>[@$required],
    additionalProperties => $additional ? JSON::PP::true : JSON::PP::false,
    (exists($opts->{description}) ? (description=>"$opts->{description}") : ()),
  };
}
sub nullable {
  my ($schema) = @_;
  die "nullable requires one schema hashref\n" unless @_ == 1 && ref($schema) eq 'HASH';
  # A union also works for enum/const schemas. Merely appending null to type does not.
  return { anyOf => [_copy($schema), {type=>'null'}] };
}
sub enum_ {
  die "enum_ requires at least one string\n" unless @_;
  my %seen;
  my @values;
  for my $v (@_) {
    die "enum_ values must be defined scalars\n" unless defined($v) && !ref($v);
    die "Duplicate enum value '$v'\n" if $seen{"$v"}++;
    push @values, "$v";
  }
  return { type=>'string', enum=>\@values };
}
1;
