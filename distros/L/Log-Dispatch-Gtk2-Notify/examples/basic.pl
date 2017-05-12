use strict;
use warnings;
use Log::Dispatch;
use Log::Dispatch::Gtk2::Notify;

my ($title, $message) = @ARGV;

my $dispatcher = Log::Dispatch->new;
$dispatcher->add(
    Log::Dispatch::Gtk2::Notify->new(
        name => 'notify',
        title => $title,
        min_level => 'debug',
    ),
);

$dispatcher->notice($message);
