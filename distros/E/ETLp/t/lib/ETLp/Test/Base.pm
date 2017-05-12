package ETLp::Test::Base;

use Moose;
use Test::More;
use ETLp::Config;
use Log::Log4perl;
use FindBin qw($Bin);
use File::Copy;
use File::chdir;

BEGIN {
    extends qw(Test::Class Moose::Object);
}

sub new_args {
    (
        keep_logger     => 0,
        create_log_file => 0,
    );
}

sub csv_dir {
    my $self = shift;
    return "$Bin/tests/csv";
}

sub file_def_dir {
    my $self  = shift;
    return "$Bin/tests/file_defs";
}

sub log_dir {
    my $self = shift;
    return "$Bin/log";
}

sub log_file_name {
    my $self = shift;
    return $self->log_dir().'/test.log';
}

sub test_config_dir {
    my $self = shift;
    return "$Bin/tests/conf";
}

sub prep_csv : Tests(startup) {
    my $self = shift;
    local $CWD = $self->csv_dir();
    
    foreach my $file (glob("*.csv")) {
        copy($file, "${file}.loc");
    }
}

sub prep_conf : Tests(startup) {    
    my $self = shift;
    local $CWD = $self->test_config_dir;
    
    foreach my $file (glob("*.conf")) {
        copy($file, "${file}.loc.conf");
    }
}

sub create_logger : Test(setup) {
    my $self = shift;
    
    my $log_conf;
    my %args = $self->new_args;
    
    foreach my $key (%args) {
        $self->{$key} = $args{$key};
    }
    
    if ($self->{create_log_file}) {
        mkdir $self->log_dir() unless (-d $self->log_dir());
        my $log_file_name = $self->log_file_name;
        $log_conf = qq(
            log4perl.rootLogger=DEBUG,LOGFILE
            
            log4perl.appender.LOGFILE=Log::Dispatch::FileRotate
            log4perl.appender.LOGFILE.filename = $log_file_name
            log4perl.appender.LOGFILE.mode=append
            log4perl.appender.LOGFILE.max      = 5
            log4perl.appender.LOGFILE.size     = 10000000
            log4perl.appender.LOGFILE.layout = PatternLayout
            log4perl.appender.LOGFILE.layout.ConversionPattern = %d %l %p> %m%n
        );
    } else {
        $log_conf = qq(
            log4perl.rootLogger=DEBUG,NULL
            log4perl.appender.NULL=ETLp::Test::Log::Log4perl::Appender::Null
            log4perl.appender.NULL.layout   = Log::Log4perl::Layout::PatternLayout
        );
    }

    Log::Log4perl::init(\$log_conf);
    my $logger = Log::Log4perl::get_logger("DW");
    my $config = ETLp::Config->new(logger => $logger,);
}

sub remove_logfile : Test(teardown){
    my $self = shift;
    unless ($self->{keep_logger}) {
        my $log_file = $self->log_file_name();
        if (-f $log_file) {
            unlink $log_file || die "Cannot unlink $log_file: $!";
            rmdir $self->log_dir();
        }
    }
}

sub rm_csv : Tests(shutdown) {
    my $self = shift;
    local $CWD = $self->csv_dir();
    
    foreach my $file (glob("*.loc")) {
        unlink $file || die $!;
    }
}


sub rm_conf : Tests(shutdown) {
    my $self = shift;
    local $CWD = $self->test_config_dir;
    
    foreach my $file (glob("*.loc.conf")) {
        unlink $file || die $!;
    }
}

sub rm_log {
    my $self = shift;
    local $CWD = $self->log_dir;
    
    foreach my $file (glob("*.locg")) {
        unlink $file || die $!;
    }
}


1;
