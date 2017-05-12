use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Inline::Guile',
    'VERSION_FROM' => 'Guile.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Inline' => "0.43",
                        'Guile'  => "0.001",
                        'Carp'   => 0, },
);

# avoid PERL_DL_NONLAZY.  libguile is missing symbols and it's not my
# job to fix...  
sub MY::test { 
    my $self = shift;
    package MY;
    my $result = $self->SUPER::test(@_);
    $result =~ s/PERL_DL_NONLAZY=1//g;
    return $result;
}
