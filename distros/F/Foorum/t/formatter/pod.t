#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {

    eval { require Pod::Xhtml }
        or plan skip_all => 'Pod::Xhtml is required for this test';

    eval { require IO::String }
        or plan skip_all => 'IO::String is required for this test';

    plan tests => 3;
}

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;

=head1 NAME

Foorum - forum system based on Catalyst

=head1 DESCRIPTION

nothing for now.

=head1 FEATURES

=over 4

=item open source

u can FETCH all code from L<http://fayland.googlecode.com/svn/trunk/Foorum/> any time any where.

=item Win32 compatibility

Linux/Unix/Win32 both OK.

=item templates

use L<Template>; for UI.

=item built-in cache

use L<Cache::Memcached> or use L<Cache::FileCache> or others;

=item Captcha

To keep robot out.

=back

=head1 SEE ALSO

L<Catalyst::Runtime>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

TEXT

my $html = filter_format( $text, { format => 'pod' } );

like( $html, qr/h2/,        '=head1 OK' );
like( $html, qr/dt/,        '=over OK' );
like( $html, qr/\<a href=/, 'L<> OK' );

#diag($html);
