package MS::Reader::XML::CV;

use strict;
use warnings;

use parent qw/MS::Reader::XML/;

use Carp;
use Scalar::Util qw/weaken/;

sub fetch_record {

    my ($self, @args) = @_;

    my $record = $self->SUPER::fetch_record(@args);

    if (exists $self->{referenceableParamGroupList}
      && $self->{referenceableParamGroupList}->{count} > 0) {
        $record->{__param_groups} =
            $self->{referenceableParamGroupList}->{referenceableParamGroup};
    }
    weaken( $record->{__param_groups} );
    
    return $record;

}

sub param {

    my ($self, $cv, %args) = @_;

    my $idx = $args{index} // 0;
    my $ref = $args{ref}   // $self;

    my $val   = $ref->{cvParam}->{$cv}->[$idx]->{value};
    my $units = $ref->{cvParam}->{$cv}->[$idx]->{unitAccession};

    # try groups if not found initially
    if (! defined $val) {
        for (@{ $ref->{referenceableParamGroupRef} }) {
            my $r = $self->{__param_groups}->{ $_->{ref} };
            next if (! exists $r->{cvParam}->{$cv});
            $val = $r->{cvParam}->{$cv}->[$idx]->{value};
            next if (! defined $val);
            $units = $ref->{cvParam}->{$cv}->[$idx]->{unitAccession};
            last;
        }
    }
        
    return wantarray ? ($val, $units) : $val;

}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::XML::CV - Base class for XML-based parsers with support for
referenceableParamGroups

=head1 SYNOPSIS

    package MS::Reader::Foo;

    use parent MS::Reader::XML::CV;

    package main;

    use MS::Reader::Foo;

    my $run = MS::Reader::Foo->new('run.foo');

    while (my $record = $foo->next_record('bar') {
       
        # etc

    }

=head1 DESCRIPTION

C<MS::Reader::XML::CV> is the base class for XML-based parsers which utilize
referenceableParamGroups. The class and its methods are not generally called
directly, but publicly available methods are documented below.

=head1 METHODS

=head2 fetch_record

    my $r = $parser->fetch_record($ref => $idx);

Takes two arguments (record reference and zero-based index) and returns a
record object. The types of records available and class of the object
returned depends on the subclass implementation. For the
L<MS::Reader::XML::CV> class, this method calls the parental method and then
adds information specific to CV parameters.

=head2 param

    use MS::CV qw/:MS/;
    my ($val, $units) = $obj->param( SOME_CV );
    my $val = $obj->param(
        SOME_CV,
        index => 2,
    );
    my $val = $obj->param(
        SOME_CV,
        index => 2,
        ref => $some_ref,
    );

Takes a single required argument, the CV term to be looked up. In scalar
context, returns the value of the term if found or else undefined. In list
context, returns the value and the units of the value. One or both items can
be undefined if not found.

The method can also take two optional named arguments:

=over

=item * C<index> — the index of the parameter to retrieve. Some CV parameters
can be repeated, and this option can be used to access each one. Default: 0.

=item * C<ref> — a hash reference pointing to an internal data structure.
This is used when the CV param to be looked up is not directly attached to the
object making the call, but possibly to a part of it's internal structure.
Generally, ths is used in implementing class methods internally, as its use
requires a knowledge of the underlying data structure.

=back

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
