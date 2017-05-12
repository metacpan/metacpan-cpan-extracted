package t::lib::Test;

use strict;
use warnings;
use Test::Builder;
use Test::LongString;
use Exporter ();

our $VERSION = '0.78';
our @ISA     = 'Exporter';
our @EXPORT  = qw{ code compiles slurp };

sub code {
	my $left    = shift;
	my $right   = shift;
	if ( ref $left ) {
		$left = join '', map { "$_\n" } @$left;
	}
	if ( ref $right ) {
		$right = join '', map { "$_\n" } @$right;
	}
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is_string( $left, $right, $_[0] );
}

sub compiles {
	my $code    = shift;
	my $package = shift;
	if ( ref $code ) {
		$code = join '', map { "$_\n" } @$code;
	}
	SKIP: {
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		my $Test = Test::Builder->new;
		if ( $ENV{ADAMK_RELEASE} ) {
			foreach ( 1 .. 4 ) {
				$Test->ok( 1, "Skipped $_[0]" );
			}
		} else {
			# Compile the dialog
			local $@;
			unless ( $package ) {
				$code = "return 1; $code";
			}
			my $rv = do {
				eval($code);
			};
			$Test->diag( $@ ) if $@;
			$Test->ok( $rv, $_[0] );

			# Try to create the object
			if ( $package ) {
				Test::More::use_ok('Wx');
				my $app = Wx::SimpleApp->new;
				Test::More::isa_ok( $app, 'Wx::App' );

				# Create the Form
				my $form = $package->new;
				Test::More::isa_ok( $form, 'Wx::Object' );
			} else {
				foreach ( 1 .. 3 ) {
					$Test->ok( 1, "Skipped $_[0]" );
				}
			}
		}
	}
}

# Provide a simple slurp implementation
sub slurp {
	my $file = shift;
	local $/ = undef;
	local *FILE;
	open( FILE, '<:utf8', $file ) or die "open($file) failed: $!";
	binmode( FILE, ':crlf' );
	my $text = <FILE>;
	close( FILE ) or die "close($file) failed: $!";
	return $text;
}

sub dval {
	# Write the code to the temp file
	require File::Temp;
	my ($fh, $filename) = File::Temp::tempfile();
	$fh->print($_[0]);
	close $fh;
	require $filename;
	unlink $filename;

	# Print the debugging output
	# my @trace = map {
		# s/\s*[{;]$//;
		# s/^s/  s/;
		# s/^p/\np/;
		# "$_\n"
	# } grep {
		# /^(?:package|sub)\b/
	# } split /\n/, $_[0];
	# print STDERR @trace, "\nCode saved as $filename\n\n";

	return 1;
}

1;
