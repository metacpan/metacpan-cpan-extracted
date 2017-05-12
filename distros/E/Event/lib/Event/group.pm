use strict;
package Event::group;
use Carp;
use base 'Event::Watcher';
use vars qw(@ATTRIBUTE);

@ATTRIBUTE = qw(timeout);

'Event::Watcher'->register;

sub new {
    my $class = shift;
    my %arg;
    my @add;
    while (my ($k,$v) = splice(@_, 0, 2)) {
	if ($k eq 'add') {
	    push @add, $v;
	} elsif ($k eq 'del') {
	    carp "del in constructor (ignored)";
	} else {
	    $arg{$k} = $v;
	}
    }
    my $o = allocate($class, delete $arg{attach_to} || {});
    $o->init(\%arg);
    $o->add($_) for @add;
    $o;
}

1;
