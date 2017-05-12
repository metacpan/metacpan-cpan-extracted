package Forest;
use Moose ();

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

1;

__END__

=pod

=head1 NAME

Forest - A collection of n-ary tree related modules

=head1 DESCRIPTION

Forest is intended to be a replacement for the L<Tree::Simple> family of modules,
and fixes many of the issues that have always bothered me about them. It is by
no means a complete replacement yet, but should eventually grow to become that.

For more information please refer to the individual module documentation,
starting with L<Forest::Tree>.

=head1 TODO

=over 4

=item More documentation

This is 0.10 so it is (still) lacking quite a bit of docs (I am being really lazy sorry).
Although I invite people to read the source, it is quite simple really.

=item More tests

The coverage is in the low 90s, but there is still a lot of behavioral stuff that could
use some testing too.

=back

=head1 SEE ALSO

=over 4

=item L<Tree::Simple>

I wrote this module a few years ago and I had served me well, but recently I find
myself getting frustrated with some of the uglier bits of this module. So Forest is
a re-write of this module.

=item L<Tree>

This is an ambitious project to replace all the Tree related modules with a single
core implementation. There is some good code in here, but the project seems to be
very much on the back-burner at this time.

=item O'Caml port of Forest

Ask me about the O'Caml port of this module, it is also sitting on my hard drive
waiting for release. It actually helped quite a bit in terms of helping me settle
on the APIs for this module. Static typing can be very helpful sometimes.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

With contributions from:

Yuval (nothingmuch) Kogman

Guillermo (groditi) Roditi

Florian (rafl) Ragwitz

Jesse (doy) Luehrs

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
