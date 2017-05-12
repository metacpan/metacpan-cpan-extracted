# Gentoo example csh .cshrc file

# some simple aliases
alias h		history 25				# use `h` to show the last 25 commands
alias j		jobs -l					# use `j` to list the background/stopped jobs
alias ls	ls -F --color=auto		# alias `ls` to show nice colours.
alias la	ls -a					# \
alias lf	ls -FA					#  > some shortcuts to common ls options
alias ll	ls -lA					# /

# you can override environment variables from /etc/csh.env from here
setenv	EDITOR	vim
setenv	VISUAL	${EDITOR}
setenv	EXINIT	'set autoindent'
setenv	PAGER	less

# make sure there is something sane in $PATH
if ( ! $?PATH ) then
	set path = (~/bin /bin /sbin /usr/{bin,sbin,X11R6/bin,pkg/{,s}bin,games} /usr/local/{,s}bin)
endif

# some options you might want in an interactive shell
if ($?prompt) then
	set filec						# use <ESC><ESC> to complete on filenames.
	set history = 1000				# remember last 1000 commands
	set ignoreeof					# dont exit if ^D is hit by accident
	set mail = (/var/mail/$USER)	# where is your user mbox?
	set mch = `hostname -s`			# display short hostname in prompt.
	set unm = `whoami`				# your username
	
	# some example csh prompts, choose one you like.
	#set prompt = "% "					# csh default, simple.
	#set prompt = "${mch:q}: {\!} "		# NetBSD example prompt, shows hostname and history reference
	set prompt = "${unm:q}@${mch:q}% "	# similar to Gentoo default.
	
	# try this to get pwd in your prompt.
	#set prompt = "${unm:q}@${mch:q}:\!:`pwd`% "
	#alias cd	'cd \!*;set prompt = "${unm:q}@${mch:q}:\!:`pwd`% "'
	
	
	umask 0022						# set your user's umask.
endif
