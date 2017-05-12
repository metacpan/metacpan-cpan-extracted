#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";
use Git::Wrapper;
use version;
use Version::Next qw(next_version);
use Path::Tiny qw(path);
use Capture::Tiny qw(capture_stdout);
use JSON;
use CPAN::Changes;
use CPAN::Changes::Group::Dependencies::Stats;
use CPAN::Changes::Dependencies::Details;
use CPAN::Meta::Prereqs::Diff;
use CPAN::Meta;
use CHI;
use CHI::Driver::LMDB;
use LMDB_File qw( MDB_NOSYNC MDB_NOMETASYNC );
use Data::Serializer::Sereal;
use Sereal::Encoder;
my $git = Git::Wrapper->new('.');

my $build_master_version;

my $extension = Path::Tiny::cwd->stringify;
$extension =~ s/[^-\p{PosixAlnum}_]+/_/msxg;

my $cache_root = Path::Tiny::tempdir->sibling('dep_changes_cache')->child($extension);

$cache_root->mkpath;

my $s = Data::Serializer::Sereal->new( options => { encoder => Sereal::Encoder->new( { compress => 1, canonical => 1 } ), } );
my %CACHE_COMMON = (
  driver         => 'LMDB',
  root_dir       => $cache_root->stringify,
  expires_in     => '7d',
  cache_size     => '30m',
  key_serializer => $s,
  serializer     => $s,
  flags          => MDB_NOSYNC | MDB_NOMETASYNC,

  # STILL SEGVing
  single_txn => 1,
);

sub xnamespace {
  my (%args) = @_;
  my $ns_root = $cache_root->child( $args{namespace} );
  $ns_root->mkpath;
  $args{root_dir} = $ns_root->stringify;
  return %args;
}
my $get_sha_cache  = CHI->new( xnamespace( namespace => 'get_sha',       %CACHE_COMMON, ) );
my $tree_sha_cache = CHI->new( xnamespace( namespace => 'tree_sha',      %CACHE_COMMON, ) );
my $meta_cache     = CHI->new( xnamespace( namespace => 'meta_cache',    %CACHE_COMMON, ) );
my $diff_cache     = CHI->new( xnamespace( namespace => 'diff_cache',    %CACHE_COMMON, ) );
my $stat_cache     = CHI->new( xnamespace( namespace => 'stat_cache',    %CACHE_COMMON, ) );
my $release_cache  = CHI->new( xnamespace( namespace => 'release_cache', %CACHE_COMMON, ) );

sub END {
  undef $release_cache;
  undef $stat_cache;
  undef $diff_cache;
  undef $meta_cache;
  undef $tree_sha_cache;

  undef $get_sha_cache;

  print "Cleanup done\n";
}
use Try::Tiny qw( try catch );

sub rev_sha {
  my ($commit) = @_;
  my $rev;
  try {
    $rev = [ $git->rev_parse($commit) ]->[0];
  };
  return $rev;
}

sub tree_sha {
  my ( $sha, $path ) = @_;
  return $tree_sha_cache->compute(
    $sha, undef,
    sub {
      #*STDERR->print("Cache Miss for tree_sha $sha + $path\n");
      my $tree;

      try {
        $tree = [ $git->ls_tree( $sha, $path ) ]->[0];
      };
      return $tree;
    }
  );
}

sub file_sha {
  my ( $commit, $path ) = @_;
  my $rev = rev_sha($commit);
  return unless $rev;
  my $tree = tree_sha( $rev, $path );
  return unless $tree;
  my ( $left, $right ) = $tree =~ /^([^\t]+)\t(.*$)/;
  my ( $flags, $type, $sha ) = split / /, $left;
  return $sha;
}

sub get_sha {
  my ($sha) = @_;
  my $key = $sha;
  return $get_sha_cache->compute(
    $sha, undef,
    sub {
      #*STDERR->print("Cache Miss for get_sha $sha\n");
      return join qq[\n], $git->cat_file( '-p', $sha );
    }
  );
}

sub get_json_prereqs {
  my ($commitish) = @_;
  if ( $commitish !~ /\d\.\d/ ) {
    $commitish = rev_sha($commitish);
  }
  return $meta_cache->compute(
    $commitish,
    undef,
    sub {
      #*STDERR->print("Cache miss for $commitish metadata\n");
      my $sha1 = file_sha( $commitish, 'META.json' );
      if ( defined $sha1 and length $sha1 ) {
        return CPAN::Meta->load_json_string( get_sha($sha1) );
      }
      $sha1 = file_sha( $commitish, 'META.yml' );
      if ( defined $sha1 and length $sha1 ) {
        return CPAN::Meta->load_yaml_string( get_sha($sha1) );
      }
      return {};
    }
  );
}

sub get_prereq_diff {
  my ( $old, $new ) = @_;
  $old = rev_sha($old) if $old !~ /\d\.\d/;
  $new = rev_sha($new) if $new !~ /\d\.\d/;

  return $diff_cache->compute(
    $old . "\0" . $new,
    undef,
    sub {
      return CPAN::Meta::Prereqs::Diff->new(
        old_prereqs => get_json_prereqs($old),
        new_prereqs => get_json_prereqs($new),
      );
    }
  );
}

sub get_summary_diff {
  my ( $old, $new ) = @_;
  my ( $oldsha, $newsha ) = ( $old, $new );
  $oldsha = rev_sha($oldsha) . "\0" . ( $build_master_version || '0' )
    if $oldsha !~ /\d\.\d/;
  $newsha = rev_sha($newsha) . "\0" . ( $build_master_version || '0' )
    if $newsha !~ /\d\.\d/;
  return $stat_cache->compute(
    $oldsha . "\0" . $newsha . "\0" . $CPAN::Changes::Group::Dependencies::Stats::VERSION,
    undef,
    sub {
      my $pchanges = CPAN::Changes::Group::Dependencies::Stats->new(
        prelude      => [ 'Dependencies changed since ' . $old . ', see misc/*.deps* for details', ],
        prereqs_diff => scalar get_prereq_diff( $old, $new )
      );
      $pchanges->_diff_items;
      return $pchanges;
    }
  );
}

sub get_release_diff {
  my ( $changes, $old, $new, $params ) = @_;
  my ( $oldsha, $newsha ) = ( $old, $new );
  $oldsha = rev_sha($oldsha) . "\0" . ( $build_master_version || '0' )
    if $oldsha !~ /\d\.\d/;
  $newsha = rev_sha($newsha) . "\0" . ( $build_master_version || '0' )
    if $newsha !~ /\d\.\d/;
  my @keyparts;
  push @keyparts, 'phases=>', sort @{ $changes->phases };
  push @keyparts, 'types=>',  sort @{ $changes->types };
  push @keyparts, 'change_types' =>, sort @{ $changes->change_types };
  push @keyparts, 'preamble=>', $changes->preamble;
  push @keyparts, $oldsha, $newsha,
    $CPAN::Changes::Dependencies::Details::VERSION,
    $CPAN::Changes::Group::Dependencies::Details::VERSION;

  return $release_cache->compute(
    ( join qq[\0], @keyparts ),
    undef,
    sub {
      my $delta = get_prereq_diff( $old, $new );
      my $release_info = { %{$params}, prereqs_diff => $delta, };
      my $release_object = $changes->_mk_release($release_info);
      return $release_object;
    }
  );
}

my @tags;

my @lines;
eval { @lines = reverse $git->RUN( 'log', '--pretty=format:%d', 'releases' ) };
for my $line (@lines) {
  if ( $line =~ /\(tag:\s*([^ ),]+)/ ) {
    my $tag = $1;
    next if $tag =~ /-source$/;
    if ( not eval { version->parse($tag); 1 } ) {
      print "tag $tag skipped\n";
      next;
    }
    push @tags, $tag;

    #print "$tag\n";
    next;
  }
  if ( $line =~ /\(/ ) {
    print "Skipped decoration $line\n";
    next;
  }
}

if ( $ENV{V} ) {
  $build_master_version = $ENV{V};
}
else {
  $build_master_version = next_version( $tags[-1] );
}

if ( rev_sha('builds') ) {
  push @tags, 'builds';
}
elsif ( rev_sha('build/master') ) {
  warn "build/master is legacy, plz git branch -m build/master builds";
  push @tags, 'build/master';
}

my $standard_phases = ' (configure/build/runtime/test)';
my $all_phases      = ' (configure/build/runtime/test/develop)';

my $changes = CPAN::Changes::Dependencies::Details->new(
  preamble     => 'This file contains changes in REQUIRED dependencies for standard CPAN phases' . $standard_phases,
  change_types => [qw( Added Changed Removed )],
  phases       => [qw( configure build runtime test )],
  types        => [qw( requires )],
);

my $changes_opt = CPAN::Changes::Dependencies::Details->new(
  preamble     => 'This file contains changes in OPTIONAL dependencies for standard CPAN phases' . $standard_phases,
  change_types => [qw( Added Changed Removed )],
  phases       => [qw( configure build runtime test )],
  types        => [qw( recommends suggests )],
);
my $changes_all = CPAN::Changes::Dependencies::Details->new(
  preamble => 'This file contains ALL changes in dependencies in both REQUIRED / OPTIONAL dependencies for all phases'
    . $all_phases,
  change_types => [qw( Added Changed Removed )],
  phases       => [qw( configure build develop runtime test )],
  types        => [qw( requires recommends suggests )],
);
my $changes_dev = CPAN::Changes::Dependencies::Details->new(
  preamble     => 'This file contains changes to DEVELOPMENT dependencies only ( both REQUIRED and OPTIONAL )',
  change_types => [qw( Added Changed Removed )],
  phases       => [qw( develop )],
  types        => [qw( requires recommends suggests )],
);

my $master_changes = CPAN::Changes->load_string( path('./Changes')->slurp_utf8, next_token => qr/\{\{\$NEXT\}\}/ );
$ENV{PERL_JSON_BACKEND} = 'JSON';

while ( @tags > 1 ) {
  my ( $old, $new ) = ( $tags[-2], $tags[-1] );
  print "$old - $new\n";
  pop @tags;

  my $date;
  my $master_release;
  if ( $master_release = $master_changes->release($new) ) {
    $date = $master_release->date();
  }
  else {
    print "$new not on master Changelog";
    if ( $new eq 'builds' or $new eq 'build/master' ) {
      $master_release = [ $master_changes->releases ]->[-1];
      print " ... using " . $master_release->version . " instead \n";

      #('{{$NEXT}}');
    }
    else {
      print "\n";
    }

  }
  my $version = $new;
  if ( $new eq 'builds' or $new eq 'build/master' ) {
    $version = $build_master_version;
  }
  my $params = {
    version => $version,
    ( defined $date ? ( date => $date ) : () ),
  };

  if ($master_release) {
    my $pchanges = get_summary_diff( $old, $new );
    $master_release->attach_group($pchanges) if $pchanges->has_changes;
  }

  for my $target ( $changes, $changes_opt, $changes_dev, $changes_all ) {
    my $diff = get_release_diff( $target, $old, $new, $params );
    $target->{releases}->{$version} = $diff if exists $target->{releases};
    push @{ $target->_releases }, $diff if $target->can('_releases');
  }
}
sub _maybe { return $_[0] if defined $_[0]; return q[] }

my $width = $Text::Wrap::columns = 120;
$Text::Wrap::break = '(?![\x{00a0}\x{202f}])\s';
$Text::Wrap::huge  = 'overflow';

my $misc = path('./misc');
if ( not -d $misc ) {
  $misc->mkpath;
}
$misc->child('Changes.deps.all')->spew_utf8( _maybe( $changes_all->serialize( width => $width ) ) );
$misc->child('Changes.deps')->spew_utf8( _maybe( $changes->serialize( width => $width ) ) );
$misc->child('Changes.deps.opt')->spew_utf8( _maybe( $changes_opt->serialize( width => $width ) ) );
$misc->child('Changes.deps.dev')->spew_utf8( _maybe( $changes_dev->serialize( width => $width ) ) );

path('./Changes')->spew_utf8( _maybe( $master_changes->serialize( width => $width ) ) );

1;
