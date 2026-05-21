package iabtcfv2 0.520;

use v5.12;
use warnings;

use GDPR::IAB::TCFv2::Parser;
use GDPR::IAB::TCFv2::Validator;

use Exporter qw(import);

our @EXPORT = qw(tcf validator);

sub tcf       { GDPR::IAB::TCFv2::Parser->Parse(@_) }
sub validator { GDPR::IAB::TCFv2::Validator->new(@_) }

1;
__END__

=pod

=encoding utf8

=head1 NAME

iabtcfv2 - Pure-exporter short alias for one-liner and shell use

=head1 SYNOPSIS

    use iabtcfv2;
    my $tc_string = 'CLc...';
    my $c = tcf($tc_string);
    my $v = validator(vendor_id => 284);

    # From the shell:
    # perl -Miabtcfv2 -E 'say tcf(shift)->cmp_id' "CLc..."

=head1 DESCRIPTION

This module is a thin wrapper around L<GDPR::IAB::TCFv2::Parser> and
L<GDPR::IAB::TCFv2::Validator>. It exports two functions by default to
reduce boilerplate in one-liners and short scripts.

=head1 FUNCTIONS

=head2 tcf($tc_string, %opts)

Alias for L<GDPR::IAB::TCFv2::Parser-E<gt>Parse>. Returns a
L<GDPR::IAB::TCFv2::Parser> object.

=head2 validator(%opts)

Alias for L<GDPR::IAB::TCFv2::Validator-E<gt>new>. Returns a
L<GDPR::IAB::TCFv2::Validator> object.

=head1 SEE ALSO

L<GDPR::IAB::TCFv2>

=cut
