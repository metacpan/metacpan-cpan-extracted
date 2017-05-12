alias d 'ls --color'
alias ls 'ls --color=auto'
alias ll 'ls --color -l'

if ($USER == "root") then
	set prompt = "%m %c # "
else
	set prompt = "%m %c $ "
endif

setenv EDITOR /usr/bin/nano
