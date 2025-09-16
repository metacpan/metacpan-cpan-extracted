TODO
====

Some features we need or want, plus some neat ideas that may not be too feasible to implement.

 - Once "post" method is sure to run, then move logger step from "pre" to "post".

 - Make sure ipc-parse can determine if action was actually performed or else the reason of why not.

 - Add [log.verbosity] 0 or 1 or 2 feature to control level of messaging spewage to the git client.

 - Investigate converting get_fork_hash common fork sniffer scan to use "git merge-base --fork-point <ref> <commit>" instead of grinding through the logs.

 - Provide branch, old hash, and new hash (for every branch updated by the git client) to post-read hook args (Requires man-in-the-middle sniffer)
   * If nothing is updated to the client, then there will be no arguments to post-read.
   * There will be a multiple of 3 args, each triple being branch, old hash, new hash, (depending on how many branches the client updates).
   * In order to facilitate the InterProcessCommunication to post-read, information should be stored in $IPC/info.txt until the post-read completes.

 - Provide branch, old hash, new hash, and common parent "fork" commit hash to pre-write hook and post-write hook args. (Requires man-in-the-middle sniffer)
   * This fork hash can be used for debugging
   * or for callback webhook.
   * In order to facilitate the InterProcessCommunication between the pre-write and post-write, information should be stored in $IPC/info.txt until the post-write completes.

 - Fix git-deploy to handle split cheese case where git server uses both IPv4 and IPv6.

 - Add Support for HTTP protocol git read and write operations using Basic password Authorization (instead of only pubkeys over SSH protocol).

 - Integrate or convert to be compatible with Git::Hooks::* plugins.

 - Monkey the core.hooksPath setting on the git server to point to these hooks provided.

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
