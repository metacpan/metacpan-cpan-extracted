use ExtUtils::MakeMaker;

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("YAML not installed, will not override META.yml");
    return $self->SUPER::metafile_target(@_);
  };

  use YAML::Node;
  my $node = YAML::Node->new({});

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = $self->{VERSION_FROM};
  $node->{license}              = 'perl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'perl';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}

WriteMakefile(
    'NAME'		=> 'Math::Fractal::Mandelbrot',
    'VERSION_FROM'	=> 'lib/Math/Fractal/Mandelbrot.pm', # finds $VERSION
#    'PREREQ_PM'		=> {
#			   }, 
#    'LIBS'		=> [''], # e.g., '-lm'
#    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
#    'INC'		=> '', # e.g., '-I/usr/include/other'
);
