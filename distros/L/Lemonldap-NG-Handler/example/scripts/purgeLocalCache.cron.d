#
# Regular cron jobs for LemonLDAP::NG
#
1 * * * * __APACHEUSER__ [ -x __BINDIR__/purgeLocalCache ] && __BINDIR__/purgeLocalCache
