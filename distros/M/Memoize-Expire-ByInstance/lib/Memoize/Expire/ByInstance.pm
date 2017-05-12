{

    package Memoize::Expire::ByInstance;
    use 5.006002;
    use warnings;
    use strict;
    use Time::HiRes qw(time);
    use Scalar::Util qw(weaken);
    use constant FILE_SEPERATOR => chr(0x1C);

    our $VERSION = 0.500005;

    ############################################################################################
    ## Tie the hash to this class. Support passing a HASH => \$hashref argument to permit
    ## chaining various tied-hashes together
    ############################################################################################
    sub TIEHASH
    {
        my ( $proto, %opts ) = @_;
        my $class = ref($proto) || $proto;

        my $default_lifetime = $opts{LIFETIME} || 0;
        my $default_num_uses = $opts{NUM_USES} || 0;

        my $self =
          { _meta => { _hash_data => {}, _expire => { _default => { lifetime => $default_lifetime, num_uses => $default_num_uses, }, }, } };
        $self->{_hash} = ( exists( $opts{HASH} ) && ref( $opts{HASH} ) eq 'HASH' ) ? $opts{HASH} : {};
        bless( $self, $class );

        # Memoize doesn't deal well with "memoize('Package::method', ...)"; hence it must be tied and memoized
        # in the same package that its used in... kinda annoying for unit testing... but handy in that I can use caller
        $self->__insert_destroy_wrapper( (caller)[0] ) if( $opts{AUTO_DESTROY} );
        $self->_argument_seperator( $opts{ARGUMENT_SEPERATOR} || FILE_SEPERATOR );

        return $self;
    }

    ############################################################################################
    ## Reset num_uses and last_set_time, and store the new value.
    ############################################################################################
    sub STORE
    {
        my ( $self, $key, $value ) = @_;
        ( my $instance_id, $key ) = $self->_split_instance($key);
        return unless($key);

        $self->{_meta}->{_hash_data}->{$key}->{last_set_time} = time();
        $self->{_meta}->{_hash_data}->{$key}->{num_uses}      = 0;

        $self->{_hash}->{$key} = $value;
        return $value;
    }

    ############################################################################################
    ## Increment num_uses, and return the value for the specified key
    ############################################################################################
    sub FETCH
    {
        my ( $self, $key ) = @_;
        ( my $instance_id, $key ) = $self->_split_instance($key);
        return unless($key);

        $self->{_meta}->{_hash_data}->{$key}->{num_uses}++;

        return $self->{_hash}->{$key};
    }

    ############################################################################################
    ## Return a true value if the key both exists AND has not expired for the instance fetching
    ## it
    ############################################################################################
    sub EXISTS
    {
        my ( $self, $key ) = @_;
        ( my $instance_id, $key ) = $self->_split_instance($key);
        return unless($key);

        return if( $self->_key_has_expired( $instance_id, $key ) );
        return ( exists( $self->{_hash}->{$key} ) );
    }

    ############################################################################################
    ## Delete a member from the hash
    ############################################################################################
    sub DELETE
    {
        my ( $self, $key ) = @_;
        ( my $instance_id, $key ) = $self->_split_instance($key);
        return unless($key);

        delete( $self->{_meta}->{_hash_data}->{$key} ) if( exists( $self->{_meta}->{_hash_data}->{$key} ) );
        return ( delete( $self->{_hash}->{$key} ) );
    }


    ############################################################################################
    ## Return next key in hash
    ############################################################################################
    sub NEXTKEY
    {
        my ($self) = @_;
        return ( each( %{ $self->{_hash} } ) );
    }


    ############################################################################################
    ## Return first key in hash
    ############################################################################################
    sub FIRSTKEY
    {
        my ($self) = @_;
        my @keys = keys( %{ $self->{_hash} } );
        return ( each( %{ $self->{_hash} } ) );
    }


    ############################################################################################
    ## Delete all members from hash
    ############################################################################################
    sub CLEAR
    {
        my ($self) = @_;

        map { delete( $self->{_meta}->{_hash_data}->{$_} ) } keys %{ $self->{_hash} };
        %{ $self->{_hash} } = ();
        return;
    }

    ############################################################################################
    ## Return scalar equivilency of hash
    ############################################################################################
    sub SCALAR
    {
        my ($self) = @_;
        return ( scalar %{ $self->{_hash} } );
    }

    ############################################################################################
    ## Register an instance with this tied hash, which will be used for lifetime/num_uses
    ## expiration uniqueness
    ############################################################################################
    sub register
    {
        my ( $self, $instance_id, %opts ) = @_;
        my $lifetime = defined( $opts{lifetime} ) ? $opts{lifetime} : $self->{_meta}->{_expire}->{_default}->{lifetime};
        my $num_uses = defined( $opts{num_uses} ) ? $opts{num_uses} : $self->{_meta}->{_expire}->{_default}->{num_uses};

        ## we make instance_id a string, because when its Memoized, the
        ## key will be be a string concatination of arguments
        $instance_id = "$instance_id";

        $self->{_meta}->{_expire}->{$instance_id}->{lifetime} = $lifetime
          if( $lifetime != $self->{_meta}->{_expire}->{_default}->{lifetime} );
        $self->{_meta}->{_expire}->{$instance_id}->{num_uses} = $num_uses
          if( $num_uses != $self->{_meta}->{_expire}->{_default}->{num_uses} );
        return $self;
    }

    ############################################################################################
    ## Unregister an instance from this tied hash, freeing the memory used in the hash for it
    ############################################################################################
    sub unregister
    {
        my ( $self, $instance_id ) = @_;

        ## we make instance_id a string, because when its Memoized, the
        ## key will be be a string concatination of arguments
        $instance_id = "$instance_id";

        if( exists( $self->{_meta}->{_expire}->{$instance_id} ) ) {
            ## undef explicitely to force immediate freeing of memory
            undef( $self->{_meta}->{_expire}->{$instance_id} );
            delete( $self->{_meta}->{_expire}->{$instance_id} );
        }
        return;
    }

    ############################################################################################
    ## Test if a key has expired for the particular instance testing EXISTS
    ############################################################################################
    sub _key_has_expired
    {
        my ( $self, $instance_id, $key ) = @_;

        # We will assume that if we do not have current _hash_data for the underlying storage
        # that it has expired.
        if( exists( $self->{_meta}->{_hash_data}->{$key} ) ) {
            my $last_set_time = $self->{_meta}->{_hash_data}->{$key}->{last_set_time};
            my $num_uses      = $self->{_meta}->{_hash_data}->{$key}->{num_uses};

            my $lifetime_lookup_id = '_default';
            my $num_uses_lookup_id = '_default';

            if( exists( $self->{_meta}->{_expire}->{$instance_id} ) ) {
                $lifetime_lookup_id = $instance_id if( exists( $self->{_meta}->{_expire}->{$instance_id}->{lifetime} ) );
                $num_uses_lookup_id = $instance_id if( exists( $self->{_meta}->{_expire}->{$instance_id}->{num_uses} ) );
            }

            my $max_lifetime = $self->{_meta}->{_expire}->{$lifetime_lookup_id}->{lifetime};
            my $max_num_uses = $self->{_meta}->{_expire}->{$num_uses_lookup_id}->{num_uses};

            return 1 if( ( $max_lifetime > 0 ) && ( time() >= $last_set_time + $max_lifetime ) );
            return 1 if( ( $max_num_uses > 0 ) && ( $num_uses >= $max_num_uses ) );
        }
        return;
    }

    ############################################################################################
    ## split the key apart on the ascii File-Seperater character used by Memoize when creating hash-keys
    ############################################################################################
    sub _split_instance
    {
        my ( $self, $key ) = @_;
        (my $instance_id, $key ) = split( $self->_argument_seperator(), $key, 2 );
        return($instance_id, $key) if($key);
        return( $instance_id, $instance_id ); ## XXX Hack, wont work if the key you are looking for contains argumement seperators itself
    }

    ############################################################################################
    ## get/set the seperator applicable to keys being inserted into our hash.
    ############################################################################################
    sub _argument_seperator
    {
        my ( $self, $value ) = @_;
        $self->{_meta}->{_argument_seperator} = $value if( defined($value) );
        return $self->{_meta}->{_argument_seperator};
    }

    ############################################################################################
    ## Attempt to insert a DESTROY method into the package that tied us. Wrap any existing.
    ############################################################################################
    sub __insert_destroy_wrapper
    {
        my ( $self, $class ) = @_;

        my $weakself = $self;
        weaken($weakself);
        my $sub = sub {return};

        no strict 'refs';
        $sub = *{ '::' . $class . '::DESTROY' }{CODE} if( defined( *{ '::' . $class . '::DESTROY' }{CODE} ) );
        use strict;

        no strict 'refs';
        no warnings 'redefine';
        *{ '::' . $class . '::DESTROY' } = sub {
            my ($this) = @_;
            $weakself->unregister("$this") if( defined($weakself) );
            return $sub->(@_);
        };
        use warnings;
        use strict;

        return;
    }
}
1;
__END__

=head1 NAME

Memoize::Expire::ByInstance - A Memoize plugin which provides per-class-instance expiration of memoized data.

=head1 VERSION

Version 0.5

=head1 SYNOPSIS

 ### Specify a per-instance maximum cache duration, while only ever calling the underlying function when actually
 ### needed; i.e. When we've not seen those arguments before, or whenever a method is called upon an instance
 ### who's lifetime or num_uses has been exceeded.
 {
    package Foo;
    use Memoize;
    use Memoize::Expire::ByInstance;

    tie my %foo => 'Memoize::Expire::ByInstance', LIFETIME => 30, NUM_USES => 100, AUTO_DESTROY => 1;
    memoize('my_class_method', SCALAR_CACHE => [ 'HASH' => \%foo ], LIST_CACHE => [ 'MERGE' ]);

    ## This is a class method, not an instance method. It does NOT use any per-instance data.
    sub my_class_method
    { 
        my ($self, $val1, $val2) = @_;
        return( something($val1) + something_else($val2) );
    }

    sub new 
    { 
        my ($proto, %args) = @_;
        my $class = ref($proto) || $proto;
        my $self = bless(\%args, $class);

        ### Register this specific instances idea of "too old"
        (tied %foo)->register("$self", lifetime => $args{lifetime}, num_uses => $args{num_uses});

        return $self;
    }
 }

 my $needs_fresh_data  = Foo->new( lifetime => 1, num_uses => 10 ); 
 my $can_use_old_data = Foo->new( lifetime => 300, num_uses => 10000 );
 my $will_rely_on_default_ages = Foo->new();

 # Calls on this instance will always get data less than 1 second old, or less than 10 uses old
 $needs_fresh_data->my_class_method( 1, 2 );

 # Calls on this instance will always get data less than 300 second old, or less than 10000 uses old
 # Since we just called my_class_method on $needs_fresh_data, it will not be invoked this time.
 $can_use_old_data->my_class_method( 1, 2 );

 # Calls on this instance will always get data less than 30 second old, or less than 100 uses old (the defaults specified when first tied)
 # Since we just called my_class_method on $needs_fresh_data, it will not be invoked this time.
 $will_rely_on_default_ages->my_class_method( 1, 2 );

 sleep(2);

 # Still good, my_class_method is not called. 
 $can_use_old_data->my_class_method( 1, 2 );

 # Still good, my_class_method is not called
 $will_rely_on_default_ages->my_class_method( 1, 2 );

 # 2 seconds > 1 second; will invoke my_class_method again.
 $needs_fresh_data->my_class_method( 1, 2 );

Note that ALL calls to "my_class_method" regardless of which instance they were called upon, are Memoized as 
though they're only arguments had been C<(1, 2)>. Calls on any instance will bypass the expensive method
invocation as long as that method has been called with the same (non-instance) arguments recently enough.

=head1 DESCRIPTION

Memoize::Expire::ByInstance is a plug-in module for Memoize which supports memoization of class-methods and allows you to set their
maximums for expiration on a per-instance bases.

Memoize works by caching the returend value of a function invocation in a hash of ($arguments => $returned_value). 
On subsequent calls to that function, if the arguments are identical, the $returned_value is returned from the hash instead of 
from calling the function again.

Because you often only want to cache for a brief period of time, of a limited number of uses, there exists a module called
Memoize::Expire. Memoize and Memoize::Expire typically do what you want 90% of the time. 

However, in the case of class-methods,  you frequently have do extra work to 
obtain the benefits of memoization. However, this still proves insufficient for cases where you 
would like to allow your object to provide customizable expiration/timeout values on a per-instance bases. 

If you tie a hash to Memoize::Expire for each instance, you lose the benefit of class-method memoization, and
if you tie a hash to Memoize::Expire for the entire class, you are unable to have per-instance timeout/expirations. 

When you want/need BOTH class-method memoization AND per-instance timeout/expiration limits, you will need to use Memoize::Expire::ByInstance (this module.)

 ### OPTION A: 
 ### All instances expire after 30 seconds, or 100 uses. It is not customizable. 
 {
    package Foo;
    use Memoize;
    use Memoize::Expire;

    sub normy { shift; return( join(chr(0x1C), @_) ) };
    tie my %foo => 'Memoize::Expire', LIFETIME => 30, NUM_USES => 100;
    memoize('my_class_method', SCALAR_CACHE => [ 'HASH' => \%foo ], LIST_CACHE => [ 'MERGE' ], NORMALIZER => 'normy');

    ## This is a class method, not an instance method. It does NOT use any per-instance data.
    sub my_class_method
    { 
        my ($self, $val1, $val2) = @_;
        return( something($val1) + something_else($val2) );
    }

    sub new 
    { 
        my ($proto, %args) = @_;
        my $class = ref($proto) || $proto;
        my $self = bless(\%args, $class);

        return $self;
    }
 }

 ### OPTION B:
 ### All instances have a unique hash, regardless of NORMALIZER trickery or scoping fun.
 {
    package Foo;
    use Memoize;
    use Memoize::Expire;


    ## This is a class method, not an instance method. It does NOT use any per-instance data.
    sub my_class_method
    { 
        my ($self, $val1, $val2) = @_;
        return( something($val1) + something_else($val2) );
    }

    sub new 
    { 
        my ($proto, %args) = @_;
        my $class = ref($proto) || $proto;
        my $self = bless(\%args, $class);

        ## unique hash, re-memoized, no joy
        ## If you use %Foo::foo instead, you'll just nuke the contents of it, and reset the expiration
        ## every time the class is re-instanced.
        tie my %Foo => 'Memoize::Expire', LIFETIME => $self->{lifetime}, NUM_USES => $self->{num_uses}; 
        memoize('my_class_method', SCALAR_CACHE => [ 'HASH' => \%foo ], LIST_CACHE => [ 'MERGE' ]);
        return $self;
    }
 }



=head1 SUMMARY

=over

=item Somewhere in the package-scope of your class:

C<tie >I<HASH>C< =E<gt> Memoize::Expire::ByInstance, >I<OPTIONS>

=over

=item HASH

This is a package-scoped hash.

=item OPTIONS to tie

=over

=item LIFETIME

Lifetime, in seconds, that the hashed value will be used by default before re-invoking the memoized method.

=item NUM_USES

Default number of times the hashed value may be retrieved before re-invoking the memoized method. 

=item AUTO_DESTROY

Attempt to automatically update the symbol table of your class to insert the requisite DESTROY subroutine, this will
preserve, and serve as a wrapper around, any existing DESTROY subroutine definition. 

=item ARGUMENT_SEPERATOR

Specifify an alternative argument seperator. By default Memoize seperates arguments via 0x1C. If you use something else, via a NORMALIZER function, you must
specify what you have chosen to use via this option to tie. 

Example: 

 ## just for the sake of insanity, I have decided 
 ## to split via the single character 'A' 
 sub normy 
 (
    return( join('A', map { "$_" } @_) );
 }

 tie my %hash, 'Memoize::Expire::ByInstance', ARGUMENT_SEPERATOR => 'A';
 memoize('my_method', SCALAR_CACHE => [ HASH => \%hash ], LIST_CACHE => [ 'MERGE' ], NORMALIZER => 'normy');

=back

=back

=item Somehwere in object initialization

C<(tied >I<HASH>C<)-E<gt>register(>I<SELF>C<, >I<OPTIONS>C<);>

=over

=item tied HASH

Is the hash you tied previously within package scope

=item SELF 

Is a string-representable blessed reference to the newly created instance, or string representation of the instance.
This must be unique to the instance, and must be identical to the string representation of the first argument passed 
to an instance method.

Said in english, C<$self>, or C<"$self">, so long as the string representation of C<$self> is guaranteed to be unique per instance.

If you have employed something like C<use overload q("") =E<gt> \&some_thing>, it must be guaranteed to be unique per instance.

Obviously there is zero point to using this with singletons. (multitons sure, but not singletons) 

=item OPTIONS to register

A hash with either or both keys "lifetime", or "num_uses".

=over

=item lifetime

Lifetime, in seconds, that a hashed value may be retrieved before calls to this instance will require re-invoking the memoized method.

=item num_uses

Maximum number of times a hashed value may be retrieved before calls to this instance will require re-invoking the memoized method.

=back

=back

=item Somehwere in object destruction 

C<(tied >I<HASH>C<)-E<gt>unregister(>I<SELF>C<);>

=over

=item tied HASH (same as with register)

Is the hash you tied previously within package scope, 

=item SELF (same as with register)

See the description of SELF for register above. 

=back

=back

=head1 INTERFACES

All required interfaces to tie to a hash.

=over

=item TIEHASH

=item SCALAR

=item EXISTS

=item FIRSTKEY

=item NEXTKEY

=item STORE

=item FETCH

=item DELETE

=item CLEAR

=back

There are the following additional interfaces on the inner-reference:

=over

=item register(SELF, OPTIONS)

=item unregister(SELF)

=back


=head1 CAVEATS

=over

=item This package can only be used "out of the box" for class-methods.

Class methods are methods that do not use any instance data; and hence would return the same value
for the same arguments, regardless of the state of any class instance they can be called upon. 

Instance methods are methods which use instance-data, e.g any information which only that particular instance has available. If a method uses anything that looks like
C<$self-E<gt>{foo}>, or C<$self-E<gt>some_accessor()>, it is an instance method.

To use a package-scoped Memoized cache for instance methods, you must provide a NORMALIZER
function to C<memoize> that will correctly take all directly or indirectly used instance-data
into account when creating hash-keys. 

e.g.

 {
    package Foo;
    use Memoize;
    use Memoize::Expire::ByInstance;

    tie my %foo, 'Memoize::Expire::ByInstance', LIFETIME => 120, NUM_USES => 1000, AUTO_DESTROY => 1;
    memoize('my_instance_method', SCALAR_CACHE => [ HASH => \%foo ], LIST_CACHE => [ 'MERGE' ], NORMALIZER => 'instance_normalizer' );

    ## Treats instance data as "arguments" for the purpose of hashing. 
    ## preserves "$self" for Memoize::Expire::ByInstance
    sub instance_normalizer
    { 
        my ($self, @args) = @_;
        return( join(chr(0x1C), "$self", $self->{foo}, $self->{bar}, $self->{baz}, @args) );
    }

    ## Uses $self->{foo}, $self->{bar}, $self->{baz}, which is instance data. 
    sub my_instance_method
    {
        my ($self, @args) = @_;
        return( $self->{foo} + $self->{bar} + $self->{baz} + something(@args) );
    }

    # ...
 }

I<This is true for any use of Memoize for instance methods, not just for use with this package>
I<When not using this package, you would want to omit C<$self> from the join> 

=item May conflict with NORMALIZER 

Hashes tied to this class will not work with NORMALIZER unless the specified NORMALIZER function does NOT strip the C<$self> element from the head of the argument list.
The stringified C<$self> is required for per-instance expiration.

Also, the NORMALIZER function must seperate arguments via the 0x1C character, or you must specify the ARGUMENT_SEPERATOR option when tie'ing.

=item Does NOT do any sanity checking of first-argument

Will not verify the first argument to a method was actually a stringified representation of C<$self>, if you call
a class method without the C<$self-E<gt>> prefix, the first argument will get discarded, and so will result in erroneous memoization hits.

e.g. B<DON'T DO THIS>:

 tie my %foo => 'Memoize::Expire::ByInstance', LIFETIME => 30, NUM_USES => 100;
 memoize('my_class_method', LIST_CACHE => [ 'HASH' => \%foo ], SCALAR_CACHE => [ 'MERGE' ]);

 sub my_class_method
 { 
    my ($val1, $val2) = @_;
    return( something($val1) + something($val2) );
 }

 sub some_other_method
 {
    my ($self) = @_;
    my $f = my_class_method(1, 2); # missing $self->, will memoize as though I had called my_class_method(2). 
    my $b = my_class_method(5, 2); # also memoized as though I had called my_class_method(2) 
 }

=item Failure to unregister on DESTROY will leak memory

Every registered instance will have memory used to track that instance's lifetime and num_uses. If the instance is destroyed, 
but never unregistered, those resources will never be freed. Since cache-expiration is only really useful for long-running
processes, it is likely this leakage could become a critical bug in your application.

=item AUTO_DESTROY uses a closure

The dangling reference is weakened via Scalar::Util::weaken; but may still leak in rare cases. (and of course, this means that weaken must be supported)

=back

=head1 SEE ALSO

L<Memoize>, L<Memoize::Expire>, L<Memoize::ExpireLRU>, L<Tie::Hash>, L<perltie>

=head1 AUTHOR

Jamie Beverly, C<< <jbeverly at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-memoize-expire-byinstance at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memoize-Expire-ByInstance>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Memoize::Expire::ByInstance


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memoize-Expire-ByInstance>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Memoize-Expire-ByInstance>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Memoize-Expire-ByInstance>

=item * Search CPAN

L<http://search.cpan.org/dist/Memoize-Expire-ByInstance/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Mark-Jason Dominus ("mjd-perl-memoize+@plover.com"), Plover Systems co. for the always awesome Memoize. 

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jamie Beverly.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
