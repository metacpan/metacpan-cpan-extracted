#
# This file is part of Dist-Zilla-PluginBundle-Author-RWSTAUNER
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::MintingProfile::Author::RWSTAUNER;
our $AUTHORITY = 'cpan:RWSTAUNER';
$Dist::Zilla::MintingProfile::Author::RWSTAUNER::VERSION = '6.001';
# ABSTRACT: Mint a new dist for RWSTAUNER

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS RWSTAUNER's PluginBundle

=head1 NAME

Dist::Zilla::MintingProfile::Author::RWSTAUNER - Mint a new dist for RWSTAUNER

=head1 VERSION

version 6.001

=head1 SYNOPSIS

  dzil new -P Author::RWSTAUNER

=head1 DESCRIPTION

Profile for minting a new dist with L<Dist::Zilla>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::App::Command::new>

=item *

L<Dist::Zilla::Role::MintingProfile>

=back

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
