# DMR: old school perl script that downloads a yaml and prints out some xyz
# files
use Modern::Perl;
use YAML::XS qw(Dump LoadFile);
use Path::Tiny;
use File::chdir;

my $yaml = "ct300296k_si_001.txt";
my $webyaml =
  "http://pubs.acs.org/doi/suppl/10.1021/ct300296k/suppl_file/$yaml";

system("wget $webyaml") unless ( -e $yaml );
my $data   = LoadFile($yaml);
my $xyzdir = path("xyzs");
$xyzdir->mkpath unless $xyzdir->exists;

{
    local $CWD = $xyzdir;

    foreach my $sol (qw(aq)) {
        foreach my $nw ( keys( %{ $data->{$sol} } ) ) {
            foreach my $config ( keys( %{ $data->{$sol}{$nw} } ) ) {
                my $xyz      = $data->{$sol}{$nw}{$config}{Z_xyz};
                my $dump_xyz = scalar( @{$xyz} ) . "\n\n";
                $dump_xyz .= join( "\n", @{$xyz} );
                my $fxyz = path("$sol-$nw-$config.xyz");
                $fxyz->spew($dump_xyz);
            }
        }
    }
}
