package Log::Dispatch::Colorful;

use strict;
use warnings;

use base qw( Log::Dispatch::Output );

use Data::Dumper;
use Log::Dispatch::Output;
use Params::Validate qw(validate BOOLEAN SCALAR ARRAYREF CODEREF);
use Term::ANSIColor;

Params::Validate::validation_options( allow_extra => 1 );

our $VERSION = '0.03';

our %LEVELS;

BEGIN {
    foreach my $level (qw( debug info notice warning err error crit critical alert emerg emergency )) {
        my $sub = sub {
            my $self = shift;
            my $messages;
            foreach my $arg (@_) {
                if ( ref $arg ) {
                    $messages = Dumper($arg);
                }
                $messages .= $arg || '';
            }

            $self->log( level => $level, message => $messages );
        };

        $LEVELS{$level} = 1;

        no strict 'refs';
        no warnings 'redefine';
        *{ "Log::Dispatch::" . $level } = $sub;
    }
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = validate(
        @_,
        {   stderr => {
                type    => BOOLEAN,
                default => 1
            },
        }
    );

    my $self = bless {}, $class;

    $self->_basic_init(%p);

    $self->{color}  = exists $p{color}  ? $p{color}  : {};
    $self->{stderr} = exists $p{stderr} ? $p{stderr} : 1;

    my @collbacks = $self->_get_callbacks(%p);
    unshift @collbacks, sub {
        my %p = @_;

        if ( $self->{color}->{ $p{level} }->{text} ) {
            $p{message} = color( $self->{color}->{ $p{level} }->{text} ) . $p{message} . color('reset');
        }

        if ( $self->{color}->{ $p{level} }->{background} ) {
            $p{message} = color( 'on_' . $self->{color}->{ $p{level} }->{background} ) . $p{message} . color('reset');
        }

        $p{message};
    };

    $self->{callbacks} = \@collbacks;

    return $self;
}

sub log {
    my $self = shift;

    my %p = validate( @_, { level => { type => SCALAR }, } );

    return unless $self->_should_log( $p{level} );

    $p{message} = $self->_apply_callbacks(%p)
        if $self->{callbacks};

    $self->log_message(%p);
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    if ( $self->{stderr} ) {
        print STDERR $p{message};
    }
    else {
        print STDOUT $p{message};
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Log::Dispatch::Colorful - Object for logging to screen.

=head1 SYNOPSIS

  use Log::Dispatch::Colorful;

  my $screen = Log::Dispatch::Colorful->new(
      name      => 'screen',
      min_level => 'debug',
      stderr    => 1,
      format    => '[%d] [%p] %m at %F line %L%n',
      color     => {
          info  => { text => 'green', },
          debug => {
              text       => 'red',
              background => 'white',
          },
          error => {
              text       => 'yellow',
              background => 'red',
          },
      }
  );

  $screen->log( level => 'error', message => "look at that rainbow!\n" );

  # dump reference variants!
  my $data = {
      foo => 'bar',
  };
  $screen->log( level => 'debug', message => $data );

=head1 DESCRIPTION

Log::Dispatch::Colorful is provides an object for logging to the screen.

=head1 ATTENTION

this module is rewrite Log::Dispatch method for Dumper.
if you don't need Dumper, you think about using L<Log::Dispatch::Screen::Color>.

=head1 METHODS

=head2 new

This method takes a hash of parameters.

=head2 log

Sends a message if the level is greater than or equal to the object's
minimum level.  This method applies any message formatting callbacks
that the object may have.
(in Log::Dispatch::Output).

=head2 log_message

Sends a message to the appropriate output.  Generally this shouldn't
be called directly but should be called through the C<log()> method
(in Log::Dispatch::Output).

=head1 AUTHOR

Daisuke Komatsu E<lt>vkg.taro@gmail.comE<gt>

=head1 SEE ALSO

L<Log::Dispatch>, L<Log::Dispatch::Screen>, L<Catalyst::Plugin::Log::Colorful>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
