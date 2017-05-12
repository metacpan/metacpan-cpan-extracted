use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Spec;
use File::Temp 0.20;
use Cwd;
use JSON::MaybeXS ();

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my $json = JSON::MaybeXS->new(ascii => 1);

sub _compare {
    my ( $report1, $report2 ) = @_;
    is(
        $report1->core_metadata->{resource},
        $report2->core_metadata->{resource},
        "Checking URI"
    );
    is( $report1->guid, $report2->guid, "Checking GUID" );
    for my $i ( 0 .. 1 ) {
        is_deeply(
            $report1->{content}[$i]->as_struct,
            $report2->{content}[$i]->as_struct,
            "Checking fact $i",
        );
    }
    return 1;
}

#--------------------------------------------------------------------------#
# start testing
#--------------------------------------------------------------------------#

require_ok('Metabase::User::Profile');
require_ok('Metabase::User::Secret');

#--------------------------------------------------------------------------#
# new profile creation
#--------------------------------------------------------------------------#

my $profile;

is exception {
    $profile = Metabase::User::Profile->create(
        full_name     => "J\x{022f}hn Doe",
        email_address => 'jdoe@example.com',
    );
}, undef,
"create new profile";

isa_ok( $profile, 'Metabase::User::Profile' );

#--------------------------------------------------------------------------#
# save and load profiles
#--------------------------------------------------------------------------#

my $tempdir = File::Temp::tempdir( CLEANUP => 1 );

my $profile_file = File::Spec->catfile( $tempdir, 'profile.json' );

$profile->save($profile_file);

ok( -r $profile_file, 'profile saved to file' );

my $profile_copy = Metabase::User::Profile->load($profile_file);
ok( $profile_copy, "Loaded profile file (created with ->create)" );
isa_ok( $profile_copy, 'Metabase::User::Profile' );

_compare( $profile, $profile_copy );

# try profile-generator
my $bin = File::Spec->rel2abs( File::Spec->catfile(qw/bin metabase-profile/) );
my $cwd = Cwd::cwd();
chdir $tempdir;
END { chdir $cwd }
my $output_file = 'my.profile.json';
my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
$bin = $bin =~ m/\s/ ? qq{"$bin"} : $bin;
qx/$X $bin -o $output_file --name "JohnPublic" --email jp\@example.com --secret 3.14159/;
ok( -r $output_file, 'created named profile file with metabase-profile' );

qx/$X $bin --name "JohnPublic" --email jp\@example.com --secret 3.14159/;
ok( -r 'metabase_id.json', 'created default profile file with metabase-profile' );

my $file_guts = do { local ( @ARGV, $/ ) = 'metabase_id.json'; <> };
my $facts         = $json->decode($file_guts);
my $profile_copy2 = Metabase::User::Profile->from_struct( $facts->[0] );
ok( $profile_copy2, "Loaded profile from file" );
my $secret_copy2 = Metabase::User::Secret->from_struct( $facts->[1] );
ok( $secret_copy2, "Loaded secret from file" );

done_testing;
