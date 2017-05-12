package # hidden from PAUSE indexer
Perl6::Loops;

our $VERSION = '0.000001';
use 5.014; use warnings;

use Keyword::Declare;

sub import {

    # Rewire the 'for' loop (but we need to handle existing usages first)...
    keytype Param  { /\$\w+\s*/   }
    keytype Params { /\$\w+\s*,?/ }

    keyword for {{{ foreach }}}

    keyword for (List $list, '->', Params @parameters, Block $code_block)
                :desc(enhanced for loop)
    {{{
        {
            state $__acc__ = [];
            foreach my $__nary__  <{ $list =~ s{\)\Z}{,\\\$__acc__)}r }>
            {
                if (!ref($__nary__) || $__nary__ != \$__acc__) {
                    push @{$__acc__}, $__nary__;
                    next if @{$__acc__} <= <{ $#parameters }>;
                }
                next if !@{$__acc__};
                my ( <{"@parameters"}> ) = @{$__acc__};
                @{$__acc__} = ();

                <{substr $code_block, 1, -1}>
            }
        }
    }}}


    # Perl 6 infinite loop...
    keyword loop (Block $loop_block)  {{{
        foreach (;;) <{$loop_block}>
    }}}


    # Perl 6 while loop...
    keyword while (List $condition, Block $loop_block)  {{{
        foreach (;<{$condition}>;) <{$loop_block}>
    }}}

    keyword while (List $condition, '->', Param $parameter, Block $loop_block)  {{{
        foreach (;my <{$parameter}> = <{$condition}>;) <{$loop_block}>
    }}}


    # Perl 6 repeat...while and variants...

    keyword repeat ('while', List $while_condition, Block $code_block) :desc(repeat loop)  {{{
        foreach(;;) { do <{$code_block}>; last if !(<{$while_condition}>); }
    }}}

    keyword repeat ('until', List $until_condition, Block $code_block) {{{
        foreach(;;) { do <{$code_block}>; last if <{$until_condition}>; }
    }}}

    keyword repeat (Block $code_block, /until|while/ $while_or_until, Expr $condition) {
        my $not = $while_or_until eq 'while' ? q{!} : q{};
        qq{ foreach (;;) { do $code_block; last if $not ($condition); } };
    }


    # Special Perl 6 phasers within loops...

    keyword FIRST (Block $code_block, ...'}' $rest_of_block) :desc(FIRST block) {
        state $FIRST_ID = 'FIRST000000'; $FIRST_ID++;
        qq{
            if (!our \$$FIRST_ID++) { $code_block }
            $rest_of_block
            {our \$$FIRST_ID = 0}
        };
    }

    keyword NEXT (Block $code_block, ...'}' $rest_of_block) :desc(NEXT block) {
        state $NEXT_ID = 'NEXT000000'; $NEXT_ID++;
        chop $rest_of_block;
        qq{
            my \$$NEXT_ID = sub $code_block;
            $rest_of_block
            \$$NEXT_ID->();
            \}
        };
    }

    keyword LAST (Block $code_block, ...'}' @rest_of_block) :desc(LAST block) {
        state $LAST_ID = 'LAST000000'; $LAST_ID++;
        qq{
            our \$$LAST_ID = sub $code_block;
            @rest_of_block
            {(our \$$LAST_ID)->();}
        };
    }
}

1; # Magic true value required at end of module
