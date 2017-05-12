# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::BuildNum;
use strict;
use warnings;
use 5.010;

use Maplat::Helpers::DateStrings;
use Sys::Hostname;

use base qw(Exporter);
our @EXPORT = qw(calcBuildNum readBuildNum); ## no critic (Modules::ProhibitAutomaticExportation)

our $VERSION = 0.995;

sub calcBuildNum {
    state $fixedbuildnum;

    if(defined($fixedbuildnum)) {
        return $fixedbuildnum;
    }
    my $hname = hostname;
    my $ts = getFileDate();
    my $buildnum = $ts . "_" . $hname;
    $fixedbuildnum = $buildnum;
    
    return $buildnum;
}
#
# readBuildNum prepends a "C" if the build number is compiled in and
# a "G" if $isCompiled is set but no buildNum was generated during compile,
# and "R" if the program is run in the runtime environment
sub readBuildNum {
    my ($fname, $isCompiled) = @_;
    
    if(!defined($fname)) {
        $fname = "buildnum";
    }
    if(!defined($isCompiled)) {
        $isCompiled = 0;
    }
    
    if($isCompiled || (defined($main::isCompiled) && $main::isCompiled == 1)) { ## no critic (Variables::ProhibitPackageVars)
        print "Extracting compiled-in build number\n";
        foreach my $line (PerlApp::get_bound_file($fname)) {
            chomp $line;
            return "C" . $line;
        }
        
        return "G" . calcBuildNum;
    }
    return "R" . calcBuildNum;
}


1;
__END__

=head1 NAME

Maplat::Helpers::BuildNum - get the build number of the application

=head1 SYNOPSIS

  use Maplat::Helpers::BuildNum;
  
  my $buildnum = readBuildNum();

  my $buildnum = readBuildNum("buildnum", 1); # when running compiled

  my $buildnum = calcBuildNum();

=head1 DESCRIPTION

This module is used in conjunction with compiled perl scripts (e.g.
when compiled with ActiveState tools or similar).

It's very usefull when upgrading a server to know the build numbers (see below)
of a compiled perl program. When used in a scripted environment, the build number
is generated on the fly.

=head2 calcbuildNum

Calculates a build number, consisting of the build date and the hostname of the
computer used.

=head2 readBuildNum

Returns the build number.

The build number consists of the form

  Xdate_hostname

Where date is the build date and time (or date/time of the first call to the function
when running non-compiled), hostname the hostname of the computer the binary was build.

"X" is either one of R ("runtime", interpreted script), C (compiled) or "G" (compiled script
but unable to read the compiled-in build number, so build-number is generated at runtime).

The function takes two optional arguments, $filename and $iscompiled:

  my $buildnum = readBuildNum("buildnum", 1);

This is used when compiled with the ActiveState PDK and must be set depending on your
development environment. The $filename is the name of the bound file, consisting of one line,
the build number.

=head2 calcBuildNum

Calculates a build number, see "Adding an automatic build number to your program"

=head1 Adding an automatic build number to your program

To work correctly, building should be done with a perl script, something like this:

  use Maplat::Helpers::BuildNum;
  ...
  my $cmd = "perlapp " .
            " --icon " . $opts{icon} .
            " --norunlib " .
            " --nocompress " .
            " --nologo " .
            " --manifest " . $opts{mf} .
            " --clean " .
            " --trim " . join(";", @trimmodules) . " " .
            " --force " .
            " --bind buildnum[data=" . calcBuildNum . "] " .
            " --exe " . $opts{exe} .
            " " . $opts{main};
  `$cmd`;

Then, at runtime, you can get the current build number:

  use Maplat::Helpers::BuildNum;
  
  our $isCompiled = 0;
  if(defined($PerlApp::VERSION)) {
    $isCompiled = 1;
  }
  my $buildnum = readBuildNum("buildnum", $isCompiled);

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
