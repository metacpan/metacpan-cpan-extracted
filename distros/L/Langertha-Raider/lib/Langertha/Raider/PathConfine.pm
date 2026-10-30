package Langertha::Raider::PathConfine;
# ABSTRACT: Internal keeper of the directories the file and search tools may reach
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Cwd qw( realpath );
use Path::Tiny;


has root => ( is => 'ro', isa => 'Maybe[Str]' );


has extra_roots => ( is => 'ro', isa => 'ArrayRef|CodeRef', default => sub { [] } );


has confine => ( is => 'ro', isa => 'Bool|CodeRef', default => 1 );


has dirs_only => ( is => 'ro', isa => 'Bool', default => 0 );


sub confined {
  my ( $self ) = @_;
  my $c = $self->confine;
  return ref $c eq 'CODE' ? ( $c->() ? 1 : 0 ) : ( $c ? 1 : 0 );
}


sub real_extra_roots {
  my ( $self ) = @_;
  my $extra = $self->extra_roots;
  my @extra = ref $extra eq 'CODE' ? $extra->() : @{ $extra };
  @extra = @{ $extra[0] } if @extra == 1 && ref $extra[0] eq 'ARRAY';
  return grep { !$self->dirs_only || -d $_ } grep { defined } map { realpath($_) } grep { defined } @extra;
}


sub allows {
  my ( $self, $real ) = @_;
  return 1 unless defined $self->root && $self->confined;
  my $p = path($real);
  return scalar grep { path($_)->subsumes($p) } $self->root, $self->real_extra_roots;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::PathConfine - Internal keeper of the directories the file and search tools may reach

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $confine = Langertha::Raider::PathConfine->new(
      root        => $real_root,                  # a real absolute directory
      extra_roots => sub { [ '/other/dir' ] },    # list, ArrayRef or CodeRef
      confine     => sub { 1 },                   # value or CodeRef
    );
    die "Path escapes root\n" unless $confine->allows($real_path);

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The one place that says which real paths L<Langertha::Raider::FileTools> and
L<Langertha::Raider::SearchTools> may reach (ADR 0023): the root, the
additional directories (L</extra_roots>) and whether the tools are confined at
all (L</confine>). Both tools used to carry their own copy.

=head2 root

The real absolute path of the root directory. Without one nothing is
confined.

=head2 extra_roots

More directories besides L</root>: an ArrayRef, or a CodeRef returning the
list (or one ArrayRef), asked on every call. One that cannot be resolved
(C<realpath> finds no existing parent) is left out; with L</dirs_only> so is
one that is not a directory.

=head2 confine

True by default. False (or a CodeRef answering false, asked on every call)
lets every path through -- the Claude layout, where the permission gate asks.

=head2 dirs_only

True: an additional directory counts only when it is a directory.

=head2 confined

True when the tools are confined right now.

=head2 real_extra_roots

The additional directories as real absolute paths, read on every call.

=head2 allows

    $confine->allows($real_path);

True when C<$real_path> lies inside the root or an additional directory, or
when nothing confines.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::FileTools>

=item * L<Langertha::Raider::SearchTools>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
