TODO
====

Some features we need or want, plus some neat ideas that may not be too feasible to implement.

 - If proxy fails with the default Forwarding Agent, try each public key individually to see if any of them work any better. (-i PUB -o IdentitiesOnly=yes? Cache winning reader PUBs? Brick over reader PUB with known writer PUBs?).

 - Investigate new feature like proxy.readonly to be used as Read-Only remote sync, instead of the normal proxy.url Two-Way syncr. This can help with setting up a load balancing cluster of git servers, particularly when used for large deployment systems, which only need read-only access anyways. This can also help when trying to sync with remote repo where read-only access is all that is available, such as a simple public HTTP sytle git URL. Writes directly to the remote proxy.readonly will be synced to the local repo, but not vice versa, so writes to the local repo will not attempt to be pushed to the proxy.readonly remote.

 - Many SSH Servers are now defaulting NOT to AcceptEnv. So in case there isn't sufficient support, the SSH Client will fail with SendEnv. So consider using another transport mechanism instead of relying so much on XMODIFIERS. (On git >= 2.18, the GIT_USER_AGENT variable is provided via Git Protocol V2 and should be more reliable than XMODIFIERS for git-client or git-deploy to use, but I'm not sure how much information could even fit in there.)

 - Instead of relying on SendEnv, git-verify should also use another mechanism to test the configuration. (Maybe another special commandline arg instead of relying on SendEnv?)

 - The {client_git_version} does not include the actual git client version during most read operations if SSHD on the Git Server Host does not have "AcceptEnv GIT_PROTOCOL" enabled.

 - The {client_git_version} does not include the actual git client version when an empty "git push" is run without actually pushing any changes.

 - Add [log.verbosity] 0 or 1 or 2 feature to control level of messaging spewage to the git client.

 - It would be nice if log.logfile could log more details about the client in case of ACL permission failures. Right now it just says "ACL pre-failure" but no {client_git_version}, no {server_git_version}, no {repo}, no {git_client_options}, no attempted {pull_branch}. (Would it help to run a dummy git emulator? Just spit back something like "0015agent=git/2.43.7\n0000" and quickly slurp in whatever the client says without allowing much blocking and without actually performing any of the requested operations.)

 - Trying to do "git config --descent { --unset <name> | --add <name> <value> }" doesn't work as expected.

 - Investigate converting get_fork_hash common fork sniffer scan to use "git merge-base --fork-point <ref> <commit>" instead of grinding through the logs.

 - Add git-deploy --insecure option to avoid choking with "The authenticity of host can't be established" when running "git fetch" the first time. Use StrictHostKeyChecking=no method instead of sloppy keyscan method. Deprecate --fix-nasty option in favor of new --insecure functionality to encompass both cases.

 - Make git-deploy remove temp files eariler so they won't exist during long waits for a push notification. (un~FD_CLOEXEC unlink /dev/fd/3 anonymous handle?)

 - Make git-deploy brick over "local modified" files if the end target version is exactly the same. (git diff HEAD? rebase --autostash?)

 - Make git-deploy --notify be able to signal other git-deploy processes running as another user. (Magic Listen Port? or Sleep w/ Special ProcTitle?).

 - Fix git-deploy to handle split cheese case where git server uses both IPv4 and IPv6. (~/.ssh/config Host $remotehost "AddressFamily" inet(6)?).

 - Add Support for HTTP protocol git read and write operations using Basic password Authorization (instead of only pubkeys over SSH protocol).
   * Design a way to support "git-deploy" feature via HTTP (through REMOTE_USER or DeployToken or URI flag or Special HTTP Header or PAT [Personal Access Token] or maybe some other mechanism). Allow client to specify max-delay seconds (default 90) in case nothing new is ready since last pull.

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

 - [webhook] features for callback:
   * Allow for WhiteList or BlackList filters to trigger webhook or ignore webhooks under certain conditions:
     : When specified branches are involved
     : When certain REMOTE_USER is involved
     : When coming from a specific IP or Network CIDR
     : When certain files are affected
     : When certain strings exist in any of the commit comments being pushed.
   * provide failover queue retry mechanism fibinacci backoff until remote webhook server returns 2xx or 3xx status.
   * at least provide when FORCE push destroys branch history
     : common fork point hash
     : list of commits that were destroyed
