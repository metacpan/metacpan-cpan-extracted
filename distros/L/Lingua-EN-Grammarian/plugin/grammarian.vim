" Vim global plugin for grammar checking
" Last change:  Mon Apr  8 20:55:17 EST 2013
" Maintainer:   Damian Conway
" License:      This file is placed in the public domain.
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  This plugin provides access to the grammar-checking functionality of the
"  Perl module Lingua::EN::Grammarian, from within Vim.
"
"  It defines a single nmap: ;g
"
"  This mapping toggles grammar checking on all buffers.
"
"  When grammar checking is activated, three additional nmaps are defined:
"
"      <TAB>      : which jumps to and describes the next error
"      <S-TAB>    : which jumps to and describes the next error or caution
"      <TAB><TAB> : which corrects the error or caution under the cursor
"
"  These mappings are reverted to their former behaviours
"  (as far as possible) when grammar checking is toggled back off.
"
"  The module requires a Vim with +perl compiled in (and Perl 5.10 or later).
"  Obviously, it also requires the Lingua::EN::Grammarian module (from CPAN).
"
"  You can configure what grammar is checked by installing and modifying the
"  'grammarian_errors' and 'grammarian_cautions' files that come with the
"  module. See the module's documentation for a description of where to put
"  these files, and what to put in them.
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" If already loaded, we're done...
if exists("loaded_grammarian")
    finish
endif
let loaded_grammarian = 1

" Preserve external compatibility options, then enable full vim compatibility...
let s:save_cpo = &cpo
set cpo&vim


" Create a pattern that matches repeated words...
let s:REPEAT_MATCHER = '\c\(\<\S\+\>\)\@>\_s\+\<\1\>'

" Display cautions and errors and messages...
highlight GRAMMARIAN_BOLD           term=bold cterm=bold                               gui=bold
highlight GRAMMARIAN_WHITE          term=bold cterm=bold ctermfg=white                 gui=bold guifg=white
highlight GRAMMARIAN_GREEN          term=bold cterm=bold ctermfg=green                 gui=bold guifg=green
highlight GRAMMARIAN_YELLOW         term=bold cterm=bold ctermfg=yellow                gui=bold guifg=yellow
highlight GRAMMARIAN_CYAN           term=bold cterm=bold ctermfg=cyan                  gui=bold guifg=cyan
highlight GRAMMARIAN_RED            term=bold cterm=bold ctermfg=red                   gui=bold guifg=red
highlight GRAMMARIAN_RED_ON_YELLOW  term=bold cterm=bold ctermfg=red   ctermbg=yellow  gui=bold guifg=red
highlight GRAMMARIAN_WHITE_ON_RED   term=bold cterm=bold ctermfg=white ctermbg=red     gui=bold guifg=white guibg=red

highlight link GRAMMARIAN_ERROR_DISPLAY             GRAMMARIAN_WHITE_ON_RED
highlight link GRAMMARIAN_REPETITION_DISPLAY        GRAMMARIAN_RED_ON_YELLOW
highlight link GRAMMARIAN_CAUTION_DISPLAY           GRAMMARIAN_BOLD

highlight link GRAMMARIAN_ERROR_MSG                 GRAMMARIAN_ERROR_DISPLAY
highlight link GRAMMARIAN_REPETITION_MSG            GRAMMARIAN_REPETITION_DISPLAY
highlight link GRAMMARIAN_CAUTION_MSG               GRAMMARIAN_CAUTION_DISPLAY
highlight link GRAMMARIAN_INFORMATION_MSG           GRAMMARIAN_WHITE
highlight link GRAMMARIAN_SUGGESTION_MSG            GRAMMARIAN_CYAN
highlight link GRAMMARIAN_SUGGESTION_DEFAULT_MSG    GRAMMARIAN_YELLOW

highlight link GRAMMARIAN_DECORATION                GRAMMARIAN_GREEN
highlight link GRAMMARIAN_PROMPT_MSG                GRAMMARIAN_GREEN

let s:grammarian_matchers = []

let g:grammarian_errors_pat_list   = []
let g:grammarian_cautions_pat_list = []

let g:grammarian_restore = {}

function! Grammarian_Toggle (...)
    " If matching, stop and clean up...
    if len(s:grammarian_matchers)
        for matcher in s:grammarian_matchers
            call matchdelete(matcher)
        endfor
        let s:grammarian_matchers = []
        execute g:grammarian_restore['query']
        execute g:grammarian_restore['query all']
        execute g:grammarian_restore['correction']
        let g:grammarian_restore = {}

    " Otherwise, start matching...
    else
        " Load patterns if necessary...
        if !len(g:grammarian_errors_pat_list)
            echohl GRAMMARIAN_INFORMATION_MSG
            echo '[Loading grammatical data]'
            echohl NONE
            perl <<END_SCRIPT
                use Lingua::EN::Grammarian qw< get_vim_error_regexes get_vim_caution_regexes >;

                my $errors_pat_list = join q{','}, get_vim_error_regexes();
                VIM::DoCommand("let g:grammarian_errors_pat_list = ['$errors_pat_list']");

                my $cautions_pat_list = join q{','}, get_vim_caution_regexes();
                VIM::DoCommand("let g:grammarian_cautions_pat_list = ['$cautions_pat_list']");
END_SCRIPT
            redraw!
        endif

        " Start matching and highlighting the cautions...
        let s:grammarian_matchers = []
        for pattern in g:grammarian_cautions_pat_list
            let s:grammarian_matchers += [matchadd('GRAMMARIAN_CAUTION_DISPLAY', pattern,1)]
        endfor

        " Start matching and highlighting the errors...
        for pattern in g:grammarian_errors_pat_list
            let s:grammarian_matchers += [matchadd('GRAMMARIAN_ERROR_DISPLAY', pattern,2)]
        endfor
        let s:grammarian_matchers += [ matchadd('GRAMMARIAN_REPETITION_DISPLAY', s:REPEAT_MATCHER,2)]

        " Install query interface
        let g:grammarian_restore['query']   = Grammarian_Get_Mapping_For('n',"<TAB>")
        nnoremap <silent> <TAB>  :call Grammarian_Query()<CR>

        let g:grammarian_restore['query all']   = Grammarian_Get_Mapping_For('n',"<S-TAB>")
        nnoremap <silent> <S-TAB>  :call Grammarian_Query('all')<CR>

        let g:grammarian_restore['correction'] = Grammarian_Get_Mapping_For('n',"<TAB><TAB>")
        nnoremap <silent> <TAB><TAB>  :call Grammarian_Correction()<CR>
    endif
endfunction

function! Grammarian_Query (...)
    perl <<END_SCRIPT
        use Lingua::EN::Grammarian 'get_next_error_at', 'get_next_caution_at';

        my $check_for_cautions = VIM::Eval('a:0');

        # Grab buffer text...
        my $text = join "\n", $curbuf->Get(1..$curbuf->Count);

        # Grab and remember cursor and normalize column to 1-based...
        my @cursor = $curwin->Cursor();
        $cursor[1]++;

        # Is cursor on an error???
        my ($error_obj, $cursor_on_error) = get_next_error_at($text, @cursor);
        if ($cursor_on_error) {
            VIM::Msg(
                $error_obj->explanation,
                $error_obj->explanation eq 'Repeated word' ? 'GRAMMARIAN_REPETITION_DISPLAY'
                                                           : 'GRAMMARIAN_ERROR_DISPLAY'
            );
            return;
        }

        # Is cursor on a caution???
        my ($caution_obj, $cursor_on_caution)
            = $check_for_cautions ? get_next_caution_at($text, @cursor) : ();
        if ($cursor_on_caution) {
            my $match = $caution_obj->match;
            $match =~ s/\s+/\\s+/g;
            my $explanations_ref = $caution_obj->explanation_hash;
            my @otherkeys = grep { !/\A$match\z/i && $match !~ /\A\Q$_\E/i  } keys %{$explanations_ref};
            my $message = @otherkeys == 1
                            ? qq{"$otherkeys[0]" ($explanations_ref->{$otherkeys[0]})}
                            : join " or ", map {qq{"$_"}} @otherkeys;
            VIM::Msg("Did you mean: $message?", 'GRAMMARIAN_CAUTION_DISPLAY');
            return;
        }

        # Is an error the next problem???
        my $error_loc   = $error_obj   ? $error_obj->from   : undef;
        my $caution_loc = $caution_obj ? $caution_obj->from : undef;
        if ($error_obj && (!$caution_obj || $error_loc->{index} <= $caution_loc->{index})) {
            VIM::Msg(
                $error_obj->explanation,
                $error_obj->explanation eq 'Repeated word' ? 'GRAMMARIAN_REPETITION_DISPLAY'
                                                           : 'GRAMMARIAN_ERROR_DISPLAY'
            );
            $curwin->Cursor($error_loc->{line}, $error_loc->{column}-1);
            return;
        }

        # Next is a caution...
        if ($caution_obj) {
            my $match = $caution_obj->match;
            $match =~ s/\s+/\\s+/g;
            my $explanations_ref = $caution_obj->explanation_hash;
            my @otherkeys = grep { !/\A$match\z/i && $match !~ /\A\Q$_\E/i  } keys %{$explanations_ref};
            my $message = @otherkeys == 1
                            ? qq{"$otherkeys[0]" (i.e. "$explanations_ref->{$otherkeys[0]}")}
                            : join " or ", map {qq{"$_"}} @otherkeys;
            VIM::Msg("Did you mean: $message?", 'GRAMMARIAN_CAUTION_DISPLAY');
            $curwin->Cursor($caution_loc->{line}, $caution_loc->{column}-1);
            return;
        }

        VIM::Msg('End of grammar warnings!', 'GRAMMARIAN_INFORMATION_MSG');
END_SCRIPT
    redraw
endfunction

perl <<END_SCRIPT
    use strict; use warnings;
    sub prompt_for_replacement {
        my ($msg, $highlight, $original, @suggestions) = @_;

        # Unique suggestions only...
        my %seen;
        @suggestions = grep { !$seen{$_}++ } @suggestions;

        return $suggestions[0] if @suggestions == 1;

        # Build table of suggestions (starting with standard responses)...
        my %suggestion = (
            "\e" => $original,
            "\r" => $suggestions[0],
            "\t" => $suggestions[0],
        );
        my $max_selector = 'a';
        while (@suggestions) {
            $suggestion{$max_selector++} = shift @suggestions;
        }

        # Report message...
        $original =~ s/\s+/ /g;
        my $vertical_bar = '_' x VIM::Eval('winwidth(0)-1');
        VIM::Msg($vertical_bar, 'GRAMMARIAN_DECORATION');
        if ($msg =~ /\n/) {
            $msg =~ s/^/    /gm;
            VIM::Msg(qq{"$original"...}, $highlight);
            VIM::Msg(qq{$msg}, $highlight);
        }
        else {
            VIM::Msg(qq{"$original" : $msg}, $highlight);
        }

        # Report suggestions...
        VIM::Msg($vertical_bar, 'GRAMMARIAN_DECORATION');
        VIM::Msg('Replace with :', 'GRAMMARIAN_DECORATION');
        for my $selector (sort grep {/[[:alpha:]]/} keys %suggestion) {
            VIM::Msg(
                "    $selector.  $suggestion{$selector}",
                ($selector eq 'a' ? 'GRAMMARIAN_SUGGESTION_DEFAULT_MSG' : 'GRAMMARIAN_SUGGESTION_MSG')
            );
        }
        VIM::Msg($vertical_bar, 'GRAMMARIAN_DECORATION');

        # Get selection...
        my $response = q{};
        while (!$response || !exists $suggestion{$response}) {
            VIM::Msg("> ", 'GRAMMARIAN_PROMPT_MSG');
            $response = VIM::Eval('nr2char(getchar())');
        }

        return $suggestion{$response};
    }
END_SCRIPT

function! Grammarian_Correction ()
    call inputsave()
    perl <<END_SCRIPT
        use strict; use warnings;
        our ($curbuf, $curwin);
        use Lingua::EN::Grammarian 'get_error_at', 'get_caution_at';

        # Grab buffer text...
        my $text = join "\n", $curbuf->Get(1..$curbuf->Count);

        # Grab and remember cursor and normalize column to 1-based...
        my @cursor = $curwin->Cursor();
        $cursor[1]++;

        # Is cursor on an error or a caution???
        my $problem_type;
        my ($problem_obj, $on_problem) = get_error_at($text, @cursor);
        if ($on_problem) {
            $problem_type = 'GRAMMARIAN_ERROR_MSG';
        }
        else {
            ($problem_obj, $on_problem) = get_caution_at($text, @cursor);
            $problem_type = 'GRAMMARIAN_CAUTION_MSG';
        }

        if ($on_problem) {
            my $newline = ($problem_obj->match =~ /\n/ ? qq{\n} : q{});
            my $replacement = prompt_for_replacement(
                                    $problem_obj->explanation,
                                    $problem_type,
                                    $problem_obj->match,
                                    $problem_obj->suggestions
                              );
            my ($from, $to) = ($problem_obj->from, $problem_obj->to);
            VIM::DoCommand(qq{normal! $from->{line}G$from->{column}|v$to->{line}G$to->{column}|s$replacement$newline\e});
            return;
        }
END_SCRIPT
    call inputrestore()
    redraw!
endfunction

function! Grammarian_Get_Mapping_For (mode, sequence)
    let sequence = eval('"' . substitute(a:sequence, '<', '\\<', 1) . '"')
    let desc = maparg(sequence, a:mode, 0, 1)
    if len(desc) > 0
        return (desc['noremap'] ? a:mode . 'noremap' : a:mode)
        \    . ' '
        \    . (desc['silent'] ? '<silent>' : '')
        \    . (desc['expr']   ? '<expr>'   : '')
        \    . (desc['buffer'] ? '<buffer>' : '')
        \    . ' '
        \    . desc['lhs']
        \    . ' '
        \    . desc['rhs']
    else
        return a:mode . 'unmap ' . a:sequence
    endif
endfunction


" Toggle grammar checking...
nmap <silent> ;g  :call Grammarian_Toggle()<CR>


" Restore previous external compatibility options
let &cpo = s:save_cpo
