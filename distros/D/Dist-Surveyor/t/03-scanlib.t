use strict;
use warnings;
use Dist::Surveyor;
use FindBin;
use File::Spec;
use Archive::Tar;
use File::Path; # core
use Test::More;
use Test::RequiresInternet 'fastapi.metacpan.org' => 443;

# for updating the scanlib direcotry:
# 1. open the current scanlib.tar:
#    tar -xvf scanlib.tar
# 2. update the directory
# 3. create a new tar file:
#    tar -cvf scanlib.tar scanlib/

my $scan_dir = File::Spec->catdir($FindBin::Bin, "scanlib");
rmtree($scan_dir);
ok(!-e $scan_dir, "scanlib directory deleted");

my $next = Archive::Tar->iter( File::Spec->catdir($FindBin::Bin, 'scanlib.tar') );
while( my $f = $next->() ) {
    $f->extract( File::Spec->catdir($FindBin::Bin, $f->name) ) 
        or warn "Extraction failed ".$f->name;
}
$next = undef;
ok(-e $scan_dir, "scanlib directory was created");

my $options = {
    distro_key_mod_names => {},
};
my $libdirs = [ $scan_dir ];
my @installed_releases = determine_installed_releases($options, $libdirs);
@installed_releases = sort { $a->{name} cmp $b->{name} } @installed_releases;
is_deeply(
    [ 'Dist-Surveyor-0.009', 'Test-Class-0.36', 'Test-Deep-0.084' ], 
    [ map $_->{name}, @installed_releases ],
    "Got all three releases" );
is_deeply(
    ['100.00', '100.00', '2.78'],
    [ map $_->{dist_data}->{percent_installed}, @installed_releases ],
    "Got all three percents correctly" );

rmtree($scan_dir);
ok(!-e $scan_dir, "scanlib directory deleted");

done_testing();
