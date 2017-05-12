package MARC::Detrans::Rules;

use strict;
use warnings;

=head1 NAME 

MARC::Detrans::Rules - A set of detransliteration rules

=head1 SYNOPSIS

    use MARC::Detrans::Rules;
    my $rules = MARC::Detrans::Rules->new();
    $rules->addRule( MARC::Detrans::Rule->new( from=>'a', to='b' ) );

=head1 DESCRIPTION

MARC::Detrans::Rules provides the core functionality for managing 
detransliteration rules and for converting transliterated text to
MARC-8. A MARC::Detrans::Rules object is essentially a collection of 
MARC::Detrans::Rule objects which are consulted during a call to convert().

=head1 METHODS

=cut

=head2 new()

Create an empty rules object to add individual rules to.

=cut

sub new {
    my $class = shift;
    my $self = { rules => {}, error => undef };
    return bless $self, ref( $class ) || $class;
}

=head2 addRule()

Add a MARC::Detrans::Rule to the rules object.

=cut

sub addRule {
    my ( $self, $rule ) = @_;
    ## get first character off the source for lookup
    ## since we'll be processing a character at a time 
    my $key = substr( $rule->from(), 0, 1 );
    ## look for existing rules with this key
    my $rules = exists($self->{rules}{$key}) ? $self->{rules}{$key} : [];
    ## and the new rule and sort the rules so that the longest come first.
    ## this will mean that when we go to use the rules in convert()
    ## that the longest match will occur first.
    push( @$rules, $rule );
    @$rules = sort byRule @$rules;
    ## stash away the new rules
    $self->{rules}{$key} = $rules;
}

sub byRule {
    return 
        length( $b->from() . $b->position() ) 
        <=> 
        length( $a->from() . $a->position() )
}

=head2 convert()

convert() applies the rules contained in the MARC::Detrans::Rules object
to convert a string that is passed in.

=cut

sub convert {
    my ( $self, $in ) = @_;
    ## ok, this is probably the most complicated bit of the distro
    ## and it's not really that bad.
    my $inLength = length( $in );
    my $out = '';
    my $pos = 0;
    my $currentEscape = '';
    ## we're going to step through the source string and build up $out
    ## to contain the de-transliterated text
    while ( $pos < $inLength ) {
        ## extract the character at the current position
        ## and look to see if we have a rule for it
        my $key = substr( $in, $pos, 1 );
        my $rules = exists $self->{rules}{$key} ? $self->{rules}{$key} : [];
        pos($in) = $pos;
        my $foundRule;
        ## go through each of the rules and see if we've got a match
        foreach my $rule ( @$rules ) {
            my $from = $rule->from();
            ## if the rule matches remember it for later and jump out of 
            ## the loop since we've got what we needed
            ## \G anchors the match at our current position
            ## \Q...\E makes sure that metacharacters in our pattern are escaped
            if ( $in =~ m/\G\Q$from\E/ ) {
                my $position = $rule->position() || '';
                if ( $position eq 'initial' ) {
                    next unless isInitial( $in, $pos ); 
                }
                elsif ( $position eq 'medial' ) {
                    next if isInitial( $in, $pos ) or isFinal( $in, $pos );
                }
                elsif ( $position eq 'final' ) {
                    next unless isFinal( $in, $pos );
                }
                $foundRule = $rule;
                last;
            }
        }
        ## no matched rule, then we've got a character in the source
        ## data which doesn't map. Store the error and return asap. 
        if ( ! defined($foundRule) ) {
            $self->{error} = sprintf( 
                qq(no matching rule found for "%s" [0x%x] at position %i), 
                    $key, ord($key), $pos+1 );
            return;
        }
        ## advance the position the amount of characters that we matched
        $pos += length( $foundRule->from() );
        ## if the rule has an associated MARC-8 escape character tag it
        ## onto the output text
        if ($foundRule->escape() and $foundRule->escape() ne $currentEscape) { 
            $out .= chr(0x1B).$foundRule->escape();
            $currentEscape = $foundRule->escape();
        }
        ## append the new text
        $out .= $foundRule->to();
    }
    ## escape back to ASCII if approriate
    if ( $currentEscape ) { $out .= chr(0x1B).chr(0x28).chr(0x42); }
    ## make sure error flag is undef since we're ok now
    $self->{error} = undef;
    ## return the new text!
    return( $out );
}

=head2 error()

Will return the latest error encountered during a call to convert(). Can
be useful for determining why a call to convert() failed. A side effect
of calling error() is that the error slot is reset.

=cut

sub error {
    my $self = shift;
    my $error = $self->{error};
    $self->{error} = undef;
    return( $error );
}

=head1 AUTHORS 

=over 4

=item * Ed Summers <ehs@pobox.com>

=cut

## helper functions to determine whether a specific positon in a string
## is at the start or at the end of a word.

sub isInitial {
    my ($string,$position) = @_;
    return 1 if $position == 0;
    return 1 if substr($string,$position-1,1) =~ /\W/;
    return 0;
}

sub isFinal {
    my ($string,$position) = @_;
    return 1 if $position == length($string)-1;
    return 1 if substr($string,$position+1,1) =~ /\W/; 
}

1;
