# This perl script writes the Makefile for Term::GetKey
# Time-stamp: "2003-0121 18:00:37 EST"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use strict;
print qq~
This is a dynamic module.
For documentation you may use either `man' or `perldoc'
to read about the features of `Term::GetKey.pm'.
~;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Term::GetKey',
    'VERSION_FROM' => 'GetKey.pm', # finds $VERSION
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__
