use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile;
use Moo;

use Types::Standard qw/Str InstanceOf/;

# ABSTRACT: Java .class parsing

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

has filename => ( is => 'ro', isa => Str, required => 1);
has ast      => ( is => 'ro', isa => InstanceOf['MarpaX::Java::ClassFile::Struct::ClassFile'], lazy => 1, builder => 1);


use Carp qw/croak/;
require MarpaX::Java::ClassFile::BNF::ClassFile;
require MarpaX::Java::ClassFile::Struct::ClassFile;

sub _build_ast {
  my ($self) = @_;

  $self->log->tracef('Opening %s', $self->filename);
  open(my $fh, '<', $self->filename) || do {
    $self->log->fatalf('Cannot open %s, %s', $self->filename, $!);
    croak "Cannot open " . $self->filename . ", $!"
  };

  $self->log->tracef('Setting %s in binary mode', $self->filename);
  binmode($fh) || do {
    $self->log->fatalf('Failed to set binary mode on %s, %s', $self->filename, $!);
    croak "Failed to set binary mode on " . $self->filename . ", $!"
  };

  $self->log->tracef('Reading %s', $self->filename);
  my $input = do { local $/; <$fh>};

  $self->log->tracef('Closing %s', $self->filename);
  close($fh) || do {
    $self->log->warnf('Failed to close %s, %s', $self->filename, $!);
    croak "Failed to close " . $self->filename . ", $!"
  };

  $self->log->debugf('Parsing %s', $self->filename);
  MarpaX::Java::ClassFile::BNF::ClassFile->new(inputRef => \$input, log => $self->log)->ast
}

with 'MooX::Log::Any';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile - Java .class parsing

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use MarpaX::Java::ClassFile;

    my $classFilename = shift || 'defaultFilename.class';
    my $o = MarpaX::Java::ClassFile->new(filename => $classFilename);
    my $ast = $o->ast;
    print "Javap-like output is using overloaded stringification: $ast\n";

=head1 DESCRIPTION

This module provide and manage an AST of an Java .class file, as per Java Virtual Machine Specification SE 8 Edition.

=head1 SUBROUTINES/METHODS

=head2 new($class, %options --> InstanceOf['MarpaX::Java::ClassFile'])

Instantiate a new object, named $self later in this document. Takes as parameter a hash of options that can be:

=over

=item Str filename

Location of the .class file on your filesystem. This option is required.

=back

=head2 ast($self --> InstanceOf['MarpaX::Java::ClassFile::Struct::ClassFile'])

Returns the parse result, as an instance of L<MarpaX::Java::ClassFile::Struct::ClassFile>.

=head1 SEE ALSO

L<Marpa::R2>

L<The Java Virtual Machine Specification, Java SE 8 Edition, Chapter 4: The class File Format|https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
