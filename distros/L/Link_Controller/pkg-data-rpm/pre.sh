#we setup the link controller user.  RPM will then create the appropriate 
#other files as created during the setup

#N.B. these should be the same as is i in default-install.pl
LC_USER=linkcont
LC_GROUP=$LC_USER
LC_DIR_INSTALL=/var/lib/linkcontroller

groupadd -rf $LC_GROUP

if ! egrep -q '^linkcont:' /etc/passwd
then
    useradd -c 'LinkController service' -d $LC_DIR_INSTALL -M -r -g $LC_GROUP\
	   -s /bin/bash $LC_USER 
fi
