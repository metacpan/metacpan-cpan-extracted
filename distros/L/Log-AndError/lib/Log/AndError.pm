package Log::AndError;
#require 5.6.0;
require 5.005;
$Log::AndError::VERSION = 1.01;
use strict;
#use warnings;
use Log::AndError::Constants qw(:all);


##############################################################################
## Variables
##############################################################################

my %Deflt = (
	'LOG_LOGGER' => \&_log,
	'LOG_SERVICE_NAME' => 'GENERIC',
	'LOG_DEBUG_LEVEL'  =>  DEBUG1,
	'LOG_INFO_LEVEL' => INFO,
	'LOG_ALWAYSLOG_LEVEL' => ALWAYSLOG,
    'LOG_ERROR_CODE' => undef,
    'LOG_ERROR_MSG' => undef,
	'LOG_TEMPLATE' => "%s: LEVEL[%d]: %s",
);

##############################################################################
## Documentation
##############################################################################
=pod

=head1 NAME

Log::AndError - Logging module for ISA inclusion in other modules or as a standalone module.

=head1 SYNOPSIS

	use Log::AndError;
        @ISA = qw(Log::AndError);
		Remember to set values with the provided methods
	or
	use Log::AndError;
	use Log::AndError::Constants qw(:all);
	my $ref_logger = Log::AndError->new(
		'LOG_LOGGER' => \&log_sub,
		'LOG_SERVICE_NAME' => 'GENERIC', # Use this to seperate log entries from different modules in your app.
		'LOG_DEBUG_LEVEL'  =>  DEBUG1, # See Log::AndError::Constants for example
		'LOG_INFO_LEVEL' => INFO, # See Log::AndError::Constants for example
		'LOG_ALWAYSLOG_LEVEL' => ALWAYSLOG, # See Log::AndError::Constants for example
	);

	$self->logger(DEBUG3, 'my_sub('.join(',',@_).')'); 
		# for instance logs the entry into a subroutine.
	$self->logger(ALWAYSLOG, 'Something is wrong'); 
		# logs an error when it is always wanted

	After you do this:
		$self->error($error_code, $error_msg);
	Your Caller does this:
		my($err,$msg) = $obj_ref->error();
	to retrieve the errors.

=head1 DESCRIPTION

This is a generic log and error class for Perl modules. There are two distinct pieces here. The error functions and the logging. The error functions are most convenient when inherited by your package although this is not needed. They are mostly here for convenience and to promote "good" behavior. The logging functions are the more complex piece and is the bulk of the code.  

To use the logging function pass in a reference to an anonymous sub routine that directs the error output to where you want it to go. There are a few sample subs located under this class. The default outputs to STDERR via C<warn()>.

The DEBUG constants are always >=0 and the ALWAYSLOG and INFO type constants always need to be <= -2 (-1 == undef on most systems). See Log::AndError::Constants for an example. 

Examples forthcoming at some point. 

Hey, it beats overwriting %SIG{__WARN__} with an anonymous sub for error string grabbing. 

=head1 METHODS

=cut

DESTROY {
my $self = shift;

}

# NO EXPORTS NEEDED 
# We're a good little module.
#@Log::AndError::ISA = qw(Log::AndError::Constants);
##############################################################################
## constructor
##############################################################################
# Generally ISA Dependant
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless($self, $class);

# This loads $self up with all of the default options.
	foreach my $nomen (keys(%Deflt)){
		$self->{$nomen} = $Deflt{$nomen};
	}
# This overwrites any default values in $self with stuff passed in.
	my %Cfg = @_;
        @{$self}{keys(%Cfg)} = values(%Cfg);
return $self;
}


##############################################################################
# Application subroutines 
##############################################################################
##############################################################################
sub service_name {
=pod

=head2 service_name()

C<Log::AndError::service_name()>

=over 2

=item Usage:

	$service_name = $obj_ref->service_name(); #From Caller's Perspective
	or
	$self->service_name('GENERIC');

=item Purpose:

Gets or sets the currently used service name. The default is in the POD above and can be retrieved at runtime from the return value.

=item Returns:

($service_name) if set.

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'service_name('.join(',',@_).')'); # DO NOT DO THIS!
my $key = 'LOG_SERVICE_NAME';
   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){ 
		$self->{$key} = $_[0]; 
	}

return($self->{$key});
}

##############################################################################
sub debug_level {
=pod

=head2 debug_level()

C<Log::AndError::debug_level()>

=over 2

=item Usage:

	$debug = $obj_ref->debug_level();  #From Caller's Perspective
        or
        $self->debug_level(1);

=item Purpose:

Sets or gets the debug level. Should be >= 0. If you decide against that then make sure you know what you are doing and info/alwayslog do not interfere. The default is in the POD above and can be retrieved at runtime from the return value.

=item Returns:

($debug_level) if set.

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'debug_level('.join(',',@_).')'); # DO NOT DO THIS!
my $key = 'LOG_DEBUG_LEVEL';
   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){ 
		$self->{$key} = $_[0]; 
	}

return($self->{$key});
}


##############################################################################
sub info_level {
=pod

=head2 info_level()

C<Log::AndError::info_level()>

=over 2

=item Usage:

	$info_level = $obj_ref->info_level();  #From Caller's Perspective
        or
        $self->info_level(INFO); # -2 from Log::AndError::Constants

=item Purpose:

Sets or gets the info debug level. Should be <= -2. If you decide against that then make sure you know what you are doing and info/alwayslog do not interfere. The default is in the POD above and can be retrieved at runtime from the return value.

=item Returns:

($info_level) if set.

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'info_level('.join(',',@_).')'); # DO NOT DO THIS!
my $key = 'LOG_INFO_LEVEL';
   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){ 
		$self->{$key} = $_[0]; 
	}

return($self->{$key});
}


##############################################################################
sub alwayslog_level {
=pod

=head2 alwayslog_level()

C<Log::AndError::alwayslog_level()>

=over 2

=item Usage:

	$alwayslog_level = $obj_ref->alwayslog_level();  #From Caller's Perspective
        or
        $self->alwayslog_level(ALWAYSLOG); # -3 from Log::AndError::Constants

=item Purpose:

Sets or gets the alwayslog level. Should be <= -2. If you decide against that then make sure you know what you are doing and info/alwayslog do not interfere. The default is in the POD above and can be retrieved at runtime from the return value.

=item Returns:

($alwayslog_level) if set.

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'alwayslog_level('.join(',',@_).')'); # DO NOT DO THIS!
my $key = 'LOG_ALWAYSLOG_LEVEL';
   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){ 
		$self->{$key} = $_[0]; 
	}
return($self->{$key});
}


##############################################################################
sub template{
=pod

=head2 template()

C<Log::AndError::template()>

=over 2

=item Usage:

	my $template = $obj_ref->template();  #From Caller's Perspective
        or 
       my $template = $self->template("%s: LEVEL[%d]: %s");

=item Purpose:

This is a method for setting the sprintf() template for the logging method. It must have a %s(string), %d(decimal), %s(string) format to it. What you place in between is up to you. The default is in the POD above and can be retrieved at runtime from the return value.

=item Returns:

($template) if set and passes syntax test.

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'template('.join(',',@_).')');# DO NOT DO THIS!
my($ok, $error) = (1, undef);
my $key = 'LOG_TEMPLATE';
   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}

	if(@_) {
		if(_template_check($_[0])){
		    $self->{$key} = $_[0];
		}
		else{
			($ok, $error) = (undef, 'Bad sprintf() Template');
			$self->{$key} = undef;
		}
	}

$self->error($ok, $error);
return($self->{$key});
}

##############################################################################
sub error{
=pod

=head2 error()

C<Log::AndError::error()>

=over 2

=item Usage:

	my($err,$msg) = $obj_ref->error();  #From Caller's Perspective
        or 
        $self->error($error_code, $error_msg);

=item Purpose:

This is a wrapper for the C<error_code()> and C<error_msg()> functions. Remember that this is most useful when inherited by your module via ISA.

=item Returns:

($err, $msg) Values are up to you. See Message for details

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'error('.join(',',@_).')');# DO NOT DO THIS!
 	if (@_){
 		my ($code,$msg) = ($_[0], $_[1]);
		$self->error_code($code);
		$self->error_msg($msg);
	}
return($self->error_code(),$self->error_msg());
}


##############################################################################
sub error_code{
=pod

=head2 error_code()

C<Log::AndError::error_code()>

=over 2

=item Usage:

	$err = $obj_ref->error_code();  #From Caller's Perspective
        or 
        $self->error_code($code);

=item Purpose:

Sets or gets the last error code encountered. Remember that this is most useful when inherited by your app via ISA.

=item Returns:

($err) Values are up to you.

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'error_code('.join(',',@_).')'); # DO NOT DO THIS!
my $key = 'LOG_ERROR_CODE';
   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){
		$self->{$key} = $_[0]; 
	}
return($self->{$key});
}

##############################################################################
sub error_msg{

=pod

=head2 error_msg()

C<Log::AndError::error_msg()>

=over 2

=item Usage:

	$msg = $obj_ref->error_msg();  #From Caller's Perspective
        or
        $self->error_msg($msg);

=item Purpose:

Sets or gets the textual description of last error. Remmber that this is most useful when inherited by your app via ISA. 

=item Returns:

($msg) Values are up to you.

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'error_msg('.join(',',@_).')'); # DO NOT DO THIS!
my $key = 'LOG_ERROR_MSG';
   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){ 
		$self->{$key} = $_[0]; 
	}
return($self->{$key});
}

##############################################################################
sub logger {

=pod

=head2 logger()

C<Log::AndError::logger()>

=over 2

=item Usage:

	my($err, $msg) = $self->logger(DEBUG_CONSTANT, $msg);

=item Purpose:

Logs messages. 

=item Returns:

($err, $msg) undef is OK. Everything else > 0 is an error. See Message for details

=back

=cut
my $self = shift;
####$self->logger(DEBUG3, 'add('.join(',',@_).')'); # DO NOT DO THIS!
my($level,$msg) = ($_[0], $_[1]);
my($nok,$error) = (undef, 'ENTRY NOT LOGGED');
my $key = 'LOG_LOGGER';

   	if(!exists($self->{$key})){
		$self->{$key} = $Deflt{$key};
	}
	if(( ($level <= $self->debug_level) && ($level >= 0) ) || ($level == $self->info_level) || ($level == $self->alwayslog_level)) { 
		$self->{$key}->(sprintf($self->template,$self->service_name,$level,$msg));
		($nok, $error) = (undef, 'ENTRY LOGGED'); 
	}
#$self->error($nok,$error); # DO NOT do this as it screws up ISA users
return($nok,$error);
}


#################################################################################
## Private Methods
#################################################################################

##############################################################################
sub _log {
warn(join(', ',@_));
}

sub _template_check {
my $temp = $_[0];
return($temp =~ m/.*\%s.*\%d.*\%s.*/gox);
}

=pod

=head1 HISTORY

=head2 See Changes file in distribution.

=head1 TODO

=over 1

=item *

More Documentation.

=item * 

More samples Log functions. (syslog, SQL, etc...) 
The SQL example should implement a time sequence for preserving order

=back

=head1 AUTHOR

=over 1

Thomas Bolioli <Thomas_Bolioli@alumni.adelphi.edu>

=back

=head1 THANKS

=over 1

Thanks to John Ballem of Brown University for the Constants module and the push to do this one. 

=back


=head1 COPYRIGHT

Copyright (c) 2001 Thomas Bolioli. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 1

=item *

perl

=item *

Log::AndError::Constants

=cut

1;
