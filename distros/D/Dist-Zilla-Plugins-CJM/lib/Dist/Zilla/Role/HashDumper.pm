#---------------------------------------------------------------------
package Dist::Zilla::Role::HashDumper;
#
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 4 Nov 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Dump selected hash keys as a string
#---------------------------------------------------------------------

our $VERSION = '4.13';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)

use Moose::Role;

use namespace::autoclean;

use Scalar::Util 'reftype';


sub hash_as_string
{
  my ($self, $hash) = @_;

  # Format the hash as a string:
  require Data::Dumper;

  my $data = Data::Dumper->new([ $hash ])
      ->Indent(1)->Sortkeys(1)->Terse(1)->Dump;

  if ($data eq "{}\n") {
    $data = '';
  } else {
    $data =~ s/^\{\n//     or die "Dump prefix! $data";
    $data =~ s/\n\}\n\z/,/ or die "Dump postfix! $data";
  }

  return $data;
} # end hash_as_string


sub extract_keys
{
  my $self = shift;

  return $self->hash_as_string( $self->extract_keys_as_hash(@_) );
} # end extract_keys


sub extract_keys_as_hash
{
  my $self = shift;
  my $type = shift;
  my $hash = shift;

  # Extract the wanted keys from the hash:
  my %want;

  foreach my $key (@_) {
    $self->log_debug("Fetching $type key $key");
    next unless defined $hash->{$key};

    # Skip keys with empty value:
    my $reftype = reftype($hash->{$key});
    if (not $reftype) {}
    elsif ($reftype eq 'HASH')  { next unless %{ $hash->{$key} } }
    elsif ($reftype eq 'ARRAY') { next unless @{ $hash->{$key} } }

    $want{$key} = $hash->{$key};
  } # end foreach $key

  return \%want;
} # end extract_keys_as_hash

no Moose::Role;
1;

__END__

=head1 NAME

Dist::Zilla::Role::HashDumper - Dump selected hash keys as a string

=head1 VERSION

This document describes version 4.13 of
Dist::Zilla::Role::HashDumper, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 DESCRIPTION

Plugins implementing HashDumper may call their own C<extract_keys>
method to extract selected keys from a hash and return a string
suitable for injecting into Perl code.  They may also call the
C<hash_as_string> method to do the same for an entire hash.

=head1 METHODS

=head2 extract_keys

  my $string = $plugin->extract_keys($name, \%hash, @keys);
  eval "%new_hash = ($string);";

This combines C<extract_keys_as_hash> and C<hash_as_string>.
It constructs a string of properly quoted keys and values from
selected keys in a hash.  (Note that C<\%hash> is a reference, but
C<@keys> is not.)  The C<$name> is used only in a log_debug message.

If any key has no value (or its value is an empty hash or array ref)
it will be omitted from the list.  If all keys are omitted, the empty
string is returned.  Otherwise, the result always ends with a comma.


=head2 extract_keys_as_hash

  my $hashref = $plugin->extract_keys_as_hash($name, \%hash, @keys);

This constructs a hashref from from selected keys in a hash.  (Note
that C<\%hash> is a reference, but C<@keys> is not.)  The C<$name> is
used only in a log_debug message.

If any key has no value (or its value is an empty hash or array ref)
it will be omitted from the new hashref.  If all keys are omitted,
an empty hashref is returned.


=head2 hash_as_string

  my $string = $plugin->hash_as_string(\%hash);
  eval "%new_hash = ($string);";

This constructs a string of properly quoted keys and values from a
hash.  If the hash is empty, the empty string will be returned.
Otherwise, the result always ends with a comma.

=head1 CONFIGURATION AND ENVIRONMENT

Dist::Zilla::Role::HashDumper requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Data::Dumper>.

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
