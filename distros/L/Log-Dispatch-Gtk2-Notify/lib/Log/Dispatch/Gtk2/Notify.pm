package Log::Dispatch::Gtk2::Notify;
our $VERSION = '0.02';
# ABSTRACT: send log messages to a desktop notification daemon


use Moose;
use MooseX::Types::Moose qw/Str HashRef ArrayRef CodeRef/;
use Log::Dispatch::Gtk2::Notify::Types qw/
    LogLevel
    Widget     is_Widget
    StatusIcon is_StatusIcon
    Pixbuf
/;
use File::Basename;
use Gtk2 -init;
use Gtk2::Notify;

use namespace::clean -except => 'meta';

extends qw/Moose::Object Log::Dispatch::Output/;

has title => (
    is      => 'ro',
    isa     => Str,
    default => sub { basename($0) },
);

has app_name => (
    is       => 'ro',
    isa      => Str,
    default  => __PACKAGE__,
);

has attach_to => (
    is  => 'ro',
    isa => Widget|StatusIcon,
    predicate => 'has_attach_to',
);

has icon_map => (
    is         => 'ro',
    isa        => HashRef[Pixbuf],
    lazy_build => 1,
);

has name => (
    is       => 'bare',
    isa      => Str,
    required => 1,
);

has min_level => (
    is       => 'bare',
    isa      => LogLevel,
    required => 1,
);

has max_level => (
    is  => 'bare',
    isa => LogLevel,
);

has callbacks => (
    is  => 'bare',
    isa => (ArrayRef[CodeRef]) | CodeRef,
);

around new => sub {
    my $orig = shift;
    my $class = shift;

    my $self = $class->$orig(@_);
    $self->_basic_init(@_);

    return $self;
};

sub BUILD {
    my ($self) = @_;
    Gtk2::Notify->init($self->app_name);
}

sub log_message {
    my ($self, %args) = @_;

    my $notification = Gtk2::Notify->new(
        $self->title, $args{message},
    );

    $self->_attach_notification($notification)
        if $self->has_attach_to;

    if (my $icon = $self->icon_map->{ $args{level} }) {
        $notification->set_icon_from_pixbuf($icon);
    }

    $notification->show;

    return;
}

sub _attach_notification {
    my ($self, $notification) = @_;
    my $to = $self->attach_to;

    if (is_StatusIcon($to)) {
        $notification->attach_to_status_icon($to);
    }
    elsif (is_Widget($to)) {
        $notification->attach_to_widget($to);
    }
    else {
        confess 'FAIL';
    }
}

sub _build_icon_map {
    my ($self) = @_;
    my $widget = Gtk2::Button->new;
    return {
        map {
            my $pixbuf = $widget->render_icon('gtk-dialog-' . $_->[0], 'dialog');
            (map { $_ => $pixbuf } @{ $_->[1] })
        } (['error'   => [qw/emergency alert critical error/]],
           ['warning' => [qw/warning/]],
           ['info'    => [qw/notice info debug/]]),
    };
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;

__END__
=pod

=head1 NAME

Log::Dispatch::Gtk2::Notify - send log messages to a desktop notification daemon

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Log::Dispatch::Gtk2::Notify;

    my $notify = Log::Dispatch::Gtk2::Notify->new(
        name      => 'notify',
        min_level => 'debug',
        app_name  => 'MyApp',
        title     => 'Important Message',
    );

    $notify->log(level => 'alert', message => 'Hello, World!');

=head1 DESCRIPTION

This modules allows you to send log messages to the desktop notification
daemon.

=cut

=pod

=for Pod::Coverage BUILD
log_message

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

