package Dist::Zilla::PluginBundle::MANWAR;

$Dist::Zilla::PluginBundle::MANWAR::VERSION   = '0.08';
$Dist::Zilla::PluginBundle::MANWAR::AUTHORITY = 'cpan:MANWAR';

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

# ABSTRACT: Dist::Zilla plugins for manwar.

sub configure {
    my ($self) = @_;

    $self->add_plugins(qw(
        PkgVersion
        PodVersion
        MinimumPerlFast
        GatherDir
        AutoPrereqs
        MetaJSON
        MetaYAML
        MakeMaker
        Manifest
        GithubMeta
    ));

    $self->add_plugins(qw(
        PodSyntaxTests
    ));

    $self->add_plugins([
        'MetaProvides::Package' => {
            inherit_version => 0,
            inherit_missing => 0,
            meta_noindex    => 1,
        }
    ]);

    $self->add_plugins([
        'PruneFiles' => {
            filenames => [ qw(dist.ini) ]
        }
    ]);
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::MANWAR - Dist::Zilla plugins for manwar.

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This is the plugin bundle that MANWAR uses.  It's equivalent to:

    [PkgVersion]
    [PodVersion]
    [MinimumPerlFast]
    [GatherDir]
    [AutoPrereqs]
    [MetaYAML]
    [MetaJSON]
    [MakeMaker]
    [Manifest]
    [GithubMeta]
    [PodSyntaxTests]

    [MetaProvides::Package]
    inherit_version = 0
    inherit_missing = 0
    meta_noindex = 1

    [PruneFiles]
    filenames = dist.ini

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Dist-Zilla-PluginBundle-MANWAR>

=head1 BUGS

Please  report any bugs/feature requests to C<bug-dist-zilla-pluginbundle-manwar at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-MANWAR>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dist::Zilla::PluginBundle::MANWAR

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-MANWAR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-MANWAR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-MANWAR>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-MANWAR/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
