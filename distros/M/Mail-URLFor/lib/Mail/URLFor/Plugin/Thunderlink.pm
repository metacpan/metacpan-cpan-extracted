package Mail::URLFor::Plugin::Thunderlink;
use Moo 2;

our $VERSION = '0.03';

=head1 NAME

Mail::URLFor::Plugin::Thunderlink - deep links to mails on Thunderbird

=head1 SYNOPSIS

    my $r = Mail::URLFor::Plugin::Thunderlink->new();
    my $url = $r->render('123456-abcdef-ghijkl@example.com');
    print "<a href=\"$url\">See mail</a>";

=cut

has 'template' => (
    is => 'ro',
    default => 'thunderlink://messageid=%s',
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

=head1 Installing Thunderlink for Thunderbird

Install the "Thunderlink" plug-in / add-on for Thunderbird and
register the C<thunderlink://> URI. This allows your browser to directly
display emails in Thunderbird.

L<https://addons.thunderbird.net/de/thunderbird/addon/thunderlink/>

Current Thunderlink maintainer:

L<https://github.com/mikehardy/thunderlink>

=head2 Windows installation

In addition to installing Thunderlink, you need to make the C<thunderlink://>
protocol known to Windows by making the following registry associations:

    REGEDIT4

    [HKEY_CLASSES_ROOT\thunderlink]
    @="URL:thunderlink Protocol"
    "URL Protocol"=""

    [HKEY_CLASSES_ROOT\thunderlink\shell]

    [HKEY_CLASSES_ROOT\thunderlink\shell\open]

    [HKEY_CLASSES_ROOT\thunderlink\shell\open\command]
    @="\"C:\\Program Files (x86)\\Mozilla Thunderbird\\thunderbird.exe\" -thunderlink \"%1\""

Alternatively, save the above lines into a C<.reg> file and execute that.

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
