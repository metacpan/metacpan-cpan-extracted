package KinoSearch::Search::PolyQuery;
use KinoSearch;

1;

__END__

__BINDING__

my $synopsis = <<'END_SYNOPSIS';
    sub walk {
        my $query = shift;
        if ( $query->isa("KinoSearch::Search::PolyQuery") ) {
            if    ( $query->isa("KinoSearch::Search::ORQuery") )  { ... }
            elsif ( $query->isa("KinoSearch::Search::ANDQuery") ) { ... }
            elsif ( $query->isa("KinoSearch::Search::RequiredOptionalQuery") ) {
                ...
            }
            elsif ( $query->isa("KinoSearch::Search::NOTQuery") ) { ... }
        }
        else { ... }
    }
END_SYNOPSIS

Clownfish::Binding::Perl::Class->register(
    parcel            => "KinoSearch",
    class_name        => "KinoSearch::Search::PolyQuery",
    bind_methods      => [qw( Add_Child Set_Children Get_Children )],
    bind_constructors => ["new"],
    make_pod          => { synopsis => $synopsis, },
);

__COPYRIGHT__

Copyright 2005-2011 Marvin Humphrey

This program is free software; you can redistribute it and/or modify
under the same terms as Perl itself.

