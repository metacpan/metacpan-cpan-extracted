#$Id: MOBY::MobyException.pm ,v 1.2 
# Created: 26-01-2006
# Updated: 29-03-2006

# Name of the package
package MOBY::Client::Exception::MobyException;

# Perl pragma to restrict unsafe constructs
use strict;

# Issue warnings about suspicious programming.
use warnings;

use Carp qw(croak);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use MOBY::Client::Exception::MobyExceptionCodes;


##########################################
# Create new instance of exception class #
##########################################
sub new {
	# Get parameters
	my ($caller, %args) = @_;
	
	my ($caller_is_obj) = ref($caller);
	my ($class) = $caller_is_obj || $caller;
	my ($self) = {};

	# Add attributes related to mobyData where has been generating exception.
	$self->{queryID} = (exists($args{queryID}) && defined($args{queryID})) ? $args{queryID} : '';
	$self->{refElement} = (exists($args{refElement}) && defined($args{refElement})) ? $args{refElement} : '';


	# Add attribute of exception code
	if (exists($args{code}) && defined($args{code})) {
		$self->{code} = $args{code};
	} else {
		$self->{code} = 0;
	}

	# Add attribute of exception "dynamic" message
	$self->{message} = (exists($args{message}) && defined($args{message})) ?  $args{message} : undef;

	# Add attribute of type of exception
	if (exists($args{type}) && defined($args{type})) {
		my ($type) = lc($args{type}); # Converts all characters in the string to lower case
		if ($type eq 'information' || $type eq 'warning' || $type eq 'error') {
			$self->{type} = $type; #  (undef | error | warning | information)
		} else {
			$self->{type} = undef;
		}
	} else {
		$self->{type} = undef;
	}

	# The magic object creation command
	bless ($self, $class);

	# Returns a new 'MobyException' object
	return $self;
}

#################
# Method bodies #
#################

#########################
# Return exception code #
#########################
sub getExceptionCode {
	# Get parameters
	my($self) = shift;
	
	croak("This is an instance method!")  unless(ref($self));
	
	return $self->{code};
} # End getExceptionCode

############################
# Return exception message #
############################
sub getExceptionMessage {
	# Get parameters
	my($self) = shift;

	my ($exceptionMessage) = undef;

	croak("This is an instance method!")  unless(ref($self));
	
	# Get standard exception message from given code
	my ($standardMessage) = MOBY::Client::Exception::MobyExceptionCodes::getExceptionCodeDescription($self->{code});

	# If standard message is not defined that means, the exception code is wrong => return undef
	return undef unless(defined($standardMessage));

	# User could add dynamic message into satandard exception message
	($exceptionMessage) = (defined($self->{message})) ? $standardMessage.$self->{message} : $standardMessage;
	
	return $exceptionMessage;
} # End getExceptionMessage

############################
# Return type of exception #
############################
sub getExceptionType {
	# Get parameters
	my($self) = shift;
	
	croak("This is an instance method!")  unless(ref($self));
	
	# type of exception is returned, if defined type of exception; otherwise returns undef
	return $self->{type};
} # End getExceptionType

#########################
# Assign exception code #
#########################
sub setExceptionCode {
	# Get parameters
	my($self, $code) = @_;

	croak("This is an instance method!")  unless(ref($self));

	if (defined($code)) {
		$self->{code} = $code;
	} else {
		croak("input argument not defined"); 
	}
# UPDATE: 19-01-2006-----------------
} # End setExceptionCode

############################
# Assign exception message #
############################
sub setExceptionMessage {
	# Get parameters
	my($self, $message) = @_;

	croak("This is an instance method!")  unless(ref($self));

	if (defined($message)) {
		$self->{message} = $message; 
	} else {
		croak("input argument not defined"); 
	}
} # End setExceptionMessage

##################################################
# Assign type of exception to attribute of class #
##################################################
sub setExceptionType {
	# Get parameters
	my($self, $type) = @_;

	croak("This is an instance method!")  unless(ref($self));

	# Input type has to be defined and to include within range of values
	if (defined($type)) {
		my ($type) = lc($type); # Converts all characters in the string to lower case
		
		# Input type has to be included within range of values
		if ($type eq 'information' || $type eq 'warning' || $type eq 'error') {
			$self->{type} = $type;
		} else {
			croak("input argument not defined");
		}
	}
} # End setExceptionType

########################################################################################
# Return xml block that will be the exception response (error, warning or information) #
########################################################################################
sub retrieveExceptionResponse {
	# Get parameters
	my($self)=shift;
	my ($exceptionResponse) = undef;
	
	croak("This is an instance method!")  unless(ref($self));


	# If corresponds to free text message, we don't mind the code or message => User is free to insert what he wants
	if (defined($self->{type}) && ($self->{type} eq 'information')) {

		# Chek if is defined information message
		my ($infoMessage) = (defined($self->{message})) ? $self->{message} : '';

		# Chek if there is article Name 
		my ($refElement) = '';
		if (exists($self->{refElement}) && defined($self->{refElement}) && ($self->{refElement} ne '')) { $refElement = "refElement='".$self->{refElement}."'" ; }

		my ($refQueryID) = '';
		if (exists($self->{queryID}) && defined($self->{queryID}) && ($self->{queryID} ne '')) { $refQueryID = "refQueryID='".$self->{queryID}."'" ; }

		$exceptionResponse = "<mobyException $refQueryID $refElement severity='information'>\n\t<exceptionCode>".$self->{code}."</exceptionCode>\n\t<exceptionMessage>$infoMessage</exceptionMessage>\n</mobyException>";

	} else {

		# Get standard exception message from given code
		my ($standardMessage) = MOBY::Client::Exception::MobyExceptionCodes::getExceptionCodeDescription($self->{code});

		#return undef unless(defined($standardMessage));
		croak("code of exception is wrong or does not exists") unless(defined($standardMessage));

		# Chek if there is article Name 
                my ($refElement) = '';
                if (exists($self->{refElement}) && defined($self->{refElement}) && ($self->{refElement} ne '')) { $refElement = "refElement='".$self->{refElement}."'" ; }

                my ($refQueryID) = '';
                if (exists($self->{queryID}) && defined($self->{queryID}) && ($self->{queryID} ne '')) { $refQueryID = "refQueryID='".$self->{queryID}."'" ; }

		# User could add dynamic message into satandard exception message
		my ($exceptionMessage) = (defined($self->{message})) ? $standardMessage.$self->{message} : $standardMessage;

		if (defined($self->{type}) && ($self->{type} eq 'warning' || $self->{type} eq 'error')) {
			if ($self->{type} eq 'error') {

				$exceptionResponse = "<mobyException $refQueryID $refElement severity='error'>\n\t<exceptionCode>".$self->{code}."</exceptionCode>\n\t<exceptionMessage>$exceptionMessage</exceptionMessage>\n</mobyException>";

			} elsif ($self->{type} eq 'warning') {

				$exceptionResponse = "<mobyException $refQueryID $refElement severity='warning'>\n\t<exceptionCode>".$self->{code}."</exceptionCode>\n\t<exceptionMessage>$exceptionMessage</exceptionMessage>\n</mobyException>";

			} else {
				croak("type of exception is wrong or does not exists");
			}
	
		} else {
			croak("type of exception is wrong or does not exists");
		}
	}

	return $exceptionResponse;
} # End retrieveExceptionResponse

##########################################
# Return xml block of one empty MobyData #
##########################################
sub retrieveEmptyMobyData {
	# Get parameters
	my($self) = shift;
	
	croak("This is an instance method!")  unless(ref($self));
	
	return "<moby:mobyData moby:queryID='".$self->{queryID}."' />";
} # End retrieveEmptyMobyData

####################################################
# Return xml block of one empty simple MobyArticle #
####################################################
sub retrieveEmptyMobySimple {
	# Get parameters
	my($self, $outputArticle)= @_;
	
	croak("This is an instance method!")  unless(ref($self));
	
	return "<moby:Simple moby:articleName='$outputArticle' />";
} # End retrieveEmptyMobySimple

########################################################
# Return xml block of one empty collection MobyArticle #
########################################################
sub retrieveEmptyMobyCollection {
	# Get parameters
	my($self, $outputArticle) = @_;
	
	croak("This is an instance method!")  unless(ref($self));
	
	return "<moby:Collection moby:articleName='$outputArticle' />";
} # End retrieveEmptyMobyCollection

########################################################################
# Return MobyData inserting MobyArticles that has been giving by input #
########################################################################
sub embedMOBYArticlesIntoMOBYData {
	# Get parameters
	my($self, $outputMOBYArticles) = @_;

	# Returns MOBYData response
	return "<moby:mobyData moby:queryID='".$self->{queryID}."'>$outputMOBYArticles</moby:mobyData>";

}

##################################################################################
# Return ServiceNotes tag inserting MobyExceptions that has been giving by input #
##################################################################################
sub embedExceptionsIntoServiceNotes {
	# Get parameters
	my($self, $outputMOBYExceptions) = @_;

	# Returns MOBYData response
	return "<serviceNotes>$outputMOBYExceptions</serviceNotes>";

}

# UPDATE: 01-02-2006-----------------
# REASON: Method that returns empty mobyStatus during asynchronous callings
# Modified by jmrc

############################################
# Return xml block of one empty MobyStatus #
############################################
sub retrieveEmptyMobyStatus {
	# Get parameters
	my($self) = shift;
	
	croak("This is an instance method!")  unless(ref($self));
	
	return "<moby:mobyStatus moby:queryID='".$self->{queryID}."' />";
} # End retrieveEmtyMobyStatus
# UPDATE: 01-02-2006-----------------


sub DESTROY {}

1;

###############################
# End General Purpose Package #
###############################
__END__

=head1 NAME

MOBY::Client::Exception::MobyException - MobyException

=head1 DESCRIPTION

Class that contains exception instance and exception methods

=head1 AUTHORS

Jose Manuel Rodriguez Carrasco -jmrodriguez@cnio.es- (INB-CNIO)

=head1 METHODS

=head2 new

B<Function:> Create new instance of exception class.

B<Args:> 
	- querID from one MobyData assign to exception.
	- refElement, reference to articleName.
	- Exception Code.
	- Exception Message.
	- Type of exception: error, information, or warning.

B<Returns:> 
	- Exception Instance.

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};

=head2 getExceptionCode

B<Function:> Return exception code.

B<Args:> <empty>

B<Returns:> 
	- Integer: Exception Code.

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				print "Code: ".$exception->getExceptionCode()."\n";
			}
		}

=head2 getExceptionMessage

B<Function:> Return exception message.

B<Args:> <empty>

B<Returns:> 
	- String: Exception message.

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				print "Message: ".$exception->getExceptionMessage()."\n";
			}
		}

=head2 getExceptionType

B<Function:> Return type of exception.

B<Args:> <empty>

B<Returns:> 
	- String (error, information, warning): Exception type of exception.

B<Usage:>

		my ($exception);
		eval {
			system("Your a$exceptionpplication") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				print "Type: ".$exception->getExceptionType()."\n";
			}
		}

=head2 setExceptionCode

B<Function:> Assign exception code.

B<Args:> 
	- Integer: Exception Code.

B<Returns:> <empty>

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new());
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				# Add new attribute
				$exception->setExceptionCode(200);
			}
		}

=head2 setExceptionMessage

B<Function:> Assign exception message.

B<Args:> 
	- String: Exception message.

B<Returns:> <empty>

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new());
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				# Add new attribute
				$exception->setExceptionMessage("Add new description");
			}
		}

=head2 setExceptionType

B<Function:> Assign type of exception to attribute of class.

B<Args:> 
	- String (error, information, warning): type of exception.

B<Returns:> <empty>

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new());
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				# Add new attribute
				$exception->setExceptionType("error");
			}
		}

=head2 retrieveExceptionResponse

B<Function:> Return xml block that will be the exception response (error, warning or information).

B<Args:> <empty>

B<Returns:>
	 - xml block of exception response. Example of 'error' block:

		<mobyException refQueryID='queryID' refElement='refElement' severity='error'>
			<exceptionCode>code</exceptionCode>
			<exceptionMessage>error message + new description</exceptionMessage>
		</mobyException>

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				print "Exception Response: ".$exception->retrieveExceptionResponse()."\n";
			}
		}

=head2 retrieveEmptyMobyData

B<Function:> Return xml block of one empty MobyData.

B<Args:> <empty>

B<Returns:>
	- xml block of one empty MobyData:

		<moby:mobyData moby:queryID='queryID' />

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				print "Empty MobyData Response: ".$exception->retrieveEmptyMobyData()."\n";
			}
		}

=head2 retrieveEmptyMobySimple

B<Function:> Return xml block of one empty simple MobyArticle.

B<Args:>
	 - String: name of output article.

B<Returns:>
	 - xml block of one empty simple MobyArticle:

		<moby:Simple moby:articleName='outputArticle' />

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				my ($emptyMobyResponse) = $exception->retrieveEmptyMobySimple('outputArticle');
			}
		}

=head2 retrieveEmptyMobyCollection

B<Function:> Return xml block of one empty collection MobyArticle.

B<Args:>
	 - String: name of output article.

B<Returns:>
	 - xml block of one empty collection MobyArticle:

		<moby:Collection moby:articleName='outputArticle' />

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				my ($emptyMobyResponse) = $exception->retrieveEmptyMobyCollection('outputArticle');
			}
		}

=head2 embedMOBYArticlesIntoMOBYData

B<Function:> Return MobyData inserting MobyArticles that has been giving by input.

B<Args:>
	 - xml block which contains MobyArticles.

B<Returns:>
	 - xml block of MobyData:

		<moby:mobyData moby:queryID='queryID'>output MOBYArticles</moby:mobyData>

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				my ($emptyMobyResponse) = $exception->retrieveEmptyMobyCollection('outputArticle');
				print "Moby Response: ".$exception->embedMOBYArticlesIntoMOBYData($emptyMobyResponse);
			}
		}

=head2 embedExceptionsIntoServiceNotes

B<Function:> Return ServiceNotes tag inserting MobyExceptions that has been giving by input.

B<Args:>
	 - xml block which contains MobyExceptions.

B<Returns:>
	 - xml block of Service Notes:

		<serviceNotes>$outputMOBYExceptions</serviceNotes>

B<Usage:>

		my ($exception);
		eval {
			system("Your application") || die ($exception = MOBY::Client::Exception::MobyException->new(
												code => 200,
												queryID => 1,
												refElement => 'test',
												message => 'Add new description',
												type => 'error',
												));
		};
		if ($@) {
			if ($exception->isa('MOBY::Client::Exception::MobyException')) { # Moby Exception
				my ($emptyMobyResponse) = $exception->retrieveEmptyMobyCollection('outputArticle');
				my ($exceptionMobyResponse) = $exception->embedMOBYArticlesIntoMOBYData($emptyMobyResponse);
				print "Service Notes: ".$exception->embedExceptionsIntoServiceNotes($exceptionMobyResponse);
			}
		}

=head2 retrieveEmptyMobyStatus

B<Function:> Return xml block of one empty MobyStatus.

B<Args:> <empty>

B<Returns:>
	 - xml block of one empty MobyStatus:

		<moby:mobyStatus moby:queryID='queryID' />

=cut















