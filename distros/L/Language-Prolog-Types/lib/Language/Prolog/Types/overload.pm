package Language::Prolog::Types::overload;

our $VERSION = '0.01';

use strict;
use warnings;

use Language::Prolog::Types;

package Language::Prolog::Types::Nil;
use overload
    '""' => sub {'[]'},
    '0+' => sub { 0 },
    'bool' => sub { 1 },
    'fallback' => 1;


package Language::Prolog::Types::Variable;
use overload
    '""' => sub {
	my $name=$_[0]->name;
	sprintf(($name=~/^[A-Z_]/ ? '%s' : '_%s') , $name)
    },
    '0+'=> sub { undef },
    'bool' => sub { 0 },
    'fallback' => 1 ;


package Language::Prolog::Types::Functor;

sub _escape($) {
    my $n=shift;
    return $n if $n=~/^[a-z][A-Za-z0-9_]*$/;
    return "'$n'"
}

use overload
    '""' => sub {
	my $self=shift;
	_escape($self->functor()).'(' . join(", ", $self->fargs) . ')'
    },
    '0+' => sub { $_[0]->arity },
    'bool' => sub { 1 },
    'fallback' => 1 ;


package Language::Prolog::Types::List;
use overload
    '""' => sub { '['.join(", ", $_[0]->largs()).']'},
    '0+' => sub { $_[0]->length },
    'bool' => sub { 1 },
    'fallback' => 1 ;


package Language::Prolog::Types::UList;
use overload
    '""' => sub {
	my $self=shift;
	'['.
	    join(', ', ($self->largs()))
		.' | '.
		    $self->tail.
			']'
    },
    "0+" => sub { $_[0]->length },
    'bool' => sub { 1 },
    'fallback' => 1;


package Language::XSB::Type::Unknow;
use overload
    '""' => sub { "<prolog_unknow ".$_[0]->id.">" },
    '0+' => sub { 0 },
    'bool' => sub { 1 },
    'fallback' => 1;


1;
__END__

=head1 NAME

Language::Prolog::Types::overload - nice formating for Prolog terms.

=head1 SYNOPSIS

use Language::Prolog::Types::overload;


=head1 ABSTRACT

This module activates overloading features for Prolog terms.


=head1 DESCRIPTION

When this module is loaded, Prolog terms are automatically converted
to strings when printed or concatenated.

When used in bool context, all terms but variables return true, even
the nil term.

In numerical context, functors return its arity and lists its length.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Language::Prolog::Types> and L<Language::Prolog::Types::Abstract>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
