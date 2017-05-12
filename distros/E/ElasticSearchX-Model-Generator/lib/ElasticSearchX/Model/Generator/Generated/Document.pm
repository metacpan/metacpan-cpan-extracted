use strict;
use warnings;

package ElasticSearchX::Model::Generator::Generated::Document;
BEGIN {
  $ElasticSearchX::Model::Generator::Generated::Document::AUTHORITY = 'cpan:KENTNL';
}
{
  $ElasticSearchX::Model::Generator::Generated::Document::VERSION = '0.1.8';
}

# ABSTRACT: A Generated C<ESX> Document Model.

use Moo;
use Path::Tiny ();
use MooseX::Has::Sugar qw( rw required );


has 'package' => rw, required;
has 'path'    => rw, required;
has 'content' => rw, required;


sub write {
  my ( $self, %args ) = @_;
  my $file = Path::Tiny::path( $self->path );
  $file->parent->mkpath;
  $file->openw->print( $self->content );
  return;
}


sub evaluate {
  my ( $self, %args ) = @_;
  require Module::Runtime;
  my $mn = Module::Runtime::module_notional_filename( $self->package );
  ## no critic (RequireLocalizedPunctuationVars)
  $INC{$mn} = 1;
  local ( $@, $! ) = ();
  ## no critic ( ProhibitStringyEval )
  if ( not eval $self->content ) {
    require Carp;
    Carp::croak( sprintf 'content for %s did not load: %s %s', $self->package, $@, $! );
  }
  ## no critic ( RequireCarping )
  die $@ if $@;
  return;
}
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Generator::Generated::Document - A Generated C<ESX> Document Model.

=head1 VERSION

version 0.1.8

=head1 METHODS

=head2 write

  $document->write();
  # $document->path is filled with $document->content

=head2 evaluate

  $document->evaluate();
  my $instance = $document->package->new(
    # magical =D
  );

=head1 ATTRIBUTES

=head2 package

  rw, required

=head2 path

  rw, required

=head2 content

  rw, required

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
