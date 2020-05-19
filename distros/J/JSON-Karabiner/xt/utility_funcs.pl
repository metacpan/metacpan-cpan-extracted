use Carp;
use File::HomeDir;
use Test::Most;
use File::Slurp qw(read_file);

my $home = File::HomeDir->home;
my $script_dir = 'xt/karabiner_generator_scripts/';
my $expected_output_dir = "$script_dir/expected_output/";
my $karabiner_dir = "$home/.config/karabiner/assets/complex_modifications/";

sub run_script {
  my $script = shift;

  my $script_path = $script_dir . $script;
  croak "Could not find script file: $script_path" unless -f $script_path;
  my $failed = system($script_dir . $script);
  croak "Failed to run generator script: $?" if $failed;
}

sub gets_output {
  my $file_prefix = shift;
  $file_prefix = "TEST_$file_prefix";
  croak 'no $file_prefix passed' unless $file_prefix;

  unlink "$karabiner_dir$file_prefix.json";
  run_script("$file_prefix.pl");
  my $script_output = read_file "$karabiner_dir$file_prefix.json";
  my $expected_output = read_file "$expected_output_dir$file_prefix.json";
  unlink "$karabiner_dir$file_prefix.json";
  my $result = $script_output eq $expected_output;
  is ($result, 1, "$file_prefix script gives expected output");
  if ( ! $result ) {
    use Data::Dumper qw(Dumper);
    print Dumper $script_output;
  }
}

1;
