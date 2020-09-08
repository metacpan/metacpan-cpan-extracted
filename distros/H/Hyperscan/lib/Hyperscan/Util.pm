package Hyperscan::Util;
$Hyperscan::Util::VERSION = '0.04';
# ABSTRACT: utility functions for other Hyperscan modules

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(re_flags_to_hs_flags);

use Carp;

use Hyperscan;

sub re_flags_to_hs_flags {
    my ($flags) = @_;

    my $i = 0;
    foreach my $char ( split //, $flags ) {
        if ( $char eq "i" ) {
            $i |= Hyperscan::HS_FLAG_CASELESS;
        }
        elsif ( $char eq "s" ) {
            $i |= Hyperscan::HS_FLAG_DOTALL;
        }
        elsif ( $char eq "m" ) {
            $i |= Hyperscan::HS_FLAG_MULTILINE;
        }
        elsif ( $char eq "u" ) {
            $i |= Hyperscan::HS_FLAG_UTF8 | Hyperscan::HS_FLAG_UCP;
        }
        else {
            carp "unsupported flag $char on regex";
        }
    }

    return $i;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hyperscan::Util - utility functions for other Hyperscan modules

=head1 VERSION

version 0.04

=head2 FUNCTIONS

=head3 re_flags_to_hs_flags( $flags )

Takes the C<$flags> string and converts it to a int that represents the same
hyperscan flags.

=head1 AUTHOR

Mark Sikora <marknsikora@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Mark Sikora.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
