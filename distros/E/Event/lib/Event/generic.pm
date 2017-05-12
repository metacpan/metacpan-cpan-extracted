use strict;
package Event::generic;
use base 'Event::Watcher';
use vars qw(@ATTRIBUTE);
@ATTRIBUTE = qw(source);

'Event::Watcher'->register;

sub new {
    # lock %Event::;

    my $class = shift;
    my %arg = @_;
    my $o = allocate($class, delete $arg{attach_to} || {});
    $o->init(\%arg);
    $o;
}

package Event::generic::Source;

sub new($) {
    return allocate($_[0], {});
}

sub watch(@) {
    return Event->generic("source", @_);
}

1;
