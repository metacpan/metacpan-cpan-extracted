use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'File::Groups',
    AUTHOR	    => 'Skye Shaw <skye.shaw AT gmail.com>',
    LICENSE         => 'perl',
    VERSION_FROM    => 'lib/File/Groups.pm',
    ABSTRACT_FROM   => 'lib/File/Groups.pm',
    META_MERGE  => {
      'meta-spec'    => {version => 2},
       resources => {
         homepage => 'https://github.com/sshaw/file_groups',
         bugtracker => { web => 'https://github.com/sshaw/file_groups/issues' },
         repository => {
           type => 'git',
           url  => 'https://github.com/sshaw/file_groups.git',
           web  => 'https://github.com/sshaw/file_groups'
         }
       }
    }
);


# Create README.pod for a repo's GitHub page. Unlike CPAN, GitHub won't
# display the module's POD, it looks for a README.*
sub MY::postamble
{
  my $self = shift;
  return if -r 'README' or ! -r $self->{VERSION_FROM};
  return<<END_MAKE;
README.pod: $self->{VERSION_FROM}
	\@perldoc -uT $self->{VERSION_FROM} > README.pod
END_MAKE
}

# Include test helpers and/or libs
sub MY::test
{
  package MY;
  my $make = shift->SUPER::test(@_);
  $make .= 'FULLPERLRUN = $(FULLPERL) -I t -I t/lib';
  return $make;
}
