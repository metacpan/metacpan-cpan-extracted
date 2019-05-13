package Mail::URLFor::Plugin::Gmail;
use Moo 2;

our $VERSION = '0.03';

=head1 NAME

Mail::URLFor::Plugin::Gmail - deep links to mails on Gmail

=head1 SYNOPSIS

    my $r = Mail::URLFor::Plugin::Gmail->new();
    my $url = $r->render('123456-abcdef-ghijkl@example.com');
    print "<a href=\"$url\">See mail</a>";

=cut

has 'template' => (
    is => 'ro',
    default => 'https://mail.google.com/mail/#search/rfc822msgid%%3A%s',
);

has 'moniker' => (
    is => 'ro',
    default => sub {
        __PACKAGE__ =~ /.*::(\w+)$/;
        $1
    },
);

with 'Mail::URLFor::Role::Template';

1;

__END__

=head1 SEE ALSO

Gmail advanced search options - L<https://support.google.com/mail/answer/7190?hl=en>

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
