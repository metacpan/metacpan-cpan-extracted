use ExtUtils::MakeMaker;



sub is_hg_installed {
    my $path_hg = `which hg`;
    my $bin_hg  = `whereis hg`;

    my $hgs = $path_hg.$bin_hg;

    my @hgs = split(/\n/,$hgs);

    my $hg = $hgs[0];

    if( -x $hg ) { 
        return 1;
    }
    else {
        return 0;
    }
}

exit 0 unless is_hg_installed;

WriteMakefile(
NAME => "My::Module",
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
);


