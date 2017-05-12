=pod

=head1 NAME

MOBY::Async::LSAE - utilities to work with LSAE analysis event blocks

=head1 AUTHORS

Former developer
Enrique de Andres Saiz (enrique.deandres@pcm.uam.es) -
INB GNHC-1 (Madrid Science Park, Spain) (2006-2007).

Maintainers
Jose Maria Fernandez (jmfernandez@cnio.es),
Jose Manuel Rodriguez (jmrodriguez@cnio.es) - 
INB GN2 (CNIO, Spain).

=head1 DESCRIPTION

Provides functionalities to work with LSAE analysis event blocks.
It defines the following constants, which represents the different types of
LSAE Event Blocks:

=over

=item LSAE_BASE_EVENT

 e.g.
 <analysis_event timestamp="today">
   <message>This is a general analysis event.</message>
 </analysis_event>

=item LSAE_HEARTBEAT_PROGRESS_EVENT

 e.g.
 <analysis_event timestamp="today">
   <message>This is a HEARTBEAT analysis event.</message>
   <heartbeat_progress/>
 </analysis_event>

=item LSAE_PERCENT_PROGRESS_EVENT

 e.g.
 <analysis_event timestamp="today">
   <message>This is a PERCENT PROGRESS analysis event.</message>
   <percent_progress percentage="52"/>
 </analysis_event>

=item LSAE_STATE_CHANGED_EVENT

 e.g.
 <analysis_event timestamp="today">
   <message>This is a STATUS CHANGED analysis event.</message>
   <state_changed previous_state="created" new_state="running"/>
 </analysis_event>

=item LSAE_STEP_PROGRESS_EVENT

 e.g.
 <analysis_event timestamp="today">
   <message>This is a STEP PROGRESS analysis event.</message>
   <step_progress total_steps="10" steps_completed="5"/>
 </analysis_event>

=item LSAE_TIME_PROGRESS_EVENT

 e.g.
 <analysis_event timestamp="today">
   <message>This is a TIME PROGRESS analysis event.</message>
   <time_progress remaining="324"/>
 </analysis_event>

=back

It also defines LSAE::AnalysisEventBlock class.

=head1 LSAE::AnalysisEventBlock METHODS

=head2 new

 Name       :    new
 Function   :    create a new LSAE::AnalysisEventBlock object.
 Usage      :    $event = LSAE::AnalysisEventBlock->new()
                 $event = LSAE::AnalysisEventBlock->new($xml)
 Args       :    $xml - (optional) a string containing the XML code of an
                        analysis event block according to the LSAE spec.
 Returns    :    the LSAE::AnalysisEventBlock object created.

=head2 type

 Name       :    type
 Function   :    get/set the type of an analysis event block object.
 Usage      :    $event->type()
                 $event->type($type)
 Args       :    $type - a value representing a type of analysis event block.
 Returns    :    a value representing the type of analysis event block object.

=head2 id

 Name       :    id
 Function   :    get/set the identifier of an analysis event block object.
 Usage      :    $event->id()
                 $event->id($id)
 Args       :    $id - (optional) a string.
 Returns    :    the value of the identifier attribute.

=head2 timestamp

 Name       :    timestamp
 Function   :    get/set the timestamp of an analysis event block object.
 Usage      :    $event->timestamp()
                 $event->timestamp($timestamp)
 Args       :    $timestamp - (optional) a tiemestamp.
 Returns    :    the value of the timestamp attribute.

=head2 message

 Name       :    message
 Function   :    get/set the message of an analysis event block object.
 Usage      :    $event->message()
                 $event->message($message)
 Args       :    $message - (optional) a string.
 Returns    :    the content of the message element.

=head2 percentage

 Name       :    percentage
 Function   :    get/set the percentage attribute of an analysis event block of
                 the type LSAE_PERCENT_PROGRESS_EVENT.
 Usage      :    $event->percentage()
                 $event->percentage($percentage)
 Args       :    $percentage - an integer between 0 and 100.
 Returns    :    the value of the percentage attribute.

=head2 previous_state

 Name       :    previous_state
 Function   :    get/set the previous_state attribute of an analysis event block of
                 the type LSAE_STATE_CHANGED_EVENT.
 Usage      :    $event->previous_state()
                 $event->previous_state($state)
 Args       :    $state - one of the following strings... created, running,
                          completed, terminated_by_request or terminated_by_error.
 Returns    :    the value of the previous_state attribute.

=head2 new_state

 Name       :    new_state
 Function   :    get/set the new_state attribute of an analysis event block of
                 the type LSAE_STATE_CHANGED_EVENT.
 Usage      :    $event->new_state()
                 $event->new_state($state)
 Args       :    $state - one of the following strings... created, running,
                          completed, terminated_by_request or terminated_by_error.
 Returns    :    the value of the new_state attribute.

=head2 total_steps

 Name       :    total_steps
 Function   :    get/set the total_steps attribute of an analysis event block of
                 the type LSAE_STEP_PROGRESS_EVENT.
 Usage      :    $event->total_steps()
                 $event->total_steps($steps)
 Args       :    $steps - an integer
 Returns    :    the value of the total_steps attribute.

=head2 steps_completed

 Name       :    steps_completed
 Function   :    get/set the steps_completed attribute of an analysis event block of
                 the type LSAE_STEP_PROGRESS_EVENT.
 Usage      :    $event->steps_completed()
                 $event->steps_completed($steps)
 Args       :    $steps - an integer
 Returns    :    the value of the steps_completed attribute.

=head2 remaining

 Name       :    remaining
 Function   :    get/set the remaining attribute of an analysis event block of
                 the type LSAE_TIME_PROGRESS_EVENT.
 Usage      :    $event->remaining()
                 $event->remaining($seconds)
 Args       :    $seconds - an integer
 Returns    :    the value of the remaining attribute.

=head2 XML

 Name       :    XML
 Function   :    get an string with the XML code of an analysis event block.
 Usage      :    $event->XML()
 Args       :    none
 Returns    :    the analysis event block.

=cut

package MOBY::Async::LSAE;
use strict;
use XML::LibXML;
use Exporter;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

use base qw(Exporter);

our @EXPORT = qw(
	LSAE_BASE_EVENT
	LSAE_HEARTBEAT_PROGRESS_EVENT
	LSAE_PERCENT_PROGRESS_EVENT
	LSAE_STATE_CHANGED_EVENT
	LSAE_STEP_PROGRESS_EVENT
	LSAE_TIME_PROGRESS_EVENT
);

our @EXPORT_OK = qw(
	LSAE_BASE_EVENT
	LSAE_HEARTBEAT_PROGRESS_EVENT
	LSAE_PERCENT_PROGRESS_EVENT
	LSAE_STATE_CHANGED_EVENT
	LSAE_STEP_PROGRESS_EVENT
	LSAE_TIME_PROGRESS_EVENT
);

our %EXPORT_TAGS = (
	all => [
		qw(
			LSAE_BASE_EVENT
			LSAE_HEARTBEAT_PROGRESS_EVENT
			LSAE_PERCENT_PROGRESS_EVENT
			LSAE_STATE_CHANGED_EVENT
			LSAE_STEP_PROGRESS_EVENT
			LSAE_TIME_PROGRESS_EVENT
		)
	]
);

use constant LSAE_BASE_EVENT               => 0;
use constant LSAE_HEARTBEAT_PROGRESS_EVENT => 1;
use constant LSAE_PERCENT_PROGRESS_EVENT   => 2;
use constant LSAE_STATE_CHANGED_EVENT      => 3;
use constant LSAE_STEP_PROGRESS_EVENT      => 4;
use constant LSAE_TIME_PROGRESS_EVENT      => 5;

package LSAE::AnalysisEventBlock;
use strict;

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	if (@_) {
		$self->{XML} = shift;
		$self->type;
		$self->id;
		$self->timestamp;
		$self->message;
		$self->percentage;
		$self->previous_state;
		$self->new_state;
		$self->total_steps;
		$self->steps_completed;
		$self->remaining;
	} else  {
		$self->{XML} = undef;
		$self->{type} = 0;
		$self->{id} = undef;
		$self->{timestamp} = undef;
		$self->{message} = undef;
		$self->{percentage} = undef;
		$self->{previous_state} = undef;
		$self->{new_state} = undef;
		$self->{total_steps} = undef;
		$self->{steps_completed} = undef;
		$self->{remaining} = undef;
	}
	return($self);
}

sub type {
	my $self = shift;
	if (@_) {
		$self->{type} = shift;
	} elsif ($self->{XML}) {
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($self->{XML});
		my $lsae = $doc->getDocumentElement();
		my @heartbeat_progress = ($lsae->getChildrenByTagName('heartbeat_progress'));
		my @percent_progress = ($lsae->getChildrenByTagName('percent_progress'));
		my @state_changed = ($lsae->getChildrenByTagName('state_changed'));
		my @step_progress = ($lsae->getChildrenByTagName('step_progress'));
		my @time_progress = ($lsae->getChildrenByTagName('time_progress'));
		if (scalar(@heartbeat_progress)) {
			$self->{type} = MOBY::Async::LSAE::LSAE_HEARTBEAT_PROGRESS_EVENT;
		} elsif (scalar(@percent_progress)) {
			$self->{type} = MOBY::Async::LSAE::LSAE_PERCENT_PROGRESS_EVENT;
		} elsif (scalar(@state_changed)) {
			$self->{type} = MOBY::Async::LSAE::LSAE_STATE_CHANGED_EVENT;
		} elsif (scalar(@step_progress)) {
			$self->{type} = MOBY::Async::LSAE::LSAE_STEP_PROGRESS_EVENT;
		} elsif (scalar(@time_progress)) {
			$self->{type} = MOBY::Async::LSAE::LSAE_TIME_PROGRESS_EVENT;
		} else {
			$self->{type} = MOBY::Async::LSAE::LSAE_BASE_EVENT;
		} 
	}
	return $self->{type};
}

sub id {
	my $self = shift;
	if (@_) {
		$self->{id} = shift;
	} elsif ($self->{XML}) {
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($self->{XML});
		my $lsae = $doc->getDocumentElement();
		$self->{id} = $lsae->getAttribute('id') || $lsae->getAttributeNS($WSRF::Constants::MOBY, 'id');
	}
	return $self->{id};
}

sub timestamp {
	my $self = shift;
	if (@_) {
		$self->{timestamp} = shift;
	} elsif ($self->{XML}) {
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($self->{XML});
		my $lsae = $doc->getDocumentElement();
		$self->{timestamp} = $lsae->getAttribute('timestamp') || $lsae->getAttributeNS($WSRF::Constants::MOBY, 'timestamp');
	}
	return $self->{timestamp};
}

sub message {
	my $self = shift;
	if (@_) {
		$self->{message} = shift;
	} elsif ($self->{XML}) {
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($self->{XML});
		my $lsae = $doc->getDocumentElement();
		my @message = ($lsae->getChildrenByTagName('message'));
		my $message = shift(@message);
		$self->{message} = $message->getFirstChild->nodeValue if ($message);
	}
	return $self->{message};
}

sub percentage {
	my $self = shift;
	if (@_) {
		$self->{percentage} = shift;
	} elsif ($self->{XML}) {
		$self->{type} = $self->type;
		if ($self->{type} == MOBY::Async::LSAE::LSAE_PERCENT_PROGRESS_EVENT) {
			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string($self->{XML});
			my $lsae = $doc->getDocumentElement();
			my @message = ($lsae->getChildrenByTagName('percent_progress'));
			my $message = shift(@message);
			$self->{percentage} = $message->getAttribute('percentage');
		}
	}
	return $self->{percentage};
}

sub previous_state {
	my $self = shift;
	if (@_) {
		$self->{previous_state} = shift;
	} elsif ($self->{XML}) {
		$self->{type} = $self->type;
		if ($self->{type} == MOBY::Async::LSAE::LSAE_STATE_CHANGED_EVENT) {
			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string($self->{XML});
			my $lsae = $doc->getDocumentElement();
			my @message = ($lsae->getChildrenByTagName('state_changed'));
			my $message = shift(@message);
			$self->{previous_state} = $message->getAttribute('previous_state');
		}
	}
	return $self->{previous_state};
}

sub new_state {
	my $self = shift;
	if (@_) {
		$self->{new_state} = shift;
	} elsif ($self->{XML}) {
		$self->{type} = $self->type;
		if ($self->{type} == MOBY::Async::LSAE::LSAE_STATE_CHANGED_EVENT) {
			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string($self->{XML});
			my $lsae = $doc->getDocumentElement();
			my @message = ($lsae->getChildrenByTagName('state_changed'));
			my $message = shift(@message);
			$self->{new_state} = $message->getAttribute('new_state');
		}
	}
	return $self->{new_state};
}

sub total_steps {
	my $self = shift;
	if (@_) {
		$self->{total_steps} = shift;
	} elsif ($self->{XML}) {
		$self->{type} = $self->type;
		if ($self->{type} == MOBY::Async::LSAE::LSAE_STEP_PROGRESS_EVENT) {
			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string($self->{XML});
			my $lsae = $doc->getDocumentElement();
			my @message = ($lsae->getChildrenByTagName('step_progress'));
			my $message = shift(@message);
			$self->{total_steps} = $message->getAttribute('total_steps');
		}
	}
	return $self->{total_steps};
}

sub steps_completed {
	my $self = shift;
	if (@_) {
		$self->{steps_completed} = shift;
	} elsif ($self->{XML}) {
		$self->{type} = $self->type;
		if ($self->{type} == MOBY::Async::LSAE::LSAE_STEP_PROGRESS_EVENT) {
			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string($self->{XML});
			my $lsae = $doc->getDocumentElement();
			my @message = ($lsae->getChildrenByTagName('step_progress'));
			my $message = shift(@message);
			$self->{steps_completed} = $message->getAttribute('steps_completed');
		}
	}
	return $self->{steps_completed};
}

sub remaining {
	my $self = shift;
	if (@_) {
		$self->{remaining} = shift;
	} elsif ($self->{XML}) {
		$self->{type} = $self->type;
		if ($self->{type} == MOBY::Async::LSAE::LSAE_TIME_PROGRESS_EVENT) {
			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string($self->{XML});
			my $lsae = $doc->getDocumentElement();
			my @message = ($lsae->getChildrenByTagName('time_progress'));
			my $message = shift(@message);
			$self->{remaining} = $message->getAttribute('remaining');
		}
	}
	return $self->{remaining};
}

sub XML {
	my $self = shift;
	
	$self->{type} = $self->type;
	$self->{id} = $self->id;
	$self->{timestamp} = $self->timestamp;
	$self->{message} = $self->message;
	$self->{percentage} = $self->percentage;
	$self->{previous_state} = $self->previous_state;
	$self->{new_state} = $self->new_state;
	$self->{total_steps} = $self->total_steps;
	$self->{steps_completed} = $self->steps_completed;
	$self->{remaining} = $self->remaining;
	
	my $id = "";
	my $timestamp = "";
	my $message = "";
	$id = " id=\"".$self->{id}."\"" if defined $self->{id};
	$timestamp = " timestamp=\"".$self->{timestamp}."\"" if defined $self->{timestamp};
	my $header = "<analysis_event$id$timestamp xmlns=''>";
	my $footer = "</analysis_event>";
	$message = "<message>".$self->{message}."</message>" if defined $self->{message};
	
	if ($self->{type} == MOBY::Async::LSAE::LSAE_BASE_EVENT) {
		
		$self->{XML}  = $header.$message.$footer;
		
	} elsif ($self->{type} == MOBY::Async::LSAE::LSAE_HEARTBEAT_PROGRESS_EVENT) {
		
		$self->{XML}  = $header.$message;
		$self->{XML} .= "<heartbeat_progress/>";
		$self->{XML} .= $footer;
		
	} elsif ($self->{type} == MOBY::Async::LSAE::LSAE_PERCENT_PROGRESS_EVENT) {
		
		return if ($self->{percentage} > 100);
		
		$self->{XML}  = $header.$message;
		$self->{XML} .= "<percent_progress percentage=\"".$self->{percentage}."\"/>";
		$self->{XML} .= $footer;
		
	} elsif ($self->{type} == MOBY::Async::LSAE::LSAE_STATE_CHANGED_EVENT) {
		
		return unless ( $self->{previous_state} eq 'created' ||
		                $self->{previous_state} eq 'running' ||
		                $self->{previous_state} eq 'completed' ||
		                $self->{previous_state} eq 'terminated_by_request' ||
		                $self->{previous_state} eq 'terminated_by_error' );
		return unless ( $self->{new_state} eq 'created' ||
		                $self->{new_state} eq 'running' ||
		                $self->{new_state} eq 'completed' ||
		                $self->{new_state} eq 'terminated_by_request' ||
		                $self->{new_state} eq 'terminated_by_error' );
		
		my $previous_state = " previous_state=\"".$self->{previous_state}."\"" if ($self->{previous_state});
		my $new_state = " new_state=\"".$self->{new_state}."\"" if ($self->{new_state});
		
		$self->{XML}  = $header.$message;
		$self->{XML} .= "<state_changed$previous_state$new_state/>";
		$self->{XML} .= $footer;
		
	} elsif ($self->{type} == MOBY::Async::LSAE::LSAE_STEP_PROGRESS_EVENT) {
		
		$self->{XML}  = $header.$message;
		$self->{XML} .= "<step_progress total_steps=\"".$self->{total_steps}."\" steps_completed=\"".$self->{steps_completed}."\"/>";
		$self->{XML} .= $footer;
		
	} elsif ($self->{type} == MOBY::Async::LSAE::LSAE_TIME_PROGRESS_EVENT) {
		
		$self->{XML}  = $header.$message;
		$self->{XML} .= "<time_progress remaining=\"".$self->{remaining}."\"/>";
		$self->{XML} .= $footer;
	}
	
	return $self->{XML};
}

sub destroy {
	my $self = shift;
	delete($self->{type});
	delete($self->{id});
	delete($self->{timestamp});
	delete($self->{message});
	delete($self->{percentage});
	delete($self->{previous_state});
	delete($self->{new_state});
	delete($self->{total_steps});
	delete($self->{steps_completed});
	delete($self->{remaining});
	delete($self->{XML});
}

1;
