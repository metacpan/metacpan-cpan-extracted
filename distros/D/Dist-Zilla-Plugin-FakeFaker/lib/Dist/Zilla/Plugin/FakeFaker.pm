package Dist::Zilla::Plugin::FakeFaker;
BEGIN {
  $Dist::Zilla::Plugin::FakeFaker::VERSION = '0.04';
}

#ABSTRACT: Because sometimes you just have to fake it

use Moose;
extends qw[Dist::Zilla::Plugin::MakeMaker];

sub setup_installer {
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

q[When Harry Met Sally];


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::FakeFaker - Because sometimes you just have to fake it

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # in dist.ini

  [FakeFaker]

=head1 DESCRIPTION

Dist::Zilla::Plugin::FakeFaker is a L<Dist::Zilla> plugin for those situations where one has
already got a C<Makefile.PL> file of one's own that has been lovingly handcrafted to do funky
things and one wishes to C<leverage> the power of L<Dist::Zilla>.

Instead of specifying C<[MakeMaker]> in one's C<dist.ini>, just specify C<[FakeFaker]> and your
C<Makefile.PL> will be used.

=head1 METHODS

=over

=item C<setup_installer>

This is basically a no-op and merely returns without creating a C<Makefile.PL>.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

