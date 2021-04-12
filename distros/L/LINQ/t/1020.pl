use v5.14;
use strict;
use warnings;
use Path::Tiny;

for my $file ( path( "t" )->children ) {
	next unless -f $file;
	next unless $file =~ /10array/;
	
	my $new = path( $file =~ s/10array/20iter/r );
	
	$new->spew_utf8(
		map {
			if ( /\A=cut/ ) {
				( $_, "\n", "BEGIN { \$LINQ::FORCE_ITERATOR = 1 }\n" );
			}
			elsif ( /L<LINQ::Array>/ ) {
				s/L<LINQ::Array>/L<LINQ::Iterator>/r;
			}
			else {
				$_;
			}
		} $file->lines_utf8
	);
	
	say "$file -> $new";
} #/ for my $file ( path( "t"...))
