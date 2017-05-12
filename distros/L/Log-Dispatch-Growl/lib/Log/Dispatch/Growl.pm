package Log::Dispatch::Growl;
use strict;
use warnings;
our $VERSION = '1.0';

use base qw(Log::Dispatch::Output);
use File::Basename qw(basename);
use Params::Validate qw(validate SCALAR BOOLEAN);
Params::Validate::validation_options( allow_extra => 1 );
use Growl::Any;

sub new {
    my $param = shift;
    my $class = ref $param || $param;

    my $self = bless {}, $class;

    $self->_basic_init(@_);
    $self->_init(@_);

    return $self;
}

sub _init {
    my $self = shift;

    my $check = {
	app_name => {
	    type => SCALAR,
	    default => __PACKAGE__,
	},
	title => {
	    type => SCALAR,
	    default => basename( $0 ),
	},
	priority => {
	    type => SCALAR,
	    default => 0,
	    regex => qr{^\-*[0-2]$}o,
	},
	icon_file => {
	    type => SCALAR,
	    default => undef,
	},
    };

    my %p = validate( @_, $check );

    $self->{app_name} = $p{app_name};
    $self->{title} = $p{title};
    $self->{priority} = $p{priority} || 0;
    $self->{sticky} = defined $p{sticky} && $p{sticky} ? 1 : 0;
    $self->{icon_file} = $p{icon_file};

    $self->{growl} = Growl::Any->new( appname => $self->{app_name}, events => [ $self->_notification_name] );
    return $self;
}

sub _notification_name { "New Message" }

sub log_message {
    my $self = shift;
    my %p = @_;

    $self->{growl}->notify(
        $self->_notification_name,
        $self->{title},
        $p{message},
        $self->{icon_file},
    );
}

1;

__END__

=head1 NAME

Log::Dispatch::Growl - Logging to Growl

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
          outputs => [
              [
                  'Growl',
                  min_level => 'debug',
                  stderr    => 1,
                  newline   => 1
              ]
          ],
      );

  $log->alert("I'm searching the city for sci-fi wasabi");

=head1 DESCRIPTION

Log::Dispatch::Growl allows you to pass log messages to Growl with L<Growl::Any> module.

=head1 AUTHOR

Kang-min Liu E<lt>gugod {at} gugod.orgE<gt>

=head1 SEE ALSO

L<Growl::Any>,
L<Log::Dispatch::MacGrowl> -- an implementation based on Mac::Growl,
L<Log::Dispatch::DesktopNotification>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut