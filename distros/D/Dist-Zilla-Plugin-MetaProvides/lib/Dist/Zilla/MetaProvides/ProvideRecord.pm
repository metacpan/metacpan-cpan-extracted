use 5.006;
use strict;
use warnings;

package Dist::Zilla::MetaProvides::ProvideRecord;

our $VERSION = '2.002004';

# ABSTRACT: Data Management Record for MetaProvider::Provides Based Class

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has );
use MooseX::Types::Moose qw( Str );
use Dist::Zilla::MetaProvides::Types qw( ModVersion ProviderObject );

use namespace::autoclean;



















has version => ( isa => ModVersion, is => 'ro', required => 1 );








has module => ( isa => Str, is => 'ro', required => 1 );







has file => ( isa => Str, is => 'ro', required => 1 );








has parent => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
  isa      => ProviderObject,
  handles  => [ 'zilla', '_resolve_version', ],
);

__PACKAGE__->meta->make_immutable;
no Moose;


















sub copy_into {
  my $self  = shift;
  my $dlist = shift;
  $dlist->{ $self->module } = {
    file => $self->file,
    $self->_resolve_version( $self->version ),
  };
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MetaProvides::ProvideRecord - Data Management Record for MetaProvider::Provides Based Class

=head1 VERSION

version 2.002004

=head1 PUBLIC METHODS

=head2 copy_into C<( \%provides_list )>

Populate the referenced C<%provides_list> with data from this Provide Record object.

This is called by the  L<Dist::Zilla::Role::MetaProvider::Provider> Role.

This is very convenient if you have an array full of these objects, for you can just do

    my %discovered;
    for ( @array ) {
       $_->copy_into( \%discovered );
    }

and C<%discovered> will be populated with relevant data.

=head1 ATTRIBUTES / PARAMETERS

=head2 version

See L<Dist::Zilla::MetaProvides::Types/ModVersion>

=head2 module

The String Name of a fully qualified module to be reported as
included in the distribution.

=head2 file

The String Name of the file as to be reported in the distribution.

=head2 parent

A L<Dist::Zilla::MetaProvides::Types/ProviderObject>, mostly to get Zilla information
and accessors from L<Dist::Zilla::Role::MetaProvider::Provider>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::MetaProvides::ProvideRecord",
    "interface":"class",
    "inherits":"Moose::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
