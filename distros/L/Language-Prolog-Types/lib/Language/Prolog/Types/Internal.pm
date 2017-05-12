package Language::Prolog::Types::Internal;

our $VERSION=0.09;

use strict;
use warnings;

use Carp;

# factory class methods:

sub new_factory {
    my $class=shift;
    my $self= \ "I'm a $class prolog factory";
    bless $self, $class;
    $self
}

sub new_nil {
    shift;
    Language::Prolog::Types::Internal::nil->new(@_)
}

sub new_list {
    shift;
    Language::Prolog::Types::Internal::list->new(@_)
}

sub new_ulist {
    shift;
    Language::Prolog::Types::Internal::ulist->new(@_)
}

sub new_functor {
    shift;
    Language::Prolog::Types::Internal::functor->new(@_)
}

sub new_variable {
    shift;
    Language::Prolog::Types::Internal::variable->new(@_)
}

sub new_opaque {
    shift;
    Language::Prolog::Types::Internal::opaque->new(@_)
}

# internal types implementation:

package Language::Prolog::Types::Internal::nil;
our @ISA=qw(Language::Prolog::Types::Nil);

use Carp;
use Language::Prolog::Types::Factory;

sub largs { () }
sub larg { croak "larg index $_[1] is out of range" }
sub length { 0 }
sub tail { prolog_nil }

sub new {
    my $class=shift;
    my $self=[];
    bless $self, $class;
    return $self;
}


package Language::Prolog::Types::Internal::functor;
our @ISA=qw(Language::Prolog::Types::Functor);

use Carp;
use Language::Prolog::Types::Factory;

sub fargs {
    my $self=shift;
    return @{$self}[1..(@$self-1)]
}

sub farg {
    my ($self, $index)=@_;
    $index=@$self-1+$index
	if $index<0;
    croak sprintf( "farg index %d out of range for %s/%d",
		   $index, $self->[0], @$self-1 )
	if $index > @$self-2;
    $self->[$index+1];
}

sub functor { $_[0]->[0] }

sub arity { @{$_[0]} - 1 }

sub new {
    my $class=shift;
    my $self=[@_];
    bless $self, $class;
    return $self;
}


package Language::Prolog::Types::Internal::list;
our @ISA=qw( Language::Prolog::Types::List);

use Carp;
use Language::Prolog::Types::Factory;

sub car {
    my $self=shift;
    return undef if $self->is_nil;
    $_[0]->[0];
}

sub cdr {
    my $self=shift;
    return prolog_nil if @$self<2;
    my $cdr=[ @{$self} ];
    shift @{$cdr};
    bless $cdr, ref $self;
    return $cdr;
}

sub car_cdr {
    my $self=shift;
    return prolog_nil if @$self<2;
    my $cdr=[ @{$self} ];
    my $car=shift @{$cdr};
    bless $cdr, ref $self;
    return $car, $cdr;
}

sub new {
    my $class=shift;
    my $self=[@_];
    bless $self, $class;
    return $self;
}

sub larg {
    my ($self, $index)=@_;
    $index=@{$self}+$index
	if $index<0;
    croak "larg index $index is out of range"
	if $index >= @{$self};
    $self->[$index];
}

sub largs { @{$_[0]} }

sub length { scalar @{$_[0]} }

sub tail { prolog_nil }

package Language::Prolog::Types::Internal::ulist;
our @ISA=qw(Language::Prolog::Types::UList);

use Carp;
use Language::Prolog::Types::Factory;

sub car { $_[0]->[0] }

sub cdr {
    my $self=shift;
    return prolog_ulist(@{$self}[1..@$self-1])
}

sub car_cdr {
    my $self=shift;
    return ($self->[0], prolog_ulist(@{$self}[1..@$self-1]))
}

sub new {
    my $class=shift;
    my $self=[@_];
    bless $self, $class;
    return $self;
}

sub largs { @{$_[0]}[0..@{$_[0]}-2] }

sub larg {
    my ($self, $index)=@_;
    $index=@{$self}-1+$index
	if $index<0;
    croak "larg index $index is out of range"
	if $index >= @{$self}-1;
    $self->[$index];
}

sub tail { $_[0]->[-1] };

sub length { @{$_[0]} - 1 }

package Language::Prolog::Types::Internal::variable;
our @ISA=qw(Language::Prolog::Types::Variable);

sub new {
    my ($class, $name)=@_;
    my $self=\$name;
    bless $self, $class;
    return $self;
}

sub name { $ {$_[0]} }

sub rename { ${$_[0]}=$_[1] }


package Language::Prolog::Types::Internal::opaque;
our @ISA=qw(Language::Prolog::Types::Opaque);

sub new {
    my ($class, $ref)=@_;
    my $self=\$ref;
    bless $self, $class;
    return $self
}

sub opaque_reference {
    my $self=shift;
    return $$self;
}

sub opaque_class { ref shift->opaque_reference }


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Language::Prolog::Types::Internal - Prolog terms implementation

=head1 SYNOPSIS

  use Language::Prolog::Types::Internal;
  
  $fty=Language::Prolog::Types::Internal->new_factory;

  $nil=$fty->new_nil
  $functor=$fty->new_functor(qw(foo, bar))

=head1 ABSTRACT

This class presents an implementation for the abstract classes defined
in L<Language::Prolog::Types::Abstract>.

They are accesible through a factory object.



=head1 DESCRIPTION

This class is intended to not be directly used but through the
L<Language::Prolog::Types> and L<Language::Prolog::Types::Factory>
modules.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Language::Prolog::Types::Abstract>, L<Language::Prolog::Types> and
L<Language::Prolog::Types::Factory>.

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Salvador Fandiño.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
