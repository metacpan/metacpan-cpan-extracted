#
# Regular cron jobs for LemonLDAP::NG Portal
#
7 *	* * *	__APACHEUSER__	[ -x __BINDIR__/purgeCentralCache ] && __BINDIR__/purgeCentralCache
