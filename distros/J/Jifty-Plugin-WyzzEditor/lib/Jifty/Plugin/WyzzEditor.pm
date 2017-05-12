use strict;
use warnings;

package Jifty::Plugin::WyzzEditor;
use base qw/Jifty::Plugin/;

our $VERSION = '0.01';

=head1 NAME

Jifty::Plugin::WyzzEditor - Simple WYSIWYG online editor for Jifty textarea

=head1 SYNOPSIS

In etc/config.yml

   Plugins:
     - WyzzEditor: {}

In your Model instead of 

   render_as 'teaxterea';

use

  render_as 'Jifty::Plugin::WyzzEditor::Textarea';


In your View 

  Jifty->web->link( 
    label   => _("Save"), 
    onclick => [
      { beforeclick =>
          "updateTextArea('".$action->form_field('myfield')->element_id."');" },
      { args => .... }
    ]
  );

=head1 DESCRIPTION

Wyzz, simple WYSIWYG online editor usable in fragments

=head1 METHOD

=head2 init

load wyzz.js on startup

=cut


sub init {
	my $self = shift;
	Jifty->web->javascript_libs([
	@{ Jifty->web->javascript_libs },
	"wyzz.js",
	]);
}

=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 COPYRIGHT AND LICENSES

Copyright 2007-2008 Yves Agostini. All Rights Reserved.

This program is free software and may be modified and distributed under the 
same terms as Perl itself.

wyzz.js is Copyright (c) 2007 The Mouse Whisperer

Contains code Copyright (c) 2006 openWebWare.com

wyzz.js is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation; either version 2.1 of the License, or 
(at your option) any later version.

=cut

1;
