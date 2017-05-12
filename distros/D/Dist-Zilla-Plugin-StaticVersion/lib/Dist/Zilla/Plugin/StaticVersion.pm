use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::StaticVersion;
BEGIN {
  $Dist::Zilla::Plugin::StaticVersion::VERSION = '0.103521';
}
# ABSTRACT: Specify version number manually, using a plugin

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( Str );
with qw/ Dist::Zilla::Role::VersionProvider /;

has version => (
    ro, lazy, required,
    isa => Str,
    default => sub { '' },
);


sub provide_version {
    return $_[0]->version if $_[0]->version;
}

1; # Magic true value required at end of module


=pod

=head1 NAME

Dist::Zilla::Plugin::StaticVersion - Specify version number manually, using a plugin

=head1 VERSION

version 0.103521

=head1 SYNOPSIS

In a plugin bundle:

    package Dist::Zilla::PluginBundle::SomePlugins;
    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Easy';
    sub configure {
        ...
        $self->add_plugins(
            ['StaticVersion' => { version => "1.14.3" } ],
        );
        ...
    }

In dist.ini:

    [StaticVersion]
    version = 1.14.3

which is equivalent to:

    version = 1.14.3

=head1 DESCRIPTION

This purpose of this plugin is to allow plugin bundles or other such
things to specify a specific version number. This allows one to write
a pluginbundle that decides based on its configuration whether to
offer a specific version number. You could not otherwise do this,
because a static version number is specified before any plugins in
F<dist.ini>.

You shouldn't need to use this plugin directly in your F<dist.ini>.

=head1 METHODS

=head2 provide_version

This method simply offers the specified version. If the specified
version is false (e.g. empty string), it will not be offered.

=head1 BUGS AND LIMITATIONS

This module is under ten lines of code. It is likely provably correct.
Regardless, please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

