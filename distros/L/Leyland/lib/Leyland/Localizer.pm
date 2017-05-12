package Leyland::Localizer;

# ABSTRACT: Wrapper for the Locale::Wolowitz localization system for Leyland apps

use Moo;
use namespace::clean;
use Locale::Wolowitz;

=head1 NAME

Leyland::Localizer - Wrapper for the Locale::Wolowitz localization system for Leyland apps

=head1 SYNOPSIS

	# in your app's main package
	sub setup {
		return {
			...
			locales => '/path/to/myapp/locales',
			...
		};
	}

	# in your controllers
	$c->set_lang('es'); # use Spanish when responding, possibly because that's what the client wants
	$c->loc('Hello %1', $c->params->{name});

	# in your views (assuming you're using L<Tenjin|Leyland::View::Tenjin>):
	<h1>[== $c->loc('Hello %1', $c->params->{name}) =]</h1>

=head1 DESCRIPTION

This module provides Leyland applications with simple localization capabilities,
using L<Locale::Wolowitz>. This does not mean localizing your application
to the locale of the computer/server on which it is running, but localizing
your HTTP responses according to your application's client's wishes.

If, for example, your application is a website provided in two or more
languages, this module will provide your application with Wolowitz's
C<loc()> method, for translating strings into a certain language.

See the L<Leyland::Manual::Localization> for more information.

=head1 ATTRIBUTES

=head2 path

The path of the directory in which L<Locale::Wolowitz> translation files
reside. Can be a relative path. This attribute will come from the "locales"
config option in C<app.psgi>.

=head2 w

The L<Locale::Wolowitz> object used for localization.

=head1 OBJECT METHODS

=head2 loc( $string, $language, [ @replacements ] )

Translates C<$string> into C<$language>, possibly performing some replacements.
This is just a shortcut for C<< Locale::Wolowitz->loc() >>, so check out
L<Locale::Wolowitz> for more information.

=cut

has 'path' => (
	is => 'ro',
	isa => sub { die "path must be a scalar" if ref $_[0] },
	required => 1
);

has 'w' => (
	is => 'ro',
	isa => sub { die "w must be a Locale::Wolowitz object" unless ref $_[0] && ref $_[0] eq 'Locale::Wolowitz' },
	writer => '_set_w',
	handles => ['loc']
);

=head1 INTERNAL METHODS

The following methods are only to be used internally.

=head2 BUILD()

=cut

sub BUILD {
	$_[0]->_set_w(Locale::Wolowitz->new($_[0]->path));
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland::Localizer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Leyland>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Leyland>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Leyland>

=item * Search CPAN

L<http://search.cpan.org/dist/Leyland/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
