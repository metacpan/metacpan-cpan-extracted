package MDOM::Util;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(
    trim_tokens
);

sub trim_tokens ($) {
    my $tokens = shift;
    return if !@$tokens;
    if ($tokens->[0] =~ /^\s+$/) {
        shift @$tokens;
    }
    return if !@$tokens;
    if ($tokens->[-1] =~ /^\s+$/) {
        pop @$tokens;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

MDOM::Util - Utilities methods for Makefile::DOM

=head1 DESCRIPTION

Includes auxiliary methods.

=head2 trim_tokens

Remove space tokens from the beginning or the end of a list reference.

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006-2014 by Yichun "agentzh" Zhang (章亦春).

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MDOM::Document>, L<MDOM::Document::Gmake>, L<PPI>, L<Makefile::Parser::GmakeDB>, L<makesimple>.

