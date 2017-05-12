#/usr/bin/perl
use strict;
use warnings;

use Form::Factory;

my $cli = Form::Factory->new_interface('CLI');
my $action = $cli->new_action(shift @ARGV);

$action->consume_and_clean_and_check_and_process;

if ($action->is_valid and $action->is_success) {
    print "done.\n";
}
else {
    my $messages = $action->results->all_messages;
    print $messages;
    print "usage: $0 OPTIONS\n\n";
    print "Options:\n";
    $action->render;
}
