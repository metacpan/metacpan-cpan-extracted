# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::FileSlurp;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(slurpTextFile slurpBinFile);

use Carp;

our $VERSION = 0.995;

sub slurpTextFile {
    my $fname = shift;
    
    # Read in file in binary mode, slurping it into a single scalar.
    # We have to make sure we use binmode *and* turn on the line termination variable completly
    # to work around the multiple idiosynchrasies of Perl on Windows
    open(my $fh, "<", $fname) or croak($!);
    local $/ = undef;
    binmode($fh);
    my $data = <$fh>;
    close($fh);
    
    # Convert line endings to a single format. This certainly is not perfect,
    # but it works in my case. So i don't f...ing care.
    $data =~ s/\015\012/\012/go;
    $data =~ s/\012\015/\012/go;
    $data =~ s/\015/\012/go;

    # Split the lines, which also removes the linebreaks
    my @datalines = split/\012/, $data;
    
    return @datalines;
}

sub slurpBinFile {
    my $fname = shift;
    
    # Read in file in binary mode, slurping it into a single scalar.
    # We have to make sure we use binmode *and* turn on the line termination variable completly
    # to work around the multiple idiosynchrasies of Perl on Windows
    open(my $fh, "<", $fname) or croak($!);
    local $/ = undef;
    binmode($fh);
    my $data = <$fh>;
    close($fh);

    return $data;
}

1;

=head1 NAME

Maplat::Helpers::FileSlurp - read in whole files from filename

=head1 SYNOPSIS

  use Maplat::Helpers::FileSlurp qw(slurpTextFile slurpBinFile);
  
  my @lines = slurpTextFile('HelloWorld.txt');
  my $bindata = slurpBinFile('camel.jpeg');

=head1 DESCRIPTION

This Module provides convinience functions to slurp in files. On text files, it
also tries *very* hard to fix line endings, split the file correctly into lines
and return an array of already chomp()'ed lines.

=head2 slurpTextFile

Takes one argument, the filename. It reads in the file in binary mode, fixes the
line endings, breaks up the file into individual lines and returns an array of
already chomp'ed lines. There might be some special cases where this doesn't work
(most likely in files where multiple empty lines have mixed file endings), but so far
it worked for me.

=head2 slurpBinFile

Takes one argument, the filename. It reads in the file in binary mode and returns
its contents as a single scalar. This function also tries very hard to work on all
operating systems (especially on Windows where there are multiple, differently broken
versions of perl.exe available).

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
