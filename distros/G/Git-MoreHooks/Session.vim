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
badd +285 lib/Git/MoreHooks/GitRepoAdmin.pm
badd +1 lib/Git/MoreHooks/CheckCommitBase.pm
badd +6 dist.ini
badd +1 t/CheckIndent-functions.t
badd +238 ../Git-Hooks/lib/Git/Hooks/Notify.pm
badd +234 ../Git-Hooks/lib/Git/Hooks.pm
badd +1039 ../Git-Hooks/lib/Git/Repository/Plugin/GitHooks.pm
badd +1755 ~/.anyenv/envs/plenv/versions/5.28.2/lib/perl5/site_perl/5.28.2/Path/Tiny.pm
badd +1 t/CheckCommitAuthorFromMailmap-load.t
badd +1 t/CheckCommitAuthorFromMailmap-hooks.t
badd +1 lib/Git/MoreHooks/CheckCommitAuthorFromMailmap.pm
badd +1 lib/Git/MoreHooks/CheckIndent.pm
badd +1 lib/Git/MoreHooks/TriggerJenkins.pm
badd +1 .perlcriticrc
badd +11 local/lib/perl5/Git/Hooks.pm
badd +0 lib/Git/MoreHooks/CheckPerl.pm
badd +0 cpanfile
badd +60 t/CheckPerl-functions.t
badd +0 t/CheckPerl-hooks.t
argglobal
%argdel
$argadd t/GitRepoAdmin-load.t
$argadd lib/Git/MoreHooks/GitRepoAdmin.pm
$argadd lib/Git/MoreHooks/CheckCommitBase.pm
set stal=2
edit .perlcriticrc
set splitbelow splitright
wincmd _ | wincmd |
vsplit
wincmd _ | wincmd |
vsplit
2wincmd h
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
wincmd _ | wincmd |
split
2wincmd k
wincmd w
wincmd w
wincmd w
wincmd _ | wincmd |
split
wincmd _ | wincmd |
split
2wincmd k
wincmd w
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe '1resize ' . ((&lines * 18 + 40) / 80)
exe 'vert 1resize ' . ((&columns * 105 + 158) / 317)
exe '2resize ' . ((&lines * 51 + 40) / 80)
exe 'vert 2resize ' . ((&columns * 105 + 158) / 317)
exe '3resize ' . ((&lines * 6 + 40) / 80)
exe 'vert 3resize ' . ((&columns * 105 + 158) / 317)
exe '4resize ' . ((&lines * 1 + 40) / 80)
exe 'vert 4resize ' . ((&columns * 105 + 158) / 317)
exe '5resize ' . ((&lines * 1 + 40) / 80)
exe 'vert 5resize ' . ((&columns * 105 + 158) / 317)
exe '6resize ' . ((&lines * 73 + 40) / 80)
exe 'vert 6resize ' . ((&columns * 105 + 158) / 317)
exe '7resize ' . ((&lines * 20 + 40) / 80)
exe 'vert 7resize ' . ((&columns * 105 + 158) / 317)
exe '8resize ' . ((&lines * 54 + 40) / 80)
exe 'vert 8resize ' . ((&columns * 105 + 158) / 317)
exe '9resize ' . ((&lines * 1 + 40) / 80)
exe 'vert 9resize ' . ((&columns * 105 + 158) / 317)
argglobal
if bufexists(".perlcriticrc") | buffer .perlcriticrc | else | edit .perlcriticrc | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 39 - ((14 * winheight(0) + 9) / 18)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
39
normal! 078|
wincmd w
argglobal
if bufexists("dist.ini") | buffer dist.ini | else | edit dist.ini | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 163 - ((50 * winheight(0) + 25) / 51)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
163
normal! 015|
wincmd w
argglobal
if bufexists("t/GitRepoAdmin-load.t") | buffer t/GitRepoAdmin-load.t | else | edit t/GitRepoAdmin-load.t | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 3 - ((0 * winheight(0) + 3) / 6)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
3
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
let s:l = 27 - ((0 * winheight(0) + 0) / 1)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
27
normal! 04|
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
let s:l = 170 - ((0 * winheight(0) + 0) / 1)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
170
normal! 05|
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
let s:l = 132 - ((1 * winheight(0) + 36) / 73)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
132
normal! 0
wincmd w
argglobal
3argu
if bufexists("lib/Git/MoreHooks/CheckIndent.pm") | buffer lib/Git/MoreHooks/CheckIndent.pm | else | edit lib/Git/MoreHooks/CheckIndent.pm | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 7 - ((4 * winheight(0) + 10) / 20)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
7
normal! 0
wincmd w
argglobal
3argu
if bufexists("lib/Git/MoreHooks/TriggerJenkins.pm") | buffer lib/Git/MoreHooks/TriggerJenkins.pm | else | edit lib/Git/MoreHooks/TriggerJenkins.pm | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 220 - ((25 * winheight(0) + 27) / 54)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
220
normal! 022|
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
let s:l = 1 - ((0 * winheight(0) + 0) / 1)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1
normal! 0
wincmd w
exe '1resize ' . ((&lines * 18 + 40) / 80)
exe 'vert 1resize ' . ((&columns * 105 + 158) / 317)
exe '2resize ' . ((&lines * 51 + 40) / 80)
exe 'vert 2resize ' . ((&columns * 105 + 158) / 317)
exe '3resize ' . ((&lines * 6 + 40) / 80)
exe 'vert 3resize ' . ((&columns * 105 + 158) / 317)
exe '4resize ' . ((&lines * 1 + 40) / 80)
exe 'vert 4resize ' . ((&columns * 105 + 158) / 317)
exe '5resize ' . ((&lines * 1 + 40) / 80)
exe 'vert 5resize ' . ((&columns * 105 + 158) / 317)
exe '6resize ' . ((&lines * 73 + 40) / 80)
exe 'vert 6resize ' . ((&columns * 105 + 158) / 317)
exe '7resize ' . ((&lines * 20 + 40) / 80)
exe 'vert 7resize ' . ((&columns * 105 + 158) / 317)
exe '8resize ' . ((&lines * 54 + 40) / 80)
exe 'vert 8resize ' . ((&columns * 105 + 158) / 317)
exe '9resize ' . ((&lines * 1 + 40) / 80)
exe 'vert 9resize ' . ((&columns * 105 + 158) / 317)
tabedit t/CheckPerl-functions.t
set splitbelow splitright
wincmd _ | wincmd |
vsplit
wincmd _ | wincmd |
vsplit
2wincmd h
wincmd _ | wincmd |
split
wincmd _ | wincmd |
split
2wincmd k
wincmd w
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
exe '1resize ' . ((&lines * 38 + 40) / 80)
exe 'vert 1resize ' . ((&columns * 78 + 158) / 317)
exe '2resize ' . ((&lines * 19 + 40) / 80)
exe 'vert 2resize ' . ((&columns * 78 + 158) / 317)
exe '3resize ' . ((&lines * 18 + 40) / 80)
exe 'vert 3resize ' . ((&columns * 78 + 158) / 317)
exe 'vert 4resize ' . ((&columns * 119 + 158) / 317)
exe '5resize ' . ((&lines * 18 + 40) / 80)
exe 'vert 5resize ' . ((&columns * 118 + 158) / 317)
exe '6resize ' . ((&lines * 58 + 40) / 80)
exe 'vert 6resize ' . ((&columns * 118 + 158) / 317)
argglobal
2argu
if bufexists("t/CheckPerl-functions.t") | buffer t/CheckPerl-functions.t | else | edit t/CheckPerl-functions.t | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 60 - ((14 * winheight(0) + 19) / 38)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
60
normal! 0
wincmd w
argglobal
2argu
if bufexists("t/CheckPerl-hooks.t") | buffer t/CheckPerl-hooks.t | else | edit t/CheckPerl-hooks.t | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 13 - ((12 * winheight(0) + 9) / 19)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
13
normal! 0
wincmd w
argglobal
2argu
if bufexists("cpanfile") | buffer cpanfile | else | edit cpanfile | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 1 - ((0 * winheight(0) + 9) / 18)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1
normal! 039|
wincmd w
argglobal
2argu
if bufexists("lib/Git/MoreHooks/CheckPerl.pm") | buffer lib/Git/MoreHooks/CheckPerl.pm | else | edit lib/Git/MoreHooks/CheckPerl.pm | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 372 - ((12 * winheight(0) + 38) / 77)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
372
normal! 015|
wincmd w
argglobal
2argu
if bufexists("lib/Git/MoreHooks/CheckPerl.pm") | buffer lib/Git/MoreHooks/CheckPerl.pm | else | edit lib/Git/MoreHooks/CheckPerl.pm | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 289 - ((11 * winheight(0) + 9) / 18)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
289
normal! 0
wincmd w
argglobal
2argu
if bufexists("lib/Git/MoreHooks/CheckPerl.pm") | buffer lib/Git/MoreHooks/CheckPerl.pm | else | edit lib/Git/MoreHooks/CheckPerl.pm | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 508 - ((35 * winheight(0) + 29) / 58)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
508
normal! 013|
wincmd w
exe '1resize ' . ((&lines * 38 + 40) / 80)
exe 'vert 1resize ' . ((&columns * 78 + 158) / 317)
exe '2resize ' . ((&lines * 19 + 40) / 80)
exe 'vert 2resize ' . ((&columns * 78 + 158) / 317)
exe '3resize ' . ((&lines * 18 + 40) / 80)
exe 'vert 3resize ' . ((&columns * 78 + 158) / 317)
exe 'vert 4resize ' . ((&columns * 119 + 158) / 317)
exe '5resize ' . ((&lines * 18 + 40) / 80)
exe 'vert 5resize ' . ((&columns * 118 + 158) / 317)
exe '6resize ' . ((&lines * 58 + 40) / 80)
exe 'vert 6resize ' . ((&columns * 118 + 158) / 317)
tabedit lib/Git/MoreHooks/CheckCommitAuthorFromMailmap.pm
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
if bufexists("lib/Git/MoreHooks/CheckCommitAuthorFromMailmap.pm") | buffer lib/Git/MoreHooks/CheckCommitAuthorFromMailmap.pm | else | edit lib/Git/MoreHooks/CheckCommitAuthorFromMailmap.pm | endif
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 284 - ((42 * winheight(0) + 38) / 77)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
284
normal! 075|
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
let s:l = 160 - ((68 * winheight(0) + 38) / 77)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
160
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
let s:l = 164 - ((72 * winheight(0) + 38) / 77)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
164
normal! 05|
wincmd w
exe 'vert 1resize ' . ((&columns * 158 + 158) / 317)
exe 'vert 2resize ' . ((&columns * 158 + 158) / 317)
tabnext 3
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
