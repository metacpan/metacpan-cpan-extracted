use strict;
package Event::idle;
use Carp;
use base 'Event::Watcher';
use vars qw($DefaultPriority @ATTRIBUTE);

@ATTRIBUTE = qw(hard max min);

'Event::Watcher'->register;

sub new {
#    lock %Event::;

    my $class = shift;
    my %arg = @_;
    my $o = allocate($class, delete $arg{attach_to} || {});
    
    # deprecated
    for (qw(min max repeat)) {
	if (exists $arg{"e_$_"}) {
	    carp "'e_$_' is renamed to '$_'";
	    $arg{$_} = delete $arg{"e_$_"};
	}
    }

    $o->repeat(1) if defined $arg{min} || defined $arg{max};
    $o->init(\%arg);
    $o;
}

1;
