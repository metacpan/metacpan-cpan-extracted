#!/usr/bin/env perl
# FILENAME: update-dist-to-gentoo.pl
# CREATED: 10/11/14 03:21:18 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Update dist-to-gentoo file.

use strict;
use warnings;
use utf8;

my %premap = ();

use FindBin;
use Path::Tiny qw(path);
use MetaCPAN::Client;
use Data::Dump qw(pp);
use List::MoreUtils qw( uniq );
use HTTP::Tiny::Mech;
use WWW::Mechanize::Cached;
my $source = path($FindBin::Bin)->sibling('share')->child('dist-to-gentoo.csv');
my $target = path($FindBin::Bin)->sibling('share')->child('module-to-gentoo.csv');
my $dvfile = path($FindBin::Bin)->sibling('share')->child('dist-versions.csv');
my $mvfile = path($FindBin::Bin)->sibling('share')->child('module-versions.csv');

sub _mk_cache {
  my ( $name, %opts ) = @_;
  my $root  = path( File::Spec->tmpdir );
  my $child = $root->child('gentoo-metacpan-cache');
  $child->mkpath;
  my $db = $child->child($name);
  require Data::Serializer::Sereal;
  my $serial = Data::Serializer::Sereal->new();
  $db->mkpath;
  require CHI;
  require CHI::Driver::LMDB;
  return CHI->new(
    driver           => 'LMDB',
    root_dir         => "$db",
    expires_in       => '6 hour',
    expires_variance => '0.2',
    namespace        => $name,
    cache_size       => '30m',
    key_serializer   => $serial,
    serializer       => $serial,
    %opts
  );
}
my $reader = $source->openr_raw();

my $client = MetaCPAN::Client->new(
  version => 'v1',
  ua      => HTTP::Tiny::Mech->new(
    mechua => WWW::Mechanize::Cached->new(
      cache     => _mk_cache('qdb'),
      timeout   => 20_000,
      autocheck => 1,
    )
  )
);
my %outmap;
my %dvmap;
my %mvmap;

my $ocache = _mk_cache('update-objects');

my %alternatives;

while ( my $line = <$reader> ) {
  chomp $line;
  my ( $upstream, $gentoo ) = split /,/, $line;
  next if not defined $upstream;
  next if not defined $gentoo;
  my $rs = $ocache->compute(
    [ 'release', $upstream ],
    undef,
    sub {
      my $rs;
      if ( not eval { $rs = $client->release($upstream); 1 } ) {
        warn "$upstream did not resolve";
        return;
      }
      delete $rs->{client};
      return $rs;
    }
  );
  next unless $rs;
  my $name = $rs->name;
  my $dist = $rs->distribution;
  my $uri  = $rs->download_url;
  $uri =~ s{\A.*\/authors\/}{};

  use CPAN::DistnameInfo;
  my $d = CPAN::DistnameInfo->new($uri);

  my $version = $rs->version;
  my $dv      = $d->version;
  printf "%s %s\e[31m%s\e[0m %s\n", $dist, $version,
    ( ( $dv ne $version && $dv ne "v$version" && "v$dv" ne $version ) ? " $dv" : "" ),
    $uri;
  $dvmap{$dist} = [ $d->version, $uri ];
  my (@mods) = $ocache->compute(
    [ 'release-mods', $name ],
    undef,
    sub {
      my $modules = $client->module(
        {
          all => [
            { release    => $name },                          #
            { author     => $rs->author },
            { authorized => 1 },
            { indexed    => 1 },                              #
            { mime       => 'text/x-script.perl-module' },    #
          ]
        }
      );
      my @out;
      while ( my $mod = $modules->next ) {
        delete $mod->{client};
        push @out, $mod;
      }
      return @out;
    }
  );
  $mvmap{$uri} = {};
  for my $mod (@mods) {
    next unless $mod->module;
    for my $module ( 'ARRAY' eq ref $mod->module ? @{ $mod->module } : ( $mod->module ) ) {
      next unless $module->{authorized};
      next unless $module->{indexed};
      my $name = $module->{name};
      if ( exists $outmap{$name} and $outmap{$name} ne $gentoo ) {
        warn "$name already provided by " . $outmap{$name} . "( from $gentoo )";
        next;
      }

      $outmap{$name} = $gentoo;

      # Prefer versions that match their module name where possible
      next
        if exists $mvmap{$uri}->{ $module->{name} }
        and exists $alternatives{ $module->{name} }->{ $mod->name };
      $alternatives{ $module->{name} }->{ $mod->name } = $module->{version};
      $mvmap{$uri}->{ $module->{name} } = $module->{version};
    }
  }
  next;
}

my $writer = $target->openw_raw();
for my $module ( sort keys %outmap ) {
  $writer->printf( "%s,%s\n", $module, $outmap{$module} );
}
$writer = $dvfile->openw_raw();
for my $dist ( sort keys %dvmap ) {
  $writer->printf( "%s,%s,%s\n", $dist, @{ $dvmap{$dist} } );
}
$writer = $mvfile->openw_raw();
for my $uri ( sort keys %mvmap ) {
  for my $module ( sort keys %{ $mvmap{$uri} } ) {
    $writer->printf( "%s,%s,%s\n", $uri, $module, ( defined $mvmap{$uri}->{$module} ? $mvmap{$uri}->{$module} : '(undef)' ) );
  }
}

