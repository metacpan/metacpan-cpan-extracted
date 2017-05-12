# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::Logo;
use strict;
use warnings;

use 5.008000;

use base qw(Exporter);
our @EXPORT= qw(MaplatLogo); ## no critic (Modules::ProhibitAutomaticExportation)

our $VERSION = 0.995;

my @lines;

sub MaplatLogo {
        my ($appname, $version) = @_;
    
    # Only on first call, read in DATA segment
    if(!defined($lines[1])) {
        @lines = <DATA>;
    }
    
    my @xlines = @lines; # Do NOT work on original data set
    foreach my $line (@xlines) {
        $line =~ s/APPNAME/$appname/g;
        $line =~ s/VERSION/$version/g;
        print $line;
    }
    print "\n";
    sleep(1); # Workaround: Serialize possible error output in Kommodo
    return 1;
}

1;

=head1 NAME

Maplat::Helpers::Logo - print the Maplat logo as ASCII Art

=head1 SYNOPSIS

  use Maplat::Helpers::Logo;
  
  MaplatLogo($appname, $version);

=head1 DESCRIPTION

This Module provides an easy way to print out the Maplat Logo as ASCII art,

=head2 MaplatLogo

Takes two arguments, $appname and $version. $appname should be the application name or
in the case where one executable functions as different programs depending on its
configuration - like the maplat worker - the configured application identification.
$version should be the version of the binary or possibly the build number.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__

    _/      _/    _/_/    _/_/_/    _/          _/_/    _/_/_/_/_/
   _/_/  _/_/  _/    _/  _/    _/  _/        _/    _/      _/
  _/  _/  _/  _/_/_/_/  _/_/_/    _/        _/_/_/_/      _/
 _/      _/  _/    _/  _/        _/        _/    _/      _/
_/      _/  _/    _/  _/        _/_/_/_/  _/    _/      _/

Application: APPNAME
Version: VERSION

This application is part of the MAPLAT Framework, developed
under the Artistic license
*******************************************************************
