package Lab::Generic::CLOptions;
$Lab::Generic::CLOptions::VERSION = '3.899';
#ABSTRACT: Global command line option processing

use v5.20;

use Getopt::Long qw/:config pass_through/;

our $DEBUG        = 0;
our $IO_INTERFACE = undef;

GetOptions(
    "debug|d"      => \$DEBUG,
    "terminal|t=s" => \$IO_INTERFACE
) or die "error in CLOptions";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Generic::CLOptions - Global command line option processing (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2014       Andreas K. Huettel
            2015       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
