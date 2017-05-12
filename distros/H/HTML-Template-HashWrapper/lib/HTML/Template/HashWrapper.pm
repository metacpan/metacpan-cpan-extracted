package HTML::Template::HashWrapper;
use strict;
use Carp 'croak';

our $VERSION = '1.3';

sub new {
  my $class = shift;
  my $wrapped = shift;
  unless ( UNIVERSAL::isa($wrapped, 'HASH') ) {
    croak "Wrapped object is not a hash reference";
  }
  my %args = @_;
  my $at_isa = $class;
  my $pkgname = $class->_GENERATE_PACKAGENAME();
  if ( UNIVERSAL::isa( $wrapped, 'UNIVERSAL' ) ) {
    # $wrapped is already blessed: add its ref to @ISA
    $at_isa .= " " . ref($wrapped);
  }
  eval "{package $pkgname; use strict; our \@ISA=qw($at_isa); 1;}";
  die $@ if $@;
  return bless $wrapped, $pkgname;
}

# If you don't like my anonymous packagename generation, you can roll your own.
sub _GENERATE_PACKAGENAME {
  my $class = shift;
  my $uniq = "ANON_".$$.time().int(rand()*10000);
  my $pkgname = "$ {class}::$ {uniq}";
  return $pkgname;
}

# todo: according to H::T, param() can also support:
#       set multiple params: hash input
#       set multuple params from a hashref input

# Standard behavior: $self is a hashref
sub param {
  my $self = shift;
  my($name, $value) = @_;
  if ( defined($name) ) {
    if (defined($value)) {
      return $self->{$name} = $value;
    } else {
      return $self->{$name};
    }
  } else {
    return keys %{$self};
  }
}


1;

package HTML::Template::HashWrapper::Plain;
use strict;
use Carp 'croak';
our @ISA=('HTML::Template::HashWrapper'); # everything is overridden, though

sub new {
  my $class = shift;
  my $target = shift;
  unless ( UNIVERSAL::isa($target, 'HASH') ) {
    croak "Wrapped object is not a hash reference";
  }
  return bless { _ref => $target }, $class;
}

# Un-reblessing behavior: $self contains a reference to the reference
sub param {
  my $self = shift;
  my($name, $value) = @_;
  if ( defined($name) ) { 
    if (defined($value)) {
      return $self->{_ref}->{$name} = $value;
    } else {
      return $self->{_ref}->{$name};
    }
  } else {
    return keys %{ $self->{_ref} };
  }
}

1;
__END__

=pod

=head1 NAME

HTML::Template::HashWrapper - Easy association with HTML::Template

=head1 SYNOPSIS

  use HTML::Template;
  use HTML::Template::HashWrapper;

  my $context = { var1 => 'Stuff',
		  var2 => [ { name => 'Name1', value => 'Val1', },
			    { name => 'Name2', value => 'Val2', },
			  ],
		};

  my $template = HTML::Template->new
    ( associate => HTML::Template::HashWrapper->new( $context ) );

  # Some::Object creates blessed hash references:
  my $something = Some::Object->new();
  my $wrapper = HTML::Template::HashWrapper->new( $something );
  my $template = HTML::Template->new( associate => $wrapper );

  # the wrapper keeps the original's interface:
  my $val1 = $something->somemethod( 251 );
  my $val2 = $wrapper->somemethod( 251 );

=head1 DESCRIPTION

HTML::Template::HashWrapper provides a simple way to use arbitrary
hash references (and hashref-based objects) with HTML::Template's
C<associate> option.

C<new($ref)> returns an object with a C<param()> method which conforms
to HTML::Template's expected interface:

=over 4

=item

C<param($key)> returns the value of C<$ref-E<gt>{$key}>.

=item

C<param()> with no argument returns the set of keys.

=item

C<param($key,$value)> may also be used to set values in the underlying
hash.

=back

C<new()> will die if given something which is not a hash reference as
an argument.

The object returned by C<$new> retains its identity with its original
class, so you can continue to use the object as normal (call its
methods, etc).

=head2 Internals

HTML::Template::HashWrapper works by re-blessing the input object (or
blessing it, if the input is an unblessed hash reference) into a new
package which extends the original package and provides an
implementation of C<param()>.

If for some reason the input reference cannot be re-blessed (for
example, you're using someone else's code which checks C<ref($orig)>
when it should be using C<isa()>), you may use
HTML::Template::HashWrapper::Plain:

    $wrapper = HTML::Template::HashWrapper::Plain->new( $obj );

The C<Plain> wrapper object provides only the compliant C<param()> method,
but not any of the original object's methods.  The original object is
left completely untouched.  Most of the time this will be unneccesary.

For purposes of testing the object type,
HTML::Template::HashWrapper::Plain C<isa> HTML::Template::HashWrapper.

HashWrapper works by creating an unique package whose C<@ISA> includes
both HashWrapper and the original package (if there is one) of the
wrapped object.

If you don't like the way the unique package names are generated, you
can override C<_GENERATE_PACKAGENAME()>.  Be aware that you will see
strange behavior if this method does not return unique values (for a
sufficient definition of "unique").

Should you desire to subclass HashWrapper, you may wish to also
subclass HashWrapper::Plain, which manages its state slightly
differently.

=head1 OTHER

In theory, C<param()> should also support setting multiple parameters
by passing in a hash or hash reference.  This interface currently does
not support that, but HTML::Template only uses the two supported
forms.

It should be possible to make this more efficient by memoizing the
pairs of base package names, at the expense of some space for the
mapping.

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast (gdf@speakeasy.net)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
