use utf8;
# ABSTRACT: Validation and utilities for Eircodes / Irish postcodes
package Eircode;

# Check Eircodes / Irish postcodes


use strict;
use Carp;
use Const::Fast;
use parent qw< Exporter >;

our @EXPORT_OK = ( qw<
                         check_eircode
                         normalise_eircode
                         split_eircode
                     > );
our $VERSION = "0.2.1";



sub check_eircode{
    my( $data, $opt, @x ) = @_;
    if( scalar @x ) {
        croak 'Usage check_eircode($data, {});';
    }

    $opt ||= {};

    my $strict = $opt->{strict};
    my $lax = $opt->{lax};
    my $space_optional = $opt->{space_optional};
    my @options = grep{$_} ($strict, $lax, $space_optional);

    if( scalar @options > 1){
        croak q{Can't combine options for strict/lax/space_optional at the moment};
    }

    if( $lax ){
        $data =~ tr/[ ]//d;
    }

    unless($strict){
        $data = uc($data);
    }

    $data or return;

    my $re = build_re($opt);
    if( $strict ){
        return $data =~ /$re/;
    }
    else{
        return $data =~ /$re/i;
    }

}

const my $EIR_LETTER => 'A-NP-Z';
const my $LETTER_CLASS => "[$EIR_LETTER]";
const my $EIR_ANY => "[$EIR_LETTER\\d]";
const my $ROUTING_KEY => "${LETTER_CLASS}${EIR_ANY}{2}";
const my $UID => "${EIR_ANY}{4}";

sub build_re{
    my($opt) = @_;
    my $lax = $opt->{lax};
    my $space_optional = $opt->{space_optional};

    my $re;
    if( $lax ){
        $re = qr{^$ROUTING_KEY$UID$};
    }
    elsif( $space_optional ){
        $re = qr{^$ROUTING_KEY\s*$UID$};
    }
    else{
        $re = qr{^$ROUTING_KEY\s+$UID$};
    }

}

sub normalise_eircode{
    my($input) = @_;
    $input = uc $input;
    $input =~ tr/ \t//d;
    my($routing_key, $uid) = split_eircode($input);
    return "$routing_key $uid";
}


sub split_eircode{
    my($input) = @_;
    my( $routing_key, $uid ) = ($input =~ /^($ROUTING_KEY)\s*($UID)$/i);
    $routing_key && $uid or die 'invalid eircode';
    return ($routing_key, $uid);
}


;1

__END__

=pod

=encoding UTF-8

=head1 NAME

Eircode - Validation and utilities for Eircodes / Irish postcodes

=head1 VERSION

version 0.2.1

=head1 SYNOPSIS

 use Eircode qw< check_eircode >;

 my $data = "not an eircode";

 if( ! check_eircode($data) ){
    die 'Invalid';
 }

=head1 DESCRIPTION

A module for checking Irish postcodes / Eircodes  / éirchód.

=head1 EXPORTABLE

=head2 check_eircode

 check_eircode("A65 B2CD") or die;

Checks it's first argument to see if it looks like a valid Eircode. If it does
it returns a truthy value, if not it returns a falsey value.

A second argument, a hashref, can be provided to tweak the validation, these
are all key => bool options.

 strict => 1, # enforces upper case and the space mutually exclusive with lax
 lax => 1, # allows any valid sequence irriguadless of spaces. mutually
           # exclusive with strict.
 space_optional => 1, # will accept A65B2CD but not A65 B2 CD. Essentially not
                      # fussed about the space that should be there, but will
                      # not tolerate completely random spacing like lax will.

The default behaviour is to enforce the space but not case sensitivity.

So:

  check_eircode("a65 b2cd"); # pass
  check_eircode("a65b2cd", {lax => 1}); # pass
  check_eircode("a65b2cd"); # fail
  check_eircode("a65b2cd", {strict => 1}); # fail
  check_eircode("a65 b2cd", {strict => 1}); # fail
  check_eircode("A65 B2CD", {strict => 1}); # pass
  check_eircode("a65b2cd", {space_optional => 1}); # pass
  check_eircode("a65 b2cd", {space_optional => 1}); # pass
  check_eircode("a65b 2cd", {space_optional => 1}); # fail

=head2 normalise_eircode

  say normalise_eircode("a65b2cd"); # Outputs A65 B2CD

Takes a loosely formatted eircode and formats it in upper case with the
correct spacing. If the input doesn't look like a valid eircode will die with
"invalid eircode".

=head2 split_eircode

  my($routing_key, $uid) = split_eircode("a65 b2cd");
  my($routing_key, $uid) = split_eircode("a65b2cd");

Take an eircode and gives you the two constitieent parts, the routing key and
the uid. 

=head1 VALIDATION NOTES

The validation doesn't check that the eircode is an existing code, merely that
the formatting is correct, doesn't contain invalid characters etc. If you want
to ensure the Eircode is a real existing code that goes well beyond the scope
of what this module is trying to achieve. However you probably still want to
run this kind of check before you go dialing out to an API to do that kind of
check.

=head1 REFERENCES

https://en.wikipedia.org/wiki/Postal_addresses_in_the_Republic_of_Ireland
https://www.eircode.ie/

=head1 CREDIT

Time to write this was provided by Print Evolved ltd, see
http://www.printevolved.co.uk for all your print / print technology needs.

=head1 AUTHOR

Joe Higton <draxil@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Joe Higton <draxil@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
