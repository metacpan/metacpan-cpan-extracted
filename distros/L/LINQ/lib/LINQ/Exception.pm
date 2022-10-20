use 5.006;
use strict;
use warnings;

if ( $] < 5.010000 ) {
	require UNIVERSAL::DOES;
}

{

	package LINQ::Exception;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	
	use Class::Tiny qw( package file line );
	use overload q[""] => sub { shift->to_string };
	
	sub message { "An error occurred" }
	
	sub to_string {
		my $self = shift;
		sprintf(
			"%s at %s line %d.\n",
			$self->message,
			$self->file,
			$self->line,
		);
	}
	
	sub throw {
		my $class = shift;
		
		my ( $level, %caller ) = 0;
		$level++ until caller( $level ) !~ /\ALINQx?(::|\z)/;
		@caller{qw/ package file line /} = caller( $level );
		
		die( $class->new( %caller, @_ ) );
	}
}

{

	package LINQ::Exception::Unimplemented;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( method );
	
	sub message {
		my $self = shift;
		my $meth = $self->method;
		"Method $meth is unimplemented";
	}
}

{

	package LINQ::Exception::InternalError;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( message );
}

{

	package LINQ::Exception::CallerError;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( message );
	
	sub BUILD {
		my $self = shift;
		'LINQ::Exception::InternalError'
			->throw( message => 'Required attribute "message" not defined' )
			unless defined $self->message;
	}
}

{

	package LINQ::Exception::CollectionError;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( collection );
	
	sub BUILD {
		my $self = shift;
		'LINQ::Exception::InternalError'
			->throw( message => 'Required attribute "collection" not defined' )
			unless defined $self->collection;
	}
}

{

	package LINQ::Exception::NotFound;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use parent -norequire, qw( LINQ::Exception::CollectionError );
	sub message { "Item not found" }
}

{

	package LINQ::Exception::MultipleFound;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use parent -norequire, qw( LINQ::Exception::CollectionError );
	use Class::Tiny qw( found );
	sub message { "Item not found" }
}

{

	package LINQ::Exception::Cast;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	use parent -norequire, qw( LINQ::Exception::CollectionError );
	use Class::Tiny qw( type );
	
	sub message {
		my $type = shift->type;
		"Not all elements in the collection could be cast to $type";
	}
	
	sub BUILD {
		my $self = shift;
		'LINQ::Exception::InternalError'
			->throw( message => 'Required attribute "type" not defined' )
			unless defined $self->type;
	}
}

1;

=pod

=encoding utf-8

=head1 NAME

LINQ::Exception - exceptions thrown by LINQ

=head1 DESCRIPTION

When LINQ encounters an error, it doesn't just C<die> with a string, but throws
an exception object which can be caught with C<eval>, L<Try::Tiny>, or
L<Syntax::Keyword::Try>.

These objects overload stringification, so if they are not caught and dealt
with, you'll get a sensible error message printed.

=head1 EXCEPTION TYPES

=head2 LINQ::Exception

This is the base class for all LINQ exceptions.

  use LINQ qw( LINQ );
  use Syntax::Keyword::Try qw( try :experimental );
  
  try {
    my $collection = LINQ [ 1, 2, 3 ];
    my $item       = $collection->element_at( 10 );
  }
  catch ( $e isa LINQ::Exception ) {
    printf(
      "Got error: %s at %s (%s line %d)\n",
      $e->message,
      $e->package,
      $e->file,
      $e->line,
    );
  }

The class provides C<message>, C<package>, C<file>, and C<line> methods to
get details of the error, as well as a C<to_string> method which provides the
message, package, file, and line as one combined string.

There is a class method C<throw> which instantiates a new object and dies.

  'LINQ::Exception'->throw;

LINQ::Exception is never directly thrown by LINQ, but subclasses of it are.

=begin trustme

=item throw

=item message

=item file

=item line

=item package

=item to_string

=end trustme

=head2 LINQ::Exception::Unimplemented

A subclass of LINQ::Exception thrown when you call a method or feature which
is not implemented for the collection you call it on.

=head2 LINQ::Exception::InternalError

A subclass of LINQ::Exception thrown when an internal error is encountered in
LINQ, not caused by the caller.

=head2 LINQ::Exception::CallerError

A subclass of LINQ::Exception thrown when the caller of a method has called it
incorrectly. For example, if a method is called which expects a coderef as a
parameter, but is given a string.

=head2 LINQ::Exception::CollectionError

A subclass of LINQ::Exception thrown when a method you've called cannot be
fulfilled by the collection you've called it on. For example, you've asked to
fetch the third item in a collection containing only two items.

The exception has a C<collection> attribute which returns the collection which
generated the error.

=head2 LINQ::Exception::NotFound

A subclass of LINQ::Exception::CollectionError thrown when trying to access an
item in a collection which cannot be found.

=head2 LINQ::Exception::MultipleFound

A subclass of LINQ::Exception::CollectionError thrown when trying to access a
single item in a collection when multiple items are found.

=head2 LINQ::Exception::Cast

A subclass of LINQ::Exception::CollectionError thrown when trying to cast all
items in a collection to a type, but this fails for one or more items.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
