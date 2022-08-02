use strict; use warnings;

use CPAN::Meta;
use Software::LicenseUtils;
use Pod::Readme::Brief 1.001;
sub slurp { open my $fh, '<', $_[0] or die "Couldn't open $_[0] to read: $!\n"; local $/; readline $fh }

chdir $ARGV[0] or die "Cannot chdir to $ARGV[0]: $!\n";

my %file;

my $meta = CPAN::Meta->load_file( 'META.json' );

my $license = do {
	my @key = ( $meta->license, $meta->meta_spec_version );
	my ( $class, @ambiguous ) = Software::LicenseUtils->guess_license_from_meta_key( @key );
	die if @ambiguous or not $class;
	$class->new( $meta->custom( 'x_copyright' ) );
};

$file{'LICENSE'} = $license->fulltext;

my ( $main_module ) = map { s!-!/!g; "lib/$_.pm" } $meta->name;

for ( $file{ $main_module } = slurp $main_module ) {
	s{(?=^=cut\n\z)}{ join "\n\n", (
		'=head1 AUTHOR', $meta->authors,
		'=head1 COPYRIGHT AND LICENSE', $license->notice . "\n",
	) }me;
	$file{'README'} = Pod::Readme::Brief->new( $_ )
		->render( installer => -e 'Makefile.PL' ? 'eumm' : die );
}

for ( $file{'MANIFEST'} = slurp 'MANIFEST' ) {
	my %have  = map +( $_, 1 ), /^([^\s#]+)/mg;
	$_ = join '', sort map "$_\n", ( split /\n/, $_ ), ( grep !$have{ $_ }, keys %file );
}

for my $fn ( sort keys %file ) {
	unlink $fn if -e $fn;
	open my $fh, '>', $fn or die "Couldn't open $fn to write: $!\n";
	print $fh $file{ $fn };
	close $fh or die "Couldn't close $fn after writing: $!\n";
}
