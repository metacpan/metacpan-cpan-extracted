package Eliza::Chatbot::Brain;

use Moo;
use MooX::LazierAttributes;

use Ref::Util qw(is_scalarref is_blessed_arrayref);

attributes(
    decomp_matches => [rw, [ ], {lzy}],
    [qw/options last/] => [rw, nan, {lzy}],
);

sub preprocess {
    my ($self, $string) = @_;
    my @orig_words = split / /, $string;

    my @converted_words;
    foreach my $word ( @orig_words ) {
        $word =~ s{[?!,]|but}{.}g;
        push @converted_words, $word; 
    }

    my $formated = join ' ', @converted_words;
    @converted_words = split /\./, $formated;
    return @converted_words;
}

sub postprocess {
   my ($self, $string) = @_;
   if ( is_blessed_arrayref($string) ) {
       for (my $i = 1; $i < scalar @{$string}; $i++){
            $string->[$i] =~ s/([,;?!]|\.*)$//;
        }
   } elsif ( is_scalarref(\$string) ) {
        $string =~ tr/  / /s;       # Eliminate any duplicate space characters. 
        $string =~ s/[ ][?]$/?/;   # Eliminate any spaces before the question mark. 
   }
   return $string;
}

sub _test_quit {
    my ($self, $string) = @_;
    foreach my $quitword (@{$self->options->data->quit}) {
        return 1 if $string =~ m{$quitword}xms;
    }
}

sub _debug_memory {
    my $self = shift;
    my @memory = @{$self->options->memory};
    my $string = sprintf("%s item(s) in memory stack:\n", scalar @memory);
    foreach my $msg (@memory) {
        $string .= sprintf("\t\t->%s\n", $msg);
    }
    return $string;
}

sub transform {
    my ($self, $string, $use_memory) = @_;

    my ($this_decomp, $reasmbkey);
    my $options = $self->options;
    $options->debug_text(sprintf("\t[Pulling string \"%s\" from memory.]\n", $string))
        if $use_memory;

    if ($self->_test_quit($string)){
        $self->last(1);
        return $options->data->final->[ $options->myrand(scalar @{$options->data->final}) ];
    }

    # Default to a really low rank. 
    my $rank   = -2;
    my $reasmb = "";
    my $goto   = "";

    # First run the string through preprocess.  
    my @string_parts = $self->preprocess( $string );

    $self->decomp_matches([]);
    # Examine each part of the input string in turn.
    foreach my $string_part (@string_parts) {

        # Run through the whole list of keywords.  
        KEYWORD: foreach my $keyword (keys %{$options->data->decomp}) {

            # Check to see if the input string contains a keyword
            # which outranks any we have found previously
            # (On first loop, rank is set to -2.)
            if ( ($string_part =~ /\b$keyword\b/i or $keyword eq $goto) 
                 and 
                 $rank < $options->data->key->{$keyword}  
               ) 
            {
                # If we find one, then set $rank to equal 
                # the rank of that keyword. 
                $rank = $options->data->key->{$keyword};
                $options->debug_text(
                    sprintf("%s \trank:%d keyword:%s",
                        ($options->debug_text // ''), $rank, $keyword)
                );

                # Now let's check all the decomposition rules for that keyword. 
                foreach my $decomp (@{$options->data->decomp->{$keyword}}) {

                    # Change '*' to '\b(.*)\b' in this decomposition rule,
                    # so we can use it for regular expressions.  Later, 
                    # we will want to isolate individual matches to each wildcard. 
                    $this_decomp = $decomp;
		    $this_decomp =~ s/\s*\*\s*/\\b\(\.\*\)\\b/g;
                    # If this docomposition rule contains a word which begins with '@', 
                    # then the script also contained some synonyms for that word.  
                    # Find them all using %synon and generate a regular expression 
                    # containing all of them. 
                    if ($this_decomp =~ /\@/ ) {
                        $this_decomp =~ s/.*\@(\w*).*/$1/i;
                        my $synonyms = join ('|', @{$options->data->synon->{$this_decomp}} );
                        $this_decomp =~ s/(.*)\@$this_decomp(.*)/$1($this_decomp\|$synonyms)$2/g;
                    }

                    $options->debug_text(
                        sprintf("%s\n\t\t: %s", $options->debug_text, $decomp)
                    );
                    
                    # Using the regular expression we just generated, 
                    # match against the input string.  Use empty "()"'s to 
                    # eliminate warnings about uninitialized variables. 
                    if ($string_part =~ /$this_decomp()()()()()()()()()()()/i) {

                        # If this decomp rule matched the string, 
                        # then create an array, so that we can refer to matches
                        # to individual wildcards.  Use '0' as a placeholder
                        # (we don't want to refer to any "zeroth" wildcard).
                        my @decomp_matches = ("0", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10); 
                      

                        push @{$self->decomp_matches}, { matches => \@decomp_matches };
                        
                        $options->debug_text(
                            sprintf( "%s : %s \n", 
                                $options->debug_text,  join( ' ', @decomp_matches))
                        );
                        
                        # Using the keyword and the decomposition rule,
                        # reconstruct a key for the list of reassamble rules.
                        $reasmbkey = join $;, $keyword, $decomp;
                        # Get the list of possible reassembly rules for this key. 
                        my @these_reasmbs = @{$options->data->reasmb->{$reasmbkey}};

                        # Pick out a reassembly rule at random :). 
                        $reasmb = $these_reasmbs[ $options->myrand( scalar @these_reasmbs ) ];
                        $options->debug_text(
                            sprintf("%s \t\t--> %s\n", 
                                $options->debug_text, $reasmb )
                        );

                        # If the reassembly rule we picked contains the word "goto",
                        # then we start over with a new keyword.  Set $keyword to equal
                        # that word, and start the whole loop over. 
                        if ($reasmb =~ m/^goto\s(\w*).*/i) {
                            $options->debug_text(sprintf("%s \$1 = $1\n",
                                $options->debug_text));
                            $goto = $keyword = $1;
                            $rank = -2;
                            redo KEYWORD;
                        }

                        # Otherwise, using the matches to wildcards which we stored above,
                        # insert words from the input string back into the reassembly rule. 
                        # [THANKS to Gidon Wise for submitting a bugfix here]
                        my $decomp_matches = $self->decomp_matches;
                        foreach my $match (@{$decomp_matches}) {
                            $match->{matches} = $self->postprocess( $match->{matches} );
                            for (my $i = 1; $i < 10; $i++) {
                                $reasmb =~ s/\($i\)/$match->{matches}->[$i]/g;
                            }
                        }

                        # Move on to the next keyword.  If no other keywords match,
                        # then we'll end up actually using the $reasmb string 
                        # we just generated above.
                        next KEYWORD;

                    }  # End if ($string_part =~ /$this_decomp/i) 

                    $options->debug_text($options->debug_text . "\n");
                } # End DECOMP: foreach $decomp (@{ $self->{decomplist}->{$keyword} }) 

            } # End if ( ($string_part =~ /\b$keyword\b/i or $keyword eq $goto) 

        } # End KEYWORD: foreach $keyword (keys %{ $self->{decomplist})
    
    } # End STRING_PARTS: foreach $string_part (@string_parts) {

    $reasmb = $self->transform("xnone", "") if $reasmb eq "";
    
    $reasmb = $self->postprocess($reasmb);
    
    if ($options->memory_on) {   
        # Shift out the least-recent item from the bottom 
        # of the memory stack if the stack exceeds the max size. 
        shift @{$options->memory} if scalar @{$options->memory} >= $options->max_memory_size;
        # push in the current reasem string
        push @{$options->memory}, $reasmb;

        $options->debug_text(sprintf("%s \t%d item(s) in memory.\n", 
                $options->debug_text, scalar @{$options->memory} ));
    }

    # Save the return string so that forgetful calling programs
    # can ask the bot what the last reply was. 
    $options->transform_text($reasmb);
    return $reasmb;
}

1;

__END__

=head1 Name

Eliza::Chatbot::Brain

=head1 VERSION

Version 0.10

=head1 SUBROUTINES/METHODS

=head2 transform

    $reply = $chatterbot->transform( $string, $use_memory );

transform applies transformation rules to the user input string.
It invokes preprocess(), does transformations, then invokes postprocess.
It returns the transformed output string, called C<$reasmb>

The algorithm embedded in the transfrom method has three main parts:

=over

=item 1

Searn the input string for a keyword.

=item 2

If we find a keyword, use the list of demoposition rules for that keyword. and pattern-match
the input string against each rule.

=item 3

If the input string matches any of the decomposition rules, then randomly select one of the 
reassembly rules for that decomposition rule, and use it to construct the reply.

transform takes two parameters. The first is the string we want to transform. The second
is a flag which indicates where this string came from. If the flag is set, then the string
has been pulled from memory, and we should use reassemble rules appropriate for that. If
the flag is not set then the string is the most recent user input, and we can use the ordinary reassembly rules.

The memory flag is only set when the transform function is called recursively. The mechanism 
for setting this parameter is embedded in he transform method itself. If the flag is set inappropriately, it is ignored.

=back

=head2 preprocess

    $string = preprocess($string);

preprocess() applies simple substitution rules to the input string.
Mostly this is to catch varieties in spelling, misspellings, contractions
and the like.

preprocess() is called from within the transform() method.
It is applied to user-input text, BEFORE any processing,
and before a reassebly statement has been selected.

It uses the array C<%pre>, which is created during the parse of the script.

=head2 postprocess

    $string = postprocess($string);

postprocess() applies simple substitution rules to the reassembly rule.
This is where all the "I"'s and "you"'s are exchanged. postprocess() is
called from within the transform() function.

It uses the attribute C<%post>, created during the parse of the script.

=head2 _test_quit
    
     $self->_test_quit($user_input) ) { } 

_test_quit detects words like "bye" and "quit" and returns true if it 
finds one of them as the first word in the sentence.

Thes words are listed in the script, under the keyword "quit".

=head2 _debug_memory

    $self->_debug_memory

_debug_memory is a special function hwihc returns the contents of Eliza's memory stack.

=head1 AUTHOR

LNATION email@lnation.org

=head1 ACKNOWLEDGEMENTS

I started here L<Chatbot::Eliza> and then got a little carried away.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

LNATION email@lnation.org

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

