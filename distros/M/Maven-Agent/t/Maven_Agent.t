use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Agent') }

use Digest::MD5;
use File::Basename;
use File::Spec;
use File::Temp;

my $test_dir          = dirname( File::Spec->rel2abs($0) );
my $maven_central_url = 'http://repo.maven.apache.org/maven2';

sub hash_file {
    my ($file) = @_;
    open( my $handle, '<', $file ) || croak("cant open $file: $!");
    binmode($handle);
    my $hash = Digest::MD5->new();
    $hash->addfile($handle);
    close($handle);
    return $hash->hexdigest();
}

# Verify local download with to
my $agent = Maven::Agent->new(
    M2_HOME     => File::Spec->catdir( $test_dir, 'M2_HOME' ),
    'user.home' => File::Spec->catdir( $test_dir, 'HOME' )
);
my $expected_file = File::Spec->catfile( $test_dir, 'HOME', '.m2', 'repository',
    'com', 'pastdev', 'foo', '1.0.1', 'foo-1.0.1.pom' );
my $to_file = File::Temp->new();
my $file = $agent->download( 'com.pastdev:foo:pom:1.0.1', to => $to_file );
is( $file, $to_file, 'file is to_file' );
is( do { local ( @ARGV, $/ ) = $to_file;       <> },
    do { local ( @ARGV, $/ ) = $expected_file; <> },
    'contents match'
);
my $to_dir = File::Temp->newdir();
$file = $agent->download( 'com.pastdev:foo:pom:1.0.1', to => $to_dir );
my $expected_download_file = File::Spec->catfile( $to_dir, 'foo.pom' );
is( $file, $expected_download_file, 'wrote expected file name to temp dir' );

SKIP: {
    eval { require LWP::UserAgent };

    skip "LWP::UserAgent not installed", 2 if $@;

    $agent = Maven::Agent->new(
        M2_HOME     => File::Spec->catdir( $test_dir, 'M2_HOME' ),
        'user.home' => File::Spec->catdir( $test_dir, 'HOME' )
    );

    if ( $agent->get_maven()->_default_agent( timeout => 1 )->head($maven_central_url)
        ->is_success() )
    {

        my $jta_jar = $agent->resolve('javax.transaction:jta:1.1');
        ok( $jta_jar, 'resolve jta jar' );

        my $jta_jar_file = $agent->download($jta_jar);
        ok( $jta_jar_file,    'got jta jar file' );
        ok( -s $jta_jar_file, 'jta jar file is not empty' );

        my $jta_jar_file_to = $agent->download( $jta_jar, to => File::Temp->new() );
        ok( $jta_jar_file_to,    'got jta jar to file to' );
        ok( -s $jta_jar_file_to, 'jta jar file to is not empty' );

        is( hash_file($jta_jar_file), hash_file($jta_jar_file_to), 'jta hashes match' );
    }
}

SKIP: {
    skip( 'not cygwin', 3 ) unless ( $^O eq 'cygwin' );

    # Verify local download with windows style localRepository in settings.xml
    my $winHome = File::Spec->catdir( $test_dir, 'WIN_HOME' );
    my $userHome = `cygpath -w $winHome`;
    $userHome =~ s/\n//g;
    my $agent = Maven::Agent->new(
        M2_HOME     => File::Spec->catdir( $test_dir, 'M2_HOME' ),
        'user.home' => $userHome
    );
    $expected_file = File::Spec->catfile(
        $test_dir, 'WIN_HOME', '.m2', 'repository',
        'com',     'pastdev',  'foo', '1.0.2',
        'foo-1.0.2.pom'
    );
    $to_file = File::Temp->new();
    my $file = $agent->download( 'com.pastdev:foo:pom:1.0.2', to => $to_file );
    is( $file, $to_file, 'cygwin file is to_file' );
    is( do { local ( @ARGV, $/ ) = $to_file;       <> },
        do { local ( @ARGV, $/ ) = $expected_file; <> },
        'cygwin contents match'
    );
    my $to_dir = File::Temp->newdir();
    $file = $agent->download( 'com.pastdev:foo:pom:1.0.2', to => $to_dir );
    my $expected_download_file = File::Spec->catfile( $to_dir, 'foo.pom' );
    is( $file, $expected_download_file, 'cygwin wrote expected file name to temp dir' );
}

done_testing();
