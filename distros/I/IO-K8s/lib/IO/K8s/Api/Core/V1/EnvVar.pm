package IO::K8s::Api::Core::V1::EnvVar;
# ABSTRACT: EnvVar represents an environment variable present in a Container.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s value => Str;


k8s valueFrom => 'Core::V1::EnvVarSource';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::EnvVar - EnvVar represents an environment variable present in a Container.

=head1 VERSION

version 1.100

=head2 name

Name of the environment variable. Must be a C_IDENTIFIER.

=head2 value

Variable references $(VAR_NAME) are expanded using the previously defined environment variables in the container and any service environment variables. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. "$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)". Escaped references will never be expanded, regardless of whether the variable exists or not. Defaults to "".

=head2 valueFrom

Source for the environment variable's value. Cannot be used if value is not empty.

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
