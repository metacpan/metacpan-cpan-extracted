package Log::Any::For::Std;

#
# Send output of STDERR to Log::Any
#

use 5.008001;
use strict;
use warnings;

use Log::Any '$log', default_adapter => 'Duperr';

our $VERSION = '0.05';

#---

my $sig;

# Value assignment is needed for futher learning in the PRINT method where the message came from
$SIG{__DIE__} = sub { die @_ if ( $^S or not defined $^S ); $sig = 'DIE' };
$SIG{__WARN__} = sub { $sig = 'WARN'; print STDERR @_ };

# We connect the descriptor STDERR with the current packet for interception of all error messages
tie *STDERR, __PACKAGE__;

# Redefinition of standard constructor for the connnected descriptor STDERR
sub TIEHANDLE {
    my $class = shift;

    bless {}, $class;
}

# Redefinition of standart method PRINT for the connected descriptor STDERR
sub PRINT {
    my ( $self, @msg ) = @_;

    chomp(@msg);

    # Current value in $@ says where the message came from
    if ( defined $sig and $sig eq 'DIE' ) {
        $log->emergency(@msg);
    }
    elsif ( defined $sig and $sig eq 'WARN' ) {
        $log->warning(@msg);
    }
    else {
        $log->notice(@msg);
    }

    # Reset to the default value
    undef $sig;
}

# Redefinition of standard methode BINMODE for the connected descriptor STDERR
# In fact this method makes no sense here but it has to be fulfiled for the backward compatibility
# with the modules that call this method for their own purposes
sub BINMODE { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::For::Std - Send output of STDERR to Log::Any

=head1 SYNOPSIS

In your application (NOT IN THE MODULE!):

    use Log::Any::Adapter;

    # Capture all the messages sent to STDER
    # and log them through Log::Any
    use Log::Any::For::Std;

    # Send all logs to Log::Any::Adapter::File
    Log::Any::Adapter->set('File', '/path/to/file.log');

=cut

=head1 DESCRIPTION

Log::Any provides convenient API for logging of messages. But to ensure
recording of a message into the log you have to evidently call out one of the
logging methods, e.g C<< $log->info('some message') >>.

At the same time it is often needed in programs to log a message which you
evidently didn't output. For example it may be a message output by the
interpreter STDERR as a result of an error.

The module C<Log::Any::For::Std>  logs your messages for you. You can just
write in your application C<use Log::Any::For::Std;> and all the standard error
messages will start logging magically.

=head1 LOGGING EVENTS

The module logs following events:

=over

=item *

Output of any messages to STDERR (e.g, C<print STDERR 'some message'>)

Messages on STDERR will be logged as C<< $log->notice('some message') >>.

=item *

Warnings output (e.g, C<warn 'some message'>)

Warnings will be logged as C<< $log->warning('some message') >>.

=item *

Fatal errors output (e.g, C<die 'some message'>)

Fatal messages will be logged as C<< $log->emergency('some message') >>.

=back

=head1 ATTENTION

Module C<Log::Any::For::Std> redefines descriptor STDERR and signals
C<__WARN__> and C<__DIE__>. These are global variables. Their action applies to
the whole program. In case your program defines these signals too you cannot
use this module.

It means as well that you should not use this module inside other modules. Use
it only in executable script, otherwise hardly detected errors may emerge.

Later on I'll try to do something with it. Sorry.

=head1 SEE ALSO

L<Log::Any|Log::Any>

=head1 AUTHORS

=over

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
