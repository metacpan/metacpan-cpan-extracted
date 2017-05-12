use 5.008000;
use ExtUtils::MakeMaker;
use strict;

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("YAML not installed, 'make dist' will not override 'META.yml'.");
    return $self->SUPER::metafile_target(@_);
  };

  require YAML::Node;
  my $node = YAML::Node->new({});

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = $self->{VERSION_FROM};
  $node->{license}              = 'gpl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'site';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}

eval { require Graph::Easy::As_svg; };

my $ver = $Graph::Easy::As_svg::VERSION;

if (!defined $ver)
  {
  print "\n************\n";
  print "Warning: You do not seem to have Graph::Easy::As_svg installed.\n";
  print "         SVG output is not possible until you install it afterwards.\n\n";
  }

if (defined $ver && $ver <= 0.16)
  {
  print "\n************\n";
  print "Warning: Your Graph::Easy::As_svg version is outdated.\n";
  print "         Please upgrade it after installing this package.\n\n";
  }

WriteMakefile(
    NAME		=> 'Graph::Dependency',
    VERSION_FROM	=> 'lib/Graph/Dependency.pm', # finds $VERSION
    PREREQ_PM		=> {
	"Graph::Easy" => 0.40,
	"Module::CoreList" => 2.02,
	"YAML" => 0,
	},
    ABSTRACT_FROM	=> 'lib/Graph/Dependency.pm',
    AUTHOR		=> 'Tels <nospam-abuse@bloodgate.com>',
    PREREQ_FATAL	=> 1,  # can't work w/o proper prereqs
);
