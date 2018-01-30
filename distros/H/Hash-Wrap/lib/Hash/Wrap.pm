package Hash::Wrap;

# ABSTRACT: create lightweight on-the-fly objects from hashes

use 5.008009;

use strict;
use warnings;

use Scalar::Util qw[ blessed ];
use MRO::Compat;

our $VERSION = '0.05';

use Hash::Wrap::Base;

our @EXPORT = qw[ wrap_hash ];

my %REGISTRY;

sub _croak {

    require Carp;
    Carp::croak( @_ );
}

sub _find_sub {

    my ( $object, $sub, $throw ) = @_;

    $throw = 1 unless defined $throw;
    my $package = blessed( $object ) || $object;

    no strict 'refs';  ## no critic (ProhibitNoStrict)


    my $mro = mro::get_linear_isa( $package );

    for my $module ( @$mro ) {
        my $candidate = *{"$module\::$sub"}{SCALAR};

        return $$candidate if defined $candidate && 'CODE' eq ref $$candidate;
    }

    $throw ? _croak( "Unable to find sub reference \$$sub for class $package\n" ) : return;
}

# this is called only if the method doesn't exist.
sub _generate_accessor {

    my ( $object, $package, $key ) = @_;

    # $code = eval "sub : lvalue { ... }" will invoke the sub as it is
    # used as an lvalue inside of the eval, so set it equal to a variable
    # to ensure it's an rvalue

    my $code = q[
        package <<PACKAGE>>;
        use Scalar::Util ();

       sub <<KEY>> <<SIGNATURE>> {
         my $self = shift;

         unless ( Scalar::Util::blessed( $self ) ) {
           require Carp;
           Carp::croak( qq[Can't locate object method "<<KEY>>" via package $self \n] );
         }

         unless ( <<VALIDATE>> ) {
           require Carp;
           Carp::croak( qq[Can't locate object method "<<KEY>>" via package @{[ Scalar::Util::blessed( $self ) ]} \n] );
         }

        $self->{q[<<KEY>>]} = $_[0] if @_;

        return $self->{q[<<KEY>>]};
       }
       \&<<KEY>>;
    ];

    my %dict = (
        package => $package,
        key     => $key,
    );

    $dict{$_} = _find_sub( $object, "generate_$_" )->()
      for  qw[ validate signature ];

    my $coderef = _compile_from_tpl( \$code, \%dict );

    _croak( qq[error compiling accessor: $@\n $code \n] )
      if $@;

    return $coderef;
}

sub _generate_validate {

    my ( $object, $package ) = @_;
    my $code = q[
        package <<PACKAGE>>;
        our $validate_key = sub {
            my ( $self, $key ) = @_;
            return <<VALIDATE>>;
        };
    ];

    _compile_from_tpl(
        \$code,
        {
            package  => $package,
            key      => '$key',
            validate => _find_sub( $object, 'generate_validate' )->()
        },
      )
      || _croak(
        qq(error creating validate_key subroutine for @{[ ref $object ]}: $@\n $code )
      );
}

sub _autoload {

    my ( $method, $object ) = @_;

    my ( $package, $key ) = $method =~ /(.*)::(.*)/;

    _croak(
        qq[Can't locate class method "$key" via package @{[ ref $object]} \n] )
      unless Scalar::Util::blessed( $object );

    # we're here because there's no slot in the hash for $key.
    #
    my $validate = _find_sub( $object, 'validate_key', 0 );

    $validate = _generate_validate( $object, $package )
      if ! defined $validate;

    _croak(
        qq[Can't locate object method "$key" via package @{[ ref $object]} \n] )
      unless $validate->( $object, $key );

    _generate_accessor( $object, $package, $key );
}


sub import {

    my ( $me ) = shift;
    my $caller = caller;

    my @imports = @_;

    push @imports, @EXPORT unless @imports;

    for my $args ( @imports ) {

        if ( !ref $args ) {
            _croak( "$args is not exported by ", __PACKAGE__, "\n" )
              unless grep { /$args/ } @EXPORT;

            $args = { -as => $args };
        }

        elsif ( 'HASH' ne ref $args ) {
            _croak(
                "argument to ",
                __PACKAGE__,
                "::import must be string or hash\n"
            ) unless grep { /$args/ } @EXPORT;
        }
        else {
            # make a copy as it gets modified later on
            $args = { %$args };
        }

        my $name = exists $args->{-as} ? delete $args->{-as} : 'wrap_hash';

        my $sub = _generate_wrap_hash( $me, $name, {%$args} );

        no strict 'refs';    ## no critic (ProhibitNoStrict)
        *{"$caller\::$name"} = $sub;
    }

}

sub _generate_wrap_hash {

    my ( $me ) = shift;
    my ( $name, $args ) = @_;

    # closure for user provided clone sub
    my $clone;

    my ( @pre_code, @post_code );

    _croak( "lvalue accessors require Perl 5.16 or later\n" )
      if $args->{-value} && $] lt '5.016000';

    _croak( "cannot mix -copy and -clone\n" )
      if exists $args->{-copy} && exists $args->{-clone};


    if ( delete $args->{-copy} ) {
        push @pre_code, '$hash = { %{ $hash } };';
    }
    elsif ( exists $args->{-clone} ) {

        if ( 'CODE' eq ref $args->{-clone} ) {
            $clone = $args->{-clone};
            push @pre_code, '$hash = $clone->($hash);';
        }
        else {
            require Storable;
            push @pre_code, '$hash = Storable::dclone $hash;';
        }

        delete $args->{-clone};
    }

    my $class;

    if ( defined $args->{-class} && !$args->{-create} ) {
        $class = $args->{-class};

        _croak( qq[class ($class) is not a subclass of Hash::Wrap::Base\n] )
          unless $class->isa( 'Hash::Wrap::Base' );

        if ( $args->{-lvalue} ) {
            my $signature = _find_sub( $class, 'generate_signature' )->();
            _croak( "signature generator for $class does not add ':lvalue'\n" )
              unless defined $signature && $signature =~ /:\s*lvalue/;
        }
    }
    else {
        $class = _build_class( $args );
    }

    my $construct = 'my $obj = ' . do {

        if ( $class->can( 'new' ) ) {
            qq[$class->new(\$hash);];
        }
        else {
            qq[bless \$hash, '$class';];
        }

    };

    #<<< no tidy
    my $code = qq[
    sub (\$) {
      my \$hash = shift;
      if ( ! 'HASH' eq ref \$hash ) { _croak( "argument to $name must be a hashref\n" ) }
      <<PRECODE>>
      <<CONSTRUCT>>
      <<POSTCODE>>
      return \$obj;
      };
    ];
    #>>>

    # clean out the rest of the known attributes
    delete @{$args}{qw[ -lvalue -create -class -undef ]};

    if ( keys %$args ) {
        _croak( "unknown options passed to ",
            __PACKAGE__, "::import: ", join( ', ', keys %$args ), "\n" );
    }

    _interpolate(
        \$code,
        {
            precode   => join( "\n", @pre_code ),
            construct => $construct,
            postcode  => join( "\n", @post_code ),
        },
    );

    return eval( $code )    ## no critic (ProhibitStringyEval)
      || _croak( "error generating wrap_hash subroutine: $@\n$code" );

}

# our bizarre little role emulator.  except our roles have no methods, just lexical subs.  whee!
sub _build_class {

    my $attr = shift;

    my $class = $attr->{-class};

    if ( !defined $class ) {

        my @class = map { ( my $attr = $_ ) =~ s/-//; $attr } sort keys %$attr;

        $class = join '::', 'Hash::Wrap::Class', @class;
    }

    return $class if $REGISTRY{$class};

    my %code = (
        class         => $class,
        signature     => '',
        body          => '',
        autoload_attr => '',
        validate      => '',
    );

    if ( $attr->{-lvalue} ) {

        $code{autoload_attr} = ': lvalue';
        $code{signature} = 'our $generate_signature = sub { q[: lvalue]; };';
    }

    if ( $attr->{-undef} ) {
        $code{validate} = q[ our $generate_validate = sub { '1' }; ];
    }

    my $class_template = <<'END';
package <<CLASS>>;

use Scalar::Util ();

our @ISA = ( 'Hash::Wrap::Base' );

<<SIGNATURE>>

<<BODY>>

<<VALIDATE>>

our $AUTOLOAD;
sub AUTOLOAD <<AUTOLOAD_ATTR>> {
    goto &{ Hash::Wrap::_autoload( $AUTOLOAD, $_[0] ) };
}

1;
END

    _compile_from_tpl( \$class_template, \%code )
      or _croak( "error generating class $class: $@\n$class_template" );

    $REGISTRY{$class}++;

    return $class;
}

# can't handle closures; should use Sub::Quote
sub _compile_from_tpl {
    my ( $code, $dict ) = @_;

    _interpolate( $code, $dict );
    eval( $$code );  ## no critic (ProhibitStringyEval)
}

sub _interpolate {

    my ( $tpl, $dict, $work ) = @_;

    $work = { loop => {} } unless defined $work;

    $$tpl =~ s{ \<\<(\w+)\>\>
              }{
                  my $key = lc $1;
                  my $v = $dict->{$key};
                  if ( defined $v ) {
                      _croak( "circular interpolation loop detected for $key\n" )
                        if $work->{loop}{$key}++;
                      _interpolate( \$v, $dict, $work );
                      --$work->{loop}{$key};
                 }
                 $v;
              }gex;
    return;
}


1;

#
# This file is part of Hash-Wrap
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

Hash::Wrap - create lightweight on-the-fly objects from hashes

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Hash::Wrap;

  sub foo {
    wrap_hash { a => 1 };
  }

  $result = foo();
  print $result->a;  # prints
  print $result->b;  # throws

  # create two constructors, <cloned> and <copied> with different
  # behaviors. does not import C<wrap_hash>
  use Hash::Wrap
    { -as => 'cloned', clone => 1},
    { -as => 'copied', copy => 1 };

=head1 DESCRIPTION

This module provides constructors which create light-weight objects
from existing hashes, allowing access to hash elements via methods
(and thus avoiding typos). By default, attempting to access a
non-existent element via a method will result in an exception, but
this may be modified so that the undefined value is returned (see
L</-undef>).

Hash elements may be added to or deleted from the object after
instantiation using the standard Perl hash operations, and changes
will be reflected in the object's methods. For example,

   $obj = wrap_hash( { a => 1, b => 2 );
   $obj->c; # throws exception
   $obj->{c} = 3;
   $obj->c; # returns 3
   delete $obj->{c};
   $obj->c; # throws exception

To prevent modification of the hash, consider using the lock routines
in L<Hash::Util> on the object.

The methods act as both accessors and setters, e.g.

  $obj = wrap_hash( { a => 1 } );
  print $obj->a; # 1
  $obj->a( 3 );
  print $obj->a; # 3

Only hash keys which are legal method names will be accessible via
object methods.

Accessors may optionally be used as lvalues, e.g.,

  $obj->a = 3;

in Perl version 5.16 or later. See L</-lvalue>.

=head2 Object construction and constructor customization

By default C<Hash::Wrap> exports a C<wrap_hash> subroutine which,
given a hashref, blesses it directly into the B<Hash::Wrap::Class>
class.

The constructor may be customized to change which class the object is
instantiated from, and how it is constructed from the data.
For example,

  use Hash::Wrap
    { -as => 'return_cloned_object', -clone => 1 };

will create a constructor which clones the passed hash
and is imported as C<return_cloned_object>.  To import it under
the original name, C<wrap_hash>, leave out the C<-as> option.

The following options are available to customize the constructor.

=over

=item C<-as> => I<subroutine name>

This is optional, and imports the constructor with the given name. If
not specified, it defaults to C<wrap_hash>.

=item C<-class> => I<class name>

The object will be blessed into the specified class.  If the class
should be created on the fly, specify the C<-create> option.
See L</Object Classes> for what is expected of the object classes.
This defaults to C<Hash::Wrap::Class>.

=item C<-create> => I<boolean>

If true, and C<-class> is specified, a class with the given name
will be created.

=item C<-copy> => I<boolean>

If true, the object will store the data in a I<shallow> copy of the
hash. By default, the object uses the hash directly.

=item C<-clone> => I<boolean> | I<coderef>

Store the data in a deep copy of the hash. if I<true>, L<Storable/dclone>
is used. If a coderef, it will be called as

   $clone = coderef->( $hash )

By default, the object uses the hash directly.

=item C<-undef> => I<boolean>

Normally an attempt to use an accessor for an non-existent key will
result in an exception.  The C<-undef> option causes the accessor
to return C<undef> instead.  It does I<not> create an element in
the hash for the key.

=item C<-lvalue> => I<boolean>

If true, the accessors will be lvalue routines, e.g. they can
change the underlying hash value by assigning to them:

   $obj->attr = 3;

The hash entry must already exist before using the accessor in
this manner, or it will throw an exception.

This is only available on Perl version 5.16 and later.

=back

=head2 Object Classes

An object class has the following properties:

=over

=item *

The class must be a subclass of C<Hash::Wrap::Base>.

=item *

The class typically does not provide any methods, as they would mask
a hash key of the same name.

=item *

The class need not have a constructor.  If it does, it is passed a
hashref which it should bless as the actual object.  For example:

  package My::Result;
  use parent 'Hash::Wrap::Base';

  sub new {
    my  ( $class, $hash ) = @_;
    return bless $hash, $class;
  }

This excludes having a hash key named C<new>.

=back

C<Hash::Wrap::Base> provides an empty C<DESTROY> method, a
C<can> method, and an C<AUTOLOAD> method.  They will mask hash
keys with the same names.

=head1 LIMITATIONS

=over

=item *

Lvalue accessors are available only on Perl 5.16 and later.

=back

=head1 SEE ALSO

Here's a comparison of this module and others on CPAN.

=over

=item L<Hash::Wrap> (this module)

=over

=item * core dependencies only

=item * only applies object paradigm to top level hash

=item * accessors may be lvalue subroutines

=item * accessing a non-existing element via an accessor throws

=item * can use custom package

=item * can copy/clone existing hash. clone may be customized

=back

=item L<Object::Result>

As you might expect from a
L<DCONWAY|https://metacpan.org/author/DCONWAY> module, this does just
about everything you'd like.  It has a very heavy set of dependencies.

=item L<Hash::AsObject>

=over

=item * core dependencies only

=item * applies object paradigm recursively

=item * accessing a non-existing element via an accessor creates it

=back

=item L<Data::AsObject>

=over

=item * moderate dependency chain (no XS?)

=item * applies object paradigm recursively

=item * accessing a non-existing element throws

=back

=item L<Class::Hash>

=over

=item * core dependencies only

=item * only applies object paradigm to top level hash

=item * can add generic accessor, mutator, and element management methods

=item * accessing a non-existing element via an accessor creates it (not documented, but code implies it)

=item * C<can()> doesn't work

=back

=item L<Hash::Inflator>

=over

=item * core dependencies only

=item * accessing a non-existing element via an accessor returns undef

=item * applies object paradigm recursively

=back

=item L<Hash::AutoHash>

=over

=item * moderate dependency chain.  Requires XS, tied hashes

=item * applies object paradigm recursively

=item * accessing a non-existing element via an accessor creates it

=back

=item L<Hash::Objectify>

=over

=item * light dependency chain.  Requires XS.

=item * only applies object paradigm to top level hash

=item * accessing a non-existing element throws, but if an existing
element is accessed, then deleted, accessor returns undef rather than
throwing

=item * can use custom package

=back

=item L<Data::OpenStruct::Deep>

=over

=item * uses source filters

=item * applies object paradigm recursively

=back

=item L<Object::AutoAccessor>

=over

=item * light dependency chain

=item * applies object paradigm recursively

=item * accessing a non-existing element via an accessor creates it

=back

=item L<Data::Object::Autowrap>

=over

=item * core dependencies only

=item * no documentation

=back

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Wrap> or by email
to L<bug-Hash-Wrap@rt.cpan.org|mailto:bug-Hash-Wrap@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/hash-wrap>
and may be cloned from L<git://github.com/djerius/hash-wrap.git>

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


#pod =head1 SYNOPSIS
#pod
#pod
#pod   use Hash::Wrap;
#pod
#pod   sub foo {
#pod     wrap_hash { a => 1 };
#pod   }
#pod
#pod   $result = foo();
#pod   print $result->a;  # prints
#pod   print $result->b;  # throws
#pod
#pod   # create two constructors, <cloned> and <copied> with different
#pod   # behaviors. does not import C<wrap_hash>
#pod   use Hash::Wrap
#pod     { -as => 'cloned', clone => 1},
#pod     { -as => 'copied', copy => 1 };
#pod
#pod =head1 DESCRIPTION
#pod
#pod
#pod This module provides constructors which create light-weight objects
#pod from existing hashes, allowing access to hash elements via methods
#pod (and thus avoiding typos). By default, attempting to access a
#pod non-existent element via a method will result in an exception, but
#pod this may be modified so that the undefined value is returned (see
#pod L</-undef>).
#pod
#pod Hash elements may be added to or deleted from the object after
#pod instantiation using the standard Perl hash operations, and changes
#pod will be reflected in the object's methods. For example,
#pod
#pod    $obj = wrap_hash( { a => 1, b => 2 );
#pod    $obj->c; # throws exception
#pod    $obj->{c} = 3;
#pod    $obj->c; # returns 3
#pod    delete $obj->{c};
#pod    $obj->c; # throws exception
#pod
#pod
#pod To prevent modification of the hash, consider using the lock routines
#pod in L<Hash::Util> on the object.
#pod
#pod The methods act as both accessors and setters, e.g.
#pod
#pod   $obj = wrap_hash( { a => 1 } );
#pod   print $obj->a; # 1
#pod   $obj->a( 3 );
#pod   print $obj->a; # 3
#pod
#pod Only hash keys which are legal method names will be accessible via
#pod object methods.
#pod
#pod Accessors may optionally be used as lvalues, e.g.,
#pod
#pod   $obj->a = 3;
#pod
#pod in Perl version 5.16 or later. See L</-lvalue>.
#pod
#pod
#pod =head2 Object construction and constructor customization
#pod
#pod By default C<Hash::Wrap> exports a C<wrap_hash> subroutine which,
#pod given a hashref, blesses it directly into the B<Hash::Wrap::Class>
#pod class.
#pod
#pod The constructor may be customized to change which class the object is
#pod instantiated from, and how it is constructed from the data.
#pod For example,
#pod
#pod   use Hash::Wrap
#pod     { -as => 'return_cloned_object', -clone => 1 };
#pod
#pod will create a constructor which clones the passed hash
#pod and is imported as C<return_cloned_object>.  To import it under
#pod the original name, C<wrap_hash>, leave out the C<-as> option.
#pod
#pod The following options are available to customize the constructor.
#pod
#pod =over
#pod
#pod =item C<-as> => I<subroutine name>
#pod
#pod This is optional, and imports the constructor with the given name. If
#pod not specified, it defaults to C<wrap_hash>.
#pod
#pod =item C<-class> => I<class name>
#pod
#pod The object will be blessed into the specified class.  If the class
#pod should be created on the fly, specify the C<-create> option.
#pod See L</Object Classes> for what is expected of the object classes.
#pod This defaults to C<Hash::Wrap::Class>.
#pod
#pod =item C<-create> => I<boolean>
#pod
#pod If true, and C<-class> is specified, a class with the given name
#pod will be created.
#pod
#pod =item C<-copy> => I<boolean>
#pod
#pod If true, the object will store the data in a I<shallow> copy of the
#pod hash. By default, the object uses the hash directly.
#pod
#pod =item C<-clone> => I<boolean> | I<coderef>
#pod
#pod Store the data in a deep copy of the hash. if I<true>, L<Storable/dclone>
#pod is used. If a coderef, it will be called as
#pod
#pod    $clone = coderef->( $hash )
#pod
#pod By default, the object uses the hash directly.
#pod
#pod =item C<-undef> => I<boolean>
#pod
#pod Normally an attempt to use an accessor for an non-existent key will
#pod result in an exception.  The C<-undef> option causes the accessor
#pod to return C<undef> instead.  It does I<not> create an element in
#pod the hash for the key.
#pod
#pod =item C<-lvalue> => I<boolean>
#pod
#pod If true, the accessors will be lvalue routines, e.g. they can
#pod change the underlying hash value by assigning to them:
#pod
#pod    $obj->attr = 3;
#pod
#pod The hash entry must already exist before using the accessor in
#pod this manner, or it will throw an exception.
#pod
#pod This is only available on Perl version 5.16 and later.
#pod
#pod =back
#pod
#pod =head2 Object Classes
#pod
#pod An object class has the following properties:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod The class must be a subclass of C<Hash::Wrap::Base>.
#pod
#pod =item *
#pod
#pod The class typically does not provide any methods, as they would mask
#pod a hash key of the same name.
#pod
#pod =item *
#pod
#pod The class need not have a constructor.  If it does, it is passed a
#pod hashref which it should bless as the actual object.  For example:
#pod
#pod   package My::Result;
#pod   use parent 'Hash::Wrap::Base';
#pod
#pod   sub new {
#pod     my  ( $class, $hash ) = @_;
#pod     return bless $hash, $class;
#pod   }
#pod
#pod This excludes having a hash key named C<new>.
#pod
#pod =back
#pod
#pod C<Hash::Wrap::Base> provides an empty C<DESTROY> method, a
#pod C<can> method, and an C<AUTOLOAD> method.  They will mask hash
#pod keys with the same names.
#pod
#pod =head1 LIMITATIONS
#pod
#pod =over
#pod
#pod =item *
#pod
#pod Lvalue accessors are available only on Perl 5.16 and later.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod Here's a comparison of this module and others on CPAN.
#pod
#pod
#pod =over
#pod
#pod =item L<Hash::Wrap> (this module)
#pod
#pod =over
#pod
#pod =item * core dependencies only
#pod
#pod =item * only applies object paradigm to top level hash
#pod
#pod =item * accessors may be lvalue subroutines
#pod
#pod =item * accessing a non-existing element via an accessor throws
#pod
#pod =item * can use custom package
#pod
#pod =item * can copy/clone existing hash. clone may be customized
#pod
#pod =back
#pod
#pod
#pod =item L<Object::Result>
#pod
#pod As you might expect from a
#pod L<DCONWAY|https://metacpan.org/author/DCONWAY> module, this does just
#pod about everything you'd like.  It has a very heavy set of dependencies.
#pod
#pod =item L<Hash::AsObject>
#pod
#pod =over
#pod
#pod =item * core dependencies only
#pod
#pod =item * applies object paradigm recursively
#pod
#pod =item * accessing a non-existing element via an accessor creates it
#pod
#pod =back
#pod
#pod =item L<Data::AsObject>
#pod
#pod =over
#pod
#pod =item * moderate dependency chain (no XS?)
#pod
#pod =item * applies object paradigm recursively
#pod
#pod =item * accessing a non-existing element throws
#pod
#pod =back
#pod
#pod =item L<Class::Hash>
#pod
#pod =over
#pod
#pod =item * core dependencies only
#pod
#pod =item * only applies object paradigm to top level hash
#pod
#pod =item * can add generic accessor, mutator, and element management methods
#pod
#pod =item * accessing a non-existing element via an accessor creates it (not documented, but code implies it)
#pod
#pod =item * C<can()> doesn't work
#pod
#pod =back
#pod
#pod =item L<Hash::Inflator>
#pod
#pod =over
#pod
#pod =item * core dependencies only
#pod
#pod =item * accessing a non-existing element via an accessor returns undef
#pod
#pod =item * applies object paradigm recursively
#pod
#pod =back
#pod
#pod =item L<Hash::AutoHash>
#pod
#pod =over
#pod
#pod =item * moderate dependency chain.  Requires XS, tied hashes
#pod
#pod =item * applies object paradigm recursively
#pod
#pod =item * accessing a non-existing element via an accessor creates it
#pod
#pod =back
#pod
#pod =item L<Hash::Objectify>
#pod
#pod =over
#pod
#pod =item * light dependency chain.  Requires XS.
#pod
#pod =item * only applies object paradigm to top level hash
#pod
#pod =item * accessing a non-existing element throws, but if an existing
#pod element is accessed, then deleted, accessor returns undef rather than
#pod throwing
#pod
#pod =item * can use custom package
#pod
#pod =back
#pod
#pod =item L<Data::OpenStruct::Deep>
#pod
#pod =over
#pod
#pod =item * uses source filters
#pod
#pod =item * applies object paradigm recursively
#pod
#pod =back
#pod
#pod =item L<Object::AutoAccessor>
#pod
#pod =over
#pod
#pod =item * light dependency chain
#pod
#pod =item * applies object paradigm recursively
#pod
#pod =item * accessing a non-existing element via an accessor creates it
#pod
#pod =back
#pod
#pod =item L<Data::Object::Autowrap>
#pod
#pod =over
#pod
#pod =item * core dependencies only
#pod
#pod =item * no documentation
#pod
#pod =back
#pod
#pod =back
