# ENVY_VERSION must be set before the shell is initialized.
# This variable is set by envy.

if ($?ENVY_VERSION) then

# probably can use backticks with source? XXX

alias module 'envy.pl -csh \!* > /tmp/tmp.$$; source /tmp/tmp.$$; /bin/rm /tmp/tmp.$$; echo Type envy instead of module '
alias envy 'envy.pl -csh \!* > /tmp/t$$; source /tmp/t$$; /bin/rm -f /tmp/t$$'
alias unenvy 'envy.pl -un -csh \!* > /tmp/t$$; source /tmp/t$$; /bin/rm -f /tmp/t$$'

set filec
set history=500
set ignoreeof
set savehist=200
set time=15

alias f 'find . -name \*\!*\* -print'
alias h 'history | tail -20'
alias ls 'ls -F'
alias psg 'ps -ef | grep \!*'

set prompt = "`uname -n`:`whoami`:`pwd`< \! >% "
alias cd        'chdir \!* ; set prompt = "`uname -n`:`whoami`:`pwd`< \! >% "'

set f=$ETOP/etc/login/cshrc.site; /bin/test -f $f && source $f
set f=$HOME/.custom/cshrc; /bin/test -f $f && source $f

endif
