package Google::RestApi::Utils;

use strict;
use warnings;

our $VERSION = '0.2';

use 5.010_000;

use autodie;
use Type::Params qw(compile);
use Types::Standard qw(StrMatch);
use YAML::Any qw(Dump);

no autovivification;

use Exporter qw(import);
our @EXPORT_OK = qw(named_extra strip bool dim dims dims_all);

# similar to allow_extra in params::validate, simply returns the
# extra key/value pairs we aren't interested in in the checked
# argument hash.
sub named_extra {
  my $p = shift;
  my $extra = delete $p->{_extra_}
    or die "No _extra_ key found in hash";
  @$p{ keys %$extra } = values %$extra;
  return $p;
}

sub strip {
  my $p = shift || '';
  $p =~ s/^\s+|\s+$//g;
  return $p;
}

# changes perl boolean to json boolean.
sub bool {
  my $bool = shift;
  return 'true' if !defined $bool;  # bold() should turn on bold.
  return $bool if $bool =~ /^(true|false)$/i;
  return $bool ? 'true' : 'false';  # converts bold(0) to 'false'.
}

# allows 'col' and 'row' internally instead of 'COLUMN' and 'ROW'.
# less shouting.
sub dim {
  state $check = compile(StrMatch[qr/^(col|row)/i]);
  my ($dim) = $check->(@_);
  return $dim =~ /^col/i ? "COLUMN" : "ROW";
}

sub dims {
  state $check = compile(StrMatch[qr/^(col|row)/i]);
  my ($dims) = $check->(@_);
  return $dims =~ /^col/i ? "COLUMNS" : "ROWS";
}

sub dims_all {
  my $dims = eval { dims(@_); };
  return $dims if $dims;
  state $check = compile(StrMatch[qr/^all/i]);
  ($dims) = $check->(@_);
  return "ALL";
}

1;
