package Language::Prolog::Types::Converter;

our $VERSION='0.02';

use strict;
use warnings;

use Carp;
use Language::Prolog::Types qw(F A L prolog_opaque);

my %conv=( ARRAY => 'array2prolog',
	   HASH => 'hash2prolog',
	   SCALAR => 'scalar2prolog',
	   GLOB => 'glob2prolog',
	   CODE => 'code2prolog',
	   '' => 'term2prolog');



sub new {
    my $class=shift;
    my $this={ opaque=>[],
	       cache=>{} };
    bless $this, $class;
    return $this;
}

sub pass_as_opaque {
    my $self=shift;
    push @{$self->{opaque}}, @_;
    $self->{cache}={}
}

sub perl_ref2prolog {
    my ($self, $ref)=@_;
    my $refref=ref $ref;
    my $method=$conv{$refref} || 'object2prolog';
    unless (exists $self->{cache}{$refref}) {
	$self->fill_cache($ref);
    }
    return prolog_opaque($ref)
	if $self->{cache}{$refref};

    my $r=$self->$method($ref);
    # warn ("prolog term: $r\n");
    $r
}

sub fill_cache {
    my ($self, $obj)=@_;
    foreach (@{$self->{opaque}}) {
	if (UNIVERSAL::isa($obj, $_)) {
	    $self->{cache}{ref $obj}=1;
	    return;
	}
    }
    $self->{cache}{ref $obj}=undef;
}

sub term2prolog { A($_[1]) }

sub array2prolog { L(@{$_[1]}) }

sub hash2prolog {
    my $h=$_[1];
    L(map { F('=>', $_, $h->{$_}) } keys %{$h}) }

sub scalar2prolog { F("\\", $ {$_[1]}) }

sub glob2prolog { A($ {$_[1]}) }

sub code2prolog { A($_[1]) }

sub object2prolog {
    my ($class, $obj)=@_;
    UNIVERSAL::can($obj, "convert2prolog_term") and
	return $obj->convert2prolog_term;

    UNIVERSAL::isa($obj, 'ARRAY') and
	return F('perl_object', ref($obj), L(@{$obj}));

    UNIVERSAL::isa($obj, 'HASH') and
	return F('perl_object', ref($obj), $class->hash2prolog($obj));

    UNIVERSAL::isa($obj, 'SCALAR') and
	return F('perl_object', ref($obj), $class->scalar2prolog($obj));

    UNIVERSAL::isa($obj, 'GLOB') and
	return F('perl_object', ref($obj), $class->glob2prolog($obj));

    UNIVERSAL::isa($obj, 'CODE') and
        return F('perl_object', ref($obj), $class->code2prolog($obj));

    croak "unable to convert reference '".ref($obj)."' to prolog term";
}

__END__

=head1 NAME

Language::Prolog::Types::Converter - Converts from Perl objects to Prolog terms

=head1 SYNOPSIS

  package MyModule;

  use Language::Prolog::Types::Converter;
  our @ISA=qw(Language::Prolog::Types::Converter);

  sub hash2prolog {
      ...
  }

  sub scalar2prolog {
      ...
  }

  etc.

=head1 ABSTRACT

This module implements a class to be used from interfaces to Prolog
systems (SWI-Prolog, XSB, etc.) to transform complex Perl data types
to Prolog types.


=head1 DESCRIPTION

You should use this module if you want to change the default
conversions performed when passing data between Perl and Prolog.

=head2 METHODS

=over 4

=item C<Language::Prolog::Types::Converter->E<gt>new()>

returns a new converter object.

=item C<$self-E<gt>pass_as_opaque($class1, $class2, ...)>

instruct the converter object to pass objects belonging to classes
class1, class2, etc. to Prolog as opaque objects. The Prolog
interpreter will not touch them but just use them in Perl call backs.

=back

To override the default conversions performed, you have to redefine
the method C<perl_ref2prolog>.

If you make your converter class inherit
L<Language::Prolog::Types::Converter>, you can change conversions only
for selected types overriding those methods:

=over 4

=item C<$conv-E<gt>hash2prolog($hash_ref)>

converts a Perl hash reference to a Prolog term.

It creates a list of functors '=>/2' with the key/value pairs as
arguments:

  [ '=>'(key0, value0), '=>'(key1, value1), ... ]


=item C<$conv-E<gt>scalar2prolog($scalar_ref)>

converts a Perl scalar reference to a Prolog term.

=item C<$conv-E<gt>glob2prolog($glob_ref)>

converts a Perl glob reference to a Prolog term.

=item C<$conv-E<gt>code2prolog($code_ref)>

converts a Perl sub reference to a Prolog term.

=item C<$conv-E<gt>object2prolog($object_ref)>

converts any other Perl object to a Prolog term.

Default implementation looks for a method called
C<convert2prolog_term> in the object class.

If this fails, it reverts to dump the internal representation of the
object as the functor:

  perl_object(class, state)

C<state> is the conversion of the perl datatype used to represent the
object (array, hash, scalar, glob or sub).

=back


=head2 EXPORT

None by default. This module has an OO interface.



=head1 SEE ALSO

L<Language::Prolog::Types>, L<Language::XSB::Base>,
L<Language::Prolog::Yaswi::Low>.

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
