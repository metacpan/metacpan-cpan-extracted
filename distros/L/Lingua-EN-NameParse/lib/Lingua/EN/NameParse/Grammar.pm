=head1 NAME

Lingua::EN::NameGrammar - grammar tree for Lingua::EN::NameParse

=head1 SYNOPSIS

Internal functions called from NameParse.pm module

=head1 DESCRIPTION

Grammar tree of personal name syntax for <Lingua::EN::NameParse> module.

The grammar defined here is for use with the Parse::RecDescent module.
Note that parsing is done depth first, meaning match the shortest string first.
To avoid premature matches, when one rule is a sub set of another longer rule,
it must appear after the longer rule. See the Parse::RecDescent documentation
for more details.


=head1 AUTHOR

NameParse::Grammar was written by Kim Ryan <kimryan at cpan dot org>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016 Kim Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
#------------------------------------------------------------------------------

package Lingua::EN::NameParse::Grammar;
use strict;
use warnings;

our $VERSION = '1.36';


# Rules that define valid orderings of a names components

my $rules_start = q{ full_name : };

my $rules_joint_names =
q{

   # A (?) refers to an optional component, occurring 0 or more times.
   # Optional items are returned as an array, which for our case will
   # always consist of one element, when they exist.

   title given_name surname conjunction title given_name surname non_matching(?)
   {
      # block of code to define actions upon successful completion of a
      # 'production' or rule

      # Two separate people
      $return =
      {
         # Parse::RecDescent lets you return a single scalar, which we use as
         # an anonymous hash reference
         title_1       => $item[1],
         given_name_1  => $item[2],
         surname_1     => $item[3],
         conjunction_1 => $item[4],
         title_2       => $item[5],
         given_name_2  => $item[6],
         surname_2     => $item[7],
         non_matching  => $item[8][0],
         number        => 2,
         type          => 'Mr_John_Smith_&_Ms_Mary_Jones'
      }
   }
   |


   title initials surname conjunction title initials surname non_matching(?)
   {
      $return =
      {
         title_1       => $item[1],
         initials_1    => $item[2],
         surname_1     => $item[3],
         conjunction_1 => $item[4],
         title_2       => $item[5],
         initials_2    => $item[6],
         surname_2     => $item[7],
         non_matching  => $item[8][0],
         number        => 2,
         type          => 'Mr_A_Smith_&_Ms_B_Jones'
      }
   }
   |
   
   title initials conjunction title initials surname non_matching(?)
   {
      # Two related people, own initials, shared surname
      $return =
      {
         title_1       => $item[1],
         initials_1    => $item[2],
         conjunction_1 => $item[3],
         title_2       => $item[4],
         initials_2    => $item[5],
         surname_1     => $item[6],
         non_matching  => $item[7][0],
         number        => 2,
         type          => 'Mr_A_&_Ms_B_Smith'
      }
   }
   |      

   title initials conjunction initials surname non_matching(?)
   {
      # Two related people, shared title, separate initials,
      # shared surname. Example, father and son, sisters
      $return =
      {
         title_1       => $item[1],
         initials_1    => $item[2],
         conjunction_1 => $item[3],
         initials_2    => $item[4],
         surname_1     => $item[5],
         non_matching  => $item[6][0],
         number        => 2,
         type          => 'Mr_A_&_B_Smith'
      }
   }
   |
   

   title conjunction title initials conjunction initials surname non_matching(?)
   {
      # Two related people, own initials, shared surname

      $return =
      {
         title_1       => $item[1],
         conjunction_1 => $item[2],
         title_2       => $item[3],
         initials_1    => $item[4],
         conjunction_2 => $item[5],
         initials_2    => $item[6],
         surname_1     => $item[7],
         non_matching  => $item[8][0],
         number        => 2,
         type          => 'Mr_&_Ms_A_&_B_Smith'
      }
   }
   |


   title conjunction title initials surname non_matching(?)
   {
      # Two related people, shared initials, shared surname
      $return =
      {
         title_1       => $item[1],
         conjunction_1 => $item[2],
         title_2       => $item[3],
         initials_1    => $item[4],
         surname_1     => $item[5],
         non_matching  => $item[6][0],
         number        => 2,
         type          => 'Mr_&_Ms_A_Smith'
      }
   }
   |

   given_name surname conjunction given_name surname non_matching(?)
   {
      $return =
      {
         given_name_1  => $item[1],
         surname_1     => $item[2],
         conjunction_1 => $item[3],
         given_name_2  => $item[4],
         surname_2     => $item[5],
         non_matching  => $item[6][0],
         number        => 2,
         type          => 'John_Smith_&_Mary_Jones'
      }
   }
   |

   initials surname conjunction initials surname non_matching(?)
   {
      $return =
      {
         initials_1    => $item[1],
         surname_1     => $item[2],
         conjunction_1 => $item[3],
         initials_2    => $item[4],
         surname_2     => $item[5],
         non_matching  => $item[6][0],
         number        => 2,
         type          => 'A_Smith_&_B_Jones'
      }
   }
   |

   given_name conjunction given_name surname non_matching(?)
   {
      $return =
      {
         given_name_1  => $item[1],
         conjunction_1 => $item[2],
         given_name_2  => $item[3],
         surname_2     => $item[4],
         non_matching  => $item[5][0],
         number        => 2,
         type          => 'John_&_Mary_Smith'
      }
   }
   |

};

my $rules_single_names =
q{

    precursor(?) title given_name_standard middle_name surname suffix(?) non_matching(?)
    {
       $return =
       {
          precursor     => $item[1][0],
          title_1       => $item[2],
          given_name_1  => $item[3],
          middle_name   => $item[4],
          surname_1     => $item[5],
          suffix        => $item[6][0],
          non_matching  => $item[7][0],
          number        => 1,
          type          => 'Mr_John_Adam_Smith'
       }
    }
    |

   precursor(?) title given_name_standard single_initial surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         title_1       => $item[2],
         given_name_1  => $item[3],
         initials_1    => $item[4],
         surname_1     => $item[5],
         suffix        => $item[6][0],
         non_matching  => $item[7][0],
         number        => 1,
         type          => 'Mr_John_A_Smith'
      }
   }
   |

   precursor(?) title given_name surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         title_1       => $item[2],
         given_name_1  => $item[3],
         surname_1     => $item[4],
         suffix        => $item[5][0],
         non_matching  => $item[6][0],
         number        => 1,
         type          => 'Mr_John_Smith'
      }
   }
   |

   precursor(?) title initials surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         title_1       => $item[2],
         initials_1    => $item[3],
         surname_1     => $item[4],
         suffix        => $item[5][0],
         non_matching  => $item[6][0],
         number        => 1,
         type          => 'Mr_A_Smith'
      }
   }
   |

   precursor(?)  given_name_standard middle_name surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         given_name_1  => $item[2],
         middle_name   => $item[3],
         surname_1     => $item[4],
         suffix        => $item[5][0],
         non_matching  => $item[6][0],
         number        => 1,
         type          => 'John_Adam_Smith'
      }
   }
   |

   precursor(?) given_name_standard single_initial surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         given_name_1  => $item[2],
         initials_1    => $item[3],
         surname_1     => $item[4],
         suffix        => $item[5][0],
         non_matching  => $item[6][0],
         number        => 1,
         type          => 'John_A_Smith'
      }
   }
   |

   precursor(?) single_initial middle_name surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         initials_1    => $item[2],
         middle_name   => $item[3],
         surname_1     => $item[4],
         suffix        => $item[5][0],
         non_matching  => $item[6][0],
         number        => 1,
         type          => 'J_Adam_Smith'
      }
   }
   |

   precursor(?) given_name surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         given_name_1  => $item[2],
         surname_1     => $item[3],
         suffix        => $item[4][0],
         non_matching  => $item[5][0],
         number        => 1,
         type          => 'John_Smith'
      }
   }
   |

   precursor(?) initials surname suffix(?) non_matching(?)
   {
      $return =
      {
         precursor     => $item[1][0],
         initials_1    => $item[2],
         surname_1     => $item[3],
         suffix        => $item[4][0],
         non_matching  => $item[5][0],
         number        => 1,
         type          => 'A_Smith'
      }
   }
   |

   given_name_standard non_matching(?)
   {
      $return =
      {
         given_name_1  => $item[1],
         non_matching  => $item[2][0],
         number        => 1,
         type          => 'John'
      }
   }
   |
   
   non_matching(?)
   {
      $return =
      {
         non_matching  => $item[1][0],
         number        => 0,
         type          => 'unknown'
      }
   }
};

#------------------------------------------------------------------------------
# Individual components that a name can be composed from. Components are
# expressed as literals or Perl regular expressions.


my $titles =
q{
    title : /(MR|MS|M\/S|MRS|MISS|DR) /  
};

my $extended_titles =
q{
    |
    /(
    SIR|                     
    MESSRS| # Plural or Mr
    MADAME?|
    MME| # Madame
    MISTER|
    MASTER|
    MAST|
    MS?GR| # Monsignor
    COUNT|
    COUNTESS|
    DUKE|
    DUCHESS|
    LORD|
    LADY|
    MARQUESS|
    
    # Medical
    DOCTOR|SISTER|MATRON|
    
    # Legal
    JUDGE|
    JUSTICE|
    MAGISTRATE|
    
    # Police
    DET|INSP|CONST|
    
    # Military
    BRIGDIER|BRIG|
    CAPTAIN|CAPT|
    COLONEL|COL|
    COMMANDER IN CHIEF|COMMANDER|
    COMMODORE|
    CDR|   # Commander, Commodore
    FIELD\ MARSHALL|   
    FLIGHT\ OFFICER| FL OFF|
    FLIGHT\ LIEUTENANT|FLT LT|
    PILOT\ OFFICER|
    GENERAL\ OF\ THE\ ARMY|GENERAL|GEN|
    PTE|PVT|PRIVATE|
    SGT|SARGENT|
    AIR\ COMMANDER|
    AIR\ COMMODORE|
    AIR\ MARSHALL|
    LIEUTENANT\ COLONEL|LT\ COL|
    LT\ GEN|
    LT\ CDR|
    LIEUTENANT|LT|LEUT|LIEUT|
    MAJOR GENERAL|MAJ GEN|
    MAJOR|MAJ|
    
    # Religious
    RABBI|
    BISHOP|
    BROTHER|
    CHAPLAIN|
    FATHER|
    PASTOR|
    MOTHER\ SUPERIOR|MOTHER|
    MOST\ REVER[E|A]ND|
    MT\ REVD|V\ REVD|REVD|
    MUFTI|
    REVER[E|A]ND|
    REVD|
    REV|
    SHEIKH?|
    VERY\ REVER[E|A]ND|
    VICAR|
    
    
    
    # Other
    AMBASSADOR|
    PROFESSOR|
    PROF|
    ALDERMAN|ALD|
    COUNCILLOR
    )\ /x
};

my $common =
q{

    precursor :
        /(
        ESTATE\ OF\ THE\ LATE|
        ESTATE\ OF|
        HIS\ EXCELLENCY|
        HIS\ HONOU?R|
        HER\ EXCELLENCY|
        HER\ HONOU?R|
        THE\ RIGHT HONOU?RABLE|
        THE\ HONOU?RABLE|
        RIGHT\ HONOU?RABLE|
        THE\ RT\ HON|
        THE\ HON|
        RT\ HON    
        )\ /x
    
    conjunction : /AND |& /

    # Used in the John_A_Smith and J_Adam_Smith name types, as well as when intials are set to 1
    single_initial: /[A-Z] /

    # Examples are Jo-Anne, D'Artagnan, O'Shaugnessy La'Keishia, T-Bone
    split_given_name :  /[A-Z]{1,}['|-][A-Z]{2,} /

    constonant: /[A-DF-HJ-NP-TV-Z]]/
    
    # For use with John_Adam_Smith and John_A_Smith name types
    given_name_standard:
        /[A-Z]{3,} / |
        /[AEIOU]/ constonant / / |
        constonant /[AEIOUY] / |
        split_given_name
    
   # Patronymic, place name and other surname prefixes
    prefix:
    /(
        [A|E]L|   # ARABIC, GREEK,
        AP|       # WELSH
        BEN|      # HEBREW
        
        DELLA|DELLE|DALLE|   # ITALIAN               
        DELA|
        DELL?|
        DE\ LA|
        DE\ LOS|
        DE|
        D[A|I|U]|
        L[A|E|O]|
        
        ST|       # ABBREVIATION FOR SAINT
        SAN|      # SPANISH
        
        # DUTCH
        DEN|     
        VON\ DER|
        VON|
        VAN\ DE[N|R]|
        VAN
    )\ /x
    |
    /[D|L|O]'/ # ITALIAN, IRISH OR FRENCH, abbreviation for 'the', 'of' etc
    |
    /D[A|E]LL'/  
    
    middle_name:
    
    # Dont grab surname prefix too early. For example, John Van Dam could be
    # interpreted as middle name of Van and Surname of Dam. So exclude prefixs
    # from middle names
    ...!prefix given_name
    {
       $return = $item[2];
    }


    # Use look-ahead to avoid ambiguity between surname and suffix. For example,
    # John Smith Snr, would detect Snr as the surname and Smith as the middle name
    surname : ...!suffix first_surname second_surname(?)
    {
       if ( $item[2] and $item[3][0] )
       {
          $return = "$item[2]$item[3][0]";
       }
       else
       {
          $return = $item[2];
       }
    }
    
    first_surname : prefix name
    {
       $return = "$item[1]$item[2]";
    }
    |
    name


    second_surname : '-' name
    {
       if ( $item[1] and $item[2] )
       {
          $return = "$item[1]$item[2]";
       }
    }
   
   # Note space will not occur for first part of a hphenated surname
   # AddressParse::_valid_name will do further check on name context 
    name : /[A-Z]{2,} ?/  

  
   suffix:

    /(
    ESQUIRE|
    ESQ |
    SN?R| # Senior
    JN?R| # Junior
    PHD |
    MD  |
    LLB |

    XI{1,3}| # 11th, 12th, 13th
    X       | # 10th
    IV      | # 4th
    VI{1,3} | # 6th, 7th, 8th
    V       | # 5th
    IX      | # 9th
    I{1,3}     # 1st, 2nd, 3rd
    )\ /x  


    # One or more characters. 
    non_matching: /.*/     
};

# Define given name combinations, specifying the minimum number of letters.
# The correct pair of rules is determined by the 'initials' key in the hash
# passed to the 'new' method.


my $given_name_min_2 = q{ given_name : given_name_standard  };

# Joe, Jo-Anne ...
my $given_name_min_3 =
q{
    given_name: /[A-Z]{3,} / | split_given_name
};


# John ...
my $given_name_min_4 =
q{
    given_name: /[A-Z]{4,} / | split_given_name
};


# Define initials combinations specifying the minimum and maximum letters.
# Order from most complex to simplest,  to avoid premature matching.

# 'A'
my $initials_1 = q{ initials : single_initial };

#'AB' 'A B'

my $initials_2 =
q{
   initials:  /([A-Z] ){1,2}/ | /([A-Z]){1,2} /
};

# 'ABC' or 'A B C'
my $initials_3 =
q{
   initials: /([A-Z] ){1,3}/ | /([A-Z]){1,3} /
};


#-------------------------------------------------------------------------------
# Assemble correct combination for grammar tree.

sub _create
{
   my $name = shift;

   my $grammar = $rules_start;
   

   if ( $name->{joint_names} )
   {
       $grammar .= $rules_joint_names;
   }
   $grammar .= $rules_single_names;
   
   
   $grammar .= $common;
   
   $grammar .= $titles;

    if ( $name->{extended_titles} )
    {
        $grammar .= $extended_titles;
    }

   $name->{initials} > 3 and $name->{initials} = 3;
   $name->{initials} < 1 and $name->{initials} = 1;

   # Define limit of when a string is treated as an initial, or
   # a given name. For example, if initials are set to 2, MR TO SMITH
   # will have initials of T & O and no given name, but MR TOM SMITH will
   # have no initials, and a given name of Tom.
   


   if ( $name->{initials} == 1 )
   {
      $grammar .= $given_name_min_2 . $initials_1;
   }
   elsif ( $name->{initials} == 2 )
   {
      $grammar .=  $initials_2 . $given_name_min_3;
   }
   elsif ( $name->{initials} == 3 )
   {
      $grammar .= $given_name_min_4 . $initials_3;
   }

 
   return($grammar);
}
#-------------------------------------------------------------------------------
1;
