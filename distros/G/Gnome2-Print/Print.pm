#
# $Id$
#

package Gnome2::Print;

use 5.008;
use strict;
use warnings;

use Gtk2;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Gnome2::Print ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.001';

sub dl_load_flags { 0x01 }

require XSLoader;
XSLoader::load('Gnome2::Print', $VERSION);

# Preloaded methods go here.

1;
__END__
=head1 NAME

Gnome2::Print - (DEPRECATED) Perl wrappers for the Gnome Print utilities.

=head1 SYNOPSIS

  use Gnome2::Print;

  my $job = Gnome2::Print::Job->new;
  my $config = $job->get_config;
  my $pc = $job->get_context;

  my ($width, $height) = $config->get_page_size;
  
  $pc->beginpage("1");
  
  $pc->setlinewidth(3.0);
  $pc->rect_stroked($width * .1, $height * .1, $width * .9, $height * .9);
  
  $pc->showpage;
  
  $job->render($pc);
  $job->close;

=head1 ABSTRACT

B<DEPRECATED> Perl bindings to the 2.2 series of the Gnome Print libraries,
for use with gtk2-perl.

=head1 DESCRIPTION

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

=over

=item *

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-print

=item *

Upstream URL: https://gitlab.gnome.org/Archive/libgnomeprint

=item *

Last upstream version: 2.18.8

=item *

Last upstream release date: 2010-09-28

=item *

Migration path for this module: Gtk3::Print*

=item *

Migration module URL: https://metacpan.org/pod/Gtk3

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module allows you to use the GNOME Print libraries within your
applications written using the gtk2-perl wrapper.  The GNOME Print libraries
(also known as libgnomeprint and libgnomeprintui) allow you to create
printable documents (using various frontends) and offer standard widgets in
order to mainatin a UI consistent for all GNOME applications.

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

Find out more about GNOME at http://www.gnome.org.

=head1 SEE ALSO

L<perl>(1), L<Glib>(3pm), L<Gtk2>(3pm), L<Gnome2>(3pm).

=head1 AUTHOR

Emmanuele Bassi E<lt>emmanuele.bassi@iol.itE<gt>,
muppet E<lt>scott at asofyet dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2006 by Emmanuele Bassi

Copyright 2003 by muppet

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
