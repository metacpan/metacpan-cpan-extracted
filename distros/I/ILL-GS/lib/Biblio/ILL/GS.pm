package Biblio::ILL::GS;

=head1 NAME

Biblio::ILL::GS - Interlibrary Loan Generic Script (GS)

=cut

use strict;
use warnings;
use Carp qw( carp croak );

=head1 VERSION

Version 0.05

=cut
our $VERSION = '0.05';

my @validFields = (
    'LSB',   # Library Symbol, Borrower
    'LSP',   # Lending library symbol
    'A#C',   # Account number
    'P/U',   # Patron name
    'N/R',   # Need-before date
    'ADR',   # Address or delivery service (multiple lines)
    'SER',   # Service
    'AUT',   # Author
    'TIT',   # Title
    'P/L',   # Place of publication
    'P/M',   # Publisher
    'EDN',   # Edition
    'DAT',   # Publication date
    'LCN',   # Local contron number
    'SBN',   # ISBN
    'NUM',   # Other numbers/letters (multiple lines)
    '#AD',   # Other
    'SRC',   # Source of your information
    'REM',   # Remarks
);

=head1 SYNOPSIS

    use Biblio::ILL::GS;
    my $gs = new Biblio::ILL::GS;

    $gs->set("LSB", "MWPL" );
    $gs->set("LSP", "BVAS" );
    $gs->set("P/U", "Christensen, David" );

    $gs->set( "ADR", 
	"Public Library Services",
	"Interlibrary Loan Department",
	"1525 First Street South",
	"Brandon, MB  R7A 7A1"
    );

    $gs->set("SER", "LOAN" );
    $gs->set("AUT", "Wall, Larry" );
    $gs->set("TIT", "Programming Perl" );
    $gs->set("P/L", "Cambridge, Mass." );
    $gs->set("P/M", "O'Reilly" );
    $gs->set("EDN", "2nd Ed." );
    $gs->set("DAT", "2000" );
    $gs->set("SBN", "0596000278" );
    $gs->set("SRC", "TEST SCRIPT" );
    $gs->set("REM", "This is a comment.", "And another comment." );

    # ouptut our string
    print $gs->as_string();


=head1 DESCRIPTION

Biblio::ILL::GS is a little bit of glue.... 

Our library web site (http://maplin.gov.mb.ca) uses Perl (of course)
and Z39.50 to enable our libraries to search for and request items
amongst themselves (and, for that matter, to/from the world at large).

The basic procedue is: find the item, parse the resulting record,
build a human-readable email out of it, and send it - all automagically.

One of our libraries has moved to an interlibrary-loan management system,
and would rather not have to re-key this data as it arrives.  Their
system, however, does have the ability to process requests in the
Interlibrary Loan Generic Script (GS) format.

Biblio::ILL::GS simply lets you build a GS format message.

=head1 METHODS

=head2 new()

Create the Biblio::ILL::GS object.

    my $gs = new Biblio::ILL::GS;

=cut

sub new { 
    my $class = shift;
    return( bless { }, ref($class) || $class );
}


=head2 set()

Set a field in the object. Fields can accept multiple values, which you pass in
a list context. If you do not pass in a valid field name you will
get a fatal error. Valid fields names include:
LSB, LSP A#C P/U N/R ADR SER AUT TIT P/L P/M EDN DAT LCN SBN NUM #AD SRC REM

    my $gs = new Biblio::ILL::GS;
    $gs->set( 'TIT', 'Huckleberry Finn' );
    $gs->set( 'REM', 'This is a comment.', 'This is another comment' );

=cut

sub set {
    my ($self,$fieldname,@ary) = @_;
    if ( ! grep /$fieldname/, @validFields ) {
	croak( "invalid field $fieldname" );
    }
    $self->{$fieldname} = [ @ary ];
}


=head2 as_string()

Returns the GS message as a string, or undef if the minimum data is not
present (LSB, LSP, ADR, SER, AUT, and TIT).

=cut

sub as_string {

    my $self = shift;
    my $GS;

    # verify that we have the (minimum) data we need

    foreach ( qw( LSB LSP ADR SER AUT TIT ) ) {
	if ( ! defined( $self->{ $_ } ) ) { 
	    croak( "missing mandatory field: $_" );
	}
    }

    # I think this is the real start of the GS msg....
    $GS .= "\t\t\tILL REQUEST/DEMANDE DE PEB\n\n";

    # why do only some of these check for existence
    # - some are mandatory, some optional (but handy)
    $GS .= "LSB:" . _stringify( @{ $self->{"LSB"} });
    $GS .= "LSP:" . _stringify( @{ $self->{"LSP"} });
    $GS .= "A#C:" . _stringify( @{ $self->{"A#C"} }) if ($self->{"A#C"});
    $GS .= "P/U:" . _stringify( @{ $self->{"P/U"} }) if ($self->{"P/U"});
    $GS .= "N/R:" . _stringify( @{ $self->{"N/R"} }) if ($self->{"N/R"});
    $GS .= "ADR:" . _stringify( @{ $self->{"ADR"} });
    $GS .= "SER:" . _stringify( @{ $self->{"SER"} });
    $GS .= "AUT:" . _stringify( @{ $self->{"AUT"} });
    $GS .= "TIT:" . _stringify( @{ $self->{"TIT"} });
    $GS .= "P/L:" . _stringify( @{ $self->{"P/L"} }) if ($self->{"P/L"});
    $GS .= "P/M:" . _stringify( @{ $self->{"P/M"} }) if ($self->{"P/M"});
    $GS .= "EDN:" . _stringify( @{ $self->{"EDN"} }) if ($self->{"N/R"});
    $GS .= "DAT:" . _stringify( @{ $self->{"DAT"} }) if ($self->{"DAT"});
    $GS .= "LCN:" . _stringify( @{ $self->{"LCN"} }) if ($self->{"LCN"});
    $GS .= "SBN:" . _stringify( @{ $self->{"SBN"} }) if ($self->{"SBN"});
    $GS .= "SRC:" . _stringify( @{ $self->{"SRC"} }) if ($self->{"SRC"});
    $GS .= "REM:" . _stringify( @{ $self->{"REM"} }) if ($self->{"REM"});

    return( $GS );

}

sub _stringify {
    my (@v) = @_;
    my $s;
    foreach my $elem (@v) {
	$s .= "\t" . $elem . "\n";
    }
    return( $s );
}

1;


__END__

=head1 SEE ALSO

For more information on Interlibrary Loan standards (ISO 10160/10161),
a good place to start is:

http://www.nlc-bnc.ca/iso/ill/main.htm

=head1 TODO

    - Make a real TODO list.
    - Look into creating Biblio::ILL::protocol, to create ISO10160/10161-compliant request messages.

=head1 AUTHOR

David Christensen, E<lt>DChristensen@westman.wave.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by David Christensen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
