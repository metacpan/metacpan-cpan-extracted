#
# Regular cron jobs for LemonLDAP::NG Handler
#
1 *	* * *	__APACHEUSER__	[ -x __BINDIR__/purgeLocalCache ] && if [ ! -d /run/systemd/system ]; then __BINDIR__/purgeLocalCache; fi
