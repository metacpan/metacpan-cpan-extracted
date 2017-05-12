package Dispatch::Profile::Dispatcher;
#-------------------------------------------------------------------------------
#   Module  : Dispatch::Profile::Dispatcher
#
#   Purpose : Dispatcher component
#-------------------------------------------------------------------------------
use Moose;
use Moose::Exporter;
Moose::Exporter->setup_import_methods( as_is => ['dispatch'] );
our $VERSION = '0.002';

#-------------------------------------------------------------------------------
#   Subroutine : dispatch
#
#   Purpose    : dispatch target
#-------------------------------------------------------------------------------
sub dispatch {
   my $self = shift;

   #-------------------------------------------------------------------------------
   #   Process _store
   #-------------------------------------------------------------------------------
   if ( defined $self->{_store} ) {
      for my $coderef ( @{ $self->{_store} } ) {
         &{ $coderef }( @_ );
      }
   }
};

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Dispatch::Profile sequential dispatcher

__END__

=pod

=encoding UTF-8

=head1 NAME

Dispatch::Profile::Dispatcher - Dispatch::Profile sequential dispatcher

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Provides a sequential dispatch method for the Dispatch::Profile package.

=head1 METHODS

=head2 dispatch

Sequentially processes the receieved payload against each coderef stored in
@{ $self->{_store} }

=head1 AUTHOR

James Spurin <james@spurin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by James Spurin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
