package Log::Any::Adapter::Multiplexor;

use 5.008001;

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Carp 'croak';
use Log::Any::Adapter;
#Default adapter
Log::Any::Adapter->set('Stdout');
 
our $VERSION    = '0.03';

my %LOG_LEVELS = (
                    '0'     => 'emergency',
                    '1'     => 'alert',
                    '2'     => 'critical',
                    '3'     => 'error',
                    '4'     => 'warning',
                    '5'     => 'notice',
                    '6'     => 'info',
                    '7'     => 'debug',
                    '8'     => 'trace',
                );

sub new {
    my $class = shift;
    my $log = shift;
    my %opt = @_;
    my $self = {};
    $self->{log} = $log;
    $self->{adapters} = {};
    $self->{combine} = {};
    bless $self, $class;


    for my $key (keys %opt) {
        my $adapter = shift @{$opt{$key}};
        my @param = @{$opt{$key}};
        $self->set_logger($key, $adapter, @param);

    }

    $log->{filter} = sub {
                                no strict 'refs';
                                my $log_level_name = $LOG_LEVELS{$_[1]} || 'trace';
                                $self->{adapters}->{$log_level_name}->$log_level_name($_[2]);

                                for my $log_level_combine (keys %{$self->{combine}}) {
                                    $self->{adapters}->{$log_level_combine}->$log_level_combine($_[2]) if
                                            $log_level_combine ne $log_level_name;
                                }
                                return;
    };

    return $self;
}


sub set_logger {
    no strict 'refs';
    my ($self, $log_level, $package, @param) = @_;
    my $log = $self->{log};
    $self->{adapters}->{$log_level} = $log->clone();
    eval "require $package";
    if ($@) {
        croak $@;
    }
    $self->{adapters}->{$log_level} = $package->new(@param);

    return 1;
}

sub combine {
    my $self = shift;
    my @param = @_;
    for my $log_level (@param) {
        $log_level = lc($log_level);
        if (not grep {$_ eq $log_level} values %LOG_LEVELS) {
            croak "Wrong log level: $log_level";
        }
        $self->{combine}->{$log_level} = 1;
    }
    return 1;
}

sub uncombine {
    my $self = shift;
    $self->{combine} = {};
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<Log::Any::Adapter::Multiplexor> - Run any Log::Any:Adapter together

=head1 VERSION

 version 0.03

=head1 SYNOPSIS

    #log warn message to a file, but info message to Stdout
    use Log::Any '$log';
    use Log::Any::Adapter;
    use Log::Any::Adapter::Multiplexor;

    #Create Log::Any::Adapter::Multiplexor object
    my $multiplexor = Log::Any::Adapter::Multiplexor->new(
                                                              $log,
                                                              'error' => ['Log::Any::Adapter::File', 'log.txt'],
                                                              'info'  => ['Log::Any::Adapter::Stdout'],
                                                            );
    #Log message to file log.txt
    $log->error("Test error");

    #Log message to Stdout
    $log->info("Test info");

    #You can override the behavior of log level
    #Example: Send warning log message to file warn_log.txt
    $multiplexor->set_logger('warning', 'Log::Any::Adapter::File', 'warn_log.txt');
    $log->warning('Warning message');

    #Combine log level 'info' and 'debug'
    $multiplexor->combine('info', 'debug');
    $log->info($message); 
    #Equals to:
    $log->info($message);
    $log->debug($message);



=head1 DESCRIPTION

B<Log::Any::Adapter::Multiplexor> connects any Log::Any::Adapter to use together

=head1 Functions

Specification function

=head2 new

    my $multiplexor = Log::Any::Adapter::Multiplexor->new($log, %param);

    $log - $Log::Any::log object
%param
key     => Log level name
value   => Arrayref ['Adapter name', @params]

=head2 set_logger

Set or override exists logger for Log::Any::Adapter::Multiplexor object

    $multiplexor->set_logger($log_level, $adapter, @param);
$log_level  => Log levels (e.g. warning, info, error)
$adapter    => Log::Any::Adapter for this log level (etc 'Log::Any::Adapter::File)
@param      => Adapter params (e.g. filename)

=head2 combine

Duplicated logs from different log levels

    $multiplexor->combine('info', 'debug');
    $log->info($message);
    #equals to
    $log->info($message);
    $log->debug($message);

=head2 uncombine

Delete associations of log levels
    $multiplexor->uncombine();

=head1 DEPENDENCE

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

