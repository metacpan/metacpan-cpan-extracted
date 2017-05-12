use strict;
package Event::signal;
use Carp;
use base 'Event::Watcher';
use vars qw($DefaultPriority @ATTRIBUTE);
$DefaultPriority = Event::PRIO_HIGH();
@ATTRIBUTE = qw(signal);

'Event::Watcher'->register;

sub new {
    # lock %Event::

    my $class = shift;
    my %arg = @_;
    my $o = allocate($class, delete $arg{attach_to} || {});
    $o->init(\%arg);
    $o;
}

1;
