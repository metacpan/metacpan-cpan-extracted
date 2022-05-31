#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::Util qw(dumper);
use 5.018;
use Net::SSH::Expect;
use POSIX;
my $connection = new Net::SSH::Expect(
  host     => '10.15.107.196',
  user     => 'solarwindcm',
  password => 'Dwl559tel',
  timeout  => 2,
  raw_pty  => 1,

  #restart_timeout_upon_receive =>1,
);

my $prompt;
eval { $prompt = $connection->login(1) };
if ($@) {
  say "connect  faile!$@";

}
elsif ( $prompt =~ /[>,#]\s*/ ) {
  say dumper $prompt;
  my $curtime = strftime "%Y-%m-%d %H:%M:%S", localtime;
  say "$curtime login  success!";
}
$connection->send('sh run');
$connection->waitfor('(?m:#\z)');
my $lines = $connection->before();
say $lines;
my $buf = $lines;
while ( $lines =~ /More/mi ) {
  $connection->get_expect()->send(" ");
  $connection->waitfor( '#\z', 0.1 );
  $lines = $connection->before();
  $buf .= $lines;
  last if $lines =~ /#\s*\z/mi;
}

say dumper $lines;
