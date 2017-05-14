 #!/usr/bin/env perl

=head1 NAME

similarity_match.pl

=head1 SYNOPSIS

Compares a list of annotations to another ontology and suggests the best match 
based on the EBI::FGPT::FuzzyRecogniser module. It is also possible to 
align one ontology to another. Accepts ontologies in both OBO and OWL formats 
as well as MeSH ASCII and OMIM txt.

The script runs non-interactively and the results have to be manually inspected, 
although it can be expected that anything with a similarity score higher 
than ~80-90% will be a valid match.  

=head2 USAGE

similarity_match.pl (-w owlfile || -o obofile || -m meshfile || -i omimfile) 
					-t targetfile -r resultfile 
					[--obotarget || --owltarget]

Optional '--obotarget' setting specifies that the target file is an OBO ontology.
Optional '--owltarget' setting specifies that the target file is an OWL ontology.

=head2 INPUT FILES

=over

=item ontologies to map the targetfile against

owlfile, obofile, meshfile, omimfile are ontologies in OWL, OBO, MeSH ASCII and OMIM 
formats respectively 
Only a single file needs to be specified.

=item targetfile

The script expects a tab-delimited text file with headers. Only the first column will 
be used for matching. All other columns will be preserved in the output.

=back

=head2 OUTPUT

The script will produce a single tab-delimited file as set with the
-r flag. The file will have four additional headers

=over

=item SOURCE_ACCESSION

Accession of the source term if target file was an ontology.

=item SOURCE_LABEL

Label of the source term if target file was an ontology.

=item SOURCE_VALUE

The annotation (label or synoym if target file was an ontology) that was matched 
based on the highest similarity against the supplied ontology file

=item MATCHED_ACCESSION

Accession of the matched term that provided the best match.

=item MATCHED_LABEL

Matched term's label.

=item MATCHED_VALUE

The actual term's annotation (label or synoym) that was matched 
based on the highest similarity from the supplied ontology file.

=item MATCH_SIMILARITY%

Similarity score of the two matched terms normalised by lenght of the
longer of the two strings and expressed in %. Higher is better.

=back

=cut

use lib 'C:\Users\Tomasz\workspace\cpan-distribution\FuzzyRecogniser\lib',
  'C:\strawberry\perl\site\lib',
  '/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib/perl5/',
  '/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib64/perl5/',
  '/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib/perl5/site_perl/',
  '/ebi/microarray/ma-subs/AE/subs/PERL_SCRIPTS/local/lib64/perl5/site_perl/';

use strict;
use warnings;

use EBI::FGPT::FuzzyRecogniser;

#use IO::File;
use Getopt::Long;
use Log::Log4perl qw(:easy);

#use IO::Handle;
use Benchmark ':hireswallclock';

use Data::Dumper;

Log::Log4perl->easy_init( { level => $INFO, layout => '%-5p - %m%n' } );

# script arguments
my (
	$owlfile,   $obofile,   $targetfile, $resultfile,
	$obotarget, $owltarget, $meshfile,   $omimfile
);

my @flat_header;

my $fuzzy;

sub main() {

	# initalize

	GetOptions(
		"o|obofile=s"  => \$obofile,
		"w|owlfile=s"  => \$owlfile,
		"m|meshfile=s" => \$meshfile,
		"i|omimfile=s" => \$omimfile,
		"t|target=s"   => \$targetfile,
		"r|results=s"  => \$resultfile,
		"obotarget"    => \$obotarget,
		"owltarget"    => \$owltarget,
	);

	usage()
	  unless ( $owlfile || $obofile || $meshfile || $omimfile )
	  && $targetfile
	  && $resultfile;

	# load appropriate files
	$fuzzy = EBI::FGPT::FuzzyRecogniser->new( obofile => $obofile ) if $obofile;
	$fuzzy = EBI::FGPT::FuzzyRecogniser->new( owlfile => $owlfile ) if $owlfile;
	$fuzzy = EBI::FGPT::FuzzyRecogniser->new( meshfile => $meshfile )
	  if $meshfile;
	$fuzzy = EBI::FGPT::FuzzyRecogniser->new( omimfile => $omimfile )
	  if $omimfile;

	unless ( defined $obotarget || defined $owltarget ) {
		matchFlat($targetfile);
	}
	else {
		matchOntology();
	}

}

sub usage() {
	print(<<"USAGE");

similarity_match.pl (-w owlfile || -o obofile || -m meshfile || -i omimfile) 
					-t targetfile -r resultfile 
					[--obotarget || --owltarget]

Optional '--obotarget' setting specifies that the target file is an OBO ontology
Optional '--owltarget' setting specifies that the target file is an OWL ontology
USAGE
	exit 255;
}

=head1 DESCRIPTION

=head2 Function list

=over

=item align()

Aligns the two data structures targetfile and ontology. Outputs
the results into a file.

=cut

sub matchOntology() {
	open my $fh_out, '>', $resultfile;
	$fh_out->autoflush(1);

	my $terms;
	$terms =
	  EBI::FGPT::FuzzyRecogniser->new( obofile => $obofile )->ontology_terms()
	  if $obofile;
	$terms =
	  EBI::FGPT::FuzzyRecogniser->new( owlfile => $owlfile )->ontology_terms()
	  if $owlfile;

	# write header
	print $fh_out "SOURCE_ACCESSION\tSOURCE_LABEL\tSOURCE_VALUE\t";
	print $fh_out
	  "MATCHED_ACCESSION\tMATCHED_LABEL\tMATCHED_VALUE\tMATCH_SIMILARITY%";
	print $fh_out "\n";

	my $c  = 0;
	my $t0 = new Benchmark;

	for my $term (@$terms) {
		my $label     = $term->label();
		my $accession = $term->accession();

		#loop through all the annotations on the ontology term
		for my $annotation ( @{ $term->annotations } ) {
			my $value = $annotation->value();
			print $fh_out $accession . "\t" . $label . "\t" . $value . "\t";

			# output match info
			my $match_result = $fuzzy->find_match($value);
			print $fh_out $match_result->{term}->accession() . "\t"
			  . $match_result->{term}->label() . "\t"
			  . $match_result->{value} . "\t"
			  . $match_result->{similarity};

			# line ending
			print $fh_out "\n";

			INFO "Processed " . $c
			  if ++$c % 100 == 0;
		}

	}

	my $t1 = new Benchmark;
	INFO "Processed $c elements in " . timestr( timediff( $t1, $t0 ) );
	close $fh_out;
}

=item parseFlat()

Custom flat file parser.

=cut

sub matchFlat($) {
	my $file = shift;
	my $value;
	my %duplicate;
	INFO "Parsing flat file $file ...";

	open my $fh_in,  '<:utf8', $file;
	open my $fh_out, '>:utf8', $resultfile;
	$fh_out->autoflush(1);

	# parse input header
	my $header = <$fh_in>;
	chomp $header;
	( $flat_header[0], $flat_header[1] ) = parseFlatColumns($header);

	INFO "Using first line as header <$header>";
	INFO "Using first column <$flat_header[0]> to match terms";

	# Write output header
	print $fh_out "SOURCE_VALUE[" . $flat_header[0] . "]\t";
	print $fh_out
	  "MATCHED_ACCESSION\tMATCHED_LABEL\tMATCHED_VALUE\tMATCH_SIMILARITY%";
	print $fh_out "\t$flat_header[1]" if defined $flat_header[1];
	print $fh_out "\n";

	my $c  = 0;
	my $t0 = new Benchmark;

	# load input
	while (<$fh_in>) {
		chomp;
		next if /^$/;    # skip empty line

		# preserve existing columns in the file
		my ( $value, $ragged_end ) = parseFlatColumns($_);

		# trim
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;

		# drop trailing quotation marks (excel artefact?)
		$value =~ s/^"+//;
		$value =~ s/"+$//;

		WARN "Duplicated <$value>" if exists $duplicate{$value};
		$duplicate{$value}++;
		
		print $fh_out $value . "\t";

		# output match info
		my $match_result = $fuzzy->find_match($value);
		print $fh_out $match_result->{term}->accession() . "\t"
		  . $match_result->{term}->label() . "\t"
		  . $match_result->{value} . "\t"
		  . $match_result->{similarity};

		# line ending
		print $fh_out "\n";

		INFO "Processed " . $c
		  if ++$c % 100 == 0;

		# output unprocessed columns back
		print $fh_out "\t" . $ragged_end if defined $ragged_end;
	}

	my $t1 = new Benchmark;
	INFO "Processed $c elements in " . timestr( timediff( $t1, $t0 ) );
	close $fh_out;
	close $fh_in;
}

=item parseFlatColumns()

Splits and joins the columns of a flat file. The first column is assigned to the first element. 
Concatenates the ragged end (leftover columns) into the second element or returns undef for 
a one-column file.

=cut

sub parseFlatColumns($) {
	my $header = shift;

	my @temp = split /\t/, $header;
	return ( $temp[0], ( join( "\t", @temp[ 1 .. $#temp ] ) || undef ) );
}

=back

=cut

=head1 ACKNOWLEDGMENTS

Emma Hastings <emma@ebi.ac.uk>

=cut

=head1 AUTHORS

Tomasz Adamusiak <tomasz@cpan.org>

=cut

main();
