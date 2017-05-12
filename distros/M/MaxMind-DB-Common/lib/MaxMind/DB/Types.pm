package MaxMind::DB::Types;

use strict;
use warnings;

our $VERSION = '0.040001';

use Carp qw( confess );
use Exporter qw( import );
use List::AllUtils;
use Scalar::Util ();
use Sub::Quote qw( quote_sub );
use overload ();

our @EXPORT_OK = qw(
    ArrayRefOfStr
    Bool
    Decoder
    Epoch
    FileHandle
    HashRef
    HashRefOfStr
    Int
    Metadata
    Str
);

## no critic (NamingConventions::Capitalization, ValuesAndExpressions::ProhibitImplicitNewlines)
{
    my $t = quote_sub(
        q{
(
           defined $_[0]
        && Scalar::Util::reftype( $_[0] ) eq 'ARRAY'
        && List::AllUtils::all(
        sub { defined $_ && !ref $_ },
        @{ $_[0] }
        )
    )
    or MaxMind::DB::Types::_confess(
    '%s is not an arrayref',
    $_[0]
    );
}
    );

    sub ArrayRefOfStr () { $t }
}

{
    my $t = quote_sub(
        q{
( !defined $_[0] || $_[0] eq q{} || "$_[0]" eq '1' || "$_[0]" eq '0' )
    or MaxMind::DB::Types::_confess(
    '%s is not a boolean',
    $_[0]
    );
}
    );

    sub Bool () { $t }
}

{
    my $t = _object_isa_type('MaxMind::DB::Reader::Decoder');

    sub Decoder () { $t }
}

{
    my $t = quote_sub(
        q{
(
    defined $_[0] && ( ( !ref $_[0] && $_[0] =~ /^[0-9]+$/ )
        || ( Scalar::Util::blessed( $_[0] )
            && ( $_[0]->isa('Math::UInt128') || $_[0]->isa('Math::BigInt') ) )
        )
    )
    or MaxMind::DB::Types::_confess(
    '%s is not an integer, a Math::UInt128 object, or a Math::BigInt object',
    $_[0]
    );
}
    );

    sub Epoch () { $t }

    sub Int () { $t }
}

{
    my $t = quote_sub(
        q{
(          ( defined $_[0] && Scalar::Util::openhandle( $_[0] ) )
        || ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa('IO::Handle') ) )
    or MaxMind::DB::Types::_confess(
    '%s is not a file handle',
    $_[0]
    );
}
    );

    sub FileHandle () { $t }
}

{
    my $t = quote_sub(
        q{
( defined $_[0] && Scalar::Util::reftype( $_[0] ) eq 'HASH' )
    or MaxMind::DB::Types::_confess(
    '%s is not a hashref',
    $_[0]
    );
}
    );

    sub HashRef () { $t }
}

{
    my $t = quote_sub(
        q{
(
           defined $_[0]
        && Scalar::Util::reftype( $_[0] ) eq 'HASH'
        && &List::AllUtils::all(
        sub { defined $_ && !ref $_ }, values %{ $_[0] }
        )
    )
    or MaxMind::DB::Types::_confess(
    '%s is not a hashref of strings',
    $_[0]
    );
}
    );

    sub HashRefOfStr () { $t }
}

{
    my $t = _object_isa_type('MaxMind::DB::Metadata');

    sub Metadata () { $t }
}

{
    my $t = quote_sub(
        q{
( defined $_[0] && !ref $_[0] )
    or MaxMind::DB::Types::_confess( '%s is not a string', $_[0] );
}
    );

    sub Str () { $t }
}

sub _object_isa_type {
    my $class = shift;

    return quote_sub(
        qq{
( Scalar::Util::blessed( \$_[0] ) && \$_[0]->isa('$class') )
    or MaxMind::DB::Types::_confess(
    '%s is not a $class object',
    \$_[0]
    );
}
    );
}
## use critic

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _confess {
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    confess sprintf(
        $_[0],
        defined $_[1] ? overload::StrVal( $_[1] ) : 'undef'
    );
}
## use critic

1;
