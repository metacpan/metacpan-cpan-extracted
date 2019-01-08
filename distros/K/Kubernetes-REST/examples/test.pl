#!/usr/bin/env perl

use strict;
use warnings;
use Kubernetes::REST;
use Signer::AWSv4::EKS;

my $AK = $ENV{ AWS_ACCESS_KEY };
my $SK = $ENV{ AWS_SECRET_KEY };
my $server = $ARGV[0] or die "Pass the script a URL to the Kubernetes API as first param";
my $cl_name = $ARGV[1] or die "Pass the script the cluster name of the cluster as second param";

if (not defined $AK or not defined $SK) {
  die "This script gets its AWS credentials from ENV: AWS_ACCESS_KEY and AWS_SECRET_KEY"
};

my $auth = Signer::AWSv4::EKS->new(
   access_key => $AK,
   secret_key => $SK,
   cluster_id => $cl_name,
);

my $api = Kubernetes::REST->new(
  credentials => $auth,
  server => { endpoint => $server },
);

use Data::Dumper;
my $result;

$result = $api->Core->GetCoreAPIVersions;
print Dumper($result);

$result = $api->Core->ListNamespace;
print Dumper($result);

$result = $api->GetAllAPIVersions;
print Dumper($result);

