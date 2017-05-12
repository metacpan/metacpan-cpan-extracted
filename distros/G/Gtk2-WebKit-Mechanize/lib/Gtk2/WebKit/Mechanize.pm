=head1 NAME

Gtk2::WebKit::Mechanize - WWW::Mechanize done with HTML WebKit engine.

=head1 SYNOPSIS

    $mech = Gtk2::WebKit::Mechanize->new;

    $mech->get('http://www.example.org');

    $mech->submit_form(fields => { field_a => 'A', field_b => 'B' });

    # returns "Hello"
    $mech->run_js('return "He" + "llo"');

=head1 DESCRIPTION

This module provides WWW::Mechanize like interface using WebKit browser engine.

Aditionally it allows access to some of JavaScript functionality (e.g. calling
JavaScript functions, accessing alerts and console messages etc.).

=cut
use strict;
use warnings FATAL => 'all';

package Gtk2::WebKit::Mechanize;
use base 'Class::Accessor::Fast';

use Gtk2 -init;
use Gtk2::WebKit;
__PACKAGE__->mk_accessors(qw(console_messages alerts view window));

our $VERSION = '0.01';

=head1 CONSTRUCTION

=head2 Gtk2::WebKit::Mechanize->new;

Constructs new Gtk2::WebKit::Mechanize object.

=cut
sub new {
	my $class = shift;
	my $view = Gtk2::WebKit::WebView->new;
	my $sw = Gtk2::ScrolledWindow->new;
	$sw->add($view);

	my $win = Gtk2::Window->new;
	$win->set_default_size(800, 600);
	$win->add($sw);

	my $self = bless { view => $view, window => $win
			, alerts => [], console_messages => [] }, $class;
	$view->signal_connect('load-finished' => sub { Gtk2->main_quit });
	$view->signal_connect('script-alert' => sub {
		push @{ $self->alerts }, $_[2];
	});
	$view->signal_connect('console-message' => sub {
		push @{ $self->console_messages }, $_[1];
	});

	$win->show_all;

	return $self;
}

=head1 METHODS

=head2 $mech->get($url)

Loads C<$url>.

=cut
sub get {
	my ($self, $url) = @_;
	$self->view->open($url);
	Gtk2->main;
}

=head2 $mech->run_js($js_str)

Evaluates C<$js_str> in the context of the current page.

=cut
sub run_js {
	my ($self, $js) = @_;
	my $fn = "___run_js_$$";
	$self->view->execute_script("function $fn() { $js }; alert($fn());");
	return pop @{ $self->alerts };
}

=head2 $mech->submit_form(%args)

Submits first form on pages using $args{fields}.

=cut
sub submit_form {
	my ($self, %form) = @_;
	while (my ($n, $v) = each %{ $form{fields} }) {
		$self->run_js("(document.getElementsByName('$n'))[0]"
			. ".value = '$v'");
	}
	$self->run_js('(document.getElementsByTagName("FORM"))[0].submit()');
	Gtk2->main;
}

=head1 ACCESSORS

=head2 $mech->title

Returns page title.

=cut
sub title {
	return shift()->view->get_main_frame->get_title;
}

=head2 $mech->content

Returns current page source.

At present it uses document.body.innerHTML. Therefore page source will not
be identical to the one sent by server.

=cut
sub content {
	return shift()->run_js('return document.body.innerHTML');
}

1;

=head1 AUTHOR

    Boris Sukholitko
    CPAN ID: BOSU
    boriss@gmail.com

=head1 COPYRIGHT

This program is free software licensed under the...

	The GNU Lesser General Public License (LGPL)
	Version 2.1, February 1999

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<WWW::Mechanize>, L<Mozilla::Mechanize>, L<Mozilla::Mechanize::GUITester>

=cut
