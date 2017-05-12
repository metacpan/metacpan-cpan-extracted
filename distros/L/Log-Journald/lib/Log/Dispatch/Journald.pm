=head1 NAME

Log::Dispatch::Journald - Journald log dispatcher

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
  outputs => [['Journald',
       min_level => 'info',
       ident     => 'Wheee'
  ]]);

  $log->info('Time to die.');
  $log->log(level => 'error', message => 'Time to die.', yolo => 'Swag');

=head1 DESCRIPTION

This module provides a L<Log::Journald> backend for L<Log::Dispatch>.
It is possible to log arbitrary key-value pairs using the Journald's
structured logging capability.

=cut

package Log::Dispatch::Journald;

use strict;
use warnings;

use Log::Dispatch::Output;

use base qw( Log::Dispatch::Output );

use Params::Validate qw(validate ARRAYREF SCALAR);
Params::Validate::validation_options( allow_extra => 1 );

use Log::Journald;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = @_;

    my $self = bless {}, $class;

    $self->_basic_init(%p);

    return $self;
}

sub log_message {
    my $self = shift;
    my %p    = @_;
    my %log;

    $log{PRIORITY} = $self->_level_as_number( $p{level} );
    while (my ($key, $value) = each %p) {
        $log{uc $key} = $value;
    }

    Log::Journald::send (%log) or warn $!;
}

1;

=head1 SEE ALSO

=over

=item *

L<Log::Dispatch> -- Log dispatcher

=item *

L<Log::Log4perl::Appender::Journald> -- Use this one with L<Log::Log4perl>

=back

=head1 COPYRIGHT

Copyright 2014 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel, L<< <lkundrak@v3.sk> >>

The code is hosted on GitHub L<http://github.com/lkundrak/perl-Log-Journald>.
Bug fixes and feature enhancements are always welcome.
