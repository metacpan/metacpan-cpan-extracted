package Mail::URLFor::Plugin::RFC2392;
use strict;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use URI;
use URI::mid;

=head1 NAME

Mail::URLFor::Plugin::RFC2392 - deep links to mails for RFC2392

=head1 SYNOPSIS

    my $r = Mail::URLFor::Plugin::RFC2392->new();
    my $url = $r->render('123456-abcdef-ghijkl@example.com');
    print "<a href=\"$url\">See mail</a>";

=cut

our $VERSION = '0.03';

sub render($self, $rfc882messageid ) {
    return URI->new( $rfc882messageid, 'mid:' )
}

has 'moniker' => (
    is => 'ro',
    default => sub {
        __PACKAGE__ =~ /.*::(\w+)$/;
        $1
    },
);

1;

__END__

=head1 SEE ALSO

RFC2392 Content-ID and Message-ID Uniform Resource Locators

L<https://tools.ietf.org/html/rfc2392>

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/Mail::URLFor>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-URLFor>
or via mail to L<mail-urlfor-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
