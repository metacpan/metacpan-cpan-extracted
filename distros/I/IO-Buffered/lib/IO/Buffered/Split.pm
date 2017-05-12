package IO::Buffered::Split; 
use strict;
use warnings;
use Carp;

use base ("IO::Buffered");

use IO::Buffered::Regexp;

# FIXME: Write documentation

our $VERSION = '1.00';

=head1 NAME

IO::Buffered::Split - Split based buffering

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT_OK = qw();

=item new()

=cut

sub new {
    my ($class, $regexp, %opts) = @_;
    
    # Check that $regexp is a Regexp or a non empty string
    croak "Split should be a string or regexp" if !(defined $regexp and 
            (ref $regexp eq 'Regexp' or (ref $regexp eq '' and $regexp ne '')));
    
    return new IO::Buffered::Regexp(qr/(.*?)$regexp/, %opts, ReturnsLast => 0); 
}

=back

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2008 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

