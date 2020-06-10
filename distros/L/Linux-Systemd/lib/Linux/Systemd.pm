package Linux::Systemd 1.201600;

use v5.16;

# ABSTRACT: Bindings for C<systemd> APIs

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers cpan testmatrix url bugtracker rt cpants kwalitee diff irc
mailto metadata placeholders metacpan

=head1 NAME

Linux::Systemd - Bindings for C<systemd> APIs

=head1 VERSION

version 1.201600

=head1 DESCRIPTION

The following C<systemd> components are wrapped to some to degree.

=head2 Journal

To log to the journal, see L<Linux::Systemd::Journal::Write>.

To read from the journal, see L<Linux::Systemd::Journal::Read>.

=head2 Daemon

To report status and use service watchdogs, see L<Linux::Systemd::Daemon>.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Linux::Systemd

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Linux-Systemd>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at L<https://gitlab.com/ioanrogers/Linux-Systemd/issues>.
You will be automatically notified of any progress on the request by the system.

=head2 Source Code

The source code is available for from the following locations:

L<https://gitlab.com/ioanrogers/Linux-Systemd>

  git clone https://gitlab.com:ioanrogers/Linux-Systemd.git

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ioan Rogers.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
