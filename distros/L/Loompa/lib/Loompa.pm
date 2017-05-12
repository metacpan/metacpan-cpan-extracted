package Loompa;
use strict;
use warnings;

use Carp;

=head1 NAME

Loompa - Lightweight object-oriented miniature Perl assistant.

=head1 VERSION

Version 0.51

=cut

our $VERSION = '0.51';

=head1 WARNING

This code is only here because some legacy code depends on it.  Do not use it
in new code.  Use L<Moose> if you want an object/class builder.

=head1 SYNOPSIS

    package MyCat;
    use base qw/ Loompa /;

    sub methods {
        [ qw/ name color temperment /]
    }

    sub init {
        my $self = shift;
        $self->color( 'black' ) if $self->name eq 'Boris'; 
        return $self;
    }

    # in a nearby piece of code ...
    use MyCat;

    my $cat = MyCat->new({
        name        => 'Boris',
        temperment  => 'evil',
    });

    print $cat->name;       # "Boris"
    print $cat->temperment; # "evil"
    print $cat->color;      # "black"

=head1 METHODS

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 new([ \%properties ])

Class method.  C<\%properties> is optional.  If provided, hash keys will be
taken as property names and hash values as property values.

It is an error to supply a property for which you have not also created an
accessor method.  In other words, if you do something like this:

    package Cat;
    use base 'Loompa';
    my $cat = Cat->new({ whiskers => 'long' });

In this case, Loompa will C<croak> with "Method 'whiskers' not defined for
object."

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# contruct a new object and take all incoming arguments as
# method/value pairs
sub new {
    my $class = shift;
    my( $properties ) = @_;

    $__PACKAGE__::LOOMPA_IS_BUILDING_ME = 1;
    croak 'Argument to constructor must be hash reference'
        if $properties and ref $properties ne 'HASH';

    my $self = bless {}, $class;
    $self->make_methods( $self->methods )
        if $self->can( 'methods' );
    while( my( $property, $value ) = each %$properties ) {
        croak qq/Method "$property" not defined for object; caller: /
            . join ':' => caller
            unless $self->can( $property );
        $self->$property( $value );
    }
    $self->set_method_defaults;
    $__PACKAGE__::LOOMPA_IS_BUILDING_ME = 0;

    $self->init( $properties );
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 init()

Blank initializer; may be overridden.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub init {
    my $self = shift;
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 check_methods( \@methods ) OR check_methods( \%methods )

Class and object method; enforces API.  One of C<\@methods> or C<\%methods> is
required.  If supplied, C<\@methods> must be a list of words.  If supplied,
C<\%methods> must be a hash reference, with keys as words and values as one of
the following:

=over 4

=item * <undef>, in which case the default getter/setter method will be used.

=item * <scalar value>, in which case the default getter/setter method will be used, and <scalar value> used as its default value.

=item * <coderef>, in which case <coderef> will be used instead of the default getter/setter.

=back

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# XXX pass { undef_ok => 1 } as $_options if you want $methods to be optional
sub check_methods {
    my $proto = shift;
    my( $methods, $_options ) = @_;

    if( $_options and $_options->{ undef_ok }) {
        return unless $methods;
    }
    else {
        croak '$methods is required' unless $methods;
    }

    my $error = 'API error:  please read the documentation for check_methods()';
    if( ref $methods eq 'ARRAY' ) {
        for( @$methods ) {
            croak $error .' (invalid method name)'
                if not defined $_
                or $_ eq ''
                or $_ =~ /\W/
                or $_ =~ /^\d/; # FIXME duplicated
        }
        return scalar @$methods;
    }
    elsif( ref $methods eq 'HASH' ) {
        croak $error .' (invalid hash reference)'
            unless %$methods;
        while( my( $key, $value ) = each %$methods ) {
            croak $error .' (invalid method name)'
                if not defined $key
                or $key eq ''
                or $key =~ /\W/
                or $key =~ /^\d/; # FIXME duplicated
            croak $error .' (invalid hash reference)'
                if defined $value and ref $value and ref $value ne 'CODE';
        }
        return scalar keys %$methods;
    }
    else {
        croak $error .' (invalid data type: argument to make_methods() must be arrayref or hashref)'
    }
    die 'Should never get here';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 make_methods( \@methods, [ $subref ], \%options ) OR make_methods( \%methods, undef, \%options )

Class and object method.  Makes methods for items in C<$methods>.

If <$methods> is an array reference, one method will be created for each name
in the list.  If supplied, C<$subref> must be a subroutine reference, and will
be used in place of the standard setter/getter.

If <%options> is provided, these are legal values:

=over 4

=item override_existing

Loompa's default behavior is to create methods only once, thereafter returning
before the construction step.  If you set C<override_existing> to true, each
method provided will be constructed anew.

=item object 

Loompa's default behavior is to pass the object in method-call style.

This is probably undesired behavior in a base class that defines many custom
class methods. Setting the 'object' value to a package name will override the
default passed-in object and provide that instead. Note that this is done
through a closure and may not be reasonable on your memory usage if you want to
define lots of methods.

You can also do dirtier things with this option, but I'm going to refrain from
describing them.

=back

if C<$methods> is a hash reference, the key/value pair will be understood as
C<$method_name> and C<$method_subroutine>.  For example:

    CatClass->make_methods({
        boris   => undef,
        sasha   => $method_cat,
        shaolin => $method_fat_cat,
    });
    my $cat = CatClass->new;
    $cat->boris;    # calls default setter/getter
    $cat->sasha;    # calls the method referenced by C<$method_cat>
    $cat->shaolin;  # calls the method referenced by C<$method_fat_cat>

In this case, 

PLEASE NOTE that the second argument to your custom subroutine will be the name
of the subroutine as it was called.  In other words, you should write something
like this:

    package MyClass;
    use base qw/ Loompa /;

    my $color_method = sub {
        my $self = shift;
        my( $name, $emotion ) = @_;
        return "My name is '$name' and I am '$emotion.'";
    };
    MyClass->make_methods( 'orange', 'brown', $color_method );

    MyClass->orange( 'happy' ); ## "My name is 'orange' and I am 'happy.'"
    MyClass->brown( 'sad' );    ## "My name is 'brown' and I am 'sad.'"

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub make_methods {
    my $proto = shift;
    my( $methods, $subref, $options ) = @_;

    return unless $methods; # XXX does this make undef_ok obsolete?
    $proto->check_methods( $methods, { undef_ok => 1 });
    if( ref $methods eq 'ARRAY' ) {
        $proto->_make_method( $_, $subref, $options )
            for @$methods;
    }
    elsif( ref $methods eq 'HASH' ) {
        while( my( $property, $prototype ) = each %$methods ) {
            $proto->_make_method( $property, $prototype, $options );
        }
    }
    return $proto;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# create an accessor method $field in the calling package
# Creates a getter/setter method for C<$name>.  If supplied, C<$subref> must be a
# subroutine reference, and will be used in place of the standard setter/getter.
sub _make_method {
    my $proto = shift;
    my( $name, $prototype, $options ) = @_;

    $options ||= {}; # makes it easier to evaluate later
    croak 'Second argument, if supplied, must be scalar value or subroutine reference'
        if defined $prototype and ( ref $prototype and not ref $prototype eq 'CODE' );

    my( $default, $subref );
    if( ref $prototype eq 'CODE' ) {
        $subref = $prototype;
    }

    my $package = ref $proto || $proto;
    return if defined &{ $package ."::$name" } and not $options->{ override_existing };

    no warnings qw/ redefine /;
    no strict qw/ refs /;
    if( $subref ) {
        if ($options->{object}) {
            my $object = $options->{object};
            *{ $package ."::$name" } = sub { shift; $subref->( $object, $name, @_ )};
        } else {
            *{ $package ."::$name" } = sub { $subref->( shift, $name, @_ )};
        }
    }
    else {
        if ($options->{object}) {
            my $object = $options->{object};
            *{ $package ."::$name" } = sub {
                shift;
                my $self = $object;

                return $self->{ $name } unless @_;
                $self->{ $name } = shift;
                croak 'Please pass only one value'
                if @_;
                $self->{ $name };
            };
        } else { 
            *{ $package ."::$name" } = sub {
                my $self = shift;

                return $self->{ $name } unless @_;
                $self->{ $name } = shift;
                croak 'Please pass only one value'
                if @_;
                $self->{ $name };
            };
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 set_method_defaults()

Object method; sets default values for accessors, as defined by local
C<methods> method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub set_method_defaults {
    my $self = shift;

    return
        unless $self->can( 'methods' ) and ref $self->methods and ref $self->methods eq 'HASH';

    my %properties = %{ $self->methods };
    while( my( $property, $value ) = each %properties ) {
        next if defined $self->$property;
        $self->$property( $value )
            if defined $value;
    }
    $self;
}


'loompa';

__END__

=head1 The generated code

The accessor method created by default is bog-standard:  it first sets the
object's property to the value of the first parameter you pass, then returns
that value:

    $cat->name( 'Natasha' );
    $cat->name([ 'Double', 'barelled' ]);

This includes C<undef>:

    $cat->name( undef );
    print $cat->name;   # undef

=head1 Changing defaults

Loompa is flexible.  You can give accessors default initial values and use your
own custom code in place of the default setter/getter method.  You can even do
both at once!

=head2 Providing default values

By default each object property accessed by a Loompa-generated method has no
value.  Literally C<undef>.  Most of the time this is what you want.  It's easy
to give properties default values, though.  Use a hash instead of an array in
your C<methods> method, and pass in a new scalar value.

    package MyCat;
    use base qw/ Loompa /;

    sub methods {
        {
            name     => undef,
            whiskers => 'long',
        }
    }

Now each C<MyCat> object will have long whiskers ...

    # in a nearby piece of code ...
    use MyCat;

    my $boris = MyCat->new({
        name        => 'Boris',
    });

    print $boris->name;       # "Boris"
    print $boris->whispers;   # "long"

... unless you tell it otherwise:

    my $sasha = MyCat->new({
        name        => 'Sasha',
        whispers    => 'bushy',
    });

    print $sasha->name;       # "Boris"
    print $sasha->whispers;   # "bushy"

Note that this only works for B<scalar> values.  References of any kind will
not be understood.

=head2 Changing the default method

Sometimes you need more generic factory code.  Or, I do anyway.  Loompa makes
this easy.  First, you define your common method:

    package MyWidget;
    use base qw/ Loompa /;

    sub input_method {
        my $self = shift;
        my $name = shift;  ## notice this
        
        $name =~ /^input_(\w+)$/;  # captures "text" out of "input_text"
        my $type = $1;
        return qq|<input type="$type" />|;
    }

Then pass is as the second parameter in your C<methods> method.

    sub methods {
        [ qw/ input_text input_hidden /],
        \&input_method
    }

You can get more elaborate if you want and combine all these methods:

    sub methods {
        {
            name        => 'Boris',
            tail        => 'long',
            color       => undef,
            temperment  => sub cat_esp{ ... do stuff ... },
        }
    }

=head1 MAINTAINER

Hans Dieter Pearcey C<< <hdp@cpan.org> >>

=head1 BUGS

I strive for perfection but am, in fact, mortal.  Please report any bugs or feature requests to C<bug-loompa at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Loompa>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Loompa

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Loompa>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Loompa>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Loompa>

=item * Search CPAN

L<http://search.cpan.org/dist/Loompa>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Erik Hollensbe for a nice way to get the names of custom subroutines.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Randall Hansen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
