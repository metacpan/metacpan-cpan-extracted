use strict;

package Dist::Zilla::Plugin::ReadmeMarkdownFromPod;
{
  $Dist::Zilla::Plugin::ReadmeMarkdownFromPod::VERSION = '0.141140';
}

# ABSTRACT: Automatically convert POD to a README.mkdn for Dist::Zilla

use Moose;
extends 'Dist::Zilla::Plugin::ReadmeAnyFromPod';

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

my $config_override = {
    type => 'markdown',
    filename => $Dist::Zilla::Plugin::ReadmeAnyFromPod::_types->{markdown}->{filename},
    location => 'build',
};

# Override the return values of all the accessors to always return the
# markdown defaults
for my $method_name (keys %$config_override) {
    around $method_name => sub { return $config_override->{$method_name}; }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::ReadmeMarkdownFromPod - Automatically convert POD to a README.mkdn for Dist::Zilla

=head1 VERSION

version 0.141140

=head1 SYNOPSIS

    # dist.ini
    [ReadmeMarkdownFromPod]

=head1 DESCRIPTION

Generate a README.mkdn from C<main_module> by L<Pod::Markdown>

This module has been converted to a wrapper for
L<Dist::Zilla::Plugin::ReadmeAnyFromPod> with settings that replicate
the behavior of the old plugin.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHORS

=over 4

=item *

Ryan C. Thompson <rct@thompsonclan.org>

=item *

Jacob Helwig <jhelwig@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jacob Helwig.

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
