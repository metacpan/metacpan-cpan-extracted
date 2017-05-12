package Log::Cabin;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration    use Log::Cabin ':all';
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
use Sys::Hostname;
use Log::Cabin::Foundation;

my $_DEFAULT_LOG_CATEGORY = "Log::Cabin";
my $_IS_INIT=0;
my $OFF=0;
my $FATAL=1;
my $ERROR=2;
my $WARN=3;
my $INFO=4;
my $DEBUG=5;
my $ALL=6;

my $LEVELTEXT = {0=>'OFF',
         1=>'FATAL',
         2=>'ERROR',
         3=>'WARN',
         4=>'INFO',
         5=>'DEBUG',
         6=>'ALL'};

my $SINGLETON_INSTANCE=undef;

## logger collection is a hash to ensure that calls for the same package
#   name return the same logger.  This was previously an array, which
#   was Very Bad.
my %ALL_LOGGERS;

sub new {
    my ($class) = shift;
    if ($_IS_INIT == 1) {
        return $SINGLETON_INSTANCE;
    } else {
        my $self = bless {}, ref($class) || $class;
        $self->_init(@_);

        unless ($self->{_SKIP_INIT}) {
            $_IS_INIT=1;
            $SINGLETON_INSTANCE = $self;
            
            for (values %ALL_LOGGERS) {
                $_->set_logger_instance($SINGLETON_INSTANCE);
            }
        }
        
        return $self;
    }
}

sub DESTROY{
     my $self = shift;
     if(defined $self->{_OUTPUT_HANDLE}){
     close $self->{_OUTPUT_HANDLE};
     }

}

sub _init {
    my $self = shift;
    die if($_IS_INIT==1);
    $self->{_DEFAULT_LOG_LEVEL} = $WARN;
    $self->{_LOG_LEVEL} = $self->{_DEFAULT_LOG_LEVEL};
    $self->{_LOG_FILE} = undef;
    $self->{_HOSTNAME} = hostname;
    $self->{_PID} = $$;
    $self->{_CLOBBER} = 1;
    my %arg = @_;
    foreach my $key (keys %arg) {
        $self->{"_$key"} = $arg{$key};
    }
}

sub initialized{
    return $_IS_INIT;
}

sub get_instance{
    return $SINGLETON_INSTANCE;
}

sub set_file_output{
    my($self,$filename) = @_;
    $self->{_LOG_FILE} = $filename;
    my $filehandle;
    if($self->{_CLOBBER}){
    open($filehandle,"+>",$self->{_LOG_FILE})
        or die "Can't open log file for writing $self->{_LOG_FILE}";
    }
    else{
    open($filehandle,">",$self->{_LOG_FILE})
        or die "Can't open log file for writing $self->{_LOG_FILE}";
    }
    $self->{_OUTPUT_HANDLE} = $filehandle;
}

sub set_output{
    my($self,$handle) = @_;
    $self->{_OUTPUT_HANDLE} = $handle;
}

sub level{
    my ($self, $level) = @_;
    if (defined $level && $level =~ /^\-*\d+$/) {
        $self->{_LOG_LEVEL} = $level;
    }
    return $self->{_LOG_LEVEL};
}

sub more_logging{
    my($self,$level) = @_;
    if(defined $level && $level =~ /^\-*\d+$/){
    $self->{_LOG_LEVEL} += $level;
    }
}

sub less_logging{
    my($self,$level) = @_;
    if(defined $level && $level =~ /^\-*\d+$/){
    $self->{_LOG_LEVEL} -= $level;
    }
}

sub _output{
    my($self,$msg,$loggername,$level,$package,$filename,$line,$subroutine) = @_;
    my $datestamp = localtime(time());
    if (defined $self->{_OUTPUT_HANDLE}) {
        print {$self->{_OUTPUT_HANDLE}} "$loggername $LEVELTEXT->{$level} $datestamp $self->{_HOSTNAME}:$self->{_PID} $filename:$package:$subroutine:$line || $msg\n";
    }
}

sub get_logger {
    my($class, @args) = @_;

    my $singleton;
    if (defined $SINGLETON_INSTANCE) {
        $singleton = $SINGLETON_INSTANCE;
    } elsif (ref $class) {
        $singleton = $class;
    } else {
        $singleton = new Log::Cabin('SKIP_INIT'=>1);
    }
    
    if (!ref $class) {
        @args = ($class,@args);
    }
    
    my $loggerinst = new Log::Cabin::Foundation($singleton, @args);
    $ALL_LOGGERS{$loggerinst->name} = $loggerinst;
    return $loggerinst;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Log::Cabin - Partial implementation of Log::Log4perl with reduced disk IO.

=head1 SYNOPSIS

    use Log::Cabin;

    my $log_level = 'WARN';

    my $logsimple = new Log::Cabin();
    $logsimple->level( 4 );

    $logsimple->set_file_output( 'some.file.log' );
    # another option
    # $logsimple->set_output(*STDERR);

    my $logger = $logsimple->get_logger('some.category');

    $logger->debug("this is a debug message");
    $logger->info("here's an info message");
    $logger->warn("now a warning message");
    $logger->error("things are going down");
    $logger->fatal("it's all gone pete tong");
    
    #### the output some.file.log will look like this ####
    some.category INFO Wed Apr 18 02:27:10 2007 colossus:21151 ./test.pl:main:Log::Cabin::Foundation::info:18 || here's an info message
    some.category WARN Wed Apr 18 02:27:10 2007 colossus:21151 ./test.pl:main:Log::Cabin::Foundation::warn:19 || now a warning message
    some.category ERROR Wed Apr 18 02:27:10 2007 colossus:21151 ./test.pl:main:Log::Cabin::Foundation::error:20 || things are going down
    some.category FATAL Wed Apr 18 02:27:10 2007 colossus:21151 ./test.pl:main:Log::Cabin::Foundation::fatal:21 || it's all gone pete tong       
    ######################################################

=head1 DESCRIPTION

Log::Cabin provides a selection of the features of Log::Log4perl but with 
a focus on reduced disk IO.  Just calling 'use Log::Log4perl' results in
hundreds of stat calls to the file system.  If you have a shared file system
with many nodes running perl scripts at once, this could result in a significant
decrease in performance.

After implementing this module we were able to cut up to 70,000 stat/open
calls per second on our NFS.  Of course, this module doesn't currently support
all the features of Log::Log4perl, but many of the most comment ones are
implemented.

=head2 EXPORT

None by default.

=head1 SEE ALSO

The usage of this module is similar to Log::Log4perl.

=head1 AUTHOR

Joshua Orvis, E<lt>jorvis@users.sourceforge.netE<gt> and Sam Angiuoli, E<lt>angiuoli@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

This module is available under the Artistic License

http://www.opensource.org/licenses/artistic-license.php

Copyright (C) 2006-2007 by Joshua Orvis and Sam Angiuoli


=cut
