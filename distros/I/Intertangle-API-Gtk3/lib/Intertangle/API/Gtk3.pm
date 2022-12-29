use Renard::Incunabula::Common::Setup;
package Intertangle::API::Gtk3;
# ABSTRACT: Provides helpers for dealing with Gtk3 code
$Intertangle::API::Gtk3::VERSION = '0.006';
sub Inline {
	return unless $_[-1] eq 'C';

	my $gtk3_pkg = 'gtk+-3.0';

	require ExtUtils::PkgConfig;
	require Intertangle::API::Glib;
	require Hash::Merge;
	my $glib = Intertangle::API::Glib->Inline($_[-1]);

	my @nosearch = $^O eq 'MSWin32' ? (':nosearch') : ();
	my @search   = $^O eq 'MSWin32' ? ( ':search' ) : ();
	my $gtk = {
		CCFLAGSEX => join(" ", delete $glib->{CCFLAGSEX}, ExtUtils::PkgConfig->cflags($gtk3_pkg)),
		LIBS => join(" ", @nosearch, delete $glib->{LIBS}, ExtUtils::PkgConfig->libs($gtk3_pkg), @search),
		AUTO_INCLUDE => <<C,
#include <gtk/gtk.h>
C
	};

	my $merge = Hash::Merge->new('RETAINMENT_PRECEDENT');
	$merge->merge( $glib, $gtk );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Gtk3 - Provides helpers for dealing with Gtk3 code

=head1 VERSION

version 0.006

=head1 METHODS

=head2 Inline

  use Inline C with => qw(Intertangle::API::Gtk3);

Returns the flags needed to configure L<Inline::C> to use with
C<gtk+-3.0>.

=head1 SEE ALSO

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
