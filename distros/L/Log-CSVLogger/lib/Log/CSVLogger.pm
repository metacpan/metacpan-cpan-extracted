package Log::CSVLogger;
use POSIX qw(strftime);
use Text::CSV_XS;
use Path::Class;
our $VERSION = 0.1;

=head1 NAME

Log::CSVLogger

=head1 SYNOPSIS

    $csvlogger = Log::CSVLogger->new("path/to/log.csv");
    
    $csvlogger->debug("Debug Message1","Debug Message2");
    
    $csvlogger->error("Error Message1","Error Message2");


=head1 DESCRIPTION

Log to a file in CSV format.

=head1 METHODS

=cut

=head2 new

It accepts csv file path as a arguement.

    $csvlogger = Log::CSVLogger->new("path/to/log.csv");
  
If the file does not exist it will create it for you.

=cut

sub new {
    my $class = shift;
    my $args = shift;
    
    my $csv = Text::CSV_XS->new;
    my $csvpath = file($args->{'csvfile'}); 
        
    my $self = {
        csv => $csv,
        csvpath => $csvpath,
    };

    bless($self,$class);
    return $self;
}

=head2 debug

This method will print a debug message.

    $csvlogger->debug("Debug Message1","Debug Message2");

    timestamp,debug,Debug Message1,Debug Message2,...,Debug MessageN

=cut


sub debug {
    my $self = shift;
    $self->log('debug', @_);
}


=head2 info

This method will print an info message.

    $csvlogger->info("Info Message1","Info Message2");
  
=cut

sub info {
    my $self = shift;
    $self->log('info', @_);
}

=head2 warn

This method will print a warn message.

    $csvlogger->warn("Warn Message1","Warn Message2");
  
=cut

sub warn {
    my $self = shift;
    $self->log('warn', @_);
}

=head2 error

This method will print an error message.

    $csvlogger->error("Error Message1","Error Message2");
  
=cut

sub error {
    my $self = shift;
    $self->log('error', @_);
}

=head2 log

In case you want to access log function, this method will print a log message with timestamp and passed arguements.

    $csvlogger->log("Log Message1","Log Message2");
  
=cut

sub log{
    my $self = shift;
    if (-f $self->{csvpath} && !-w $self->{csvpath} ){
        print STDERR "File " . $self->{csvpath} . " exists but don't have write permission on it.\n";
        return 0;
    }
    if ( !-f $self->{csvpath} && !-w $self->{csvpath}->parent ){
        print STDERR "File " . $self->{csvpath} . "does not exist and also don't have write permission on it.\n";
        return 0;
    }
    unless (open FILE, ">>", $self->{csvpath}) { 
        print STDERR "Unable to open file " . $@;  
    } 
    my $timestamp = POSIX::strftime( "%a %b %e %H:%M:%S %Y", localtime);
    $self->{csv}->combine ($timestamp,@_);
    my $string = $self->{csv}->string;
    print FILE "$string\n";
    close FILE;
    return 1;
    
}

=head1 AUTHOR

Gaurav Khambhala ( gaurav at deeproot dot co dot in )

=head1 CREDITS

Terence Monteiro

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 or any later version. See http://www.fsf.org/licensing/licenses/gpl.html

=cut

1;
