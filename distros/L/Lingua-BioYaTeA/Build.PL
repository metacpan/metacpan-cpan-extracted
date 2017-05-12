use Module::Build;

# my $class = Module::Build->subclass(code => <<'EOF');
# sub process_dat_files {
#     my $self = shift;
#     ... locate and process *.dat files,
#     ... and create something in blib/lib/
#     }
# EOF


 
my $class = Module::Build->subclass(
				    class => "Module::Build::Custom",
code => <<'SUBCLASS' );

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install;
#     warn "\nDon't forget to set the variables CONFIG_DIR and LOCALE_DIR in the configuration file bioyatea.rc to the right path if necessary.\n\n";
}

sub ACTION_fakeinstall {
    my $self = shift;
    $self->SUPER::ACTION_fakeinstall;

#     warn "\nDon't forget to set the variables CONFIG_DIR and LOCALE_DIR in the configuration file bioyatea.rc to the right path if necessary.\n\n";
}

sub ACTION_build {
    my $self = shift;

    require Config::General;

#     warn "Setting configuration variables in etc/bioyatea/bioyatea.rc\n";
#     my $rcfile = $self->base_dir() . "/etc/bioyatea/bioyatea.rc";
#     # warn "RCFILE: $rcfile\n";
#     chmod(0644, $rcfile);
#     if (!( -f "$rcfile.orig") ) {
# 	File::Copy::copy($rcfile, "$rcfile.orig");
#     }

#     my $conf = new Config::General('-ConfigFile' => $rcfile . ".orig",
# 				   '-InterPolateVars' => 0,
# 				   '-InterPolateEnv' => 0,
# 				   '-StoreDelimiter' => " = ",
# 				   );
#     my %config = $conf->getall;
#     # warn "SHARE: " .  $self->install_destination("share") . "\n";
#     $config{'DefaultConfig'}->{'CONFIG_DIR'} = $self->install_destination("share") . "/BioYaTeA/config";
#     $config{'DefaultConfig'}->{'LOCALE_DIR'} = $self->install_destination("share") . "/BioYaTeA/locale";

#     # warn $config{'DefaultConfig'}->{'CONFIG_DIR'} . "\n";

#     $conf->save_file($rcfile,\%config);
#     warn "Done\n";

#     warn "Setting the default location of bioyatea.rc in lib/Lingua/BioYaTeA.pm\n";
#     my $mainpmfile = $self->base_dir() . "/lib/Lingua/BioYaTeA.pm";
    
#     require File::Copy;

#     my $n = FileHandle->new($mainpmfile,"r");
# #     File::Copy->cp($n,"$mainpmfile.orig");

#     chmod(0644, $mainpmfile);
#     if (!( -f "$mainpmfile.orig") ) {
# 	File::Copy::copy($mainpmfile, "$mainpmfile.orig");
#     }
#     my $line;
#     open MAINPMFILE, "$mainpmfile.orig" or die "No such file ($mainpmfile.orig)\n";
#     open MAINPMFILEDEST, ">$mainpmfile" or die "Can not open file $mainpmfile\n";
#     while($line = <MAINPMFILE>) {
# 	if ($line =~ /^(\s\$rcfile\s=\s\")\/etc\/bioyatea\/bioyatea.rc(\".*\n)/) {
# 	    $line = $1 . $self->install_destination("conf") . "/bioyatea/bioyatea.rc" . $2;
# 	}
# 	print MAINPMFILEDEST $line;
#     }
#     close MAINPMFILE;
#     close MAINPMFILEDEST;
#     warn "Done\n";

    $self->SUPER::ACTION_build;
}

sub ACTION_clean {
    my $self = shift;
    $self->SUPER::ACTION_clean;

    # require File::Copy;
    # my $mainpmfile = $self->base_dir() . "/lib/Lingua/BioYaTeA.pm";
    # File::Copy::move("$mainpmfile.orig", $mainpmfile);

    # my $rcfile = $self->base_dir() . "/etc/bioyatea/bioyatea.rc";
    # File::Copy::move("$rcfile.orig", $rcfile);
}

SUBCLASS

my $build = $class->new
    (
     module_name => 'Lingua::BioYaTeA',
     dist_version_from => 'lib/Lingua/BioYaTeA.pm',
     license => 'perl',
     configure_requires => { 'Module::Build' => 0.38,
			     'File::chmod' => 0,
     },
     requires => {'perl' => '5.005',
		  Lingua::YaTeA => 0.622,
		  Data::Dumper => 0, 
		  Pod::Usage => 0,
		  Config::General => 2.30,
		  Test::More     => 0.62,
		  Test::Pod::Coverage => 0,
		  Test::Pod => 0,
		  File::Basename => 0,
		  Getopt::Long => 0,
		  XML::Twig => 3.3,
		  'Module::Build::Compat' => 0,
		  },

#      $build->add_build_element('dat');
#      $build->create_build_script;

    build_requires => {
        "Module::Build"     => 0.28,
	Test::More     => 0.62,
    },


#       installdirs => 'core',
     conf_files => {'etc/bioyatea/bioyatea.rc' => 'conf/bioyatea/bioyatea.rc'},
     share_files => {
     		     'share/BioYaTeA/config/EN/ChunkingExceptions' => 'share/BioYaTeA/config/EN/ChunkingExceptions',
     		     'share/BioYaTeA/config/EN/ChunkingFrontiers' => 'share/BioYaTeA/config/EN/ChunkingFrontiers',
     		     'share/BioYaTeA/config/EN/CleaningExceptions' => 'share/BioYaTeA/config/EN/CleaningExceptions',
     		     'share/BioYaTeA/config/EN/CleaningFrontiers' => 'share/BioYaTeA/config/EN/CleaningFrontiers',
     		     'share/BioYaTeA/config/EN/ForbiddenStructures' => 'share/BioYaTeA/config/EN/ForbiddenStructures',
     		     'share/BioYaTeA/config/EN/LGPmapping' => 'share/BioYaTeA/config/EN/LGPmapping',
     		     'share/BioYaTeA/config/EN/LinguisticConfiguration' => 'share/BioYaTeA/config/EN/LinguisticConfiguration',
     		     'share/BioYaTeA/config/EN/Options' => 'share/BioYaTeA/config/EN/Options',
     		     'share/BioYaTeA/config/EN/ParsingPatterns' => 'share/BioYaTeA/config/EN/ParsingPatterns',
     		     'share/BioYaTeA/config/EN/TagSet' => 'share/BioYaTeA/config/EN/TagSet',
     		     'share/BioYaTeA/locale/EN/Messages' => 'share/BioYaTeA/locale/EN/Messages',
     		 },
     );

$build->install_base_relpaths( conf => 'etc' );
$build->prefix_relpaths('site', conf => 'etc' );
$build->prefix_relpaths('core', conf => 'etc' );
$build->prefix_relpaths('vendor', conf => 'etc' );
$build->add_build_element('conf');


$build->install_base_relpaths( share => 'share' );
$build->prefix_relpaths('site', share => 'share' );
$build->prefix_relpaths('core', share => 'share' );
$build->prefix_relpaths('vendor', share => 'share' );
$build->add_build_element('share');

foreach my $type (keys(%{$build->install_sets})) {
    $build->install_sets->{$type}->{'conf'} = '/etc';
    $build->install_sets->{$type}->{'share'} = '/usr/share';
}

$build->install_sets->{'site'}->{'share'} = '/usr/local/share';

$build->install_sets->{'site'}->{'conf'} = '/usr/local/etc';

$build->install_path->{'conf'} = $build->prefix() . '/etc';
$build->install_path->{'share'} = $build->prefix() .  '/usr/share';

# # same thing with prefix
# if (((defined $build->install_base()) && ($build->install_base() eq "/usr")) ||
#     ((defined $build->prefix()) && ($build->prefix() eq "/usr")))
#  {
# 	$build->install_path->{'conf'} = '/etc';
# 	$build->install_path->{'share'} = '/usr/share';
# }


$build->create_build_script;


