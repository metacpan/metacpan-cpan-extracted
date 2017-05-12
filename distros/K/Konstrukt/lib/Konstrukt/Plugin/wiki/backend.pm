=head1 NAME

Konstrukt::Plugin::wiki::backend - Base class for wiki backends

=head1 SYNOPSIS
	
	use base 'Konstrukt::Plugin::wiki::backend';
	#overwrite the methods
	
=head1 DESCRIPTION

Base class/interface for a backend class. Actually the backend class will
problably be a base class itself, which will be implemented for the
various backend typed (DBI, file, ...).

=cut

package Konstrukt::Plugin::wiki::backend;

use strict;
use warnings;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless {}, $class;
}
#= /new

=head2 init

Method that will be called right before the first usage within a request.
Should be overridden by the inheriting class.

For example you may set default settings here.

=cut
sub init {
	return 1;
}
#= /init

=head2 actions

This method will return an array of strings with the actions
(C<file.html?action=youraction>) that your backend plugin will handle.

You should return an empty list, if your plugin has no responsibilities. But in
this case your plugin will most likely never be called.

If such an action is called, the method with the name of the action will be
called on your plugin object.

Example:

	#your plugin is responsible for the action foo.
	#wiki.html?action=foo has been called.
	#this method will be called:
	$your_plugin->foo($tag);

Your method has to put out its result just like any other plugin does (see
L<Konstrukt::Plugin/add_node>).

Your method will also get a reference to the C<<& wiki &>>-tag node to grant you
access to some attributes or the content of the tag.

=cut
sub actions {
	return ();
}
#= /actions

=head2 normalize_link

This method will return a normalized version of a passed link string.

The backend may use this method to normalize the link to an object.

This is the default implementation, which may be overwritten by the implementing
backend classes. 

Some critical characters will be converted or escaped.
Also converts the link to lowercase. So C<SomeLink> will point to the same
page as C<[[somelink]]>.

B<Parameters>:

=over

=item * $link - The link to normalize

=back

=cut
sub normalize_link {
	my ($self, $link) = @_;
	
	my %convert = (
		#convert (some) non-ASCII-characters to lowercase
		qw(
			Á á
			À à
			Â â
			Å å
			Ã ã
			Ä ä
			Æ æ
			
			Ç ç
			Ð ð
			
			É é
			È è
			Ê ê
			Ë ë
			
			Í í
			Ì ì
			Î î
			Ï ï
			
			Ñ ñ
			
			Ó ó
			Ò ò
			Ô ô
			Õ õ
			Ö ö
			
			Ø ø
			
			Ú ú
			Ù ù
			Û û
			Ü ü
			
			Ý ý
		),
		
		#normalize quotes
		qw(
			` '
			" '
			´ '
		),
		
		#replace (some) critical (filesystem, HTML) characters
		#some characters must additionally escaped with a backslash to get the regexp working
		qw(
			\* %2A
			\: %3A
			\/ %2F
			\\ %5C
			\? %3F
			<  %3C
			>  %3E
			\| %7C
			%  %25
		)
	);
	#also replace whitespaces and sharps
	$convert{' '} = '_';
	$convert{'#'} = '%23';
	my $match = "(" . join('|', keys %convert) . ")";
	$link =~ s/$match/$convert{$1}/gi;
	
	#lowercase link
	return lc $link;
}
#= /normalize_link

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
