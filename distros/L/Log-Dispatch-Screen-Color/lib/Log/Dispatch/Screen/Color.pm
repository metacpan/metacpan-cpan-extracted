package Log::Dispatch::Screen::Color;
use strict;
use warnings;
use base 'Log::Dispatch::Screen';
our $VERSION = '0.04';

use Params::Validate qw(validate HASHREF BOOLEAN);
Params::Validate::validation_options( allow_extra => 1 );

use Term::ANSIColor ();
require Win32::Console::ANSI if $^O eq 'MSWin32';

our $DEFAULT_COLOR = {
    debug => {},
    info  => {
        text       => 'blue',
        background => undef,
    },
    notice  => {
        text       => 'green',
        background => undef,
    },
    warning  => {
        text       => 'black',
        background => 'yellow',
    },
    error  => {
        text       => 'red',
        background => 'yellow',
    },
    critical  => {
        text       => 'black',
        background => 'red',
    },
    alert  => {
        text       => 'white',
        background => 'red',
        bold       => 1,
    },
    emergency  => {
        text       => 'yellow',
        background => 'red',
        bold       => 1,
    },
};
$DEFAULT_COLOR->{err}   = $DEFAULT_COLOR->{error};
$DEFAULT_COLOR->{crit}  = $DEFAULT_COLOR->{critical};
$DEFAULT_COLOR->{emerg} = $DEFAULT_COLOR->{emergency};


sub new {
    my $proto = shift;
    my $self  = $proto->SUPER::new(@_);

    my %p = validate( @_, {
        color => {
            type     => HASHREF,
            optional => 1,
            default  => +{},
        },
        newline => {
            type => BOOLEAN,
            optional => 1,
            default => 0,
        },
    });

    # generate color table
    my $color = {};
    while (my($level, $val) = each %{ $DEFAULT_COLOR }) {
        my $obj = $p{color}->{$level} || $val;
        $color->{$level} = {
            text       => $obj->{text},
            background => $obj->{background},
            bold       => $obj->{bold},
        };
    }
    $self->{color} = $color;

    # inject color callback
    my @callbacks      = $self->_get_callbacks(%p);
    $self->{callbacks} = [ sub { $self->colored(@_) }, @callbacks ];

    # newline
    if ($p{newline}) {
        push @{$self->{callbacks}}, \&_add_newline_callback;
    }

    $self;
}

my $RESET = Term::ANSIColor::color('reset');
my $BOLD  = Term::ANSIColor::color('bold');
my %COLOR_CACHE;
sub colored {
    my($self, %p) = @_;
    my $message = $p{message};
    my $level   = $p{level};
    return $message unless $level;
    my $map     = $self->{color}->{$level};
    return $message unless $map;

    if (my $name = $map->{text}) {
        my $color = $COLOR_CACHE{$name} ||= Term::ANSIColor::color($name);
        $message = join '', $color, $message, $RESET;
    }
    if (my $name = $map->{background}) {
        my $color = $COLOR_CACHE{"on_$name"} ||= Term::ANSIColor::color("on_$name");
        $message = join '', $color, $message, $RESET;
    }
    if ($map->{bold}) {
        $message = join '', $BOLD, $message, $RESET;
    }

    return $message;
}

sub _add_newline_callback {
    my %p = @_;
    return $p{message} . "\n";
}


1;
__END__

=encoding utf8

=head1 NAME

Log::Dispatch::Screen::Color - attached color for Log::Dispatch::Screen

=head1 SYNOPSIS

  use Log::Dispatch::Screen::Color;

  my $log = Log::Dispatch::Screen::Color->new(
      name      => 'test',
      min_level => 'debug',
      stderr    => 1,
  );

  # not use default color map
  my $log = Log::Dispatch::Screen::Color->new(
      name      => 'test',
      min_level => 'debug',
      stderr    => 1,
      color     => {
          info  => {
              text => 'red',
          },
          error   => {
              background => 'red',
          },
          alert   => {
              text       => 'red',
              background => 'white',
          },
          warning => {
              text       => 'red',
              background => 'white',
              bold       => 1,
          },
      },
  );

  $log->log( level => 'info', message => "I like wasabi!\n" );

=head1 DESCRIPTION

Log::Dispatch::Screen::Color is attaching a color safely for Screen. because L<Log::Dispatch::Colorful> has rewrite L<Log::Dispatch> method problem.

Win32 is supported.

Note that a newline will I<not> be added automatically at the end of a
message by default.  To do that, pass C<newline =E<gt> 1>.

=head1 OVERRIDES

Setting $Log::Dispatch::Screen::Color::DEFAULT_COLOR overrides. default color is changed.

  local $Log::Dispatch::Screen::Color::DEFAULT_COLOR->{info} = {
    text => 'red',
  };

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

L<Log::Dispatch>, L<Log::Dispatch::Screen>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
