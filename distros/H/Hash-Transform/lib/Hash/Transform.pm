package Hash::Transform;

use warnings;
use strict;

our $VERSION = '0.01';

use Carp ();



sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->init(@_);
  return $self;
}


sub init {
  my $self = shift;
  $self->{rules} = {};
  $self->rules(@_) if @_;
  return $self;
}


sub rules {
  my $self = shift;
  Carp::croak "Missing rules" unless @_;
  my $hash_ref = _hash_arg(@_);
  Carp::croak "Invalid rules" unless $hash_ref;
  $self->{rules} = $hash_ref;
  return $self;
}


sub _apply_rule {
  my ($self, $code, $data) = @_;
  return unless defined $code && ref $data eq 'HASH';

  '' eq ref $code
    and return $data->{$code};

  'SCALAR' eq ref $code
    and return $$code;

  'CODE' eq ref $code
    and return $code->($data);

  'ARRAY' eq ref $code
    and return join(
                    $code->[0],
                    map {
                      my $entry = $self->_apply_rule($_, $data);
                      defined $entry ? $entry : '';
                    } @$code[1..$#$code]
                   );

  ## default
  return;
}


sub apply {
  my $self = shift;
  my $source = _hash_arg (@_)
    or Carp::croak "Invalid data set";
  my $rules = $self->{rules}
    or Carp::croak "Missing rules table";

  my %target = map {
    my $key = $_;
    my $value = $self->_apply_rule ($rules->{$key}, $source);
    ($key => $value);
  } keys %$rules;

  return wantarray ? %target : \%target;
}


sub _hash_arg {
  my $hash_ref
    = (@_ == 1 and ref $_[0] eq 'HASH') ? $_[0]
    : (@_ % 2 == 0)                     ? { @_ }
    : return
    ;
  return wantarray ? %$hash_ref : $hash_ref;
}



1;

__END__

=head1 NAME

Hash::Transform - a simple data-driven class for doing data
transformation.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 my %rules = (
              foo_field => 'foo',
              bar_field => 'bar',
              name      => [' ', \'Name:', 'first', 'last'],
              constant  => \'42',
              friend    => sub {
                my $data = shift;
                my $fullname = join (' ', @$data{'first','last'});
                return 'Ford' if $fullname eq 'Arthur Dent';
                return 'Arthur' if $fullname eq 'Ford Prefect';
                return 'No friends';
              },
             );
 my $transform = Hash::Transform->new(%rules);
 my %old_data = (
                 foo   => 'hello',
                 bar   => 'goodbye',
                 first => 'Arthur',
                 last  => 'Dent',
                );
 my %new_data = $transform->apply(%old_data);

 ## current contents of %new_data = (
 ##                                  foo_field => 'hello',
 ##                                  bar_field => 'goodbye',
 ##                                  name      => 'Name: Arthur Dent',
 ##                                  constant  => '42',
 ##                                  friend    => 'Ford',
 ##                                 );

=head1 DESCRIPTION

This class transforms data according to rules setup at instantiation or
via the C<rules> mutator.

The basic interface is C<new>, C<rules> and C<apply>.  The C<new> and
C<rules> methods take the same argument, which is either a hash or a
reference to a hash which will be used to setup the transformation rules.

The C<apply> method takes a hash or reference to a hash and returns
either a hash or reference to a hash which is the result of applying
the current rule set to the passed hash or hash ref.

The usual pattern of use would probably be:

    my %rules = (
                 # ... transform rules
                );
    my $transform = Hash::Transform->new(%rules);

    while (my $source_hash_ref = get_data_from_some_source()) {
      my $target_hash_ref = $transform->apply($source_hash);
      store_data_somewhere($target_hash_ref);
    }

=head1 CONSTRUCTOR

=head2 new()

Creates a new transformation object, which implements a single
transformation.

  my $transform = Hash::Transform->new(%transform_rules);

The transformation rules are optional at instantiation, and may be set
later via the C<rules> accessor.  They are required prior to applying
a transformation.

=head1 METHODS

=head2 $transform->rules(%transform_rules)

The mutator for transformation rules.  New rules passed to C<rules>
completely overwrite the old rules.  Note, this is only a mutator;
there is no accessor for rules.

=head2 $transform->apply(%original_data)

Applies the current transformation rules to the supplied hash or hash
ref, and returns the result as either a hash ref in scalar context, or
a hash list in array context.

=head2 $transform->init(%transform_rules)

This method is called by C<new>.  It resets an object to a "like new"
state, with only the transform rules passed to C<init> (if any).

=head1 HOW THE RULES WORK

The rules are passed in the form of a hash in which each key
represents a key in the transformed hash which will be returned.  Each
value may be a scalar value, a reference to a scalar, a reference to
an array, or a reference to code.  The ref type of the value will
determine the type of processing the C<apply> method will perform to
create the value of the new key.

=head2 Scalar value

A scalar value will copy the value of the old key equal to the scalar
value to the value of the new key.  No changes of any kind are made.

In the example in the synopsis, the value of $new_data{foo_field} will
be 'hello' (the value of $old_data{foo}).

=head2 Scalar reference

A scalar reference will set the value of the new key to that value.
The old data is not checked at all and no changes to the data are
made.

In the example in the synopsis, the value of $new_data{constant} will
be the string '42' (%old_data does not affect this).  A reference to a
variable containing the value '42' would have the same effect.

=head2 Array reference

An array reference acts very similar to the C<join> function.  It
causes the C<apply> method to take the first element of the array as a
separator field, then recursively process the rest of the elements
according to the same rules, and concatenate those values with the
separator field between each value.  The final result is the value of
the new key.

In the example in the synopsis, the value of $new_data{name} will be
'Name: Arthur Dent', which is the 'Name:' (from a scalar
reference), $old_data{first} (from a scalar), and $old_data{last}
(also from a scalar) all concatenated together with a space separating
them.

=head2 Code reference

A code reference is for complex data processing not manageable by the
above rules.  The code will be called passing a reference to the old
data set (which may or may not be a reference to the original hash).
The value of the new key will be set to whatever is returned by that
call.  Code references are the most powerful but most obscure way of
transforming data.

In the example in the synopsis, the value of $new_data{friend}
will be 'Ford', which is what the anonymous subroutine will return
for this particular %old_data.

=head1 ERROR HANDLING

This module deliberately does very little error handling.  If a key
referenced in the rules doesn't exist, then that key in the new hash
will be silently set to c<undef>.  Calls to sub refs are not wrapped
in evals, so if they do something illegal the error will propegate
back to the caller.

=head1 AUTHOR

Dave Trischuk, C<< <trischuk at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-transform at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Transform>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Transform


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Transform>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Transform>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Transform>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Transform>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Dave Trischuk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
