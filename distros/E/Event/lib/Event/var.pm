use strict;
package Event::var;
use base 'Event::Watcher';
use vars qw(@ATTRIBUTE);
@ATTRIBUTE = qw(var poll);

'Event::Watcher'->register;

sub new {
    # lock %Event::;

    my $class = shift;
    my %arg = @_;
    my $o = allocate($class, delete $arg{attach_to} || {});
    $o->init(\%arg);
    $o;
}

1;
