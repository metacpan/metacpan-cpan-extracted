use strict;
use warnings;
use Test::More;

use Cwd qw( abs_path );
use File::Basename qw( dirname );
use File::Find ();
use Module::Metadata ();

# THE CLAIM THIS TEST MAKES (stated up front, so that a future change has to
# say whether it keeps this claim or replaces it):
#
#   "No package this distribution ships is shipped by the current IO-K8s."
#
# A tombstone is only right for a name IO-K8s has stopped shipping. Both
# distributions install into the same tree, so a name present in both is the
# same file path twice and whichever is installed LAST wins. Installing this
# dist over a current IO-K8s then replaces a working class with a stub that
# dies on load -- and that names a "replacement" for a class that is not gone.
#
# It can happen without anyone touching this repository: IO-K8s brings a name
# back. The 76-name "*List" sweep once included the two meta.v1 discovery
# Kinds APIGroupList and APIResourceList; IO-K8s 1.106 shipped both again as
# real classes, and from that release on the two tombstones were a trap.
# Nothing in a tombstone can notice that by itself, and t/01-tombstones.t
# stays green throughout, because the stub still dies exactly as asked. This
# guard is what makes it loud.
#
# Where "the current IO-K8s" is read from -- first hit wins, never the
# network:
#
#   1. $ENV{IO_K8S_LIB}, an explicit lib directory.
#   2. A checkout named "io-k8s-p5" next to this one. Looked for up to three
#      levels up, so it is also found from inside a dzil build directory
#      (<repo>/IO-K8s-Deprecated-X.Y, <repo>/.build/<id>) -- "dzil test" and
#      "dzil release" are when this guard matters most.
#   3. An installed IO::K8s in @INC.
#
# With none of them there is nothing to compare against, and the test skips.
#
# An installed tree needs three precautions a checkout does not:
#
#   * What IO-K8s ships is what its .packlist lists, never what happens to
#     lie in the tree. An installer does not delete files a newer release no
#     longer brings, so an upgraded site_perl keeps the classes of every older
#     IO-K8s (InitializerConfigurationList and friends) although the current
#     one does not ship them. Only the files listed in the .packlist of the
#     installed IO-K8s (auto/IO/K8s/.packlist in @INC) count; an installed
#     IO::K8s without a .packlist that lists its IO/K8s.pm has no reliable
#     list of files, and the test skips.
#
#   * It is shared with an installed copy of THIS distribution, whose stubs
#     sit in the very same directories. They are not IO-K8s shipping the name
#     -- and they are not in IO-K8s's .packlist, so they never enter the
#     comparison. A stub that did overwrite a file IO-K8s ships still sits in
#     that .packlist and is reported as the collision it is. Every tombstone
#     must still die the way $TOMBSTONE_RE expects -- unconditionally, at the
#     top level, "die __PACKAGE__ ..." at the start of a line -- which is
#     asserted below.
#
#   * It may be OLD. An IO-K8s from before the removals still ships the
#     tombstoned names, by design -- that is the very release the takeover is
#     aimed at, and it says nothing about the current IO-K8s. So an installed
#     IO::K8s only counts when it is at least as new as this distribution,
#     whose version is by policy above the last IO-K8s release that shipped
#     any tombstoned name (VERSION POLICY in IO::K8s::Deprecated). An older
#     one skips.
#
# A checkout gets neither: it IS the current IO-K8s, so a stale one fails
# loudly instead of being argued away.

my $TOMBSTONE_RE = qr/^die __PACKAGE__\b/;
my $MAIN_MODULE  = 'IO/K8s/Deprecated.pm';
my $CHECKOUT     = 'io-k8s-p5';

my $ROOT    = abs_path(dirname(__FILE__).'/..');
my $LIB_DIR = $ROOT.'/lib';

# What one module file declares in its CODE. POD and everything after
# __END__/__DATA__ are skipped: a "package My::App;" in a SYNOPSIS is an
# example, not a shipped name.
sub scan_file {
  my ( $file ) = @_;
  open my $fh, '<', $file or BAIL_OUT('cannot read '.$file.': '.$!);
  my ( @packages, $in_pod, $tombstone );
  while (my $line = <$fh>) {
    last if $line =~ /^__(?:END|DATA)__\s*$/;
    if ($line =~ /^=cut\b/)    { $in_pod = 0; next }
    if ($line =~ /^=[a-zA-Z]/) { $in_pod = 1; next }
    next if $in_pod;
    $tombstone = 1 if $line =~ $TOMBSTONE_RE;
    push @packages, $1
      while $line =~ /(?:^|[;{}])\s*package\s+([A-Za-z_][\w:]*)\s*(?=[;{]|v?[0-9])/g;
  }
  close $fh;
  return { packages => \@packages, tombstone => $tombstone };
}

sub scan_module {
  my ( $lib, $file ) = @_;
  my $scan = scan_file($file);
  $scan->{file} = $file;
  $scan->{rel}  = substr($file, length($lib) + 1);
  return $scan;
}

# Every *.pm below $lib.
sub scan_tree {
  my ( $lib ) = @_;
  my @modules;
  File::Find::find(
    {
      no_chdir => 1,
      wanted   => sub {
        push @modules, scan_module($lib, $File::Find::name)
          if /\.pm\z/ && -f $_;
      },
    },
    $lib,
  );
  return sort { $a->{rel} cmp $b->{rel} } @modules;
}

# The files the installed IO-K8s lists in its .packlist, below $lib. The
# .packlist of a pure-Perl dist lives in the arch directory, so every @INC
# entry is searched; one counts only when it lists $lib/IO/K8s.pm itself.
# Returns an empty list when there is no such .packlist.
sub packlist_files {
  my ( $lib ) = @_;
  my $root = abs_path($lib);
  for my $inc ( grep { !ref } @INC ) {
    my $packlist = $inc.'/auto/IO/K8s/.packlist';
    next unless -f $packlist;
    open my $fh, '<', $packlist or next;
    my %listed;
    while (my $line = <$fh>) {
      chomp $line;
      1 while $line =~ s/ \w+=\S*\z//;    # "path type=link from=..." entries
      next unless $line =~ /\.pm\z/ && -f $line;
      my $path = abs_path($line);
      $listed{$path} = 1 if defined $path;
    }
    close $fh;
    next unless $listed{ $root.'/IO/K8s.pm' };
    return grep { index($_, $root.'/') == 0 } sort keys %listed;
  }
  return;
}

sub io_k8s_version {
  my ( $lib ) = @_;
  return eval { Module::Metadata->new_from_file($lib.'/IO/K8s.pm')->version('IO::K8s') };
}

sub find_io_k8s {
  if (defined $ENV{IO_K8S_LIB} && length $ENV{IO_K8S_LIB}) {
    ( my $lib = $ENV{IO_K8S_LIB} ) =~ s{/+\z}{};
    # Asked for explicitly: pointing nowhere must not end in a green skip.
    BAIL_OUT('IO_K8S_LIB='.$ENV{IO_K8S_LIB}.' holds no IO/K8s.pm')
      unless -e $lib.'/IO/K8s.pm';
    return ( 'IO_K8S_LIB', $lib );
  }
  my $dir = $ROOT;
  for ( 1 .. 3 ) {
    $dir = dirname($dir);
    my $lib = $dir.'/'.$CHECKOUT.'/lib';
    return ( 'checkout', $lib ) if -e $lib.'/IO/K8s.pm';
  }
  for my $inc ( grep { !ref } @INC ) {
    ( my $lib = $inc ) =~ s{/+\z}{};
    return ( 'installed', $lib ) if -e $lib.'/IO/K8s.pm';
  }
  return;
}

# A guard that quietly checks nothing is worse than no guard: neither a
# missing lib/ nor an empty scan may look like success.
BAIL_OUT('no lib directory at '.$LIB_DIR) unless -d $LIB_DIR;

my @own = scan_tree($LIB_DIR);
BAIL_OUT('found no packages under '.$LIB_DIR.' -- guard is inoperative')
  unless grep { @{ $_->{packages} } } @own;

my ( $source, $main_lib ) = find_io_k8s();

plan skip_all => 'IO-K8s not available to compare against: no '.$CHECKOUT
  .' checkout next to this one, no IO::K8s installed, IO_K8S_LIB not set'
  unless defined $main_lib;

my $main_version = io_k8s_version($main_lib);
my $installed    = $source eq 'installed';

if ($installed) {
  my $own_version = eval {
    Module::Metadata->new_from_file($LIB_DIR.'/'.$MAIN_MODULE)
      ->version('IO::K8s::Deprecated');
  };
  plan skip_all => 'cannot read a version from the installed IO::K8s in '.$main_lib
    unless defined $main_version && defined $own_version;
  plan skip_all => 'installed IO::K8s '.$main_version.' is older than this'
    .' distribution ('.$own_version.'): it predates the removals and says'
    .' nothing about the current IO-K8s'
    if $main_version < $own_version;
}

my @main;
if ($installed) {
  my @listed = packlist_files($main_lib);
  plan skip_all => 'the installed IO::K8s in '.$main_lib.' has no .packlist'
    .' listing its files (auto/IO/K8s/.packlist): files lying in the tree are'
    .' not evidence that IO-K8s ships them'
    unless @listed;
  @main = sort { $a->{rel} cmp $b->{rel} }
    map { scan_module(abs_path($main_lib), $_) } @listed;
}
else {
  @main = scan_tree($main_lib);
}

my ( %main_package, %main_path );
for my $module (@main) {
  $main_path{ $module->{rel} } = $module->{file};
  $main_package{$_} //= $module->{file} for @{ $module->{packages} };
}

BAIL_OUT('scan of '.$main_lib.' did not find package IO::K8s -- guard is inoperative')
  unless $main_package{'IO::K8s'};

my $main_label = 'IO-K8s '.( defined $main_version ? $main_version : '(no version)' )
  .' ('.$source.': '.$main_lib.')';
note('comparing '.scalar(@own).' modules against '.$main_label.', '
  .scalar(keys %main_package).' packages');

my @unmarked = map { $_->{rel} }
  grep { !$_->{tombstone} && $_->{rel} ne $MAIN_MODULE } @own;
is_deeply(\@unmarked, [],
  'every tombstone has the die line an installed copy is recognised by')
  or diag('expected a line starting with: die __PACKAGE__');

for my $module (@own) {
  my %hit;
  $hit{ $main_path{ $module->{rel} } } = 1 if $main_path{ $module->{rel} };
  $hit{ $main_package{$_} } = 1
    for grep { $main_package{$_} } @{ $module->{packages} };

  my $name = join(', ', @{ $module->{packages} }) || $module->{rel};
  ok(!%hit, $name.' is not shipped by IO-K8s')
    or diag($name." is shipped by BOTH distributions.\n"
      .'  here:    lib/'.$module->{rel}."\n"
      .join('', map { '  IO-K8s:  '.$_."\n" } sort keys %hit)
      .'  against: '.$main_label."\n"
      ."Whichever is installed last overwrites the other. A name IO-K8s ships\n"
      ."is not an orphan: remove the tombstone here (the file, its line in\n"
      ."IO::K8s::Deprecated's POD and in t/01-tombstones.t).");
}

done_testing;
