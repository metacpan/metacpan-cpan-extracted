package MARC::Descriptions;

use strict;
use Carp qw(croak);
use Clone::Any qw(clone);
use MARC::Descriptions::Data qw(%MARC_tag_data);

our $VERSION = '0.9';

=head1 NAME

MARC::Descriptions - MARC metadata looker-upper

=head1 SYNOPSIS

 use MARC::Descriptions

 my $TD = MARC::Descriptions->new;

 # hash of all tag data
 my $href = $TD->get("245");

 # string description
 my $s = $TD->get("245", "description");

 # hash of all subfields
 my $href = $TD->get("245", "subfield");

 # hash of subfield 'a'
 my $href = $TD->get("245", "subfield", "a");

 # description of subfield 'a'
 my $s = $TD->get("245", "subfield", "a", "description");

=head1 DESCRIPTION

MARC::Description allows you to get either a string of information about a particular
bit of a MARC record (eg: the description of the 245 tag, or the flags associated
with tag 245 subfield \$a), or a hash of (hashes of) strings of information about a
particular subset of a MARC record (eg: all of the 2nd indicators for tag 245, or
all of the subfields for tag 245, or even a complete breakdown of tag 245).

=cut

=head1 CONSTRUCTOR

=head2 new()

Creates the MARC::Descriptions object.  You only ever need one of these; all
of the fun stuff is done in get().

=cut
sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;
    return $self;
} # new()

=head1 METHODS

=head2 get( $tag [, $parm1 [, $parm2 [, $parm3]]] )

 Returns information about the MARC structure.

 tag is the MARC tag
    eg: get("010")
    With no other parameters, this returns a hash of all information
    about that tag.

 parm1 can be one of:
    "description","shortname", or "flags" (eg: get("245","description")),
       in which case a string is returned with that information,
   or
    "ind1","ind2","subfield" (eg: get("245","subfield")),
       in which case parm2 will be the indicator/subfield that you're
       interested in, and get() will return a hash of the information
       about all possible indicators or subfields.

 If both parm1 and parm2 are specified, then parm3 can also be specified
    to have get() return a string containing information about that particular
    indicator/subfield.  (eg: get("245","subfield","a"))

=cut
sub get {
    my $self = shift;
    my ($tag, @options) = @_;

    if( @options ) {
        $_ = $options[ 0 ];

        return $MARC_tag_data{ $tag }{ $1 } if /^(description|flags|shortname)$/i;
        return clone( $MARC_tag_data{ $tag }{ $1 } ) if /^(ind[12]|subfield)/i and @options == 1;
        return clone( $MARC_tag_data{ $tag }{ $1 }{ $options[ 1 ] }{$options[ 2 ] } ) if /^(ind[12]|subfield)/i and @options == 3;

        return;

    }

    # return everything for this tag
    return clone( $MARC_tag_data{ $tag } );
}

=head1 THE HASH

If you've asked get() to return a hash, it will look like this (or
a subset of this) - the example is for get("010"):

 {
 flags => "",
 shortname => "LCCN",
 description => "Library of Congress Control Number",
 ind1 => {
	"#" => {
		flags => "",
		description => "Unused",
		},
	},
 ind2 => {
	"#" => {
		flags => "",
		description => "Blank",
		},
	},
 subfield => {
	"a" => {
		flags => "",
		description => "LC control number",
		},
	"b" => {
		flags => "aR",
		description => "National Union Catalog of Manuscript Collections Control Number",
		},
	"z" => {
		flags => "R",
		description => "Canceled/invalid LC control number",
		},
	},
 }

=cut

=head1 SEE ALSO

=over 4

=item * perl4lib (L<http://www.rice.edu/perl4lib/>)

A mailing list devoted to the use of Perl in libraries.

=item * Library Of Congress MARC pages (L<http://www.loc.gov/marc/>)

The definitive source for all things MARC.


=item * I<Understanding MARC Bibliographic> (L<http://lcweb.loc.gov/marc/umb/>)

Online version of the free booklet.  An excellent overview of the MARC format.  Essential.


=item * Tag Of The Month (L<http://www.tagofthemonth.com/>)

Follett Software Company's
(L<http://www.fsc.follett.com/>) monthly discussion of various MARC tags.


=item * Cataloguer's Reference Shelf (L<http://www.carl.org/tlc/crs/CRS0000.htm>)

The Library Corporation's (L:<http://www.carl.org/tlccarl/index.asp>)
free online resource for cataloguers.

=back

=head1 AUTHOR

David Christensen, <DChristensenSPAMLESS@westman.wave.ca>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by David Christensen

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
