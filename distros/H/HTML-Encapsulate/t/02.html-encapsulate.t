#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Request;
use Test::More;
use File::Path qw(rmtree mkpath);
use Exporter qw(import);
use LWP::UserAgent::Snapshot;
use File::Glob qw(bsd_glob);

use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/lib";

eval "use Test::Files 0.14";
plan skip_all => "Test::Files 0.14 required" if $@;
plan tests => 10;


use_ok 'HTML::Encapsulate', 'download';
my $temp_dir = "$Bin/temp/html-encapsulate";
my $data_dir = "$Bin/data/html-encapsulate";

rmtree $temp_dir if -e $temp_dir;
mkpath $temp_dir;

my $ua = LWP::UserAgent::Snapshot->new;
my $url = "http://nowhere/";



# Ways of using the API
my %useages = 
    (functional => sub # use the functional API, with an explicit agent
     { 
         my %a = @_;
         download($a{request}, 
                  $a{dest},
                  $ua);

     },
     oo_constructor => sub # use the OO API, passing the agent to the constructor
     {
         my %a = @_;
         HTML::Encapsulate->new(ua => $ua)->download($a{request},
                                                     $a{dest});
     },
     oo_method => sub # use the OO API, passing the agent to the method
     {
         my %a = @_;
         HTML::Encapsulate->new->download($a{request},
                                          $a{dest}, 
                                          $ua);
     },
 );


# Cases which should work, or not
my @cases = map { (File::Spec->splitpath($_))[2] } 
    bsd_glob "$data_dir/*";


# Now try all combinations of usage and target
foreach my $case (@cases)
{
    my $reference_dir = "$data_dir/$case/reference";
    $ua->mock_from("$data_dir/$case/mock_data");    
    
    foreach my $useage_name (sort keys %useages)
    {
        rmtree $temp_dir;
#        mkpath $temp_dir;

        my $request = HTTP::Request->new(GET => $url);

        # invoke the use case
        my $useage = $useages{$useage_name};
        $useage->(request => $request,
                  url => $url,
                  dest => $temp_dir);
        
        # compare downloaded files with the reference
        compare_dirs_ok("$reference_dir/nowhere", 
                        "$temp_dir", 
                        "case=$case/useage=$useage_name: downloaded files from $url match reference");
    }
}

# TODO
# test that missing dependencies don't abort the whole download
# add frames support?
