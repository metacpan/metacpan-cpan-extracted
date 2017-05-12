package Keybinder;
our $VERSION = '0.03';

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw/bind_key unbind_key/;

require XSLoader;
require Gtk2;

XSLoader::load('Keybinder', $VERSION);

1;
__END__

=head1 NAME

Keybinder - Perl extension that wraps libkeybinder for GTK apps

=head1 SYNOPSIS

  use Keybinder;

  bind_key('<Ctrl>B' => sub{ ... });
  bind_key('<Shift>F1' => sub{ ... });
  bind_key('<Ctrl><Alt>V' => sub{ ... });
  unbind_key('<Ctrl>B');


=head1 DESCRIPTION

Gtk2 toolkit is great, but it does not provides "global" hotkeys availability, i.e.
catching some accelerator press event while current window is not active. B<libkeybinder>
has been developed to fill that gap.


The current bindings aren't complete, but enough for my purposes.


The accelerator representatic string should be accepted by B<gtk_accelerator_parse>. Here
is an extraction:

  The format looks like "<Control>a" or "<Shift><Alt>F1" or "<Release>z"
  (the last one is for key release). The parser is fairly liberal and allows
  lower or upper case, and also abbreviations such as "<Ctl>" and "<Ctrl>".

=head2 EXPORT

bind_key, unbind_key

=head1 SEE ALSO

L<https://github.com/engla/keybinder>, L<https://developer.gnome.org/gtk3/>

=head1 AUTHOR

Ivan Baidakou (a.k.a. basiliscos)  E<lt>dmol@(cpan.org)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Ivan Baidakou

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
