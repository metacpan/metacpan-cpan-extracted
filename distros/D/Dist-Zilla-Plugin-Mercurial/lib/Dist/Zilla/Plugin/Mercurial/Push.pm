package Dist::Zilla::Plugin::Mercurial::Push;
$Dist::Zilla::Plugin::Mercurial::Push::VERSION = '0.08';
use strict;
use warnings;
use autodie qw( :all );

use Moose;

with 'Dist::Zilla::Role::AfterRelease';

sub after_release {
    my $self = shift;

    system( 'hg push' );
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Push the current Mercurial branch

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Mercurial::Push - Push the current Mercurial branch

=head1 VERSION

version 0.08

=head1 SYNOPSIS

In your F<dist.ini>:

  [Mercurial::Push]

=head1 DESCRIPTION

Once the release is done, this plugin will push current Mercurial branch.

=for Pod::Coverage after_release

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
