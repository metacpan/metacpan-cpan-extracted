use File::Find;
use Test::More;

my @classes = my_find();

plan tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "bail out! $class did not compile\n" unless use_ok( $class );
	}

sub my_find
	{
	my @files = ();
	
	find(
		sub { 
			return unless -f $_;
			if( /\.pm$/ )
				{
				my $file = $File::Find::name;
				$file =~ s|blib/lib/||;
				$file =~ s|/|::|g;
				$file =~ s|\.pm$||;
				
				push @files, $file;
				}
			},
		"blib"
		);
		
	@files;
	}
