use strict;
use warnings;
use Test::More 'no_plan';
use File::Temp qw(tempdir);

use lib 't/lib';
use TestResolver;
use MasonX::Resolver::Multiplex;
use HTML::Mason::Resolver::File;
use HTML::Mason::Resolver::Null;

my $dir = tempdir(CLEANUP => 1);

for my $file (qw(a b)) {
  open my $fh, ">$dir/$file" or die "Can't create $dir/$file: $!";
  print $fh $file;
}

my $res = MasonX::Resolver::Multiplex->new(
  resolvers => [
    HTML::Mason::Resolver::File->new,
    HTML::Mason::Resolver::Null->new,
  ],
);

my $src = $res->get_info(
  '/a', test => $dir,
);

isa_ok($src, 'HTML::Mason::ComponentSource');
is($src->comp_id, '/test/a', "get_info delegated to File");
is_deeply(
  [ $res->glob_path('/*', $dir) ],
  [ qw(/a /b) ],
  "glob_path delegated to File",
);

is($res->get_info('/c', test => $dir), undef, 'get_info on missing file');

push @{ $res->resolvers }, TestResolver->new;

$src = $res->get_info('/c', test => $dir);
isa_ok($src, 'HTML::Mason::ComponentSource');
is($src->comp_id, '/test/c', 'get_info delegated to TestResolver');
is($src->comp_source, "auto: /c", "comp_source is correct");
