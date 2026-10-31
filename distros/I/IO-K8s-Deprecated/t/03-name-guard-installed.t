use strict;
use warnings;
use Test::More;

use Cwd qw( abs_path );
use File::Basename qw( dirname );
use File::Copy qw( copy );
use File::Find ();
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );

# t/02-name-guard.t, run against an INSTALLED IO::K8s, decides what that
# IO-K8s ships from its .packlist. This test builds throwaway installation
# trees and runs the guard against them, to pin that down:
#
#   * a class file lying in the tree that no .packlist lists is left over from
#     an older IO-K8s (an installer never deletes it) -- no collision;
#   * a class file the .packlist lists IS shipped by IO-K8s -- collision;
#   * without a .packlist there is nothing reliable to compare -- skip.

my $ROOT = abs_path(dirname(__FILE__).'/..');

# A copy of lib/ and the guard in a directory of their own, so that neither a
# sibling io-k8s-p5 checkout nor IO_K8S_LIB can answer instead of the tree.
my $dist = tempdir( CLEANUP => 1 ).'/dist';
make_path($dist.'/t');
copy($ROOT.'/t/02-name-guard.t', $dist.'/t/02-name-guard.t')
  or BAIL_OUT('cannot copy the guard: '.$!);
File::Find::find(
  {
    no_chdir => 1,
    wanted   => sub {
      my $rel = File::Spec->abs2rel($File::Find::name, $ROOT);
      if (-d $File::Find::name) { make_path($dist.'/'.$rel) }
      else { copy($File::Find::name, $dist.'/'.$rel) or BAIL_OUT("copy $rel: $!") }
    },
  },
  $ROOT.'/lib',
);

# A tombstone name to play with: first one in lib/.
my ( $victim ) = sort grep { m{^IO/K8s/(?!Deprecated\.pm)} }
  map { File::Spec->abs2rel($_, $ROOT.'/lib') }
  glob($ROOT.'/lib/IO/K8s/Api/*/*/*.pm');
BAIL_OUT('no tombstone found in lib/') unless $victim;
( my $package = $victim ) =~ s{/}{::}g;
$package =~ s/\.pm\z//;

sub write_file {
  my ( $file, $content ) = @_;
  make_path(dirname($file));
  open my $fh, '>', $file or BAIL_OUT('cannot write '.$file.': '.$!);
  print {$fh} $content;
  close $fh;
}

# An installation tree as ExtUtils::MakeMaker leaves it: modules in lib,
# .packlist in the arch directory beside it. $listed names the files the
# .packlist lists besides IO/K8s.pm.
sub install_tree {
  my ( $listed ) = @_;
  my $tree = tempdir( CLEANUP => 1 );
  my ( $lib, $arch ) = ( $tree.'/lib', $tree.'/arch' );
  write_file($lib.'/IO/K8s.pm', "package IO::K8s;\nour \$VERSION = '9999.000';\n1;\n");
  # the file lies in the tree in every case: left over, or shipped
  write_file($lib.'/'.$victim, "package $package;\nour \$VERSION = '1.100';\n1;\n");
  if ($listed) {
    write_file($arch.'/auto/IO/K8s/.packlist',
      join('', map { $lib.'/'.$_."\n" } 'IO/K8s.pm', @{$listed}));
  }
  else { make_path($arch) }
  return ( $lib, $arch );
}

sub run_guard {
  my ( $lib, $arch ) = @_;
  local $ENV{PERL5LIB} = join(':', $lib, $arch);
  delete local $ENV{IO_K8S_LIB};
  my $out = qx{ cd "$dist" && "$^X" -I"$dist/lib" t/02-name-guard.t 2>&1 };
  return ( $? >> 8, $out );
}

{
  my ( $status, $out ) = run_guard(install_tree([]));
  is($status, 0, 'a class file no .packlist lists is not a collision')
    or diag($out);
  like($out, qr/^ok \d+ - \Q$package\E is not shipped by IO-K8s$/m,
    'the guard compared the class') or diag($out);
  unlike($out, qr/^1\.\.0/m, 'the guard did not skip');
}

{
  my ( $status, $out ) = run_guard(install_tree([ $victim ]));
  isnt($status, 0, 'a class file the .packlist lists is a collision');
  like($out, qr/\Q$package\E is shipped by BOTH distributions/,
    'the collision names the class') or diag($out);
}

{
  my ( $status, $out ) = run_guard(install_tree(undef));
  is($status, 0, 'an installed IO::K8s without a .packlist does not fail');
  like($out, qr/^1\.\.0 # SKIP .*no \.packlist/m,
    'it skips and says why') or diag($out);
}

done_testing;
