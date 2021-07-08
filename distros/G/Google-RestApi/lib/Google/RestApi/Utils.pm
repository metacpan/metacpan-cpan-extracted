package Google::RestApi::Utils;

use strict;
use warnings;

our $VERSION = '0.7';

use feature 'state';

use autodie;
use File::Basename;
use Hash::Merge;
use Log::Log4perl qw(:easy);
use Type::Params qw(compile_named compile);
use Types::Standard qw(Str StrMatch Any slurpy);
use YAML::Any qw(Dump LoadFile);

no autovivification;

use Exporter qw(import);
our @EXPORT_OK = qw(named_extra config_file resolve_config_file strip bool dim dims dims_all cl_black cl_white);

# similar to allow_extra in params::validate, simply returns the
# extra key/value pairs we aren't interested in in the checked
# argument hash.
sub named_extra {
  my $p = shift;
  my $extra = delete $p->{_extra_}
    or LOGDIE "No _extra_ key found in hash";
  @$p{ keys %$extra } = values %$extra;
  return $p;
}

sub config_file {
  state $check = compile_named(
    config_file => Str, { optional => 1 },
    _extra_     => slurpy Any,
  );
  my $merged_config = named_extra($check->(@_));

  my $config_file = $merged_config->{config_file};
  if ($config_file) {
    my $config = eval { LoadFile($config_file); };
    LOGDIE "Unable to load config file '$config_file': $@" if $@;
    $merged_config = Hash::Merge::merge($merged_config, $config);
  }

  return $merged_config;
}

# a standard way to store file names in a config and resolve them
# to a full path. can be used in Auth configs, possibly others.
# see sub RestApi::auth for more.
sub resolve_config_file {
  my ($file_key, $config) = @_;

  my $file_path = $config->{$file_key}
    or LOGDIE "No config file name found for '$file_key':\n", Dump($config);

  # if file name is a simple file name (no path) then assume it's in the
  # same directory as the config file.
  if (!-e $file_path) {
    my $config_file = $config->{config_file} || $config->{parent_config_file};
    $file_path = dirname($config_file) . "/$file_path"
      if $config_file;
  }

  LOGDIE "Config file '$file_key' not found or is not readable:\n", Dump($config)
    if !-f -r $file_path;

  return $file_path;
}

sub strip {
  my $p = shift // '';
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

sub cl_black { { red => 0, blue => 0, green => 0, alpha => 1 }; }
sub cl_white { { red => 1, blue => 1, green => 1, alpha => 1 }; }

1;
