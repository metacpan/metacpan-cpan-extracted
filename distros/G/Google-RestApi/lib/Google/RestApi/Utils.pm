package Google::RestApi::Utils;

use strict;
use warnings;

our $VERSION = '0.8';

use feature 'state';

use autodie;
use File::Spec::Functions;
use File::Basename;
use Hash::Merge;
use Log::Log4perl qw(:easy);
use Type::Params qw(compile_named compile);
use Types::Standard qw(Str StrMatch HashRef Any slurpy);
use YAML::Any qw(Dump LoadFile);

no autovivification;

use Exporter qw(import);
our @EXPORT_OK = qw(
  named_extra
  merge_config_file resolve_config_file_path
  bool
  dim dims dims_all
  cl_black cl_white
  strip
);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

# used by validation with type::params.
# similar to allow_extra in params::validate, simply returns the
# extra key/value pairs we aren't interested in in the checked
# argument hash.
sub named_extra {
  state $check = compile_named(
    _extra_   => HashRef,
    validated => slurpy HashRef,
  );
  my $p = $check->(@_);
  my $extra = delete $p->{_extra_};

  my %p;
  %p = %{ $p->{validated} } if $p->{validated};  # these are validated by the caller.
  @p{ keys %$extra } = values %$extra;  # stuff back the ones the caller wasn't interested in.
  return \%p;
}

sub merge_config_file {
  state $check = compile_named(
    config_file => Str->where( '-f -r $_' ), { optional => 1 },
    _extra_     => slurpy Any,
  );
  my $passed_config = named_extra($check->(@_));

  my $config_file = $passed_config->{config_file};
  return $passed_config if !$config_file;

  my $config_from_file = eval { LoadFile($config_file); };
  LOGDIE "Unable to load config file '$config_file': $@" if $@;

  # left_precedence, the passed config wins over anything in the file.
  # can't merge coderefs, error comes from Storable buried deep in hash::merge.
  my $merged_config = Hash::Merge::merge($passed_config, $config_from_file);
  TRACE("Config used:\n". Dump($merged_config));

  return $merged_config;
}

# a standard way to store file names in a config and resolve them
# to a full path. can be used in Auth configs, possibly others.
# see sub RestApi::auth for more.
sub resolve_config_file_path {
  state $check = compile(HashRef, Str);
  my ($config, $file_key) = $check->(@_);

  my $config_file = $config->{$file_key} or return;
  return $config_file if -f $config_file;

  my $full_file_path;
  if ($file_key ne 'config_file' && $config->{config_file}) {
    my $dir = dirname($config->{config_file});
    my $path = catfile($dir, $config_file);
    $full_file_path = $path if -f $path
  }

  if (!$full_file_path) {
    my $dir = $config->{config_dir};
    if ($dir) {
      my $path = catfile($dir, $config_file);
      $full_file_path = $path if -f $path
    }
  }
  
  LOGDIE("Unable to resolve config file '$file_key => $config_file' to a full file path")
    if !$full_file_path;

  # action at a distance, but is convenient to stuff the real file name in the config here.
  $config->{$file_key} = $full_file_path;
  
  return $full_file_path;
}

# changes perl boolean to json boolean.
sub bool {
  my $bool = shift;
  return 'true' if !defined $bool;  # bold() should turn on bold.
  $bool =~ s/^true$/true/i;
  $bool =~ s/^false$/false/i;
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

sub strip {
  my $p = shift // '';
  $p =~ s/^\s+|\s+$//g;
  return $p;
}

1;
