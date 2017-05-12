use strict;
use warnings;

package IPC::Open3::Callback::Logger;
$IPC::Open3::Callback::Logger::VERSION = '1.19';
# ABSTRACT: A logger for when Log4perl is not available
# PODNAME: IPC::Open3::Callback::Logger

use Carp;

our $AUTOLOAD;
my %levels = (
    all    => 0,
    trace  => 1,
    debug  => 2,
    info   => 3,
    'warn' => 4,
    error  => 5,
    fatal  => 6,
    off    => 7
);
my $logger;

sub _new {
    my ( $class, @args ) = @_;
    return bless( {}, $class )->_init(@args);
}

sub AUTOLOAD {
    my ( $self, @message ) = @_;

    my $method = substr( $AUTOLOAD, length(__PACKAGE__) + 2 );

    if (   $method =~ /^is_(.*)$/
        && $1 ne 'all'
        && $1 ne 'off'
        && defined( $levels{$1} ) )
    {
        return $self->_is_enabled($1);
    }
    elsif ( $method ne 'all' && $method ne 'off' && defined( $levels{$method} ) ) {
        if ( $self->_is_enabled($method) ) {
            print( '(', uc($method), '): ', @message, "\n" );
        }
    }
    else {
        croak("undefined method: $method");
    }
}

sub DESTROY {

    # dont print anything
}

sub get_logger {
    if ( !$logger ) {
        $logger = IPC::Open3::Callback::Logger->_new();
    }
    return $logger;
}

sub _init {
    my ( $self, $level ) = @_;

    if ($level) {
        $self->set_level($level);
    }

    return $self;
}

sub _is_enabled {
    my ( $self, $level ) = @_;
    return $levels{$level} && $levels{$level} >= $self->{level};
}

sub set_level {
    my ( $class, $level ) = @_;
    $level = lc($level);

    if ( !defined( $levels{$level} ) ) {
        croak("undefined log level '$level'");
    }

    get_logger()->{level} = $levels{$level};
}

1;

__END__

=pod

=head1 NAME

IPC::Open3::Callback::Logger - A logger for when Log4perl is not available

=head1 VERSION

version 1.19

=head1 SYNOPSIS

  use IPC::Open3::Callback;
  use IPC::Open3::Callback::Logger;
  
  # warn and above log messages will be written to std out
  IPC::Open3::Callback::Logger->set_level( 'warn' );

  my $runner = IPC::Open3::Callback->new();
  my $exit_code = $runner->run_command( 'echo Hello World' );

=head1 DESCRIPTION

This provides a very basic logger for when Log4perl is not available.

=head1 METHODS

=head2 get_logger()

Returns the logger instance.

=head2 set_level( $level )

Sets the log level to one of:

  all
  trace
  debug
  info
  warn
  error
  fatal
  off

=head1 AUTHORS

=over 4

=item *

Lucas Theisen <lucastheisen@pastdev.com>

=item *

Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::Open3::Callback|IPC::Open3::Callback>

=item *

L<IPC::Open3::Callback|IPC::Open3::Callback>

=item *

L<IPC::Open3::Callback::Command|IPC::Open3::Callback::Command>

=item *

L<IPC::Open3::Callback::CommandRunner|IPC::Open3::Callback::CommandRunner>

=item *

L<https://github.com/lucastheisen/ipc-open3-callback|https://github.com/lucastheisen/ipc-open3-callback>

=back

=for Pod::Coverage new AUTOLOAD

=cut
