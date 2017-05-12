package Lingua::FR::Ladl::Parametrizer;

use warnings;
use strict;
use Carp;
use utf8;

use version; our $VERSION = qv('0.0.1');

use Class::Std;

{
  my %empty_string_mark_of   : ATTR( :default('<E>') :name<empty_string_mark>    ); # null value for string type columns
  my %negation_particles_of  : ATTR(                 :name<negation_particles>   ); # what's a negation
  my %verbal_arguments_of    : ATTR(                 :name<verbal_arguments>     ); # which are verbal arguments (head) or whatever
  my %associate_for_particle : ATTR(                 :name<associate_for_particle); # translation particle -> associate
  my %associate_for_verb     : ATTR(                 :name<associate_for_verb    ); # translation verb component -> associate

  sub BUILD {
    my ($self, $id, $arg_ref) = @_;

    $negation_particles_of{$id} = {
                                   "Nég" => 1,
                                   pas => 1,
                                  };
    $verbal_arguments_of{$id} = {
                                 v => 1,
                                 adj =>1,
                                };
    $associate_for_particle{$id} = {
                                    "l'" => 'l',
                                    'la' => 'la',
                                    'les' => 'les',
                                    'le' => 'cla',
                                    'en' => 'clg',
                                    'y' => 'cll',
                                    "s'" => 'clr',
                                    'se' => 'clr',
                                    "n'" => 'neg',
                                    "ne" => 'neg',
                                   };
    $associate_for_verb{$id} = {
                                advm => 'advm',
                                adv => 'adv',
                                advt => 'advt',
                                adj => 'adj',
                                'poss n' => 'poss_n',
                                advfut => 'advfut',
                                advp => 'advp',
                                'nég' => 'neg',
                                'pas' => 'neg',
                               }

  }

}

1; # Magic true value required at end of module
__END__

=head1 NAME

Parametrizer -- for an easier and more flexible customization of the Lingua::FR::Ladl modules


=head1 VERSION

This document describes Lingua::FR::Ladl::Parametrizer version 0.0.1


=head1 SYNOPSIS

    # create a default parametrizer object
    my $param = Lingua::FR::Ladl::Parametrizer->new();

    # change the empty string mark from I<<E>> (the default) to I<EMPTY>
    $param->set_empty_string_mark('EMPTY');

=head1 DESCRIPTION


=head1 INTERFACE 

The following accessors are provided automagically via the Class::Std attribute I<name> and initialised with the defaults during the B<BUILD> process.

=over

=item get/set_empty_string_mark

The null value for string type columns, default is I<<E>>.

=item get/set_negation_particles

Which particles of a verb entry are to be considered negation markers. Type is a hash reference.
Current values are:

 {
   "Nég" => 1,
   pas => 1,
 }

=item get/set_verbal_arguments

Which arguments are to be considered verbal arguments. Type is a hash reference.
Currenty these are:

  {
    v => 1,
    adj => 1,
  }

=item get/set_associate_for_particle

Which parts of a particle entry are to be considered markers for associates. Type is a hash reference.
Current values are:

  {
     "l'" => 'l',
     'la' => 'la',
     'les' => 'les',
     'le' => 'cla',
     'en' => 'clg',
     'y' => 'cll',
     "s'" => 'clr',
     'se' => 'clr',
     "n'" => 'neg',
     "ne" => 'neg',
  }

This means eg. I<ne> is considered as a marker for the associate I<neg>, I<en> for I<clg> etc.

=item get/set_associate_for_verb

Which parts of a particle entry are to be considered markers for associates. Type is a hash reference.
Current values are:

    {
      advm => 'adv',
      advm => 'adv',
      advt => 'advt',
      adj => 'adj',
      'poss n' => 'poss_n',
      advfut => 'advfut',
      advp => 'advp',
      'nég' => 'neg',
      'pas' => 'neg',
    }

The meaning is similar to that of I<get/set_associate_for_verb>

=back


=head1 DEPENDENCIES

L<Class::Std>

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

L<Class::Std>


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
C<bug-<RT NAME>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Ingrid Falk  C<< <ingrid dot falk at loria dot fr> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Ingrid Falk C<< <ingrid dot falk at loria dot fr> >>. All rights reserved.

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
