use strict;
use warnings;

use Test::More tests => 22;
use File::Spec::Functions ':ALL';
use File::Find::Rule       ();
use File::Find::Rule::Perl ();

use constant FFR => 'File::Find::Rule';





#####################################################################
# Run four variations of the standard query

SCOPE: {
	my @params = (
		[ ],
		[ curdir() ],
		[ 'META.yml' ],
		[ { directory => [ 'inc', 't', 'xt' ] } ],
	);

	foreach my $p ( @params ) {
		my $rule  = FFR->relative->no_index(@$p)->file;
		isa_ok( $rule, 'File::Find::Rule' );

		my %ignore = map { $_ => 1 } qw{
			Makefile
			MANIFEST
                        MANIFEST.SKIP
			LICENSE
			README
			pm_to_blib
                        MYMETA.yml
                        MYMETA.json
                        Makefile.old
		};
		my @files = sort grep {
			! /^debian\b/
			and
			! /(?:^|\W)\.\w/
			and
			! /\bblib\b/
			and
			! /\b_eumm\b/
			and
			! $ignore{$_}
		} $rule->in( curdir() );

		is_deeply( \@files, [ qw{
			Changes
                        META.json
			META.yml
			Makefile.PL
			lib/File/Find/Rule/Perl.pm
		} ], 'Found the expected files' );
	}
}

###################################################################
# Several variations of absolute path and relative path , both 
# in no_index and in search prefix.

SCOPE: {
	my @params = (
		{
			name  => 'Relative Path',
			path  => 'lib/File/Find/Rule/Perl.pm',
			dir   => curdir(),
			check => [ 'Rule', 'Perl.pm' ],
		},
		{
			name  => 'Absolute path, Absolute Dir',
			path  => rel2abs(curdir())
			       . '/lib/File/Find/Rule/Perl.pm',
			dir   => rel2abs(curdir()),
			check => [ 'Rule', 'Perl.pm' ],
		},
	);

	foreach my $p ( @params ) {
		my $check = quotemeta File::Spec->catfile( @{$p->{check}} );
		my $regex = qr/$check/;
		my $rule  = FFR->relative->no_index( {
			file => [ $p->{path} ]
		} )->file;

		my @files = sort grep {
			$_ !~ m/\bblib\b/ and $_ =~ $regex
		} $rule->in( $p->{dir} );

		if ( @files ) {
			ok( 0, 'No_index + filename ' . $p->{name} );
			for ( @files ) {
				diag( "File Found: $_ \n , no_index file was <$p->{path}>");
			}
		} else { 
			ok( 1, 'No_index + filename ' . $p->{name} );
		}
	}
}





#####################################################################
# Run a test in a relative subdirectory
# Test with and without ->relative, and with and without a relative ->in

# With relative enabled
SCOPE: {
	my $dir = catdir('t', 'dist');
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->relative->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is_deeply( \@files, [ qw{
		META.yml
		lib/Foo.pm
	} ], 'Found the expected files' );
}

# With relative disabled
SCOPE: {
	my $dir = catdir('t', 'dist');
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is( scalar(@files), 2, 'Found the same file quantity' );
}

# With relative enabled
SCOPE: {
	my $dir = rel2abs(catdir('t', 'dist'));
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->relative->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is_deeply( \@files, [ qw{
		META.yml
		lib/Foo.pm
	} ], 'Found the expected files' );
}

# With relative disabled
SCOPE: {
	my $dir = rel2abs(catdir('t', 'dist'));
	ok( -d $dir, 'Found testing directory' );
	my $rule = FFR->no_index->file;
	isa_ok( $rule, 'File::Find::Rule' );
	my @files = sort grep {
		! /\.svn\b/
		and
		! /\bblib\b/
	} $rule->in($dir);
	is( scalar(@files), 2, 'Found the same file quantity' );
}
