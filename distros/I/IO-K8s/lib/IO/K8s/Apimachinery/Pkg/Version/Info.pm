package IO::K8s::Apimachinery::Pkg::Version::Info;
# ABSTRACT: Info contains versioning information. how we'll want to distribute that information.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s buildDate => Str, 'required';

k8s compiler => Str, 'required';

k8s gitCommit => Str, 'required';

k8s gitTreeState => Str, 'required';

k8s gitVersion => Str, 'required';

k8s goVersion => Str, 'required';

k8s major => Str, 'required';

k8s minor => Str, 'required';

k8s platform => Str, 'required';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Version::Info - Info contains versioning information. how we'll want to distribute that information.

=head1 VERSION

version 1.008

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
