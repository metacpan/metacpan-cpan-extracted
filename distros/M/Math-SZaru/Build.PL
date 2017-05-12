#!/usr/bin/perl -w
use strict;
use Module::Build::WithXSpp;
use File::Copy qw(copy);
use ExtUtils::CChecker;
use Capture::Tiny qw(capture_merged);
use File::Find qw(find);

my $build = Module::Build::WithXSpp->new(
  module_name     => 'Math::SZaru',
  license         => 'perl',
  requires        => {
  },
  configure_requires => {
    'Devel::CheckLib' => 0,
    'ExtUtils::CChecker' => 0,
    'File::Copy' => 0,
    'Capture::Tiny' => 0,
    'File::Find' => 0,
  },
  extra_compiler_flags => [qw(-Isrc -Ipublic -I.)],
  extra_linker_flags => [qw(-lcrypto)],
  extra_typemap_modules => {
    'ExtUtils::Typemaps::Default' => '0.01',
  },
  early_includes => [qw(
    "myconfig.h"
    "myinit.h"
    "szaru.h"
  )],
  cpp_source_dirs  => [],
  cpp_source_files => [map "src/$_", qw(emitters/szlunique.cc emitters/top.cc emitters/quantile.cc utilities/hashutils.cc)],
);

$build->create_build_script;


# Now, this is truly evil, but who in his right mind uses a "config.h" file?
SCOPE: {
  my @files;
  find({
    wanted => sub { push @files, $_ if !/\.o(?:bj)?$/ and -f $_; },
    no_chdir => 1,
    follow => 1,
  }, 'src');

  system($^X, '-pi', '-e', 's/"config.h"/"myconfig.h"/g', @files);
}

# Sue me
for (qw(ppport.h myinit.h myxshead.h)) {
  copy($_, "src");
  $build->add_to_cleanup("src/$_");
}

my %opt = ExtUtils::CppGuess->new->module_build_options();
my $cc = ExtUtils::CChecker->new;

# The grep/split is fundamentally WRONG, not portable, and insulting, but can't be avoided right now
$cc->push_extra_compiler_flags(grep /\S/, split /\s+/, $opt{extra_compiler_flags});
$cc->push_extra_linker_flags(grep /\S/, split /\s+/, $opt{extra_linker_flags});

$build->add_to_cleanup("src/myconfig.h");

check_hash($cc);

# ported from wscript of SZaru
sub check_hash {
  my $cc = shift;
  print "Checking for the location of hash_map\n";
  foreach my $location (qw(tr1/unordered_map ext/hash_map hash_map)) {
    foreach my $namespace ("std::tr1", "__gnu_cxx", "", "std", "stdext") {
      foreach my $name ("unordered_map", "hash_map") {
        if (check_hash_snippet($cc, $location, $namespace, $name)) {
          define_config($cc, $location, $namespace, $name);
          return;
        }
      }
    }
  }
  die "Could not find an STL hash_map\n";
}

sub check_hash_snippet {
  my ($cc, $location, $namespace, $name) = @_;

  my $fragment = qq!
    #include <$location>
    const ${namespace}::${name}<int, int> t;
    int main(){ t.find(1); }
  !;

  return try_compile_run_silently($cc, source => $fragment);
}

sub define_config {
  my ($cc, $location, $namespace, $name) = @_;

  my $hash_map_header = "<$location>";
  (my $hash_set_header = $hash_map_header) =~ s/map/set/g;

  (my $hash_set_class = $name) =~ s/map/set/g;

  open my $fh, ">", "src/myconfig.h" or die $!;
  print $fh <<'HERE';
#ifndef SZARU_XS_MYDEFINES_H_
#define SZARU_XS_MYDEFINES_H_
HERE

  my @defines = (
    ['HAVE_HASH_MAP'],
    ['HAVE_HASH_SET'],
    [HASH_MAP_H     => $hash_map_header],
    [HASH_SET_H     => $hash_set_header],
    [HASH_MAP_CLASS => $name],
    [HASH_SET_CLASS => $hash_set_class],
    [HASH_NAMESPACE => $namespace],
  );

  print $fh "#define $_->[0]" . (defined $_->[1] ? " " . $_->[1] : "") . "\n" for @defines;

  print $fh "\n#endif\n";
  close $fh;
}


sub try_compile_run_silently {
  my $cc = shift;
  my @args = @_;
  my $ok;
  my $output = capture_merged {
    $ok = $cc->try_compile_run(@args);
  };
  # warn $output

  return $ok;
}
