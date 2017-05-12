use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Util::EmulatePhase::PrereqCollector;

our $VERSION = '1.001002';

#ABSTRACT: A dummy Dist::Zilla to fake a 'prereq' object on.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has );
use namespace::autoclean;
use Dist::Zilla::Prereqs;













has shadow_zilla => (
  is       => 'ro',
  isa      => 'Ref',
  required => 1,
);

has prereqs => (
  is       => 'ro',
  isa      => 'Dist::Zilla::Prereqs',
  init_arg => undef,
  default  => sub { Dist::Zilla::Prereqs->new },
  handles  => [qw( register_prereqs )],
);

## no critic ( Subroutines::RequireArgUnpacking )







sub find_files {
  return shift->shadow_zilla->find_files(@_);
}





sub plugins {
  return [];
}
## no critic ( Subroutines::RequireArgUnpacking, Subroutines::ProhibitUnusedPrivateSubroutines, Subroutines::ProtectPrivateSubs )










my $white_list = [
  [ 'Dist::Zilla::Plugin::MakeMaker',          'Dist::Zilla::Plugin::MakeMaker::register_prereqs' ],
  [ 'Dist::Zilla::Plugin::MakeMaker::Awesome', 'Dist::Zilla::Plugin::MakeMaker::Awesome::register_prereqs' ],
];

sub _is_white_listed {
  my ( undef, $package, $subroutine ) = @_;
  for my $list_rule ( @{$white_list} ) {
    next unless $package->isa( $list_rule->[0] );
    next unless $subroutine eq $list_rule->[1];
    return 1;
  }
  return;
}

sub _share_dir_map {
  my $self    = shift;
  my $package = [ caller 0 ]->[0];
  ## no critic (ProhibitMagicNumbers)
  my $subroutine = [ caller 1 ]->[3];

  if ( $self->_is_white_listed( $package, $subroutine ) ) {
    return $self->shadow_zilla->_share_dir_map(@_);
  }

  my $message = <<'_MSG_';
[Dist::Zilla::Util::EmulatePhase] Call to self->zilla->_share_dir_map should be avoided
 ... and your package/sub ( %s::%s ) is not listed in the WhiteList.
 ... Please try eliminate this call to a private method or request it being whitelisted
_MSG_

  require Carp;
  Carp::croak( sprintf $message, $package, $subroutine );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::EmulatePhase::PrereqCollector - A dummy Dist::Zilla to fake a 'prereq' object on.

=head1 VERSION

version 1.001002

=head1 METHODS

=head2 find_files

L<< C<Dist::Zilla>'s C<find_files>|Dist::Zilla/find_files >> proxy.

=head2 plugins

=head2 _share_dir_map

L<< C<Dist::Zilla>'s C<_share_dir_map>|Dist::Zilla/_share_dir_map >> proxy.

B<WARNING>: This method is provided as a temporary workaround and may eventually disappear,
as the behaviour it is wrapping probably shouldn't be done like this.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Util::EmulatePhase::PrereqCollector",
    "interface":"class",
    "inherits":"Moose::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
