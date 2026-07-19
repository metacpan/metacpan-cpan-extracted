use 5.014;
use strict;
use warnings;

use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptions);
use POSIX qw(strftime);

my $iterations = 200;
my $outdir;

GetOptions(
  'iterations=i' => \$iterations,
  'outdir=s' => \$outdir,
) or die "Usage: $0 [--iterations N] [--outdir DIR]\n";

my $root = abs_path(getcwd());
$outdir ||= File::Spec->catdir($root, 'profile', 'nytprof', strftime('%Y%m%d-%H%M%S', localtime));
make_path($outdir);

my @cases = (
  [qw(simple_scalar upstream_ast upstream_string houtou_facade_ast houtou_facade_string houtou_prepared_ir houtou_compiled_ir houtou_xs_ast houtou_xs_string)],
  [qw(nested_variable_object upstream_ast upstream_string houtou_facade_ast houtou_facade_string houtou_prepared_ir houtou_compiled_ir houtou_xs_ast houtou_xs_string)],
  [qw(list_of_objects upstream_ast upstream_string houtou_facade_ast houtou_facade_string houtou_prepared_ir houtou_compiled_ir houtou_xs_ast houtou_xs_string)],
  [qw(abstract_with_fragment upstream_ast upstream_string houtou_facade_ast houtou_facade_string houtou_prepared_ir houtou_compiled_ir houtou_xs_ast houtou_xs_string)],
  [qw(async_scalar upstream_ast upstream_string houtou_facade_ast houtou_facade_string houtou_prepared_ir houtou_compiled_ir)],
  [qw(async_list upstream_ast upstream_string houtou_facade_ast houtou_facade_string houtou_prepared_ir houtou_compiled_ir)],
);

my @generated;
for my $row (@cases) {
  my ($case_name, @targets) = @$row;
  for my $target_name (@targets) {
    my $run_dir = File::Spec->catdir($outdir, $case_name, $target_name);
    my $raw_file = File::Spec->catfile($run_dir, 'nytprof.out');
    my $html_dir = File::Spec->catdir($run_dir, 'html');
    my $profile_stdout = File::Spec->catfile($run_dir, 'profile.stdout');
    my $profile_stderr = File::Spec->catfile($run_dir, 'profile.stderr');
    my $html_stdout = File::Spec->catfile($run_dir, 'nytprofhtml.stdout');
    my $html_stderr = File::Spec->catfile($run_dir, 'nytprofhtml.stderr');
    make_path($run_dir);

    run(
      {
        PATH => File::Spec->catdir($root, 'local', 'bin') . ':' . ($ENV{PATH} // ''),
        PERL5LIB => File::Spec->catdir($root, 'local', 'lib', 'perl5')
          . (($ENV{PERL5LIB} && length $ENV{PERL5LIB}) ? ':' . $ENV{PERL5LIB} : ''),
        NYTPROF => "file=$raw_file:start=begin",
      },
      [ 'perl', '-d:NYTProf', 'util/profile-execution-target.pl',
        '--case', $case_name,
        '--target', $target_name,
        '--iterations', $iterations,
      ],
      $profile_stdout,
      $profile_stderr,
    );

    run(
      {
        PATH => File::Spec->catdir($root, 'local', 'bin') . ':' . ($ENV{PATH} // ''),
        PERL5LIB => File::Spec->catdir($root, 'local', 'lib', 'perl5')
          . (($ENV{PERL5LIB} && length $ENV{PERL5LIB}) ? ':' . $ENV{PERL5LIB} : ''),
      },
      [ 'nytprofhtml', '--file', $raw_file, '--out', $html_dir ],
      $html_stdout,
      $html_stderr,
    );

    push @generated, [ $case_name, $target_name ];
  }
}

my $readme = File::Spec->catfile($outdir, 'README.md');
open my $fh, '>', $readme or die "open $readme: $!";
print {$fh} "# NYTProf Snapshot\n\n";
print {$fh} "Generated with `util/generate-nytprof-snapshot.pl --iterations $iterations`.\n\n";
for my $entry (@generated) {
  my ($case_name, $target_name) = @$entry;
  print {$fh} "- `$case_name / $target_name`: `$case_name/$target_name/html/index.html`\n";
}
close $fh;

print "$outdir\n";

sub run {
  my ($env, $argv, $stdout_path, $stderr_path) = @_;

  open my $stdout_fh, '>', $stdout_path or die "open $stdout_path: $!";
  open my $stderr_fh, '>', $stderr_path or die "open $stderr_path: $!";

  my $pid = fork();
  die "fork failed: $!" unless defined $pid;

  if ($pid == 0) {
    open STDOUT, '>&', $stdout_fh or die "dup STDOUT: $!";
    open STDERR, '>&', $stderr_fh or die "dup STDERR: $!";
    local %ENV = (%ENV, %$env);
    exec @$argv or die "exec failed: @$argv";
  }

  waitpid($pid, 0);
  my $exit = $? >> 8;
  close $stdout_fh;
  close $stderr_fh;
  die "command failed ($exit): @$argv\n" if $exit != 0;
}
