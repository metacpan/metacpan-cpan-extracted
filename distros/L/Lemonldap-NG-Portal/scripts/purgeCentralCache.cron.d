#
# Regular cron jobs for LemonLDAP::NG Portal
#
7 *	* * *	__APACHEUSER__	[ -x __BINDIR__/purgeCentralCache ] && if [ ! -d /run/systemd/system ]; then __BINDIR__/purgeCentralCache; fi
