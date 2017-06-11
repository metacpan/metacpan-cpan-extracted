use strict;
use warnings;
use Dist::Surveyor::Inquiry;
use Data::Dumper;
use Test::More;
use Test::RequiresInternet 'fastapi.metacpan.org' => 443;

my $module_data = get_module_versions_in_release('SEMUELF', 'Dist-Surveyor-0.009');
my $expected =  {
    'Dist::Surveyor' => {
        'version' => '0.009',
        'name' => 'Dist::Surveyor',
        'path' => 'lib/Dist/Surveyor.pm',
        'size' => 43879
    },
    'Dist::Surveyor::DB_File' => {
        'version' => '0.009',
        'name' => 'Dist::Surveyor::DB_File',
        'path' => 'lib/Dist/Surveyor/DB_File.pm',
        'size' => 676
    }
};
is_deeply($module_data, $expected, "get_module_versions_in_release");

my $releases = get_candidate_cpan_dist_releases("Dist::Surveyor::DB_File", "0.009", 676);
is_deeply([keys %$releases], ['Dist-Surveyor-0.009'], "Got the right release");
is( $releases->{'Dist-Surveyor-0.009'}->{path}, 'lib/Dist/Surveyor/DB_File.pm', "Found the file" );

my $release_info = get_release_info('SEMUELF', 'Dist-Surveyor-0.009');
is($release_info->{name}, 'Dist-Surveyor-0.009', "Got the right release");
is($release_info->{download_url}, 'https://cpan.metacpan.org/authors/id/S/SE/SEMUELF/Dist-Surveyor-0.009.tar.gz', 
    "Got the right download URL");

done_testing();
