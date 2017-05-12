use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  NAME          => 'IO::Multiplex::KQueue',
  ABSTRACT_FROM => 'lib/IO/Multiplex/KQueue.pm',
  VERSION_FROM  => 'lib/IO/Multiplex/KQueue.pm', # finds $VERSION
  PREREQ_PM     => { # e.g., Module::Name => 1.1
    'IO::Socket' => 0,
    'IO::KQueue' => 0.30,
  },
  dist => {
    COMPRESS => 'gzip -vf',
  },
  ;

package MY;

sub processPL {
  my $self = shift;
  my $block = $self->SUPER::processPL(@_);
  # "Version:" in spec needs to match
  # "$VERSION" from VERSION_FROM
  $block =~ s%(spec.PL\s*)$%$1 \$\(VERSION_FROM\)%m;
  $block;
}
