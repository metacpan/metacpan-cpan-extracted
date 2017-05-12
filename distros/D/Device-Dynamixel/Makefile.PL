use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Device::Dynamixel',
    AUTHOR              => q{Dima Kogan <dkogan@cpan.org>},
    VERSION_FROM        => 'lib/Device/Dynamixel.pm',
    ABSTRACT_FROM       => 'lib/Device/Dynamixel.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
	'Const::Fast' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-Dynamixel-*' },
);

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

This is a simple driver for control of Robotis Dynamixel servo
motors. This repository stores the history for the Device::Dynamixel
module on CPAN. Install the module via CPAN. CPAN page at
L<http://search.cpan.org/~dkogan/Device-Dynamixel/lib/Device/Dynamixel.pm>

=cut

EOF

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open MOD, 'lib/Device/Dynamixel.pm' or die "Couldn't open main module";
  open README, '>README.pod'     or die "Couldn't open README.pod";

  print README $POD_header;

  while (<MOD>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}
