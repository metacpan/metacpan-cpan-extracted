package Log::Cabin::Foundation;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Log::Cabin::Foundation ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.06';


# Preloaded methods go here.

use strict;

my $OFF=0;
my $FATAL=1;
my $ERROR=2;
my $WARN=3;
my $INFO=4;
my $DEBUG=5;
my $ALL=6;

sub new {
    my $class = shift;

    #This singleton is an instance of Log::Cabin This singleton is
    #required to have all multiple logger instances write to the same
    #log files with access to the global logger settings
    my $loggersingleton = shift;
    my $name = shift;

    my $self = bless {}, ref($class) || $class;

    $name = 'default' if (!defined $name);
    $self->{_name} = $name;

    die if(!defined $loggersingleton);
    $self->set_logger_instance($loggersingleton);
    $self->{_LOG_LEVEL} = $self->level();

    return $self;
}

sub name {
    return $_[0]->{_name};
}

sub set_logger_instance{
    my($self,$instance) = @_;
    $self->{_logsimpleobj} = $instance;
}

sub fatal{
    my($self,$msg) = @_;
    if($self->{_LOG_LEVEL} >= $FATAL || $self->{_logsimpleobj}->{_LOG_LEVEL} >= $FATAL){
	$self->{_logsimpleobj}->_output($msg,$self->{_name},$FATAL,caller(0));
    }
}

sub error{
    my($self,$msg) = @_;
    if($self->{_LOG_LEVEL} >= $ERROR || $self->{_logsimpleobj}->{_LOG_LEVEL} >= $ERROR){
	$self->{_logsimpleobj}->_output($msg,$self->{_name},$ERROR,caller(0));
    }
}

sub warn{
    my($self,$msg) = @_;
    if($self->{_LOG_LEVEL} >= $WARN || $self->{_logsimpleobj}->{_LOG_LEVEL} >= $WARN){
	$self->{_logsimpleobj}->_output($msg,$self->{_name},$WARN,caller(0));
    }
}

sub info{
    my($self,$msg) = @_;
    if($self->{_LOG_LEVEL} >= $INFO || $self->{_logsimpleobj}->{_LOG_LEVEL} >= $INFO){
	$self->{_logsimpleobj}->_output($msg,$self->{_name},$INFO,caller(0));
    }
}

sub debug{
    my($self,$msg) = @_;
    if($self->{_LOG_LEVEL} >= $DEBUG || $self->{_logsimpleobj}->{_LOG_LEVEL} >= $DEBUG){
	$self->{_logsimpleobj}->_output($msg,$self->{_name},$DEBUG,caller(0));
    }
}

sub logdie{
    my($self,$msg) = @_;
    $self->{_logsimpleobj}->_output($msg,$self->{_name},$FATAL,caller(0));
    my($package,$filename,$line,$subroutine) = caller(0);
    die "Died with '$msg' at $filename line $line\n";
}

sub is_fatal{
    my $self = shift;
    return ($self->{_LOG_LEVEL} >= $FATAL) || ($self->{_logsimpleobj}->{_LOG_LEVEL} >= $FATAL);
}
sub is_error{
    my $self = shift;
    return ($self->{_LOG_LEVEL} >= $ERROR) || ($self->{_logsimpleobj}->{_LOG_LEVEL} >= $ERROR);
}
sub is_warn{
    my $self = shift;
    return ($self->{_LOG_LEVEL} >= $WARN) || ($self->{_logsimpleobj}->{_LOG_LEVEL} >= $WARN);
}
sub is_info{
    my $self = shift;
    return ($self->{_LOG_LEVEL} >= $INFO) || ($self->{_logsimpleobj}->{_LOG_LEVEL} >= $INFO);
}
sub is_debug{
    my $self = shift;
    return ($self->{_LOG_LEVEL} >= $DEBUG) || ($self->{_logsimpleobj}->{_LOG_LEVEL} >= $DEBUG);
}

#
#Set log levels for named logger
#These log levels will be overridden by the global log level set in the singleton instance of
#Log::Cabin

sub level {
    my($self,$level) = @_;
    $self->{_logsimpleobj}->level($level);
}

sub more_logging{
    my($self,$level) = @_;
    $self->{_LOG_LEVEL} += $level;
}

sub less_logging{
    my($self,$level) = @_;
    $self->{_LOG_LEVEL} -= $level;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Log::Cabin::Foundation - Foundation class for Log::Cabin

=head1 SYNOPSIS

  use Log::Cabin::Foundation;

=head1 DESCRIPTION

See perldoc for Log::Cabin

=head2 EXPORT

None by default.

=head1 SEE ALSO

See perldoc for Log::Cabin

=head1 AUTHOR

Joshua Orvis, E<lt>jorvis@users.sourceforge.netE<gt> and Sam Angiuoli, E<lt>angiuoli@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

This module is available under the Artistic License

http://www.opensource.org/licenses/artistic-license.php

Copyright (C) 2006-2007 by Joshua Orvis and Sam Angiuoli

=cut
