package Dist::Zilla::Role::EncodingProvider 6.032;
# ABSTRACT: something that sets a files' encoding

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod EncodingProvider plugins do their work after files are gathered, but before
#pod they're munged.  They're meant to set the C<encoding> on files.
#pod
#pod The method C<set_file_encodings> is called with no arguments.
#pod
#pod =cut

requires 'set_file_encodings';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::EncodingProvider - something that sets a files' encoding

=head1 VERSION

version 6.032

=head1 DESCRIPTION

EncodingProvider plugins do their work after files are gathered, but before
they're munged.  They're meant to set the C<encoding> on files.

The method C<set_file_encodings> is called with no arguments.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
