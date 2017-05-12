#
# Regular cron jobs for LemonLDAP::NG
#
*/10 * * * * __APACHEUSER__ [ -x __BINDIR__/purgeCentralCache ] && __BINDIR__/purgeCentralCache
