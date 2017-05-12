# $Id: MPlayerEmbed.pm,v 1.7 2006/01/02 19:44:41 jodrell Exp $
# Copyright (c) 2005 Gavin Brown. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms as
# Perl itself.
package Gtk2::Ex::MPlayerEmbed;
use constant {
	PAUSE		=> 'pause',
	RESUME		=> 'pause', # 'pause' is really a toggle
	CLOSE		=> 'quit',
};
use Carp;
use FileHandle;
use Gtk2;
use vars qw($VERSION $STATE_ENUM_PKG);
use strict;

our $VERSION = '0.02';


BEGIN {
	our $STATE_ENUM_PKG = sprintf('%s::PlayingState', __PACKAGE__);
	Glib::Type->register_enum(
		$STATE_ENUM_PKG,
		'stopped', 'playing', 'paused'
	);
}

*new = \&Glib::Object::new;

=pod

=head1 NAME

Gtk2::Ex::MPlayerEmbed - a widget to embed the MPlayer media player into GTK+ applications

=head1 SYNOPSIS

	use Gtk2::Ex::MPlayerEmbed;

	my $window = Gtk2::Window->new;

	my $embed = Gtk2::MPlayerEmbed->new;

	$window->add($embed);

	$window->show_all;

	$embed->play("movie.mpg");

	Gtk2->main;

=head1 DESCRIPTION

Gtk2::Ex::MPlayerEmbed allows you to embed a video player into your
applications. It uses the XEMBED system to allow the I<mplayer> program
to insert its window into your application.

=head1 OBJECT HIERARCHY

  Glib::Object
  +----Gtk2::Object
       +----Gtk2::Widget
            +----Gtk2::Container
                 +----Gtk2::Socket
                      +----Gtk2::Ex::MPlayerEmbed

=head1 PROPERTIES

The following properties are accessible through the standard Glib C<get()> and C<set()> methods:

=over


=item C<mplayer_path>

This is the path to the I<mplayer> program. This is C</usr/bin/mplayer> by default.

=item C<args>

This is a string containing the command line arguments passed to I<mplayer> (no
default).

=item C<loaded>

This is a B<boolean> value that indicates whether the I<mplayer> program is
currently running.

=item C<state>

This is an B<enumeration> (described by C<Gtk2::Ex::MPlayerEmbed::PlayingState>)
that indicates the state of the player. C<state> may be one of: C<stopped>,
C<playing>, C<paused>. It is C<stopped> at startup.

=back

=cut

Glib::Type->register(
	Gtk2::Socket::,
	__PACKAGE__,
	properties => [
		Glib::ParamSpec->string(
			'mplayer_path',
			'MPlayer Path',
			'Path to the MPlayer program',
			'/usr/bin/mplayer',
			[qw/readable writable/],
		),

		Glib::ParamSpec->string(
			'args',
			'MPlayer Arguments',
			'The arguments supplied to the mplayer command',
			'',
			[qw/readable writable/],
		),

		Glib::ParamSpec->boolean(
			'loaded',
			'Loaded Flag',
			'Do we have an input loaded?',
			0,
			[qw/readable writable/],
		),

		Glib::ParamSpec->enum(
			'state',
			'Playing state',
			'The current state of the player',
			$STATE_ENUM_PKG,
			'stopped',
			[qw/readable writable/],
		),
	],
);

sub INIT_INSTANCE {
	my $self = shift;
	$self->modify_bg('normal', Gtk2::Gdk::Color->new(0, 0, 0));
	$self->{slave} = FileHandle->new;
	$self->slave->autoflush(1);
	return 1;
}

=pod

=head1 METHODS

	$embed->play([$content]);

This method has two behaviours: if the the C<loaded> property is true (a video
stream has been loaded), and the C<state> property is C<paused>, then it will
resume playing the stream. If C<loaded> is true but the stream is B<not>
paused, then the method will carp() and return undef.

If C<load> is false, and the C<$content> argument is defined, then the player
will attempt to load and play the stream identified by C<$content>, which may
be a path to a file, the URL of a network resource, or a "meta-URI" such as
C<dvd://> or C<dvb://>.

=cut

sub play {
	my ($self, $file) = @_;
	if ($self->get('loaded') && $self->get('state') ne 'stopped') {
		if ($self->get('state') eq 'playing') {
			carp("Can't play while still playing, use stop() first.");
			return undef;

		} else {
			return $self->resume;

		}

	} else {
		my $cmd = sprintf(
			'|%s -slave -wid %d -geometry %dx%d %s "%s" 1>/dev/null 2>/dev/null',
			$self->get('mplayer_path'),
			$self->get_id,
			$self->allocation->width,
			$self->allocation->height,
			$self->get('args'),
			$file
		);
		if (!$self->slave->open($cmd)) {
			croak("Cannot open '$cmd': $!");
			return undef;

		} else {
			$self->set('loaded',	1);
			$self->set('state',	'playing');
			return 1;

		}
	}
}

=pod

	$embed->pause;

This method will pause the current video stream. If the stream is not playing,
this method will carp() and return undef.

=cut

sub pause {
	my $self = shift;
	if (!$self->get('loaded') || $self->get('state') eq 'stopped') {
		carp("Player must be loaded and playing before it can pause/resume.");
		return undef;

	} else {
		$self->set('state', 'paused');
		return $self->tell_slave(PAUSE);

	}
}

=pod

	$embed->resume;

This is just a convenience wrapper around C<pause()>. The C<pause()> method is
really a toggle, and two subsequent calls to C<pause()> will pause and then
resume the stream, so this method exists to disambiguate.

=cut

sub resume { $_[0]->pause }

=pod

	$embed->stop;

This method tells I<mplayer> to quit, and resets the widget's internal state.
Before loading another video stream with C<play()>, use this method first.

=cut

sub stop {
	my $self = shift;
	if (!$self->get('loaded') || $self->get('state') eq 'stopped') {
		carp("Can't stop an unloaded or stopped stream.");

	} else {
		$self->tell_slave(CLOSE);
		$self->slave->close;
		$self->{slave} = FileHandle->new;
		$self->set('loaded', undef);
		$self->set('state', 'stopped');

	}
}

=pod

	$embed->tell_slave($something);

This method sends a command to the I<mplayer> slave process. The available
commands are documented in the mplayer-slave-spec.txt file in the source
distribution.

=cut

sub tell_slave {
	my ($self, $msg) = @_;
	return $self->slave->print("$msg\n");
}

sub slave {
	return $_[0]->{slave};
}

=pod

=head1 PREREQUISITES

=over

=item L<Gtk2>

=item The I<mplayer> program, available from L<http://www.mplayerhq.hu/>.

=back

=head1 TODO

1. Do something about controlling aspect ration. We need a way to get the
aspect ratio of the video stream, and use a L<Gtk2::AspectFrame> to constrain
the shape of the widget.

2. Implement more convenience wrappers around the mplayer command set.

2. Implement a C<stream_ended> signal that watches the I<mplayer> process and
emits when it quits.

=head1 SEE ALSO

L<GStreamer>, for a much more powerful, general purpose multimedia system
that's compatible with GTK+.

=head1 AUTHOR

Gavin Brown (gavin dot brown at uk dot com)  

=head1 COPYRIGHT

(c) 2005 Gavin Brown. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.     

=cut

1;
