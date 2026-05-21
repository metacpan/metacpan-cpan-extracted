TODO
====

Some features we need or want, plus some neat ideas that may not be too feasible to implement.

 - Sometimes, it's hard to discern which repo run-git-hooks is involved with, so it ought to update its proctitle to be something more useful. Right now, it can look something less useful like this:
    git      3629420  0.9  0.0  36348  7104 ?        Ss   03:49   0:00  |       \_ /usr/bin/perl /usr/src/git-server/hooks/run-git-hooks -c git-upload-pack '/home/git/repo'
    git      3629917  1.0  0.0  29868  6532 ?        S    03:49   0:00  |           \_ /usr/bin/perl /usr/src/git-server/hooks/pre-read
    git      3629935  0.0  0.0  26328  5116 ?        S    03:49   0:00  |               \_ /usr/bin/perl /usr/src/git-server/hooks/configs
    git      3629939  2.5  0.1  33276  7972 ?        S    03:49   0:00  |                   \_ /usr/bin/perl /home/git/bin/git config --list --null
    git      3630007  6.0  0.1  33164  7956 ?        S    03:49   0:00  |                       \_ /usr/bin/perl /usr/local/bin/git config --list --local --show-origin --null

 - The pre-receive hook ought to default to BLOCK any changes if not running through git-server correctly.

 - If proxy fails with the default Forwarding Agent, try each public key individually to see if any of them work any better. (-i PUB -o IdentitiesOnly=yes? Cache winning reader PUBs? Brick over reader PUB with known writer PUBs?).

 - Investigate new feature like proxy.readonly to be used as Read-Only remote sync, instead of the normal proxy.url Two-Way syncr. This can help with setting up a load balancing cluster of git servers, particularly when used for large deployment systems, which only need read-only access anyways. This can also help when trying to sync with remote repo with read-only access is all that is available, such as a simple public HTTP sytle git URL. Writes directly to the remote proxy.readonly will be synced to the local repo, but not vice versa, so writes to the local repo will not attempt to be pushed to the proxy.readonly remote.

 - Right now, if proxy.url detects remote [there] changes, then the local [here] repo is updated accordingly, even if connected with acl.readers or acl.deploy rights, and no {operation} "push" webhook is fired off and the push-notification is not triggered. This is definitely bad because the git-deploy clients will not be notified right away, as expected, so they will need to wait upto --max-delay seconds. This may also pose a security problem as these updates can bypass hooks and triggers. And this should be BLOCKED if {remote_user} does not have acl.writers permissions. If {remote_user} does have acl.writers permissions, then an appropriate {operation} "push" webhook, (with {refs} including all commits updated), ought to be fired off, either instead of or in addition to the original "push" or "pull" {operation} that triggered this Proxy Sync. And the push-notification should be triggered. Then local [here] proxy sync changes can behave more like any normal "push" without any cheater bypassing. Maybe this can be implemented with hooks/pre-receive to verify REMOTE_USER has acl.writers. Will pre-receive be hooked properly for these imported changes pushed from the .workingdir? Or maybe hooks/proxy can snapshot the REMOTE_USER permissions prior to jumping into the .workingdir, then BLOCK local changes if REMOTE_USER doesn't have acl.writers permissions. Or maybe both hooks/pre-receive and hooks/proxy? I'm hoping to avoid having to double SSH back to ssh://$USER@$SERVER_ADDR/repo using the SSH_AUTH_SOCK with "skip_proxy" to avoid infinite recursion, but maybe that's another way to implement it to really ensure all the "push" hooks are caught appropriately.

 - Add [log.verbosity] 0 or 1 or 2 feature to control level of messaging spewage to the git client.

 - Trying to do "git config --descent { --unset <name> | --add <name> <value> }" doesn't work as expected.

 - Investigate converting get_fork_hash common fork sniffer scan to use "git merge-base --fork-point <ref> <commit>" instead of grinding through the logs.

 - Add git-deploy --insecure option to avoid choking with "The authenticity of host can't be established" when running "git fetch" the first time. Use StrictHostKeyChecking=no method instead of sloppy keyscan method. Deprecate --fix-nasty option in favor of new --insecure functionality to encompass both cases.

 - Make git-deploy remove temp files eariler so they won't exist during long waits for a push notification. (un~FD_CLOEXEC unlink /dev/fd/3 anonymous handle?)

 - Make git-deploy brick over "local modified" files if the end target version is exactly the same. (git diff HEAD? rebase --autostash?)

 - Make git-deploy --notify be able to signal other git-deploy processes running as another user. (Magic Listen Port? or Sleep w/ Special ProcTitle?).

 - Fix git-deploy to handle split cheese case where git server uses both IPv4 and IPv6. (~/.ssh/config Host $remotehost "AddressFamily" inet(6)?).

 - Add Support for HTTP protocol git read and write operations using Basic password Authorization (instead of only pubkeys over SSH protocol).
   * Design a way to support "git-deploy" feature via HTTP (through REMOTE_USER or DeployToken or URI flag or Special HTTP Header or PAT [Personal Access Token] or maybe some other mechanism). Allow client to specify max-delay seconds (default 90) in case nothing new is ready since last pull.

 - Investigate why unsynced proxy.url deletes a tag from the side that has the tag, but it ought to copy to the missing side.

 - Pre-Load GIT_OPTION_<optionname> also since GIT_OPTION_<N> is annoying to spin through every time just to find the option you want.

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

 - Investigate making git-deploy setup alias.deploy hook in case it's not in a cron path.

 - [webhook] features for callback:
   * Allow for WhiteList or BlackList filters to trigger webhook or ignore webhooks under certain conditions:
     : When a certain operation is performed, i.e., clone|pull|push
     : When specified branches are involved
     : When certain REMOTE_USER is involved
     : When coming from a specific IP or Network CIDR
     : When certain files are affected
     : When certain strings exist in any of the commit comments being pushed.
   * provide failover queue retry mechanism fibinacci backoff until remote webhook server returns 2xx or 3xx status.
   * at least provide when FORCE push destroys branch history
     : common fork point hash
     : list of commits that were destroyed
