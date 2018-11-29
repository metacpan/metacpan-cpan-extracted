#!perl
use 5.020;
use strict;
use warnings FATAL => 'all';
use feature qw(postderef);
no warnings qw(experimental::postderef);
use Test::More;
use Test::Exception;

use Mail::DataFeed::Abusix;

subtest 'constructor' => sub{
  dies_ok( sub{ my $abusix_feed=Mail::DataFeed::Abusix->new(); }, 'Empty constructor dies' );
  dies_ok( sub { my $abusix_feed=Mail::DataFeed::Abusix->new(feed_key=>'test',feed_dest=>'test:123'); }, 'Missing feed_name dies' );
  dies_ok( sub { my $abusix_feed=Mail::DataFeed::Abusix->new(feed_name=>'test',feed_dest=>'test:123'); }, 'Missing feed_key dies' );
  dies_ok( sub { my $abusix_feed=Mail::DataFeed::Abusix->new(feed_name=>'test',feed_key=>'test'); }, 'Missing feed_dest dies' );
  lives_ok( sub { my $abusix_feed=Mail::DataFeed::Abusix->new(feed_name=>'test',feed_key=>'test',feed_dest=>'test:123'); }, 'Good constructor lives' );
  is( ref Mail::DataFeed::Abusix->new(feed_name=>'test',feed_key=>'test',feed_dest=>'test:123'), 'Mail::DataFeed::Abusix', 'Constructor returns object' );
};

my $abusix_feed=Mail::DataFeed::Abusix->new(feed_name=>'test_feed_id',feed_key=>'test_feed_key',feed_dest=>'');

subtest 'default' => sub {

  is( split_feed($abusix_feed)->[0], 'test_feed_id', 'correct value set' );

  subtest 'timestamp' => sub {
    my $now = time();
    my $feed_now = split_feed($abusix_feed)->[1];
    is( defined $feed_now, 1, 'is defined' );
    is( $feed_now =~ /^\d+$/, 1, 'is numeric' );
    is( $feed_now - $now < 5, 1, 'is about now' ); # Seriously, if this takes more than 5 seconds to run then we have other issues!
  };

  subtest 'fake_timestamp' => sub {
    my $time = '123456';
    my $feed_now = split_feed($abusix_feed,{_time=>$time})->[1];
    is( $feed_now, '123456', 'fake timestamp set' );
  };

  subtest 'port' => sub {
    is( split_feed($abusix_feed)->[2], '', 'defaults to unknown' );
    $abusix_feed->port(25);
    is( split_feed($abusix_feed)->[2], '25', 'correct value set' );
  };

  subtest 'ip_address' => sub {
    is( split_feed($abusix_feed)->[3], '', 'defaults to unknown' );
    $abusix_feed->ip_address('1.2.3.4');
    is( split_feed($abusix_feed)->[3], '1.2.3.4', 'correct value set' );
  };

  subtest 'reverse_dns' => sub {
    is( split_feed($abusix_feed)->[4], '', 'defaults to unknown' );
    $abusix_feed->reverse_dns('example.com');
    is( split_feed($abusix_feed)->[4], 'example.com', 'correct value set' );
  };

  subtest 'helo' => sub {
    is( split_feed($abusix_feed)->[5], '', 'defaults to unknown' );
    $abusix_feed->helo('helo.example.com');
    is( split_feed($abusix_feed)->[5], 'helo.example.com', 'correct value set' );
  };

  subtest 'used_esmtp' => sub {
    is( split_feed($abusix_feed)->[6], '', 'defaults to unknown' );
    $abusix_feed->used_esmtp(1);
    is( split_feed($abusix_feed)->[6], 'Y', 'correct true value set' );
    $abusix_feed->used_esmtp(0);
    is( split_feed($abusix_feed)->[6], 'N', 'correct false value set' );
  };

  subtest 'used_tls' => sub {
    is( split_feed($abusix_feed)->[7], '', 'defaults to unknown' );
    $abusix_feed->used_tls(1);
    is( split_feed($abusix_feed)->[7], 'Y', 'correct true value set' );
    $abusix_feed->used_tls(0);
    is( split_feed($abusix_feed)->[7], 'N', 'correct false value set' );
  };

  subtest 'used_auth' => sub {
    is( split_feed($abusix_feed)->[8], '', 'defaults to unknown' );
    $abusix_feed->used_auth(1);
    is( split_feed($abusix_feed)->[8], 'Y', 'correct true value set' );
    $abusix_feed->used_auth(0);
    is( split_feed($abusix_feed)->[8], 'N', 'correct false value set' );
  };

  subtest 'mail_from_domain' => sub {
    is( split_feed($abusix_feed)->[9], '', 'defaults to unknown' );
    $abusix_feed->mail_from_domain('sender.example.com');
    is( split_feed($abusix_feed)->[9], 'sender.example.com', 'correct value set' );
  };

  is( split_feed($abusix_feed)->[10], '', 'extended json is empty' );

  subtest 'checksum' => sub {
    $abusix_feed->port(25);
    $abusix_feed->ip_address('1.2.3.4');
    $abusix_feed->reverse_dns('test.example.org');
    $abusix_feed->helo('server.example.org');
    $abusix_feed->used_esmtp(1);
    $abusix_feed->used_tls(1);
    $abusix_feed->used_auth(0);
    $abusix_feed->mail_from_domain('from.example.org');
    my $time = '123456';
    is( split_feed($abusix_feed,{_time=>$time})->[11], '0ee00d14be4ac17f759ccec9d66c80b1', 'checksum is as expected' );
  };

  is( scalar split_feed($abusix_feed)->@*, 12, 'correct number of fields' );

};

sub split_feed {
  my ($feed,$args) = @_;
  my $data = $feed->_build_report($args);
  my @split_feed = split("\n", $data);
  return \@split_feed;
}

done_testing();

