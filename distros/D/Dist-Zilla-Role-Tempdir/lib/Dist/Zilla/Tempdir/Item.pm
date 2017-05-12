use 5.006;    #06 -> [pragmas, our]
use strict;
use warnings;

package Dist::Zilla::Tempdir::Item;

our $VERSION = '1.001003';

# ABSTRACT: A result object for things that DO() DZ::R::Tempdir;

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has );
use MooseX::LazyRequire;
use namespace::autoclean;

use Carp qw(croak);
use Scalar::Util qw( blessed );
















has 'status' => (
  isa           => 'Str',
  lazy_required => 1,
  is            => 'rw',
);













has 'file' => (
  isa      => 'Dist::Zilla::Role::File',
  required => 1,
  is       => 'rw',
  handles  => { name => 'name' },
);









sub _mk_status {
  my $name  = shift;
  my $value = shift;

  my $setter = sub {
    my $self = shift;
    return croak( $name . 'is an instance method, not a class method' ) unless blessed($self);
    return croak( 'too many arguments ( 0 expected ) to ->' . $name ) if @_;
    $self->status($value);
  };

  my $getter = sub {
    my $self = shift;
    return croak( $name . 'is an instance method, not a class method' ) unless blessed($self);
    return croak( 'too many arguments ( 0 expected ) to ->' . $name ) if @_;
    $self->status() eq $value;
  };

  {
    ## no critic ( ProhibitNoStrict )
    no strict 'refs';
    *{ __PACKAGE__ . q[::set_] . $name } = $setter;
    *{ __PACKAGE__ . q[::is_] . $name }  = $getter;
  }
  return 1;
}











_mk_status( 'modified', 'M' );











_mk_status( 'original', 'O' );












_mk_status( 'new', 'N' );











_mk_status( 'deleted', 'D' );

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Tempdir::Item - A result object for things that DO() DZ::R::Tempdir;

=head1 VERSION

version 1.001003

=head1 SYNOPSIS

  my $foo = Dist::Zilla::Tempdir::Item->new(
    name => 'Path/To/File.txt',
    file => $dzilfile,
  );
  $foo->set_new;
  $foo->is_new; # true
  $foo->is_deleted; # false
  $foo->set_deleted;
  $foo->is_new; # false
  $foo->is_deleted; # true.

Ultimately, I figured using a character with "C<eq>" every where in extending code
was a way to extra bugs that were hard to detect. Going via all the Object-Oriented niceness
you'll probably incur* a small performance penalty,  but things going B<Bang> when you
make a typo or add invisible white-space is a Good Thing.

* albeit immeasurably insignificant in size, especially for something that will only take
15 seconds of run-time every once in a while, not to mention the overhead is drowned by the
fact we're doing file-system IO and running many of the files through a complete hashing
algorithm to test for modification.

=head1 ATTRIBUTES

=head2 status

  isa => Str,
  is  => rw,

The internal status character. You can mangle this yourself if you want, and for compatibility with older versions
of this dist, you may even have to, but try not to, if it breaks, something something something pieces.

Using the is_* and set_* accessors is a I<much> smarter idea.

At present, the characters M, O, N and D have defined meanings, but this could change. ( Its not even unforeseeable expanding it to
be 2 characters to represent different parts of state, I probably will not do that, but do not pretend I will not ;) )

=head2 file

  isa      => Dist::Zilla::Role::File,
  required => 1,
  is       => rw

This is the Dist::Zilla::File::* item which we refer to. For items that C<is_deleted>, C<file> is likely to be the file before it got deleted.

For C<is_new> and C<is_original> files, the item is the file itself, and for C<is_modified>, its the modified version of the file.

=head1 METHODS

=head2 name

Proxy for C<< $item->file->name >>

This is the path to the file relative to the dist root.

=head2 is_modified

returns if the file is modified or not.

=head2 set_modified

sets the state to 'modified'

=head2 is_original

returns if the file is the original file or not.

=head2 set_original

sets the state to 'original'

=head2 is_new

returns if the file is new or not ( that is, if it wasn't in the dist prior to executing
the given code ).

=head2 set_new

sets the state to 'new'

=head2 is_deleted

returns if the file is deleted or not ( that is, if it were deleted during the execution phase )

=head2 set_deleted

sets the state to 'deleted'

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
