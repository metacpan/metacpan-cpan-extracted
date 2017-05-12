package Message::Match;
{
  $Message::Match::VERSION = '1.132270';
}

use strict;use warnings;
require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(mmatch);

our $named_regex = {};

sub mmatch {
    my ($message, $match) = @_;
    die 'Message::Match::mmatch: two HASH references required'
        if  scalar @_ < 2 or
            scalar @_ > 2 or
            not ref $message or
            not ref $match or
            ref $message ne 'HASH' or
            ref $match ne 'HASH';

    return _match($message, $match);
}

sub _special {
    my ($message, $match) = @_;
    substr($match, 0, 8, '');
    if($match =~ m{^/}) { #regex type
        my $re;
        eval "\$re = qr$match;";    #this is hideously inefficient
                                    #but it is highly cacheable, later on
        if($message =~ $re) {
            if(%+) {
                while(my($key, $value) = each %+) {
                    $named_regex->{$key} = $value;
                }
            }
            return 1
        } else {
            return 0;
        }
    }
    die "Message::Match::mmatch: special of unknown type passed: $match";
}

sub _match {
    my ($message, $match) = @_;
    my $ref_message = ref $message; my $ref_match = ref $match;
    if(not $ref_message and not $ref_match) { #scalar on both sides
        if(substr($match, 0, 8) eq ' special') { #special handling
            return _special($message, $match);
        }
        return $message eq $match; #otherwise, brain-dead comparison
    }
    if($ref_message eq 'JSON::PP::Boolean' and $ref_match eq 'JSON::PP::Boolean') {
        return "$message" eq "$match";
    }
    if($ref_message eq 'HASH' and $ref_match eq 'HASH') {
        foreach my $key (keys %$match) {
            my $message = $message->{$key};
            my $match = $match->{$key};
            return 0 if not defined $message;
            return 0 if not defined $match;
            return 0 unless _match($message, $match);
        }
        return 1;
    }
    if($ref_message eq 'ARRAY' and not $ref_match) {    #check for scalar inside the array
        foreach my $item (@$message) {
            return 1 if $item eq $match;
        }
        return 0;
    }
    if($ref_message eq 'ARRAY' and $ref_match eq 'ARRAY') {  #check the entire array
        foreach my $item (@$match) {
            my $match = $item;
            my $message = shift @{$message};
            return 0 unless _match($message, $match);
        }
        return 1;
    }
    if($ref_message eq 'ARRAY' and $ref_match eq 'HASH') {
#The idea is that if a message field is an array, and the
#match field is a hash, every element in the array must have a key in the
#hash in order to pass
        foreach my $item (@$message) {
            return 0 unless defined $match->{$item};
        }
        return 1;
    }
    return 0; #anything we don't know about fails
}
1;
__END__

=head1 NAME

Message::Match - Fast, simple message matching

=head1 SYNOPSIS

    use Message::Match qw(mmatch);

    #basic usage
    mmatch(
        {a => 'b', c => 'd'},   #message
        {a => 'b'}              #match
    ); #true
    mmatch(
        {a => 'b', c => {x => 'y'}, #message
        {c => {x => 'y'}}           #match
    ); #true
    mmatch(
        {a => 'b', c => 'd'},   #message
        {x => 'y'}              #match
    ); #false

    #set membership
    mmatch(
        {a => [1,2,3], some => 'thing'},    #message
        {a => 2},                           #match
    ); #true
    mmatch(
        {a => [1,2,3], some => 'thing'},    #message
        {a => 4},                           #match
    ); #false

    #array recursion
    mmatch(
        {a => [{a => 'b'},2,3], x => 'y'},      #message
        {a => [{a => 'b'},2,3]},                #match
    ); #true

    #regex
    mmatch(
        {a => 'forefoot'},          #message
        {a => ' special/foo/'},     #match
    ); #true

    #universal match
    mmatch(
        {some => 'random', stuff => 'here'},    #message
        {},                                     #match
    ); #true

=head1 DESCRIPTION

This is a very light-weight and fast library that does some basic but
reasonably powerful message matching.

=head1 FUNCTION

=head2 mmatch($message, $match);

Takes two and only two arguments, both HASH references.

=head1 SEE ALSO

Good question; I found some things somewhat similiar to this, but not quite
close enough to mention here.

=head1 TODO

Define handling for other tuples:
 HASH,scalar
 scalar,HASH
 scalar,ARRAY
 ARRAY,HASH
 HASH,ARRAY

More special handling.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2012, 2013, 2016 Dana M. Diederich. All Rights Reserved.

=head1 AUTHOR

Dana M. Diederich <diederich@gmail.com>

=cut
