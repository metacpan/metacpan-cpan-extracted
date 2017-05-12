package Decision::ParseTree;

use base qw{Exporter};
our @EXPORT_OK = qw{ParseTree};

use warnings;
use strict;

=head1 NAME

Decision::ParseTree - Replacing waterfall IF-ELSIF-ELSE blocks

=head1 VERSION

Version 0.041

=cut

our $VERSION = '0.041';

=head1 SYNOPSIS

Death to long if-elsif-else blocks that are hard to maintain, and hard to 
explain to your manager. Heres an overly simplistic example:

=head2 OLD CODE

   if ( $obj->is_numeric ) {
      if ( $obj->is_positive ) {
         print 'Positive Number';
      } 
      elsif ( $obj->is_negative ) 
         print 'Negative Number';
      }
      else {
         print 'Looks like zero';
      }
   else {
      print 'Non-Numeric Value';
   }

=head2 NEW CODE

=head3 YAML Decision Tree

   ---
      - is_num : 
         0 : Non-Numeric Value
         1 : - is_pos :
               1 : Positive Number
             - is_neg :
               = : Looks like zero
               1 : Negative Number
   ...


=head3 Rules Object

   package Rules;
   use Scalar::Util;
  
   sub is_num { 
      my ( $self, $obj ) = @_;
      return (Scalar::Util::looks_like_number($obj->{value})) ? 1 : 0; 
   }

   sub is_pos { 
      my ( $self, $obj ) = @_;
      return ($obj->{value} > 0 ) ? 1 : 0; 
   }

   sub is_neg { 
      my ( $self, $obj ) = @_;
      return ($obj->{value} < 0 ) ? 1 : 0; 
   }

=head3 Goal Object to be passed thru the rules

   package Number;
   
   sub new {
      my ( $class, $value ) = @_
      my $self = { parse_path => [], 
                   value => $value };
      return bless $self, $class;
   }
   
=head3 Replacement to that if-else block

   use Decision::ParseTree q{ParseTree};

   my $rules = Rules->new;
   my $tree  = LoadFile('tree.yaml');
   
   print ParseTree( $tree, $rules, Number->new(10) ); # Positive Number
   print ParseTree( $tree, $rules, Number->new(-1) ); # Negative Number
   print ParseTree( $tree, $rules, Number->new(0)  ); # Looks like zero
   print ParseTree( $tree, $rules, Number->new('a')); # Non-Numeric Value




=head1 DESCRIPTION

=head1 YAML as a Decision tree

To make this all work we need a few parts:

=over

=item * A rules object: This will be a library of rules.

=item * An object that will be passed thru the rules.

=item * A YAML doc that outlines your decision tree.

=back

=head2 Why YAML

So this all started as a way to make a decision tree thats easy to parse and
easy to read for non-programmers. So to do this I looked to YAML, it's easy
to read and easy to parse. Though make this work we have some hard and fast 
rules to follow for the tree construction:

=over

=item * RULES are a key value pair

=over

=item * the key is the method to run in the rules object

=item * the value must be an arrayref or hashref

=back

=item * ARRAYS are a series of rules run in order

=item * HASHES are a series of answers

=item * SCALARS are endpoints

=back

=head2 Why add more parts, why blow everything in to separate objects.

Sometimes you have to make things messy before they can get clean.

Theres a flexibility that comes with breaking things apart in to nice, neat
little chunks. By separating the rule logic in to one place you can make 
very complex rules that do not gunk up your code. You pull the order of these
rules in to another place as it's completely possible that you would want to
tweak the order. And lastly you need to glue these separate things together, 
so you have an object that gets passed thru to make this all work. Tada! 

=head2 Examples

It would be nice to whip up a big example here to show all the interesting
bits, sadly I can't think of a good example. Ideas?

=over

=item * Selecting a tests to run for hardware

=item * Building settings/configuration files on the fly for varried hardware.

=item * Would any one like to use this to write up a GO AI engine? Chess?

=back

=head1 FEATURES

=over

=item * tracking for free

=over

=item * If $obj->{parse_path} exists then every step that this obj takes thru
the rules will be tracked. This path will be stored as an array ref, of hash refs. 

   $obj = Number->new(10);
   ParseTree( $tree, $rules, $obj );
   # $obj->{parse_path} will now look like :
   #   [  { 'is_num' => 1 },
   #      { 'is_pos' => 1 },
   #   ]

=item * If $obj->{parse_answer} exists then, when an answer is found, then it
gets stored here as well as being returned.

  print $obj->{parse_answer}; # Positive Number

=back

=back

=head1 EXPORT OK-able

ParseTree is the only thing that can get exported, it's also the only thing in
here, so export away.

=head1 FUNCTIONS

=head2 ParseTree($tree, $rules, $obj)

Runs $obj thru $tree, using $rules as the library of rules.

Returns the first endpoint that you run into as the answer.

=cut

#===  FUNCTION  ================================================================
#         NAME:  ParseTree
#      PURPOSE:  walk a decision tree to get an answer
#   PARAMETERS:  $tree : Expected to be a big array ref of stuff pulled from YAML
#                $rules: an object of rules that holds $tree's nodes
#                $obj  : The concept is that this $obj is what is passed thru the
#                        rules. So build your rules as though $obj will be passed
#                        to them. 
#                        Also, there are two 'plugins' for $obj:
#                         $obj->{parse_path}   : if exists it will contain the path
#                                                that the $obj took
#                         $obj->{parse_answer} : if exists it will hold the result
#      RETURNS:  the proper value from $tree or undef
#       THROWS:  there are many assertions that will die on failure
#     COMMENTS:  none
#     SEE ALSO:  the pod above for an explination and example
#===============================================================================

sub ParseTree {
   use YAML; # to get YAML::Value
   use Carp::Assert::More;
   my($tree, $rules, $obj) = @_;

   assert_listref( $tree, q{A list of rules must be an array.} ); 

   NODE : foreach my $task (@$tree) {
      assert_hashref( $task, q{Task nodes must be a hashref.} );
      
      #---------------------------------------------------------------------------
      #  grab the values as they are the answers that we will check agenst
      #---------------------------------------------------------------------------
      my ($answers) = values(%$task);
      assert_hashref( $answers, q{You answers need to be presented as a hashref.} );

      #---------------------------------------------------------------------------
      #  grab the action 
      #---------------------------------------------------------------------------
      my ($action) = keys %$task;

      #---------------------------------------------------------------------------
      #  run the action to get the reply
      #---------------------------------------------------------------------------
      assert_defined( $rules->can($action), q{Your rule needs to exist in your rules object.} );
      my $reply = $rules->$action($obj);

      #---------------------------------------------------------------------------
      #  Log to the obj if theres a place to log to
      #---------------------------------------------------------------------------
      if (defined $obj->{parse_path}) {
         push @{$obj->{parse_path}}, {$action => $reply}; 
      }

      #---------------------------------------------------------------------------
      #  handle default YAML values if they exist if not by spec if we get 
      # undef back we continue to the next node
      #---------------------------------------------------------------------------
      if( !defined( $reply ) 
          || !defined( $answers->{$reply} )
      ) {
         if( defined $answers->{YAML::VALUE} ) { 
            # YAML::Value is a constant in YAML that specifies any default (=) key
            $reply = YAML::VALUE; 
         } else {
            next NODE; #continue if $reply is not an $answer
         }
      }

      #---------------------------------------------------------------------------
      #  Deal with sub trees
      #---------------------------------------------------------------------------
      return ParseTree($answers->{$reply}, $rules, $obj)
         if ref($answers->{$reply}) eq q{ARRAY};
          
      #---------------------------------------------------------------------------
      #  Deal with our answer
      #---------------------------------------------------------------------------
      if (defined $obj->{parse_answer}) {
         $obj->{parse_answer} = $answers->{$reply};
      }
      return $answers->{$reply};
      
   } 
   return undef; #catch all failure... this should never happen
}
=head1 CAVEATS / TODO

=over

=item * Currently $tree is expected to be a pre-parsed YAML File, This should 
change here soon to also accept a filename. Currently though it does not.

=item * would like even more examples.

=item * need to flush out the docs more.

=back

=head1 AUTHOR

ben hengst, C<< <notbenh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-decision-parsetree at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decision-ParseTree>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Decision::ParseTree

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Decision-ParseTree>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Decision-ParseTree>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Decision-ParseTree>

=item * Search CPAN

L<http://search.cpan.org/dist/Decision-ParseTree>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 ben hengst, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Decision::ParseTree
