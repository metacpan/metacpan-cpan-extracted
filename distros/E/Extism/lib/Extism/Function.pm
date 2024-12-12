package Extism::Function v0.3.0;

use 5.016;
use strict;
use warnings;
use feature 'say';
use Extism::XS qw(
    function_new function_free function_set_namespace CopyToPtr);
use Extism::CurrentPlugin;
use Devel::Peek qw(Dump);
use Exporter 'import';
use Carp qw(croak);
use Data::Dumper;

use constant {
  Extism_I32 => 0,
  Extism_I64 => 1,
  Extism_F32 => 2,
  Extism_F64 => 3,
  Extism_V128 => 4,
  Extism_FuncRef => 5,
  Extism_ExternRef => 6,
  # not a part of libextism, handled by this sdk
  Extism_String => 7
};

our @EXPORT_OK = qw(
  Extism_I32
  Extism_I64
  Extism_F32
  Extism_F64
  Extism_V128
  Extism_FuncRef
  Extism_ExternRef
  Extism_String
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

# [PTR_LENGTH, PTR_PAIR, SZ, JSON_PTR_LENGTH, JSON_PTR_PAIR, JSON_SZ, U8ARRAY_PTR_LENGTH, U8ARRAY_]

sub new {
    my ($class, $name, $input_types, $output_types, $func, $namespace) = @_;
    my %hostdata = (func => $func);
    my @inputs = @{$input_types};
    my @outputs = @{$output_types};
    my %realtype = (inputs => [], outputs => []);
    foreach my $input (@inputs) {
      my $type;
      if ($input == Extism_String) {
        $type = $input;
        $input = Extism_I64;
      }
      push @{$realtype{inputs}}, $type;
    }
    foreach my $output (@outputs) {
      my $type;
      if ($output == Extism_String) {
        $type = $output;
        $output = Extism_I64;
      }
      push @{$realtype{outputs}}, $type;
    }
    $hostdata{conversions} = \%realtype;
    my $input_types_array = pack('L*', @inputs);
    my $input_types_ptr = unpack('Q', pack('P', $input_types_array));
    my $output_types_array = pack('L*', @outputs);
    my $output_types_ptr = unpack('Q', pack('P', $output_types_array));
    my $function = function_new($name, $input_types_ptr, scalar(@inputs), $output_types_ptr, scalar(@outputs), \%hostdata);
    $function or croak("Failed to create function, is the name valid?");
    my $functionref = bless \$function, $class;
    defined $namespace and $functionref->set_namespace($namespace);
    return $functionref;
}

sub DESTROY {
    my ($self) = @_;
    $$self or return;
    function_free($$self);
}

sub set_namespace {
    my ($self, $namespace) = @_;
    function_set_namespace($$self, $namespace);
}

sub load_raw_array {
  my ($ptr, $elm_size, $n) = @_;
  $n or return [];
  my $input_array = unpack('P'.($elm_size * $n), pack('Q', $ptr));
  my @input_packed = unpack("(a$elm_size)*", $input_array);
  return \@input_packed;
}

sub host_function_caller_perl {
    my ($current_plugin, $input_ptr, $input_len, $output_ptr, $output_len, $user_data) = @_;
    local $Extism::CurrentPlugin::instance = $current_plugin;
    my $input_packed = load_raw_array($input_ptr, 16, $input_len);
    my @input = map {
      my $type = unpack('L', $_);
      my $value = substr($_, 8);
      if ($type == Extism_I32) {
        $value = unpack('l', $value);
      } elsif($type == Extism_I64) {
        $value = unpack('q', $value);
      } elsif($type == Extism_F32) {
        $value = unpack('f', $value);
      } elsif($type == Extism_F64) {
        $value = unpack('F', $value);
      }
      $value
    } @{$input_packed};
    {
        my $i = 0;
        foreach my $item (@{$user_data->{conversions}{inputs}}) {
          if (defined $item && $item == Extism_String) {
            $input[$i] = Extism::CurrentPlugin::memory_load_from_handle($input[$i]);
          }
          $i++;
        }
    }
    my @outputs = $user_data->{func}(@input);
    scalar(@outputs) <= $output_len or croak "host function returned too many outputs";
    $output_len or return;
    {
        my $i = 0;
        foreach my $item (@{$user_data->{conversions}{outputs}}) {
          if (defined $item && $item == Extism_String) {
            $outputs[$i] = Extism::CurrentPlugin::memory_alloc_and_store($outputs[$i]);
          }
          $i++;
        }
    }
    my $outputs_packed = load_raw_array($output_ptr, 16, $output_len);
    my @output_types = map { unpack('L', $_) } @{$outputs_packed};
    my $output_array = unpack('P'.(16 * $output_len), pack('Q', $output_ptr));
    my $outputi = 0;
    foreach my $type (@output_types) {
      my $value;
      if ($type == Extism_I32) {
        $value = pack('l', $outputs[$outputi]);
      } elsif($type == Extism_I64) {
        $value = pack('q', $outputs[$outputi]);
      } elsif($type == Extism_F32) {
        $value = pack('f', $outputs[$outputi]);
      } elsif($type == Extism_F64) {
        $value = pack('F', $outputs[$outputi]);
      } else {
        $value =  "\x00" x 8;
      }
      substr($output_array, 16*$outputi+8, 8, $value);
    }
    CopyToPtr($output_array, $output_ptr, length($output_array));
}

1; # End of Extism::Function
