use strict;
use warnings;
use utf8;

package Dist::Zilla::MintingProfile::Author::LESPEA;
$Dist::Zilla::MintingProfile::Author::LESPEA::VERSION = '1.008000';
BEGIN {
  $Dist::Zilla::MintingProfile::Author::LESPEA::AUTHORITY = 'cpan:LESPEA';
}

# ABSTRACT: LESPEA's Minting Profile

use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';




__PACKAGE__->meta->make_immutable;
no Moose;

# Happy ending
1;

__END__

=pod

=head1 NAME

Dist::Zilla::MintingProfile::Author::LESPEA - LESPEA's Minting Profile

=head1 VERSION

version 1.008000

=head1 SYNOPSIS

    #   On the command line run:
    dzil new -P Author::LESPEA Some::Dist::Name

=head1 DESCRIPTION

This installs a L<Dist::Zilla|Dist::Zilla> profile to start a new module with

=encoding utf8

=begin Pod::Coverage




=end Pod::Coverage

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::PluginBundle::Author::LESPEA|Dist::Zilla::PluginBundle::Author::LESPEA>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Lesperance.

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
