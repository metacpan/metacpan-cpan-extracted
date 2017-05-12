package Marketplace::Rakuten::Utils;

=head1 NAME

Marketplace::Rakuten::Utils

=head1 DESCRIPTION

Common routines for the L<Marketplace::Rakuten> classes.

=head1 EXPORTS

None. You have to call the full name of the functions, e.g.

Marketplace::Rakuten::Utils::turn_empty_hashrefs_into_empty_strings($data)

=head1 FUNCTIONS

=head2 turn_empty_hashrefs_into_empty_strings

The module used for the XML parsing, L<XML::LibXML::Simple>, doesn't
ignore empty tags, but instead return an empty hashref. With this
function (which doesn't recurse for deeper structures), the hashref
passed as argument will be modified to consider and empty hashref as
an empty string.

=cut


sub turn_empty_hashrefs_into_empty_strings {
    my ($hashref) = @_;
    die "Missing argument" unless $hashref;
    die "Argument must be an hashref" unless ref($hashref) eq 'HASH';
    foreach my $k (keys %$hashref) {
        if (my $ref = ref($hashref->{$k})) {
            if ($ref eq 'HASH') {
                if (!%{$hashref->{$k}}) {
                    $hashref->{$k} = '';
                }
            }
        }
    }
}



1;
