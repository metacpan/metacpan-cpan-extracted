package Mail::URLFor::Plugin::OSX;
use Moo 2;

our $VERSION = '0.03';

=head1 NAME

Mail::URLFor::Plugin::OSX - deep links to mails on OSX Mail.app

=head1 SYNOPSIS

    my $r = Mail::URLFor::Plugin::OSX->new();
    my $url = $r->render('123456-abcdef-ghijkl@example.com');
    print "<a href=\"$url\">See mail</a>";

=cut

has 'template' => (
    is => 'ro',
    default => 'message:%%3C%s%%3E',
);

has 'moniker' => (
    is => 'ro',
    default => sub {
        __PACKAGE__ =~ /.*::(\w+)$/;
        $1
    },
);

with 'Mail::URLFor::Role::Template';

around 'munge_messageid' => sub { $_[2] };

1;

__END__

=head1 SEE ALSO

L<https://apple.stackexchange.com/questions/300437/is-it-possible-to-deep-link-to-a-specific-email-in-mail-app-on-mac-os-x>


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
