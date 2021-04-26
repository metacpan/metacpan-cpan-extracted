package Finance::Alpaca::Types 0.9900 {
    use strictures 2;
    use Type::Library -base;
    use Types::Standard -types;
    use Type::Tiny::Class;
    use Time::Moment;
    our @EXPORT = qw[Timestamp];

    # Type::Tiny::Class is a subclass of Type::Tiny for creating
    # InstanceOf-like types. It's kind of better though because
    # it does cool stuff like pass through $type->new(%args) to
    # the class's constructor.
    #
    my $dt = __PACKAGE__->add_type(
        Type::Tiny::Class->new( name => 'Timestamp', class => 'Time::Moment', ) );

    # Can't just use "plus_coercions" method because that creates
    # a new anonymous child type to add the coercions to. We want
    # to add them to the type which exists in this library.
    #
    $dt->coercion->add_type_coercions(

        #Undef() => q[Time::Moment->now()],
        Int() => q[Time::Moment->from_epoch($_)],
        Str() => q[Time::Moment->from_string($_)]
    );
    __PACKAGE__->make_immutable;
};
1;

# No need for docs as this is internal
