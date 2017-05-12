#---------------------------------------------------------------------
package Dist::Zilla::Plugin::Metadata;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  2 Dec 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Add arbitrary keys to distmeta
#---------------------------------------------------------------------

our $VERSION = '3.03';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)


use Moose;

has metadata => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

with 'Dist::Zilla::Role::MetaProvider';

#---------------------------------------------------------------------
sub BUILDARGS
{
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  my %metadata;
  while (my ($key, $value) = each %copy) {
    my @keys = split (/\./, $key, -1);
    my $hash = \%metadata;
    while (@keys > 1) {
      $hash = $hash->{shift @keys} ||= {};
    }

    $hash->{$keys[0]} = $value;
  } # end while each %copy

  return {
    zilla       => $zilla,
    plugin_name => $name,
    metadata    => \%metadata,
  };
} # end BUILDARGS

#---------------------------------------------------------------------
sub mvp_multivalue_args
{
  return qw(author keywords license no_index.file no_index.directory
            no_index.package no_index.namespace resources.license );
} # end mvp_multivalue_args

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::Metadata - Add arbitrary keys to distmeta

=head1 VERSION

This document describes version 3.03 of
Dist::Zilla::Plugin::Metadata, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 SYNOPSIS

In your F<dist.ini>:

  [Metadata]
  dynamic_config              = 1
  resources.homepage          = http://example.com
  resources.bugtracker.mailto = bugs@example.com

=head1 DESCRIPTION

The Metadata plugin allows you to add arbitrary keys to your
distribution's metadata.

It splits each key on '.' and uses that as a multi-level hash key.  It
doesn't try to do any validation; the MetaJSON or MetaYAML plugin will
do that.  It does know which keys in the spec are List values; those
keys can be repeated.

=for Pod::Coverage
mvp_multivalue_args

=head1 CONFIGURATION AND ENVIRONMENT

Dist::Zilla::Plugin::Metadata requires no configuration files or environment variables.

=head1 DEPENDENCIES

Metadata requires L<Dist::Zilla> (4.300009 or later).

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-Plugins-CJM AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugins-CJM >>.

You can follow or contribute to Dist-Zilla-Plugins-CJM's development at
L<< https://github.com/madsen/dist-zilla-plugins-cjm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
