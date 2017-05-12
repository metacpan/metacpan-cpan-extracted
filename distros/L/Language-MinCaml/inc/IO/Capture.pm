#line 1
package IO::Capture;

$VERSION = 0.05;
use strict;
use Carp;

#line 270


sub new {
    my $class = shift;
    if (ref $class) {
		carp "WARNING: " . __PACKAGE__ . "::new cannot be called from existing object. (cloned)";
		return;
    }
    my $object = shift || {};
    bless $object, $class;
    $object->_initialize; 
}

sub _check_pre_conditions {
    my $self = shift;

    if( $self->{'IO::Capture::status'} ne "Ready") {
		carp "Start issued on an in progress capture ". ref($self);
		return;
	}

    return 1;
}

sub _initialize {
    my $self = shift;
    if (!ref $self) {
	carp "WARNING: _initialize was called, but not called from a valid object";
	return;
    }

        $self->{'IO::Capture::messages'} = [];
        $self->{'IO::Capture::line_pointer'} = 1;
        $self->{'IO::Capture::status'} = "Ready";
    return $self;
}

sub start {
    my $self = shift;

	if (! $self->_check_pre_conditions) {
		carp "Error: failed _check_pre_confitions in ". ref($self);
		return;
	}

    if (! $self->_save_current_configuration ) { 
		carp "Error saving configuration in " . ref($self);
		return;
    }

    $self->{'IO::Capture::status'} = "Busy";

    if (! $self->_start(@_)) {
		carp "Error starting capture in " . ref($self);
		return;
    }
    return 1;
}

sub stop {
    my $self = shift;

    if( $self->{'IO::Capture::status'} ne "Busy") {
		carp "Stop issued on an unstarted capture ". ref($self);
		return;
	}

    if (! $self->_retrieve_captured_text() ) {
        carp "Error retreaving captured text in " . ref($self);
		return;
    }

    if (!$self->_stop() ) {
		carp "Error return from _stop() " . ref($self) . "\n";
		return;
    }

    $self->{'IO::Capture::status'} = "Ready";

	return 1;
}

sub read {
    my $self = shift;

    $self->_read;
}

#
#  Internal start routine.  This needs to be overriden with instance
#  method
#
sub _start {
    my $self = shift;
    return 1;
}

sub _read {
    my $self = shift;
    my $messages = \@{$self->{'IO::Capture::messages'}};
    my $line_pointer = \$self->{'IO::Capture::line_pointer'};

	if ($self->{'IO::Capture::status'} ne "Ready") {
		carp "Read cannot be done while capture is in progress". ref($self);
		return;
	}

    return if $$line_pointer > @$messages;
	return wantarray ? @$messages :  $messages->[($$line_pointer++)-1];
}

sub _retrieve_captured_text {
    return 1;
    
}

sub _save_current_configuration {
    my $self = shift;
    $self->{'IO::Capture::handler_save'} = $SIG{__WARN__};
    open STDOUT_SAVE, ">&STDOUT";
    $self->{'IO::Capture::stdout_save'} = *STDOUT_SAVE;
    open STDERR_SAVE, ">&STDOUT";
    $self->{'IO::Capture::stderr_save'} = *STDERR_SAVE;
    return $self; 
}

sub _stop {
    my $self = shift;
    return 1;
}

sub line_pointer {
    my $self = shift;
    my $new_number = shift;

    $self->{'IO::Capture::line_pointer'} = $new_number if $new_number;
    return $self->{'IO::Capture::line_pointer'};
}
1;
