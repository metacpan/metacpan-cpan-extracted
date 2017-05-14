# This perl script is an example of using XML-RPC as an interface to
# local processes through a pipe.  You can pass RPC requests on
# standard input to this script and receive RPC responses on standard
# out.
#
# That's not all!  This script is also an example of running multiple
# requests in the same connection (pipe).
#
# But wait, there's more!  This script can also be used as an XML-RPC
# CGI by removing the `print "\n--]]><<\n";' line near the end of the
# script.
#
# The file `example-cli-input' is a sample input file for this script.
#
# $Id: cli-xml-rpc.pl,v 1.1 1999/11/21 00:13:21 kmacleod Exp $
#

use Frontier::RPC2;

# this flag is set by the `done' RPC when called
$done = 0;

###
### The following is the meat of this server, copied from the
### Frontier::RPC `states-daemon.pl' example script
###

@states = (qw/Alabama Alaska Arizona Arkansas California Colorado Connecticut
	   Delaware Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas
	   Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota
	   Mississippi Missouri Montana Nebraska Nevada/, 'New Hampshire',
	   'New Jersey', 'New Mexico', 'New York', 'North Carolina',
	   'North Dakota', qw/Ohio Oklahoma Oregon Pennsylvania/, 'Rhode Island',
	   'South Carolina', 'South Dakota', qw/Tennessee Texas Utah Vermont
	   Virginia Washington/, 'West Virginia', 'Wisconsin', 'Wyoming');

sub get_state_name {
    my $state_num = shift;

    return $states[$state_num - 1];
}

sub get_state_list {
    my $num_list = shift;

    my ($state_num, @state_list);
    foreach $state_num (@$num_list) {
	push @state_list, $states[$state_num - 1];
    }

    return join(',', @state_list);
}

sub get_state_struct {
    my $struct = shift;

    my ($state_num, @state_list);
    foreach $state_num (values %$struct) {
	push @state_list, $states[$state_num - 1];
    }

    return join(',', @state_list);
}

sub echo {
    return [@_];
}

sub done {
    $done = 1;
}

###
### This is the main loop that reads one RPC call from standard input,
### services it, and then returns the resulting XML.
###
### XML-RPC requests and replies are terminated by a single line
### containing the sequence:
###
###     --]]><<
###
### This sequence of characters is not allowed in ordinary XML.
###

$| = 1;  # Perl magic to use unbuffered output on standard output

$xml_rpc_server = Frontier::RPC2->new;

# create a list of the methods to be served
$methods = {
    'examples.getStateName'   => \&get_state_name,
    'examples.getStateList'   => \&get_state_list,
    'examples.getStateStruct' => \&get_state_struct,
    'echo'                    => \&echo,
    'done'                    => \&done,
};


while ( !$done ) {
    # read one line from standard input, until it is the seperator
    @xml_fragment = ();
    while ( ($line = <>) && ($line !~ /^--\]\]><<$/) ) {
	push @xml_fragment, $line;
    }
    # end of input if nothing pushed on @xml_fragment
    last if $#xml_fragment == -1;

    # serve and print the result
    print $xml_rpc_server->serve ( join ('', @xml_fragment), $methods );

    # Remove the following line to use this script as a CGI
    print "\n--]]><<\n";
}
