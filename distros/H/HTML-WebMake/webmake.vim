" Vim syntax file
" Language:	WebMake (supporting embedded HTML)
" Maintainer:	Justin Mason <jm@jmason.org>
" URL:		http://webmake.taint.org/vim/syntax/webmake.vim
" Last Change:	Sep 27 2001 jm

" For full WebMake support, copy this file to your $VIM/syntax
" directory, and add these lines to your .vimrc:
"
" au BufNewFile,BufReadPost *.wmk so $HOME/.vim/webmake.vim
" map ,wm :w!<CR>:! webmake -R %<CR>
"
" ,wm will then rebuild the site using webmake, from inside VIM.

" ---------------------------------------------------------------------------
" based heavily on htmlm4.vim

" define main_syntax here so that included files can test for it
if !exists("main_syntax")
  syn clear
  let main_syntax='webmake'
endif

so <sfile>:p:h/html.vim
syn case match

" references, from make.vim
" These don't get nested references, ie. ${${blah}.foo} right
syn match webMakeIdent     "\$([^)].\{-})"
syn match webMakeIdent     "\${[^}].\{-}}"
syn match webMakeIdent     "\$\[[^\]].\{-}\]"

" comments
syn region webMakeComment   start=+<{!--+ end=+--}>+
hi link webMakeComment Comment

syn match webMakeIdent     "<{set\{-}}>"
syn match webMakeIdent     "<{perl\{-}}>"
syn match webMakeIdent     "<{perlout\{-}}>"
hi link webMakeIdent PreProc

" add the WebMake tags to the HTML allowed tag set
syn keyword htmlTagName contained content contents media out for
syn keyword htmlTagName contained webmake include wmmeta sitemap
syn keyword htmlTagName contained metatable navlinks metadefault
syn keyword htmlTagName contained breadcrumbs attrdefault sitetree
syn keyword htmlTagName contained use contenttable template templates

" and EtText extensions
syn keyword htmlTagName contained etright etleft safe csvtable

syn keyword htmlArg contained listname map format namefield
syn keyword htmlArg contained namesubst nametr isroot metatable
syn keyword htmlArg contained valuefield delimiter encoding
syn keyword htmlArg contained file node leaf sortorder skip
syn keyword htmlArg contained values up next prev nonext noprev
syn keyword htmlArg contained prefix suffix noup sitemap
syn keyword htmlArg contained opennode closednode thispage leaf
syn keyword htmlArg contained plugin

syn include @htmlPerlScript <sfile>:p:h/perl.vim
syn region wmPerlScript start=+<{perl+ keepend end=+}>+me=e contains=@htmlPerlScript

hi link wmPerlScript Special

let b:current_syntax = "webmake"

if main_syntax == 'webmake'
  unlet main_syntax
endif

