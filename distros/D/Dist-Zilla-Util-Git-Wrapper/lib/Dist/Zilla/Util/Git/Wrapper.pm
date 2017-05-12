use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Wrapper;

our $VERSION = '0.004002';

# ABSTRACT: Vivify a Git::Wrapper instance for Dist::Zilla

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY






















use Moose qw( with has );
with 'Dist::Zilla::UtilRole::MaybeZilla';
use Git::Wrapper;

our $AUTOLOAD;

## no critic (ProhibitAutoloading)

sub AUTOLOAD {
  my ( $self, @args ) = @_;
  my $meth = $AUTOLOAD;
  $meth =~ s/.+:://msx;
  return if 'DESTROY' eq $meth;
  return $self->git->$meth(@args);
}














has git => ( isa => 'Object', is => 'ro', lazy_build => 1 );

sub _build_git {
  my ( $self, ) = @_;
  return Git::Wrapper->new( $self->zilla->root );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Wrapper - Vivify a Git::Wrapper instance for Dist::Zilla

=head1 VERSION

version 0.004002

=head1 SYNOPSIS

    use Dist::Zilla::Util::Git::Wrapper;

    my $wrapper =  Dist::Zilla::Util::Git::Wrapper->new( zilla => $self->zilla );

    $wrapper->log(); # etc.

Yes, this does very little, but simply serves as an abstraction for getting a Git::Wrapper
object from git, mostly, because everyone remembers C<< $self->zilla >>, but you have to RTFM
and go source diving to know about C<< $self->zilla->root >>

This is a simple straight forward way of doing what you want with the least mental overhead.

Everything else is just proxy methods for C<< git >>

This is a more I.O.C approach to my swathes of C<< Dist::Zilla::Role::Git::LocalRepository >> stuff,
which got so complex with dependency management my head exploded.

=head1 ATTRIBUTES

=head2 C<zilla>

Parameter lazily required, and should be a Dist::Zilla object ( or compatible )

=head2 C<git>

A Git::Wrapper instance. Optional, and pointless to specify manually,
but could be useful for testing where you don't want Dist::Zilla

Vivified if not specified based on the C<zilla> parameter.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
