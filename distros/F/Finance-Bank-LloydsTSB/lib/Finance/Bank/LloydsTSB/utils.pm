package Finance::Bank::LloydsTSB::utils;

=head1 NAME

Finance::Bank::LloydsTSB::utils - internal utility routines

=cut

use strict;
use warnings;

our $VERSION = '1.35';

use base 'Exporter';
our @EXPORT_OK = qw(trim debug);

sub trim {
    my $class = shift;
    my ($text) = @_;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}

sub debug {
    my $class = shift;
    my $varname = (ref($class) || $class) . "::DEBUG";
    no strict 'refs';
    warn @_ if $$varname;
}

1;
