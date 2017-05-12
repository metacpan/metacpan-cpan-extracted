" Vim syntax file
" Language:		Perl with literate comments, Bird style,
"			POD style and plain text surrounding
"			'=begin code' and '=end code' blocks
" Maintainer:		Autrijus Tang <autrijus@autrjius.org>
" Original Author:	Autrijus Tang <autrijus@autrjius.org>
" Last Change:		2004 November 7
" Version:		0.01
"
" This style guesses as to the type of markup used in a literate Perl
" file and will highlight POD markup if it finds any
" This behaviour can be overridden, both glabally and locally using
" the lperl_markup variable or b:lperl_markup variable respectively.
"
" lperl_markup	    must be set to either  pod	or  none  to indicate that
"		    you always want POD highlighting or no highlighting
"		    must not be set to let the highlighting be guessed
" b:lperl_markup	    must be set to eiterh  pod	or  none  to indicate that
"		    you want POD highlighting or no highlighting for
"		    this particular buffer
"		    must not be set to let the highlighting be guessed
"


" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" First off, see if we can inherit a user preference for lperl_markup
if !exists("b:lperl_markup")
    if exists("lperl_markup")
	if lperl_markup =~ '\<\%(pod\|none\)\>'
	    let b:lperl_markup = matchstr(lperl_markup,'\<\%(pod\|none\)\>')
	else
	    echohl WarningMsg | echo "Unknown value of lperl_markup" | echohl None
	    let b:lperl_markup = "unknown"
	endif
    else
	let b:lperl_markup = "unknown"
    endif
else
    if b:lperl_markup !~ '\<\%(pod\|none\)\>'
	let b:lperl_markup = "unknown"
    endif
endif

" Remember where the cursor is, and go to upperleft
let s:oldline=line(".")
let s:oldcolumn=col(".")
call cursor(1,1)

" If no user preference, scan buffer for our guess of the markup to
" highlight. We only differentiate between POD and plain markup, where
" plain is not highlighted. The heuristic for finding POD markup is if
" the '=begin code' line occurs anywhere in the file
if b:lperl_markup == "unknown"
    if search('=begin code','W') != 0
	let b:lperl_markup = "pod"
    else
	let b:lperl_markup = "plain"
    endif
endif

" If user wants us to highlight POD syntax, read it.
if b:lperl_markup == "pod"
    if version < 600
	source <sfile>:p:h/pod.vim
    else
	runtime! syntax/pod.vim
	unlet b:current_syntax
    endif
endif

" Literate Perl is Perl in between text, so at least read Perl
" highlighting
if version < 600
    syn include @perlTop <sfile>:p:h/perl.vim
else
    syn include @perlTop syntax/perl.vim
endif

syntax region lperlPerlBirdTrack start="^>" end="\%(^[^>]\)\@=" contains=@perlTop,lperlBirdTrack
syntax region lperlPerlBeginEndBlock start="^=begin code" end="^=end code" contains=@perlTop

syntax match lperlBirdTrack "^>" contained

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_pod_syntax_inits")
  if version < 508
    let did_pod_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink lperlBirdTrack Comment

  delcommand HiLink
endif

" Restore cursor to original position, as it may have been disturbed
" by the searches in our guessing code
call cursor (s:oldline, s:oldcolumn)

unlet s:oldline
unlet s:oldcolumn

let b:current_syntax = "lperl"

" vim: ts=8
