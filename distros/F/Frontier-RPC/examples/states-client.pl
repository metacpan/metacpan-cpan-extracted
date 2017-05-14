#
# Copyright (C) 1999 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: states-client.pl,v 1.1 1999/01/19 19:14:41 kmacleod Exp $
#

require 'dumpvar.pl';		# used to dump results

use Frontier::Client;

$url = 'http://betty.userland.com/RPC2';

# this client will accept a URL on the command line if it's given
if ($#ARGV > -1) {
    $url = $ARGV[0];
}

$server = Frontier::Client->new( url => $url );

printf "Calling examples.getStateName\n";
$result = $server->call('examples.getStateName', 41);

dumpvar ('main', 'result');


printf "Calling examples.getStateList\n";
$result = $server->call('examples.getStateList',
			[12, 28, 33, 39, 46]);

dumpvar ('main', 'result');


printf "Calling examples.getStateStruct\n";
$result = $server->call('examples.getStateStruct',
			{ state1 => 18, state2 => 27, state3 => 48 });

dumpvar ('main', 'result');
