use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Langertha::Skeid;

{
  my $calls = 0;
  my $skeid = Langertha::Skeid->new(
    config_loader => sub {
      $calls++;
      return {
        nodes => [
          { id => 'dyn', url => 'http://dyn', healthy => 1 },
        ],
      };
    },
  );

  ok $calls >= 1, 'loader called at build time';
  $skeid->call_function('nodes.list', {});
  $skeid->call_function('nodes.list', {});
  ok $calls >= 3, 'loader called per task dispatch';
}

{
  my ($fh, $path) = tempfile();
  print $fh "nodes:\n";
  print $fh "  - id: first\n";
  print $fh "    url: http://first\n";
  close $fh;

  my $skeid = Langertha::Skeid->new(config_file => $path);
  is $skeid->list_nodes->[0]{id}, 'first', 'initial file config loaded';

  sleep 1;
  open my $out, '>', $path or die $!;
  print $out "nodes:\n";
  print $out "  - id: second\n";
  print $out "    url: http://second\n";
  close $out;

  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{id}, 'second', 'file config reloaded on mtime change';
}

done_testing;
