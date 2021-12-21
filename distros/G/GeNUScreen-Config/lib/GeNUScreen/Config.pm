# vim: set ts=4 sw=4 tw=78 et si:
#
package GeNUScreen::Config;

use warnings;
use strict;
use Carp;
use GeNUScreen::Config::Diff;

use version; our $VERSION = qv('v0.0.11');

my $re_cfgval  = qr/\S.*/;
my $re_cfgvar  = qr/[0-9a-z_]+/i;
my $re_cfgpath = qr/$re_cfgvar(?:\.$re_cfgvar)*/;
my $re_marker  = qr/[a-z]+/i;

use Class::Std;
{
    # storage for attributes
    my %cfg : ATTR;

    sub BUILD {
        my ($self, $ident, $args_ref) = @_;

        $cfg{$ident} = {}; # nothing more for now
    } # BUILD()

    sub read_config {
        my ($self,$filename) = @_;

        my %gs_cfg;
        my $prefix = '';

        open my $fh, '<', $filename
            or croak("Could not open $filename for reading");

        while (<$fh>) {
            chomp;
            if (/^\s*($re_cfgpath)\s*=\s*($re_cfgval)?$/) {
                $gs_cfg{$prefix . $1} = $2;
            }
            elsif (/^\s*($re_cfgpath)\s*<<\s*($re_marker)$/) {
                my $cfgpath = $1;
                my $marker = $2;
                my $cfgval = '';
                while (<$fh>) {
                    last if (/^$marker$/);
                    $cfgval .= $_;
                }
                $gs_cfg{$prefix . $cfgpath} = $cfgval;
            }
            elsif (/^\s*($re_cfgvar)\s*\{\s*$/) {
                $prefix .= $1 . ".";
            }
            elsif (/^\s*\}\s*$/) {
                my @path_elements = split /[.]/, $prefix;
                $#path_elements--;
                $prefix = join('.', @path_elements) . '.';
            }
            else {
                croak("read_config could not parse"
                      . " line $. in file $filename: '$_'");
            }
        }
        $cfg{ident $self} = \%gs_cfg;
        close $fh;
    } # read_config()

    sub get_keys {
        my ($self) = @_;

        return keys %{$cfg{ident $self}};
    } # get_keys()

    sub get_value {
        my ($self,$key) = @_;

        return $cfg{ident $self}->{$key};
    } # get_value()

    sub diff {
        my ($self,$thatcfg) = @_;

        my $diff = GeNUScreen::Config::Diff->new();

        $diff->compare($self,$thatcfg);
        return $diff;
    } # diff()

} # package GeNUScreen::Config

1; # Magic true value required at end of module
__END__

=head1 NAME

GeNUScreen::Config - work with GeNUScreen configuration files

=head1 VERSION

This document describes GeNUScreen::Config version v0.0.11

=head1 SYNOPSIS

  use GeNUScreen::Config;

  my $thiscfg = GeNUScreen::Config->new();

  $thiscfg->read_config($thisfile);

  foreach ($thiscfg->get_keys()) {
    printf "%s = %s\n", $_, $thiscfg->get_value($_);
  }

  my $thatcfg = GeNUScreen::Config->new();

  $thatcfg->read_config($thatfile);

  my $cfgdiff = $thiscfg->diff($thatcfg);

  print "Configurations are identical\n" if ($cfgdiff->is_empty());

  foreach ($cfgdiff->get_keys()) {
    print "%s\n", $_;
    print " this = %s\n", $cfgdiff->get_this_value($_);
    print " that = %s\n", $cfgdiff->get_that_value($_);
  }

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 Methods

=over

=item C<< new() >>

Returns a new GeNUScreen::Config object.

  my $thiscfg = GeNUScreen::Config->new();

=item C<< read_config($filename) >>

Reads the configuration either from a file that was exported from the
GeNUScreen firewall via the web interface or from the I<< config.hdf >>
obtained via SSH or Console.

After calling C<< read_config() >> the object contains only the
configuration read from the last file. Any configuration that was held
before is lost.

  $thiscfg->read_config($thisfile);

=item C<< get_keys() >>

Returns a list of all keys currently in the configuration.

  my @keys = $thiscfg->get_keys();

=item C<< get_value($key) >>

Returns the value for the given key.

  foreach ($thiscfg->get_keys()) {
    printf "%s = %s\n", $_, $thiscfg->get_value($_);
  }

=item C<< diff($thatcfg) >>

Takes another GeNUScreen::Config object as argument and returns a
GeNUScreen::Config::Diff object holding the differences between this and that
object.

  my $cfgdiff = $thiscfg->diff($thatcfg);

  print "Configurations are identical\n" if ($cfgdiff->is_empty());

  foreach ($cfgdiff->get_keys()) {
    print "%s\n", $_;
    print " this = %s\n", $cfgdiff_get_this_value($_);
    print " that = %s\n", $cfgdiff_get_that_value($_);
  }

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Could not open %s for reading >>

This message is returned with croak when a configuration file could not be
read.

=item C<< read_config could not parse line %d in file %s: %s >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
GeNUScreen::Config requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-genuscreen-config@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Mathias Weidner  C<< <mamawe@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Mathias Weidner C<< <mamawe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
