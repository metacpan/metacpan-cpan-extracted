package Hash::Wrap;

# ABSTRACT: create on-the-fly objects from hashes

use 5.01000;

use strict;
use warnings;

use Scalar::Util qw[ blessed reftype ];
use Digest::MD5;
our $VERSION = '0.09';

our @EXPORT = qw[ wrap_hash ];

our @CARP_NOT = qw( Hash::Wrap );
our $DEBUG    = 0;

my %REGISTRY;

sub _croak {

    require Carp;
    Carp::croak( @_ );
}

sub _find_symbol {

    my ( $package, $symbol, $reftype ) = @_;

    no strict 'refs';    ## no critic (ProhibitNoStrict)

    my $candidate = *{"$package\::$symbol"}{SCALAR};

    return $$candidate
      if defined $candidate
      && 2 ==
      grep { defined $_->[0] && defined $_->[1] ? $_->[0] eq $_->[1] : 1 }
      [ $reftype->[0], reftype $candidate ],
      [ $reftype->[1], reftype $$candidate ];

    _croak( "Unable to find scalar \$$symbol in class $package" );
}

# this is called only if the method doesn't exist.
sub _generate_accessor {

    my ( $hash_class, $class, $key ) = @_;

    my %dict = (
        key   => $key,
        class => $class,
    );

    my $code = $REGISTRY{$hash_class}{accessor_template};

    my $coderef = _compile_from_tpl( \$code, \%dict );

    _croak_about_code( \$code, 'accessor' )
      if $@;

    return $coderef;
}

sub _autoload {

    my ( $hash_class, $method, $object ) = @_;

    my ( $class, $key ) = $method =~ /(.*)::(.*)/;

    _croak( qq[Can't locate class method "$key" via package @{[ ref $object]}] )
      unless Scalar::Util::blessed( $object );

    _croak(
        qq[Can't locate object method "$key" via package @{[ ref $object]}] )
      unless $REGISTRY{$hash_class}{validate}->( $object, $key );

    _generate_accessor( $hash_class, $class, $key );
}


sub import {

    shift;

    my $caller = caller;

    my @imports = @_;

    push @imports, @EXPORT unless @imports;

    for my $args ( @imports ) {

        if ( !ref $args ) {
            _croak( "$args is not exported by ", __PACKAGE__ )
              unless grep { /$args/ } @EXPORT;

            $args = { -as => $args };
        }

        elsif ( 'HASH' ne ref $args ) {
            _croak(
                "argument to ",
                __PACKAGE__,
                "::import must be string or hash"
            ) unless grep { /$args/ } @EXPORT;
        }
        else {
            # make a copy as it gets modified later on
            $args = {%$args};
        }

        _croak( "cannot mix -base and -class" )
          if !!$args->{-base} && exists $args->{-class};

        $DEBUG = $ENV{HASH_WRAP_DEBUG} // delete $args->{-debug} ;

        $args->{-as} = 'wrap_hash' unless exists $args->{-as};
        my $name = delete $args->{-as};

        if ( $args->{-base} ) {

            $args->{-class} = $caller;
            $args->{-new} = 1 unless !!$args->{-new};
            _build_class( $args );
        }

        else {
            _build_class( $args );
            _build_constructor( $caller, $name, $args )
              if defined $name;
        }

        # clean out known attributes
        delete @{$args}{
            qw[ -base -as -class -lvalue -undef -exists -defined -new -copy -clone ]
        };

        if ( keys %$args ) {
            _croak( "unknown options passed to ",
                __PACKAGE__, "::import: ", join( ', ', keys %$args ) );
        }
    }
}

# copied from Damian Conway's PPR: PerlIdentifier
use constant PerlIdentifier => qr/([^\W\d]\w*+)/;

sub _build_class {

    my $attr = shift;

    if ( !defined $attr->{-class} ) {

        my @class = map {
                ( my $key = $_ ) =~ s/-//;
                ( $key, defined $attr->{$_} ? $attr->{$_} : "<undef>" )
            } sort keys %$attr;

        $attr->{-class} = join '::', 'Hash::Wrap::Class', Digest::MD5::md5_hex( @class );
    }

    my $class = $attr->{-class};

    return $class if defined $REGISTRY{$class};

    my %dict = (
        class           => $class,
        signature       => '',
        body            => [],
        autoload_attr   => '',
        validate_inline => 'exists $self->{\<<KEY>>}',
        validate_method => 'exists $self->{$key}',
        meta => [  map { ( qq[q($_) => q($attr->{$_}),] ) } keys %$attr ],
    );

    if ( $attr->{-lvalue} ) {

        if ( $] lt '5.016000' ) {
            _croak( "lvalue accessors require Perl 5.16 or later" )
              if $attr->{-lvalue} < 0;
        }
        else {
            $dict{autoload_attr} = q[: lvalue];
            $dict{signature}     = q[: lvalue];
        }
    }

    if ( $attr->{-undef} ) {
        $dict{validate_method} = q[ 1 ];
        $dict{validate_inline} = q[ 1 ];
    }

    if ( $attr->{-exists} ) {
        $dict{exists} = $attr->{-exists} =~ PerlIdentifier ? $1 : 'exists';
        push @{ $dict{body} }, q[ sub <<EXISTS>> { exists $_[0]->{$_[1] } } ];
    }

    if ( $attr->{-defined} ) {
        $dict{defined} = $attr->{-defined} =~ PerlIdentifier ? $1 : 'defined';
        push @{ $dict{body} }, q[ sub <<DEFINED>> { defined $_[0]->{$_[1] } } ];
    }

    my $class_template = <<'END';
package <<CLASS>>;

use Scalar::Util ();

our $meta = { <<META>> };

our $validate = sub {
    my ( $self, $key ) = @_;
    return <<VALIDATE_METHOD>>;
};

our $accessor_template = q[
  package \<<CLASS>>;

  use Scalar::Util ();

  sub \<<KEY>> <<SIGNATURE>> {
    my $self = shift;

    unless ( Scalar::Util::blessed( $self ) ) {
      require Carp;
      Carp::croak( qq[Can't locate class method "\<<KEY>>" via package $self] );
    }

    unless ( <<VALIDATE_INLINE>> ) {
      require Carp;
      Carp::croak( qq[Can't locate object method "\<<KEY>>" via package @{[ Scalar::Util::blessed( $self ) ]}] );
    }

   $self->{q[\<<KEY>>]} = $_[0] if @_;

   return $self->{q[\<<KEY>>]};
  }
  \&\<<KEY>>;
];


<<BODY>>

our $AUTOLOAD;
sub AUTOLOAD <<AUTOLOAD_ATTR>> {
    goto &{ Hash::Wrap::_autoload( q[<<CLASS>>], $AUTOLOAD, $_[0] ) };
}

sub DESTROY { }

sub can {

    my ( $self, $key ) = @_;

    my $class = Scalar::Util::blessed( $self );
    return if !defined $class;

    return unless exists $self->{$key};

    my $method = "${class}::$key";

    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    return *{$method}{CODE}
      || Hash::Wrap::_generate_accessor( q[<<CLASS>>], $self, $method, $key );
}

1;
END

    _compile_from_tpl( \$class_template, \%dict )
      or _croak_about_code( \$class_template, "class $class" );

    if ( !!$attr->{-new} ) {
        my $name = $attr->{-new} =~ PerlIdentifier ? $1 : 'new';
        _build_constructor( $class, $name, { %$attr, -method => 1 } );
    }

    push @CARP_NOT, $class;
    $REGISTRY{$class} = {
        accessor_template =>
          _find_symbol( $class, "accessor_template", [ "SCALAR", undef ] ),
        validate => _find_symbol( $class, 'validate', [ 'REF', 'CODE' ] ),
    };

    Scalar::Util::weaken( $REGISTRY{$class}{validate} );

    return $class;
}

sub _build_constructor {

    my ( $package, $name, $args ) = @_;

    # closure for user provided clone sub
    my $clone;

    _croak( "cannot mix -copy and -clone" )
      if exists $args->{-copy} && exists $args->{-clone};

    my %dict = (
        package => $package,
        name    => $name,
        use     => [],
    );

    $dict{class} = do {

        if ( $args->{-method} ) {
            'shift;';
        }
        else {

            'q[' . $args->{-class} . '];';
        }
    };

    $dict{copy} = do {

        if ( $args->{-copy} ) {
            '$hash = { %{ $hash } };';
        }

        elsif ( exists $args->{-clone} ) {


            if ( 'CODE' eq ref $args->{-clone} ) {
                $clone = $args->{-clone};
                '$hash = $clone->($hash);';
            }
            else {
                push @{ $dict{use} }, q[use Storable ();];
                '$hash = Storable::dclone $hash;';
            }
        }
    };

    #<<< no tidy
    my $code = q[
    package <<PACKAGE>>;
    <<USE>>
    use Scalar::Util ();

    no warnings 'redefine';

    sub <<NAME>> (;$) {
      my $class = <<CLASS>>
      my $hash = shift // {};

      if ( 'HASH' ne Scalar::Util::reftype($hash) ) {
         require Carp;
         Carp::croak( "argument to <<PACKAGE>>::<<NAME>> must be a hashref" )
      }
      <<COPY>>
      bless $hash, $class;
    }
    1;
    ];
    #>>>

    _interpolate( \$code, \%dict );

    eval( $code )    ## no critic (ProhibitStringyEval)
      || _croak(
        "error generating constructor (as $name) subroutine: $@\n$code" );
}

sub _croak_about_code {

    my ( $code, $what ) = @_;

    my $error = $@;

    _line_number_code( $code );

    _croak( qq[error compiling $what: $error\n$$code] );
}

sub _line_number_code {

    my ( $code ) = @_;

    my $space = length( $$code =~ tr/\n// );
    my $line  = 0;
    $$code =~ s/^/sprintf "%${space}d: ", ++$line/emg;
}


# can't handle closures; should use Sub::Quote
sub _compile_from_tpl {
    my ( $code, $dict ) = @_;

    _interpolate( $code, $dict );

    if ( $DEBUG ) {
        my $code = $$code;
        _line_number_code( \$code );
        print STDERR $code;
    }

    eval( $$code );    ## no critic (ProhibitStringyEval)
}

sub _interpolate {

    my ( $tpl, $dict, $work ) = @_;

    $work = { loop => {} } unless defined $work;

    $$tpl =~ s{(\\)?\<\<(\w+)\>\>
              }{
                  if ( defined $1 ) {
                     "<<$2>>";
                  }
                  else {
                    my $key = lc $2;
                    my $v = $dict->{$key};
                    if ( defined $v ) {

                        $v = join( "\n", @$v )
                          if 'ARRAY' eq ref $v;

                        _croak( "circular interpolation loop detected for $key" )
                          if $work->{loop}{$key}++;
                        _interpolate( \$v, $dict, $work );
                        --$work->{loop}{$key};
                    $v;
                    }
                    else {
                        '';
                    }
                }
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

Hash::Wrap - create on-the-fly objects from hashes

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use Hash::Wrap;

  my $result = wrap_hash( { a => 1 } );
  print $result->a;  # prints
  print $result->b;  # throws

  # import two constructors, <cloned> and <copied> with different behaviors.
  use Hash::Wrap
    { -as => 'cloned', clone => 1},
    { -as => 'copied', copy => 1 };

  my $cloned = cloned( { a => 1 } );
  print $cloned->a;

  my $copied = copied( { a => 1 } );
  print $copied->a;

=head1 DESCRIPTION

B<Hash::Wrap> creates objects from hashes, providing accessors for
hash elements.  The objects are hashes, and may be modified using the
standard Perl hash operations and the object's accessors will behave
accordingly.

Why use this class? Sometimes a hash is created on the fly and it's too
much of a hassle to build a class to encapsulate it.

  sub foo () { ... ; return { a => 1 }; }

With C<Hash::Wrap>:

  use Hash::Wrap;

  sub foo () { ... ; return wrap_hash( { a => 1 ); }

  my $obj = foo ();
  print $obj->a;

Elements can be added or removed to the object and accessors will
track them.  If the object should be immutable, use the lock routines
in L<Hash::Util> on it.

There are many similar modules on CPAN (see L<SEE ALSO> for comparisons).

What sets B<Hash::Wrap> apart is that it's possible to customize
object construction and accessor behavior:

=over

=item *

It's possible to use the passed hash directly, or make shallow or deep copies of it.

=item *

Accessors can be customized so that accessing a non-existent element can throw an exception or return the undefined value.

=item *

On recent enough versions of Perl, accessors can be lvalues, e.g.

   $obj->existing_key = $value;

=back

=head1 USAGE

=head2 Simple Usage

C<use>'ing B<Hash::Wrap> without options imports a subroutine called
C<wrap_hash> which takes a hash, blesses it into a wrapper class and
returns the hash:

  use Hash::Wrap;

  my $h = wrap_hash { a => 1 };
  print $h->a, "\n";             # prints 1

The wrapper class has no constructor method, so the only way to create
an object is via the C<wrap_hash> subroutine. (See L</WRAPPER CLASSES>
for more about wrapper classes)  If C<wrap_hash> is called without
arguments, it will create a hash for you.

=head2 Advanced Usage

=head3 C<wrap_hash> is an awful name for the constructor subroutine

So rename it:

  use Hash::Wrap { -as => "a_much_better_name_for_wrap_hash" };

  $obj = a_much_better_name_for_wrap_hash( { a => 1 } );

=head3 The Wrapper Class name matters

If the class I<name> matters, but it'll never be instantiated
except via the imported constructor subroutine:

  use Hash::Wrap { -class => 'My::Class' };

  my $h = wrap_hash { a => 1 };
  print $h->a, "\n";             # prints 1
  $h->isa( 'My::Class' );        # returns true

Again, the wrapper class has no constructor method, so the only way to create
an object is via the C<wrap_hash> subroutine.

=head3 The Wrapper Class needs its own class constructor method

To generate a wrapper class which can be instantiated via its own
constructor method:

  use Hash::Wrap { -class => 'My::Class', -new => 1 };

The default C<wrap_hash> constructor subroutine is still exported, so

  $h = My::Class->new( { a => 1 } );

and

  $h = wrap_hash( { a => 1 } );

do the same thing.

To give the constructor method a different name:

  use Hash::Wrap { -class => 'My::Class',  -new => '_my_new' };

To prevent the constructor subroutine from being imported:

  use Hash::Wrap { -as => undef, -class => 'My::Class', -new => 1 };

=head3 A stand alone Wrapper Class

To create a stand alone wrapper class,

   package My::Class;

   use Hash::Wrap { -base => 1 };

   1;

And later...

   use My::Class;

   $obj = My::Class->new( \%hash );

It's possible to modify the constructor and accessors:

   package My::Class;

   use Hash::Wrap { -base => 1, -new => 'new_from_hash', -undef => 1 };

   1;

=head1 OPTIONS

B<Hash::Wrap> works at compile time.  To modify its behavior pass it
options when it is C<use>'d:

  use Hash::Wrap { %options1 }, { %options2 }, ... ;

Multiple options hashes may be passed; each hash specifies options for
a separate constructor or class.

For example,

  use Hash::Wrap
    { -as => 'cloned', clone => 1},
    { -as => 'copied', copy => 1 };

creates two constructors, C<cloned> and C<copied> with different
behaviors.

=head2 Constructor

=over

=item C<-as> => I<subroutine name>

Import the constructor subroutine with the given name. It defaults to C<wrap_hash>.

=item C<-copy> => I<boolean>

If true, the object will store the data in a I<shallow> copy of the
hash. By default, the object uses the hash directly.

=item C<-clone> => I<boolean> | I<coderef>

Store the data in a deep copy of the hash. if I<true>, L<Storable/dclone>
is used. If a coderef, it will be called as

   $clone = coderef->( $hash )

By default, the object uses the hash directly.

=back

=head2 Accessors

=over

=item C<-undef> => I<boolean>

Normally an attempt to use an accessor for an non-existent key will
result in an exception.  This option causes the accessor
to return C<undef> instead.  It does I<not> create an element in
the hash for the key.

=item C<-lvalue> => I<flag>

If non-zero, the accessors will be lvalue routines, e.g. they can
change the underlying hash value by assigning to them:

   $obj->attr = 3;

The hash entry I<must already exist> or this will throw an exception.

lvalue subroutines are only available on Perl version 5.16 and later.

If C<-lvalue = 1> this option will silently be ignored on earlier versions of Perl.

If C<-lvalue = -1> this option will cause an exception on earlier versions of Perl.

=back

=head2 Class

=over

=item C<-base> => I<boolean>

If true, the enclosing package is converted into a proxy wrapper class.  This should
not be used in conjunction with C<-class>.  See L</A stand alone Wrapper Class>.

=item C<-class> => I<class name>

A class with the given name will be created and new objects will be
blessed into the specified class by the constructor subroutine.  The
new class will not have a constructor method.

If not specified, the class name will be constructed based upon the
options.  Do not rely upon this name to determine if an object is
wrapped by B<Hash::Wrap>.

=item C<-new> => I<boolean> | I<Perl Identifier>

Add a class constructor method.

If C<-new> is a true boolean value, the method will be called
C<new>. Otherwise C<-new> specifies the name of the method.

=back

=head3 Extra Class Methods

=over

=item C<-defined> => I<boolean> | I<Perl Identifier>

Add a method which returns true if the passed hash key is defined or
does not exist. If C<-defined> is a true boolean value, the method will be called
C<defined>. Otherwise it specifies the name of the method. For
example,

   use Hash::Wrap { -defined => 1 };
   $obj = wrap_hash( { a => 1, b => undef } );

   $obj->defined( 'a' ); # TRUE
   $obj->defined( 'b' ); # FALSE
   $obj->defined( 'c' ); # FALSE

or

   use Hash::Wrap { -defined => 'is_defined' };
   $obj = wrap_hash( { a => 1 } );
   $obj->is_defined( 'a' );

=item C<-exists> => I<boolean> | I<Perl Identifier>

Add a method which returns true if the passed hash key exists. If
C<-exists> is a boolean, the method will be called
C<exists>. Otherwise it specifies the name of the method. For example,

   use Hash::Wrap { -exists => 1 };
   $obj = wrap_hash( { a => 1 } );
   $obj->exists( 'a' );

or

   use Hash::Wrap { -exists => 'is_present' };
   $obj = wrap_hash( { a => 1 } );
   $obj->is_present( 'a' );

=back

=head1 WRAPPER CLASSES

A wrapper class has the following characteristics.

=over

=item *

It has the methods C<DESTROY>, C<AUTOLOAD> and C<can>.

=item *

It will have other methods if the C<-undef> and C<-exists> options are specified. It may
have other methods if it is L<a stand alone class|/A stand alone Wrapper Class>.

=item *

It will have a constructor if either of C<-base> or C<-new> is specified.

=back

=head2 Wrapper Class Limitations

=over

=item *

Wrapper classes have C<DESTROY>, C<can> method, and
C<AUTOLOAD> methods, which will mask hash keys with the same names.

=item *

Classes which are generated without the C<-base> or C<-new> options do
not have a class constructor method, e.g C<< Class->new() >> will
I<not> return a new object.  The only way to instantiate them is via
the constructor subroutine generated via B<Hash::Wrap>.  This allows
the underlying hash to have a C<new> attribute which would otherwise be
masked by the constructor.

=back

=head1 LIMITATIONS

=head2 Lvalue accessors

Lvalue accessors are available only on Perl 5.16 and later.

=head2 Accessors for deleted hash elements

Accessors for deleted elements are not removed.  The class's C<can>
method will return C<undef> for them, but they are still available in
the class's stash.

=head1 SEE ALSO

Here's a comparison of this module and others on CPAN.

=over

=item L<Hash::Wrap> (this module)

=over

=item * core dependencies only

=item * only applies object paradigm to top level hash

=item * accessors may be lvalue subroutines

=item * accessing a non-existing element via an accessor
throws by default, but can optionally return C<undef>

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

=item L<Object::Accessor>

=over

=item * core dependencies only

=item * only applies object paradigm to top level hash

=item * accessors may be lvalue subroutines

=item * accessing a non-existing element via an accessor
returns C<undef> by default, but can optionally throw. Changing behavior
is done globally, so all objects are affected.

=item * accessors must be explicitly added.

=item * accessors may have aliases

=item * values may be validated

=item * invoking an accessor may trigger a callback

=back

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Hash-Wrap>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Wrap>

=back

=head2 Email

You can email the author of this module at C<DJERIUS at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-hash-wrap at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Hash-Wrap>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://gitlab.com/djerius/hash-wrap>

  https://gitlab.com/djerius/hash-wrap.git

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
#pod   my $result = wrap_hash( { a => 1 } );
#pod   print $result->a;  # prints
#pod   print $result->b;  # throws
#pod
#pod   # import two constructors, <cloned> and <copied> with different behaviors.
#pod   use Hash::Wrap
#pod     { -as => 'cloned', clone => 1},
#pod     { -as => 'copied', copy => 1 };
#pod
#pod   my $cloned = cloned( { a => 1 } );
#pod   print $cloned->a;
#pod
#pod   my $copied = copied( { a => 1 } );
#pod   print $copied->a;
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Hash::Wrap> creates objects from hashes, providing accessors for
#pod hash elements.  The objects are hashes, and may be modified using the
#pod standard Perl hash operations and the object's accessors will behave
#pod accordingly.
#pod
#pod Why use this class? Sometimes a hash is created on the fly and it's too
#pod much of a hassle to build a class to encapsulate it.
#pod
#pod   sub foo () { ... ; return { a => 1 }; }
#pod
#pod With C<Hash::Wrap>:
#pod
#pod   use Hash::Wrap;
#pod
#pod   sub foo () { ... ; return wrap_hash( { a => 1 ); }
#pod
#pod   my $obj = foo ();
#pod   print $obj->a;
#pod
#pod Elements can be added or removed to the object and accessors will
#pod track them.  If the object should be immutable, use the lock routines
#pod in L<Hash::Util> on it.
#pod
#pod There are many similar modules on CPAN (see L<SEE ALSO> for comparisons).
#pod
#pod What sets B<Hash::Wrap> apart is that it's possible to customize
#pod object construction and accessor behavior:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod It's possible to use the passed hash directly, or make shallow or deep copies of it.
#pod
#pod =item *
#pod
#pod Accessors can be customized so that accessing a non-existent element can throw an exception or return the undefined value.
#pod
#pod =item *
#pod
#pod On recent enough versions of Perl, accessors can be lvalues, e.g.
#pod
#pod    $obj->existing_key = $value;
#pod
#pod =back
#pod
#pod =head1 USAGE
#pod
#pod =head2 Simple Usage
#pod
#pod C<use>'ing B<Hash::Wrap> without options imports a subroutine called
#pod C<wrap_hash> which takes a hash, blesses it into a wrapper class and
#pod returns the hash:
#pod
#pod   use Hash::Wrap;
#pod
#pod   my $h = wrap_hash { a => 1 };
#pod   print $h->a, "\n";             # prints 1
#pod
#pod The wrapper class has no constructor method, so the only way to create
#pod an object is via the C<wrap_hash> subroutine. (See L</WRAPPER CLASSES>
#pod for more about wrapper classes)  If C<wrap_hash> is called without
#pod arguments, it will create a hash for you.
#pod
#pod =head2 Advanced Usage
#pod
#pod =head3 C<wrap_hash> is an awful name for the constructor subroutine
#pod
#pod So rename it:
#pod
#pod   use Hash::Wrap { -as => "a_much_better_name_for_wrap_hash" };
#pod
#pod   $obj = a_much_better_name_for_wrap_hash( { a => 1 } );
#pod
#pod =head3 The Wrapper Class name matters
#pod
#pod If the class I<name> matters, but it'll never be instantiated
#pod except via the imported constructor subroutine:
#pod
#pod   use Hash::Wrap { -class => 'My::Class' };
#pod
#pod   my $h = wrap_hash { a => 1 };
#pod   print $h->a, "\n";             # prints 1
#pod   $h->isa( 'My::Class' );        # returns true
#pod
#pod Again, the wrapper class has no constructor method, so the only way to create
#pod an object is via the C<wrap_hash> subroutine.
#pod
#pod =head3 The Wrapper Class needs its own class constructor method
#pod
#pod To generate a wrapper class which can be instantiated via its own
#pod constructor method:
#pod
#pod   use Hash::Wrap { -class => 'My::Class', -new => 1 };
#pod
#pod The default C<wrap_hash> constructor subroutine is still exported, so
#pod
#pod   $h = My::Class->new( { a => 1 } );
#pod
#pod and
#pod
#pod   $h = wrap_hash( { a => 1 } );
#pod
#pod do the same thing.
#pod
#pod To give the constructor method a different name:
#pod
#pod   use Hash::Wrap { -class => 'My::Class',  -new => '_my_new' };
#pod
#pod To prevent the constructor subroutine from being imported:
#pod
#pod   use Hash::Wrap { -as => undef, -class => 'My::Class', -new => 1 };
#pod
#pod =head3 A stand alone Wrapper Class
#pod
#pod To create a stand alone wrapper class,
#pod
#pod    package My::Class;
#pod
#pod    use Hash::Wrap { -base => 1 };
#pod
#pod    1;
#pod
#pod And later...
#pod
#pod    use My::Class;
#pod
#pod    $obj = My::Class->new( \%hash );
#pod
#pod It's possible to modify the constructor and accessors:
#pod
#pod    package My::Class;
#pod
#pod    use Hash::Wrap { -base => 1, -new => 'new_from_hash', -undef => 1 };
#pod
#pod    1;
#pod
#pod =head1 OPTIONS
#pod
#pod B<Hash::Wrap> works at compile time.  To modify its behavior pass it
#pod options when it is C<use>'d:
#pod
#pod   use Hash::Wrap { %options1 }, { %options2 }, ... ;
#pod
#pod Multiple options hashes may be passed; each hash specifies options for
#pod a separate constructor or class.
#pod
#pod For example,
#pod
#pod   use Hash::Wrap
#pod     { -as => 'cloned', clone => 1},
#pod     { -as => 'copied', copy => 1 };
#pod
#pod creates two constructors, C<cloned> and C<copied> with different
#pod behaviors.
#pod
#pod =head2 Constructor
#pod
#pod =over
#pod
#pod =item C<-as> => I<subroutine name>
#pod
#pod Import the constructor subroutine with the given name. It defaults to C<wrap_hash>.
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
#pod =back
#pod
#pod =head2 Accessors
#pod
#pod =over
#pod
#pod =item C<-undef> => I<boolean>
#pod
#pod Normally an attempt to use an accessor for an non-existent key will
#pod result in an exception.  This option causes the accessor
#pod to return C<undef> instead.  It does I<not> create an element in
#pod the hash for the key.
#pod
#pod =item C<-lvalue> => I<flag>
#pod
#pod If non-zero, the accessors will be lvalue routines, e.g. they can
#pod change the underlying hash value by assigning to them:
#pod
#pod    $obj->attr = 3;
#pod
#pod The hash entry I<must already exist> or this will throw an exception.
#pod
#pod lvalue subroutines are only available on Perl version 5.16 and later.
#pod
#pod If C<-lvalue = 1> this option will silently be ignored on earlier versions of Perl.
#pod
#pod If C<-lvalue = -1> this option will cause an exception on earlier versions of Perl.
#pod
#pod =back
#pod
#pod =head2 Class
#pod
#pod =over
#pod
#pod =item C<-base> => I<boolean>
#pod
#pod If true, the enclosing package is converted into a proxy wrapper class.  This should
#pod not be used in conjunction with C<-class>.  See L</A stand alone Wrapper Class>.
#pod
#pod =item C<-class> => I<class name>
#pod
#pod A class with the given name will be created and new objects will be
#pod blessed into the specified class by the constructor subroutine.  The
#pod new class will not have a constructor method.
#pod
#pod If not specified, the class name will be constructed based upon the
#pod options.  Do not rely upon this name to determine if an object is
#pod wrapped by B<Hash::Wrap>.
#pod
#pod =item C<-new> => I<boolean> | I<Perl Identifier>
#pod
#pod Add a class constructor method.
#pod
#pod If C<-new> is a true boolean value, the method will be called
#pod C<new>. Otherwise C<-new> specifies the name of the method.
#pod
#pod =back
#pod
#pod =head3 Extra Class Methods
#pod
#pod =over
#pod
#pod =item C<-defined> => I<boolean> | I<Perl Identifier>
#pod
#pod Add a method which returns true if the passed hash key is defined or
#pod does not exist. If C<-defined> is a true boolean value, the method will be called
#pod C<defined>. Otherwise it specifies the name of the method. For
#pod example,
#pod
#pod    use Hash::Wrap { -defined => 1 };
#pod    $obj = wrap_hash( { a => 1, b => undef } );
#pod
#pod    $obj->defined( 'a' ); # TRUE
#pod    $obj->defined( 'b' ); # FALSE
#pod    $obj->defined( 'c' ); # FALSE
#pod
#pod or
#pod
#pod    use Hash::Wrap { -defined => 'is_defined' };
#pod    $obj = wrap_hash( { a => 1 } );
#pod    $obj->is_defined( 'a' );
#pod
#pod =item C<-exists> => I<boolean> | I<Perl Identifier>
#pod
#pod Add a method which returns true if the passed hash key exists. If
#pod C<-exists> is a boolean, the method will be called
#pod C<exists>. Otherwise it specifies the name of the method. For example,
#pod
#pod    use Hash::Wrap { -exists => 1 };
#pod    $obj = wrap_hash( { a => 1 } );
#pod    $obj->exists( 'a' );
#pod
#pod or
#pod
#pod    use Hash::Wrap { -exists => 'is_present' };
#pod    $obj = wrap_hash( { a => 1 } );
#pod    $obj->is_present( 'a' );
#pod
#pod
#pod =back
#pod
#pod =head1 WRAPPER CLASSES
#pod
#pod A wrapper class has the following characteristics.
#pod
#pod =over
#pod
#pod =item *
#pod
#pod It has the methods C<DESTROY>, C<AUTOLOAD> and C<can>.
#pod
#pod =item *
#pod
#pod It will have other methods if the C<-undef> and C<-exists> options are specified. It may
#pod have other methods if it is L<a stand alone class|/A stand alone Wrapper Class>.
#pod
#pod =item *
#pod
#pod It will have a constructor if either of C<-base> or C<-new> is specified.
#pod
#pod =back
#pod
#pod =head2 Wrapper Class Limitations
#pod
#pod =over
#pod
#pod =item *
#pod
#pod Wrapper classes have C<DESTROY>, C<can> method, and
#pod C<AUTOLOAD> methods, which will mask hash keys with the same names.
#pod
#pod =item *
#pod
#pod Classes which are generated without the C<-base> or C<-new> options do
#pod not have a class constructor method, e.g C<< Class->new() >> will
#pod I<not> return a new object.  The only way to instantiate them is via
#pod the constructor subroutine generated via B<Hash::Wrap>.  This allows
#pod the underlying hash to have a C<new> attribute which would otherwise be
#pod masked by the constructor.
#pod
#pod =back
#pod
#pod =head1 LIMITATIONS
#pod
#pod =head2 Lvalue accessors
#pod
#pod Lvalue accessors are available only on Perl 5.16 and later.
#pod
#pod =head2 Accessors for deleted hash elements
#pod
#pod Accessors for deleted elements are not removed.  The class's C<can>
#pod method will return C<undef> for them, but they are still available in
#pod the class's stash.
#pod
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
#pod =item * accessing a non-existing element via an accessor
#pod throws by default, but can optionally return C<undef>
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
#pod =item L<Object::Accessor>
#pod
#pod =over
#pod
#pod =item * core dependencies only
#pod
#pod =item * only applies object paradigm to top level hash
#pod
#pod =item * accessors may be lvalue subroutines
#pod
#pod =item * accessing a non-existing element via an accessor
#pod returns C<undef> by default, but can optionally throw. Changing behavior
#pod is done globally, so all objects are affected.
#pod
#pod =item * accessors must be explicitly added.
#pod
#pod =item * accessors may have aliases
#pod
#pod =item * values may be validated
#pod
#pod =item * invoking an accessor may trigger a callback
#pod
#pod =back
#pod
#pod
#pod =back
