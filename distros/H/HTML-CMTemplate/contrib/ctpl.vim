" Vim syntax file
" Language:     ctpl CMTemplate
" Maintainer:   Chris Monson <chris@bouncingchairs.net>
" URL:          None yet
" Email:        Subject: Give me CTPL Syntax!
" Last Change:  2001 Mar 10


" Remove any old syntax stuff hanging around
syn clear

if !exists("main_syntax")
  let main_syntax = 'ctpl'
endif

if &filetype == 'ctpl_html'
    so $VIMRUNTIME/syntax/html.vim
    syn cluster htmlPreproc add=@ctplRegion
elseif &filetype == 'ctpl_apache'
    so $VIMRUNTIME/syntax/apachestyle.vim
    syn cluster apachestylePreProc add=@ctplRegion
elseif &filetype == 'ctpl_js'
    so $VIMRUNTIME/syntax/javascript.vim
    syn cluster htmlPreproc add=@ctplRegion
endif

syn case match

" Hanging end tags are tags that occur on the end of the line.  They change
"   color to remind people that the endline will be eaten up with the rest
"   of the tag.  This should help people to remember to add an extra newline
"   when one is desired.
syntax match CMParen /[)(]/ contained
syntax match CMBlockBlankError /\S\+/ contained
syntax match CMHangEnd /?>$/ contained
syntax match CMHangEndColon /:\s\{-}?>$/ contained
syntax match CMHangEndError /?>$/ contained
syntax match CMHangEndColonError /:\s\{-}?>$/ contained

syntax match CMEnd /?>./ contained
syntax match CMEndColon /:\s\{-}?>./ contained
syntax match CMEndError /?>./ contained
syntax match CMEndColonError /:\s\{-}?>./ contained

"syntax match CMCallDef /\S\+\s*(.\{-})/ contained

syntax cluster CMETag contains=OHangEnd,OEnd
syntax cluster CMETagColon contains=OHangEndColon,OEndColon
syntax cluster CMETagError contains=OHangEndError,OEndError
syntax cluster CMETagColonError contains=OHangEndColonError,OEndColonError

syntax match CMStart /<?=/ contained

syntax cluster CMTagGrp contains=@OETag,@OETagColonError,OStart
syntax cluster CMTagColonGrp contains=@OETagColon,@OETagError,OStart

syntax keyword CMOp contained in
syntax keyword CMName contained echo if elif endif for endfor def enddef
syntax keyword CMName contained call inc break continue
syntax keyword CMNameElse contained else
syntax keyword CMNameComment contained comment
syntax keyword CMNameExec contained exec
syntax keyword CMNameInclude contained inc rawinc

syntax match CMForFunction /for_\(index\|list\|count\|is_last\|is_first\)\s*(\s*\d*\s*)/ contains=OParen contained

syntax region CMTagShortcut start=/<?=/ end=/?>/ contains=@OTagGrp,OForFunction,OParen keepend

syntax region CMTagCondBlock start=/<?=\(if\|elif\)\(\s\|$\)/ end=/:\s*?>/ contains=@OTagColonGrp,OName keepend

syntax region CMTagElseBlock start=/<?=else/ end=/\s*:\s*?>/ contains=@OTagColonGrp,OBlockBlankError,ONameElse keepend

syntax region CMTagDefBlock start=/<?=\(def\)\(\s\|$\)/ end=/:\s*?>/ contains=@OTagColonGrp,OName,OParen keepend

syntax region CMTagForBlock start=/<?=\(for\)\(\s\|$\)/ end=/:\s*?>/ contains=@OTagColonGrp,OName,OOp,OForFunction keepend

syntax region CMTagEndBlock start=/<?=\(endif\|endfor\|enddef\|break\|continue\)/ end=/?>/ contains=@OTagGrp,OBlockBlankError,OName keepend

syntax region CMTagCall start=/<?=call\(\s\|$\)/ end=/?>/ contains=@OTagGrp,OName,OForFunction keepend

syntax region CMTagEcho start=/<?=echo\(\s\|$\)/ end=/?>/ contains=@OTagGrp,OName,OForFunction,OParen keepend

syntax region CMTagComment start=/<?=comment\(\s\|$\)/ end=/?>/ contains=@OTagGrp,ONameComment keepend

syntax region CMTagExec start=/<?=exec\(\s\|$\)/ end=/?>/ contains=@OTagGrp,OForFunction,ONameExec keepend

syntax region CMTagInclude start=/<?=\(inc\|rawinc\)\(\s\|$\)/ end=/?>/ contains=@OTagGrp,ONameInclude keepend

" Cluster this region together so that it is easy to add to the HTML
" preprocessor stuff (and any other preprocessor stuff, since this stuff
" is always processed first).
syntax cluster ctplRegion contains=OTagShortcut,OTagCondBlock,OTagElseBlock,OTagDefBlock,OTagForBlock,OTagEndBlock,OTagCall,OTagEcho,OTagComment,OTagExec,OTagInclude

" Link the highlight groups together to make editing them easy
hi link CMTagShortcut        ctplTag
hi link CMTagCondBlock       ctplTag
hi link CMTagElseBlock       ctplTag
hi link CMTagDefBlock        ctplTag
hi link CMTagForBlock        ctplTag
hi link CMTagEndBlock        ctplTag
hi link CMTagCall            ctplTag
hi link CMTagEcho            ctplTag
hi link CMTagComment         ctplTag
hi link CMTagExec            ctplTag
hi link CMTagInclude         ctplTag

hi link CMBlockBlankError    ctplError
hi link CMHangEndError       ctplError
hi link CMHangEndColonError  ctplError
hi link CMEndError           ctplError
hi link CMEndColonError      ctplError

hi link CMName               ctplIdent
hi link CMNameElse           ctplIdent
hi link CMNameComment        ctplIdent
hi link CMNameExec           ctplIdent
hi link CMNameInclude        ctplIdent

hi link CMOp                 ctplOperator
hi link CMParen              ctplOperator
hi link CMForFunction        ctplOperator
"hi link CMCallDef            ctplOperator

hi link CMHangEnd            ctplHangDelimiter
hi link CMHangEndColon       ctplHangDelimiter
hi link CMEnd                ctplDelimiter
hi link CMEndColon           ctplDelimiter
hi link CMStart              ctplDelimiter

hi ctplTag guifg=white guibg=#555555 term=reverse ctermbg=3
hi ctplError guifg=white guibg=red term=bold ctermbg=red
hi ctplOperator guifg=Green guibg=#555555 gui=bold term=reverse ctermbg=3
hi ctplIdent guifg=#ffff60 gui=bold guibg=#555555 term=reverse ctermbg=3

hi ctplHangDelimiter guifg=Cyan gui=bold guibg=#555555 term=reverse ctermbg=3
hi ctplDelimiter guifg=Orange guibg=#555555 term=reverse ctermbg=3
