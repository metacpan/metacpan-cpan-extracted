#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Test::More tests => 1 + 1 * 11; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::Cut');
}

my @samples = (
   {
      file => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      expect => {
         duration => '7418',
         video_tags => 149,
         audio_tags => 285,
      },
   },
);

my @cleanup;

END
{
   # Delete temp files
   unlink $_ for @cleanup;
}

for my $sample (@samples)
{
   my $expect = $sample->{expect};
   my $total_tags = $expect->{video_tags} + $expect->{audio_tags};

   my $c = FLV::Cut->new();
   my %tmp = (
      all   => (tempfile)[1],
      one   => (tempfile)[1],
      two   => (tempfile)[1],
      three => (tempfile)[1],
      four  => (tempfile)[1],
      all2  => (tempfile)[1],
   );
   push @cleanup, values %tmp;

   $c->add_output($tmp{all}, 500, 1500); # effectively overridden below
   $c->add_output($tmp{all}, undef, undef);
   $c->add_output($tmp{all}, undef, undef); # no-op
   $c->add_output($tmp{one}, undef, 2000);
   $c->add_output($tmp{two}, 2001, 4000);
   $c->add_output($tmp{three}, 4001, undef);
   $c->add_output($tmp{four}, 2001, undef); # equivalent to two + three
   $c->add_output($tmp{all2}, undef, undef);
   $c->parse_flv($sample->{file});

   for my $key (sort keys %tmp)
   {
      is([$c->{outfiles}->{$tmp{all}}->{flv}->get_body->get_tags]->[0]->get_time, 0, 'all videos start at time zero -- ' . $key);
   }
   is($c->{outfiles}->{$tmp{all}}->{flv}->get_body->get_tags, $total_tags, 'all tags');
   is($c->{outfiles}->{$tmp{all2}}->{flv}->get_body->get_tags, $total_tags, 'all tags');
   is($c->{outfiles}->{$tmp{one}}->{flv}->get_body->get_tags +
      $c->{outfiles}->{$tmp{two}}->{flv}->get_body->get_tags +
      $c->{outfiles}->{$tmp{three}}->{flv}->get_body->get_tags,
      $total_tags, 'sum tags');
   is($c->{outfiles}->{$tmp{two}}->{flv}->get_body->get_tags +
      $c->{outfiles}->{$tmp{three}}->{flv}->get_body->get_tags,
      $c->{outfiles}->{$tmp{four}}->{flv}->get_body->get_tags, 'sum tags');
   cmp_ok(abs($c->{outfiles}->{$tmp{one}}->{flv}->get_body->get_tags -
              $c->{outfiles}->{$tmp{two}}->{flv}->get_body->get_tags),
          '<', 7, 'compare tags');

   $c->save_all;
   # TODO: read back in and validate
}
