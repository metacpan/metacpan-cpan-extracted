use strict;
package Event::io;
use vars qw(@ISA @EXPORT_OK @ATTRIBUTE);
@ISA = qw(Event::Watcher Exporter);
@EXPORT_OK = qw(R W E T);  # bit constants
@ATTRIBUTE = qw(poll fd timeout timeout_cb);

'Event::Watcher'->register;

sub new {
#    lock %Event::;

    my $class = shift;
    my %arg = @_;
    my $o = allocate($class, delete $arg{attach_to} || {});
    $o->init(\%arg);
    $o;
}

1;
