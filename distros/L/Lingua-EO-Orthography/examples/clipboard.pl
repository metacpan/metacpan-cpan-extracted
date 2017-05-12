#!perl


# ****************************************************************
# pragma(s)
# ****************************************************************

use 5.008_001;
use strict;
use warnings;
use utf8;


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

use Encode qw(decode_utf8 find_encoding);
use Lingua::EO::Orthography;
use Win32::Clipboard;


# ****************************************************************
# main routine
# ****************************************************************

sub main {
    my $converter = Lingua::EO::Orthography->new;
    my $clipboard = Win32::Clipboard->new;
    my $utf8      = find_encoding('utf8');

    die 'cliped data is not text'
        unless $clipboard->IsText;
    my $text = $clipboard->GetText;

    die 'GAAAAAAAAA, Win32::Clipboard::Set() does not accept UTF-8 string!!';

    $clipboard->Empty;
    $clipboard->Set( $converter->convert( $utf8->encode($text) ) );

    return;
}

main();

__END__

=pod

=head1 NAME

clipboard.pl - An example of converting string in clipboard of Win32

=head1 DESCRIPTION

This is an example of converting string in clipboard of Win32.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This script is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
