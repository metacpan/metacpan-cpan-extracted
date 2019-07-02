package Lab::Moose::Catfile;
$Lab::Moose::Catfile::VERSION = '3.682';
use warnings;
use strict;

# ABSTRACT: Export custom catfile which avoids backslashes

# PDL::Graphics::Gnuplot <= 2.011 cannot handle backslashes on windows.


our @ISA    = qw(Exporter);
our @EXPORT = qw/our_catfile/;

sub our_catfile {
    if ( @_ == 0 ) {
        return;
    }
    return join( '/', @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Catfile - Export custom catfile which avoids backslashes

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose::Catfile;
 my $dir = our_catfile($dir1, $dir2, $basename);

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
