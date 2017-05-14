#!/usr/bin/perl
package Lingua::TreeTagger::Filter::Element;

use Moose;
use Carp;

extends 'Lingua::TreeTagger::Token';

#===============================================================================
#attributes
#===============================================================================

has 'quantifier' => (
  is        => 'ro',
  isa       => 'Str',
  default   => 1,
  reader    => 'get_quantifier',

);

has 'sub_tag' => (
  is        => 'ro',
  isa       => 'Str',
  required   => 1,
  reader    => 'get_sub_tag',

);

has 'sub_lemma' => (
  is        => 'ro',
  isa       => 'Str',
  required   => 1,
  reader    => 'get_sub_lemma',

);

has 'sub_original' => (
  is        => 'ro',
  isa       => 'Str',
  required   => 1,
  reader    => 'get_sub_original',

);

#===============================================================================
#private attributes
#===============================================================================

has '_neg_original' => (
  is        => 'ro',
  isa       => 'Int',
  default   => 0,
  reader    => 'get_neg_original',

);

has '_neg_lemma' => (
  is        => 'ro',
  isa       => 'Int',
  default   => 0,
  reader    => 'get_neg_lemma',

);

has '_neg_tag' => (
  is        => 'ro',
  isa       => 'Int',
  default   => 0,
  reader    => 'get_neg_tag',
);  

has '_is_wildcard' => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
  reader  => 'get_is_wildcard',
);

has '_is_null' => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
  reader  => 'get_is_null',
);

has '_is_greedy' => (
  is      => 'ro',
  isa     => 'Int',
  default => 1,
  reader  => 'get_is_greedy',
);



#===============================================================================
# Object construction hooks.
#===============================================================================

around BUILDARGS => sub {

    my $original_buildargs = shift;
    my $class              = shift;
    # Initialization.
    my %param;
    # Parameters are passed directly.
    if (defined($_[1])){
      %param = @_;
    }
    # Parameters are passed in a hash reference.
    else {
      %param = %{$_[0]};
    } 
    
    # Default entries.
    $param{original}           ||= ".";
    $param{tag}                ||= ".";
    $param{lemma}              ||= ".";
    $param{sub_original}       ||= ".";
    $param{sub_tag}            ||= ".";
    $param{sub_lemma}          ||= ".";
    $param{is_SGML_tag}        ||= 0;
    $param{quantifier}         ||= "1";
    # False parameter for the negation symbol.
    $param{neg_symbol}         ||= "!";
    
    # Element is a wildcard.
    if ( $param{original} eq '.' && $param{lemma} eq '.' && $param{tag} eq '.'){
      $param{_is_wildcard} = 1;
    }
    # Erasing the {}  for the quantifier.
    if($param{quantifier} =~ /[{}]/){
      my @tab_clean = split( /[^0-9,]/ , $param{quantifier} );
      $param{quantifier} = $tab_clean[1];
    }
    # Quantifier allows 0.
    if ( substr( $param{quantifier},0,1) eq '0' || 
      substr( $param{quantifier},0,1) eq ',' ||
      $param{quantifier} eq '*' || 
      $param{quantifier} eq '?'
    ) {
      
      $param{_is_null} = 1;
        
    } 
    # Non greedy quantifier
    if ( $param{quantifier} eq '+?' || $param{quantifier} eq '*?' ) {
      $param{quantifier} = substr($param{quantifier},0,1);
      $param{_is_greedy} = 0;
    } 
    # Extracting the eventual negations.
    if(substr($param{original},0,1) eq $param{neg_symbol}){
      # Udpating the value from the original filter.
      $param{original} = substr($param{original},1);
      # Set the corresponding attribute to 1.
      $param{_neg_original} = 1;
    }
    if(substr($param{lemma},0,1) eq $param{neg_symbol}){
      # Udpating the value from the original filter
      $param{lemma} = substr($param{lemma},1);
      # Set the corresponding attribute to 1
      $param{_neg_lemma} = 1;
    }
    if(substr($param{tag},0,1) eq $param{neg_symbol}){
      # Udpating the value from the original filter
      $param{tag} = substr($param{tag},1);
      # Set the corresponding attribute to 1
      $param{_neg_tag} = 1;
    }
    # Erasing the false parameters (which as no corresponding attributes).
    delete $param{neg_symbol};
    
    # Anchor gestion.
    foreach my $attribute ( "tag" , "lemma", "original" ){
    
      if ($param{$attribute} ne "."){
      
        my $current_anchor = "anchor_" . $attribute; 
        # No anchor.
        if (defined($param{$current_anchor})) {
        
          # Erasing the control value.
          delete($param{$current_anchor});
        
        }
        # Anchors, strict match
        else {
        
          
          # Adding the anchors.
          $param{$attribute} = '^' . $param{$attribute} . '$';
          
        } 
      
      }
    
    }

    return $class->$original_buildargs( %param );
};

#===============================================================================
# Public methods
#===============================================================================
#-----------------------------------------------------------------------------
# function 
#-----------------------------------------------------------------------------
# Synopsis:         
# attributes:        - 
# Return values:     - 
#-----------------------------------------------------------------------------



#===============================================================================
# Standard Moose cleanup.
#===============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__

=head1 NAME

Lingua::TreeTagger::Filter::Element - Element of a filter

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

  use Lingua::TreeTagger::Filter;
  
  # Create a new element object.
  my $element = Lingua::TreeTagger::Filter::Element->new(
      lemma       => 'lemma1',
      original    => 'original1',
      tag         => 'tag1',
      quantifier  => '{1}',
  );
  
  
  # Create a new element object which will match every token(wildcard).
  $element = Lingua::TreeTagger::Filter::Element->new();
      
  # Using the negation with the original attribute -> implies that it will match
  # anything but a token with original1 as original attribute. 
  $element = Lingua::TreeTagger::Filter::Element->new(
      lemma       => 'lemma1',
      original    => '!original1',
      tag         => 'tag1',
  );



=head1 Description

This module is part of the Lingua::TreeTagger::Filter distribution. It
 defines a 
class of elements which constitute the filters. These elements will be
compared with the token element of the taggedtext.
This class extends the module Lingua::TreeTagger::Token, see also the 
related documentation.
See also L<Lingua::TreeTagger::Filter>, 
L<Lingua::TreeTagger::Filter::Result> and
L<Lingua::TreeTagger::Filter::Result::Hit>

=head1 METHODS

=over 4

=item C<new()>

The constructor has only optionnal parameters. If constructor the is 
called without any parameter, object will be initialized as a all 
token matching object (wildcard). This constructor is normally called 
by the method add_element of the module Lingua::TreeTagger::Filter and
not directly by the user 

For the parameters (tag, original and  lemma), if ommited the 
corresponding attributes will be initialized with the value of "." so
it will match any values. These parameters are defined in the mother
class Lingua::TreeTagger::Token, please see the related documentation.

For the parameters (tag, original and  lemma), you can negate any 
attribute by adding a "!" in front of it.
sample: "tag=!JJ" -> signifies that it will match any non-adjective.

=over 4

=item C<sub_tag>

Optionnal , a string containing the expression to be substitued with 
the tag  attribute from the tokens of a Lingua::TreeTagger output.

=item C<sub_original>

Optionnal a string containing the expression to be substitued with the
original attribute from the tokens of a Lingua::TreeTagger output.

=item C<sub_lemma>

Optionnal, a string containing the expression to be substitued with 
the lemma  attribute from the tokens of a Lingua::TreeTagger output.

=item C<quantifier>

a string, must respect the syntax of Perl quantifier. 
samples: +/*/?/{n}/{n,m}

The quantifier defines the number of repetitions of the current 
element in the filter sequence.

If element_object is not defined and quantifier is omitted, the value 
of quantifier attribute in the corresponding filter element will be 
initiated to 1(the correpsonding element must appear exactly one time)

=back

=back

=head1 ACCESSORS

=over 4

=item C<tag()>

Read-only accessor for the 'tag' attribute of a filter element

=item C<original()>

Read-only accessor for the 'original' attribute of a filter element

=item C<lemma()>

Read-only accessor for the 'lemma' attribute of a filter element

=item C<get_quantifier()>

Read-only accessor for the 'quantifier' attribute of a filter element

=item C<sub_tag()>

Read-only accessor for the 'sub_tag' attribute of a filter element

=item C<sub_original()>

Read-only accessor for the 'sub_original' attribute of a filter 
element

=item C<sub_lemma()>

Read-only accessor for the 'sub_lemma' attribute of a filter element

=back

=head1 DIAGNOSTICS

=over 4


=back

=head1 DEPENDENCIES

This is part of the Lingua::TreeTagger::Filter distribution. 
It is not intended to be used as an independent module.

This module requires module Moose and was developed using version 1.09.
Please report incompatibilities with earlier versions to the author.


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Benjamin Gay (Benjamin.Gay@unil.ch)

Patches are welcome.

=head1 AUTHOR

Benjamin Gay, C<< <Benjamin.Gay at unil.ch> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Benjamin Gay.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::TreeTagger::Filter