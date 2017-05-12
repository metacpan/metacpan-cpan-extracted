package HTTP::Easy;

use warnings;
use strict;

=head1 NAME

HTTP::Easy - Useful set for work with HTTP

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use HTTP::Easy::Headers;
    my $h = "Connection: close\015\012".
        "Expect: continue-100\015\012".
        "Content-Type: text/html";

    my $hash = HTTP::Easy::Headers->decode($h);

    $hash->{connection};     # 'close'
    $hash->{expect};         # 'continue-100'
    $hash->{'content-type'}; # 'text/html'
    
    my $hdr = HTTP::Easy::Headers->encode($hash);
    
    use HTTP::Easy::Cookie;
    
    my $cookie_jar = HTTP::Easy::Cookie->decode($hdr->{cookie});
    
    $hdr->{cookie} = HTTP::Easy::Cookie->encode($cookie_jar, host => 'example.net', path => '/path' );
    
=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1;
