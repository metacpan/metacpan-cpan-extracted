die "SysV semaphores are not implemented yet.  Send email to perl-loop@perl.org if you think this is a problem.  Thanks!\n";

package Event::semaphore;

use Event;
use IPC::Semaphore;

register Event;

my $LABEL = "sem000000";
my %SEM = ();

sub new {
    use attrs qw(locked method);

    my $class = shift;
    my %arg = @_;
    my $sem = $arg{'-semaphore'};
    my $op = $arg{'-op'};
    my $cb = $arg{'-callback'};

    croak 'Event->semaphore( -semaphore => $sem, -op => $arrayref, -callback => $coderef)'
	unless(UNIVERSAL::isa($msg,'IPC::Semaphore')
		&& UNIVERSAL::isa($op,'ARRAY')
		&& UNIVERSAL::isa($cb,'CODE'));

    my $obj = bless {
	callback  => $cb,
	semaphore => $sem,
	semop     => $op,
	label	  => $LABEL++,
    }, $class;
    $SEM{$obj->{'label'}} = $obj;
    $obj;
}

sub prepare { 3600 }

sub check {
    my $obj;
    my @del = ();
    foreach $obj (values %SEM) {
	if($obj->{'semaphore'}->op(@{$obj->{'semop'}}) >= 0) {
	    my($o,$cb,$s,$op) = ($obj,$obj->{'callback'},
				$obj->{'semaphore'},$obj->{'semop'});
	    Event->queueEvent( sub { $cb->($o,$s) } );
	    push @del, $obj->{'label'};
	}
    }
    delete @sem{@del};
    1;
}

sub cancel {
    my $self = shift;
    delete $SEM{$self->{'label'}};
}

sub again {
    my $self = shift;
    $SEM{$self->{'label'}} = $self;
}

1;
