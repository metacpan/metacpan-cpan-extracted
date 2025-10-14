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

 - Provide branch, old hash, new hash, and common parent "fork" commit hash to pre-write hook and post-write hook args.
   * This fork hash can be used for debugging
   * or for callback webhook.
   * In order to facilitate the InterProcessCommunication between the pre-write and post-write, information should be stored in $IPC/info.txt until the post-write completes.

 - Make a commandline configuration helper checker utility that verifies the git server configurations:
   * XXX - Can we overload the "git-server" command to use -t STDIN to detect commandline TTY?
   * Scripts and hooks installations
   * Secured ~/.ssh/authorized_keys format, including "KEY" settings
   * Files and Directories chmod permissions
   * ADMIN and ACL Management
   * List / Create / Remove repos
   * SSHD Settings
     1. "AcceptEnv XMODIFIERS" in case they want
          to allow "--server-option" and/or "--push-option" and/or "-o" to have
          $GIT_OPTION_COUNT and $GIT_OPTION_{NUM} to be available during pre-* hooks
          or "git-deploy --max-delay <seconds>" for custom push notification timeout
          or "git-client -O <name=val>"
          or other DEBUG features
     2. "AllowAgentForwarding yes" for proxy.url two-way auto-sync feature
     3. "ExposeAuthInfo yes" to allow hooks to obtain public key info, if desired

 - Pull out the iotrace utility into its own perl module IO::Trace.

 - Convert git-client to use Getopt::Long instead of manually parsing @ARGV.

 - Fix git-deploy to handle split cheese case where git server uses both IPv4 and IPv6.

 - Add Support for HTTP protocol git read and write operations using Basic password Authorization (instead of only pubkeys over SSH protocol).

 - Set REMOTE_ADDR env (from SSH_CONNECTION) to make it easier for any hooks to determine Client IP regardless of protocol.

 - Set REMOTE_USER env (from KEY) to make it easier for any hooks to Client User regardless of protocol.

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
