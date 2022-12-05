#
# Copyright (c) homqyy
#
use 5.026003;
use ExtUtils::MakeMaker;
use FindBin qw($Bin);

my $project_dir = $Bin;
my $kcp_inc = defined $ENV{KCP_INC_DIR} ? $ENV{KCP_INC_DIR} :  "$project_dir";
my $kcp_lib = defined $ENV{KCP_LIB} ? $ENV{KCP_LIB} :  "$project_dir/libkcp.a";

WriteMakefile(
    NAME              => 'KCP',
    VERSION_FROM      => 'lib/KCP.pm',
    PREREQ_PM         => {
        'strict'        => 0,
        'warnings'      => 0,
        'Devel::PPPort' => '3.68',
    },
    ABSTRACT_FROM     => 'lib/KCP.pm',
    AUTHOR            => 'homqyy <yilupiaoxuewhq@163.com>',
    LICENSE           => 'mit',
    MYEXTLIB          => "$kcp_lib",
    LIBS              => [],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. -I$kcp_inc",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/Homqyy/kcp-perl.git',
              web  => 'https://github.com/Homqyy/kcp-perl',
          },
      }})
   : ()
  ),
);
