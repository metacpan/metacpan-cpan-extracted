use strict;
use warnings;

use Farly;

# specify the actual firewall configuration here

my $file = "../t/test.cfg";

# create the configuration file importer

my $importer = Farly->new();

# call the process method in order to obtain
# an Farly::Object::List<Farly::Object> firewall
# device model

my $container = $importer->process( "ASA", $file );

# create a rule expander object which will be
# used to obtain an Farly::Object::List<Farly::Object>
# container with all of the firewalls raw rule entries
# (same as "show access-list" on a Cisco ASA firewall)

use Farly::Rule::Expander;

my $rule_expander = Farly::Rule::Expander->new($container);

# get the raw rule entries

my $expanded_rules = $rule_expander->expand_all();

# create a search object
# you don't have to specify all possible properties
# only the ones you're interested in
# protocol's and port's must be the integer value (6 = tcp)

my $web = Farly::Object->new();

$web->set( "ACTION",   Farly::Value::String->new("permit") );
$web->set( "PROTOCOL", Farly::Transport::Protocol->new(6) );
$web->set( "SRC_IP",   Farly::IPv4::Network->new("0.0.0.0 0.0.0.0") );
$web->set( "DST_PORT", Farly::Transport::Port->new(80) );

# create a container to put the search result in
# (this allows the results of multiple searches to go in the
# same container, if needed)

my $search_result = Farly::Object::List->new();

# do the search

$expanded_rules->search( $web, $search_result );

# or public tcp/80 access
# $expanded_rules->matches( $web, $search_result );

# or all rules permitting access to tcp/80
# $expanded_rules->contains( $web, $search_result );

# create a template class to convert the search result
# into ASA format

use Farly::Template::Cisco;

my $template = Farly::Template::Cisco->new('ASA');

# print the search results

foreach my $rule_object ( $search_result->iter() ) {
    $template->as_string($rule_object);
    print "\n";
}
