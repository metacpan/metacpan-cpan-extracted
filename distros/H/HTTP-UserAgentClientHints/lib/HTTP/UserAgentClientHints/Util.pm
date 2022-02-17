package
    HTTP::UserAgentClientHints::Util;
use strict;
use warnings;

sub strip_quote {
    my ($self, $value) = @_;

    return '' unless defined $value;

    $value =~ s/^"//;
    $value =~ s/"$//;

    return $value;
}

1;

__END__

=encoding UTF-8

=head1 NAME

HTTP::UserAgentClientHints::Util - The utility for HTTP::UserAgentClientHints


=head1 METHODS

=head2 strip_quote($string)

=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<HTTP::UserAgentClientHints::Util> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
