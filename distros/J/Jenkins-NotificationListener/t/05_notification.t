#!/usr/bin/env perl
use Test::More;
use Jenkins::Notification;
use Jenkins::NotificationListener;
use LWP::Simple qw(get);
use File::Read;
use JSON::XS;

my $json = decode_json read_file 't/data/job.json';
my $build_id = $json->{lastBuild}->{number};
my $build_url = $json->{lastBuild}->{url};
ok $json;
ok $build_id;
ok $build_url;

my $payload = Jenkins::Notification->new( 
    name => 'jruby-git' , 
    url => 'http://ci.jruby.org/job/jruby-git',
    build => {
        number => $build_id,
        phase => "STARTED",
        status => "FAILED",
        url => "job/jruby-git/" . $build_id,
        full_url => $build_url,
        parameters => {
            branch => 'master'
        }
    }
);

ok $payload;
ok $payload->name;
ok $payload->job;
ok $payload->build;

isa_ok $payload->job, 'Net::Jenkins::Job';
isa_ok $payload->build, 'Net::Jenkins::Job::Build';

my $json = read_file 't/data/notification.json';

my $notification = parse_jenkins_notification($json);
ok $notification;
ok $notification->job;
ok $notification->build;
ok $notification->to_hashref;
done_testing;
