use strict;
use warnings;

use lib qw'lib inc';
use MyBuilder;
use Lingua::TreeTagger::Installer;

use Archive::Any;
use LWP::Simple;
use POSIX qw'uname';
use File::Path qw'remove_tree';
use File::Copy qw'move';

remove_tree 'treetagger';

my %common_requirements = (
                           'File::Copy' => 0,
                           'Test::More' => '0.40',
                           'Archive::Any' => 0,
                           'Getopt::Std' => 0,
                           'File::Basename' => 0,
                           'LWP::Simple' => 0,
                           'IO::Uncompress::Gunzip' => 0,
                           'File::Temp' => 0,
                           'Clone' => 0,
                           'YAML' => 0,
                          );

my $builder = MyBuilder->new
  (
   module_name    => 'Lingua::TreeTagger::Installer',
   dist_abstract  => "Automates TreeTagger installation",
   dist_author    => q{Alberto Simões <ambs@cpan.org>},
   license        => 'perl',
   requires           => \%common_requirements,
   build_requires     => \%common_requirements,
   configure_requires => \%common_requirements,
   add_to_cleanup => ['Lingua-TreeTagger-Installer-*', 'treetagger'],
  );


my $installlibdir =  $builder->install_destination("lib");
my $installbindir =  $builder->install_destination("bin");

my $treelibdir = "$installlibdir/treetagger";
my $treebindir = "$installbindir/treetagger";

$builder->config_data(lib => $installlibdir);
$builder->config_data(bin => $installbindir);

$builder->config_data(treelib => $treelibdir);
$builder->config_data(treebin => $treebindir);

my $platform = $^O;

if ($platform eq "linux") {
    $platform .= "64" if (uname())[4] =~ /64/;

    warn "Installing $platform binaries for Tree Tagger\n";

    $builder->notes('platform' => $platform);
}
elsif ($platform eq "darwin" && (uname())[4] =~ /86/) {
    warn "Installing x86 darwin binaries for Tree Tagger\n";
    $builder->notes('platform' => 'macosx-intel');
}
else {
    warn "Platform $platform not yet supported\n";
    return 0;
}

install_binary($builder->notes('platform'));
install_tagger_scripts();


sub install_binary {
    my $platform = shift;
    my $url = $Lingua::TreeTagger::Installer::data->{platforms}{$platform};

    mkdir "treetagger";

    warn "Fetching Tree-Tagger binary\n- $url\n";
    getstore $url => "treetagger.tar.gz";
    die "Could not download $url!\n" unless -f "treetagger.tar.gz";

    warn "- unwrapping tarball\n";
    my $tgz = Archive::Any->new("treetagger.tar.gz");
    $tgz->extract("treetagger");
    unlink "treetagger.tar.gz";

    return $platform;
}


sub install_tagger_scripts {
    my $url = "ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tagger-scripts.tar.gz";
    warn "Fetching Tree-Tagger scripts\n- $url\n";
    getstore $url => "tagger-scripts.tar.gz";

    warn "- unwrapping tarball\n";
    my $tgz = Archive::Any->new("tagger-scripts.tar.gz");
    $tgz->extract("treetagger");
    unlink "tagger-scripts.tar.gz";
}

process_files($builder,
              bin => $installbindir,
              cmd => $treebindir,
              lib => $treelibdir);

add_custom_installs($builder,
                    sitebin => $installbindir,
                    libdir  => $treelibdir,
                    bindir  => $treebindir);

$builder->create_build_script;


sub process_files {
    my ($builder, %paths) = @_;

    $builder->fix_shebang_line(glob("treetagger/cmd/*.perl"));

    for my $file (glob("treetagger/cmd/*")) {
        my $contents;
        {
            local $/ = undef;
            open F, "$file" or die;
            $contents = <F>;
            close F;
            
            $contents =~ s/BIN=.*/BIN='$paths{bin}'/;
            $contents =~ s/CMD=.*/CMD='$paths{cmd}'/;
            $contents =~ s/LIB=.*/LIB='$paths{lib}'/;
            open F, ">", "$file" or die;
            print F $contents;
            close F;
        }
    }
    for my $file (glob("treetagger/cmd/tree-tagger-*")) {
        move $file => "treetagger/bin";
    }
}

sub add_custom_installs {
    my $builder = shift;
    my %paths = @_;

    # Tell Module::Build there's two new types of installs.
    $builder->add_build_element('treelib');
    $builder->add_build_element('treebin');
    $builder->add_build_element('sitebin');

    # And where to install them.
    $builder->install_path( treebin => $paths{bindir} );
    $builder->install_path( treelib => $paths{libdir} );
    $builder->install_path( sitebin => $paths{sitebin});
}

