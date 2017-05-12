package Magpie::Machine;
$Magpie::Machine::VERSION = '1.163200';
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
use Magpie::Resource::Abstract;
use Magpie::Util;

#ABSTRACT: Event Class For Creating Magpie Pipelines

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject',
    #coerce      => 1,
);

#sub has_resource { defined shift->resource ? 1 : 0 }


#-------------------------------------------------------------------------------
# pipline( @list_of_class_names )
# This loads the list of Event classes that will constitue the app's
# program flow.
#-------------------------------------------------------------------------------
sub pipeline {
    my $self    = shift;
    my @args = @_;
    my @handlers = Magpie::Util::make_tuples( @args );
    $self->handlers(\@handlers);
}

# SEEALSO: Magpie

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Machine - Event Class For Creating Magpie Pipelines

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
