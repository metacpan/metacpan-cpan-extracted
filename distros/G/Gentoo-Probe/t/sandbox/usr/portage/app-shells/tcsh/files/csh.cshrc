# system-wide csh.cshrc

if (-e /etc/csh.env) then
	source /etc/csh.env
endif

if ($USER == "root") then
	setenv PATH "/bin:/sbin:/usr/bin:/usr/sbin:$ROOTPATH"
	#077 would be more secure, but 022 is generally quite realistic
	umask 022
else
	set path = (/bin /usr/bin $path)
	umask 022
endif

unsetenv ROOTPATH
