use strict;
package Event::timer;
use Carp;
use base 'Event::Watcher';
use vars qw(@ATTRIBUTE);

@ATTRIBUTE = qw(at hard interval);

'Event::Watcher'->register;

sub new {
#    lock %Event::;
    my $class = shift;
    my %arg = @_;
    my $o = allocate($class, delete $arg{attach_to} || {});

    # deprecated
    for (qw(at after interval repeat)) {
	if (exists $arg{"e_$_"}) {
	    carp "'e_$_' is renamed to '$_'";
	    $arg{$_} = delete $arg{"e_$_"};
	}
    }

    my $has_at = exists $arg{at};
    my $has_after = exists $arg{after};

    croak "'after' and 'at' are mutually exclusive"
	if $has_at && $has_after;

    if ($has_after) {
	my $after = delete $arg{after};
	$o->at(Event::time() + $after);
	$has_at=1;
	$o->interval($after) if !exists $arg{interval};
    } elsif ($has_at) {
	$o->at(delete $arg{at});
    }
    if (exists $arg{interval}) {
	my $i = delete $arg{interval};
	$o->at(Event::time() + (ref $i? $$i : $i)) unless $has_at;
	$o->interval($i);
	$o->repeat(1) unless exists $arg{repeat};
    }

    $o->init(\%arg);
    $o;
}

1;
