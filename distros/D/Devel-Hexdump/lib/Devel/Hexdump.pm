package Devel::Hexdump;

use 5.008008;
use strict;
use warnings;
BEGIN { require Exporter; our @ISA = 'Exporter'; }
our %EXPORT_TAGS = ( 'all' => [ our @EXPORT = our @EXPORT_OK = qw(xd) ]);
our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Devel::Hexdump', $VERSION);

1;
__END__
=head1 NAME

Devel::Hexdump - Print nice hex dump of binary data

=head1 SYNOPSIS

    use Devel::Hexdump 'xd';

    my $binary = '...';
    print xd $binary, {
        row   => 10, # print 10 bytes in a row
        cols  => 2,  # split in 2 column groups, separated with <hsp?>
          hsp => 2,  # add 2 spaces between hex columns
          csp => 1,  # add 1 space between char columns
        hpad  => 1,  # pad each hex byte with 1 space (ex: " 00" )
        cpad  => 1,  # pad each char byte with 1 space
    };
    
    # or just
    print xd $binary;

=head1 AUTHOR

Mons Anderson, E<lt>mons@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Mons Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
