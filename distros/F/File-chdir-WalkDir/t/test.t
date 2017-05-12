use Test::More tests => 4;

BEGIN {
  use_ok('File::chdir::WalkDir');
}

my @files;
my $code = sub {
  my ($file, $dir) = @_;

  push @files, $file;
};

walkdir('test_files', $code);
is_deeply( [ sort @files ], [qw/ a1 a2 b1 c1 /], 'All' );

@files = ();
walkdir('test_files', $code, qr/^a$/ );
is_deeply( [ sort @files ], [qw/ b1 c1 /], 'Exclude a' );

@files = ();
walkdir('test_files', $code, qr/^a1$/ );
is_deeply( [ sort @files ], [qw/ a2 b1 c1 /], 'Exclude a1' );

