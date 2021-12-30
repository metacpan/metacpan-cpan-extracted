let SessionLoad = 1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/other/own_github/git-morehooks
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +1 t/GitRepoAdmin-load.t
badd +177 lib/Git/MoreHooks/GitRepoAdmin.pm
badd +0 lib/Git/MoreHooks/CheckCommitBase.pm
badd +6 dist.ini
badd +0 t/CheckIndent-functions.t
badd +238 ../Git-Hooks/lib/Git/Hooks/Notify.pm
badd +234 ../Git-Hooks/lib/Git/Hooks.pm
badd +1039 ../Git-Hooks/lib/Git/Repository/Plugin/GitHooks.pm
badd +1755 ~/.anyenv/envs/plenv/versions/5.28.2/lib/perl5/site_perl/5.28.2/Path/Tiny.pm
badd +0 t/CheckCommitAuthorFromMailmap-load.t
badd +118 t/CheckCommitAuthorFromMailmap-hooks.t
argglobal
%argdel
$argadd t/GitRepoAdmin-load.t
$argadd lib/Git/MoreHooks/GitRepoAdmin.pm
$argadd lib/Git/MoreHooks/CheckCommitBase.pm
set stal=2
edit t/GitRepoAdmin-load.t
set splitbelow splitright
wincmd _ | wincmd |
vsplit
wincmd _ | wincmd |
vsplit
2wincmd h
wincmd w
wincmd _ | wincmd |
split
wincmd _ | wincmd |
split
2wincmd k
wincmd w
wincmd w
wincmd w
wincmd _ | wincmd |
split
1wincmd k
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 105 + 158) / 317)
exe '2resize ' . ((&lines * 1 + 40) / 81)
exe 'vert 2resize ' . ((&columns * 105 + 158) / 317)
exe '3resize ' . ((&lines * 1 + 40) / 81)
exe 'vert 3resize ' . ((&columns * 105 + 158) / 317)
exe '4resize ' . ((&lines * 75 + 40) / 81)
exe 'vert 4resize ' . ((&columns * 105 + 158) / 317)
exe '5resize ' . ((&lines * 77 + 40) / 81)
exe 'vert 5resize ' . ((&columns * 105 + 158) / 317)
exe '6resize ' . ((&lines * 1 + 40) / 81)
exe 'vert 6resize ' . ((&columns * 105 + 158) / 317)
argglobal
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 6 - ((5 * winheight(0) + 39) / 79)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
6
normal! 02|
wincmd w
argglobal
2argu
if bufexists("t/CheckIndent-functions.t") | buffer t/CheckIndent-functions.t | else | edit t/CheckIndent-functions.t | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 30 - ((0 * winheight(0) + 0) / 1)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
30
normal! 0
wincmd w
argglobal
2argu
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 173 - ((0 * winheight(0) + 0) / 1)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
173
normal! 09|
wincmd w
argglobal
2argu
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 179 - ((44 * winheight(0) + 37) / 75)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
179
normal! 05|
wincmd w
argglobal
3argu
if bufexists("lib/Git/MoreHooks/GitRepoAdmin.pm") | buffer lib/Git/MoreHooks/GitRepoAdmin.pm | else | edit lib/Git/MoreHooks/GitRepoAdmin.pm | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 340 - ((61 * winheight(0) + 38) / 77)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
340
normal! 0
wincmd w
argglobal
3argu
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 66 - ((0 * winheight(0) + 0) / 1)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
66
normal! 06|
wincmd w
exe 'vert 1resize ' . ((&columns * 105 + 158) / 317)
exe '2resize ' . ((&lines * 1 + 40) / 81)
exe 'vert 2resize ' . ((&columns * 105 + 158) / 317)
exe '3resize ' . ((&lines * 1 + 40) / 81)
exe 'vert 3resize ' . ((&columns * 105 + 158) / 317)
exe '4resize ' . ((&lines * 75 + 40) / 81)
exe 'vert 4resize ' . ((&columns * 105 + 158) / 317)
exe '5resize ' . ((&lines * 77 + 40) / 81)
exe 'vert 5resize ' . ((&columns * 105 + 158) / 317)
exe '6resize ' . ((&lines * 1 + 40) / 81)
exe 'vert 6resize ' . ((&columns * 105 + 158) / 317)
tabedit t/CheckCommitAuthorFromMailmap-hooks.t
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 158 + 158) / 317)
exe 'vert 2resize ' . ((&columns * 158 + 158) / 317)
argglobal
1argu
if bufexists("t/CheckCommitAuthorFromMailmap-hooks.t") | buffer t/CheckCommitAuthorFromMailmap-hooks.t | else | edit t/CheckCommitAuthorFromMailmap-hooks.t | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 118 - ((77 * winheight(0) + 39) / 78)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
118
normal! 0
wincmd w
argglobal
1argu
if bufexists("t/CheckCommitAuthorFromMailmap-hooks.t") | buffer t/CheckCommitAuthorFromMailmap-hooks.t | else | edit t/CheckCommitAuthorFromMailmap-hooks.t | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 6 - ((5 * winheight(0) + 39) / 78)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
6
normal! 05|
wincmd w
2wincmd w
exe 'vert 1resize ' . ((&columns * 158 + 158) / 317)
exe 'vert 2resize ' . ((&columns * 158 + 158) / 317)
tabnext 2
set stal=1
if exists('s:wipebuf') && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 winminheight=1 winminwidth=1 shortmess=filnxtToOF
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
