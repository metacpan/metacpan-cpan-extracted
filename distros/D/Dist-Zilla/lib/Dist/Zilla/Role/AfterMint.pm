package Dist::Zilla::Role::AfterMint 6.033;
# ABSTRACT: something that runs after minting is mostly complete

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role have their C<after_mint> method called once all
#pod the files have been written out.  It is passed a hashref with the following
#pod data:
#pod
#pod   mint_root - the directory in which the dist was minted
#pod
#pod =cut

requires 'after_mint';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::AfterMint - something that runs after minting is mostly complete

=head1 VERSION

version 6.033

=head1 DESCRIPTION

Plugins implementing this role have their C<after_mint> method called once all
the files have been written out.  It is passed a hashref with the following
data:

  mint_root - the directory in which the dist was minted

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

This software is copyright (c) 2025 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
