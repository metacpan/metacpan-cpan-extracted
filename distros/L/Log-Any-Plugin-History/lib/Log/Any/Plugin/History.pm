package Log::Any::Plugin::History;
# ABSTRACT: Add a message history to a Log::Any adapter

our $VERSION = '0.02';

use strict;
use warnings;

use Log::Any::Adapter::Util qw( log_level_aliases logging_methods );
use Class::Method::Modifiers qw( install_modifier );

sub install {
    my ($class, $adapter_class, %args) = @_;

    my $history = [];
    my $history_size = $args{size} // 10;
    my $timestamp = $args{timestamp} // sub { time };

    my $aliases = { log_level_aliases() };

    # Create history attribute if it doesn't exist
    unless ($adapter_class->can('history')) {
        install_modifier( $adapter_class, 'fresh', history => sub {
            my ($self, $arg) = @_;
            $history = $arg if defined $arg and ref $arg eq 'ARRAY';
            return $history;
        });
    }

    # Create max_history_size attribute if it doesn't exist
    unless ($adapter_class->can('max_history_size')) {
        install_modifier( $adapter_class, 'fresh', max_history_size => sub {
            my ($self, $arg) = @_;

            return $history_size unless $arg;

            $history_size = $arg;
            return $self;
        });
    }

    # Push to history from logging methods
    for my $method ( logging_methods() ) {
        install_modifier( $adapter_class, 'around', $method => sub {
            my $orig = shift;
            my $self = shift;

            my $level   = $aliases->{$method} // $method;
            my $check   = "is_$level";

            return unless $self->$check;

            my $history = $self->history;
            my $max     = $self->max_history_size;

            my $msg = $self->$orig( @_ );

            push @{$history}, [ $timestamp->(), $level, $msg ];
            shift @{$history} while scalar @{$history} > $max;

            return $msg;
        });
    }

    # Make aliases call their counterparts
    for my $alias ( keys %{$aliases} ) {
        install_modifier( $adapter_class, 'around', $alias => sub {
            my $orig = shift;
            my $self = shift;

            my $method = $aliases->{$alias};
            return $self->$method(@_);
        });
    }
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set( 'SomeAdapter' );

    # Add a log history to the adapter
    use Log::Any::Plugin;
    Log::Any::Plugin->add( 'History', size => 5 );

=head1 DESCRIPTION

Log::Any::Plugin::History adds a history mechanism to your L<Log::Adapter>,
modelled after that of L<Mojo::Log>. The history is an array reference with
the most recent messages that have been logged.

=head1 CONFIGURATION

=over 4

=item B<size>

Sets the maximum number of logged messages to store in the history. This value
defaults to 10.

Note that, to more closely mimic the behaviour of L<Mojo::Log>, assigning a
value lower than the current size of the log history will not immediately
discard offending values, since the shifting takes place at the time of logging.

=item B<timestamp>

The log history stores a timestamp for each logged message. By default, this
is the return of a call to C<time>, but this can be overriden with the
B<timestamp> option.

This option takes a code reference, the result of which will be saved in the
history. The subroutine will be called with no arguments, and should return
something that makes sense as a timestamp for your application.

=back

=head1 METHODS

This plugin adds the following two methods to your adapter:

=over 4

=item B<history>

=item B<history( $arrayref )>

Sets or gets the current log history. When used as a getter it returns the
existing value; otherwise it returns the logging object.

=item B<max_history_size>

=item B<max_history_size( $int )>

Sets or gets the current maximum size of the log history. When used as a getter
it returns the existing value; otherwise it returns the logging object.

=back

=head1 SEE ALSO

=over 4

=item * L<Log::Any::Plugin>

=item * L<Mojo::Log>

=back

=head1 AUTHOR

=over 4

=item * José Joaquín Atria (L<jjatria@cpan.org>)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
