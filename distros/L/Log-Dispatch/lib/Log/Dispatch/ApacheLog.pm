package Log::Dispatch::ApacheLog;

use strict;
use warnings;

our $VERSION = '2.70';

use Log::Dispatch::Types;
use Params::ValidationCompiler qw( validation_for );

BEGIN {
    if ( $ENV{MOD_PERL} && $ENV{MOD_PERL} =~ /2\./ ) {
        require Apache2::Log;
    }
    else {
        require Apache::Log;
    }
}

use base qw( Log::Dispatch::Output );

{
    my $validator = validation_for(
        params => { apache => { type => t('ApacheLog') } },
        slurpy => 1,
    );

    sub new {
        my $class = shift;
        my %p     = $validator->(@_);

        my $self = bless { apache_log => ( delete $p{apache} )->log }, $class;
        $self->_basic_init(%p);

        return $self;
    }
}

{
    my %methods = (
        emergency => 'emerg',
        critical  => 'crit',
        warning   => 'warn',
    );

    sub log_message {
        my $self = shift;
        my %p    = @_;

        my $level = $self->_level_as_name( $p{level} );

        my $method = $methods{$level} || $level;

        $self->{apache_log}->$method( $p{message} );
    }
}

1;

# ABSTRACT: Object for logging to Apache::Log objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::ApacheLog - Object for logging to Apache::Log objects

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [ 'ApacheLog', apache => $r ],
      ],
  );

  $log->emerg('Kaboom');

=head1 DESCRIPTION

This module allows you to pass messages to Apache's log object,
represented by the L<Apache::Log> class.

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * apache ($)

An object of either the L<Apache> or L<Apache::Server> classes. Required.

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
