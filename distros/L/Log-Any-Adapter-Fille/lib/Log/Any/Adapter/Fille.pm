package Log::Any::Adapter::Fille;

#
# Advanced adapter for logging to files
#

use 5.008001;
use strict;
use warnings;
use utf8::all;

use Config;
use Fcntl qw(:flock);
use POSIX;
use IO::File;
use Time::HiRes qw(gettimeofday);
use Log::Any::Adapter::Util ();

use base qw/Log::Any::Adapter::Base/;

our $VERSION = '0.05';

#---

# Log levels (names satisfy the official log names Log::Any)
my %levels = (
    0 => 'EMERGENCY',
    1 => 'ALERT',
    2 => 'CRITICAL',
    3 => 'ERROR',
    4 => 'WARNING',
    5 => 'NOTICE',
    6 => 'INFO',
    7 => 'DEBUG',
    8 => 'TRACE',
);

my $HAS_FLOCK = $Config{d_flock} || $Config{d_fcntl_can_lock} || $Config{d_lockf};

sub new {
    my ( $class, @args ) = @_;

    return $class->SUPER::new(@args);
}

sub init {
    my $self = shift;

    if ( exists $self->{log_level} ) {
        $self->{log_level} = Log::Any::Adapter::Util::numeric_level( $self->{log_level} )
            unless $self->{log_level} =~ /^\d+$/;
    }
    else {
        $self->{log_level} = Log::Any::Adapter::Util::numeric_level('info');
    }

    open( $self->{fh}, ">>", $self->{file} ) or die "Не удалось открыть файл '$self->{file}': $!";
    $self->{fh}->autoflush(1);
}

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';    ## no critic (ProhibitNoStrict)

    my $method_level = Log::Any::Adapter::Util::numeric_level($method);

    *{$method} = sub {
        my ( $self, $text ) = @_;

        return if $method_level > $self->{log_level};

        my ( $sec, $msec ) = gettimeofday;

        # Log line in "date time pid level message" format
        my $msg = sprintf( "%s.%.6d %5d %s %s\n", strftime( "%Y-%m-%d %H:%M:%S", localtime($sec) ), $msec, $$, $levels{$method_level}, $text );

        flock( $self->{fh}, LOCK_EX ) if $HAS_FLOCK;
        $self->{fh}->print($msg);
        flock( $self->{fh}, LOCK_UN ) if $HAS_FLOCK;
        }
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';    ## no critic (ProhibitNoStrict)

    my $base = substr( $method, 3 );

    my $method_level = Log::Any::Adapter::Util::numeric_level($base);

    *{$method} = sub {
        return !!( $method_level <= $_[0]->{log_level} );
        }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Fille - Advanced adapter for logging to files


=head1 SYNOPSIS

    use Log::Any::Adapter ('Fille', file => '/path/to/file.log');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('Fille', file => '/path/to/file.log');

    # with minimum level 'warn'

    use Log::Any::Adapter (
        'Fille', file => '/path/to/file.log', log_level => 'warn',
    );

=head1 DESCRIPTION

Adapter C<Log::Any::Adapter::Fille> is intended for logging messages to the
file. Behavior of this adapter resembles simple built-in adapter behavior
L<Log::Any::Adapter::File|Log::Any::Adapter::File>, but differs from it in
several details.

The C<log_level> attribute may be set to define a minimum level to log.

Category is ignored.

=head1 DIFFERENCE FROM BUILT-IN ADAPTER FILE

Adapter C<Fille> registers logs in advanced format
C<< <date> <time> <PID> <log_level> <message> >>, unlike built-in adapter
C<File>, which registers logs in simple format C<< <localtime> <message> >>.

At the same time:

=over 4

=item *

C<Fille> represents date and time in ISO 8601 format, including microseconds

C<File> represents date in built-in Perl format without microseconds

=item *

C<Fille> registers PID and log_level

C<File> does not register them

=item *

C<Fille> correctly processes messages containing wide character

C<File> displays warning 'Wide character in print at ...'

=back

Example of a log C<Fille>:

    2015-06-02 17:50:50.894774 16315 WARNING Some message

Example of a log C<File>:

    [Tue Jun  2 17:50:50 2015] Some message

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>

=head1 AUTHORS

=over 4

=item *

Mikhail Ivanov <m.ivanych@gmail.com>

=item *

Anastasia Zherebtsova <zherebtsova@gmail.com> - translation of documentation
into English

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
