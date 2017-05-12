package FurlX::Coro;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '1.02';

use parent qw(Furl);
use Furl::HTTP;
use FurlX::Coro::HTTP;

sub new {
    my $class = shift;
    my $ua    = FurlX::Coro::HTTP->new(
        header_format => Furl::HTTP::HEADERS_AS_HASHREF(),
        @_);
    return bless \$ua, $class;
}

1;
__END__

=head1 NAME

FurlX::Coro - Multiple HTTP requests with Coro

=head1 VERSION

This document describes FurlX::Coro version 1.02.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Coro;
    use FurlX::Coro;

    my @coros;
    foreach my $url(@ARGV) {
        push @coros, async {
            print "fetching $url\n";
            my $ua  = FurlX::Coro->new();
            $ua->env_proxy();
            my $res = $ua->head($url);
            printf "%s: %s\n", $url, $res->status_line();
        }
    }

    $_->join for @coros;

=head1 DESCRIPTION

This is a wrapper to C<Furl> for asynchronous HTTP requests with C<Coro>.

=head1 INTERFACE

Interface is the same as C<Furl>.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Furl>

L<Coro>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
