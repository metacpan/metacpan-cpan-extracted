package KinoSearch::Plan::Int32Type;
use KinoSearch;

1;

__END__

__BINDING__

my $synopsis = <<'END_SYNOPSIS';
    my $schema     = KinoSearch::Plan::Schema->new;
    my $int32_type = KinoSearch::Plan::Int32Type->new;
    $schema->spec_field( name => 'count', type => $int32_type );
END_SYNOPSIS
my $constructor = <<'END_CONSTRUCTOR';
    my $int32_type = KinoSearch::Plan::Int32Type->new(
        indexed  => 0,    # default true
        stored   => 0,    # default true
        sortable => 1,    # default false
    );
END_CONSTRUCTOR

Clownfish::Binding::Perl::Class->register(
    parcel            => "KinoSearch",
    class_name        => "KinoSearch::Plan::Int32Type",
    bind_constructors => ["new|init2"],
    #make_pod          => {
    #    synopsis    => $synopsis,
    #    constructor => { sample => $constructor },
    #},
);

__COPYRIGHT__

Copyright 2005-2011 Marvin Humphrey

This program is free software; you can redistribute it and/or modify
under the same terms as Perl itself.

