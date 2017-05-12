use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $samples = { 
        "samples/beep.PL"  => "samples/beep.pl",
        "samples/motor.PL" => "samples/motor.pl",
      };    

WriteMakefile(
    'NAME'	=> 'LEGO::RCX',
    'VERSION_FROM' => 'RCX.pm', # finds $VERSION
    'PL_FILES' => $samples,
    'dist' => { 'DIST_DEFAULT' => 'rcx_docs tardist' },
);

package MY;

sub MY::postamble {
'
rcx_docs : RCX.pm
	pod2text RCX.pm > DOCS
'
}

sub MY::clean {
    my $this = shift;
    
    $this->SUPER::clean( @_ ) . 
    "\n\t-rm DOCS"
}

