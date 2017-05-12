package Mandel::Iterator;

=head1 NAME

Mandel::Iterator - An object iterating over a collection cursor

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Mojo::Base -base;
use Scalar::Util 'blessed';
use Carp 'confess';

require Mandel::Collection;    # TODO: Fix ugly method call below

=head1 ATTRIBUTES

=head2 cursor

An object we can do C<next()> on. Normally a L<Mango::Cursor> object.

=head2 model

An object that inherit from L<Mandel::Model>.

=cut

has cursor => sub { confess "cursor required in constructor" };
has model  => sub { confess "model required in constructor" };

=head1 METHODS

=head2 next

  $self = $self->next(sub { my($self, $err, $obj) = @_; ... });

Fetch next document.

=cut

sub next {
  my ($self, $cb) = @_;

  $self->cursor->next(
    sub {
      my ($cursor, $err, $doc) = @_;

      # TODO: Fix this ugly method call
      $self->$cb($err, $doc ? $self->Mandel::Collection::_new_document($doc, 1) : undef);
    }
  );

  $self;
}

=head2 rewind

  $self = $self->rewind($cb);

Rewind cursor and kill it on the server

=cut

sub rewind {
  my ($self, $cb) = @_;

  if ($self->{cursor}) {
    $self->cursor->rewind(
      sub {
        $self->$cb($_[1]);
      }
    );
  }
  else {
    $self->$cb('');
  }

  $self;
}

=head1 SEE ALSO

L<Mojolicious>, L<Mango>, L<Mandel>

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
