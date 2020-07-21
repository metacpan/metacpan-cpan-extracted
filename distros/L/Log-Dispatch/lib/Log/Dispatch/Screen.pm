package Log::Dispatch::Screen;

use strict;
use warnings;

our $VERSION = '2.70';

use Encode qw( encode );
use IO::Handle;
use Log::Dispatch::Types;
use Params::ValidationCompiler qw( validation_for );

use base qw( Log::Dispatch::Output );

{
    my $validator = validation_for(
        params => {
            stderr => {
                type    => t('Bool'),
                default => 1,
            },
            utf8 => {
                type    => t('Bool'),
                default => 0,
            },
        },
        slurpy => 1,
    );

    sub new {
        my $class = shift;
        my %p     = $validator->(@_);

        my $self = bless { map { $_ => delete $p{$_} } qw( stderr utf8 ) },
            $class;

        $self->_basic_init(%p);

        return $self;
    }
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    # This is a bit gross but it's important that we print directly to the
    # STDOUT or STDERR handle for backwards compatibility. Various modules
    # have tests which rely on this, so we can't open a new filehandle to fd 1
    # or 2 and use that.
    my $message
        = $self->{utf8} ? encode( 'UTF-8', $p{message} ) : $p{message};

    ## no critic (InputOutput::RequireCheckedSyscalls)
    if ( $self->{stderr} ) {
        print STDERR $message;
    }
    else {
        print STDOUT $message;
    }
}

1;

# ABSTRACT: Object for logging to the screen

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Screen - Object for logging to the screen

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Screen',
              min_level => 'debug',
              stderr    => 1,
              newline   => 1
          ]
      ],
  );

  $log->alert("I'm searching the city for sci-fi wasabi");

=head1 DESCRIPTION

This module provides an object for logging to the screen (really
C<STDOUT> or C<STDERR>).

Note that a newline will I<not> be added automatically at the end of a
message by default. To do that, pass C<< newline => 1 >>.

The handle will be autoflushed, but this module opens it's own handle to fd 1
or 2 instead of using the global C<STDOUT> or C<STDERR>.

=for Pod::Coverage new log_message

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * stderr (0 or 1)

Indicates whether or not logging information should go to C<STDERR>. If
false, logging information is printed to C<STDOUT> instead.

This defaults to true.

=item * utf8 (0 or 1)

If this is true, then the output uses C<binmode> to apply the
C<:encoding(UTF-8)> layer to the relevant handle for output. This will not
affect C<STDOUT> or C<STDERR> in other parts of your code.

This defaults to false.

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
