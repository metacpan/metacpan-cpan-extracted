#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

package AI::FreeHAL::Module::Parser;

our $data = {};
our %config;

use AI::Util;
use AI::POS;
use AI::FreeHAL::Config;

use Data::Dumper;

our @functions = qw{
    split_sentence
    dividerparser
    get_rest_of_this_sentence
    get_count_of_verbs
    is_participle
    check_for_relative_clause
    dividerparser_statement
    dividerparser_relative_clause
    left_until_article_or_other_noun_end
    array_to_string
    hash_to_string
    is_name
    is_name_or_noun_with_genitive_s
    remove_questionword_and_description
    sort_linking
    remove_advs_to_list
    strip_nothings
    resolve_hashes
};


=head2 split_sentence($CLIENT_ref, $text)

$text will be parsed using two parsers:

=over 4

=item Parse::RecDescend

First FreeHAL tries to parse $text using a parser built with Parse::RecDescend. A generic grammer for english and german is used.

=item Traditional Parser

This parser is used by FreeHAL since Spring 2008. It can parse every sentence, but has also some bugs. That's why we try to replace it with a new one in future.

=back

=cut




sub split_sentence {
    my $CLIENT_ref = shift;
    my $CLIENT     = ${$CLIENT_ref};
    my $text       = shift;

    #$text =~ s/[{}]//gm;
    $text =~ s/  / /gm;

    $text =~ s/kennst du/was ist/igm
      if $text !~ /aus.?.?$/
          && $text !~ /(question|fact)next/
          && $text !~ /\s(es|das)\s/;

    print "split_sentence: " . $text . "\n";

    $text =~ s/["](.*?)["]/"_$1_" /igm;

#    $text
#        =~ s/["]([a-zA-Z0-9_,;-=)(_]+)\s+([a-zA-Z0-9_,;-=\)\(\s]+)["]/"$1_$2" /igm;
#    $text
#        =~ s/["]([a-zA-Z0-9_,;-=)(_]+)\s+([a-zA-Z0-9_,;-=\)\(]+)["]/"$1_$2" /igm;
    while (
        $text =~ /["]([a-zA-Z0-9_,;-=)(_]+)\s+([a-zA-Z0-9_,;-=)(_\s+]+)["]/ )
    {
        $text =~
s/["]([a-zA-Z0-9_,;-=)(_]+)\s+([a-zA-Z0-9_,;-=)(_\s+]+)["]/$1_"$2" /im;
        $text =~
          s/["]([a-zA-Z0-9_,;-=)(_]+)\s+([a-zA-Z0-9_,;-=)(_]+)["]/$1_"$2" /im;

        print $text, "\n";
    }
    $text =~ s/[_]["]/_/igm;
    $text =~ s/["]/ /igm;
    $text =~ s/\s+/ /igm;

    #	my @copy = split //, $text;
    #	$text = q{};    # empty
    #	while ( defined( my $char = $copy[0] ) ) {
    #		shift @copy;
    #		if ( $char eq q{"} ) {    # for all in "´s
##			$text .= '_';
    #		while ( my $char = $copy[0] ) {
    #			shift @copy;
    #			if ( $char eq q{"} ) {
    #					$text .= '_';
    #					last;
    #				}
    #				elsif ( $char eq q{ } ) {
    #					$text .= '_';    # replace " " by "_"
    #				}
    #				else {
    #					$text .= $char;
    #				}
    #			}
    #		}
    #		else {
    #			$text .= $char;
    #		}
    #	}

    $text =~ s/,\s*/,/gm;
    $text =~ s/\s*,/,/gm;
    $text =~ s/(\d)[,.]\s*(\d)/$1_komma_$2/igm;
    $text =~ s/[%]/ Prozent/igm;
    $text =~ s/,/ KOMMA /gm;
    $text =~ s/\s+/ /gm;
    $text =~ s/\s+$//gm;
    $text =~ s/\.$//gm;

    print '>> Sentence: ' . $text . "\n";

    #########################################################################################
    # NEW: try Parse::RecDescent
    #########################################################################################

    my $grammar = q
    ?
        Text:		Statement(s) /^$/
                    { $item[1] }
             |	<error>

        Statement:	"KOMMA" PREP QUESTIONWORDS DESCR SubStatement
                    { { questionword => $item[3], description => $item[4], %{$item[4]}, advs => [@{$item[4]->{advs}||[]}, $item[2]] } }
             |	"KOMMA" D_QUES DESCR SubStatement
                    { { questionword => $item[2], description => $item[3], %{$item[4]} } }
             |	PREPS QUESTIONWORDS DESCR SubStatement
                    { { questionword => $item[2], description => $item[3], %{$item[4]}, advs => [@{$item[4]->{advs}||[]}, $item[1]] } }
             |	D_QUES DESCR SubStatement
                    { { questionword => $item[1], description => $item[2], %{$item[3]} } }
             |	QUES SubStatement
                    { { questionword => $item[1], %{$item[2]} } }
             |	"KOMMA" QUES SubStatement
                    { { questionword => $item[2], %{$item[3]} } }
             |	"KOMMA" SUBJ_ART SubStatement
                    { do{my $hashref = { %{$item[3]}, subjects => [@{$item[3]->{subjects}}, 'RELATIVE'] }} }
             |	"KOMMA" OBJ_ART SubStatement
                    { do{my $hashref = { %{$item[3]}, objects => [@{$item[3]->{objects}}, 'RELATIVE'] }} }
             |	"KOMMA" SubStatement
                    { $item[2] }
             |	SubStatement
                    { $item[1] }

        SubStatement:	AD NounPh AD VerbPh AD NounPh AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4], $item[8] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD NounPh AD VerbPh AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[6], $item[8] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD Adverb AD VerbPh AD NounPh AD VerbPh AD
                    { { subjects => [ $item[6] ], verbs => [ $item[4], $item[8] ], objects => [ $item[2] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD Adverb AD NounPh AD VerbPh AD VerbPh AD
                    { { subjects => [ $item[4] ], verbs => [ $item[6], $item[8] ], objects => [ $item[2] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD Adverb AD VerbPh AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[6], $item[8] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD VerbPh AD Adverb AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4], $item[8] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD VerbPh AD NounPh AD NounPh AD VerbPh AD
                    { { subjects => [ $item[4] ], verbs => [ $item[2], $item[8] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD VerbPh AD NounPh AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4], $item[8] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |  AD NounPh AD VerbPh AD NounPh AD Adverb AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[8]] } }
             |	AD NounPh AD NounPh AD VerbPh AD Adverb AD
                    { { subjects => [ $item[2] ], verbs => [ $item[6] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[8]] } }
             |	AD NounPh AD NounPh AD Adverb AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[8] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[6]] } }
             |	AD Adverb AD VerbPh AD NounPh AD Adverb AD
                    { { subjects => [ $item[6] ], verbs => [ $item[4] ], objects => [ $item[2] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[8]] } }
             |	AD Adverb AD NounPh AD VerbPh AD Adverb AD
                    { { subjects => [ $item[4] ], verbs => [ $item[6] ], objects => [ $item[2] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[8]] } }
             |	AD NounPh AD Adverb AD VerbPh AD Adverb AD
                    { { subjects => [ $item[2] ], verbs => [ $item[6] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[8]] } }
             |	AD NounPh AD VerbPh AD Adverb AD Adverb AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[6], $item[8]] } }
             |	AD VerbPh AD NounPh AD NounPh AD Adverb AD
                    { { subjects => [ $item[4] ], verbs => [ $item[2] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[8]] } }
             |	AD NounPh AD VerbPh AD NounPh AD Adverb AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7], $item[9], $item[8]] } }
             |	AD NounPh AD NounPh AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[6] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD VerbPh AD NounPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD Adverb AD VerbPh AD NounPh AD
                    { { subjects => [ $item[6] ], verbs => [ $item[4] ], objects => [ $item[2] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD Adverb AD NounPh AD VerbPh AD
                    { { subjects => [ $item[4] ], verbs => [ $item[6] ], objects => [ $item[2] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD Adverb AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[6] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD VerbPh AD Adverb AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD VerbPh AD NounPh AD NounPh AD
                    { { subjects => [ $item[4] ], verbs => [ $item[2] ], objects => [ $item[6] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5], $item[7]] } }
             |	AD NounPh AD VerbPh AD
                    { { subjects => [ $item[2] ], verbs => [ $item[4] ], objects => [], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5]] } }
             |	AD Adverb AD VerbPh AD
                    { { subjects => [], verbs => [ $item[4] ], objects => [ $item[2] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5]] } }
             |	AD VerbPh AD Adverb AD
                    { { subjects => [], verbs => [ $item[2] ], objects => [ $item[4] ], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5]] } }
             |	AD VerbPh AD NounPh AD
                    { { subjects => [ $item[4] ], verbs => [ $item[2] ], objects => [], advs => [grep {$_ && $_ ne "AD"} $item[1], $item[3], $item[5]] } }

        NounPh:		Art Adverb Noun
                    { $item[1] . ' ' . $item[2] . ' ' . $item[3] }
                   |	Adverb Noun
                    { $item[1] . ' ' . $item[2] }
                   |	Art Noun
                    { $item[1] . ' ' . $item[2] }
                   |	Art Adverb
                    { $item[1] . ' ' . $item[2] }
                   |	Noun
                   
        AD:     Prep NounPh
                    { $item[1] . ' ' . $item[2] }
            |   "nicht" | "Nicht" | "not"
            |   
        VerbPh:		Verb
        QUES:		Questionword
        SUBJ_ART:	"der" | "die" | "das" | "welcher" | "welches" | "welche" | "who" | "which" | "that"
        OBJ_ART:	"den" | "dem" | "welchem" | "welchen"
        DESCR:      Adverb
             |      Noun
        PREP:       Prep
        D_QUES:     /wie|was|welch|welcher|welches|welchen|welchem|welche|which|whose|what/i

    ?;

#        Questionword:	"wer" | "weil"
#        Art:		"den" | "dem" | "welchem" | "welchen" | "der" | "die" | "das" | "welcher" | "welches" | "welche" | "who" | "which" | "that"
#        Adverb:		"da"
#        Verb:		/bin|habe|ist/
#        Noun:		/Ich|Hunger/i

    $::RD_HINT = 1;

    my @return_data = ();
    eval {
        local $SIG{__DIE__};

        eval 'use Parse::RecDescent;';

        my @Questionword = ();
        my @Art          = ();
        my @Adverb       = ();
        my @Verb         = ();
        my @Noun         = ();
        my @Prep         = ();

        my @words = split /\s+|([!.;][ ])/, $text;
        print Dumper \@words;
        my $i = 0;
        foreach my $word (@words) {
            if ( $word =~ m/^(nicht|not)$/i ) {
                next;
            }

            my $pos =
              pos_of( $CLIENT_ref, $word, $i == 0, undef, undef, $text );

            if ( $pos == $data->{const}{NOUN} ) {
                push @Noun, $word;
            }
            if ( $pos == $data->{const}{VERB} ) {
                push @Verb, $word;
            }
            if ( $pos == $data->{const}{ADJ} ) {
                push @Adverb, $word;
            }
            if ( $pos == $data->{const}{ART} ) {
                push @Art, $word;
            }
            if ( $pos == $data->{const}{QUESTIONWORD} ) {
                push @Questionword, $word;
            }
            if ( $pos == $data->{const}{PREP} ) {
                push @Prep, $word;
            }

            $i++;
        }

        push @Noun,         'nothing' if !@Noun;
        push @Verb,         'nothing' if !@Verb;
        push @Adverb,       'nothing' if !@Adverb;
        push @Art,          'nothing' if !@Art;
        push @Questionword, 'nothing' if !@Questionword;
        push @Prep,         'nothing' if !@Prep;

        $grammar .= 'Noun:  "' . join( '" | "', @Noun ) . "\"\n";
        $grammar .= 'Verb:  "' . join( '" | "', @Verb ) . "\"\n";
        $grammar .= 'Adverb:  "' . join( '" | "', @Adverb ) . "\"\n";
        $grammar .= 'Art:  "' . join( '" | "', @Art ) . "\"\n";
        $grammar .=
          'Questionword:  "' . join( '" | "', @Questionword ) . "\"\n";
        $grammar .= 'Prep:  /' . join( '|', @Prep ) . "/i\n";

        my $_preps         = '/' . join( '|', @Prep ) . '/i';
        my $_questionwords = '/' . join( '|', @Questionword ) . '/i';

        $grammar =~ s/PREPS/$_preps/gm;
        $grammar =~ s/QUESTIONWORDS/$_questionwords/gm;

        print $grammar, "\n";

        my $parser = Parse::RecDescent->new($grammar)
          or die "Bad grammar";

        my ${is_question} = 0;

        if ( $text =~ /[?]/ ) {
            $data->{lang}{is_question} = 1;
            $text =~ s/[?]//gm;
            $text =~ s/\s+?$//gm;
            $text =~ s/^\s+?//gm;
        }

        print 'text: ', $text, "\n";

        my $tree = $parser->Text($text)
          or die "Bad script";

        use Data::Dumper;
        print Dumper $tree;

        my $last_noun;
        foreach my $clause (@$tree) {
            foreach my $atom ( @{ $clause->{subjects} } ) {
                if ( $atom eq 'RELATIVE' ) {
                    $clause->{subjects} = $last_noun;
                    last;
                }
            }
            foreach my $atom ( @{ $clause->{objects} } ) {
                if ( $atom eq 'RELATIVE' ) {
                    $clause->{objects} = $last_noun;
                    last;
                }
            }

            $last_noun =
              @{ $clause->{subjects} }
              ? $clause->{subjects}
              : $clause->{objects};
        }

        print Dumper $tree;
        @return_data = ( [$tree], $data->{lang}{is_question} );
    };
    if ($@) {
        print $@, "\n";
    }
    return @return_data if (@return_data);

    #########################################################################################

    my @words = split /\s+|([!.;][ ])/, $text;
    my @new_words_array = ();
    my $adverbs;
    my $in_adverbial                    = 0;
    my $last_was_in_adverbial           = 0;
    my $last_word                       = q{};                           # empty
    my $last_pos                        = $data->{const}{POS_UNKNOWN};
    my $first_pos                       = $data->{const}{POS_UNKNOWN};
    my $adverbial                       = q{};                           # empty
    my ${is_a_question}                 = 0;
    my $word_is_first_word_is_adjective = 0;
    my @verb_prefixes_to_add            = ();
    my $after_questionword              = 0;

    for my $x ( 0 .. $#words ) {
        if ( lc $words[$x] eq 'komma' ) {
            push @verb_prefixes_to_add, q{};                             # empty
        }
    }
    push @verb_prefixes_to_add, q{};                                     # empty

    for my $x ( 0 .. $#words ) {
        my $word = $words[$x];
        if ( $word =~ /[?]/ ) {
            $data->{lang}{is_a_question} = 1;
            $word =~ s/[?]//gm;
        }
        $words[$x] = $word;
    }
    @words = grep { $_ } @words;

    if ( $data->{lang}{is_verb_prefix}{ $words[-1] } && $words[-1] !~ /[=][>]/ )
    {
        say '#';
        say '# added verb prefix ', $words[-1], ' to last position.';
        say '#';
        $verb_prefixes_to_add[-1] = pop @words;
    }

    #for my $x ( 0 .. $#words ) {
    #if ( lc $words[$x] eq 'komma' ) {
    #if ( $data->{lang}{is_verb_prefix}{ $words[ $x - 1 ] } ) {
    #$verb_prefixes_to_add[0] = $words[ $x - 1 ];
    #delete $words[ $x - 1 ];
    #}
    #last;
    #}
    #}
    if (   $words[-1] =~ /[?]/
        && $data->{lang}{is_verb_prefix}{ $words[-2] }
        && $words[-2] !~ /[=][>]/ )
    {
        my $questionmark = pop @words;
        if ( $verb_prefixes_to_add[-1] ) {
            $verb_prefixes_to_add[-1] = pop @words;
        }
        else {
            $verb_prefixes_to_add[-1] = pop @words;
        }
        say '#';
        say '# added verb prefix ', $verb_prefixes_to_add[-1],
          ' to last position.';
        say '#';
        push @words, $questionmark;
    }

    my $remove_second_word_too = 0;
    if ( $words[0] =~ /[,]/ ) {
        $words[0] =~ s/[,]//gm;
    }
    if ( $words[1] =~ /[,]/ ) {
        $words[1] =~ s/[,]//gm;
        $remove_second_word_too = 1;
    }

    my $first_is_interj =
      ( pos_of( $CLIENT_ref, $words[0], 1, undef, undef, ( join ' ', @words ) )
          == $data->{const}{INTER} );
    shift @words if $first_is_interj;
    shift @words if $first_is_interj && $remove_second_word_too;

    my @words_new = ();
    foreach my $word_item (@words) {

        if (
            $word_item =~ /^wor/i
            && pos_of(
                $CLIENT_ref, $word_item,
                0,           undef,
                undef, ( join ' ', @words )
            ) == $data->{const}{QUESTIONWORD}
          )
        {
            $word_item =~ s/^wor//i;
            push @words_new, ( $word_item, 'was' );
        }
        elsif (
            $word_item =~ /^wo.+/i
            && pos_of(
                $CLIENT_ref, $word_item,
                0,           undef,
                undef, ( join ' ', @words )
            ) == $data->{const}{QUESTIONWORD}
          )
        {
            $word_item =~ s/^wo//i;
            push @words_new, ( $word_item, 'was' );
        }
        else {
            push @words_new, $word_item;
        }
    }
    @words = @words_new;

    my $number_of_komma = 0;

    my $exit_next = 0;

    for ( my $x = 0 ; $x < @words ; $x += 1 ) {
        my $word = $words[$x];
        if ( $word =~ /[?]/ ) {
            $data->{lang}{is_a_question} = 1;
            $word =~ s/[?]//gm;
        }
        if ($exit_next) {
            $exit_next -= 1;
            next;
        }
        if ( lc $words[$x] eq 'komma' ) {
            if (   $data->{lang}{is_verb_prefix}{ $words[ $x - 1 ] }
                && $words[ $x - 1 ] !~ /[=][>]/ )
            {
                $verb_prefixes_to_add[$number_of_komma] = $words[ $x - 1 ];
                delete $words[ $x - 1 ];
            }
            $number_of_komma += 1;
        }
        my $word_next;
        my $wt_next_direct = pos_of( $CLIENT_ref, $words[ $x + 1 ],
            0, undef, undef, ( join ' ', @words ) );
        my $wt_next;
      FIND_NEXT_WORD:
        for my $d ( $x .. $#words ) {
            my $word_lower_scope = $words[$d];

            #			print "d:word_lower_scope:$d:$word_lower_scope\n";
            $wt_next =
              pos_of( $CLIENT_ref, $word_lower_scope, $d == 0, undef, undef,
                ( join ' ', @words ) );
            $wt_next = $data->{const}{NOUN} if $wt_next == $data->{const}{PP};
            if ( $wt_next == $data->{const}{VERB} ) {
                $word_next = $words[$d];
                last;
            }
            if ( $wt_next == $data->{const}{NOUN} ) {

                my $next_word_is_participle = 0;

                $word_next = $words[ $d + 1 ];

                if (
                    pos_of(
                        $CLIENT_ref, $word_next,
                        0,           undef,
                        undef, ( join ' ', @words )
                    ) == $data->{const}{ADJ}
                    && ( $word_next =~ /(end)|(ende)|(enden)|(endes)|(ender)$/ )
                  )
                {
                    $next_word_is_participle = 1;
                }

                next if $next_word_is_participle;

                $word_next = $words[$d];
                last FIND_NEXT_WORD;
            }
        }
        my $word_tmp = $words[$x];
        chomp $word;
        chomp $word_tmp;
        my $wt =
          pos_of( $CLIENT_ref, $word, $x == 0, undef, undef,
            ( join ' ', @words ) );

        if ( $wt == $data->{const}{VERB} && $word !~ /[=][>]/ ) {
            $word = $verb_prefixes_to_add[$number_of_komma] . $word
              if !$data->{lang}{is_modal_verb}{ lc $word };
            $verb_prefixes_to_add[$number_of_komma] = q{}
              if !$data->{lang}{is_modal_verb}{ lc $word };
        }

        if (   $last_pos == $data->{const}{KOMMA}
            && $wt == $data->{const}{PREP}
            && $wt_next_direct != $data->{const}{ART}
            && $word ne 'sondern' )
        {
            $wt = $data->{const}{QUESTIONWORD};
        }

        if (   $last_pos == $data->{const}{ADJ}
            && $wt == $data->{const}{KOMMA}
            && $wt_next_direct == $data->{const}{ADJ} )
        {

            $x += 1;
            my $word = $words[$x];

            if ($word) {
                if ( $new_words_array[-1]->[2] ) {
                    $new_words_array[-1]->[2] .= ' ' . $word;
                }
                else {
                    $new_words_array[-1]->[0] .= ' ' . $word;
                }
            }

            next;
        }

        if (   $wt == $data->{const}{ADJ}
            && $word_is_first_word_is_adjective != 2
            && $wt_next != $data->{const}{NOUN} )
        {
            $word_is_first_word_is_adjective = 1;
        }
        else {
            $word_is_first_word_is_adjective = 2;
        }

        #		print 'pos_of( $CLIENT_ref, ' . $word . ', '
        #		  . ( $x == 0 ) . ' ): '
        #		  . $wt . "\n";

        if (
            (
                is_name(
                    $word . ' ' . $words[ $x + 1 ] . ' ' . $words[ $x + 2 ]
                )
                || $data->{lang}{is_anrede}{ lc $word }
            )
            && $x + 2 < scalar @words
            && (   $wt == $data->{const}{NOUN}
                || $wt == $data->{const}{ART}
                || $wt == $data->{const}{ADJ} )
            && pos_of(
                $CLIENT_ref, $words[ $x + 1 ],
                0,           undef,
                undef, ( join ' ', @words )
            ) == $data->{const}{NOUN}
            && pos_of(
                $CLIENT_ref, $words[ $x + 2 ],
                0,           undef,
                undef, ( join ' ', @words )
            ) == $data->{const}{NOUN}
          )
        {
            $words[ $x + 2 ] =
              $word . " " . $words[ $x + 1 ] . " " . $words[ $x + 2 ];
            $exit_next = 1;
            next;
        }

        if (
            (
                is_name( $word . ' ' . $words[ $x + 1 ] )
                || $data->{lang}{is_anrede}{ lc $word }
            )
            && $x + 1 < scalar @words
            && $wt == $data->{const}{NOUN}
            && pos_of(
                $CLIENT_ref, $words[ $x + 1 ],
                0,           undef,
                undef, ( join ' ', @words )
            ) == $data->{const}{NOUN}
          )
        {
            $words[ $x + 1 ] = $word . " " . $words[ $x + 1 ];
            next;
        }

        if ( $wt == $data->{const}{UNIMPORTANT} ) {
            next;
        }

        if ( $first_pos == $data->{const}{POS_UNKNOWN} ) {
            $first_pos = $wt;
        }
        if ( $wt == $data->{const}{PP} ) {
            $wt = $data->{const}{NOUN};
        }
        
        print "wt is: ", $wt, "\n";

        if ( $wt == $data->{const}{ART} ) {
            $word_tmp .= " - Artikel";
        }
        if ( $wt == $data->{const}{ADJ} ) {
            $word_tmp .= " - Adjektiv";
        }
        if ( $wt == $data->{const}{NOUN} ) {
            $word_tmp .= " - $data->{const}{NOUN}";
        }
        if ( $wt == $data->{const}{VERB} ) {
            $word_tmp .= " - Verb";
        }
        if ( $wt == $data->{const}{QUESTIONWORD} ) {
            $word_tmp .= " - questionwort";
        }
        if ( $wt == $data->{const}{PREP} ) {
            $word_tmp .= " - Praeposition";
        }
        if ( $wt == $data->{const}{SPO} ) {
            $word_tmp .= " - Subjekt/Verb/Objekt";
        }
        if ( $wt == $data->{const}{KOMMA} ) {
            $word_tmp .= " - ein Komma";
        }

        my $linking_adverbial_restore =
          (      $in_adverbial
              && $data->{lang}{is_linking}{ lc $words[ $x + 1 ] }
              && $wt_next_direct == $data->{const}{VERB} )
          ? 1
          : 0;

        if ( $wt == $last_pos && $wt == $data->{const}{NOUN} && $in_adverbial )
        {
            if (  !is_name($word)
                || is_name($last_word) )
            {
                $last_was_in_adverbial = $in_adverbial;
                if ( $in_adverbial == 1 ) {

                    #$in_adverbial          = 0;
                }
                elsif ( $in_adverbial == 2 ) {
                    $in_adverbial = 1;
                }
            }
        }

       #if ( $wt == $data->{const}{VERB} && $last_pos == $data->{const}{ART} ) {
       #    $wt = $data->{const}{ADJ};
       #}
        if ( $wt == $data->{const}{VERB} && $last_pos == $data->{const}{PREP} )
        {
            $wt = $data->{const}{ADJ};
        }
        if ( $wt == $data->{const}{PREP} ) {
            if ( $last_pos == $data->{const}{ART} ) {
                push @new_words_array, [ 'nothing', $data->{const}{NOUN}, q{} ];
            }

            if ( $last_pos != $data->{const}{KOMMA} ) {
                $in_adverbial ||= 1;
            }

            if (   $last_pos != $data->{const}{KOMMA}
                && $last_pos == $data->{const}{ART} )
            {
                $in_adverbial = 2;
            }
        }
        if ( $wt == $data->{const}{VERB} ) {
            if (  !is_name($word)
                || is_name($last_word) )
            {
                $in_adverbial = 0;
            }
        }
        if ( $wt == $data->{const}{QUESTIONWORD} ) {
            $in_adverbial = 0;
        }

        if ( $wt == $data->{const}{NOUN}
            && is_name_or_noun_with_genitive_s($word) )
        {
            $in_adverbial ||= 1;

            $adverbial .= ' ';
            $adverbial .= 'von';
            chomp $adverbial;

            $word =~ s/.$//;    # no 'g', only once!
        }

        say( '(06)', $in_adverbial );

        say '$last_pos: ', $last_pos;
        if (   $wt == $data->{const}{ART}
            && LANGUAGE() eq 'de'
            && $last_pos != $data->{const}{KOMMA}
            && $last_pos != $data->{const}{ART}
            && $wt_next == $data->{const}{NOUN} )
        {
            print 'word_next:' . $word_next . "\n";
            my $g = ( pos_prop( $CLIENT_ref, $word_next ) )->{'genus'};
            say $g;

            if ( $g =~ /m$/ ) {
                if (   lc $word ne "der"
                    && lc $word ne "den"
                    && lc $word ne "des"
                    && lc $word ne "ein"
                    && lc $word ne "einen"
                    && lc $word ne "mein"
                    && lc $word ne "meinen"
                    && lc $word ne "dein"
                    && lc $word ne "deinen"
                    && lc $word ne "sein"
                    && lc $word ne "seinen"
                    && lc $word ne "unser"
                    && lc $word ne "unseren"
                    && lc $word ne "unsern"
                    && lc $word ne "euer"
                    && lc $word ne "euren"
                    && lc $word ne "eueren"
                    && lc $word ne "euer"
                    && lc $word ne "ihr"
                    && lc $word ne "ihren"
                    && lc $word !~ /er$/
                    && lc $word !~ /en$/ )
                {
                    $in_adverbial ||= 1;
                }
                elsif ($last_pos == $data->{const}{NOUN}
                    && lc $word !~ /er$/
                    && lc $word !~ /en$/ )
                {

                    $in_adverbial ||= 1;
                }

                elsif ( $last_pos == $data->{const}{NOUN} ) {

                    $in_adverbial = 0;
                }

                #else {
                # 	$in_adverbial = 0;
                #}
            }
            if ( $g =~ /f$/ ) {
                if (   lc $word ne "die"
                    && lc $word ne "eine"
                    && lc $word ne "einen"
                    && lc $word ne "einer"
                    && lc $word ne "meine"
                    && lc $word ne "meiner"
                    && lc $word ne "meinen"
                    && lc $word ne "deine"
                    && lc $word ne "deiner"
                    && lc $word ne "meinen"
                    && lc $word ne "seine"
                    && lc $word ne "seiner"
                    && lc $word ne "meinen"
                    && lc $word ne "unsere"
                    && lc $word ne "unserer"
                    && lc $word ne "unseren"
                    && lc $word ne "euere"
                    && lc $word ne "eurer"
                    && lc $word ne "euren"
                    && lc $word ne "euerer"
                    && lc $word ne "euere"
                    && lc $word ne "ihre"
                    && lc $word ne "eine"
                    && lc $word ne "ihrer"
                    && lc $word ne "ihren"
                    && lc $word !~ /e$/
                    && lc $word !~ /ein$/ )
                {
                    $in_adverbial ||= 1;
                }
                elsif ( $last_pos == $data->{const}{NOUN}
                    && lc $word =~ /er$/ )
                {

                    $in_adverbial ||= 1;
                }

                elsif ( $last_pos == $data->{const}{NOUN} ) {

                    $in_adverbial = 0;
                }
            }
            if ( $g =~ /s$/ ) {
                if (   lc $word ne "der"
                    && lc $word ne "den"
                    && lc $word ne "das"
                    && lc $word ne "einem"
                    && lc $word ne "ein"
                    && lc $word ne "mein"
                    && lc $word ne "meinem"
                    && lc $word ne "dein"
                    && lc $word ne "deinem"
                    && lc $word ne "sein"
                    && lc $word ne "seinem"
                    && lc $word ne "unser"
                    && lc $word ne "unserem"
                    && lc $word ne "unserm"
                    && lc $word ne "euer"
                    && lc $word ne "eurem"
                    && lc $word ne "euerem"
                    && lc $word ne "euerm"
                    && lc $word ne "ihr"
                    && lc $word ne "dem"
                    && lc $word ne "ihrem"
                    && lc $word !~ /em$/ )
                {
                    $in_adverbial ||= 1;
                }
                elsif ( $last_pos == $data->{const}{NOUN} ) {

                    $in_adverbial = 0;
                }
            }
        }

        say( '(05)', $in_adverbial );

        my $ist_einzelnes_adjektiv = 0;
        if ( $wt == $data->{const}{ADJ} ) {
            my $has_no_noun_behind = 1;
            if ( $x + 1 >= scalar @words ) {
                $has_no_noun_behind = 1;
            }
            my $wt_1 = $data->{const}{POS_UNKNOWN};
            my $wt_2 = $data->{const}{POS_UNKNOWN};
            my $wt_3 = $data->{const}{POS_UNKNOWN};
            if ( $x + 1 < scalar @words ) {
                $wt_1 = pos_of( $CLIENT_ref, $words[ $x + 1 ],
                    0, undef, undef, ( join ' ', @words ) );
                if (   $wt_1 == $data->{const}{NOUN}
                    || $wt_1 == $data->{const}{PP} )
                {
                    print '('
                      . ( $wt_1 == $data->{const}{NOUN} ) . ' || '
                      . ( $wt_1 == $data->{const}{PP} ) . ")\n";
                    $has_no_noun_behind = 0;
                }
            }
            if ( $x + 2 < scalar @words && $wt_1 != $data->{const}{KOMMA} ) {
                $wt_2 = pos_of( $CLIENT_ref, $words[ $x + 2 ],
                    0, undef, undef, ( join ' ', @words ) );
                if (   $wt_2 == $data->{const}{NOUN}
                    || $wt_2 == $data->{const}{PP} )
                {
                    print "("
                      . ( $wt_2 == $data->{const}{NOUN} ) . " || "
                      . ( $wt_2 == $data->{const}{PP} ) . ") && "
                      . ( $wt_1 != $data->{const}{KOMMA} ) . "\n";
                    $has_no_noun_behind = 0;
                }
            }
            if ( $x + 3 < scalar @words && $wt_1 != $data->{const}{KOMMA} ) {
                if ( $words[ $x + 1 ] ne "," && $words[ $x + 2 ] ne "," ) {
                    $wt_3 = pos_of( $CLIENT_ref, $words[ $x + 3 ],
                        0, undef, undef, ( join ' ', @words ) );
                    if (   $wt_3 == $data->{const}{NOUN}
                        || $wt_3 == $data->{const}{PP}
                        && $wt_1 != $data->{const}{KOMMA} )
                    {
                        print "("
                          . ( $wt_3 == $data->{const}{NOUN} ) . " || "
                          . ( $wt_3 == $data->{const}{PP} ) . ") && "
                          . ( $wt_1 != $data->{const}{KOMMA} ) . " && "
                          . ( $wt_2 != $data->{const}{KOMMA} ) . "|"
                          . $wt_1
                          . $wt_2
                          . $words[ $x + 1 ] . ";"
                          . $words[ $x + 2 ] . "\n";
                        $has_no_noun_behind = 0;
                    }
                }
            }
            if ( $has_no_noun_behind && $last_pos != $data->{const}{KOMMA} ) {
                $ist_einzelnes_adjektiv = 1;
            }
        }
        my $before_questionword = 0;
        if ( $x + 1 < scalar @words ) {
            my $wt_ = pos_of( $CLIENT_ref, $words[ $x + 1 ],
                0, undef, undef, ( join ' ', @words ) );
            if ( $wt_ == $data->{const}{QUESTIONWORD} ) {
                $before_questionword = 1;

                if ( scalar @new_words_array >= 3 ) {
                    $before_questionword = 1;
                }
                elsif ( !is_name($word)
                    || is_name($last_word) )
                {
                    $in_adverbial = 0;
                }

            }
        }
        $after_questionword = 0
          if $wt != $data->{const}{NOUN}
              && $last_pos != $data->{const}{ADJ}
              && $wt != $data->{const}{ADJ};
        if ( $x - 1 < scalar @words && $x - 1 >= 0 ) {
            my $wt_ = pos_of( $CLIENT_ref, $words[ $x - 1 ],
                0, undef, undef, ( join ' ', @words ) );
            if (
                $wt_ == $data->{const}{QUESTIONWORD}
                && (   lc $words[ $x - 1 ] ne "wenn"
                    && lc $words[ $x - 1 ] ne "falls"
                    && lc $words[ $x - 1 ] ne "sobald"
                    && lc $words[ $x - 1 ] ne "if"
                    && lc $words[ $x - 1 ] ne "when"
                    && lc $words[ $x - 1 ] ne "why"
                    && lc $words[ $x - 1 ] ne "wer"
                    && lc $words[ $x - 1 ] ne "who"
                    && lc $words[ $x - 1 ] ne "warum"
                    && lc $words[ $x - 1 ] ne "wieso"
                    && lc $words[ $x - 1 ] ne "weshalb"
                    && lc $words[ $x - 1 ] ne "because"
                    && lc $words[ $x - 1 ] ne "weil" )
              )
            {
                $after_questionword = 1 if $wt != $data->{const}{VERB};
                if (  !is_name( lc $word )
                    || is_name( lc $last_word ) )
                {
                    $in_adverbial = 0;
                }
            }
        }
        my $verb_in_sicht = 0;
        if ( $x < scalar @words ) {
            my $wt_ =
              pos_of( $CLIENT_ref, $words[$x], 0, undef, undef,
                ( join ' ', @words ) );
            if ( $wt_ == $data->{const}{VERB} ) {
                $verb_in_sicht = 1;
            }
        }
        if ( $x + 1 < scalar @words ) {
            my $wt_ = pos_of( $CLIENT_ref, $words[ $x + 1 ],
                0, undef, undef, ( join ' ', @words ) );
            if ( $wt_ == $data->{const}{VERB} ) {
                $verb_in_sicht = 1;
            }
        }
        if ( $x + 2 < scalar @words ) {
            my $wt_ = pos_of( $CLIENT_ref, $words[ $x + 2 ],
                0, undef, undef, ( join ' ', @words ) );
            if ( $wt_ == $data->{const}{VERB} ) {
                $verb_in_sicht = 1;
            }
        }
        if ( $x + 3 < scalar @words ) {
            my $wt_ = pos_of( $CLIENT_ref, $words[ $x + 3 ],
                0, undef, undef, ( join ' ', @words ) );
            if ( $wt_ == $data->{const}{VERB} ) {
                $verb_in_sicht = 1;
            }
        }

        if ( $in_adverbial && $wt == $data->{const}{VERB} ) {
            $in_adverbial = 0;
        }

        if ( $wt == $data->{const}{KOMMA} || $word =~ /komma/i ) {

            $in_adverbial           = 0;
            $ist_einzelnes_adjektiv = 0;
            $verb_in_sicht          = 0;
        }

        say( '(04)', $in_adverbial );

        if ( $wt_next_direct == $data->{const}{VERB} && lc $word eq 'to' ) {
            $word = 'XXtoXX';
            $wt   = $data->{const}{QUESTIONWORD};
            push @new_words_array, [ 'KOMMA', $data->{const}{KOMMA}, q{} ];

            $in_adverbial           = 0;
            $ist_einzelnes_adjektiv = 0;
            $verb_in_sicht          = 0;
        }

        say '$wt_next_direct: ', $wt_next_direct;
        say 'lc $word eq \'zu\':', lc $word eq 'zu';
        say $wt_next_direct == $data->{const}{VERB}, ' && ', lc $word eq 'zu';

        if ( $wt_next_direct == $data->{const}{VERB} && lc $word eq 'zu' ) {
            $word = 'XXtoXX';
            $wt   = $data->{const}{QUESTIONWORD};

            #if ( $last_pos == $data->{const}{VERB} ) {
            push @new_words_array, [ 'KOMMA', $data->{const}{KOMMA}, q{} ];

            #}

            $in_adverbial           = 0;
            $ist_einzelnes_adjektiv = 0;
            $verb_in_sicht          = 0;
        }

        if (   @new_words_array
            && @new_words_array > 1
            && lc $word =~
/^(that|which|whose|what|who|where|when|if|because|before|after|nachdem|anstatt|dass|bevor|aber|wohingegen|jedoch)$/
          )
        {
            $wt = $data->{const}{QUESTIONWORD};

            #if ( $last_pos == $data->{const}{VERB} ) {
            if ($adverbial) {
                push @new_words_array,
                  [ 'nothing', $data->{const}{NOUN}, $adverbial ];
            }
            push @new_words_array, [ 'KOMMA', $data->{const}{KOMMA}, q{} ];

            #}

            $in_adverbial           = 0;
            $ist_einzelnes_adjektiv = 0;
            $verb_in_sicht          = 0;
        }

        if ( $wt == $data->{const}{VERB} && $word =~ /zu/i ) {
            my $prefixes      = '';
            my $there_is_a_zu = 0;

          FIND_ZU:
            foreach my $dum ( 0 .. 10 ) {
                foreach my $prefix ( keys %{ $data->{lang}{is_verb_prefix} } ) {
                    if ( $word =~ /^zu/i ) {
                        $word =~ s/^zu//i;
                        $there_is_a_zu = 1;
                        $word          = $prefixes . $word;

                        last FIND_ZU;
                    }
                    elsif ( $word =~ /^$prefix/i ) {
                        $word =~ s/^$prefix//i;
                        $prefixes .= $prefix;
                    }
                }
            }

            if ($there_is_a_zu) {
                $in_adverbial = 0;
                push @new_words_array,
                  [ 'XXtoXX', $data->{const}{QUESTIONWORD}, q{} ];
            }
        }

#		if (    $wt == $data->{const}{KOMMA}
#		     && $last_pos == $data->{const}{ADJ}
#		     && $wt_next_direct == $data->{const}{ADJ}
#		     && (   $words[$x+1] =~ /^[-+]?\d+$/;
#	             || $words[$x+1] =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/
#	            )
#	       ) {
#
#		}

        say( '(03)', $in_adverbial );

        if ( $data->{lang}{is_linking_but_not_divide}{ lc $word } ) {
            $in_adverbial = 1 if $last_was_in_adverbial;
        }

        if ( $x == 0 && $data->{lang}{is_adverb_of_time}{ lc $word } ) {
            $in_adverbial ||= 1;
        }

        say( '(02)', $in_adverbial );

        #if ( $last_pos == $data->{const}{ART} ) {
        #    $in_adverbial = 0;
        #}

        #if ( $wt == $data->{const}{ADJ} ) {
        #    $in_adverbial = 0;
        #}

        if ( $word =~ /^zu[mr]_/ ) {
            if ( @new_words_array && $new_words_array[-1][0] eq 'nothing' ) {
                $new_words_array[-1][2] .= ' ' . $word;
            }
            else {
                push @new_words_array,
                  [ 'nothing', $data->{const}{NOUN}, $word ];
            }
        }
        elsif ( $wt == $data->{const}{ART} && !$in_adverbial ) {
            push @new_words_array,
              [ 'nothing', $data->{const}{ADJ}, $adverbial ]
              if $adverbial;
            push @new_words_array, [ $word, $wt, q{} ];
            $adverbial = q{};    # empty
        }
        elsif ( $after_questionword && $in_adverbial ) {
            $new_words_array[-1]->[2] .= $adverbial;
            push @new_words_array, [ $word, $wt, q{} ];
            $adverbial = q{};    # empty
        }
        elsif (
            ( $before_questionword || $after_questionword )
            && (   $wt == $data->{const}{ART}
                || $wt == $data->{const}{NOUN}
                || $wt == $data->{const}{ADJ}
                || $wt == $data->{const}{PREP} )
            && $verb_in_sicht
            && (
                (
                      ( $x - 1 >= 0 )
                    ? ( $words[ $x - 1 ] )
                    : q{}
                ) ne "dass"
            )
          )
        {
            $adverbial .= " ";
            $adverbial .= $word;
            chomp $adverbial;
        }
        elsif ($in_adverbial) {
            if ( $wt == $data->{const}{PREP} ) {
                $adverbial .= " ";
            }
            else {
                $adverbial .= " ";
            }
            $adverbial .= $word;
            chomp $adverbial;
        }

        #elsif ($ist_einzelnes_adjektiv) {
        #$adverbial .= " ";
        #$adverbial .= $word;
        #chomp $adverbial;
        #}
        elsif ( $word_is_first_word_is_adjective == 1 ) {
            $adverbial .= " ";
            $adverbial .= $word;
            chomp $adverbial;
        }
        else {
            if (   $wt == $data->{const}{VERB}
                || $data->{lang}{is_linking}{ lc $word } )
            {
                if ( $adverbial && @new_words_array ) {
                    if ( $new_words_array[-1][0] eq 'nothing' ) {
                        $new_words_array[-1][2] .= ' ' . $adverbial;
                    }
                    else {
                        push @new_words_array,
                          [ 'nothing', $data->{const}{NOUN}, $adverbial ];
                    }
                    $adverbial = q{};    # empty
                }
            }

            if ( $after_questionword || @new_words_array ) {
                if (   $new_words_array[-1]->[1] == $data->{const}{ART}
                    || $new_words_array[-1]->[1] == $data->{const}{ADJ} )
                {
                    push @new_words_array,
                      [ 'nothing', $data->{const}{ADJ}, $adverbial ]
                      if $adverbial;
                    push @new_words_array, [ $word, $wt, q{} ];
                }
                else {
                    $new_words_array[-1]->[2] .= $adverbial;
                    push @new_words_array, [ $word, $wt, q{} ];
                }
                $adverbial = q{};    # empty
            }
            else {
                push @new_words_array, [ $word, $wt, $adverbial ];
            }
            if ( length($adverbial) != 0 ) {
                $adverbial = q{};    # empty
            }
            if (  !is_name($word)
                || is_name($last_word) )
            {
                if (
                    !$data->{lang}{is_linking_but_not_divide}{ lc $last_word } )
                {
                    $last_was_in_adverbial = $in_adverbial;
                    $in_adverbial          = 0;
                }
            }
        }

        if ( $wt == $data->{const}{NOUN} ) {
            $last_was_in_adverbial = $in_adverbial;
            if ( $in_adverbial == 1 ) {

                #$in_adverbial          = 0;
            }
            elsif ( $in_adverbial == 2 ) {
                $in_adverbial = 1;
            }
        }

        say( '(01)', $in_adverbial );

        if ($linking_adverbial_restore) {
            $in_adverbial ||= 1;
        }

        if ( $data->{lang}{is_linking_but_not_divide}{ lc $word } ) {
            $in_adverbial = 1 if $last_was_in_adverbial;
        }

        print $in_adverbial
          . $ist_einzelnes_adjektiv
          . $before_questionword
          . $after_questionword
          . $verb_in_sicht

          #		  . $in_adverbial_backup
          . " " . $word_tmp . $wt . $last_word . "\n";

        $last_pos  = $wt;
        $last_word = $word;

        if (
            @new_words_array
            && (   $new_words_array[-1][0] eq ' '
                || $new_words_array[-1][0] eq '' )
          )
        {
            pop @new_words_array;
        }
    }

    my @new_words_array_divided_by_komma = ( [] );
    foreach my $item (@new_words_array) {
        if ( lc $item->[0] eq 'komma' ) {
            push @new_words_array_divided_by_komma, [];
            next;
        }
        push @{ $new_words_array_divided_by_komma[-1] }, $item;
    }

    say Dumper \@verb_prefixes_to_add;
    foreach my $num ( 0 .. @verb_prefixes_to_add ) {

        my $only_one_verb =
          grep { $_->[1] == $data->{const}{VERB} }
          @{ $new_words_array_divided_by_komma[$num] };
        $only_one_verb =
          $only_one_verb == 1
          ? 1
          : 0;

        if ( $verb_prefixes_to_add[$num] && $only_one_verb ) {
            my $num_of_komma = 0;
            foreach my $item ( @{ $new_words_array_divided_by_komma[$num] } ) {
                if ( $item->[1] == $data->{const}{VERB} ) {
                    $item->[0] = $verb_prefixes_to_add[$num] . $item->[0];
                }
            }
        }
    }

    if ( length($adverbial) != 0 ) {
        if ( @new_words_array > 0 ) {
            $new_words_array[-1]->[2] .= " " . $adverbial;
            chomp $new_words_array[-1]->[2];
            $adverbial = q{};    # empty
        }
    }
    else {
        push @new_words_array, [ q{nothing}, $last_pos, $adverbial ];
    }

    foreach my $item (@new_words_array) {
        my $to_print = join ";", @$item;
        print $to_print . "\n";
    }

    my @clauses_with_relative_sentences = ();

    my @new_words                 = ( [] );
    my @new_words_komma_adverbial = ( [] );
    my $index                     = -1;

    ### BEGIN this will never execute

    if (0) {
        << 'EOT';
        my $word_count = -1;
        while ( my $item = shift @new_words_array ) {
            my ${is_komma}= ( ( $item->[0] ) =~ /KOMMA/i );
            $word_count += 1;

            if ($is_komma) {
                if (   $new_words[$index]->[-1]
                    && $new_words_array[0]->[1] == $data->{const}{ADJ}
                    && $new_words[$index]->[-1]->[1] == $data->{const}{ADJ} )
                {
                    my $next_item = shift @new_words_array;
                    $new_words[$index]->[-1]->[0] .= ',_' . $next_item->[0];
                    $new_words[$index]->[-1]->[2] .= ' ' . $next_item->[2]
                      if $next_item->[2];
                    chomp $new_words[$index]->[-1]->[2];
                    next;
                }
            }

            if ( $data->{lang}{is_komma}|| $word_count == 0 ) {
                say "ITEM:", ( join ', ', @$item );

                my @rest_of_sentence = ();

                while ( defined( my $item = shift @new_words_array ) ) {
                    if ( $item->[1] == $data->{const}{QUESTIONWORD} && $item->[0] ne 'XXtoXX' ) {
                        push @rest_of_sentence, $item;

                        #					unshift @new_words_array, $item;
                        last;
                    }
                    if ( ( join ";", @$item ) =~ /KOMMA/i ) {
                        unshift @new_words_array, $item;
                        last;
                    }
                    push @rest_of_sentence, $item;
                }

                my $already_done_unshift = 0;

                my @count_of_verbs = grep { $_->[1] == $data->{const}{VERB} } @rest_of_sentence;
                if ( !@count_of_verbs || $word_count == 0 ) {
                    unshift @new_words_array, @rest_of_sentence;
                    $already_done_unshift = 1;

                    #				unshift @new_words_array, $article;
                }

                say '$data->{lang}{is_article_for_subject}{ $rest_of_sentence[0]->[1] }: ',
                  $data->{lang}{is_article_for_subject}{ $rest_of_sentence[0]->[0] };
                say '$rest_of_sentence[0]->[1]:                            ',
                  $rest_of_sentence[0]->[1];
                say '$is_komma:                                            ',
                  $is_komma;
                say '$index >= 0:                                          ',
                  $index >= 0;
                say '\$rest_of_sentence: ', Dumper \@rest_of_sentence;

                if (
                    $data->{lang}{is_komma}                    && (   $data->{lang}{is_article_for_subject}{ $rest_of_sentence[0]->[0] }
                        || $data->{lang}{is_article_for_object}{ $rest_of_sentence[0]->[0] } )
                    && $index >= 0
                    && @count_of_verbs
                  )
                {
                    my $article = shift @rest_of_sentence;

                    my @as_subj = ();
                    my @as_obj  = ();

                    if ( $data->{lang}{is_article_for_subject}{ $article->[0] } ) {
                        @as_subj = left_until_article_or_other_noun_end(
                            @{ $new_words[$index] } );
                    }

                    if ( $data->{lang}{is_article_for_object}{ $article->[0] } ) {
                        @as_obj = left_until_article_or_other_noun_end(
                            @{ $new_words[$index] } );
                    }

                    if (@count_of_verbs) {
                        push @clauses_with_relative_sentences,
                          [ [ @as_subj, @rest_of_sentence, @as_obj, ] ];
                        print Dumper [ @as_subj, @rest_of_sentence, @as_obj, ];
                    }
                    shift @new_words_array;
                }
                elsif (
                       $data->{lang}{is_komma}                    && $rest_of_sentence[0]->[1] == $data->{const}{PREP}
                    && (   $data->{lang}{is_article_for_subject}{ $rest_of_sentence[1]->[0] }
                        || $data->{lang}{is_article_for_object}{ $rest_of_sentence[1]->[0] } )
                    && $index >= 0
                    && @count_of_verbs
                  )
                {
                    my $data->{const}{PREP}    = shift @rest_of_sentence;
                    my $article = shift @rest_of_sentence;

                    my @as_subj = ();
                    my @as_obj  = ();

                    my @things = [
                        'nothing',
                        $data->{const}{NOUN},
                        $data->{const}{PREP}->[0]
                          . ( ( $data->{const}{PREP}->[2] ) ? ' ' : '' )
                          . $data->{const}{PREP}->[2] . ' '
                          . (
                            join ' ',
                            map { $_->[0] . ( $_->[2] ? ' ' : '' ) . $_->[2] }
                              left_until_article_or_other_noun_end(
                                @{ $new_words[$index] }
                              )
                          )
                    ];

                    if ( $data->{lang}{is_article_for_subject}{ $article->[0] } ) {
                        @as_subj = @things;
                    }

                    if ( $data->{lang}{is_article_for_object}{ $article->[0] } ) {
                        @as_obj = @things;
                    }

                    if (@count_of_verbs) {
                        push @clauses_with_relative_sentences,
                          [ [ @as_subj, @rest_of_sentence, @as_obj, ] ];
                    }
                    shift @new_words_array;
                }
                else {
                    print '@count_of_verbs: ', Dumper \@count_of_verbs;
                    say '$rest_of_sentence[0]->[1] == $data->{const}{QUESTIONWORD}: ',
                      $rest_of_sentence[0]->[1] == $data->{const}{QUESTIONWORD};

                    if (   @count_of_verbs
                        || $rest_of_sentence[0]->[1] == $data->{const}{QUESTIONWORD} )
                    {
                        if ( $word_count > 0 ) {
                            unshift @new_words_array, @rest_of_sentence
                              if !$already_done_unshift;

                            # begin a new komma subclause
                            print 'Clearing @tmp:'
                              . ( @{ $new_words[$index] } ) . "\n";
                            push @new_words,                 [];
                            push @new_words_komma_adverbial, [];
                            $index += 1;
                        }
                        if ( $word_count == 0 ) {
                            push @{ $new_words[$index] }, $item;
                        }
                    }

                    else {
                        if ( $word_count > 0 ) {
                            my $adverbial_string = join ' ',
                              map { $_->[0] . ' ' . $_->[2] } @rest_of_sentence;
                            $adverbial_string =~ s/\s+/ /igm;
                            $adverbial_string =~ s/(\s+$)|(^\s+)//igm;
                            $adverbial_string =~ s/\s/_/igm;

                            #					$adverbial_string = '(' . $adverbial_string . ')';
                            #					push @{ $new_words[$index] },
                            #						[ $adverbial_string, $data->{const}{ADJ}, q{} ];
                            $new_words_komma_adverbial[$index] = []
                              if !( $new_words_komma_adverbial[$index] );
                            push @{ $new_words_komma_adverbial[$index] },
                              $adverbial_string;

                            while ( my $item = shift @new_words_array ) {
                                if ( ( join ";", @$item ) =~ /KOMMA/i ) {
                                    last;
                                }
                                push @rest_of_sentence, $item;
                            }
                        }
                        else {

                            #						unshift @new_words_array, @rest_of_sentence;
                            push @{ $new_words[$index] }, $item;
                        }
                    }
                }
            }
            else {
                push @{ $new_words[$index] }, $item;
            }
        }
EOT
    }

    ### END this will never execute

    my (
        $new_words_ref,
        $new_words_komma_adverbial_ref,
        $clauses_with_relative_sentences_ref,
    ) = dividerparser( words => \@new_words_array );

    @new_words_komma_adverbial       = @$new_words_komma_adverbial_ref;
    @new_words                       = @$new_words_ref;
    @clauses_with_relative_sentences = @$clauses_with_relative_sentences_ref;

    foreach my $ind ( 0 .. @new_words_komma_adverbial ) {
        next if !$new_words_komma_adverbial[$ind];
        if ( @{ $new_words_komma_adverbial[$ind] } ) {
            push @{ $new_words[$index] },
              [
                'nothing',
                $data->{const}{NOUN},
                '('
                  . (
                    join '_',
                    (
                        map { ref($_) eq 'ARRAY' && $_->[0] ? $_->[0] : () }
                          @{ $new_words_komma_adverbial[$ind] }
                    )
                  )
                  . ')'
              ];
        }
    }

    my @questionwords = ();
    my @clauses       = ();
    foreach my $list_item (@new_words) {
        my @clause = @$list_item;
        my ( $clause_ref, $descr, $questionword ) =
          remove_questionword_and_description( $CLIENT_ref, @$list_item );
        if ($clause_ref) {
            @clause = @$clause_ref;
        }

        say(    'clause: '
              . ( join "--", ( map { join ',', @$_ } @clause ) ) . ", "
              . $descr . ", "
              . $questionword );

        my @real_clauses =
          ( [ [ $questionword, $data->{const}{QUESTIONWORD}, $descr ] ] );
        my $index              = 0;
        my @items_already_over = ();
        while ( my $item = shift @clause ) {
            last if !$item;
            next if !@$item;

            say 'got: ', join( ', ', @$item );

            #			last if scalar @$item != 3;
            push @items_already_over, $item;
            my ( $word, $type, $adv ) = @$item;

            if (   $item->[1] != $data->{const}{QUESTIONWORD}
                && @clause > 2
                && ( $clause[1][1] || 0 ) == $data->{const}{VERB}
                && ( $clause[0][1] || 0 ) == $data->{const}{ADJ} )
            {

                my $no1 = shift @clause;
                my $no2 = shift @clause;
                unshift @clause, $no1;
                unshift @clause, $no2;
            }
            if (   $item->[1] != $data->{const}{QUESTIONWORD}
                && @clause > 2
                && ( $clause[1][1] || 0 ) == $data->{const}{VERB}
                && ( $clause[0][0] || q{} ) eq 'nothing'
                && $items_already_over[-1][2] )
            {

                # sonst falsche reihenfolge:
                # z.B. von fischen zum schutz
                # statt: zum schutz von fischen
                if ( $clause[0][2] =~ /zu[mr]_/ ) {
                    $real_clauses[$index][-1][2] =
                      $clause[0][2] . ' ' . $real_clauses[$index][-1][2];
                    $real_clauses[$index][-1][2] =~ s/\s+/ /gm;
                }
                else {
                    $real_clauses[$index][-1][2] .= ' ' . $clause[0][2];
                    $real_clauses[$index][-1][2] =~ s/\s+/ /gm;
                }
                shift @clause;
            }

# causes problems when: Zonen zum Schutz von Fischen bewahren die Korallen nicht vor der gefuerchteten Bleiche

            #elsif (   $item->[1] != $data->{const}{QUESTIONWORD}
            #&& @clause > 2
            #&& ($clause[1][1]||0) == $data->{const}{VERB}
            #&& ($clause[0][0]||q{}) eq 'nothing' ) {

            #my $no1 = shift @clause;
            #my $no2 = shift @clause;
            #unshift @clause, [$no1->[2], $data->{const}{ADJ}, ''];
            #unshift @clause, $no2;
            #}

            my $next_relevant_word_is_verb = 0;
            if (@clause) {
                if ( ( $clause[0][1] || 0 ) == $data->{const}{VERB} ) {
                    $next_relevant_word_is_verb = 1;
                }
            }

            if (   $item->[1] != $data->{const}{QUESTIONWORD}
                && @items_already_over >= 3
                && ( $items_already_over[-3][1] || 0 ) == $data->{const}{VERB}
                && ( $items_already_over[-2][1] || 0 ) == $data->{const}{ADJ} )
            {

                my $no1 = pop @items_already_over;
                my $no2 = pop @items_already_over;
                my $no3 = pop @items_already_over;
                push @items_already_over, $no2;
                push @items_already_over, $no3;
                push @items_already_over, $no1;
            }
            if (   $item->[1] != $data->{const}{QUESTIONWORD}
                && @items_already_over >= 3
                && ( $items_already_over[-3][1] || 0 ) == $data->{const}{VERB}
                && ( $items_already_over[-2][0] || q{} ) eq 'nothing' )
            {

                my $no1 = pop @items_already_over;
                my $no2 = pop @items_already_over;
                my $no3 = pop @items_already_over;
                push @items_already_over,
                  [ $no2->[2], $data->{const}{ADJ}, '' ];
                push @items_already_over, $no3;
                push @items_already_over, $no1;
            }
            if (   $item->[1] != $data->{const}{QUESTIONWORD}
                && @{ $real_clauses[$index] } >= 2
                && ( $real_clauses[$index][-2][1] || 0 ) == $data->{const}{VERB}
                && ( $real_clauses[$index][-1][0] || q{} ) eq 'nothing' )
            {

                my $no2 = pop @{ $real_clauses[$index] };
                my $no3 = pop @{ $real_clauses[$index] };
                push @{ $real_clauses[$index] },
                  [ 'nothing', $data->{const}{ADJ}, $no2->[2] ];
                push @{ $real_clauses[$index] }, $no3;
            }
            if (   $item->[1] != $data->{const}{QUESTIONWORD}
                && @{ $real_clauses[$index] } >= 3
                && ( $real_clauses[$index][-3][1] || 0 ) == $data->{const}{VERB}
                && ( $real_clauses[$index][-2][0] || q{} ) eq 'nothing' )
            {

                my $no1 = pop @{ $real_clauses[$index] };
                my $no2 = pop @{ $real_clauses[$index] };
                my $no3 = pop @{ $real_clauses[$index] };
                push @{ $real_clauses[$index] },
                  [ 'nothing', $data->{const}{ADJ}, $no2->[2] ];
                push @{ $real_clauses[$index] }, $no3;
                push @{ $real_clauses[$index] }, $no1;
            }

            my $last_relevant_word_is_verb = 0;
            if ( @items_already_over >= 2 ) {
                if ( @items_already_over > 3
                    && ( $items_already_over[-2][1] || 0 ) ==
                    $data->{const}{VERB} )
                {
                    $last_relevant_word_is_verb = 1;
                }
            }

            my $there_is_a_verb_before_a_linking_word_after  = 0;
            my $there_is_a_verb_before_a_linking_word_before = 0;

          AFTER:
            foreach my $item_next (@clause) {
                my ( $word_next, $type_next, $adv_next ) = @$item_next;
                last if !$type_next;
                if ( $data->{lang}{is_linking}{ lc $word_next } ) {
                    last AFTER;
                }
                elsif ( $type_next == $data->{const}{VERB} ) {
                    $there_is_a_verb_before_a_linking_word_after = 1;
                    last AFTER;
                }
            }

            my @missing_subject = ();
          BEFORE:
            foreach my $item_next (
                ( reverse @items_already_over )[ 1 .. $#items_already_over ] )
            {
                my ( $word_next, $type_next, $adv_next ) = @$item_next;

                #				print "report-2: ", $word_next, ",,", $type_next, ",,",
                #				  $adv_next, "\n";
                if ( $data->{lang}{is_linking}{ lc $word_next }
                    && !$there_is_a_verb_before_a_linking_word_before )
                {
                    last BEFORE;
                }
                last if !$type_next;
                if ( ( $type_next || 0 ) == $data->{const}{VERB} ) {
                    $there_is_a_verb_before_a_linking_word_before += 1;
                }
                elsif ( $there_is_a_verb_before_a_linking_word_before == 1 ) {
                    if ( $data->{lang}{is_linking}{ lc $word_next } ) {
                        if ( scalar @missing_subject == 0 ) {
                            next BEFORE;
                        }
                    }
                    push @missing_subject, $item_next;
                }
                elsif ($there_is_a_verb_before_a_linking_word_before) {
                    last BEFORE;
                }
            }

#			say(
#				'Report:',
#				lc $word,
#				'||',
#				( $data->{lang}{is_linking}{ lc $word } ? $data->{lang}{is_linking}{ lc $word } : '0' ),
#				'||',
#				$next_relevant_word_is_verb,
#				'||',
#				$last_relevant_word_is_verb,
#				'||',
#				$there_is_a_verb_before_a_linking_word_after,
#				'||',
#				$there_is_a_verb_before_a_linking_word_before,
#			);

            say '$there_is_a_verb_before_a_linking_word_after:  ',
              $there_is_a_verb_before_a_linking_word_after
              if $data->{lang}{is_linking}{ lc $word };
            say '$there_is_a_verb_before_a_linking_word_before: ',
              $there_is_a_verb_before_a_linking_word_before
              if $data->{lang}{is_linking}{ lc $word };
            say Dumper 'reverse @items_already_over: ',
              [ reverse @items_already_over ]
              if !$there_is_a_verb_before_a_linking_word_before
                  && $there_is_a_verb_before_a_linking_word_after
                  && $data->{lang}{is_linking}{ lc $word };

            if (
                   $data->{lang}{is_linking}{ lc $word }
                && !$data->{lang}{is_linking_but_not_divide}{ lc $word }
                && (   $next_relevant_word_is_verb
                    || $last_relevant_word_is_verb )
                && $there_is_a_verb_before_a_linking_word_after
                && $there_is_a_verb_before_a_linking_word_before
              )
            {
                say( 'Clearing @real_clauses:',
                    ( scalar @{ $real_clauses[$index] } ) );
                if ($next_relevant_word_is_verb) {
                    @missing_subject = reverse @missing_subject;
                    say( 'Missing subject words:',
                        join ", ", map { ${$_}[0] } @missing_subject );

                    my $this_item = shift @items_already_over;

                    #					unshift @items_already_over, @missing_subject;
                    #					unshift @items_already_over, $this_item;
                    push @real_clauses, \@missing_subject;
                }
                else {
                    say('No missing subjects needed.');
                    push @real_clauses, [];
                }

                print Dumper $real_clauses[$index]->[-1];
                print Dumper $clause[0];

                if (   $real_clauses[$index]->[-2]->[1] == $data->{const}{ADJ}
                    && $clause[1][1] == $data->{const}{ADJ} )
                {

                    say 'there are adjectives left and right.';

                    if ($next_relevant_word_is_verb) {
                        pop @{ $real_clauses[$index] };
                    }

                    my @verbs_to_add_to__real_clauses = ();

                  ITEM_OF_CLAUSE:
                    foreach my $item_of_clause (@clause) {
                        if ( $item_of_clause->[1] == $data->{const}{VERB} ) {
                            push @verbs_to_add_to__real_clauses,
                              $item_of_clause;
                        }
                        if ( $item_of_clause->[1] == $data->{const}{KOMMA} ) {
                            last ITEM_OF_CLAUSE;
                        }
                    }

                    my @verbs_to_add_to__clause = ();

                  ITEM_OF_CLAUSE:
                    foreach my $item_of_clause (@real_clauses) {
                        if ( $item_of_clause->[1] == $data->{const}{VERB} ) {
                            push @verbs_to_add_to__clause, $item_of_clause;
                        }
                        if ( $item_of_clause->[1] == $data->{const}{KOMMA} ) {
                            last ITEM_OF_CLAUSE;
                        }
                    }

                    push @{ $real_clauses[$index] },
                      @verbs_to_add_to__real_clauses;
                    $real_clauses[ $index + 1 ] ||= [];
                    push @{ $real_clauses[ $index + 1 ] },
                      @verbs_to_add_to__clause;
                }

                $index += 1;
            }
            else {
                push @{ $real_clauses[$index] }, $item;
            }
        }

        my @clauses_new = ();
        foreach my $subclauses (@clauses) {
            say 'loop (1)';

            #foreach my $arr_clause1 (@$subclauses) {
            #	my @arr_2 = @$arr_clause1;
            #	my @arr   = @arr_2;
            #}

            say 'scalar @real_clauses: ', scalar @real_clauses;
            foreach my $arr_clause2 (@real_clauses) {
                push @clauses_new, [ @$subclauses, $arr_clause2 ];
                say('1 push @clauses_new');

                #, [ ',
                #	$arr_clause1, ', ', $arr_clause2, ' ];' );
            }
            if ( not @$subclauses ) {
                foreach my $arr_clause2 (@real_clauses) {
                    push @clauses_new, [ $arr_clause2, ];
                    say( '2 push @clauses_new, [',
                        ( map { join "," } $arr_clause2 ), '];' );
                }
            }
        }
        if ( not @clauses ) {
            foreach my $arr_clause2 (@real_clauses) {
                push @clauses_new, [ $arr_clause2, ];
                say( '3 push @clauses_new, [',
                    ( map { join "," } $arr_clause2 ), '];' );
            }
        }
        @clauses = @clauses_new;

        say "CLAUSES:";
        say Dumper \@clauses;
    }
    say( "Clauses (1): ", scalar @clauses );
    push @clauses, map {
        map { [$_] }
          @$_
    } @clauses_with_relative_sentences;
    say( "Clauses (2): ", scalar @clauses );

    my @sentences = ();
    foreach my $sentence (@clauses) {
        say("Sentence:");
        my @hashs_subclauses = ();

        foreach my $clause_ref (@$sentence) {
            my $questionword                = q{};                     # empty
            my $descr                       = q{};                     # empty
            my @subjects                    = ( [ 'nothing', '' ] );
            my @objects                     = ( [ 'nothing', '' ] );
            my $obj_has_been_added_to_array = 0;
            my $index_subj                  = 0;
            my $index_obj                   = 0;
            my @verbs                       = ();
            my $in_object                   = 0;
            my $added_subject               = 0;
            say(    "  Subclause: "
                  . array_to_string($clause_ref) . "->"
                  . @$clause_ref );
            my $i = -1;

            my $verb_is_first_or_last_word = 0;
            my $already_passed_verb        = 0;
            if ( $clause_ref->[0]->[1] == $data->{const}{VERB} ) {
                $verb_is_first_or_last_word = 1;
            }
            if (   $clause_ref->[0]->[1] == $data->{const}{QUESTIONWORD}
                && $clause_ref->[1]->[1] == $data->{const}{VERB} )
            {
                $verb_is_first_or_last_word = 1;
            }
            if ( $clause_ref->[-1]->[1] == $data->{const}{VERB} ) {
                $clause_ref->[-1]->[2] =~ s/nothing//igm;
                $clause_ref->[-1]->[2] =~ s/^\s+//igm;
                $clause_ref->[-1]->[2] =~ s/\s+$//igm;
                $verb_is_first_or_last_word = 1
                  if !$clause_ref->[-1]->[2];
            }
            my @temp_array = @$clause_ref;
            while ( my $item_ref = shift @temp_array ) {
                if (   $item_ref->[1] != $data->{const}{VERB}
                    && $item_ref->[1] != $data->{const}{QUESTIONWORD} )
                {
                    unshift @temp_array, $item_ref;
                    last;
                }
            }
            while ( my $item_ref = pop @temp_array ) {
                if ( $item_ref->[1] != $data->{const}{VERB} ) {
                    push @temp_array, $item_ref;
                    last;
                }
            }
            foreach my $item_ref (@temp_array) {
                if ( $item_ref->[1] == $data->{const}{VERB} ) {
                    $verb_is_first_or_last_word = 0;
                }
            }

            say '$verb_is_first_or_last_word: ', $verb_is_first_or_last_word;

            my $k = -1;
            foreach my $item (@$clause_ref) {
                $k += 1;
                $i += 1;
                chomp $item->[1];
                say;
                say;
                print "    Item: " . $item . "->" . @$item . "\n";
                next if not $item;
                next if not @$item;
                next if not scalar @$item == 3;
                my ( $word, $type, $adv ) = @$item;
                say(    "    "
                      . ( $in_object ? "object: " : "subject: " )
                      . $word . "|"
                      . $adv . "|"
                      . $type );
                chomp $type;
                next if !$word && !$type;

                say;
                say join ', ', @$item;
                say 'index_obj: ', $index_obj;
                say 'in_object: ', $in_object;

                if ( LANGUAGE() eq 'de' ) {
                    my $g =
                      $clause_ref->[ $k + 1 ]->[1] == $data->{const}{NOUN}
                      ? (
                        pos_prop( $CLIENT_ref, $clause_ref->[ $k + 1 ]->[0] ) )
                      ->{'genus'}
                      : undef;

                    if ( $type == $data->{const}{ART} && $g =~ /m$/ ) {
                        if (   lc $word ne "der"
                            && lc $word ne "den"
                            && lc $word ne "ein"
                            && lc $word ne "einen"
                            && lc $word ne "mein"
                            && lc $word ne "dein"
                            && lc $word ne "sein"
                            && lc $word ne "unser"
                            && lc $word ne "euer"
                            && lc $word ne "ihr"
                            && lc $word ne "eine"
                            && lc $word !~ /n$/ )
                        {
                            $in_object = 0;
                        }
                    }
                    elsif ( $type == $data->{const}{ART} && $g =~ /f$/ ) {
                        if (   lc $word ne "die"
                            && lc $word ne "eine"
                            && lc $word ne "einer"
                            && lc $word ne "einen"
                            && lc $word ne "ein"
                            && lc $word ne "meine"
                            && lc $word ne "meiner"
                            && lc $word ne "meinen"
                            && lc $word ne "deine"
                            && lc $word ne "deiner"
                            && lc $word ne "deinen"
                            && lc $word ne "seine"
                            && lc $word ne "seiner"
                            && lc $word ne "unsere"
                            && lc $word ne "unserer"
                            && lc $word ne "unserer"
                            && lc $word ne "euere"
                            && lc $word ne "eurer"
                            && lc $word ne "euerer"
                            && lc $word ne "euere"
                            && lc $word ne "ihre"
                            && lc $word ne "eine"
                            && lc $word ne "ihrer"
                            && lc $word !~ /en$/
                            && lc $word !~ /ein$/
                            && lc $word !~ /er$/ )
                        {
                            $in_object = 0;
                        }
                    }
                    elsif ( $type == $data->{const}{ART} && $g =~ /s$/ ) {
                        if (   lc $word ne "das"
                            && lc $word ne "ein"
                            && lc $word ne "mein"
                            && lc $word ne "dein"
                            && lc $word ne "sein"
                            && lc $word ne "unser"
                            && lc $word ne "euer"
                            && lc $word ne "ihr"
                            && lc $word ne "eine" )
                        {
                            $in_object = 0;
                        }
                    }
                    elsif (
                        $type == $data->{const}{ART}
                        && (   $word eq "des"
                            || $word =~ /es$/ )
                      )
                    {
                        $in_object = 0;
                    }
                }

                say 'in_object:           ', $in_object;
                say 'already_passed_verb: ', $already_passed_verb;

                my $next_word_is_participle = 0;

                my ( $word_next, $type_next, $adv_next ) =
                  ( $clause_ref->[ $i + 1 ] )
                  ? @{ $clause_ref->[ $i + 1 ] }
                  : ( '', 0, '' );

                if ( $type_next == $data->{const}{ADJ}
                    && ( $word_next =~ /(end)|(ende)|(enden)|(endes)|(ender)$/ )
                  )
                {
                    $next_word_is_participle = 1;
                }

                if ( $data->{lang}{is_linking}{$word}
                    && !$data->{lang}{is_linking_but_not_divide}{$word} )
                {
                    $in_object                   -= 1;
                    $obj_has_been_added_to_array -= 1;

                    if ($in_object) {
                        $index_obj -= 1 if $index_obj > -1;
                        $objects[$index_obj][0] .= ' ' . $word;
                        $objects[$index_obj][1] .= ' ' . $adv;
                        $objects[$index_obj][0] =~ s/(^\s*|\s*$)//gm;
                        $objects[$index_obj][1] =~ s/(^\s*|\s*$)//gm;

                        # Auskommentiert: fuer und, oder kein neues
                        # Subjekt/Objekt registrieren, sondern anhaengen

                        # automatisch eins dazu
                        #						$index_obj = scalar @objects;
                    }

                    else {
                        $index_subj -= 1 if $index_subj > -1;
                        while ( $index_subj < 0 ) {
                            unshift @subjects, [];
                            $index_subj += 1;
                        }
                        $subjects[$index_subj][0] .= ' ' . $word;
                        $subjects[$index_subj][1] .= ' ' . $adv;
                        $subjects[$index_subj][0] =~ s/(^\s*|\s*$)//gm;
                        $subjects[$index_subj][1] =~ s/(^\s*|\s*$)//gm;

                        # Auskommentiert: fuer und, oder kein neues
                        # Subjekt/Objekt registrieren, sondern anhaengen

                        #						$index_subj += 1;
                        #						$subjects[$index_subj] = [ '', '' ];
                    }

                }

                #                elsif ( $word eq 'zu' ) {
                #                   $questionword = 'XXtoXX';
                #              }
                elsif ( $type == $data->{const}{QUESTIONWORD} ) {
                    $questionword = $item->[0];
                    $descr .= $item->[2];
                    $descr =~ s/^\s+//igm;
                    $descr =~ s/\s+$//igm;
                    $in_object -= 1;
                }
                elsif ( $type == $data->{const}{VERB} ) {    # verb
                    $already_passed_verb += 1;
                    push @verbs, $word;

                    if ( $word =~ /^(.+?)zu/ ) {
                        $word =~ s/^(.+?)zu/$1/igm;
                        $questionword = 'XXtoXX';
                    }

                    if ( !$verb_is_first_or_last_word ) {
                        $in_object += 1;
                    }

                    if ( $i + 1 < scalar @$clause_ref ) {
                        $clause_ref->[ $i + 1 ]->[2] =
                          $adv . ' ' . $clause_ref->[ $i + 1 ]->[2];
                        chomp $clause_ref->[ $i + 1 ]->[2];
                    }
                    else {
                        if ($obj_has_been_added_to_array) {
                            $in_object += 1;
                            $index_obj += 1;
                            $objects[$index_obj] = [ 'nothing', '' ]
                              if not $objects[$index_obj];
                        }

                        $objects[$index_obj][0] .= ' ';
                        $objects[$index_obj][1] .= ' ' . $adv;
                        $objects[$index_obj][0] =~ s/(^\s*|\s*$)//gm;
                        $objects[$index_obj][1] =~ s/(^\s*|\s*$)//gm;
                        $obj_has_been_added_to_array = 1;
                    }
                }

                elsif ($in_object >= 0
                    && ( $already_passed_verb || $verb_is_first_or_last_word )
                    && $added_subject
                    && $type != $data->{const}{QUESTIONWORD}
                    && $type != $data->{const}{VERB} )
                {    # object
                    say '#object';
                    if ( $word || $adv ) {
                        $objects[$index_obj][0] .= ' ' . $word;
                        $objects[$index_obj][1] .= ' ' . $adv;
                        $objects[$index_obj][0] =~ s/(^\s*|\s*$)//gm;
                        $objects[$index_obj][1] =~ s/(^\s*|\s*$)//gm;
                        $obj_has_been_added_to_array = 1;
                    }
                }

                else {    # subject
                    say '#subject';
                    $subjects[$index_subj][0] .= ' ' . $word;
                    $subjects[$index_subj][1] .= ' ' . $adv;
                    $subjects[$index_subj][0] =~ s/(^\s*|\s*$)//gm;
                    $subjects[$index_subj][1] =~ s/(^\s*|\s*$)//gm;

                    if (   !$verb_is_first_or_last_word
                        && !$already_passed_verb )
                    {
                        open my $FIRST_NAMES, '>>',
                            $data->{intern}{dir} . "lang_"
                          . LANGUAGE()
                          . "/wsh/names.wsh";
                        print $FIRST_NAMES $subjects[$index_subj][0] . "\n";
                        close $FIRST_NAMES;

                        my $fn = $subjects[$index_subj][0];
                        $fn =~ s/[_]/ /igm;
                        $fn =~ s/(^|\s|[;])nothing(\s|_|[;]|$)//igm;
                        $fn =~ s/nothing\s//igm;

                        $fn =~ s/[mds]ein\s//igm;
                        $data->{lang}{is_a_name}{$fn} = 1;

                    }
                    $added_subject = 1;

                    if (
                        !(
                            (
                                   $type == $data->{const}{NOUN}
                                || $type != $data->{const}{ADJ}
                                || $type != $data->{const}{ART}
                            )
                            && !$next_word_is_participle
                        )
                      )
                    {
                        $in_object = 0;
                    }
                }

                if (
                    (
                        ( $type == $data->{const}{NOUN} )

                        #&& !$next_word_is_participle
                    )
                  )
                {

                    if ( $in_object == 0 ) {
                        $index_obj = 0;
                    }
                    $in_object += 1;
                    $index_obj += 1;
                    $objects[$index_obj] = [ 'nothing', '' ]
                      if !$objects[$index_obj];
                }

                next if !@subjects && !@objects;
            }

            #			if (not $obj_has_been_added_to_array) {
            #				push @objects, [ 'nothing', '' ];
            #			}

            $descr =~ s/[;]//gm;

            push @hashs_subclauses,
              {
                "questionword" => $questionword,
                "description"  => $descr,
                "subjects"     => \@subjects,
                "objects"      => \@objects,
                "verbs"        => \@verbs,
              };
            say( "    question word: " . $questionword ) if $questionword;
            say( "    description:   " . $descr )        if $descr;
        }
        push @sentences, \@hashs_subclauses;
    }

    foreach my $sent_ref (@sentences) {
        @$sent_ref = (
            ( grep { not $_->{'questionword'} } @$sent_ref ),
            ( grep { $_->{'questionword'} } @$sent_ref )
        );

        foreach my $subclause_ref (@$sent_ref) {
            $subclause_ref = remove_advs_to_list( $CLIENT_ref, $subclause_ref );
        }
    }

    print Dumper \@sentences;

    return ( \@sentences, $data->{lang}{is_a_question} );
}

sub dividerparser {
    ### BEGIN this will never execute

    if (0) {
        my $temp = << 'EOT';
        my $index                     = 0;
        my $word_count = -1;
        while ( my $item = shift @new_words_array ) {
            my ${is_komma}= ( ( $item->[0] ) =~ /KOMMA/i );
            $word_count += 1;

            if ($is_komma) {
                if (   $new_words[$index]->[-1]
                    && $new_words_array[0]->[1] == $data->{const}{ADJ}
                    && $new_words[$index]->[-1]->[1] == $data->{const}{ADJ} )
                {
                    my $next_item = shift @new_words_array;
                    $new_words[$index]->[-1]->[0] .= ',_' . $next_item->[0];
                    $new_words[$index]->[-1]->[2] .= ' ' . $next_item->[2]
                      if $next_item->[2];
                    chomp $new_words[$index]->[-1]->[2];
                    next;
                }
            }

            if ( $data->{lang}{is_komma}|| $word_count == 0 ) {
                say "ITEM:", ( join ', ', @$item );

                my @rest_of_sentence = ();

                while ( defined( my $item = shift @new_words_array ) ) {
                    if ( $item->[1] == $data->{const}{QUESTIONWORD} && $item->[0] ne 'XXtoXX' ) {
                        push @rest_of_sentence, $item;

                        #					unshift @new_words_array, $item;
                        last;
                    }
                    if ( ( join ";", @$item ) =~ /KOMMA/i ) {
                        unshift @new_words_array, $item;
                        last;
                    }
                    push @rest_of_sentence, $item;
                }

                my $already_done_unshift = 0;

                my @count_of_verbs = grep { $_->[1] == $data->{const}{VERB} } @rest_of_sentence;
                if ( !@count_of_verbs || $word_count == 0 ) {
                    unshift @new_words_array, @rest_of_sentence;
                    $already_done_unshift = 1;

                    #				unshift @new_words_array, $article;
                }

                say '$data->{lang}{is_article_for_subject}{ $rest_of_sentence[0]->[1] }: ',
                  $data->{lang}{is_article_for_subject}{ $rest_of_sentence[0]->[0] };
                say '$rest_of_sentence[0]->[1]:                            ',
                  $rest_of_sentence[0]->[1];
                say '$is_komma:                                            ',
                  $is_komma;
                say '$index >= 0:                                          ',
                  $index >= 0;
                say '\$rest_of_sentence: ', Dumper \@rest_of_sentence;

                if (
                    $data->{lang}{is_komma}                    && (   $data->{lang}{is_article_for_subject}{ $rest_of_sentence[0]->[0] }
                        || $data->{lang}{is_article_for_object}{ $rest_of_sentence[0]->[0] } )
                    && $index >= 0
                    && @count_of_verbs
                  )
                {
                    my $article = shift @rest_of_sentence;

                    my @as_subj = ();
                    my @as_obj  = ();

                    if ( $data->{lang}{is_article_for_subject}{ $article->[0] } ) {
                        @as_subj = left_until_article_or_other_noun_end(
                            @{ $new_words[$index] } );
                    }

                    if ( $data->{lang}{is_article_for_object}{ $article->[0] } ) {
                        @as_obj = left_until_article_or_other_noun_end(
                            @{ $new_words[$index] } );
                    }

                    if (@count_of_verbs) {
                        push @clauses_with_relative_sentences,
                          [ [ @as_subj, @rest_of_sentence, @as_obj, ] ];
                        print Dumper [ @as_subj, @rest_of_sentence, @as_obj, ];
                    }
                    shift @new_words_array;
                }
                elsif (
                       $data->{lang}{is_komma}                    && $rest_of_sentence[0]->[1] == $data->{const}{PREP}
                    && (   $data->{lang}{is_article_for_subject}{ $rest_of_sentence[1]->[0] }
                        || $data->{lang}{is_article_for_object}{ $rest_of_sentence[1]->[0] } )
                    && $index >= 0
                    && @count_of_verbs
                  )
                {
                    my $data->{const}{PREP}    = shift @rest_of_sentence;
                    my $article = shift @rest_of_sentence;

                    my @as_subj = ();
                    my @as_obj  = ();

                    my @things = [
                        'nothing',
                        $data->{const}{NOUN},
                        $data->{const}{PREP}->[0]
                          . ( ( $data->{const}{PREP}->[2] ) ? ' ' : '' )
                          . $data->{const}{PREP}->[2] . ' '
                          . (
                            join ' ',
                            map { $_->[0] . ( $_->[2] ? ' ' : '' ) . $_->[2] }
                              left_until_article_or_other_noun_end(
                                @{ $new_words[$index] }
                              )
                          )
                    ];

                    if ( $data->{lang}{is_article_for_subject}{ $article->[0] } ) {
                        @as_subj = @things;
                    }

                    if ( $data->{lang}{is_article_for_object}{ $article->[0] } ) {
                        @as_obj = @things;
                    }

                    if (@count_of_verbs) {
                        push @clauses_with_relative_sentences,
                          [ [ @as_subj, @rest_of_sentence, @as_obj, ] ];
                    }
                    shift @new_words_array;
                }
                else {
                    print '@count_of_verbs: ', Dumper \@count_of_verbs;
                    say '$rest_of_sentence[0]->[1] == $data->{const}{QUESTIONWORD}: ',
                      $rest_of_sentence[0]->[1] == $data->{const}{QUESTIONWORD};

                    if (   @count_of_verbs
                        || $rest_of_sentence[0]->[1] == $data->{const}{QUESTIONWORD} )
                    {
                        if ( $word_count > 0 ) {
                            unshift @new_words_array, @rest_of_sentence
                              if !$already_done_unshift;

                            # begin a new komma subclause
                            print 'Clearing @tmp:'
                              . ( @{ $new_words[$index] } ) . "\n";
                            push @new_words,                 [];
                            push @new_words_komma_adverbial, [];
                            $index += 1;
                        }
                        if ( $word_count == 0 ) {
                            push @{ $new_words[$index] }, $item;
                        }
                    }

                    else {
                        if ( $word_count > 0 ) {
                            my $adverbial_string = join ' ',
                              map { $_->[0] . ' ' . $_->[2] } @rest_of_sentence;
                            $adverbial_string =~ s/\s+/ /igm;
                            $adverbial_string =~ s/(\s+$)|(^\s+)//igm;
                            $adverbial_string =~ s/\s/_/igm;

                            #					$adverbial_string = '(' . $adverbial_string . ')';
                            #					push @{ $new_words[$index] },
                            #						[ $adverbial_string, $data->{const}{ADJ}, q{} ];
                            $new_words_komma_adverbial[$index] = []
                              if !( $new_words_komma_adverbial[$index] );
                            push @{ $new_words_komma_adverbial[$index] },
                              $adverbial_string;

                            while ( my $item = shift @new_words_array ) {
                                if ( ( join ";", @$item ) =~ /KOMMA/i ) {
                                    last;
                                }
                                push @rest_of_sentence, $item;
                            }
                        }
                        else {

                            #						unshift @new_words_array, @rest_of_sentence;
                            push @{ $new_words[$index] }, $item;
                        }
                    }
                }
            }
            else {
                push @{ $new_words[$index] }, $item;
            }
        }
EOT
    }

    ### END this will never execute

    my %arg = ();
    %arg = ( %arg, @_ );

    return dividerparser_statement( words => $arg{words} );
}

sub get_rest_of_this_sentence {
    my @new_words_array  = @_;
    my @rest_of_sentence = ();

    while ( defined( my $item = shift @new_words_array ) ) {
        if (   $item->[1] == $data->{const}{QUESTIONWORD}
            && $item->[0] ne 'XXtoXX' )
        {
            push @rest_of_sentence, $item;
            last;
        }
        if ( ( join ";", @$item ) =~ /KOMMA/i ) {
            unshift @new_words_array, $item;
            last;
        }
        push @rest_of_sentence, $item;
    }

    return [ \@rest_of_sentence, \@new_words_array ];
}

sub get_count_of_verbs {
    my @count_of_verbs =
      grep { $_->[1] == $data->{const}{VERB} }
      @{ get_rest_of_this_sentence(@_)->[0] };
    return @count_of_verbs;
}

sub is_participle {
    return grep {
        say 'is participle ?: ', $_;
        my $regex = $data->{lang}{regex_str_verb_prefixes};
        m/^($regex).+?t$/
      }
      map { $_->[0] } @_;
}

sub check_for_relative_clause {
    my %arg = ();
    %arg = ( %arg, @_ );

    %{ $data->{lang}{is_article_for_subject} } =
      map { $_ => 1 } qw{der die das welcher welches welche who which that};

    %{ $data->{lang}{is_article_for_object} } =
      map { $_ => 1 } qw{den dem welchem welchen};

    my @adv_clauses = @{ $arg{adv_clauses} };
    my @clauses_with_relative_sentences =
      @{ $arg{clauses_with_relative_sentences} };

    say '$data->{lang}{is_article_for_subject}{ ', $arg{words}->[0]->[0], ' }:',
      $data->{lang}{is_article_for_subject}{ $arg{words}->[0]->[0] };

    if ( $data->{lang}{is_article_for_subject}{ $arg{words}->[0]->[0] } ) {

        shift @{ $arg{words} };

        my ( $adv_clauses_ref, $clauses_with_relative_sentences_ref ) =
          dividerparser_relative_clause(
            %arg,
            words => $arg{words},
            subj  => left_until_article_or_other_noun_end( @{ $arg{clauses} } ),
            clauses => [ @{ $arg{clauses} } ],
          );
        push @adv_clauses, $adv_clauses_ref;
        push @clauses_with_relative_sentences,
          @{$clauses_with_relative_sentences_ref};
    }

    elsif ( $data->{lang}{is_article_for_object}{ $arg{words}->[0]->[0] } ) {

        shift @{ $arg{words} };

        my ( $adv_clauses_ref, $clauses_with_relative_sentences_ref ) =
          dividerparser_relative_clause(
            %arg,
            words => $arg{words},
            obj   => left_until_article_or_other_noun_end( @{ $arg{clauses} } ),
            clauses => [ @{ $arg{clauses} } ],
          );
        push @adv_clauses, $adv_clauses_ref;
        push @clauses_with_relative_sentences,
          @{$clauses_with_relative_sentences_ref};
    }
    else {
        return;
    }

    if (@clauses_with_relative_sentences) {
        my $count_of_verbs =
          get_count_of_verbs( @{ $clauses_with_relative_sentences[-1] } );
        say '$count_of_verbs: ', $count_of_verbs;
        say '... for: ',         Dumper $clauses_with_relative_sentences[-1];

        if ( !$count_of_verbs ) {
            ( my $rest_ref, $arg{words} ) = get_rest_of_this_sentence(
                @{ $clauses_with_relative_sentences[-1] } );
            my $adverbial_string = join ' ',
              map { $_->[0] . ' ' . $_->[2] } @$rest_ref;
            $adverbial_string =~ s/\s+/ /igm;
            $adverbial_string =~ s/(\s+$)|(^\s+)//igm;
            $adverbial_string =~ s/\s/_/igm;

            push @adv_clauses, [$adverbial_string];

            pop @clauses_with_relative_sentences;
        }
    }

    return ( \@adv_clauses, \@clauses_with_relative_sentences );
}

sub dividerparser_statement {
    my %arg = ();
    %arg = ( %arg, @_ );

    my @clauses                         = ( [] );
    my @adv_clauses                     = ();
    my @clauses_with_relative_sentences = ();

    while ( my $item = $arg{words}->[0] ) {

        # word is komma
        if ( $item->[0] =~ /komma/i ) {

            my $komma = shift @{ $arg{words} };

            my ( $adv_clauses_ref, $clauses_with_relative_sentences_ref ) =
              check_for_relative_clause(
                words => $arg{words},
                clauses_with_relative_sentences =>
                  \@clauses_with_relative_sentences,
                adv_clauses => \@adv_clauses,
                clauses     => [ @{ $clauses[-1] } ]
              );

            if ($adv_clauses_ref) {
                @adv_clauses = @$adv_clauses_ref;
                push @clauses_with_relative_sentences,
                  $clauses_with_relative_sentences_ref;
            }
            else {
                push @clauses, [];
            }

            #if (    @{ $arg{words} } >= 1
            #     && $arg{words}->[0]->[0] =~ /komma/i ) {
            #
            #    shift @{ $arg{words} };
            #}

        }

        # word is a normal word
        else {

            shift @{ $arg{words} };
            push @{ $clauses[-1] }, $item;
        }
    }

    return ( \@clauses, \@adv_clauses, \@clauses_with_relative_sentences );
}

sub dividerparser_relative_clause {
    my %arg = ( words => [], subj => [], obj => [] );
    %arg = ( %arg, @_ );

    my @adv_clauses = @{ $arg{adv_clauses} };
    my @clauses_with_relative_sentences =
      @{ $arg{clauses_with_relative_sentences} };
    push @clauses_with_relative_sentences, [];

    my @clauses = ( [] );

    say 'dividerparser_relative_clause operates on:';
    say '... ', Dumper $arg{words};

  WORD:
    while ( my $item = $arg{words}->[0] ) {

        # word is komma
        if ( $item->[0] =~ /komma/i ) {

            my $komma = shift @{ $arg{words} };

            my ( $adv_clauses_ref, $clauses_with_relative_sentences_ref ) =
              check_for_relative_clause(
                words => $arg{words},
                clauses_with_relative_sentences =>
                  \@clauses_with_relative_sentences,
                adv_clauses => \@adv_clauses,
                clauses     => [ @{ $clauses[-1] } ],    # [@{ $arg{clauses} }]
              );

            if ($adv_clauses_ref) {
                @adv_clauses = @$adv_clauses_ref;
                @clauses_with_relative_sentences =
                  @$clauses_with_relative_sentences_ref;

                if (   @{ $arg{words} } >= 3
                    && $arg{words}->[0]->[1] == $data->{const}{VERB}
                    && $arg{words}->[1]->[0] =~ /komma/i )
                {

                    #shift @{ $arg{words} };
                    push @{ $clauses[-1] }, shift @{ $arg{words} };

                    #shift @{ $arg{words} };

                }
            }
            else {
                push @clauses, [];
            }

            while ( @{ $arg{words} } >= 1
                && $arg{words}->[0]->[0] =~ /komma/i )
            {

                shift @{ $arg{words} };
            }

            #unshift @{ $arg{words} }, $komma;

            last WORD;
        }

        # word is a normal word
        else {

            shift @{ $arg{words} };
            push @{ $clauses[-1] }, $item;
        }
    }

    if ( !@{ $arg{obj} } && @{ $arg{subj} } ) {

        # if there is a verb which is a participle
        if ( is_participle( get_count_of_verbs( @{ $clauses[-1] } ) ) ) {
            @{ $arg{obj} }  = @{ $arg{subj} };
            @{ $arg{subj} } = ();
        }
    }

    if ( @{ $clauses[-1] } ) {
        unshift @{ $clauses[-1] }, @{ $arg{subj} };
        push @{ $clauses[-1] }, @{ $arg{obj} };
    }
    elsif ( @clauses >= 2 && @{ $clauses[-2] } ) {
        unshift @{ $clauses[-2] }, @{ $arg{subj} };
        push @{ $clauses[-2] }, @{ $arg{obj} };
    }

    push @clauses_with_relative_sentences, @clauses;
    say
'@clauses_with_relative_sentences (return value of dividerparser_relative_clause):',
      Dumper \@clauses_with_relative_sentences;

    return ( \@adv_clauses, \@clauses_with_relative_sentences, );
}

sub left_until_article_or_other_noun_end {
    my @word_list = @_;

    my @noun = ();

    my $verb_is_first_or_last_word = 0;
    my $already_passed_verb        = 0;
    my $passed_nouns               = 0;
    my $have_seen_nouns            = 0;
    if ( $word_list[0]->[1] == $data->{const}{VERB} ) {
        $verb_is_first_or_last_word = 1;
    }
    if ( $word_list[-1]->[1] == $data->{const}{VERB} ) {
        $verb_is_first_or_last_word = 1;
    }
    my @temp_array = @word_list;
    while ( my $item_ref = shift @temp_array ) {
        if ( $item_ref->[1] != $data->{const}{VERB} ) {
            unshift @temp_array, $item_ref;
            last;
        }
    }
    while ( my $item_ref = pop @temp_array ) {
        if ( $item_ref->[1] != $data->{const}{VERB} ) {
            push @temp_array, $item_ref;
            last;
        }
    }
    foreach my $item_ref (@temp_array) {
        if ( $item_ref->[1] == $data->{const}{VERB} ) {
            $verb_is_first_or_last_word = 0;
        }
    }

    say '\@word_list:';
    print Dumper \@word_list;

    say '$verb_is_first_or_last_word: ', $verb_is_first_or_last_word;

    foreach my $item_ref ( reverse @word_list ) {
        if ( $item_ref->[1] == $data->{const}{NOUN} ) {
            $have_seen_nouns = 1
              if !$verb_is_first_or_last_word;
            if ( !$passed_nouns && $have_seen_nouns ) {
                push @noun, [@$item_ref];
            }
            else {
                last;
            }
        }
        elsif ( $item_ref->[1] == $data->{const}{ADJ} ) {
            push @noun, [@$item_ref];
            $passed_nouns = 1 if $have_seen_nouns;
        }
        elsif ( $item_ref->[1] == $data->{const}{ART} ) {
            push @noun, [@$item_ref];
            last;
        }
        else {
            last;
        }
    }

    return [ reverse @noun ];
}

sub array_to_string {
    my @array = @{ $_[0] };
    my $str   = '';

    $str .= '(';
    foreach my $key (@array) {
        $str .= q{'};
        $str .= $key;
        $str .= q{', };
    }
    $str .= ')';
    return $str;
}

sub hash_to_string {
    my %hash = %{ $_[0] };
    my $str  = '';

    $str .= '{';
    foreach my $key ( keys %hash ) {
        $str .= q{'};
        $str .= $key;
        $str .= q{' => '};
        $str .= $hash{$key};
        $str .= q{', };
    }
    $str .= '}';
    return $str;
}

=head2 is_name($name)

Checks whether $name is a name. A boolean will be returned.

=cut

sub is_name {
    my $name = lc shift;
    say "is_name: $name" if is_verbose || 1;
    $name =~ s/[_]/ /igm;
    chomp $name;

    say 'no name.' if is_verbose && $name =~ /^(es|ich|du|i|you)[\s|_]/i;
    return 0 if $name =~ /^(es|ich|du|i|you)[\s|_]/i;

    open my $NO_NAMES, '<',
      $data->{intern}{dir} . "lang_" . LANGUAGE() . "/wsh/no-names.wsh";
    while ( defined( my $fn = <$NO_NAMES> ) ) {
        $fn = lc $fn;
        chomp $fn;

        $fn =~ s/[_]/ /igm;
        $fn =~ s/(^|\s|[;])nothing(\s|_|[;]|$)//igm;
        $fn =~ s/nothing\s//igm;

        #		print "$fn eq $name\n";
        if ( $fn eq $name ) {
            print 'no name.', "\n" if is_verbose;
            return 0;
        }
    }
    close $NO_NAMES;

    $name =~ s/[mds]ein\s//igm;
    if ( $data->{lang}{is_a_name}{$name} ) {
        return 1;
    }

    return 1
      if $name =~ /mount\s+/i;

    print 'not found.', "\n" if is_verbose || 1;
    return 0;
}

sub is_name_or_noun_with_genitive_s {
    my ($word) = @_;

    $word = lc $word;
    $word =~ s/_/ /igm;
    $word =~ s/\s+/ /igm;
    $word =~ s/(^\s+)|(\s+$)//igm;
    $word =~ s/.$//;                 # no 'g', only once!

    %{ $data->{lang}{is_name_or_noun} } = map { $_ => 1 } @names_and_nouns;

    if ( $data->{lang}{is_name_or_noun}{$word} ) {
        say 'is name or noun: ', $word;
        return 1;
    }

    say 'no name or noun: ', $word;
    print join( ', ', sort @names_and_nouns );
    return 0;
}

sub remove_questionword_and_description {
    my $CLIENT_ref                           = shift;
    my @words_backup                         = @_;
    my @words                                = @words_backup;
    my $descr                                = q{};             # empty
    my $questionword                         = q{};             # empty
    my $already_seen_questionword            = 0;
    my $already_seen_noun_after_questionword = 0;

    while ( my $item = shift @words ) {
        my ( $word, $type, $adv ) = @$item;

        print( $word, '::', $type, '::', $adv );
        print "\n";

        if ( $data->{lang}{is_linking}{ lc $word } ) {
            $descr .= ' ' . $word . ' ' . $adv;
            chomp $descr;
        }
        elsif ($type == $data->{const}{NOUN}
            && !$already_seen_noun_after_questionword
            && $already_seen_questionword )
        {
            $descr .= ' ' . $word . ' ' . $adv;
            chomp $descr;
            last;
        }
        elsif ( $type == $data->{const}{VERB} ) {
            unshift @words, [ $word, $type, $adv ];
            last;
        }
        elsif ( $type == $data->{const}{QUESTIONWORD} ) {
            $word = lc $word;

            $adv = q{} if ( not $adv );

            $descr .= ' ' . $adv;
            chomp $descr;

            print( $word, '::', $type, '::', $adv, 'questionword',
                $data->{lang}{is_inacceptable_questionword}{$word},
                q{(}, scalar %{ $data->{lang}{is_inacceptable_questionword} },
                q{)} );
            print "\n";

            if ( $data->{lang}{is_inacceptable_questionword}{$word} ) {
                return;    # return ( \@words_backup, q{}, q{} )
            }

            $already_seen_questionword = 1;
            $questionword              = $word;
            chomp $questionword;

            $descr =~ s/^\s+//igm;
            $descr =~ s/\s+$//igm;

            if ( pos_of( $CLIENT_ref, lc $descr, 0, 0, 0, $descr ) ==
                $data->{const}{PREP} )
            {
                push @words, [ 'nothing', $data->{const}{NOUN}, $descr ];
                $descr = '';
            }

            if ( length($descr) ) {
                $already_seen_noun_after_questionword = 1;
                chomp $descr;

            #				@words = ( [ 'nothing', $data->{const}{NOUN}, $adv ], @words );

                last;
            }
        }
        else {
            $descr .= ' ' . $word . ' ' . $adv;
            chomp $descr;
        }
    }

    if ( not @words ) {
        return;    # return ( \@words_backup, q{}, q{} )
    }

    $descr        =~ s/^\s//gm;
    $descr        =~ s/\s$//gm;
    $questionword =~ s/^\s//gm;
    $questionword =~ s/\s$//gm;

    if ( not $questionword ) {
        return;
    }

    $descr =~ s/[;]//gm;

    return ( \@words, $descr, $questionword );
}

sub sort_linking {
    return sort {
        ( $a =~ /^([&]|und|oder|and|or)/ )
          <=> ( $b =~ /^([&]|und|oder|and|or)/ )
    } @_;
}

sub remove_advs_to_list {
    my ( $CLIENT_ref, $sentence_ref ) = @_;
    my @advs   = ();
    my $CLIENT = $$CLIENT_ref;

    say;
    say q{$sentence_ref->{'objects'}:}, Dumper @{ $sentence_ref->{'objects'} };

    # the subjects
    my @subjs = ();
    foreach my $_sub ( @{ $sentence_ref->{'subjects'} } ) {
        ( push @subjs, $_sub and next ) if not is_array($_sub);
        next if not( join '', @$_sub );

        ( $_sub, my $adv ) = @$_sub;

        #		$_sub =~ s/_/ /igm if $_sub !~ /^[_]/;
        $_sub =~ s/nothing//igm;
        $_sub =~ s/(^\s*|\s*$)//igm;
        $adv  =~ s/nothing//igm;
        $adv  =~ s/(^\s*|\s*$)//igm;
        $_sub = q{nothing} if not $_sub;
        $adv  = q{nothing} if not $adv;
        push @advs, $adv if $adv && $adv ne q{nothing};

        #		$_sub =~ s/einer /eine /igm;
        #		$_sub =~ s/einem /ein /igm;
        #		$_sub =~ s/einen /ein /igm;
        #		$_sub =~ s/eines /ein /igm;

        if ( $_sub =~ /(^|\s)(nicht)(\s|$)/i ) {
            push @advs, 'nicht';
            $_sub =~ s/(^|\s|[;])(nicht)(\s|$)/$1/igm;
        }

        if ( $_sub =~ /(^|\s)(not)(\s|$)/i ) {
            push @advs, 'not';
            $_sub =~ s/(^|\s|[;])(not)(\s|$)/$1/igm;
        }

        my @_sub_array = split /\s/, $_sub;
        push @advs,
          grep { $data->{lang}{is_adverb_of_time}{ lc $_ } } @_sub_array;
        $_sub = join ' ',
          grep { !$data->{lang}{is_adverb_of_time}{ lc $_ } } @_sub_array;

        #$_sub =~ s/^(.ein.?.?)\s/$1qq/igm;
        push @subjs, $_sub;
    }
    @{ $sentence_ref->{'subjects'} } = join ' ',
      sort_linking(@{ $sentence_ref->{'subjects'} });

    # the objects
    my @objs = ();
    foreach my $_obj ( @{ $sentence_ref->{'objects'} } ) {
        ( push @objs, $_obj and next ) if not is_array($_obj);
        next if ( not join '', @$_obj );

        ( $_obj, my $adv ) = @$_obj;

        say '(1) obj: ', $_obj, ' ; adv: ', $adv;

        #		$_obj =~ s/_/ /igm if $_obj =~ /^[_]/;
        $_obj =~ s/nothing//igm;
        $_obj =~ s/(^\s*|\s*$)//igm;
        $adv  =~ s/nothing//igm;
        $adv  =~ s/(^\s*|\s*$)//igm;
        $_obj = q{nothing} if not $_obj;
        $adv  = q{nothing} if not $adv;
        push @advs, $adv if $adv && $adv ne q{nothing};

        say '(2) obj: ', $_obj, ' ; adv: ', $adv;

        if ( $_obj =~ /(^|\s)(nicht)(\s|$)/i ) {
            push @advs, 'nicht';
            $_obj =~ s/(^|\s|[;])(nicht)(\s|$)/$1/igm;
        }

        if ( $_obj =~ /(^|\s)(not)(\s|$)/i ) {
            push @advs, 'not';
            $_obj =~ s/(^|\s|[;])(not)(\s|$)/$1/igm;
        }

        my @_obj_array = split /\s/, $_obj;
        push @advs,
          grep { $data->{lang}{is_adverb_of_time}{ lc $_ } } @_obj_array;
        $_obj = join ' ',
          grep { !$data->{lang}{is_adverb_of_time}{ lc $_ } } @_obj_array;

        #$_obj =~ s/^(.ein.?.?)\s/$1qq/igm;
        push @objs, $_obj;

        say '(3) obj: ', $_obj, ' ; adv: ', $adv;
    }

    if ( grep { lc $_ eq 'sich' } @subjs ) {
        @subjs = grep { lc $_ ne 'sich' } @subjs;
        if ( !@subjs ) {
            push @subjs, shift @objs;
        }
        push @objs, 'sich';
    }

    map { s/[;\s]+/;/igm } @advs;
    map { s/[;\s]+/;/igm } @advs;
    map { s/[;\s]+/;/igm } @advs;
    map { s/^[;\s]+//igm } @advs;
    map { s/[;\s]+$/;/igm } @advs;

    # currently broken

    #~ say;
    #~ say join( ', ', @advs );
    #~ say join( ', ', @objs );
    #~ my @objs_backup = @objs;
    #~ foreach my $backup (@objs) {
    #~ my @words = split /[_\s]+/, $backup;
    #~ say '@words: ', scalar @words;
    #~ say 'pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup ) = ',
    #~ pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup );
    #~ print qq{
    #~ my ret = ( }
    #~ . pos_of( $CLIENT_ref, ucfirst $words[-1], 0, 1, 0, $backup )
    #~ . qq{ == $data->{const}{NOUN}
    #~ && (    }
    #~ . pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup )
    #~ . qq{ == $data->{const}{ART}
    #~ || }
    #~ . pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup )
    #~ . qq{ == $data->{const}{ADJ}
    #~ || } . scalar @words . qq{ == 1 )
    #~ ? 0
    #~ : 1 );
    #~ };
    #~ my $ret = (
    #~ pos_of( $CLIENT_ref, ucfirst $words[-1], 0, 1, 0, $backup ) ==
    #~ $data->{const}{NOUN}
    #~ && (
    #~ pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup ) ==
    #~ $data->{const}{ART}
    #~ || pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup )
    #~ == $data->{const}{ADJ}
    #~ || pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup )
    #~ == $data->{const}{NOUN}
    #~ || @words == 1 )
    #~ ? 0
    #~ : 1
    #~ );

    #~ say '$ret: ', $ret;

    #~ if ($ret) {
    #~ my @words = split /\s+/, $backup;
    #~ push @advs, pop @words;
    #~ $backup = join( ' ', @words );
    #~ }
    #~ }

    #~ say;
    #~ say join( ', ', @advs );
    #~ say join( ', ', @objs );
    #~ @objs = ();
    #~ foreach my $backup (@objs_backup) {
    #~ my @words = split /[_\s]+/, $backup;
    #~ say '@words: ', scalar @words;
    #~ my $ret = (
    #~ pos_of( $CLIENT_ref, ucfirst $words[-1], 0, 1, 0, $backup ) ==
    #~ $data->{const}{NOUN}
    #~ && (
    #~ pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup ) ==
    #~ $data->{const}{ART}
    #~ || pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup )
    #~ == $data->{const}{ADJ}
    #~ || pos_of( $CLIENT_ref, lc $words[0], 0, 1, 0, $backup )
    #~ == $data->{const}{NOUN}
    #~ || @words == 1 )
    #~ ? 1
    #~ : 0
    #~ );
    #~ if ($ret) {
    #~ my @words = split /\s+/, $backup;
    #~ push @objs, pop @words;
    #~ $backup = join( ' ', @words );
    #~ }
    #~ }

    say;
    say join( ', ', @advs );
    say join( ', ', @objs );
    push @objs, grep {
        my @words = split /[_\s]+/, $_;
        lc $words[-1] =~ /^(das)$/
          ? 1
          : 0
    } @advs;

    say;
    say join( ', ', @advs );
    say join( ', ', @objs );
    @advs = grep {
        my @words = split /[_\s]+/, $_;
        lc $words[-1] =~ /^(das)$/
          ? 0
          : 1
    } @advs;

    say;
    say join( ', ', @advs );
    say join( ', ', @objs );

    push @advs, grep {
        my @words = split /[_\s]+/, $_;
        $words[-1] !~
          /(dies|ganz|letzte|halb|naechste).?.?\s(tag|woche|jahr|monat|nacht)/i
          ? 0
          : 1
    } @objs;

    @objs = grep {
        my @words = split /[_\s]+/, $_;
        $words[-1] !~
          /(dies|ganz|letzte|halb|naechste).?.?\s(tag|woche|jahr|monat|nacht)/i
          ? 1
          : 0
    } @objs;

    if ( @subjs == 1 && $subjs[0] eq 'nothing' ) {
        @subjs = shift @objs;
        @objs = ('nothing') if !@objs;
    }
    if ( @subjs == 1 && !defined $subjs[0] ) {
        @subjs = shift @objs;
        @objs = ('nothing') if !@objs;
    }

    $sentence_ref->{'subjects'} = \@subjs;
    $sentence_ref->{'objects'}  = \@objs;

    say(
        "Subjects (ref):",
        $sentence_ref->{'subjects'},
        ' ',
        "Objects (ref): ",
        $sentence_ref->{'objects'}
    );
    say(
        "Subjects (no ref): ",
        @{ $sentence_ref->{'subjects'} },
        ' ',
        "Objects (no ref): ",
        @{ $sentence_ref->{'objects'} }
    );

    if ( scalar grep { /^(mir|mich|dir|dich|sich)$/i }
        @{ $sentence_ref->{'subjects'} } )
    {
        my @add_to_obj =
          grep { /^(mir|mich|dir|dich|sich)$/i }
          @{ $sentence_ref->{'subjects'} };
        @{ $sentence_ref->{'subjects'} } =
          grep { !/^(mir|mich|dir|dich|sich)$/i }
          @{ $sentence_ref->{'subjects'} };
        unshift @{ $sentence_ref->{'objects'} }, @add_to_obj;
    }

    if ( scalar grep { /^(ich|du|er|sie)$/i } @{ $sentence_ref->{'objects'} } )
    {
        my @add_to_subj =
          grep { /^(ich|du|er|sie)$/i } @{ $sentence_ref->{'objects'} };
        @{ $sentence_ref->{'objects'} } =
          grep { !/^(ich|du|er|sie)$/i } @{ $sentence_ref->{'objects'} };
        push @{ $sentence_ref->{'subjects'} }, @add_to_subj;
    }

    if (  !scalar @{ $sentence_ref->{'subjects'} }
        && scalar @{ $sentence_ref->{'objects'} } )
    {
        push @{ $sentence_ref->{'subjects'} },
          shift @{ $sentence_ref->{'objects'} };
    }

    $sentence_ref->{'advs'} = \@advs;

    $sentence_ref = strip_nothings($sentence_ref);

    my $tmp = lc join ' ', @{ $sentence_ref->{'verbs'} };
    if ( $tmp =~ /(wird|wurde|werden|wirst|wire|wirde|werd|werdst)/i ) {

        my @temp_verbs =
          grep { $_ !~ /(wird|wurde|werden|wirst|wire|wirde|werd|werdst)/i }
          @{ $sentence_ref->{'verbs'} };

        if (@temp_verbs) {
            my @subj = ();
            foreach my $adv (@advs) {
                if ( $adv =~ /(von|by)\s(.*?)/i ) {
                    my $adv_to_use = $adv;
                    $adv        =~ s/(von|by).*//i;
                    $adv_to_use =~ s/.*?(von|by)\s//i;

                    push @subj, $adv_to_use;
                }
                chomp $adv;
            }
            @advs = grep { $_ } @advs;

            @{ $sentence_ref->{'verbs'} } = @temp_verbs if @temp_verbs;

            foreach my $verb ( @{ $sentence_ref->{'verbs'} } ) {
                $verb =~ s/ge//;
            }

            @{ $sentence_ref->{'objects'} } = (
                @{ $sentence_ref->{'subjects'} },
                @{ $sentence_ref->{'objects'} },
            );
            @{ $sentence_ref->{'subjects'} } = ();

            $sentence_ref->{'advs'} = \@advs;

            if (@subj) {
                push @{ $sentence_ref->{'subjects'} }, @subj;
            }

            elsif ( !@{ $sentence_ref->{'subjects'} } ) {
                push @{ $sentence_ref->{'subjects'} }, q{$$anyone$$};
            }
        }
    }

    @{ $sentence_ref->{'verbs'} } =
      grep { $_ !~ /nothing/i } @{ $sentence_ref->{'verbs'} };

    @{ $sentence_ref->{'verbs'} } =
      map { lc $_ } @{ $sentence_ref->{'verbs'} };

    @{ $sentence_ref->{'verbs'} } = (
        ( grep { $_ eq 'do' } @{ $sentence_ref->{'verbs'} } ),
        ( grep { $_ ne 'do' } @{ $sentence_ref->{'verbs'} } )
    );

    if ( $sentence_ref->{'verbs'}->[0] eq 'do' ) {
        shift @{ $sentence_ref->{'verbs'} };
    }

    @advs = grep { $_ } @advs;

    say;
    say join( ', ', @advs );
    say join( ', ', @objs );

    if (
        (
            (
                @{ $sentence_ref->{'subjects'} } == 1
                && $sentence_ref->{'subjects'}[0] eq 'nothing'
            )
            || ( @{ $sentence_ref->{'subjects'} } == 1
                && $sentence_ref->{'subjects'}[0] eq '' )
            || !@{ $sentence_ref->{'subjects'} }
        )
        && $sentence_ref->{'description'}
      )
    {

        @{ $sentence_ref->{'subjects'} } = ( $sentence_ref->{'description'}, );

        #$sentence_ref->{'description'} = '';
    }

    print Dumper $sentence_ref;

    # return
    return $sentence_ref;
}


sub strip_nothings {
    my ($sentence_ref) = @_;

    @{ $sentence_ref->{'objects'} } =
      grep { not /nothing/i } @{ $sentence_ref->{'objects'} };
    push @{ $sentence_ref->{'objects'} }, 'nothing'
      if not @{ $sentence_ref->{'objects'} };

    @{ $sentence_ref->{'subjects'} } =
      grep { not /nothing/i } @{ $sentence_ref->{'subjects'} };

    if ( $sentence_ref->{'description'} && !@{ $sentence_ref->{'subjects'} } ) {
        push @{ $sentence_ref->{'subjects'} }, $sentence_ref->{'description'};
        $sentence_ref->{'description'}           = '';    # empty
        $sentence_ref->{'subjects_use_examples'} = 1;
    }
    $sentence_ref->{'subjects_use_examples'} ||= 0;

    push @{ $sentence_ref->{'subjects'} }, 'nothing'
      if not @{ $sentence_ref->{'subjects'} };

    $sentence_ref->{'description'} =~ s/nothing//igm;
    $sentence_ref->{'description'} =~ s/^\s+//igm;
    $sentence_ref->{'description'} =~ s/\s+$//igm;

    return $sentence_ref;
}

sub resolve_hashes {

    #my @synonyms = map { [ verb_synonyms($_) ] } @words;

    my @synonyms = @_;    # array of hashes

    my @synonyms_all = @{ shift @synonyms || [] };

    while ( $synonyms[0] ) {
        my @synonyms_all_shorter = @synonyms_all;
        @synonyms_all = ();

        foreach my $verb ( @{ shift @synonyms || [] } ) {
            chomp $verb;
            return if !$verb;

            push @synonyms_all, map { $_ . ' ' . $verb } @synonyms_all_shorter;
        }
    }

    return @synonyms_all;
}


1;