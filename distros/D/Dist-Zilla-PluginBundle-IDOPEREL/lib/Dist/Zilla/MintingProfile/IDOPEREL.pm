package Dist::Zilla::MintingProfile::IDOPEREL;

# ABSTRACT: Wrapper for IDOPEREL's personal minting profile

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

our $VERSION = "1.001000";
$VERSION = eval $VERSION;

=head1 NAME

Dist::Zilla::MintingProfile::IDOPEREL - Wrapper for IDOPEREL's personal minting profile

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dist-zilla-pluginbundle-idoperel at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-IDOPEREL>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Dist::Zilla::MintingProfile::IDOPEREL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-IDOPEREL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-IDOPEREL>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
