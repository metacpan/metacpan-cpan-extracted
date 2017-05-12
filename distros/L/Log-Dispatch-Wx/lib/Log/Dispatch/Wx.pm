package Log::Dispatch::Wx;

use strict;
use warnings;
use base qw(Log::Dispatch::Output);

use Wx;

our $VERSION = '0.01';

sub new {
    my( $class, %p ) = @_;
    my $self = bless {}, $class;

    $self->_basic_init(%p);

    return $self;
}

my %level_map =
  ( 0 => 'Wx::LogDebug',
    1 => 'Wx::LogMessage',
    2 => 'Wx::LogMessage',
    3 => 'Wx::LogWarning',
    4 => 'Wx::LogError',
    5 => 'Wx::LogError',
    6 => 'Wx::LogError',
    7 => 'Wx::LogError',
    );


sub log_message {
    my( $self, %p ) = @_;
    my $level = $self->_level_as_number( $p{level} );
    my $sub = $level_map{$level};

    no strict 'refs';
    &$sub( '%s', $p{message} );
}

1;

__END__

=head1 NAME

Log::Dispatch::Wx - Object for logging through Wx::Log*

=head1 SYNOPSIS

  use Log::Dispatch::Wx;

  my $file = Log::Dispatch::Wx->new( name      => 'file1',
                                     min_level => 'info',
                                     );

  $file->log( level   => 'warning',
              message => "I've fallen but I am getting up\n" );

=head1 DESCRIPTION

This module provides a simple object for logging to C<wxLog> under the
Log::Dispatch::* system.

=head1 METHODS

=over 4

=item * new(%p)

This method takes the same parameters as C<Log::Dispatch::Output::new>.

=item * log_message( message => $ )

Sends a message to the appropriate output.  Generally this shouldn't
be called directly but should be called through the C<log()> method
(in Log::Dispatch::Output).

=back

=head1 NOTES

The logging levels used by C<Log::Dispatch> are more fine-grained than
what is offered by the wxWidgets log facility.  The following mapping
is used to determine which wxWidgets log function must be called:

    debug      Wx::LogDebug
    info       Wx::LogMessage
    notice         "
    warning    Wx::LogWarning
    error      Wx::LogError
    critical       "
    alert          "
    emergency      "

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2006 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself

=cut
