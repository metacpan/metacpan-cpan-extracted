package MOP4Import::Util::JSON_TYPE;
use strict;
use warnings;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

use MOP4Import::Util qw/globref define_constant/;

use Cpanel::JSON::XS::Type;

our %JSON_TYPES; # It is too early to hide this.

BEGIN {
  my $CLS = 'Cpanel::JSON::XS::Type';

  foreach my $origTypeName (qw(int float string bool null)) {
    foreach my $suffix ('', '_or_null') {
      # Ignore null_or_null
      next if $origTypeName eq 'null' and $suffix ne '';

      my $typeName = $origTypeName . $suffix;
      my $lowerName = "JSON_TYPE_".$typeName;
      my $upperName = "JSON_TYPE_".uc($typeName);
      my $value = $CLS->$upperName;
      define_constant(join("::", __PACKAGE__, $lowerName), $value);

      # Make sure underlying typecode 1, 2, 3... can be resolved too.
      $JSON_TYPES{$value} = $value;
    }
  }

  foreach my $keyword (qw(hashof arrayof anyof null_or_anyof)) {
    my $longName = "json_type_$keyword";
    *{globref(__PACKAGE__, $keyword)} = $CLS->can($longName);
  }
}

sub intern_json_type {
  my ($pack, $typeName) = @_;
  if (ref $typeName) {
    $typeName;
  } else {
    $JSON_TYPES{$typeName} //= $pack->build_json_type($typeName);
  }
}

sub lookup_json_type {
  my ($pack, $typeName) = @_;
  $JSON_TYPES{$typeName};
}

sub register_json_type_of_field {
  my ($pack, $destpkg, $fieldName, $jsonType) = @_;
  my $typeRec = $JSON_TYPES{$destpkg} //= +{};
  unless (ref $typeRec eq 'HASH') {
    Carp::croak "Can't set json_type for $destpkg\->{$fieldName} because it was already declared as type: @{[$typeRec // '']}"
  }

  my $found;
  if (not ref $jsonType and ref ($found = $JSON_TYPES{$jsonType})) {
    # If given $jsonType is a typename string and actual entry is a reference,
    # we can weaken it.
    $typeRec->{$fieldName} = $found;
    Scalar::Util::weaken($typeRec->{$fieldName});
  } else {
    $typeRec->{$fieldName} = $pack->intern_json_type($jsonType);
  }
}


sub build_json_type {
  my ($pack, $typeSpec) = @_;
  if (not defined $typeSpec) {
    Carp::croak "json_type is undef!";
  }
  elsif (not ref $typeSpec) {
    if (defined (my $found = $JSON_TYPES{$typeSpec})) {
      # Note: weakening here does not take effect.
      $found;
    } elsif (my $sub = $pack->can(my $longName = "JSON_TYPE_".$typeSpec)) {
      $sub->();
    } else {
      Carp::croak "Unknown JSON_TYPE name: $typeSpec";
    }
  }
  elsif (ref $typeSpec eq 'ARRAY') {
    my ($keyword, @args) = @$typeSpec;
    $pack->$keyword(map {$pack->build_json_type($_)} @args);
  }
  elsif (ref $typeSpec eq 'HASH') {
    my %spec;
    foreach my $key (keys %$typeSpec) {
      $spec{$key} = $pack->build_json_type($typeSpec->{$key});
    }
    \%spec;
  }
}

1;
