#!/usr/bin/env perl
# ABSTRACT: the application asks the engine's tool_result_images and tool_result_pdf, no guess from the wire (karr k166)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use lib 't/lib';

BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504)';
}
use Test::Raider::MockAI qw( mock_app );

my $home = Path::Tiny->tempdir;
local $ENV{HOME} = $home->realpath->stringify;
delete local $ENV{CLAUDE_CONFIG_DIR};

my $dir  = Path::Tiny->tempdir;
my $root = $dir->realpath;
$root->child('CLAUDE.md')->spew_utf8("x\n");
$root->child('pic.png')->spew_raw("\x89PNG\r\n\x1a\n0000");
$root->child('doc.pdf')->spew_raw("%PDF-1.4\n%%EOF\n");

my %can;
my $wire = 'openai';    # the wire name decides nothing any more
no warnings 'redefine';
my $orig_supports = Langertha::Engine::Virtual->can('supports');
local *Langertha::Engine::Virtual::supports = sub {
  my ( $self, $flag ) = @_;
  return exists $can{$flag} ? $can{$flag} : $self->$orig_supports($flag);
};
local *Langertha::Engine::Virtual::tool_wire_format = sub { $wire };

sub result_of {
  my ($file) = @_;
  my $app = mock_app( root => "$root",
    script => [ { tool_calls => [ [ read_file => { path => $file } ] ] }, { text => 'ok' } ] );
  $app->run('look');
  return $app->mock_engine->results->[0]{result};
}

for my $c (
  [ 'images only', 1, 0 ],
  [ 'PDF only',    0, 1 ],
  [ 'both',        1, 1 ],
  [ 'neither',     0, 0 ],
) {
  my ( $name, $images, $pdf ) = @$c;
  subtest $name => sub {
    %can = ( tool_result_images => $images, tool_result_pdf => $pdf, image_input => 0 );
    my $r = result_of('pic.png');
    is( ( $r->{isError} ? 0 : 1 ), $images, 'image follows tool_result_images' );
    $r = result_of('doc.pdf');
    is( ( $r->{isError} ? 0 : 1 ), $pdf, 'PDF follows tool_result_pdf' );
  };
}

done_testing;
