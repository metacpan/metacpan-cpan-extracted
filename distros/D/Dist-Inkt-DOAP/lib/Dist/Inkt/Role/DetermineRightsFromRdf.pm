package Dist::Inkt::Role::DetermineRightsFromRdf;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

use Moose::Role;
use RDF::Trine qw( iri literal statement variable );
use List::Util qw( uniq );
use Path::Tiny qw( path );
use Path::Iterator::Rule;
use Software::License;
use Software::LicenseUtils;
use Types::Standard -types;
use namespace::autoclean;

my %URIS = (
	'http://www.gnu.org/licenses/agpl-3.0.txt'              => 'AGPL_3',
	'http://www.apache.org/licenses/LICENSE-1.1'            => 'Apache_1_1',
	'http://www.apache.org/licenses/LICENSE-2.0'            => 'Apache_2_0',
	'http://www.apache.org/licenses/LICENSE-2.0.txt'        => 'Apache_2_0',
	'http://www.perlfoundation.org/artistic_license_1_0'    => 'Artistic_1_0',
	'http://opensource.org/licenses/artistic-license.php'   => 'Artistic_1_0',
	'http://www.perlfoundation.org/artistic_license_2_0'    => 'Artistic_2_0',
	'http://opensource.org/licenses/artistic-license-2.0.php'  => 'Artistic_2_0',
	'http://www.opensource.org/licenses/bsd-license.php'    => 'BSD',
	'http://creativecommons.org/publicdomain/zero/1.0/'     => 'CC0_1_0',
	'http://www.freebsd.org/copyright/freebsd-license.html' => 'FreeBSD',
	'http://www.gnu.org/copyleft/fdl.html'                  => 'GFDL_1_3',
	'http://www.opensource.org/licenses/gpl-license.php'    => 'GPL_1',
	'http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt'  => 'GPL_1',
	'http://www.opensource.org/licenses/gpl-2.0.php'        => 'GPL_2',
	'http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt'  => 'GPL_2',
	'http://www.opensource.org/licenses/gpl-3.0.html'       => 'GPL_3',
	'http://www.gnu.org/licenses/gpl-3.0.txt'               => 'GPL_3',
	'http://www.opensource.org/licenses/lgpl-2.1.php'       => 'LGPL_2_1',
	'http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt' => 'LGPL_2_1',
	'http://www.opensource.org/licenses/lgpl-3.0.html'      => 'LGPL_3_0',
	'http://www.gnu.org/licenses/lgpl-3.0.txt'              => 'LGPL_3_0',
	'http://www.opensource.org/licenses/mit-license.php'    => 'MIT',
	'http://www.mozilla.org/MPL/MPL-1.0.txt'                => 'Mozilla_1_0',
	'http://www.mozilla.org/MPL/MPL-1.1.txt'                => 'Mozilla_1_1',
	'http://opensource.org/licenses/mozilla1.1.php'         => 'Mozilla_1_1',
	'http://www.openssl.org/source/license.html'            => 'OpenSSL',
	'http://dev.perl.org/licenses/'                         => 'Perl_5',
	'http://www.opensource.org/licenses/postgresql'         => 'PostgreSQL',
	'http://trolltech.com/products/qt/licenses/licensing/qpl'  => 'QPL_1_0',
	'http://h71000.www7.hp.com/doc/83final/BA554_90007/apcs02.html'  => 'SSLeay',
	'http://www.openoffice.org/licenses/sissl_license.html' => 'Sun',
	'http://www.zlib.net/zlib_license.html'                 => 'Zlib',
);
eval("require Software::License::$_") for uniq values %URIS;

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
my $CPAN = RDF::Trine::Namespace->new('http://purl.org/NET/cpan-uri/terms#');
my $DC   = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $DOAP = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $FOAF = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $NFO  = RDF::Trine::Namespace->new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#');
my $SKOS = RDF::Trine::Namespace->new('http://www.w3.org/2004/02/skos/core#');

sub _determine_rights_from_rdf
{
	my ($self, $f) = @_;
	unless ($self->{_rdf_copyright_data})
	{
		my $model = $self->model;
		my $iter  = $model->get_pattern(
			RDF::Trine::Pattern->new(
				statement(variable('subject'), $NFO->fileName, variable('filename')),
				statement(variable('subject'), $DC->license, variable('license')),
				statement(variable('subject'), $DC->rightsHolder, variable('rights_holder')),
				statement(variable('rights_holder'), $FOAF->name, variable('name')),
			),
		);
		my %results;
		while (my $row = $iter->next) {
			my $l = $row->{license}->uri;
			$row->{class} = literal("Software::License::$URIS{$l}")
				if exists $URIS{$l};
			$results{ $row->{filename}->literal_value } = $row;
		}
		$self->{_rdf_copyright_data} = \%results;
	}
	
	if ( my $row = $self->{_rdf_copyright_data}{$f} ) {
		return (
			sprintf("Copyright %d %s.", 1900 + (localtime((stat $f)[9]))[5], $row->{name}->literal_value),
			$row->{class}->literal_value->new({holder => "the copyright holder(s)"}),
		) if $row->{class};
	}
	
	return;
}

1;
