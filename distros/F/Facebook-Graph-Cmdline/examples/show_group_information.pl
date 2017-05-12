#!/usr/bin/perl

#ABSTRACT: Example Demonstrating Facebook::Graph::Cmdline life cycle

# show_group_information.pl:
#  Demonstrates Facebook::Graph::Cmdline life cycle
#
#  Initializes Facebook::Graph::Cmdline from a yaml
#  configfile(facebook.yml), creates and saves an
#  access token, requests and prints information
#  about a group (LA Perl Mongers)

use warnings;
use strict;

use Data::Dumper;
use Facebook::Graph::Cmdline;
my $fb = Facebook::Graph::Cmdline->new_with_config(
    configfile => 'facebook.yml' );

$fb->save_access_token();

my $lapm_group_id = '119158178096277';
print Dumper $fb->fetch($lapm_group_id);
