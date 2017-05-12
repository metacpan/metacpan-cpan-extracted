use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::InnerClassesAttribute;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool attribute_name_index attribute_length number_of_classes classes/],
  '""' => [
           [ sub { 'Classes count'                                 } => sub { $_[0]->number_of_classes } ],
           [ sub { 'Classes'                                       } => sub { $_[0]->arrayStringificator($_[0]->classes) } ]
          ];

# ABSTRACT: InnerClasses_attribute

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2 U4/;
use Types::Standard qw/ArrayRef InstanceOf/;

has _constant_pool         => ( is => 'rw', required => 1, isa => ArrayRef);
has attribute_name_index   => ( is => 'ro', required => 1, isa => U2 );
has attribute_length       => ( is => 'ro', required => 1, isa => U4 );
has number_of_classes      => ( is => 'ro', required => 1, isa => U2 );
has classes                => ( is => 'ro', required => 1, isa => ArrayRef[InstanceOf['MarpaX::Java::ClassFile::Struct::Class']] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::InnerClassesAttribute - InnerClasses_attribute

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
