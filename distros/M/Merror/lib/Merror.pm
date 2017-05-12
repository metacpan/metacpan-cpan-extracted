=pod

=head1 NAME

Merror - OOP errorhandling with stacktracing ability

=head1 VERSION

1.4

=head1 SYNOPSIS
		
		use Merror;
		
		function create_error {
				my $obj = Merror->new(stackdepth => 16);
				#indicate that an error happened
				$obj->error(1);
				#set an error code
				$obj->ec(-1);
				#set an error description
				$obj->et("This is an error message");
				return($obj);
		}
		
		my $error_obj = create_error();
		#check if an error occured
		if($error_obj->error()) {
				#print out the errorcode (-1)
				print("Errorcode: " . $obj->ec() ."\n");
				#print out the error description (This is an error message)
				print("Error description: " . $obj->et() . "\n");
				#print out the captured stacktrace
				$obj->stacktrace();
		} else {
				print("No error occured\n");
		}
		
=head1 DESCRIPTION

Merror gives you the ability to C<throw> and catch errors in an OOP way. That means if you dont catch errors probably your code will continue running.
One C<big> feature of Merror is that it captures a stacktrace when an error occured that you can print out.

=head1 METHODS

=over 4

=item B<new(option =>>B< value, ...)>

Constructor.

		Example:
		my $obj = Merror->new( stackdepth => 64 );
		
the following options are available:

=over 4

=item stackdepth

Number defining the maximum tracing depth of a stacktrace.

		# example: define tracingdepth of 64
		stackdepth => 64
		
=item errorfile

Name of a file containing you errormapping, See section ERRORFILE for more information about the syntax of the file.

		# example: define errorfile C</etc/merror/testerrors>
		errorfile => C</etc/merror/testerrors>
		
=item ramusage

If set to an value other than undef or false the complete mapping of a given errorfile will be held in RAM instead of parsing it new every time you call an errorcode or error descrption.

		# example: define ramusage
		ramusage => 1
		
=back 

=item B<error(indicate)>

Call this method with 1 as parameter C<indicate> to indicate that an error happened. You can fetch the error state by calling this method without any paramter. It returns 1 if an error occured or 0 if not.

		Example:
		my $obj = Merror->new(stackdepth => 10, errorfile => C</etc/merror/errorfile>, ramusage=>0);
		
		...
		
		#if you formerly called $obj->error(1) than this query whill return 1
		if($obj->error()( {
				...
		}

=item B<ec(errorCode)>

If you call this method with a number this will set the errorcode. Call it without any parameter to get the last errorcode back.

		Example:
		# set error code -255
		$obj->ec(-255);
		# print out the last errorcode
		print($obj->ec()."\n");
		
=item B<et(errorDescription)>

Call this method with a string paramter and this string will be set as the error description. Call it without any parameter to get back the last error description.

		Example:
		# set error description
		$obj->et("Fatal unresolvable error occured");
		# print out the last error description
		print($obj->et()."\n");
		
=item B<mappedError(errorCode)>

This method searches the errorfile for errorCode and sets the errorcode and error description from the mapping

		Example:
		# we got the following mapping in our errorfile: 24: Could not connect to given host
		# set error code and description depending on the mapping
		$obj->mappedError(24);
		# print out the errorcode: 24
		print($obj->ec()."\n");
		# print out the error description: Could not connect to given host
		print($obj->et()."\n");
		
=item B<stacktrace>

Prints out the caputed stacktrace.

=item B<return_stacktrace>

Returns the captured stacktrace as an array where every element is one level ov the stacktrace

		Example:
		my @st = $obj->return_stacktrace();
		foreach (@st) {
				print("$_\n");
		}
		
=item B<merror_copy(destinationStructure)>

You can treat this method as an copy-operator for Merror structures. It will copy the complete internal state ob the calling object into an hash reference indicated by C<destionationStructure>

		Example:
		use Merror;
		my $obj = Merror->new();
		$obj->ec(13);
		$obj->et("Test error");
		
		# will print out: 13
		print($obj->ec()."\n");
		# will print out: Test error
		print($obj->et()."\n");
		
		# now copy the internal state
		my $obj2 = {};
		$obj->merror_copy($obj2);
		
		# will print out: 13
		print($obj2->ec()."\n");
		# will print out: Test error
		print($obj2->et()."\n");
		
=back

=head1 ERRORFILE

By defining a file in the constructor parameter C<errorfile> you have the ability to use this file for your error descriptions.
The syntax of every line of the file is:

		[Errorcode]: [Errordescription]
		-255: Unknown Error occurred

Lines starting with a # will be ignored.
Every line will be parsed through this regular expression:

		/^(\d{1,})\s{0,}:\s{0,}(.*)/

=head1 BUGS
		
None known
		
=head1 ACKNOWLEDGEMENTS

If you find any bugs or got some feature you wish to have implemented please register at C<mantis.markus-mazurczak.de>.

=head1 COPYRIGHT

See README.

=head1 AVAILABILITY

You can allways get the latest version from CPAN.

=head1 AUTHOR

Markus Mazurczak <coding@markus-mazurczak.de>

=cut

package Merror;
our $VERSION = '1.4';

use strict;
use warnings;

sub new {
	my $invocant = shift;
	my %opts	 = @_;
	my $class = ref($invocant) || $invocant;
	my $self = {
		ERROR		=> 0,
		EC			=> 0,
		ET			=> "",
		STACKDEPTH	=> ($opts{stackdepth} || 64),
		ERRORFILE	=> ($opts{errorfile} || undef),
		RAMUSAGE	=> ($opts{ramusage} || 0),
		ERRMAPPING	=> { },
		STACK		=> { },
	};
	
	bless $self, $class;
	
	if(defined($self->{ERRORFILE}) && !-r $self->{ERRORFILE}) {
		$self->{ERROR} = 1;
		$self->{EC} = -255;
		$self->{ET} = "Could not read configured error mapping file: " . $self->{ERRORFILE};
	} elsif(defined($self->{ERRORFILE}) && $self->{RAMUSAGE} != 0) {
		$self->parseErrorFile();
	}
	return($self);
}

sub error {
	my $self = shift;
	if(@_) { 
		$self->{ERROR} = 1;
		fillstack($self);
	}
	else { return($self->{ERROR}); }
}

sub ec {
	my $self = shift;
	if(@_) { $self->{EC} = $_[0]; }
	else { $self->{ERROR}=0;return($self->{EC}); }
}

sub et {
	my $self = shift;
	if(@_) { $self->{ET} = $_[0]; }
	else { $self->{ERROR}=0;return($self->{ET}); }
}

sub mappedError {
	my $self = shift;
	my $errorcode = shift;
	
	if(!defined($errorcode) || !defined($self->{ERRORFILE})) {
		$self->ec(-255);
		$self->et("Undefined error occured");
	} else {
		$self->ec($errorcode);
		$self->et($self->mapErrorCode($errorcode));
	}
}

sub stacktrace {
	my $self = shift;
	$self->{ERROR}=0;
	foreach my $stacklevel(sort(keys(%{$self->{STACK}}))) {
		print("Level: $stacklevel -- File: ");
		print($self->{STACK}->{$stacklevel}->{FILE}." -- Pkg: ");
		print($self->{STACK}->{$stacklevel}->{PKGNAME}." -- Sub: ");
		print($self->{STACK}->{$stacklevel}->{SUBROUTINE}." -- Line: ");
		print($self->{STACK}->{$stacklevel}->{LINE}."\n");
	}
}

sub return_stacktrace {
		my $self = shift;
		my @stack_array;
		my $counter = 0;
		$self->{ERROR}=0;
		foreach my $stacklevel(sort(keys(%{$self->{STACK}}))) {
				$stack_array[$counter] = "Level: $stacklevel -- File: ";
				$stack_array[$counter + 1] = $self->{STACK}->{$stacklevel}->{FILE}." -- Pkg: ";
				$stack_array[$counter + 2] = $self->{STACK}->{$stacklevel}->{PKGNAME}." -- Sub: ";
				$stack_array[$counter + 3] = $self->{STACK}->{$stacklevel}->{SUBROUTINE}." -- Line: ";
				$stack_array[$counter + 4] = $self->{STACK}->{$stacklevel}->{LINE}."\n";
				$counter += 5;
		}
		return(@stack_array);
}

sub merror_copy {
	my ($self, $to) = @_;
	if($self->{EC}) 					{ $to->{EC} 		= $self->{EC}; }
	if($self->{ET}) 					{ $to->{ET} 		= $self->{ET}; }
	if($self->{ERROR}) 				{ $to->{ERROR} 		= $self->{ERROR}; }
	if($self->{STACKDEPTH})	{ $to->{STACKDEPTH} = $self->{STACKDEPTH}; }
	if($self->{STACK}) 				{ $to->{STACK} 		= $self->{STACK}; }
	if($self->{ERRORFILE}) 		{ $to->{ERRORFILE}	= $self->{ERRORFILE}; }
	if($self->{RAMUSAGE}) 		{ $to->{RAMUSAGE}	= $self->{RAMUSAGE}; }
	if($self->{ERRMAPPING}) 	{ $to->{ERRMAPPING}	= $self->{ERRMAPPING}; }
}

# private method
# Captures the stacktrace with a max depth of $self->{STACKDEPTH}
sub fillstack {
	my $self = shift;
	for(my $i=0; $i<$self->{STACKDEPTH}; $i++) {
		if(!defined(caller($i))) { return; }
		my ($pkgname, $file, $line, $subroutine,) = caller($i);
		$self->{STACK}->{$i}->{PKGNAME} 	= ($pkgname || "");
		$self->{STACK}->{$i}->{FILE} 		= ($file || "");
		$self->{STACK}->{$i}->{LINE} 		= ($line || "");
		$self->{STACK}->{$i}->{SUBROUTINE} 	= ($subroutine || "");
	}
}

# private method
# If user wants to parse the complete error mapping file and save it into ram than this function is called
sub parseErrorFile {
	my $self = shift;
	
	open(MAPFILE, $self->{ERRORFILE}) or die("This should never happen (function: parseErrorFile, file: Merror.pm).");
	while(my $line = <MAPFILE>) {
		chomp($line);
		next if($line =~ /^#/ || $line =~ /^\s{0,}$/);
		my ($number, $desc) = ($line =~ /^(\d{1,})\s{0,}:\s{0,}(.*)/);
		if(!defined($number) || !defined($desc) || $number =~ /^\s{1,}$/ || $desc =~ /^\s{1,}$/) {
			$self->{ERROR} = 1;
			$self->{EC} = -254;
			$self->{ET} = "Syntax error in error mapping file (".$self->{ERRORFILE}.") in line: $.";
			return;
		}
		$self->{ERRMAPPING}->{$number} = $desc;
	}
	close(MAPFILE);
}

# private method
# Returns the error description of the given errorcode. If errorcode is undef than an undefined error will be returned.
sub mapErrorCode {
	my $self = shift;
	my $errorcode = shift;
	if(!defined($errorcode)) {
		return("Undefined error occured");
	}
	
	if($self->{RAMUSAGE} != 0) {
		return($self->{ERRMAPPING}->{$errorcode} || "Undefined error occured");
	}
	
	open(MAPFILE, $self->{ERRORFILE}) or die("This should never happen (function: parseErrorFile, file: Merror.pm).");
	while(my $line = <MAPFILE>) {
		chomp($line);
		next if($line =~ /^#/ || $line =~ /^\s{0,}$/);
		my ($number, $desc) = ($line =~ /^(\d{1,})\s{0,}:\s{0,}(.*)/);
		if($number =~ /^\s{1,}$/ || $desc =~ /^\s{1,}$/) {
			return("Undefined error occured");
		}
		if("$errorcode" eq "$number") {
			return($desc);
		}
	}
	close(MAPFILE);
	return("Undefined error occured");
}

1;
