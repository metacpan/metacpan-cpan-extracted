package Language::Dashrep;

use 5.010;
use warnings;
use strict;
use Carp;
require Exporter;


=head1 NAME

Language::Dashrep - Dashrep language translator/interpreter

=cut


=head1 VERSION

Version 2.33

=cut

our $VERSION = '2.33';


=head1 SYNOPSIS

The following sample code executes the Dashrep-language actions specified in the standard input file.

   use Language::Dashrep;
   &Dashrep::dashrep_linewise_translate( );

The module also supports direct access to functions that define Dashrep phrases, expand text that contains Dashrep phrases, and more.

=cut


=head1 ABOUT

Dashrep (TM) is a versatile descriptive programming language that recognizes hyphenated phrases, such as B<rectangle-outline-attention-begin>, and recursively expands the phrases to generate an HTML web page, an XML file, a JavaScript program, a boilerplate-based document, a template-based email message, or any other text-based content.

See www.Dashrep.org for details about the Dashrep language.

Although Dashrep code is not directly executable, it can generate executable code.  Although it does not directly define loops, it generates lists in which any delimited (using commas and/or spaces) list of text strings (including integers) specifies the unique values for the list items.  Although the Dashrep language does not directly implement a branching structure, the translated code can be completely changed at any level (including within lists) based on parameterized hyphenated phrases such as B<[-template-for-move-proposal-link-for-action-[-output-requested-action-]-]>.

The Dashrep language has been used to convert text files into MML- and XML-format files (for two books, I<The Creative Problem Solver's Toolbox> and I<Ending The Hidden Unfairness In U.S. Elections>), specify dynamically generated HTML pages (at www.VoteFair.org and www.NegotiationTool.com), generate JavaScript code (that Adobe Illustrator executed to generate vector graphics for use in the book I<Ending The Hidden Unfairness In U.S. Elections>), generate invoices and packing slips, expand boilerplate-like text, and more.

The design goals for the Dashrep language were:

=over

=item * Provide a convenient way to move descriptive code out of executable code.

=item * Keep it simple, and keep it flexible.

=item * Make the language speakable.  (This characteristic is useful for various purposes, including circumventing keyboard-induced repetitive-stress injury, and using microphone-equipped mobile devices.)

Note about Version 2 and later: These versions, if they are from GitHub instead of CPAN, can be used without the CPAN envioronment.  The GitHub version only needs the Perl interpreter, which means that on the Windows operating system only the I<perl.exe> and I<perl512.dll> and I<libgcc_s_sjlj-1.dll> files (or their more-recent equivalents) are needed.

=back

=cut


=head1 EXPORT

The following subroutines are exported.

=head2 dashrep_define

=head2 dashrep_import_replacements

=head2 dashrep_get_replacement

=head2 dashrep_get_list_of_phrases

=head2 dashrep_delete

=head2 dashrep_delete_all

=head2 dashrep_expand_parameters

=head2 dashrep_expand_phrases

=head2 dashrep_expand_phrases_except_special

=head2 dashrep_expand_special_phrases

=head2 dashrep_xml_tags_to_dashrep

=head2 dashrep_top_level_action

=head2 dashrep_linewise_translate

=cut


our @ISA = qw(Exporter);
our @EXPORT = qw(
    dashrep_define
    dashrep_import_replacements
    dashrep_get_replacement
    dashrep_get_list_of_phrases
    dashrep_delete
    dashrep_delete_all
    dashrep_expand_parameters
    dashrep_expand_phrases
    dashrep_expand_phrases_except_special
    dashrep_expand_special_phrases
    dashrep_xml_tags_to_dashrep
    dashrep_top_level_action
    dashrep_linewise_translate
);


#-----------------------------------------------
#  This Perl code is intentionally written
#  in a subset of Perl and uses a C-like
#  syntax so that it can be ported more
#  easily to other languages, especially
#  the C language for faster execution.
#
#  If you offer improvements to this code,
#  please follow this convention so that
#  the code continues to be easily converted
#  into other languages.
#-----------------------------------------------


#-----------------------------------------------
#  Declare package variables.

my $global_true ;
my $global_false ;
my $global_endless_loop_counter ;
my $global_endless_loop_counter_limit ;
my $global_nesting_level_of_file_actions ;
my $global_xml_level_number ;
my $global_xml_accumulated_sequence_of_tag_names ;
my $global_spaces ;
my $global_ignore_level ;
my $global_capture_level ;
my $global_phrase_to_insert_after_next_top_level_line ;
my $global_top_line_count_for_insert_phrase ;
my %global_dashrep_replacement ;
my %global_replacement_count_for_item_name ;
my %global_exists_xml_hyphenated_phrase ;
my @global_list_of_lists_to_generate ;
my @global_xml_tag_at_level_number ;


#-----------------------------------------------
#  Define package constants, and initialize
#  special phrases.

BEGIN {
    $global_true = 1 ;
    $global_false = 0 ;
    $global_endless_loop_counter = 0 ;
    $global_endless_loop_counter_limit = 70000 ;
    $global_xml_accumulated_sequence_of_tag_names = "" ;
    $global_spaces = "                                                                              " ;
    $global_nesting_level_of_file_actions = 0 ;
    $global_ignore_level = 0 ;
    $global_capture_level = 0 ;
    $global_xml_level_number = 0 ;
    %global_replacement_count_for_item_name = ( ) ;
    @global_list_of_lists_to_generate = ( ) ;
    @global_xml_tag_at_level_number = ( ) ;

    %global_dashrep_replacement = ( ) ;
    $global_dashrep_replacement{ "dashrep-comments-ignored" } = "" ;
    $global_dashrep_replacement{ "dashrep-endless-loop-counter-limit" } = "" ;
    $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-ignore-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-ignore-level" } = "" ;
    $global_dashrep_replacement{ "dashrep-capture-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-capture-level" } = "" ;
    $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-first-xml-tag-name" } = "" ;
    $global_dashrep_replacement{ "dashrep-xml-yes-handle-open-close-tag-" } = "" ;
    $global_dashrep_replacement{ "dashrep-xml-yes-handle-open-close-tag-" } = "" ;
    $global_dashrep_replacement{ "dashrep-yes-or-no-export-delimited-definitions" } = "" ;
}


=head1 FUNCTIONS


=head2 initialize_special_phrases

Initialize the phrases with special "dashrep_..."
names.

=cut

#-----------------------------------------------
#-----------------------------------------------
#                 initialize_special_phrases
#-----------------------------------------------
#-----------------------------------------------

sub initialize_special_phrases
{
    $global_dashrep_replacement{ "dashrep-comments-ignored" } = "" ;
    $global_dashrep_replacement{ "dashrep-endless-loop-counter-limit" } = "" ;
    $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-ignore-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-ignore-level" } = "" ;
    $global_dashrep_replacement{ "dashrep-capture-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-capture-level" } = "" ;
    $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } = "" ;
    $global_dashrep_replacement{ "dashrep-first-xml-tag-name" } = "" ;
    $global_dashrep_replacement{ "dashrep-xml-yes-handle-open-close-tag-" } = "" ;
    $global_dashrep_replacement{ "dashrep-xml-yes-handle-open-close-tag-" } = "" ;
    $global_dashrep_replacement{ "dashrep-yes-or-no-export-delimited-definitions" } = "" ;
}


=head2 dashrep_define

Associates a replacement text string with
the specified hyphenated phrase.

First parameter is the hyphenated phrase.
Second parameter is its replacement text
string.

Return value is 1 if the definition is
successful.  Return value is zero if there
are not exactly two parameters.

=cut

#-----------------------------------------------
#-----------------------------------------------
#                 dashrep_define
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_define
{

    my $phrase_name ;
    my $expanded_text ;


#-----------------------------------------------
#  Do the assignment.

    if ( scalar( @_ ) == 2 )
    {
        $phrase_name = $_[ 0 ] ;
        $expanded_text = $_[ 1 ] ;
        $phrase_name =~ s/^ +// ;
        $phrase_name =~ s/ +$// ;
        $global_dashrep_replacement{ $phrase_name } = $expanded_text ;
    } else
    {
       carp "Warning: Call to dashrep_define subroutine does not have exactly two parameters." ;
        return 0 ;
    }


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}


=head2 dashrep_import_replacements

Parses text that associates Dashrep phrases
with the definitions for those phrases.

First, and only, parameter is the text
string that uses the Dashrep language.

Return value is the count for how many
hyphenated phrases were defined (or
redefined).  Return value is zero if
there is not exactly one parameter.

=cut

#-----------------------------------------------
#-----------------------------------------------
#                dashrep_import_replacements
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_import_replacements
{

    my $definition_name ;
    my $definition_value ;
    my $input_string ;
    my $replacements_text_to_import ;
    my $text_before ;
    my $text_including_comment_end ;
    my $text_after ;
    my $do_nothing ;
    my @list_of_replacement_names ;
    my @list_of_replacement_strings ;


#-----------------------------------------------
#  Get the text that contains replacement
#  definitions.

    if ( scalar( @_ ) == 1 )
    {
        $replacements_text_to_import = $_[ 0 ] ;
    } else
    {
       carp "Warning: Call to dashrep_import_replacements subroutine does not have exactly one parameter." ;
        return 0 ;
    }
    if ( not( defined( $replacements_text_to_import ) ) )
    {
        $replacements_text_to_import = "" ;
        if ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" )
        {
            print "{{trace; imported zero definitions from empty text}}\n" ;
        }
    }


#-----------------------------------------------
#  If the supplied text is empty, indicate this
#  case and return.

    if ( $replacements_text_to_import !~ /[^ ]/ )
    {
        if ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" )
        {
            print "{{trace; imported zero definitions from empty text}}\n" ;
        }
        return 0 ;
    }


#-----------------------------------------------
#  Reset the "ignore" and "capture" levels.

    $global_ignore_level = 0 ;
    $global_capture_level = 0 ;


#-----------------------------------------------
#  Initialization.

    @list_of_replacement_names = ( ) ;


#-----------------------------------------------
#  Replace line breaks, and tabs, with spaces.

    $replacements_text_to_import =~ s/[\n\r\t]+/ /sg ;
    $replacements_text_to_import =~ s/[\n\r\t]+/ /sg ;
    $replacements_text_to_import =~ s/  +/ /sg ;


#-----------------------------------------------
#  Ignore comments that consist of, or are embedded
#  in, strings of the following types:
#    *------  -------*
#    /------  -------/

    $replacements_text_to_import =~ s/\*\-\-\-+\*/ /g ;
    $replacements_text_to_import =~ s/\/\-\-\-+\// /g ;
    while ( $replacements_text_to_import =~ /^(.*?)([\*\/]\-\-+)(.*)$/ )
    {
        $text_before = $1 ;
        $global_dashrep_replacement{ "dashrep-comments-ignored" } .= "  " . $2 ;
        $text_including_comment_end = $3 ;
        $text_after = "" ;
        if ( $text_including_comment_end =~ /^(.*?\-\-+[\*\/])(.*)$/ )
        {
            $global_dashrep_replacement{ "dashrep-comments-ignored" } .= $1 . "  " ;
            $text_after = $2 ;
        }
        $replacements_text_to_import = $text_before . " " . $text_after ;
    }


#-----------------------------------------------
#  Split the replacement text at spaces,
#  and put the strings into an array.

    $replacements_text_to_import =~ s/  +/ /g ;
    @list_of_replacement_strings = split( / / , $replacements_text_to_import ) ;


#-----------------------------------------------
#  Read and handle each item in the array.

    $definition_name = "" ;
    foreach $input_string ( @list_of_replacement_strings )
    {
        if ( $input_string =~ /^ *$/ )
        {
            $do_nothing ++ ;


#-----------------------------------------------
#  Ignore the "define-begin" directive.

        } elsif ( $input_string eq 'define-begin' )
        {
            $do_nothing ++ ;


#-----------------------------------------------
#  Ignore the "dashrep-definitions-begin" and
#  "dashrep-definitions-end" directives.

        } elsif ( ( $input_string eq 'dashrep-definitions-begin' ) || ( $input_string eq 'dashrep-definitions-end' ) )
        {
            $do_nothing ++ ;


#-----------------------------------------------
#  When the "define-end" directive, or a series
#  of at least 3 dashes ("--------"), is encountered,
#  clear the definition name.
#  Also remove trailing spaces from the previous
#  replacement.

        } elsif ( ( $input_string eq 'define-end' ) || ( $input_string =~ /^---+$/ ) )
        {
            $definition_value = $global_dashrep_replacement{ $definition_name } ;
            $definition_value =~ s/ +$// ;
            if ( $definition_value =~ /[^ \n\r]/ )
            {
                $global_dashrep_replacement{ $definition_name } = $definition_value ;
            } else
            {
                $global_dashrep_replacement{ $definition_name } = "" ;
            }
            $definition_name = "" ;


#-----------------------------------------------
#  Get a definition name.
#  Allow a colon after the hyphenated name.
#  If this definition name has already been defined,
#  ignore the earlier definition.
#  If the name does not contain a hyphen,
#  prefix the name with "invalid-phrase-name-".

        } elsif ( $definition_name eq "" )
        {
            $definition_name = $input_string ;
            $definition_name =~ s/\:$//  ;
            if ( $definition_name !~ /\-/ )
            {
                $definition_name = "invalid-phrase-name-" . $definition_name ;
            }
            $global_dashrep_replacement{ $definition_name } = "" ;
            push( @list_of_replacement_names , $definition_name ) ;


#-----------------------------------------------
#  Collect any text that is part of a definition.
#  But do not allow the definition to include
#  the name of the phrase being defined (because
#  that would cause an endless loop when the
#  phrase is replaced).

        } elsif ( $input_string ne "" )
        {
            if ( $input_string eq $definition_name )
            {
                 $global_dashrep_replacement{ $definition_name } = "ERROR: Replacement for the hyphenated phrase:\n    " . $definition_name . "\n" . "includes itself, which would cause an endless replacement loop." . "\n" ;
                carp "Warning: Replacement for the hyphenated phrase:\n    " . $definition_name . "\n" . "includes itself, which would cause an endless replacement loop.". "\n" . "Error occurred " ;
            } else
            {
                if ( $global_dashrep_replacement{ $definition_name } ne "" )
                {
                    $global_dashrep_replacement{ $definition_name } .= " " ;
                }
                $global_dashrep_replacement{ $definition_name } = $global_dashrep_replacement{ $definition_name } . $input_string ;
            }
        }


#-----------------------------------------------
#  Repeat the loop for the next string.

    }


#-----------------------------------------------
#  End of subroutine.

    return $#list_of_replacement_names + 1 ;

}


=head2 dashrep_get_replacement

Gets/returns the replacement text string that
is associated with the specified hyphenated
phrase.

First, and only, parameter is the hyphenated
phrase.

Return value is the replacement string that
is associated with the specified hyphenated
phrase.  Return value is an empty string if
there is not exactly one parameter.

=cut

#-----------------------------------------------
#-----------------------------------------------
#                 dashrep_get_replacement
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_get_replacement
{

    my $phrase_name ;
    my $expanded_text ;


#-----------------------------------------------
#  Get the name of the hyphenated phrase.

    if ( scalar( @_ ) == 1 )
    {
        $phrase_name = $_[ 0 ] ;
    } else
    {
        $expanded_text = "" ;
        return $expanded_text ;
    }


#-----------------------------------------------
#  Get the replacement text that is associated
#  with the hyphenated phrase.

    if ( ( exists( $global_dashrep_replacement{ $phrase_name } ) ) && ( $global_dashrep_replacement{ $phrase_name } =~ /[^ ]/ ) )
    {
        $expanded_text = $global_dashrep_replacement{ $phrase_name } ;
    } else
    {
        $expanded_text = "" ;
    }


#-----------------------------------------------
#  End of subroutine.

    return $expanded_text ;

}


=head2 dashrep_get_list_of_phrases

Returns an array that lists all the
hyphenated phrases that have been defined
so far.

There are no parameters.

Return value is an array that lists all the
hyphenated phrases that have been defined.
Return value is an empty array if there is
not exactly zero parameters.

=cut

#-----------------------------------------------
#-----------------------------------------------
#           dashrep_get_list_of_phrases
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_get_list_of_phrases
{

    my @list_of_phrases ;

    if ( scalar( @_ ) != 0 )
    {
       carp "Warning: Call to dashrep_define subroutine does not have exactly zero parameters." ;
        @list_of_phrases = ( ) ;
        return @list_of_phrases ;
    }

    @list_of_phrases = keys( %global_dashrep_replacement ) ;
    return @list_of_phrases ;

}


=head2 dashrep_delete

Deletes the specified hyphenated phrase.

First parameter is the hyphenated phrase.

Return value is 1 if the deletion is
successful.  Return value is zero if there
is not exactly one parameter.

=cut

#-----------------------------------------------
#-----------------------------------------------
#                 dashrep_delete
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_delete
{

    my $phrase_name ;


#-----------------------------------------------
#  Delete the indicated phrase.

    if ( scalar( @_ ) == 1 )
    {
        $phrase_name = $_[ 0 ] ;
        $phrase_name =~ s/^ +// ;
        $phrase_name =~ s/ +$// ;
        delete( $global_dashrep_replacement{ $phrase_name } );
    } else
    {
       carp "Warning: Call to dashrep_delete subroutine does not have exactly one parameter." ;
        return 0 ;
    }


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}


=head2 dashrep_delete_all

Deletes all the hyphenated phrases.

There are no parameters.

Return value is 1 if the deletion is
successful.  Return value is zero if there
is not exactly zero parameters.

=cut

#-----------------------------------------------
#-----------------------------------------------
#                 dashrep_delete_all
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_delete_all
{


#-----------------------------------------------
#  Reset the "ignore" and "capture" levels.

    $global_ignore_level = 0 ;
    $global_capture_level = 0 ;


#-----------------------------------------------
#  Reset the xml-parsing state.

    $global_xml_level_number = 0 ;
    @global_xml_tag_at_level_number = ( ) ;


#-----------------------------------------------
#  Delete all the phrases.

    if ( scalar( @_ ) == 0 )
    {
        %global_dashrep_replacement = ( );
        &initialize_special_phrases( ) ;
    } else
    {
       carp "Warning: Call to dashrep_delete_all subroutine does not have exactly zero parameters." ;
        return 0 ;
    }


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}


=head2 dashrep_expand_parameters

Parses a text string that is written in the
Dashrep language and handles parameter
replacements and special operations.  The
special operations must be within
"[- ... -]" text strings.
If the supplied text string is just a
hyphenated phrase, it is expanded to its
replacement string.  Otherwise, any
hyphenated phrase that does not appear
within the square-bracket pattern is
not replaced.  (Those hyphenated phrases
must be replaced using either the
dashrep_expand_phrases,
dashrep_expand_phrases_except_special,
or dashrep_expand_special_phrases subroutines.)

First, and only, parameter is the text -- or
hyphenated phrase -- that is to be expanded.

Return value is the text after expanding
any parameters.  Return value is an empty
string if there is not exactly one parameter.

=cut

#-----------------------------------------------
#-----------------------------------------------
#       dashrep_expand_parameters
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_expand_parameters
{

    my $supplied_text ;
    my $replacement_text ;
    my $loop_status_done ;
    my $text_begin ;
    my $text_parameter_name ;
    my $text_parameter_value ;
    my $text_end ;
    my $action_name ;
    my $object_of_action ;
    my $count ;
    my $zero_one_multiple ;
    my $empty_or_nonempty ;
    my $full_length ;
    my $length_half ;
    my $string_beginning ;
    my $string_end ;
    my $same_or_not_same ;
    my $sorted_numbers ;
    my $text_parameter_placeholder ;
    my $text_parameter ;
    my $name_for_count ;
    my $text_for_value ;
    my $possible_new_limit ;
    my $text_parameter_content ;
    my $source_phrase ;
    my $target_phrase ;
    my $comparison_type ;
    my $first_number_text ;
    my $second_number_text ;
    my $first_number ;
    my $second_number ;
    my $yes_or_no ;
    my $first_object_of_action ;
    my $second_object_of_action ;
    my @list ;
    my @list_of_sorted_numbers ;
    my @list_of_replacements_to_auto_increment ;


#-----------------------------------------------
#  Get the hyphenated phrase or supplied string.

    if ( scalar( @_ ) == 1 )
    {
        $supplied_text = $_[ 0 ] ;
    } else
    {
        $replacement_text = "" ;
        return $replacement_text ;
    }


#-----------------------------------------------
#  Use the supplied text as the default result,
#  without leading or trailing spaces.

    $replacement_text = $supplied_text ;
    $replacement_text =~ s/^ +//sg;
    $replacement_text =~ s/ +$//sg;


#-----------------------------------------------
#  If just a hyphenated phrase was supplied,
#  expand it into its replacement text.

    if ( $supplied_text =~ /^ *([^\- ]+-[^ ]*[^\- ]) *$/ )
    {
        $supplied_text = $1 ;
        if ( ( exists( $global_dashrep_replacement{ $supplied_text } ) ) && ( $global_dashrep_replacement{ $supplied_text } =~ /[^ ]/ ) )
        {
            $replacement_text = $global_dashrep_replacement{ $supplied_text } ;
        }
    }


#-----------------------------------------------
#  Initialize the list of replacement names
#  encountered that need to be auto-incremented.

    @list_of_replacements_to_auto_increment = ( ) ;


#-----------------------------------------------
#  Update the endless loop count limit in case
#  it has changed.

    if ( $global_dashrep_replacement{ "dashrep-endless-loop-counter-limit" } =~ /^[0-9]+$/ )
    {
        $possible_new_limit = $global_dashrep_replacement{ "dashrep-endless-loop-counter-limit" } + 0 ;
        if ( ( $possible_new_limit != $global_endless_loop_counter_limit ) && ( $possible_new_limit > 1000 ) )
        {
            $global_endless_loop_counter_limit = $possible_new_limit ;
            if ( ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" ) && ( $replacement_text =~ /[^ ]/ ) )
            {
                print "{{trace; updated endless loop counter limit: " . $possible_new_limit . "}}\n";
            }
        }
    }


#-----------------------------------------------
#  Begin a loop that repeats until there have
#  been no more replacements.

    $loop_status_done = $global_false ;
    while ( $loop_status_done == $global_false )
    {
        $loop_status_done = $global_true ;

        if ( ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" ) && ( $replacement_text =~ /[^ ]/ ) )
        {
            print "{{trace; replacement string: " . $replacement_text . "}}\n";
        }


#-----------------------------------------------
#  Get the next inner-most parameter syntax --
#  with "[-" at the beginning and "-]" at the end.
#  (It must not contain a nested parameter syntax.)

        if ( $replacement_text =~ /^(.*?)\[\-([^\[\]]*)\-\](.*)$/ )
        {
            $text_begin = $1 ;
            $text_parameter_content = $2 ;
            $text_end = $3 ;
            $text_parameter_content =~ s/^ +// ;
            $text_parameter_content =~ s/ +$// ;
            $loop_status_done = $global_false ;

            if ( ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" ) && ( $text_parameter_content =~ /[^ ]/ ) )
            {
                print "{{trace; innermost parameter: " . $text_parameter_content . "}}\n";
            }


#-----------------------------------------------
#  If the parameter is a defined phrase, do the
#  replacement.

            if ( ( $text_parameter_content !~ / / ) && ( exists( $global_dashrep_replacement{ $text_parameter_content } ) ) )
            {
                $text_parameter = $global_dashrep_replacement{ $text_parameter_content } ;
                if ( $text_parameter =~ /[^ ]/ )
                {
                    $replacement_text = $text_begin . $text_parameter . $text_end ;
                    $global_replacement_count_for_item_name{ $text_parameter_content } ++ ;
                    $loop_status_done = $global_false ;
                    if ( $text_parameter_content =~ /^auto-increment-/ )
                    {
                        push( @list_of_replacements_to_auto_increment , $text_parameter_content ) ;
                    }
                } else
                {
                    $replacement_text = $text_begin . " " . $text_end ;
                    $loop_status_done = $global_false ;
                }


#-----------------------------------------------
#  If there is a parameter value assigned -- as
#  indicated by an equal sign -- then assign
#  the value.
#
#  Problems will arise if the parameter value
#  contains a space, bracket, colon, or equal
#  sign, but in those cases just specify a
#  replacement name instead of the value of
#  that replacement.

            } elsif ( $text_parameter_content =~ /^ *([^ \n\:=]+) *= *([^ \n\:=]+) *$/ )
            {
                $text_parameter_name = $1 ;
                $text_parameter_value = $2 ;
                $text_parameter_value =~ s/[\- ]+$// ;
                if ( length( $text_parameter_name ) > 0 )
                {
                    $global_dashrep_replacement{ $text_parameter_name } = $text_parameter_value ;
                    $global_replacement_count_for_item_name{ $text_parameter_name } ++ ;
                }
                $replacement_text = $text_begin . " " . $text_end ;
                $global_replacement_count_for_item_name{ $text_parameter_value } ++ ;
                if ( ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" ) && ( $text_parameter_name =~ /[^ ]/ ) )
                {
                    print "{{trace; assignment: " . $text_parameter_name . " = " . $text_parameter_value . "}}\n";
                }


#-----------------------------------------------
#  Handle the two-operand action:
#  append-from-phrase-to-phrase

            } elsif ( $text_parameter_content =~ /^append-from-phrase-to-phrase *: *([^\n\:=]*) +([^\n\:=]*)$/ )
            {
                $source_phrase = $1 ;
                $target_phrase = $2 ;
                $global_dashrep_replacement{ $target_phrase } .= " " . $global_dashrep_replacement{ $source_phrase } ;
                if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
                {
                    print "{{trace; appended from phrase " . $source_phrase . " to phrase " . $target_phrase . "}}\n" ;
                }
                $replacement_text = $text_begin . " " . $text_end ;


#-----------------------------------------------
#  Handle these two-operand actions:
#  yes-or-no-first-number-equals-second-number
#  yes-or-no-first-number-greater-than-second-number
#  yes-or-no-first-number-less-than-second-number

            } elsif ( $text_parameter_content =~ /^(yes-or-no-first-number-((equals)|(greater-than)|(less-than))-second-number) *: *([0-9\,]+) +([0-9\,]+)$/ )
            {
                $comparison_type = $2 ;
                $first_number_text = $6 ;
                $second_number_text = $7 ;
                $first_number = $first_number_text + 0 ;
                $second_number = $second_number_text + 0 ;
                if ( ( $comparison_type eq "equals" ) && ( $first_number == $second_number ) )
                {
                    $yes_or_no = "yes" ;
                } elsif ( ( $comparison_type eq "greater-than" ) && ( $first_number > $second_number ) )
                {
                    $yes_or_no = "yes" ;
                } elsif ( ( $comparison_type eq "less-than" ) && ( $first_number < $second_number ) )
                {
                    $yes_or_no = "yes" ;
                } else
                {
                    $yes_or_no = "no" ;
                }
                if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
                {
                    print "{{trace; comparison of type " . $comparison_type . " for numbers " . $first_number_text . " and " . $second_number_text . "}}\n" ;
                }
                $replacement_text = $text_begin . $yes_or_no . $text_end ;


#-----------------------------------------------
#  If there is an action requested (which
#  may include a colon between the action and
#  its operand(s), handle it.

            } elsif ( $text_parameter_content =~ /^([^ \n\:=]+-[^ \n\:=]+) *[: ] *([^\n\:=]*)$/ )
            {
                $action_name = $1 ;
                $object_of_action = $2 ;
                $object_of_action =~ s/\-+$// ;
                $object_of_action =~ s/^ +// ;
                $object_of_action =~ s/ +$// ;
                if ( $object_of_action =~ /^([^ ]+) +(.+)$/ )
                {
                    $first_object_of_action = $1 ;
                    $second_object_of_action = $2 ;
                }

                if ( ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" ) && ( $action_name =~ /[^ ]/ ) )
                {
                    print "{{trace; action and object: " . $action_name . " : " . $object_of_action . "}}\n";
                }


#-----------------------------------------------
#  Handle the action:
#  first-item-in-list

                if ( $action_name eq "first-item-in-list" )
                {
                    @list = &dashrep_internal_split_delimited_items( $object_of_action ) ;
                    $count = $#list + 1 ;
                    $text_for_value = " " ;
                    if ( $count > 0 )
                    {
                        $text_for_value = $list[ 0 ] ;
                    }
                    $replacement_text = $text_begin . $text_for_value . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  last-item-in-list

                } elsif ( $action_name eq "last-item-in-list" )
                {
                    @list = &dashrep_internal_split_delimited_items( $object_of_action ) ;
                    $count = $#list + 1 ;
                    $text_for_value = " " ;
                    if ( $count > 0 )
                    {
                        $text_for_value = $list[ $#list ] ;
                    }
                    $replacement_text = $text_begin . $text_for_value . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  count-of-list

                } elsif ( $action_name eq "count-of-list" )
                {
                    if ( $object_of_action =~ /[^ ]/ )
                    {
                        @list = &dashrep_internal_split_delimited_items( $object_of_action ) ;
                        $count = $#list + 1 ;
                        if ( $count > 0 )
                        {
                            $text_for_value = $count ;
                        } else
                        {
                            $text_for_value = "0" ;
                        }
                    } else
                    {
                        $text_for_value = "0" ;
                    }
                    $replacement_text = $text_begin . $text_for_value . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  zero-one-multiple-count-of-list

                } elsif ( $action_name eq "zero-one-multiple-count-of-list" )
                {
                    if ( $object_of_action =~ /[^ ]/ )
                    {
                        @list = &dashrep_internal_split_delimited_items( $object_of_action ) ;
                        $count = $#list + 1 ;
                        if ( $count == 0 )
                        {
                            $name_for_count = "zero" ;
                        } elsif ( $count == 1 )
                        {
                            $name_for_count = "one" ;
                        } elsif ( $count > 1 )
                        {
                            $name_for_count = "multiple" ;
                        }
                    } else
                    {
                        $name_for_count = "zero" ;
                    }
                    $replacement_text = $text_begin . $name_for_count . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  zero-one-multiple

                } elsif ( $action_name eq "zero-one-multiple" )
                {
                    if ( $object_of_action + 0 <= 0 )
                    {
                        $zero_one_multiple = "zero" ;
                    } elsif ( $object_of_action + 0 == 1 )
                    {
                        $zero_one_multiple = "one" ;
                    } else
                    {
                        $zero_one_multiple = "multiple" ;
                    }
                    $replacement_text = $text_begin . $zero_one_multiple . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  empty-or-nonempty

                } elsif ( $action_name eq "empty-or-nonempty" )
                {
                    if ( $object_of_action =~ /[^ \n\t]/ )
                    {
                        $empty_or_nonempty = "nonempty" ;
                    } else
                    {
                        $empty_or_nonempty = "empty" ;
                    }
                    $replacement_text = $text_begin . $empty_or_nonempty . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  empty-or-nonempty-phrase

                } elsif ( $action_name eq "empty-or-nonempty-phrase" )
                {
                    $empty_or_nonempty = "empty" ;
                    if ( $object_of_action =~ /[^ \n\t]/ )
                    {
                        if ( exists( $global_dashrep_replacement{ $object_of_action } ) )
                        {
                            if ( $global_dashrep_replacement{ $object_of_action } =~ /[^ \n\t]/ )
                            {
                                $empty_or_nonempty = "nonempty" ;
                            }
                        }
                    }
                    $replacement_text = $text_begin . $empty_or_nonempty . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  same-or-not-same

                } elsif ( $action_name eq "same-or-not-same" )
                {
                    $full_length = length( $object_of_action ) ;
                    $length_half = int( $full_length / 2 ) ;
                    $string_beginning = substr( $object_of_action , 0 , $length_half ) ;
                    $string_end = substr( $object_of_action , $full_length - $length_half , $length_half ) ;
                    if ( $string_beginning eq $string_end )
                    {
                        $same_or_not_same = "same" ;
                    } else
                    {
                        $same_or_not_same = "not-same" ;
                    }
                    $replacement_text = $text_begin . $same_or_not_same . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  sort-numbers

                } elsif ( $action_name eq "sort-numbers" )
                {
                    if ( $object_of_action =~ /[1-9]/ )
                    {
                        $object_of_action =~ s/ +/,/gs ;
                        $object_of_action =~ s/^,// ;
                        $object_of_action =~ s/,$// ;
                        @list = split( /,+/ , $object_of_action ) ;
                        @list_of_sorted_numbers = sort { $a <=> $b } @list ;
                        $sorted_numbers = join( "," , @list_of_sorted_numbers ) ;
                    } else
                    {
                        $sorted_numbers = " " ;
                    }
                    $replacement_text = $text_begin . $sorted_numbers . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  unique-value
#
#  Currently this action is equivalent to the
#  auto-increment action.
#  It can be changed to accomodate a
#  parallel-processing environment where the
#  code here would assign values from separate
#  blocks of numbers assigned to each
#  processor/process.

                } elsif ( $action_name eq "unique-value" )
                {
                    if ( exists( $global_dashrep_replacement{ $object_of_action } ) )
                    {
                        $global_dashrep_replacement{ $object_of_action } = $global_dashrep_replacement{ $object_of_action } + 1 ;
                    } else
                    {
                        $global_dashrep_replacement{ $object_of_action } = 1 ;
                    }
                    $replacement_text = $text_begin . " " . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  auto-increment

                } elsif ( $action_name eq "auto-increment" )
                {
                    if ( exists( $global_dashrep_replacement{ $object_of_action } ) )
                    {
                        $global_dashrep_replacement{ $object_of_action } = $global_dashrep_replacement{ $object_of_action } + 1 ;
                    } else
                    {
                        $global_dashrep_replacement{ $object_of_action } = 1 ;
                    }
                    $replacement_text = $text_begin . " " . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  create-list-named

                } elsif ( $action_name eq "create-list-named" )
                {
                    push ( @global_list_of_lists_to_generate , $object_of_action ) ;
                    $replacement_text = $text_begin . " " . $text_end ;


#-----------------------------------------------
#  Handle the action:
#  insert-phrase-with-brackets-after-next-top-line
#  For now, just get the phrase name.

                } elsif ( $action_name eq "insert-phrase-with-brackets-after-next-top-line" )
                {
                    $global_phrase_to_insert_after_next_top_level_line = $object_of_action ;
                    $global_top_line_count_for_insert_phrase = 1 ;
                    $replacement_text = $text_begin . " " . $text_end ;
                    if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
                    {
                        print "{{trace; got phrase to insert after next line: " . $global_phrase_to_insert_after_next_top_level_line . "}}\n" ;
                    }


#-----------------------------------------------
#  Terminate the branching that handles a
#  parameter that looks like it might begin with
#  an action name, but doesn't.  Just leave the
#  text unchanged, but remove the "[-" and "-]"
#  strings.

                } else
                {
                    if ( ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" ) && ( $action_name =~ /[^ ]/ ) )
                    {
                        print "{{trace; action not recognized: " . $action_name . "}}\n";
                    }
                    $replacement_text = $text_begin . " " . $text_parameter_content . " " . $text_end ;
                }


#-----------------------------------------------
#  If the parameter content has not been
#  recognized, simply remove the "[-" and "-]"
#  strings.

            } else
            {
                $replacement_text = $text_begin . $text_parameter_content . $text_end ;
            }


#-----------------------------------------------
#  Avoid an endless loop (caused by a replacement
#  containing, at some level, itself).

            $global_endless_loop_counter ++ ;
            if ( $global_endless_loop_counter > $global_endless_loop_counter_limit )
            {
                &dashrep_internal_endless_loop_info( ) ;
                die "Error: The dashrep_expand_parameters subroutine encountered an endless loop." . "\n" . "Stopped" ;
            }


#-----------------------------------------------
#  Repeat the loop that gets the next inner-most
#  parameter syntax.

        }


#-----------------------------------------------
#  Repeat the loop that repeats until no
#  replacement was done.

    }


#-----------------------------------------------
#  For each encountered replacement that begins
#  with "auto-increment-", increment its value.

    foreach $text_parameter_placeholder ( @list_of_replacements_to_auto_increment )
    {
        $global_dashrep_replacement{ $text_parameter_placeholder } ++ ;
    }
    @list_of_replacements_to_auto_increment = ( ) ;


#-----------------------------------------------
#  Return the revised text.

    return $replacement_text ;


#-----------------------------------------------
#  End of subroutine.

}


=head2 dashrep_generate_lists

Internal subroutine, not exported.
It is only needed within the Dashrep module.

=cut


#-----------------------------------------------
#-----------------------------------------------
#         Non-exported subroutine:
#
#         dashrep_generate_lists
#-----------------------------------------------
#-----------------------------------------------
#  Generates one or more lists, and the elements
#  in them, and puts each list and each element
#  into a named replacement.
#  Allows new list names to be specified
#  while generating the initial lists.

#  This subroutine is not exported because it
#  is only needed within this Dashrep module.

sub dashrep_generate_lists
{

    my $list_name ;
    my $generated_list_name ;
    my $parameter_name ;
    my $do_nothing ;
    my $list_prefix ;
    my $list_separator ;
    my $list_suffix ;
    my $replacement_name ;
    my $delimited_list_of_parameters ;
    my $pointer ;
    my $parameter ;
    my $item_name ;
    my @list_of_parameters ;
    my %already_generated_list_named ;


#-----------------------------------------------
#  Begin a loop that handles each list to
#  be generated.

    foreach $list_name ( @global_list_of_lists_to_generate )
    {


#-----------------------------------------------
#  Don't generate the same list more than once.

        if ( exists( $already_generated_list_named{ $list_name } ) )
        {
            if ( $already_generated_list_named{ $list_name } == $global_true )
            {
                next ;
            }
        }
        $already_generated_list_named{ $list_name } = $global_true ;


#-----------------------------------------------
#  Get information about the list being generated.

        $generated_list_name = "generated-list-named-" . $list_name ;
        if ( exists( $global_dashrep_replacement{ "parameter-name-for-list-named-" . $list_name } ) )
        {
            $parameter_name = $global_dashrep_replacement{ "parameter-name-for-list-named-" . $list_name } ;
        } else
        {
            $parameter_name = "unspecified-parameter-name-for-list-named-" . $list_name ;
            if ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" )
            {
                print "{{trace; WARNING: phrase  parameter-name-for-list-named-" . $list_name . "  is not defined}}\n";
            }
        }


#-----------------------------------------------
#  If the list prefix, separator, or suffix is
#  not defined, set it to empty (the default
#  value).

        if ( not( exists( $global_dashrep_replacement{ "prefix-for-list-named-" . $list_name } ) ) )
        {
            $global_dashrep_replacement{ "prefix-for-list-named-" . $list_name } = "" ;
        }
        $list_prefix = &dashrep_expand_parameters( "prefix-for-list-named-" . $list_name ) . "\n" ;

        if ( not( exists( $global_dashrep_replacement{ "separator-for-list-named-" . $list_name } ) ) )
        {
            $global_dashrep_replacement{ "separator-for-list-named-" . $list_name } = "" ;
        }
        $list_separator = &dashrep_expand_parameters( "separator-for-list-named-" . $list_name ) . "\n" ;

        if ( not( exists( $global_dashrep_replacement{ "suffix-for-list-named-" . $list_name } ) ) )
        {
            $global_dashrep_replacement{ "suffix-for-list-named-" . $list_name } = "" ;
        }
        $list_suffix = &dashrep_expand_parameters( "suffix-for-list-named-" . $list_name ) . "\n" ;


#-----------------------------------------------
#  Get the list of parameters that define the list.

        $replacement_name = "list-of-parameter-values-for-list-named-" . $list_name ;
        $delimited_list_of_parameters = &dashrep_expand_parameters( "list-of-parameter-values-for-list-named-" . $list_name ) ;
        @list_of_parameters = &dashrep_internal_split_delimited_items( $delimited_list_of_parameters ) ;
        $global_dashrep_replacement{ "logged-list-of-parameter-values-for-list-named-" . $list_name } = join( "," , @list_of_parameters ) ;


#-----------------------------------------------
#  Insert a prefix at the beginning of the list.

        $global_dashrep_replacement{ $generated_list_name } = $list_prefix . "\n" ;


#-----------------------------------------------
#  If the list of values is empty, skip over
#  the upcoming loop.

        if ( $#list_of_parameters < 0 )
        {
            if ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" )
            {
                print "{{trace; list named " . $list_name . "  is empty}}\n";
            }
        } else
        {


#-----------------------------------------------
#  Begin a loop that handles each list item.
#  Do not change the order of the parameters.

            for ( $pointer = 0 ; $pointer <= $#list_of_parameters ; $pointer ++ )
            {
                $parameter = $list_of_parameters[ $pointer ] ;
                $global_dashrep_replacement{ $parameter_name } = $parameter ;


#-----------------------------------------------
#  Add the next item to the list.

                $item_name = "item-for-list-" . $list_name . "-and-parameter-" . $parameter ;
                $global_dashrep_replacement{ $generated_list_name } .= $item_name . "\n" ;


#-----------------------------------------------
#  Using a template, generate each item in the list.

                $global_dashrep_replacement{ $item_name } = &dashrep_expand_parameters( "template-for-list-named-" . $list_name ) ;


#-----------------------------------------------
#  Insert separators between items.

                if ( $pointer < $#list_of_parameters )
                {
                    $global_dashrep_replacement{ $generated_list_name } .= $list_separator . "\n" ;
                }


#-----------------------------------------------
#  Protect against an endless loop.

                $global_endless_loop_counter ++ ;
                if ( $global_endless_loop_counter > $global_endless_loop_counter_limit )
                {
                    die "Error: The dashrep_generate_lists subroutine encountered an endless loop.  Stopped" ;
                }


#-----------------------------------------------
#  Repeat the loop for the next list item.

            }


#-----------------------------------------------
#  Finish skipping over the above sections when
#  the list is empty.

        }


#-----------------------------------------------
#  Terminate the generated list.

        $global_dashrep_replacement{ $generated_list_name } .= $list_suffix . "\n" ;


#-----------------------------------------------
#  Repeat the loop for the next list to be
#  generated.

    }


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}


=head2 dashrep_expand_phrases_except_special

Expands the hyphenated phrases in a text
string that is written in the Dashrep
language -- except the special
(built-in) hyphenated phrases that handle
spaces, hyphens, tabs, and line breaks,
and except the parameterized phrases.

First, and only, parameter is the text
string that uses the Dashrep language.

Return value is the expanded text string.
Return value is an empty string if there
is not exactly one parameter.

=cut

#-----------------------------------------------
#-----------------------------------------------
#       dashrep_expand_phrases_except_special
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_expand_phrases_except_special
{

    my $current_item ;
    my $hyphenated_phrase_to_expand ;
    my $expanded_output_string ;
    my $first_item ;
    my $remainder ;
    my $replacement_item ;
    my @item_stack ;
    my @items_to_add ;


#-----------------------------------------------
#  Initialization.

    $expanded_output_string = "" ;


#-----------------------------------------------
#  Internally define the "hyphen-here" phrase.

    $global_dashrep_replacement{ "hyphen-here" } = "no-space - no-space" ;


#-----------------------------------------------
#  Get the starting replacement name.

    if ( scalar( @_ ) == 1 )
    {
        $hyphenated_phrase_to_expand = $_[ 0 ] ;
    } else
    {
        $expanded_output_string = "" ;
        return $expanded_output_string ;
    }


#-----------------------------------------------
#  Generate any needed lists.

    &dashrep_generate_lists ;


#-----------------------------------------------
#  Start with a single phrase on a stack.

    @item_stack = ( ) ;
    push( @item_stack , $hyphenated_phrase_to_expand ) ;


#-----------------------------------------------
#  Begin a loop that does all the replacements.

    while( $#item_stack >= 0 )
    {


#-----------------------------------------------
#  If an endless loop occurs, handle that situation.

        $global_endless_loop_counter ++ ;
        if ( $global_endless_loop_counter > $global_endless_loop_counter_limit )
        {
            &dashrep_internal_endless_loop_info( ) ;
            die "Error: The dashrep_expand_phrases_except_special subroutine encountered an endless loop." . "\n" . "Stopped" ;
        }


#-----------------------------------------------
#  Get the first/next item from the stack.
#  If it is empty (after removing spaces),
#  repeat the loop.

        $current_item = pop( @item_stack ) ;
        $current_item =~ s/^ +// ;
        $current_item =~ s/ +$// ;
        if ( $current_item eq "" )
        {
            next ;
        }


#-----------------------------------------------
#  If the item contains a space or line break,
#  split the string at the first space or
#  line break, and push those strings onto the
#  stack, and then repeat the loop.

        if ( $current_item =~ /^ *([^ ]+)[ \n\r]+(.*)$/ )
        {
            $first_item = $1 ;
            $remainder = $2 ;
            if ( $remainder =~ /[^ ]/ )
            {
                push( @item_stack , $remainder ) ;
            }
            push( @item_stack , $first_item ) ;
            next ;
        }


#-----------------------------------------------
#  If the item is a hyphenated phrase that has
#  been defined, expand the phrase into its
#  associated text (its definition), split the
#  text at any spaces or line breaks, put those
#  delimited items on the stack, and repeat
#  the loop.

        if ( exists( $global_dashrep_replacement{ $current_item } ) )
        {
            $replacement_item = $global_dashrep_replacement{ $current_item } ;
            if ( $replacement_item =~ /[^ ]/ )
            {
                @items_to_add = split( /[ \n\r]+/ , $replacement_item ) ;
                push( @item_stack , reverse( @items_to_add ) ) ;
                $global_replacement_count_for_item_name{ $current_item } ++ ;
                next ;
            }
            next ;
        }


#-----------------------------------------------
#  If the item cannot be expanded, append it to
#  the output string.

        $expanded_output_string .= $current_item . " " ;


#-----------------------------------------------
#  Repeat the loop for the next replacement.

    }


#-----------------------------------------------
#  End of subroutine.

    return $expanded_output_string ;

}


=head2 dashrep_expand_special_phrases

Expands only the the special (built-in)
hyphenated phrases that handle hyphens,
tabs, spaces and line breaks,

First, and only, parameter is the
text string that contains the special
hyphenated phrases.

Return value is the expanded text string.
Return value is an empty string if there
is not exactly one parameter.

=cut

#-----------------------------------------------
#-----------------------------------------------
#         dashrep_expand_special_phrases
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_expand_special_phrases
{

    my $expanded_string ;
    my $phrase_name ;
    my $code_for_non_breaking_space ;
    my $code_with_spaces ;
    my $code_begin ;
    my $code_end ;
    my $remaining_string ;
    my $ignore_directive ;
    my $capture_directive ;


#-----------------------------------------------
#  Get the starting hyphenated-phrase.

    if ( scalar( @_ ) == 1 )
    {
        $expanded_string = $_[ 0 ] ;
    } else
    {
        $expanded_string = "" ;
        return $expanded_string ;
    }
    if ( $expanded_string !~ /[^ ]/ )
    {
        return "";
    }


#-----------------------------------------------
#  If a single hyphenated phrase is supplied and
#  is defined, expand it.  Otherwise, assume
#  it's a text string that contains the special
#  phrases.

    if ( $expanded_string =~ /^ *([^ \[\]]+-[^ \[\]]+) *$/ )
    {
        $phrase_name = $1 ;
        if ( exists( $global_dashrep_replacement{ $phrase_name } ) )
        {
            $expanded_string = $global_dashrep_replacement{ $phrase_name } ;
        }
    }


#-----------------------------------------------
#  Get the ignore level.  It can be accessed
#  from outside this subroutine in case multiple
#  streams of Dashrep code are being processed
#  in turn.

    if ( $global_dashrep_replacement{ "dashrep-ignore-level" } =~ /^[0-9]+$/ )
    {
        $global_ignore_level = $global_dashrep_replacement{ "dashrep-ignore-level" } + 0 ;
    }


#-----------------------------------------------
#  Get the capture level.  It can be accessed
#  from outside this subroutine in case multiple
#  streams of Dashrep code are being processed
#  in turn.

    if ( $global_dashrep_replacement{ "dashrep-capture-level" } =~ /^[0-9]+$/ )
    {
        $global_capture_level = $global_dashrep_replacement{ "dashrep-capture-level" } + 0 ;
    }


#-----------------------------------------------
#  If the ignore level and capture level are both
#  non-zero, indicate an error (because they
#  overlap).

    if ( ( $global_ignore_level > 0 ) && ( $global_capture_level > 0 ) )
    {
        $expanded_string .= " [warning: ignore and capture directives overlap, both directives reset] " ;
        $global_ignore_level = 0 ;
        $global_capture_level = 0 ;
    }


#-----------------------------------------------
#  Handle the directives:
#  "ignore-begin-here" and
#  "ignore-end-here"

    $remaining_string = $expanded_string ;
    $expanded_string = "" ;

    if ( ( $global_ignore_level > 0 ) && ( $remaining_string !~ /((ignore-begin-here)|(ignore-end-here))/si ) )
    {
        if ( $global_dashrep_replacement{ "dashrep-ignore-trace-on-or-off" } eq "on" )
        {
            print "{{trace; ignore level: " . $global_ignore_level . "}}\n" ;
            if ( $remaining_string =~ /[^ ]/ )
            {
                print "{{trace; ignored: " . $remaining_string . "}}\n" ;
            }
        }
        $remaining_string = "" ;
    }

    while ( $remaining_string =~ /^((.*? +)?)((ignore-begin-here)|(ignore-end-here))(( +.*)?)$/si )
    {
        $code_begin = $1 ;
        $ignore_directive = $3 ;
        $remaining_string = $6 ;

        if ( $global_ignore_level > 0 )
        {
            if ( $global_dashrep_replacement{ "dashrep-ignore-trace-on-or-off" } eq "on" )
            {
                print "{{trace; ignore level: " . $global_ignore_level . "}}\n" ;
                if ( $remaining_string =~ /[^ ]/ )
                {
                    print "{{trace; ignored: " . $code_begin . "}}\n" ;
                }
            }
        } else
        {
            $expanded_string .= $code_begin . " " ;
        }

        if ( $ignore_directive eq "ignore-begin-here" )
        {
            if ( $global_dashrep_replacement{ "dashrep-ignore-trace-on-or-off" } eq "on" )
            {
                print "{{trace; ignore directive: " . $ignore_directive . "}}\n" ;
            }
            $global_ignore_level ++ ;
            $global_dashrep_replacement{ "dashrep-ignore-level" } = sprintf( "%d" , $global_ignore_level ) ;
        } elsif ( $ignore_directive eq "ignore-end-here" )
        {
            if ( $global_dashrep_replacement{ "dashrep-ignore-trace-on-or-off" } eq "on" )
            {
                print "{{trace; ignore directive: " . $ignore_directive . "}}\n" ;
            }
            $global_ignore_level -- ;
            $global_dashrep_replacement{ "dashrep-ignore-level" } = sprintf( "%d" , $global_ignore_level ) ;
        }
    }
    $expanded_string .= $remaining_string ;


#-----------------------------------------------
#  Handle the directives:
#  "capture-begin-here" and
#  "capture-end-here"

    $remaining_string = $expanded_string ;
    $expanded_string = "" ;

    if ( ( $global_capture_level > 0 ) && ( $remaining_string !~ /((capture-begin-here)|(capture-end-here))/si ) )
    {
        $global_dashrep_replacement{ "captured-text" } .= " " . $remaining_string ;
        if ( $global_dashrep_replacement{ "dashrep-capture-trace-on-or-off" } eq "on" )
        {
            print "{{trace; capture level: " . $global_capture_level . "}}\n" ;
            if ( $remaining_string =~ /[^ ]/ )
            {
                print "{{trace; captured: " . $remaining_string . "}}\n" ;
            }
        }
        $remaining_string = "" ;
    }

    while ( $remaining_string =~ /^((.*? +)?)((capture-begin-here)|(capture-end-here))(( +.*)?)$/si )
    {
        $code_begin = $1 ;
        $capture_directive = $3 ;
        $remaining_string = $6 ;

        if ( $global_capture_level > 0 )
        {
            $global_dashrep_replacement{ "captured-text" } .= " " . $code_begin ;
            if ( $global_dashrep_replacement{ "dashrep-capture-trace-on-or-off" } eq "on" )
            {
                print "{{trace; capture level: " . $global_capture_level . "}}\n" ;
                if ( $remaining_string =~ /[^ ]/ )
                {
                    print "{{trace; captured: " . $code_begin . "}}\n" ;
                }
            }
        } else
        {
            $expanded_string .= $code_begin . " " ;
        }

        if ( $capture_directive eq "capture-begin-here" )
        {
            $global_dashrep_replacement{ "captured-text" } = "" ;
            if ( $global_dashrep_replacement{ "dashrep-capture-trace-on-or-off" } eq "on" )
            {
                print "{{trace; capture directive: " . $capture_directive . "}}\n" ;
            }
            $global_capture_level ++ ;
            $global_dashrep_replacement{ "dashrep-capture-level" } = sprintf( "%d" , $global_capture_level ) ;
        } elsif ( $capture_directive eq "capture-end-here" )
        {
            if ( $global_dashrep_replacement{ "dashrep-capture-trace-on-or-off" } eq "on" )
            {
                print "{{trace; capture directive: " . $capture_directive . "}}\n" ;
            }
            $global_capture_level -- ;
            $global_dashrep_replacement{ "dashrep-capture-level" } = sprintf( "%d" , $global_capture_level ) ;
        }
    }
    $expanded_string .= $remaining_string ;


#-----------------------------------------------
#  Handle the directive:
#  "non-breaking-space"

    $code_for_non_breaking_space = $global_dashrep_replacement{ "non-breaking-space" } ;
    while ( $expanded_string =~ /^(.* +)?non-breaking-space( +.*)?$/sgi )
    {
        $code_begin = $1 ;
        $code_end = $2 ;
        $code_begin =~ s/ +$//si ;
        $code_end =~ s/^ +//si ;
        $expanded_string = $code_begin . $code_for_non_breaking_space . $code_end ;
    }


#-----------------------------------------------
#  Handle the directives:
#  "span-non-breaking-spaces-begin" and
#  "span-non-breaking-spaces-end"

    $code_for_non_breaking_space = $global_dashrep_replacement{ "non-breaking-space" } ;
    while ( $expanded_string =~ /^(.*)\bspan-non-breaking-spaces-begin\b *(.*?) *\bspan-non-breaking-spaces-end\b(.*)$/sgi )
    {
        $code_begin = $1 ;
        $code_with_spaces = $2 ;
        $code_end = $3 ;
        $code_with_spaces =~ s/ +/ ${code_for_non_breaking_space} /sgi ;
        $code_with_spaces =~ s/ +//sgi ;
        $expanded_string = $code_begin . $code_with_spaces . $code_end ;
    }


#-----------------------------------------------
#  Replace multiple spaces and tabs with single spaces.

    $expanded_string =~ s/[ \n][ \t]+/ /sg ;


#-----------------------------------------------
#  Handle the directive:
#  "tab-here"

    $expanded_string =~ s/ *\btab-here\b */\t/sg ;


#-----------------------------------------------
#  Handle the directives:
#  "empty-line" and "new-line"

    $expanded_string =~ s/ *\bempty-line\b */\n\n/sg ;
    $expanded_string =~ s/ *\bnew-line\b */\n/sg ;


#-----------------------------------------------
#  Concatenate lines and spaces as indicated by
#  the "no-space" and "one-space" directives.

    $expanded_string =~ s/\bone-space\b/<onespace>/sgi ;

    $expanded_string =~ s/\bno-space\b/<nospace>/sgi ;

    $expanded_string =~ s/[ \t]+<nospace>[ \t]*/<nospace>/sgi ;
    $expanded_string =~ s/[ \t]*<nospace>[ \t]+/<nospace>/sgi ;
    $expanded_string =~ s/<nospace>//sgi ;
    $expanded_string =~ s/<nospace>//sgi ;

    $expanded_string =~ s/[ \t]+<onespace>[ \t]*/<onespace>/sgi ;
    $expanded_string =~ s/[ \t]*<onespace>[ \t]+/<onespace>/sgi ;
    $expanded_string =~ s/<onespace>/ /sgi ;
    $expanded_string =~ s/<onespace>/ /sgi ;


#-----------------------------------------------
#  End of subroutine.

    return $expanded_string ;

}


=head2 dashrep_expand_phrases

Expands all the hyphenated phrases
in a text string that is written in the
Dashrep language.  This includes expanding
the special (built-in) hyphenated phrases
that handle spaces, hyphens, and line breaks.

First, and only, parameter is the text string
that may contain hyphenated phrases to be
expanded.

Return value is the expanded text string.
Return value is an empty string if there is not
exactly one parameter.

=cut

#-----------------------------------------------
#-----------------------------------------------
#              dashrep_expand_phrases
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_expand_phrases
{

    my $text_string_to_expand ;
    my $partly_expanded_string ;
    my $expanded_string ;


#-----------------------------------------------
#  Get the starting hyphenated-phrase.

    if ( scalar( @_ ) == 1 )
    {
        $text_string_to_expand = $_[ 0 ] ;
    } else
    {
        $expanded_string = "" ;
        return $expanded_string ;
    }


#-----------------------------------------------
#  Expand the phrase except for special phrases.

    $partly_expanded_string = &dashrep_expand_phrases_except_special( $text_string_to_expand ) ;
    if ( $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } eq "on" )
    {
        print "{{trace; after non-special phrases expanded: " . $partly_expanded_string . "}}\n" ;
    }


#-----------------------------------------------
#  Handle special directives:
#  "empty-line" and "new-line" and
#  "no-space" and "one-space" and others

    $expanded_string = &dashrep_expand_special_phrases( $partly_expanded_string ) ;


#-----------------------------------------------
#  End of subroutine.

    return $expanded_string ;

}


=head2 dashrep_xml_tags_to_dashrep

Converts a single line of XML code into Dashrep
code in which XML tags are replaced by Dashrep
phrases.
Tags are replaced by hyphenated phrases that
are named according to the accumulated XML
tag names, with "begin-" and "end-" to indicate
the beginning and ending tags.  The prefix
"begin-and-end-" indicates a self-terminating
XML tag (e.g. "<br />").
If the resulting phrase has a Dashrep definition,
that definition (which is assumed to be a single
phrase) is used instead.
If the non-tag content contains any hyphens,
they are replaced with the phrase "hyphen-here".
If a tag's opening bracket (<) and closing
bracket (>) are not both on the same line, the
tag will not be recognized.

=cut


#-----------------------------------------------
#-----------------------------------------------
#             dashrep_xml_tags_to_dashrep
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_xml_tags_to_dashrep
{

    my $input_text ;
    my $first_tag_name ;
    my $output_text ;
    my $open_brackets ;
    my $close_brackets ;
    my $remaining_string ;
    my $prefix_text ;
    my $tag_full ;
    my $suffix_text ;
    my $tag_name ;
    my $previous_input_text ;
    my $text_before_tag ;
    my $tag_and_possible_parameters ;
    my $parameter_name ;
    my $parameter_value ;
    my $text_after_tag ;
    my $revised_tags ;
    my $possible_slash ;
    my $may_include_closing_slash ;
    my $previous_tag_name ;
    my $sequence_without_hyphen_prefix ;
    my $starting_position_of_last_tag_name ;
    my $full_phrase ;


#-----------------------------------------------
#  Get the input text.

    if ( scalar( @_ ) == 1 )
    {
        $input_text = $_[ 0 ] ;
    } else
    {
       carp "Warning: Call to xml_tags_to_dashrep subroutine does not have exactly one parameter." ;
        return 0 ;
    }


#-----------------------------------------------
#  Trim spaces from the input line, and clear
#  the output text.

    $input_text =~ s/^ +// ;
    $input_text =~ s/ +$// ;
    $output_text = "" ;


#-----------------------------------------------
#  Get the tag name that is regarded as at
#  the highest level of interest.  Tags at
#  higher levels are ignored.

    $first_tag_name = $global_dashrep_replacement{ "dashrep-first-xml-tag-name" } ;


#-----------------------------------------------
#  If a line does not contain the same number
#  of open angle brackets (<) as close angle
#  brackets (>), and tracing is on, issue a
#  warning.

    $open_brackets = $input_text ;
    $open_brackets =~ s/[^<]//g ;
    $close_brackets = $input_text ;
    $close_brackets =~ s/[^>]//g ;
    if ( length( $open_brackets ) != length( $close_brackets ) )
    {
        if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
        {
            print "{{trace; non-matching angle brackets: " . $input_text . "}}\n" ;
        }
    }


#-----------------------------------------------
#  If a tag is identified -- through use of
#  special hyphenated phrases -- as of the
#  open-and-close type that may not include a
#  closing slash (such as "<br>"), then insert
#  a closing tag.
#  Note that the match is case-sensitive.

    $remaining_string = $input_text ;
    $input_text = "" ;
    while ( $remaining_string =~ /^(.*?)(<[^ <>\/][^>]*[^>\/]>)(.*)$/ )
    {
        $prefix_text = $1 ;
        $tag_full = $2 ;
        $suffix_text = $3 ;
        $tag_name = $tag_full ;
        $tag_name =~ s/^<([^ >\/]+).*>$/$1/ ;
        if ( $tag_name ne "" )
        {
            if ( exists( $global_dashrep_replacement{ "dashrep-xml-yes-handle-open-close-tag-" . $tag_name } ) )
            {
                $tag_full .= '</' . $tag_name . ">" ;
                if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
                {
                    print "{{trace; open-and-close type xml tag: " . $tag_name . " , modified to include closing tag: " . $tag_full . "}}\n" ;
                }
            }
        }
        $input_text .= $prefix_text . $tag_full ;
        $remaining_string = $suffix_text ;
    }
    $input_text .= $remaining_string ;


#-----------------------------------------------
#  If one of the parameters within a tag is a
#  "style" tag that has multiple CSS
#  parameters with their own parameter values
#  (with a colon (:) separating each
#  sub-parameter name from its sub-parameter
#  value, and with semicolons (;) separating
#  those name & value pairs within the XML
#  parameter), split up those sub-parameters
#  into separate parameters (with combined
#  names).

    $previous_input_text = "" ;
    while ( $input_text ne $previous_input_text )
    {
        $previous_input_text = $input_text ;
        $input_text =~ s/(<[^>]+ style) *= *\"([^\"\:\;>]+) *: *([^\"\:\;>]*) *; *([^\">]+)\"([^>]*>)/$1_$2=\"$3\" style=\"$4\"$5/sgi ;
        $input_text =~ s/(<[^>]+ style) *= *\"([^\"\:\;>]+) *: *([^\"\:\;>]*)\"([^>]*>)/$1_$2=\"$3\"$4/sgi ;
        if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
        {
            if ( $previous_input_text ne $input_text )
            {
                print "{{trace; after xml sub-parameters extracted: " . $input_text . "}}\n" ;
            }
        }
    }


#-----------------------------------------------
#  Expand parameters within a tag into separate
#  XML tags.
#  TODO: Insert "begin-xml-tag-parameters" and
#  "end-xml-tag-parameters" around parameters.

    while ( $input_text =~ /^(.*)(<[^ >\!\?\/][^>]*) ([^ >\=]+)=((\"([^>\"]*)\")|([^ >\"\']+)) *>(.*)$/ )
    {
        $text_before_tag = $1 ;
        $tag_and_possible_parameters = $2 ;
        $parameter_name = $3 ;
        $parameter_value = $4 ;
        $text_after_tag = $8 ;
        $parameter_value =~ s/^\"(.*)\"$/$1/ ;
        $parameter_name =~ s/\-/_/g ;
        $revised_tags = $tag_and_possible_parameters . "><" . $parameter_name . ">" . $parameter_value . '</' . $parameter_name . ">" ;
        $input_text = $text_before_tag . $revised_tags . $text_after_tag ;
        if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
        {
            print "{{trace; after xml parameter extracted: " . $revised_tags . "}}\n" ;
        }
    }


#-----------------------------------------------
#  Begin a loop that repeats for each XML tag.
#
#  Get the name within a (single) tag, and
#  ignore any other content within the tag.
#  Ignore the opening XML-standard-required
#  declaration.

    while ( $input_text =~ /^ *([^<>]*)<(\/?)([^ >\?\/]+[^ >\/]*)([^>]*)>(.*)$/ )
    {
        $text_before_tag = $1 ;
        $possible_slash = $2 ;
        $tag_name = $3 ;
        $may_include_closing_slash = $4 ;
        $suffix_text = $5 ;
        if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
        {
            print "{{trace; input line: " . $input_text . "}}\n" ;
        }
        $input_text = $suffix_text ;
        if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
        {
            print "{{trace; tag: <" . $possible_slash . $tag_name . ">}}\n" ;
        }


#-----------------------------------------------
#  If the non-tag content text contains any
#  hyphens, replace them with the phrase
#  "hypen-here".

        $text_before_tag =~ s/\-/dashrep_internal_hyphen_here/sg ;
        $text_before_tag =~ s/dashrep_internal_hyphen_here/ hyphen-here /sg ;


#-----------------------------------------------
#  If any text precedes the tag, write it on a
#  separate line.

        if ( $text_before_tag =~ /[^ ]/ )
        {
            if ( $global_ignore_level <= 0 )
            {
                $output_text .= $text_before_tag . "\n" ;
            }
        }


#-----------------------------------------------
#  If a specially named Dashrep phrase indicates
#  that the tag should be ignored, ignore it.

        if ( exists( $global_dashrep_replacement{ "dashrep-xml-yes-ignore-tag-named-" . $tag_name } ) )
        {
            if ( $global_dashrep_replacement{ "dashrep-xml-yes-ignore-tag-named-" . $tag_name } eq "yes" )
            {
                if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
                {
                    print "{{trace; ignoring tag: " . $tag_name . "}}\n" ;
                }
                next ;
            }
        }


#-----------------------------------------------
#  If a specially named Dashrep phrase indicates
#  that the XML tag should be renamed, rename it as
#  requested.

        if ( exists( $global_dashrep_replacement{ "dashrep-xml-replacement-name-for-tag-named-" . $tag_name } ) )
        {
            $previous_tag_name = $tag_name ;
            $tag_name = $global_dashrep_replacement{ "dashrep-xml-replacement-name-for-tag-named-" . $previous_tag_name } ;
            if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
            {
                print "{{trace; changing tag name " . $previous_tag_name . " into tag name " . $tag_name . "}}\n" ;
            }
        }


#-----------------------------------------------
#  If the tag is of the "close" type, write the
#  appropriate dashrep phrase (and indent it to
#  indicate the nesting level).  Then remove the
#  lowest-level tag name from the phrase that
#  contains all the tag names.

        if ( $possible_slash eq '/' )
        {
            if ( length( $global_xml_accumulated_sequence_of_tag_names ) > 0 )
            {
                if ( $global_xml_tag_at_level_number[ $global_xml_level_number ] eq $tag_name )
                {
                    $full_phrase = "end" . $global_xml_accumulated_sequence_of_tag_names ;
                    if ( exists( $global_dashrep_replacement{ $full_phrase } ) )
                    {
                        $global_ignore_level = 0 ;
                    }
                    if ( $global_ignore_level <= 0 )
                    {
                        $output_text .= substr( $global_spaces , 0 , ( 2 * $global_xml_level_number ) ) ;
                        $output_text .= "[-" ;
                        if ( exists( $global_dashrep_replacement{ $full_phrase } ) )
                        {
                            $output_text .= $global_dashrep_replacement{ $full_phrase } ;
                        } else
                        {
                            $output_text .= $full_phrase ;
                        }
                        $output_text .= "-]" ;
                        $output_text .= "\n" ;
                    } else
                    {
                        $global_ignore_level -- ;
                    }
                    $sequence_without_hyphen_prefix = $global_xml_accumulated_sequence_of_tag_names ;
                    $sequence_without_hyphen_prefix =~ s/^\-// ;
                    $global_exists_xml_hyphenated_phrase{ $sequence_without_hyphen_prefix } = "exists" ;
                    $starting_position_of_last_tag_name = length( $global_xml_accumulated_sequence_of_tag_names ) - length( $global_xml_tag_at_level_number[ $global_xml_level_number ] ) - 1 ;
                    if ( $starting_position_of_last_tag_name > 0 )
                    {
                        $global_xml_accumulated_sequence_of_tag_names = substr( $global_xml_accumulated_sequence_of_tag_names , 0 , $starting_position_of_last_tag_name ) ;
                    } else
                    {
                        $global_xml_accumulated_sequence_of_tag_names = "" ;
                    }
                    $global_xml_level_number -- ;
                } else
                {
                    if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
                    {
                        print "{{trace; close tag " . $tag_name . " ignored because it does not match expected close tag name " . $global_xml_tag_at_level_number[ $global_xml_level_number ] . "}}\n" ;
                    }
                }
            }


#-----------------------------------------------
#  If the tag is of the singular (open and close)
#  type, write the appropriate dashrep phrase.

        } elsif ( $may_include_closing_slash =~ /\// )
        {
            if ( length( $global_xml_accumulated_sequence_of_tag_names ) > 0 )
            {
                $full_phrase = "begin-and-end" . $global_xml_accumulated_sequence_of_tag_names . "-" . $tag_name ;
                if ( ( exists( $global_dashrep_replacement{ "dashrep-xml-yes-ignore-if-no-tag-replacement" } ) ) && ( $global_dashrep_replacement{ "dashrep-xml-yes-ignore-if-no-tag-replacement" } eq "yes" ) && ( not( exists( $global_dashrep_replacement{ $full_phrase } ) ) ) )
                {
                    $global_ignore_level ++ ;
                }
                if ( exists( $global_dashrep_replacement{ $full_phrase } ) )
                {
                    $global_ignore_level = 0 ;
                }
                if ( $global_ignore_level <= 0 )
                {
                    $output_text .= substr( $global_spaces , 0 , ( 2 * ( $global_xml_level_number + 1 ) ) ) ;
                    $output_text .= "[-" ;
                    if ( exists( $global_dashrep_replacement{ $full_phrase } ) )
                    {
                        $output_text .= $global_dashrep_replacement{ $full_phrase } ;
                    } else
                    {
                        $output_text .= $full_phrase ;
                    }
                    $output_text .= "-]" ;
                    $output_text .= "\n" ;
                } else
                {
                    $global_ignore_level -- ;
                }
            }


#-----------------------------------------------
#  If the tag is of the "open" type, append the
#  new tag name to the accumulated hyphenated
#  phrase, and then write the appropriate Dashrep
#  phrase.  However, do not use tag names that
#  occur before the specified first tag name
#  (of interest) -- unless the first tag name
#  is empty.

        } else
        {
            if ( length( $global_xml_accumulated_sequence_of_tag_names ) <= 0 )
            {
                if ( $tag_name eq $first_tag_name )
                {
                    $global_xml_level_number ++ ;
                    $global_xml_tag_at_level_number[ $global_xml_level_number ] = $tag_name ;
                    $global_xml_accumulated_sequence_of_tag_names = "-" . $tag_name ;
                    if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
                    {
                        print "{{trace; specified top-level tag name: " . $first_tag_name . "}}\n" ;
                    }
                } elsif ( $first_tag_name =~ /^ *$/ )
                {
                    $global_xml_level_number ++ ;
                    $global_xml_tag_at_level_number[ $global_xml_level_number ] = $tag_name ;
                    $first_tag_name = $tag_name ;
                    $global_dashrep_replacement{ "dashrep-first-xml-tag-name" } = $first_tag_name ;
                    $global_xml_accumulated_sequence_of_tag_names = "-" . $tag_name ;
                    if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
                    {
                        print "{{trace; default top-level tag name: " . $tag_name . "}}\n" ;
                    }
                } else
                {
                    if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
                    {
                        print "{{trace; ignored tag: " . $tag_name . "}}\n" ;
                    }
                }
            } else
            {
                $global_xml_level_number ++ ;
                $global_xml_tag_at_level_number[ $global_xml_level_number ] = $tag_name ;
                $global_xml_accumulated_sequence_of_tag_names .= "-" . $tag_name ;
            }
            if ( length( $global_xml_accumulated_sequence_of_tag_names ) > 0 )
            {
                $full_phrase = "begin" . $global_xml_accumulated_sequence_of_tag_names ;
                if ( ( exists( $global_dashrep_replacement{ "dashrep-xml-yes-ignore-if-no-tag-replacement" } ) ) && ( $global_dashrep_replacement{ "dashrep-xml-yes-ignore-if-no-tag-replacement" } eq "yes" ) && ( not( exists( $global_dashrep_replacement{ $full_phrase } ) ) ) )
                {
                    $global_ignore_level ++ ;
                }
                if ( exists( $global_dashrep_replacement{ $full_phrase } ) )
                {
                    $global_ignore_level = 0 ;
                }
                if ( $global_ignore_level <= 0 )
                {
                    $output_text .= substr( $global_spaces , 0 , ( 2 * ( $global_xml_level_number - 1 ) ) ) ;
                    $output_text .= "[-" ;
                    if ( exists( $global_dashrep_replacement{ $full_phrase } ) )
                    {
                        $output_text .= $global_dashrep_replacement{ $full_phrase } ;
                    } else
                    {
                        $output_text .= $full_phrase ;
                    }
                    $output_text .= "-]" ;
                    $output_text .= "\n" ;
                }
                $sequence_without_hyphen_prefix = $global_xml_accumulated_sequence_of_tag_names ;
                $sequence_without_hyphen_prefix =~ s/^\-// ;
                $global_exists_xml_hyphenated_phrase{ $sequence_without_hyphen_prefix } = "exists" ;
            }
        }


#-----------------------------------------------
#  Repeat the loop for the next tag in the
#  input line.

    }


#-----------------------------------------------
#  If the non-tag content text contains any
#  hyphens, replace them with the phrase
#  "hypen-here".

    $input_text =~ s/\-/dashrep_internal_hyphen_here/sg ;
    $input_text =~ s/dashrep_internal_hyphen_here/ hyphen-here /sg ;


#-----------------------------------------------
#  If any text follows the last tag, write it on a
#  separate line.

    if ( $input_text =~ /^ *([^ ].*)$/ )
    {
        $input_text = $1 ;
        $output_text .= "\n" . $input_text ;
        $input_text = "" ;
    }


#-----------------------------------------------
#  End of subroutine.

    return $output_text ;

}


=head2 dashrep_top_level_action

Handles a top-level action such as a transfer
to and from files.

First, and only, parameter is the
text string that contains any text, which
may include one top-level action (which is
a hyphenated phrase).

Return value is the text string after removing
the executed action, or the original text
string if there was no action phrase.
Return value is an empty string if there
is not exactly one parameter.

=cut


#-----------------------------------------------
#-----------------------------------------------
#         dashrep_top_level_action
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_top_level_action
{

    my $source_definitions ;
    my $input_text ;
    my $translation ;
    my $partial_translation ;
    my $source_filename ;
    my $target_filename ;
    my $source_phrase ;
    my $target_phrase ;
    my $lines_to_translate ;
    my $line_count ;
    my $text_list_of_phrases ;
    my $possible_error_message ;
    my $all_defs_begin ;
    my $all_defs_end ;
    my $phrase_begin ;
    my $phrase_end ;
    my $def_begin ;
    my $def_end ;
    my $all_lines ;
    my $input_line ;
    my $phrase_name ;
    my $tracking_on_or_off ;
    my $qualifier ;
    my $numeric_return_value ;
    my $full_line ;
    my $multi_line_limit ;
    my $open_brackets ;
    my $close_brackets ;
    my $multi_line_count ;
    my $xml_hyphenated_phrase ;
    my $counter ;
    my @list_of_phrases ;


#-----------------------------------------------
#  Reset the xml-parsing state.

    $global_xml_level_number = 0 ;
    @global_xml_tag_at_level_number = ( ) ;


#-----------------------------------------------
#  Get the input text.

    if ( scalar( @_ ) == 1 )
    {
        $input_text = $_[ 0 ] ;
    } else
    {
       carp "Warning: Call to dashrep_top_level_action subroutine does not have exactly one parameter." ;
        return 0 ;
    }


#-----------------------------------------------
#  Clear the error message.

    $possible_error_message = "" ;


#-----------------------------------------------
#  Ensure this function is not called recursively.

    $global_nesting_level_of_file_actions ++ ;
    if ( $global_nesting_level_of_file_actions > 1 )
    {
       carp "Warning: Call to dashrep_top_level_action subroutine called recursivley, which is not allowed." ;
        return 0 ;
    }


#-----------------------------------------------
#  In case definitions are exported, specify
#  which delimiters to use -- based on the "yes"
#  or "no" definition of the phrase
#  "dashrep-yes-or-no-export-delimited-definitions".

    if ( $global_dashrep_replacement{ "dashrep-yes-or-no-export-delimited-definitions" } eq "yes" )
    {
        $all_defs_begin = "export-defs-all-begin\n\n" ;
        $all_defs_end = "export-defs-all-end\n\n" ;
        $phrase_begin = "export-defs-phrase-begin " ;
        $phrase_end = " export-defs-phrase-end\n\n" ;
        $def_begin = "export-defs-def-begin " ;
        $def_end = " export-defs-def-end\n\n" ;
    } else
    {
        $all_defs_begin = "dashrep-definitions-begin\n\n" ;
        $all_defs_end = "dashrep-definitions-end\n\n" ;
        $phrase_begin = "" ;
        $phrase_end = ":\n" ;
        $def_begin = "" ;
        $def_end = "\n-----\n\n" ;
    }


#-----------------------------------------------
#  Handle the action:
#  append-from-phrase-to-phrase

    if ( $input_text =~ /^ *append-from-phrase-to-phrase +([^ \[\]]+) +([^ \[\]]+) *$/ )
    {
        $source_phrase = $1 ;
        $target_phrase = $2 ;
        $global_dashrep_replacement{ $target_phrase } .= " " . $global_dashrep_replacement{ $source_phrase } ;
        if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
        {
            print "{{trace; appended from phrase " . $source_phrase . " to phrase " . $target_phrase . "}}\n" ;
        }
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  copy-from-phrase-append-to-file
#
#  The filename is edited to remove any path
#  specifications, so that only local files
#  are affected.

    } elsif ( $input_text =~ /^ *copy-from-phrase-append-to-file +([^ \[\]]+) +([^ \[\]]+) *$/ )
    {
        $source_phrase = $1 ;
        $target_filename = $2 ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        if ( open ( OUTFILE , ">>" . $target_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $target_filename . " could not be opened for writing]" ;
        }
        if ( $possible_error_message eq "" )
        {
            print OUTFILE "\n" . $global_dashrep_replacement{ $source_phrase } . "\n" ;
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; copied from phrase " . $source_phrase . " to end of file " . $target_filename . "}}\n" ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; error: " . $possible_error_message . "}}\n" ;
            }
        }
        close( OUTFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  expand-phrase-to-file
#
#  The filename is edited to remove any path
#  specifications, so that only local files
#  are affected.

    } elsif ( $input_text =~ /^ *expand-phrase-to-file +([^ \[\]]+) +([^ \[\]]+) *$/ )
    {
        $source_phrase = $1 ;
        $target_filename = $2 ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        if ( open ( OUTFILE , ">" . $target_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $target_filename . " could not be opened for writing]" ;
        }
        if ( $possible_error_message eq "" )
        {
            $partial_translation = &dashrep_expand_parameters( $source_phrase );
            if ( $global_dashrep_replacement{ "dashrep-debug-trace-on-or-off" } eq "on" )
            {
                print "{{trace; after parameters expanded: " . $partial_translation . "}}\n" ;
            }
            $translation = &dashrep_expand_phrases( $partial_translation );
            print OUTFILE $translation . "\n" ;
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; expanded phrase " . $source_phrase . " to file " . $target_filename . "}}\n" ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; error: " . $possible_error_message . "}}\n" ;
            }
        }
        close( OUTFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  copy-from-file-to-phrase

    } elsif ( $input_text =~ /^ *copy-from-file-to-phrase +([^ \[\]]+) +([^ \[\]]+) *$/ )
    {
        $source_filename = $1 ;
        $target_phrase = $2 ;
        if ( open ( INFILE , "<" . $source_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $source_filename . " not found, or could not be opened]" ;
        }
        if ( $possible_error_message eq "" )
        {
            $possible_error_message .= " [file named " . $source_filename . " found, and opened]" ;
            $all_lines = "" ;
            while( $input_line = <INFILE> )
            {
                chomp( $input_line ) ;
                $input_line =~ s/[\n\r\f\t]+/ /g ;
                $all_lines .= $input_line . "\n" ;
            }
            $global_dashrep_replacement{ $target_phrase } = $all_lines ;
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; copied from file " . $source_filename . " to phrase " . $target_phrase . "}}\n" ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; error: " . $possible_error_message . "}}\n" ;
            }
        }
        close( INFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  create-empty-file
#
#  The filename is edited to remove any path
#  specifications, so that only local files
#  are affected.

    } elsif ( $input_text =~ /^ *create-empty-file +([^ \[\]]+) *$/ )
    {
        $target_filename = $1 ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        if ( open ( OUTFILE , ">" . $target_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $target_filename . " could not be created]" ;
        }
        if ( $possible_error_message eq "" )
        {
            print OUTFILE "" ;
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; created empty file: " . $target_filename . "}}\n" ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; error: " . $possible_error_message . "}}\n" ;
            }
        }
        close( OUTFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  delete-file
#
#  The filename is edited to remove any path
#  specifications, so that only local files
#  are affected.

    } elsif ( $input_text =~ /^ *delete-file +([^ \[\]]+) *$/ )
    {
        $target_filename = $1 ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        unlink $target_filename ;
        if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
        {
            print "{{trace; deleted file: " . $target_filename . "}}\n" ;
        }
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  write-all-dashrep-definitions-to-file
#
#  The filename is edited to remove any path
#  specifications, so that only local files
#  are affected.

    } elsif ( $input_text =~ /^ *write-all-dashrep-definitions-to-file +([^ \[\]]+) *$/ )
    {
        $target_filename = $1 ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        @list_of_phrases = &dashrep_get_list_of_phrases( ) ;
        if ( $#list_of_phrases < 0 )
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; warning: no phrases to write (to file)}}\n" ;
            }
        } else
        {
            if ( open ( OUTFILE , ">" . $target_filename ) )
            {
                $possible_error_message .= "" ;
            } else
            {
                $possible_error_message .= " [file named " . $target_filename . " could not be opened for writing]" ;
            }
            if ( $possible_error_message eq "" )
            {
                $counter = 0 ;
                print OUTFILE $all_defs_begin ;
                foreach $phrase_name ( sort( @list_of_phrases ) )
                {
                    if ( ( defined( $phrase_name ) ) &&( $phrase_name =~ /[^ ]/ ) && ( exists( $global_dashrep_replacement{ $phrase_name } ) ) )
                    {
                        print OUTFILE $phrase_begin . $phrase_name . $phrase_end . $def_begin . $global_dashrep_replacement{ $phrase_name } . $def_end ;
                        $counter ++ ;
                    }
                }
                print OUTFILE $all_defs_end ;
                if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
                {
                    print "{{trace; wrote " . $counter . " definitions to file: " . $target_filename . "}}\n" ;
                }
            } else
            {
                if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
                {
                    print "{{trace; error: " . $possible_error_message . "}}\n" ;
                }
            }
        }
        close( OUTFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  write-dashrep-definitions-listed-in-phrase-to-file
#
#  The filename is edited to remove any path
#  specifications, so that only local files
#  are affected.

    } elsif ( $input_text =~ /^ *write-dashrep-definitions-listed-in-phrase-to-file +([^ \[\]]+) +([^ \[\]]+) *$/ )
    {
        $source_phrase = $1 ;
        $target_filename = $2 ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        $text_list_of_phrases = $global_dashrep_replacement{ $source_phrase } ;
        if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
        {
            print "{{trace; phrase that contains list of phrases to export: " . $source_phrase . "}}\n" ;
            print "{{trace; list of phrases for exporting definitions to file: " . $text_list_of_phrases . "}}\n" ;
        }
        @list_of_phrases = &dashrep_internal_split_delimited_items( $text_list_of_phrases ) ;
        if ( open ( OUTFILE , ">" . $target_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $target_filename . " could not be opened for writing]" ;
        }
        if ( $possible_error_message eq "" )
        {
            $counter = 0 ;
            print OUTFILE $all_defs_begin ;
            foreach $phrase_name ( sort( @list_of_phrases ) )
            {
                if ( ( defined( $phrase_name ) ) && ( $phrase_name =~ /[^ ]/ ) && ( exists( $global_dashrep_replacement{ $phrase_name } ) ) )
                {
                    print OUTFILE $phrase_begin . $phrase_name . $phrase_end . $def_begin . $global_dashrep_replacement{ $phrase_name } . $def_end ;
                    $counter ++ ;
                }
            }
            print OUTFILE $all_defs_end ;
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; wrote " . $counter . " definitions to file: " . $target_filename . "}}\n" ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; error: " . $possible_error_message . "}}\n" ;
            }
        }
        close( OUTFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  get-definitions-from-file

    } elsif ( $input_text =~ /^ *get-definitions-from-file +([^ \[\]]+) *$/ )
    {
        $source_filename = $1 ;
        $source_filename =~ s/[ \t]+//g ;
        if ( open ( INFILE , "<" . $source_filename ) )
        {
            $possible_error_message = "" ;
        } else
        {
            if ( -e $source_filename )
            {
                $possible_error_message .= " [file named " . $source_filename . " found, but could not be opened]" ;
            } else
            {
                $possible_error_message .= " [file named " . $source_filename . " not found]" ;
            }
        }
        if ( $possible_error_message eq "" )
        {
            $possible_error_message .= " [file named " . $source_filename . " found, and opened]" ;
            $source_definitions = "" ;
            while( $input_line = <INFILE> )
            {
                chomp( $input_line ) ;
                $input_line =~ s/[\n\r\f\t]+/ /g ;
                if ( ( defined( $input_line ) ) && ( $input_line =~ /[^ ]/ ) )
                {
                    $source_definitions .= $input_line . " " ;
                }
            }
            $numeric_return_value = &dashrep_import_replacements( $source_definitions ) ;
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; imported " . $numeric_return_value . " definitions from file: " . $source_filename . "}}\n" ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; error: " . $possible_error_message . "}}\n" ;
            }
        }
        close( INFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  clear-all-dashrep-phrases

    } elsif ( $input_text =~ /^ *clear-all-dashrep-phrases *$/ )
    {
        $tracking_on_or_off = $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } ;
        &dashrep_delete_all( );
        if ( $tracking_on_or_off eq "on" )
        {
            print "{{trace; cleared all definitions}}\n" ;
        }
        $global_endless_loop_counter = 0 ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the actions:
#  linewise-translate-from-file-to-file and
#  linewise-translate-parameters-only-from-file-to-file
#  linewise-translate-phrases-only-from-file-to-file
#  linewise-translate-special-phrases-only-from-file-to-file
#
#  The output filename is edited to remove any path
#  specifications, so that only local files
#  are affected.
#
#  If there are Dashrep definitions, get them.

    } elsif ( $input_text =~ /^ *linewise-translate(()|(-parameters-only)|(-phrases-only)|(-special-phrases-only))-from-file-to-file +([^ \[\]]+) +([^ \[\]]+) *$/ )
    {
        $qualifier = $1 ;
        $source_filename = $6 ;
        $target_filename = $7 ;
        $source_filename =~ s/[ \t]+//g ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        if ( open ( INFILE , "<" . $source_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            if ( -e $source_filename )
            {
                $possible_error_message .= " [file named " . $source_filename . " exists, but could not be opened]" ;
            } else
            {
                $possible_error_message .= " [file named " . $source_filename . " not found]" ;
            }
        }
        if ( open ( OUTFILE , ">" . $target_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $target_filename . " could not be opened for writing]" ;
        }
        if ( $possible_error_message eq "" )
        {
            $global_ignore_level = 0 ;
            $global_capture_level = 0 ;
            $global_top_line_count_for_insert_phrase = 0 ;
            while( $input_line = <INFILE> )
            {
                chomp( $input_line ) ;
                $input_line =~ s/[\n\r\f\t]+/ /g ;
                $global_endless_loop_counter = 0 ;
                %global_replacement_count_for_item_name = ( ) ;
                $lines_to_translate = 1 ;
                while ( $lines_to_translate > 0 )
                {
                    if ( $input_line =~ /^ *dashrep-definitions-begin *$/ )
                    {
                        $all_lines = "" ;
                        $line_count = 0 ;
                        while( $input_line = <INFILE> )
                        {
                            chomp( $input_line );
                            $input_line =~ s/[\n\r\f\t]+/ /g ;
                            if ( $input_line =~ /^ *dashrep-definitions-end *$/ )
                            {
                                last;
                            }
                            if ( ( $input_line =~ /[^ ]/ ) && ( defined( $input_line ) ) )
                            {
                                $all_lines .= $input_line . " " ;
                            }
                            $line_count ++ ;
                        }
                        if ( $all_lines =~ /[^ ]/ )
                        {
                            $numeric_return_value = &dashrep_import_replacements( $all_lines );
                            if ( ( $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } eq "on" ) && ( $input_line =~ /[^ ]/ ) )
                            {
                                print "{{trace; definitions found, imported " . $numeric_return_value . " definitions from " . $line_count . " lines}}\n" ;
                            }
                        }
                        $lines_to_translate = 0 ;
                    } else
                    {
                        $lines_to_translate = 0 ;
                        if ( $qualifier eq "-parameters-only" )
                        {
                            $translation = &dashrep_expand_parameters( $input_line );
                        } elsif ( $qualifier eq "-phrases-only" )
                        {
                            $translation = &dashrep_expand_phrases( $input_line );
                        } elsif ( $qualifier eq "-special-phrases-only" )
                        {
                            $translation = &dashrep_expand_special_phrases( $input_line );
                        } else
                        {
                            $partial_translation = &dashrep_expand_parameters( $input_line );
                            $translation = &dashrep_expand_phrases( $partial_translation );
                        }
                        if ( ( $translation =~ /[^ ]/ ) && ( ( $global_ignore_level < 1 ) || ( $global_capture_level < 1 ) ) )
                        {
                            print OUTFILE $translation . "\n" ;
                        }
                        if ( $global_top_line_count_for_insert_phrase == 1 )
                        {
                            $global_top_line_count_for_insert_phrase = 2 ;
                        } elsif ( $global_top_line_count_for_insert_phrase == 2 )
                        {
                            $global_top_line_count_for_insert_phrase = 0 ;
                            if ( $global_phrase_to_insert_after_next_top_level_line ne "" )
                            {
                                $input_line = "[-" . $global_phrase_to_insert_after_next_top_level_line . "-]" ;
                                $lines_to_translate = 1 ;
                            }
                        }
                    }
                }
            }
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; linewise translated from file " . $source_filename . " to file " . $target_filename . "}}\n" ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; failed to linewise translate from file " . $source_filename . " to file " . $target_filename . "}}\n" ;
            }
        }
        close( INFILE ) ;
        close( OUTFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle the action:
#  linewise-translate-xml-tags-in-file-to-dashrep-phrases-in-file
#
#  The output filename is edited to remove any path
#  specifications, so that only local files
#  are affected.
#  If a tag does not end on the same line as it
#  starts, more lines are read in an attempt
#  to reach the end of the tag, but this
#  capability is not robust.  This is done to
#  accomodate XHTML generated by the "Tidy"
#  utility.

    } elsif ( $input_text =~ /^ *linewise-translate-xml-tags-in-file-to-dashrep-phrases-in-file +([^ \[\]]+) +([^ \[\]]+) *$/ )
    {
        $source_filename = $1 ;
        $target_filename = $2 ;
        $target_filename =~ s/^.*[\\\/]// ;
        $target_filename =~ s/^\.+// ;
        if ( open ( INFILE , "<" . $source_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $source_filename . " not found, or could not be opened]" ;
        }
        if ( open ( OUTFILE , ">" . $target_filename ) )
        {
            $possible_error_message .= "" ;
        } else
        {
            $possible_error_message .= " [file named " . $target_filename . " could not be opened for writing]" ;
        }
        if ( $possible_error_message eq "" )
        {
            $full_line = "" ;
            $multi_line_limit = 10 ;
            while( $input_line = <INFILE> )
            {
                chomp( $input_line ) ;
                $input_line =~ s/[\n\r\f\t]+/ /g ;
                if ( $full_line ne "" )
                {
                    $full_line = $full_line . " " . $input_line ;
                } else
                {
                    $full_line = $input_line ;
                }
                $open_brackets = $full_line ;
                $close_brackets = $full_line ;
                $open_brackets =~ s/[^<]//g ;
                $close_brackets =~ s/[^>]//g ;
                if ( ( length( $open_brackets ) != length( $close_brackets ) ) && ( $multi_line_count < $multi_line_limit ) )
                {
                    next ;
                }
                if ( $global_dashrep_replacement{ "dashrep-xml-trace-on-or-off" } eq "on" )
                {
                    print "{{trace; accumulated text to convert: " . $full_line . "}}\n" ;
                }
                $global_endless_loop_counter = 0 ;
                %global_replacement_count_for_item_name = ( ) ;
                $translation = &dashrep_xml_tags_to_dashrep( $full_line );
                print OUTFILE $translation . "\n" ;
                $full_line = "" ;
            }
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; source xml file named " . $source_filename . " expanded into dashrep phrases in file named " . $target_filename . "}}\n" ;
            }
            $global_dashrep_replacement{ "dashrep-list-of-xml-phrases" } = "" ;
            foreach $xml_hyphenated_phrase ( sort( keys ( %global_exists_xml_hyphenated_phrase ) ) )
            {
                $global_dashrep_replacement{ "dashrep-list-of-xml-phrases" } .= $xml_hyphenated_phrase . " " ;
            }
        } else
        {
            if ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" )
            {
                print "{{trace; failed to expand source xml file named " . $source_filename . " into dashrep phrases in file named " . $target_filename . "}}\n" ;
            }
        }
        close( INFILE ) ;
        close( OUTFILE ) ;
        $input_text = "" ;


#-----------------------------------------------
#  Handle text that was not recognized as an
#  action.

    } else
    {
        if ( ( $global_dashrep_replacement{ "dashrep-action-trace-on-or-off" } eq "on" ) && ( $input_text =~ /[^ ]/ ) )
        {
            print "{{trace; not recognized as top-level action: " . $input_text . "}}\n" ;
        }
    }


#-----------------------------------------------
#  If there was an error message, put it
#  into the text that is returned (and remove
#  the action that caused the error).

    $possible_error_message =~ s/^ +// ;
    $possible_error_message =~ s/ +$// ;
    if ( $possible_error_message =~ /[^ ]/ )
    {
        $input_text = $possible_error_message ;
    }


#-----------------------------------------------
#  Track the nesting level.

    $global_nesting_level_of_file_actions -- ;


#-----------------------------------------------
#  Return, possibly with an error message.

    return $input_text ;


#-----------------------------------------------
#  End of subroutine.

}


=head2 dashrep_linewise_translate

Reads from the standard input file,
does the specified Dashrep translations,
and writes any requested translations
into the standard output file.

There are no parameters.

Return value is a text string that is either
empty -- if there is no error -- or else
contains an error message (although currently
no errors are defined).

=cut


#-----------------------------------------------
#-----------------------------------------------
#         dashrep_linewise_translate
#-----------------------------------------------
#-----------------------------------------------

sub dashrep_linewise_translate
{

    my $input_line ;
    my $all_lines ;
    my $line_count ;
    my $numeric_return_value ;
    my $revised_text ;
    my $after_possible_action ;
    my $error_message ;


#-----------------------------------------------
#  Ensure there is no input text.

    if ( scalar( @_ ) != 0 )
    {
       carp "Warning: Call to dashrep_top_level_action subroutine does not have exactly zero parameters." ;
        return 0 ;
    }


#-----------------------------------------------
#  Read each line from the input file.

    while( $input_line = <STDIN> )
    {
        chomp( $input_line );
        $input_line =~ s/[\n\r\f\t]+/ /g ;
        if ( ( $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } eq "on" ) && ( $input_line =~ /[^ ]/ ) )
        {
            print "{{trace; linewise input line: " . $input_line . "}}\n" ;
        }


#-----------------------------------------------
#  If there are Dashrep definitions, get them.

        if ( $input_line =~ /^ *dashrep-definitions-begin *$/ )
        {
            $all_lines = "" ;
            $line_count = 0 ;
            while( $input_line = <STDIN> )
            {
                chomp( $input_line );
                $input_line =~ s/[\n\r\f\t]+/ /g ;
                if ( $input_line =~ /^ *dashrep-definitions-end *$/ )
                {
                    last;
                }
                if ( ( $input_line =~ /[^ ]/ ) && ( defined( $input_line ) ) )
                {
                    $all_lines .= $input_line . " " ;
                }
                $line_count ++ ;
            }
            if ( $all_lines =~ /[^ ]/ )
            {
                $numeric_return_value = &dashrep_import_replacements( $all_lines );
                if ( ( $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } eq "on" ) && ( $input_line =~ /[^ ]/ ) )
                {
                    print "{{trace; definition line: " . $input_line . " ; imported " . $numeric_return_value . " definitions from " . $line_count . " lines}}\n" ;
                }
            }


#-----------------------------------------------
#  Otherwise, translate this line by itself.

        } else
        {
            $global_endless_loop_counter = 0 ;
            %global_replacement_count_for_item_name = ( ) ;
            $revised_text = &dashrep_expand_parameters( $input_line );
            if ( ( $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } eq "on" ) && ( $revised_text =~ /[^ ]/ ) )
            {
                print "{{trace; line after parameters expanded: " . $revised_text . "}}\n" ;
            }
            $after_possible_action = &dashrep_top_level_action( $revised_text );
            if ( ( $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } eq "on" ) && ( $after_possible_action =~ /^ *$/ ) && ( $revised_text =~ /[^ ]/ ) )
            {
                print "{{trace; line after action executed: " . $after_possible_action . "}}\n" ;
            }
            $revised_text = &dashrep_expand_phrases( $after_possible_action );
            if ( ( $global_dashrep_replacement{ "dashrep-linewise-trace-on-or-off" } eq "on" ) && ( $revised_text =~ /[^ ]/ ) )
            {
                print "{{trace; line after phrases expanded: " . $revised_text . "}}\n" ;
            }
            print $revised_text . "\n" ;
        }


#-----------------------------------------------
#  Repeat the loop for the next line.

    }


#-----------------------------------------------
#  End of subroutine.

    return $error_message ;

}


=head2 dashrep_internal_endless_loop_info

Internal subroutine, not exported.
It is only needed within the Dashrep module.

=cut

#-----------------------------------------------
#-----------------------------------------------
#         Non-exported subroutine:
#
#         dashrep_internal_endless_loop_info
#-----------------------------------------------
#-----------------------------------------------
#  This subroutine displays the name of the
#  most-replaced hyphenated phrase, which is
#  usually the one that caused the endless loop.

#  This subroutine is not exported because it
#  is only needed within this Dashrep module.

#  The collected information is displayed in a
#  warning message.

sub dashrep_internal_endless_loop_info
{

    my $item_name ;
    my $highest_usage_counter ;
    my $highest_usage_item_name ;

    $highest_usage_counter = - 1 ;
    foreach $item_name ( keys( %global_replacement_count_for_item_name ) )
    {
        if ( $global_replacement_count_for_item_name{ $item_name } > $highest_usage_counter )
        {
            $highest_usage_counter = $global_replacement_count_for_item_name{ $item_name } ;
            $highest_usage_item_name = $item_name ;
        }
    }
   carp "Too many cycles of replacement (" . $global_endless_loop_counter . ").\n" . "Hyphenated phrase with highest replacement count (" . $highest_usage_counter . ") is:\n" . "    " . $highest_usage_item_name . "\n" ;


#-----------------------------------------------
#  End of subroutine.

    return 1 ;

}


=head2 dashrep_internal_split_delimited_items

Internal subroutine, not exported.
It is only needed within the Dashrep module.

=cut


#-----------------------------------------------
#-----------------------------------------------
#         Non-exported subroutine:
#
#         dashrep_internal_split_delimited_items
#-----------------------------------------------
#-----------------------------------------------
#  This subroutine converts a text-format list
#  of text items separated by commas, spaces, or
#  line breaks into an array of separate
#  text strings.  It does not expand any
#  hyphenated phrases.

#  This subroutine is not exported because it
#  is only needed within this Dashrep module.

sub dashrep_internal_split_delimited_items
{
    my $text_string ;
    my @array ;

    $text_string = $_[ 0 ] ;


#-----------------------------------------------
#  Convert all delimiters to single commas.

    if ( $text_string =~ /[\n\r]/ )
    {
        $text_string =~ s/[\n\r][\n\r]+/,/gs ;
        $text_string =~ s/[\n\r][\n\r]+/,/gs ;
    }

    $text_string =~ s/ +/,/gs ;
    $text_string =~ s/,,+/,/gs ;


#-----------------------------------------------
#  Remove leading and trailing commas.

    $text_string =~ s/^,// ;
    $text_string =~ s/,$// ;


#-----------------------------------------------
#  If there are only commas and spaces, or
#  the string is empty, return an empty list.

    if ( $text_string =~ /^[ ,]*$/ )
    {
        @array = ( ) ;


#-----------------------------------------------
#  Split the strings into an array.

    } else
    {
        @array = split( /,+/ , $text_string ) ;
    }


#-----------------------------------------------
#  Return the resulting array.

    return @array ;

}




=head1 AUTHOR

Richard Fobes, "CPSolver" at GitHub.com


=head1 DOCUMENTATION

See www.Dashrep.org for details about the Dashrep language.


=head1 BUGS

Please report any bugs or feature requests to "CPSolver" at GitHub.com.


=head1 TO DO

See www.Dashrep.org for descriptions of possible future developments.


=head1 ACKNOWLEDGEMENTS

Richard Fobes designed the Dashrep (TM) language and
developed the original version of this code over a
period of many years.  Richard Fobes is the author
of the book titled The Creative Problem Solver's Toolbox.


=head1 COPYRIGHT & LICENSE

Copyright 2009 through 2011 Richard Fobes at www.Dashrep.org, all rights reserved.

You can redistribute and/or modify this library module
under the Perl Artistic License 2.0, a copy
of which is included in the LICENSE file.

Conversions of this code into other languages are also
covered by the above license terms.

The Dashrep (TM) name is trademarked by Richard Fobes at
www.Dashrep.org to prevent the name from being co-opted.

The Dashrep (TM) language is in the public domain.

=cut

1; # End of package
