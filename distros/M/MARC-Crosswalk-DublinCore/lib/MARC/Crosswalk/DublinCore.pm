package MARC::Crosswalk::DublinCore;

=head1 NAME

MARC::Crosswalk::DublinCore - Convert data between MARC and Dublin Core

=head1 SYNOPSIS

	my $crosswalk = MARC::Crosswalk::DublinCore->new;
	
	# Convert a MARC record to Dublin Core (simple)
	my $marc = MARC::Record->new_from_usmarc( $blob );
	my $dc   = $crosswalk->as_dublincore( $marc );

	# Convert simple DC to MARC
	$marc = $crosswalk->as_marc( $dc );
	
	# Convert MARC to qualified DC instead
	$crosswalk->qualified( 1 );
	$dc = $crosswalk->as_dublincore( $marc );

=head1 DESCRIPTION

This module provides an implentation of the LOC's spec on how to convert
metadata between MARC and Dublin Core format. The spec for converting MARC to
Dublin Core is available at: http://www.loc.gov/marc/marc2dc.html, and from DC to
MARC: http://www.loc.gov/marc/dccross.html.

NB: The conversion cannot be done in a round-trip manner. i.e. Doing a conversion
from MARC to DC, then trying to go back to MARC will not yield the original record.

=head1 INSTALLATION

To install this module via Module::Build:

	perl Build.PL
	./Build         # or `perl Build`
	./Build test    # or `perl Build test`
	./Build install # or `perl Build install`

To install this module via ExtUtils::MakeMaker:

	perl Makefile.PL
	make
	make test
	make install

=cut

use strict;
use warnings;

use MARC::Record;
use MARC::Field;
use DublinCore::Record;
use DublinCore::Element;

use Carp qw( croak );

our $VERSION = '0.02';

my %leader06_lut = (
	a => 'Text',
	c => 'Text',
	d => 'Text',
	t => 'Text',
	e => 'Image',
	f => 'Image',
	g => 'Image',
	k => 'Image',
	i => 'Sound',
	j => 'Sound',
#	m => 'No Type Provided',
#	o => 'No Type Provided',
#	p => 'No Type Provided',
#	r => 'No Type Provided'
);

my %leader07_lut = (
	c => 'Collection',
	s => 'Collection',
	p => 'Collection'
);

my @dc_qualified = (
	{
		tag => 245,
		dc  => { name => 'Title' }
	},
	( map +{
		tag => $_,
		dc  => { name => 'Title', qualifier => 'Alternative' }
	}, ( 130, 210, 240, 242, 246, 730, 740 ) ),
	( map +{
		tag => $_,
		dc  => { name => 'Creator' }
	}, ( 100, 110, 111, 700, 710, 711, 720 ) ),
	( map +{
		tag        => $_,
		indicators => [ undef, 0 ],
		dc         => { name => 'Subject', scheme => 'LCSH' }
	}, ( 600, 610, 611, 630, 650 ) ),
	( map +{
		tag        => $_,
		indicators => [ undef, 2 ],
		dc         => { name => 'Subject', scheme => 'MeSH' }
	}, ( 600, 610, 611, 630, 650 ) ),
	{
		tag => '050',
		dc  => { name => 'Subject', scheme => 'LCC' }
	},
	{
		tag => '082',
		dc  => { name => 'Subject', scheme => 'DDC' }
	},
	{
		tag => '080',
		dc  => { name => 'Subject', scheme => 'UDC' }
	},
	( map +{
		tag => $_,
		dc  => { name => 'Description' }
	}, grep { $_ !~ /^(505|506|520|530|540|546)$/ } 500..599 ),
	{
		tag        => 505,
		indicators => [ 3, undef ],
		dc         => { name => 'Description', qualifier => 'tableOfContents' }
	},
	{
		tag => 520,
		dc  => { name => 'Description', qualifier => 'Abstract' }
	},
	{
		tag       => 260,
		subfields => 'ab',
		dc        => { name => 'Publisher' }
	},
	{
		tag       => 260,
		subfields => 'cg',
		dc        => { name => 'Date', qualifier => 'Created' }
	},
	{
		tag       => 533,
		subfields => 'd',
		dc        => { name => 'Date', qualifier => 'Created' }
	},
	{
		tag       => 260,
		subfields => 'c',
		dc        => { name => 'Date', qualifier => 'Issued' }
	},
	{
		tag  => '008',
		code => sub {
			return substr( shift, 7, 4 );
		},
		dc   => { name => 'Date', qualifier => 'Issued' }
	},
	{
		tag  => 'Leader',
		code => sub { return $leader06_lut{ substr( shift, 6, 1 ) }; },
		dc   => { name => 'Type', scheme => 'DCMI Type Vocabulary' }
	},
	{
		tag  => 'Leader',
		code => sub { return $leader07_lut{ substr( shift, 7, 1 ) }; },
		dc   => { name => 'Type', scheme => 'DCMI Type Vocabulary' }
	},
	{
		tag         => 655,
		subfield_eq => [ '2', 'dct' ],
		dc          => { name => 'Type', scheme => 'DCMI Type Vocabulary' }
	},
	{
		tag       => 865,
		subfields => 'q',
		dc        => { name => 'Format', scheme => 'IMT' }
	},
	{
		tag       => 300,
		subfields => 'a',
		dc        => { name => 'Format', qualifier => 'Extent' }
	},
	{
		tag       => 533,
		subfields => 'e',
		dc        => { name => 'Format', qualifier => 'Extent' }
	},
	{
		tag       => 340,
		subfields => 'a',
		dc        => { name => 'Format', qualifier => 'Medium' }
	},
	{
		tag       => 856,
		subfields => 'u',
		dc        => { name => 'Identifier', scheme => 'URI' }
	},
	{
		tag       => 786,
		subfields => 'o',
		dc        => { name => 'Source', scheme => 'URI' }
	},
	{
		tag  => '008',
		code => sub {
			return substr( shift, 35, 3 );
		},
		dc   => { name => 'Language', scheme => 'ISO 639-2' }
	},
	{
		tag => '041',
		dc  => { name => 'Language', scheme => 'ISO 639-2' }
	},
	{
		tag => '546',
		dc  => { name => 'Language', scheme => 'RFC 1766' }
	},
	{
		tag => 775,
		dc  => { name => 'Relation', qualifier => 'isVersionOf' }
	},
	{
		tag       => 786,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'isVersionOf' }
	},
	{
		tag => 775,
		dc  => { name => 'Relation', qualifier => 'isVersionOf', scheme => 'URI' }
	},
	{
		tag       => 786,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'isVersionOf', scheme => 'URI' }
	},
	{
		tag       => 775,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'hasVersion' }
	},
	{
		tag       => 775,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'hasVersion', scheme => 'URI' }
	},
	{
		tag       => 785,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'isReplaceBy' }
	},
	{
		tag       => 785,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'isReplaceBy', scheme => 'URI' }
	},
	{
		tag       => 780,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'Replaces' }
	},
	{
		tag       => 780,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'Replaces', scheme => 'URI' }
	},
	{
		tag => 538,
		dc  => { name => 'Relation', qualifier => 'Requires' }
	},
	{
		tag       => 773,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'isPartOf' }
	},
	( map +{
		tag => $_,
		dc  => { name => 'Relation', qualifier => 'isPartOf' }
	}, ( 760, 440, 490, 800, 810, 811, 830 ) ),
	{
		tag => 760,
		dc  => { name => 'Relation', qualifier => 'isPartOf', scheme => 'URI' }
	},
	{
		tag       => 773,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'isPartOf', scheme => 'URI' }
	},
	{
		tag       => 774,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'hasPart' }
	},
	{
		tag       => 774,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'hasPart', scheme => 'URI' }
	},
	{
		tag => 510,
		dc  => { name => 'Relation', qualifier => 'isReferencedBy' }
	},
	{
		tag       => 776,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'isFormatOf' }
	},
	{
		tag => 530,
		dc  => { name => 'Relation', qualifier => 'isFormatOf' }
	},
	{
		tag       => 776,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'isFormatOf', scheme => 'URI' }
	},
	{
		tag       => 530,
		subfields => 'u',
		dc        => { name => 'Relation', qualifier => 'isFormatOf', scheme => 'URI' }
	},
	{
		tag       => 776,
		subfields => 'nt',
		dc        => { name => 'Relation', qualifier => 'hasFormat' }
	},
	{
		tag => 530,
		dc  => { name => 'Relation', qualifier => 'hasFormat' }
	},
	{
		tag       => 776,
		subfields => 'o',
		dc        => { name => 'Relation', qualifier => 'hasFormat', scheme => 'URI' }
	},
	{
		tag       => 530,
		subfields => 'u',
		dc        => { name => 'Relation', qualifier => 'hasFormat', scheme => 'URI' }
	},
	( map +{
		tag => $_,
		dc  => { name => 'Coverage', qualifier => 'Spacial' }
	}, ( 522, 651, 255, 752 ) ),
	{
		tag       => 650,
		subfields => 'z',
		dc        => { name => 'Coverage', qualifier => 'Spacial' }
	},
	( map +{
		tag       => $_,
		subfields => 'c',
		dc        => { name => 'Coverage', qualifier => 'Spacial', scheme => 'ISO 3166' }
	}, ( '043', '044' ) ),
	{
		tag         => 651,
		subfield_eq => [ '2', 'tgn' ],
		dc          => { name => 'Coverage', qualifier => 'Spacial', scheme => 'TGN' }
	},
	{
		tag       => 513,
		subfields => 'b',
		dc        => { name => 'Coverage', qualifier => 'Temporal' }
	},
	{
		tag       => '033',
		subfields => 'a',
		dc        => { name => 'Coverage', qualifier => 'Temporal' }
	},
	( map +{
		tag => $_,
		dc  => { name => 'Rights' }
	}, ( 506, 540 ) )

);

my @dc_simple    = (
	{
		tag => 245,
		dc  => { name => 'Title' }
	},
	( map +{
		tag => $_,
		dc  => { name => 'Creator' }
	}, ( 100, 110, 111, 700, 710, 711, 720 ) ),
	( map +{
		tag => $_,
		dc  => { name => 'Subject' }
	}, ( 600, 610, 611, 630, 650, 653 ) ),
	( map +{
		tag => $_,
		dc  => { name => 'Description' }
	}, grep { $_ !~ /^(506|530|540|546)$/ } 500..599 ),
	{
		tag       => 260,
		subfields => 'ab',
		dc        => { name => 'Publisher' }
	},
	{
		tag  => 'Leader',
		code => sub { return $leader06_lut{ substr( shift, 6, 1 ) }; },
		dc   => { name => 'Type' }
	},
	{
		tag  => 'Leader',
		code => sub { return $leader07_lut{ substr( shift, 7, 1 ) }; },
		dc   => { name => 'Type' }
	},
	{
		tag => 655,
		dc  => { name => 'Type' }
	},
	{
		tag       => 856,
		subfields => 'q',
		dc        => { name => 'Format' }
	},
	{
		tag       => 856,
		subfields => 'u',
		dc        => { name => 'Identifier' }
	},
	{
		tag       => 786,
		subfields => 'ot',
		dc        => { name => 'Source' }
	},
	{
		tag  => '008',
		code => sub {
			return substr( shift, 35, 3 );
		},
		dc   => { name => 'Language' }
	},
	{
		tag => 546,
		dc  => { name => 'Language' }
	},
	{
		tag => 530,
		dc  => { name => 'Relation' }
	},
	( map +{
		tag       => $_,
		subfields => 'ot',
		dc        => { name => 'Relation' }
	}, ( 760..787 ) ),
	( map +{
		tag => $_,
		dc  => { name => 'Coverage' }
	}, ( 651, 752 ) ),
	( map +{
		tag => $_,
		dc  => { name => 'Rights' }
	}, ( 506, 540 ) )
);

my @marc_qualified;
my @marc_simple;

=head1 METHODS

=head2 new( %options )

Creates a new crosswalk object. You can pass the "qualified" option (true/false) as
well.

	# DC Simple
	$crosswalk = MARC::Crosswalk::DublinCore->new;

	# DC Qualified
	$crosswalk = MARC::Crosswalk::DublinCore->new( qualified => 1 );

=cut

sub new {
	my $class   = shift;
	my %options = @_;
	my $self    = {};

	bless $self, $class;

	$self->qualified( 1 ) if $options{ qualified }; 

	return $self;
}

=head2 qualified( $qualified )

Allows you to specify if qualified Dublin Core should be used in
the input or output. Defaults to false (DC simple).

	# DC Simple
	$crosswalk->qualified( 0 );

	# DC Qualified
	$crosswalk->qualified( 1 );

=cut

sub qualified {
	my $self      = shift;
	my $qualified = @_;

	$self->{ _QUALIFIED } = $qualified if @_;

	return $self->{ _QUALIFIED };
}

=head2 as_dublincore( $marc )

convert a MARC::Record to a DublinCore::Record.

=cut

sub as_dublincore {
	my $self = shift;
	my $marc = shift;

	croak( 'Input is not a MARC::Record!' ) unless $marc->isa( 'MARC::Record' );

	my $rules = $self->qualified ? \@dc_qualified : \@dc_simple;
	my $dc    = DublinCore::Record->new;

	for my $rule ( @$rules ) {
		for my $field ( $rule->{ tag } eq 'Leader' ? $marc->leader : $marc->field( $rule->{ tag } ) ) {
			next unless defined $field;

			my $content = ref $field ? $field->as_string( $rule->{ subfields } ) : $field;

			if( $rule->{ subfield_eq } ) {
				my @eq = @{ $rule->{ subfield_eq } };
				while( @eq ) {
					$content = undef unless $field->subfield( shift( @eq ) ) eq shift( @eq );
				}
			}
			if( $rule->{ indicators } ) {
				for( 0, 1 ) {
					next unless defined $rule->{ indicators }->[ $_ ];
					$content = undef unless $field->indicator( $_ + 1 ) == $rule->{ indicators }->[ $_ ];
				}
			}

			if( $rule->{ code } ) {
				$content = $rule->{ code }->( $content );
			}

			if( $content ) {
				my $element = DublinCore::Element->new( $rule->{ dc } );
				$content    =~ s/^\s+|\s+$//;
				$element->content( $content );
				$dc->add( $element );
			}
		}
	}

	return $dc;
}

=head2 as_marc( $dublincore )

convert a DublinCore::Record to a MARC::Record. NB: Not yet implemented.

=cut

sub as_marc {
	my $self = shift;
	my $dc   = shift;

	croak( 'Input is not a DublinCore::Record!' ) unless $dc->isa( 'DublinCore::Record' );

	my $rules = $self->qualified ? \@marc_qualified : \@marc_simple;
	my $marc  = MARC::Record->new;

	croak( 'Not implemented.' );
}

=head1 TODO

=over 4

=item * Implement as_marc()

=item * add tests

=back

=head1 SEE ALSO

=over 4

=item * http://www.loc.gov/marc/marc2dc.html

=item * http://www.loc.gov/marc/dccross.html

=item * MARC::Record

=item * DublinCore::Record

=back

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;