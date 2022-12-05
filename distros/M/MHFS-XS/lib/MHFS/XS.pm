package MHFS::XS;

use 5.020002;
use strict;
use warnings;
use version; our $VERSION = version->declare("v0.2.3");

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MHFS::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);



require XSLoader;
XSLoader::load('MHFS::XS', $VERSION);

# Preloaded methods go here.

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MHFS::XS - XS extension module for Media HTTP File Server, for server
side media encoding.

=head1 SYNOPSIS

    use MHFS::XS;
    my $mf = MHFS::XS::new('/path/to/musicfile');
    my $flacBuffer = MHFS::XS::get_flac($mf, 0, 44100);
    my $waveBuffer = MHFS::XS::wavvfs_read_range($mf, 44, 176444);  

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc MHFS::XS

Additional documentation, support, and bug reports can be found at the
MHFS repository L<https://github.com/G4Vi/MHFS>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
