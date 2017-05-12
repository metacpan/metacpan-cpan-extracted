#!/usr/bin/env perl

use strict;
use warnings;
use Jenkins::API;

my $url = shift;
unless ($url)
{
    print "Usage $0 http://jenkins:8080/\n";
    exit 1;
}

my $api = Jenkins::API->new({ base_url => $url });
unless($api->check_jenkins_url)
{
    print "$url does not appear to be a valid jenkins url\n";
    exit 2;
}

my $jobs = $api->current_status({ extra_params => { tree => 'jobs[name,color]' } });
my @job_list = @{$jobs->{jobs}};
@job_list = sort { $a->{name} cmp $b->{name} } @job_list;
for my $job (@job_list)
{
    # status isn't really this simple, but unstable doesn't
    # map very to the todos in perl, so I'm not interested
    # in it personally.
    my $status = $job->{color} eq 'blue' ? 'OK' : 'Fail';
    print "$job->{name} - $status\n";
}
