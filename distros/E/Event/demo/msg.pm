die "SysV messages are not implemented yet.  Send email to perl-loop@perl.org if you think this is a problem.  Thanks!\n";

package Event::msg;

use Event;
use IPC::Msg;

register Event;

my %MSG;
my $LABEL = "msg000000";

sub new {
    use attrs qw(locked method);

    my $class = shift;
    my %arg = @_;
    my $msg = $arg{'-msg'};
    my $cb  = $arg{'-callback'};

    croak 'Event->msg( -msg => $msg, -callback => $coderef)'
	unless(UNIVERSAL::isa($msg,'IPC::Msg')
		&& UNIVERSAL::isa($cb,'CODE'));

    my $obj = {
	callback => $cb,
	msg	 => $msg,
	label    => $label++
    }, $class;

    $msg{$obj->{'label'}} = $obj;

    $obj;
}

sub cancel {
    my $self = shift;
    delete $msg{$self->{'label'}};
}

sub prepare { 3600 }


sub check {
    my $obj;
    my @del = ();
    foreach $obj (values %msg) {
	my $ds = $obj->{'msg'}->stat;
	if($ds->qnum && $ds->lspid != $$)
	    my($o,$cb,$msg) = ($obj,$obj->{'callback'},$obj->{'msg'});
	    Event->queueEvent( sub { $cb->($o,$msg) } );
	}
    }
    1;
}

1;

