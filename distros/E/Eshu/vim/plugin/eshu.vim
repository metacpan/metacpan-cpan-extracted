" eshu.vim — Indentation fixer using the Eshu CLI
"
" Installation:
"
"   1. Make sure the 'eshu' command is in your PATH:
"
"        cd /path/to/Eshu && perl Makefile.PL && make && make install
"
"   2. Choose ONE of the following methods:
"
"      a) Vim 8+ native packages (no plugin manager needed):
"
"           mkdir -p ~/.vim/pack/eshu/start
"           ln -s /path/to/Eshu/vim ~/.vim/pack/eshu/start/eshu
"
"      b) Neovim native packages:
"
"           mkdir -p ~/.local/share/nvim/site/pack/eshu/start
"           ln -s /path/to/Eshu/vim ~/.local/share/nvim/site/pack/eshu/start/eshu
"
"      c) Manual (just source it from your ~/.vimrc):
"
"           source /path/to/Eshu/vim/plugin/eshu.vim
"
"      d) vim-plug (add to your ~/.vimrc, then run :PlugInstall):
"
"           Plug '/path/to/Eshu/vim'
"
"      e) Vundle (add to your ~/.vimrc, then run :PluginInstall):
"
"           Plugin 'file:///path/to/Eshu/vim'
"
"      f) Pathogen (symlink into your bundle directory):
"
"           ln -s /path/to/Eshu/vim ~/.vim/bundle/eshu
"
" Configuration:
"
"   To override the eshu binary path (defaults to 'eshu'):
"
"       let g:eshu_cmd = '/path/to/Eshu/bin/eshu'
"
" Usage:
"
"   :EshuFix          Fix indentation for entire file
"   :EshuFixRange     Fix indentation for visual selection
"   <leader>ef        Fix entire file (normal mode) - \ef
"   <leader>ef        Fix selection (visual mode) - enter visual mode and highlight then \ef

if exists('g:loaded_eshu') || &compatible
  finish
endif
let g:loaded_eshu = 1

" Allow user to override the eshu binary path
if !exists('g:eshu_cmd')
  let g:eshu_cmd = 'eshu'
endif

function! s:EshuDetectLang() abort
  let ext = expand('%:e')
  let map = {
    \ 'c': 'c', 'h': 'c',
    \ 'xs': 'xs',
    \ 'pl': 'perl', 'pm': 'perl', 't': 'perl',
    \ 'xml': 'xml', 'xsl': 'xsl', 'xslt': 'xslt', 'svg': 'svg',
    \ 'xhtml': 'xhtml',
    \ 'html': 'html', 'htm': 'htm', 'tmpl': 'tmpl', 'tt': 'tt', 'ep': 'ep',
    \ 'css': 'css', 'scss': 'scss', 'less': 'less',
    \ 'js': 'js', 'jsx': 'js', 'mjs': 'js', 'cjs': 'js',
    \ 'ts': 'js', 'tsx': 'js', 'mts': 'js',
    \ 'pod': 'pod',
    \ }
  return get(map, tolower(ext), '')
endfunction

function! s:EshuFix() abort
  let lang = s:EshuDetectLang()
  if lang ==# ''
    echohl ErrorMsg | echomsg 'Eshu: cannot detect language for ' . expand('%:t') | echohl None
    return
  endif

  let pos = getpos('.')
  silent execute '%!' . g:eshu_cmd . ' --lang ' . lang
  if v:shell_error
    silent undo
    echohl ErrorMsg | echomsg 'Eshu: command failed' | echohl None
  endif
  call setpos('.', pos)
endfunction

function! s:EshuFixRange() range abort
  let lang = s:EshuDetectLang()
  if lang ==# ''
    echohl ErrorMsg | echomsg 'Eshu: cannot detect language for ' . expand('%:t') | echohl None
    return
  endif

  " Use --range so the full file is sent and eshu can parse context
  let pos = getpos('.')
  let range_arg = a:firstline . ',' . a:lastline
  silent execute '%!' . g:eshu_cmd . ' --lang ' . lang . ' --range ' . range_arg
  if v:shell_error
    silent undo
    echohl ErrorMsg | echomsg 'Eshu: command failed' | echohl None
  endif
  call setpos('.', pos)
endfunction

command! EshuFix call s:EshuFix()
command! -range EshuFixRange <line1>,<line2>call s:EshuFixRange()

" Default mappings — override g:eshu_no_mappings = 1 to disable
if !get(g:, 'eshu_no_mappings', 0)
  nnoremap <silent> <F6> :EshuFix<CR>
  vnoremap <silent> <F6> :EshuFixRange<CR>
endif
