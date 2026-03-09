package IO::K8s::Api::Core::V1::DownwardAPIProjection;
# ABSTRACT: Represents downward API info for projecting into a projected volume. Note that this is identical to a downwardAPI volume source without the default mode.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s items => ['Core::V1::DownwardAPIVolumeFile'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::DownwardAPIProjection - Represents downward API info for projecting into a projected volume. Note that this is identical to a downwardAPI volume source without the default mode.

=head1 VERSION

version 1.008

=head2 items

Items is a list of DownwardAPIVolume file

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
