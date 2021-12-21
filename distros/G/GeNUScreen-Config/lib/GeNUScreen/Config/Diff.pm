# vim: set ts=4 sw=4 tw=78 et si:
#
package GeNUScreen::Config::Diff;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('v0.0.11');

my $re_cfgval  = qr/\S.*/;
my $re_cfgvar  = qr/[0-9a-z_]+/i;
my $re_cfgpath = qr/$re_cfgvar(?:\.$re_cfgvar)*/;
my $re_marker  = qr/[a-z]+/i;

use Class::Std;
{
    # storage for attributes
    my %diff : ATTR;

    sub BUILD {
        my ($self, $ident, $args_ref) = @_;
        
        $diff{ident $self} = {};
    } # BUILD()

    sub compare {
        my ($self,$this,$that) = @_;

        my %d;
        my %all_keys = ();

        foreach my $k ($this->get_keys()) {$all_keys{$k} = 1};
        foreach my $k ($that->get_keys()) {$all_keys{$k} = 1};

        foreach my $k (keys %all_keys) {
            my $thisval = $this->get_value($k);
            my $thatval = $that->get_value($k);

            unless ((not defined $thisval and not defined $thatval)
                    or (defined $thisval and defined $thatval
                        and $thisval eq $thatval)
                   ) {
                $d{$k}->{this} = $thisval;
                $d{$k}->{that} = $thatval;
            }
        }
        $diff{ident $self} = \%d;
    } # compare()

    sub get_keys {
        my ($self) = @_;

        return keys %{$diff{ident $self}};
    } # get_keys()

    sub get_that_value {
        my ($self,$key) = @_;

        return $diff{ident $self}->{$key}->{that};
    } # get_that_value()

    sub get_this_value {
        my ($self,$key) = @_;

        return $diff{ident $self}->{$key}->{this};
    } # get_this_value()

    sub is_empty {
        my ($self) = @_;

        return 0 == scalar keys %{$diff{ident $self}};
    }

} # package GeNUScreen::Config::Diff

1; # Magic true value required at end of module
__END__

=head1 NAME

GeNUScreen::Config::Diff - differences between GeNUScreen configuration files

=head1 SYNOPSIS

  use GeNUScreen::Config;

  my $thiscfg = GeNUScreen::Config->new();

  $thiscfg->read_config($thisfile);

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

Returns a new GeNUScreen::Config::Diff object.

  my $cfgdiff = GeNUScreen::Config::Diff->new();

=item C<< compare($thiscfg,$thatcfg) >>

Compares two GeNUScreen::Config objects.

After calling C<< compare() >> the object contains only the
differences from these two configurations. Any differences held
before are lost.

  $cfgdiff->compare($thiscfg,$thatcfg);

=item C<< get_keys() >>

Returns a list of all keys with different values.

  my @keys = $cfgdiff->get_keys();

=item C<< get_this_value($key) >>

Returns the value of the first configuration for the given key.

=item C<< get_that_value($key) >>

Returns the value of the second configuration for the given key.

  foreach ($cfgdiff->get_keys()) {
    printf "%s\n", $_;
    printf " this = %s\n", $_, $cfgdiff->get_this_value($_);
    printf " that = %s\n", $_, $cfgdiff->get_that_value($_);
  }

=item C<< is_empty() >>

Returns a true value if there are no differences between the two last compared
configurations.

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

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
