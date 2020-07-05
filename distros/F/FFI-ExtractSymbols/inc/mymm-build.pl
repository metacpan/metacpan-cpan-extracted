use strict;
use warnings;
use FFI::CheckLib qw( find_lib );
use FFI::Build;
use File::ShareDir::Dist::Install qw( install_config_set install_config_get );

my $config = install_config_get 'FFI-ExtractSymbols';

my $build = FFI::Build->new(
  'test',
  source    => ['t/ffi/*.c'],
  dir       => 't/ffi',
  export    => ['my_function','my_variable'],
  verbose   => 2,
);

$build->build;

if($config->{'posix_nm'})
{
  my $lib = find_lib lib => 'test', symbol => 'my_function', libpath => 't/ffi';
  die "unable to find libtest!" unless defined $lib;

  my $nm = $config->{exe}->{nm};

  my @lines = `$nm -g -P $lib`;

  my $function = '';
  my $variable = '';

  foreach my $line (@lines)
  {
    if($line =~ /^(_?)my_function ([A-Za-z])/)
    {
      install_config_set 'FFI-ExtractSymbols', function_prefix => $1;
      install_config_set 'FFI-ExtractSymbols', function_code   => $2;
      $function = 1;
    }
    if($line =~ /^(_?)my_variable ([A-Za-z])/)
    {
      install_config_set 'FFI-ExtractSymbols', data_prefix => $1;
      install_config_set 'FFI-ExtractSymbols', data_code   => $2;
      $variable = 1;
    }
  }

  unless($function || $variable)
  {
    print STDERR "unable to find my_function from nm output\n" unless $function;
    print STDERR "unable to find my_variable from nm output\n" unless $variable;
    print STDERR "[out]\n";
    print STDERR $_ for @lines;
    die "missing some symbols in nm output scan";
  }
}
