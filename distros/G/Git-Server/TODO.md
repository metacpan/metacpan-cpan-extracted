TODO
====

Some features we need or want, plus some neat ideas that may not be too feasible to implement.

 - Make sure ipc-parse can determine if action was actually performed or else the reason of why not.

 - Add [log.verbosity] 0 or 1 or 2 feature to control level of messaging spewage to the git client.

 - Trying to do "git config --descent { --unset <name> | --add <name> <value> }" doesn't work as expected.

 - Investigate converting get_fork_hash common fork sniffer scan to use "git merge-base --fork-point <ref> <commit>" instead of grinding through the logs.

 - Fix git-deploy to handle split cheese case where git server uses both IPv4 and IPv6.

 - Add Support for HTTP protocol git read and write operations using Basic password Authorization (instead of only pubkeys over SSH protocol).
   * Design a way to support "git-deploy" feature via HTTP (through REMOTE_USER or DeployToken or URI flag or Special HTTP Header or PAT [Personal Access Token] or maybe some other mechanism). Allow client to specify max-delay seconds (default 90) in case nothing new is ready since last pull.

 - Integrate or convert to be compatible with Git::Hooks::* plugins.

 - Augment Git::Hooks (maybe Git::Hooks::Server) to provide extra functionality
   * Add Drivers to implement missing capabilities required
     1. GITHOOKS_PRE_READ    / PRE_READ
     2. GITHOOKS_PRE_WRITE   / PRE_WRITE
     3. GITHOOKS_POST_READ   / POST_READ
     4. GITHOOKS_POST_WRITE  / POST_WRITE
   * Use same general compatible [githooks] syntax
     1. git config --list | grep 'githooks\.plugin'
     2. git config --add githooks.plugin WebHook
     3. git config --add githooks."webhook".callbackurl https://website.com/post.cgi
   * Use the same general githooks.pl format like: run_hook($0, @ARGV);
   * Provide a seemless way to transport information between hooks.
     1. For example, the ability to export ENV variables from a PRE* hook to a POST* hook.
     2. Allow data in $git->stash to persist among all hooks where the $git object is the first argument passed to each custom block hook.

 - Monkey the core.hooksPath setting on the git server to point to these hooks provided.

 - Investigate making git-deploy setup alias.deploy hook in case it's not in a cron path.

 - [webhook] features for callback:
   * Allow for WhiteList or BlackList filters to trigger webhook or ignore webhooks under certain conditions:
     : When specified branches are involved
     : When certain KEY users are involved
     : When coming from a specific IP or Network CIDR
     : When certain files are affected (tricky for pull reads)
     : When certain strings exist in any of the commit comments being pushed. (Tricky for pull reads.)
   * provide failover queue retry mechanism fibinacci backoff until remote webhook server returns 2xx or 3xx status.
   * at least provide when FORCE push destroys branch history
     : common fork point hash
     : list of commits that were destroyed
