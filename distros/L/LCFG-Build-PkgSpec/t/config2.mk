COMP=foo
NAME=lcfg-foo
DESCR=An lcfg component to manage the foo daemon
V=1.0.0
R=1
SCHEMA=1
VERSION=$(V)
GROUP=LCFG/System
AUTHOR=Stephen Quinney <squinney@inf.ed.ac.uk>
PLATFORMS=Fedora5, Fedora6, ScientificLinux5

MANDIR=$(LCFGMAN)/man$(MANSECT)
CONFDIR=$(LCFGCONF)/$(COMP)
SCRIPTDIR=$(LCFGDATA)/$(COMP)/scripts
PERLMODDIR=$(LCFGPERL)/LCFG/Web

TEMPLATE_CACHE=/var/cache/lcfgweb/tt

WEBBASE=http://www.lcfg.org
CVSWEBURL=http://cvs.inf.ed.ac.uk/cgi-bin/cvsweb.cgi
SERVER_RSYNC=rsync.lcfg.org
BASE_RSYNC=::lcfgreleases

RSYNC=/usr/bin/rsync
RSYNC_OPTIONS="--recursive --links --times"
RPMBUILD=/usr/bin/rpmbuild

DATE=02/10/07 17:37
