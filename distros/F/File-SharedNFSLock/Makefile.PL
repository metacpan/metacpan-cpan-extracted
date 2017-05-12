use 5.008001;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::SharedNFSLock',
    VERSION_FROM      => 'lib/File/SharedNFSLock.pm', # finds $VERSION
    PREREQ_PM         => {
      'File::Copy'    => '0',
      'File::Spec'    => '0',
      'Sys::Hostname' => '0',
      'Time::HiRes'   => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/SharedNFSLock.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),

    ($mm_ver >= 6.46 ? (META_MERGE => {
      resources  => {
        bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-SharedNFSLock',
        homepage   => 'http://search.cpan.org/search?query=File%3A%3ASharedNFSLock&mode=dist',
        repository => 'git://github.com/fangly/file-sharednfslock.git',
      },
    }) : () ),

);
