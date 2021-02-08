package Log::Dispatch::Code;

use strict;
use warnings;

our $VERSION = '2.70';

use Log::Dispatch::Types;
use Params::ValidationCompiler qw( validation_for );

use base qw( Log::Dispatch::Output );

{
    my $validator = validation_for(
        params => { code => { type => t('CodeRef') } },
        slurpy => 1,
    );

    sub new {
        my $class = shift;

        my %p = $validator->(@_);

        my $self = bless { code => delete $p{code} }, $class;
        $self->_basic_init(%p);

        return $self;
    }
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    delete $p{name};

    $self->{code}->(%p);
}

1;

# ABSTRACT: Object for logging to a subroutine reference

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Code - Object for logging to a subroutine reference

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Code',
              min_level => 'emerg',
              code      => \&_log_it,
          ],
      ]
  );

  sub _log_it {
      my %p = @_;

      warn $p{message};
  }

=head1 DESCRIPTION

This module supplies a simple object for logging to a subroutine reference.

=for Pod::Coverage new log_message

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * code ($)

The subroutine reference.

=back

=head1 HOW IT WORKS

The subroutine you provide will be called with a hash of named arguments. The
two arguments are:

=over 4

=item * level

The log level of the message. This will be a string like "info" or "error".

=item * message

The message being logged.

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
