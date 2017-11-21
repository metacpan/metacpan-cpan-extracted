let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
vmap  <Plug>SchleppDupLeft
vmap <silent> + :call EQAS_Align('vmap', {'cursor':1} )
nmap <silent> ++ :call EQAS_Align('nmap', {'cursor':1, 'paragraph':1} )
nmap <silent> + :call EQAS_Align('nmap', {'cursor':1} )
nnoremap ,S :mksession!
nnoremap ,s :mksession
nnoremap ,  :nohlsearch 
vmap <silent> = :call EQAS_Align('vmap')
nmap <silent> == :call EQAS_Align('nmap', {'paragraph':1} )
nmap <silent> = :call EQAS_Align('nmap')
vmap D <Plug>SchleppDupLeft
vmap gx <Plug>NetrwBrowseXVis
nmap gx <Plug>NetrwBrowseX
nnoremap gr gT
nnoremap j gj
nnoremap k gk
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>
vnoremap <silent> <Plug>NetrwBrowseXVis :call netrw#BrowseXVis()
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#BrowseX(expand((exists("g:netrw_gx")? g:netrw_gx : '<cfile>')),netrw#CheckIfRemote())
vmap <Right> <Plug>SchleppRight
vmap <Left> <Plug>SchleppLeft
vmap <Down> <Plug>SchleppDown
vmap <Up> <Plug>SchleppUp
onoremap <Right> <Nop>
onoremap <Left> <Nop>
onoremap <Down> <Nop>
onoremap <Up> <Nop>
let &cpo=s:cpo_save
unlet s:cpo_save
set backspace=indent,eol,start
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set foldlevelstart=10
set helplang=en
set hlsearch
set incsearch
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,:
set iskeyword=@,48-57,_,192-255,$,%,@-@,:
set lazyredraw
set nomodeline
set mouse=a
set pastetoggle=<F2>
set printoptions=paper:a4
set ruler
set runtimepath=~/.vim,/var/lib/vim/addons,/usr/share/vim/vimfiles,/usr/share/vim/vim74,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,~/.vim/after
set shiftwidth=4
set showcmd
set showmatch
set softtabstop=4
set splitbelow
set splitright
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set tabstop=4
set wildmenu
set window=45
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/Documents/Code/Perl/Modules/Device-Network-ConfigParser
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +1 lib/Device/Network/ConfigParser/CheckPoint/Gaia.pm
badd +1 t/01-checkpoint_gaia.t
badd +1 t/00-load.t
badd +1 t/02-cisco_asa.t
badd +1 lib/Device/Network/ConfigParser/Cisco/ASA.pm
argglobal
silent! argdel *
argadd lib/Device/Network/ConfigParser/CheckPoint/Gaia.pm
set stal=2
edit lib/Device/Network/ConfigParser/Cisco/ASA.pm
set splitbelow splitright
wincmd t
set winheight=1 winwidth=1
argglobal
nmap <buffer> <silent> * :let @/ = TPV_locate_perl_var()
vmap <buffer> cv :call TPV_rename_perl_var('visual')gv
nmap <buffer> cv :call TPV_rename_perl_var('normal')
nmap <buffer> <silent> gd :let @/ = TPV_locate_perl_var_decl()
nmap <buffer> <silent> tt :let b:track_perl_var_locked = ! b:track_perl_var_locked:call TPV_track_perl_var()
setlocal keymap=
setlocal noarabic
setlocal noautoindent
setlocal backupcopy=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal nofoldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=10
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
set foldnestmax=10
setlocal foldnestmax=10
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=crqol
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=0
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(substitute(v:fname,'::','/','g'),'->*','',''),'$','.pm','')
setlocal indentexpr=GetPerlIndent()
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0=,0),0],0=or,0=and
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,$,%,@-@,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal modifiable
setlocal nrformats=bin,octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,~/perl5/perlbrew/perls/perl-5.25.12/lib/site_perl/5.25.12/x86_64-linux,~/perl5/perlbrew/perls/perl-5.25.12/lib/site_perl/5.25.12,~/perl5/perlbrew/perls/perl-5.25.12/lib/5.25.12/x86_64-linux,~/perl5/perlbrew/perls/perl-5.25.12/lib/5.25.12
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
set relativenumber
setlocal relativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=4
setlocal tagcase=
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
72
normal! zo
73
normal! zo
76
normal! zo
124
normal! zo
141
normal! zo
150
normal! zo
150
normal! zo
150
normal! zo
155
normal! zo
158
normal! zo
161
normal! zo
171
normal! zo
171
normal! zo
186
normal! zo
193
normal! zo
200
normal! zo
let s:l = 145 - ((18 * winheight(0) + 22) / 44)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
145
normal! 013|
tabedit t/02-cisco_asa.t
set splitbelow splitright
wincmd t
set winheight=1 winwidth=1
argglobal
nmap <buffer> <silent> * :let @/ = TPV_locate_perl_var()
vmap <buffer> cv :call TPV_rename_perl_var('visual')gv
nmap <buffer> cv :call TPV_rename_perl_var('normal')
nmap <buffer> <silent> gd :let @/ = TPV_locate_perl_var_decl()
nmap <buffer> <silent> tt :let b:track_perl_var_locked = ! b:track_perl_var_locked:call TPV_track_perl_var()
setlocal keymap=
setlocal noarabic
setlocal noautoindent
setlocal backupcopy=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=10
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
set foldnestmax=10
setlocal foldnestmax=10
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=crqol
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=0
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(substitute(v:fname,'::','/','g'),'->*','',''),'$','.pm','')
setlocal indentexpr=GetPerlIndent()
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0=,0),0],0=or,0=and
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,$,%,@-@,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal modifiable
setlocal nrformats=bin,octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,~/perl5/perlbrew/perls/perl-5.25.12/lib/site_perl/5.25.12/x86_64-linux,~/perl5/perlbrew/perls/perl-5.25.12/lib/site_perl/5.25.12,~/perl5/perlbrew/perls/perl-5.25.12/lib/5.25.12/x86_64-linux,~/perl5/perlbrew/perls/perl-5.25.12/lib/5.25.12
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
set relativenumber
setlocal relativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=4
setlocal tagcase=
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
111
normal! zo
112
normal! zo
114
normal! zo
114
normal! zo
114
normal! zo
114
normal! zo
115
normal! zo
121
normal! zo
123
normal! zo
123
normal! zo
123
normal! zo
123
normal! zo
123
normal! zo
131
normal! zo
133
normal! zo
133
normal! zo
133
normal! zo
133
normal! zo
133
normal! zo
141
normal! zo
143
normal! zo
143
normal! zo
143
normal! zo
143
normal! zo
143
normal! zo
151
normal! zo
153
normal! zo
153
normal! zo
153
normal! zo
153
normal! zo
153
normal! zo
161
normal! zo
163
normal! zo
163
normal! zo
163
normal! zo
163
normal! zo
164
normal! zo
164
normal! zo
164
normal! zo
164
normal! zo
164
normal! zo
169
normal! zo
171
normal! zo
171
normal! zo
171
normal! zo
171
normal! zo
177
normal! zo
179
normal! zo
179
normal! zo
179
normal! zo
179
normal! zo
179
normal! zo
180
normal! zo
187
normal! zo
189
normal! zo
189
normal! zo
189
normal! zo
189
normal! zo
189
normal! zo
190
normal! zo
197
normal! zo
199
normal! zo
199
normal! zo
199
normal! zo
199
normal! zo
199
normal! zo
200
normal! zo
let s:l = 197 - ((28 * winheight(0) + 22) / 44)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
197
normal! 05|
tabnext 1
set stal=1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
