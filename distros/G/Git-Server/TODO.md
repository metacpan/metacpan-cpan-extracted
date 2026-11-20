TODO
====

Some features we need or want, plus some neat ideas that may not be too feasible to implement.

 - If proxy fails with the default Forwarding Agent, try each public key individually to see if any of them work any better. (-i PUB -o IdentitiesOnly=yes? Cache winning reader PUBs? Brick over reader PUB with known writer PUBs?).

 - Investigate new feature like proxy.readonly to be used as Read-Only remote sync, instead of the normal proxy.url Two-Way syncr. This can help with setting up a load balancing cluster of git servers, particularly when used for large deployment systems, which only need read-only access anyways. This can also help when trying to sync with remote repo where read-only access is all that is available, such as a simple public HTTP sytle git URL. Writes directly to the remote proxy.readonly will be synced to the local repo, but not vice versa, so writes to the local repo will not attempt to be pushed to the proxy.readonly remote.

 - While using "ssh -o SendEnv=..." seems like a convenient method to transport information, many SSH Servers are now defaulting NOT to AcceptEnv, or it might only work for certain magic variables, i.e., LC_TELEPHONE or LANG, thus "SendEnv" may not work as expected.
   * In case "AcceptEnv GIT_PROTOCOL" is not enabled, the Git Server will downgrade READ operations (using "git-upload-pack") from Git V2 to Git V1 protocol, even if both client and server have newer git 2.x. This is less efficient and causes loss of functionality.
   * In case "AcceptEnv XMODIFIERS" is not enabled, some features may not function correctly between the Git Client and Git Server, especially when git-client or git-deploy is used, so it may help to consider using another transport mechanism instead of relying so much on XMODIFIERS.
   * For example, if LC_TELEPHONE works but XMODIFIERS does not, then git-client can just use "-o SendEnv=LC_TELEPHONE" instead.
   * And if XMODIFIERS works but not GIT_PROTOCOL, then maybe a flag like "protocol=v2" could be injected for read operations (if the client actually has git 2.x) using SendEnv=XMODIFIERS.
   * And if XMODIFIERS really works, then maybe the git version could also be injected, so the server can still see the client version, even for older versions, i.e., "user_agent=git/1.7.1".
   * Hopefully "git-verify" can detect the capabilities of its SSHD server properly, such as which "AcceptEnv" variables are honored, if any. The unprivileged user hosting the git server likely won't have Super User access enough to read the sshd_config in order to scan which AcceptEnv variables ought to work, such as LC_TELEPHONE or LANG, so a localhost SSH connection can be used to probe some hard-coded common names.
   * The Git Server user can store a cache to configure which magic Env to use instead, in case GIT_PROTOCOL is disabled. (For example, as the Git User on the Git Server: "git config --global core.UseAcceptEnvVar LC_TIME,XMODIFIERS")
   * And/Or the Git Client could cache which Env is safe to use via SendEnv transport with that Git Server. (On the git client side: "git config --local remote.$origin.UseSendEnvVar LANG,GIT_PROTOCOL")
   * On git >= 2.18, the GIT_USER_AGENT variable is transported via Git Protocol V2 (regardless of AcceptEnv support) for WRITE operations, (like "git push"). I'm not sure how much info can be augmented into GIT_USER_AGENT but this could be more reliable than just using XMODIFIERS.
   * Unfortunately, IF "AcceptEnv GIT_PROTOCOL" isn't enabled on the Git Server, even augmenting GIT_USER_AGENT still won't help transport anything when it comes to READ operations, (like "git fetch").
   * If there were some way to detect that the Git Server was capable of supporting Git Protocol V2 even though SendEnv=GIT_PROTOCOL won't work, then it could be flagged. (On the git client side: git config --local --bool remote.$origin.AlternateV2TransportSupported true)
   * If this special "Alt" flag is set AND the Git Client really supports V2, then the git client could signal the server somehow.
     o If the server can detect this flag, then this may present a solution to all SendEnv problems by simply augmenting this more-flexible Protocol V2.
     o Maybe the "git-client" wrapper could use a special GIT_SSH_COMMAND or GIT_SSH setting.
     o Maybe by munging "git-upload-pack" to "git-upload-pack-ForceV2" or by sending some special commandline param.
     o However, it would be preferable to signal the Git Server using some slightly alternate format, but that won't BREAK other NON-Git-Server repos without the AltForceV2 support.
     o If SendEnv=GIT_PROTOCOL doesn't work AND either the Client or Server can't speak Git Protocol V2, then it's probably okay to just let it go untouched. If such a crusty old git version 1.x is being used, then a bunch of features are already missing anyways, so going through too much extra work just to handle this rare case is probably not worth the effort.

 - The {client_git_version} does not include the actual git client version in several cases:
   * Older git clients, regardless of operation. The "agent" feature wasn't introduced until git 1.8.5 but was backported to 1.8.3.1 on RHEL.
   * For read operations (using "git-upload-pack") if SSHD doesn't have "AcceptEnv GIT_PROTOCOL" enabled and no "want" refs are requested.
   * For empty "Everything up-to-date" push operations when nothing is actually pushed, regardless of git version.

 - Add [log.verbosity] 0 or 1 or 2 feature to control level of messaging spewage to the git client.

 - It would be nice if log.logfile could log more details about the client in case of ACL permission failures. Right now it just says "ACL pre-failure" but no {client_git_version}, no {server_git_version}, no {repo}, no {git_client_options}, no attempted {pull_branch}. (Would it help to run a dummy git emulator? Just spit back something like "0015agent=git/2.43.7\n0000" and quickly slurp in whatever the client says without allowing much blocking and without actually performing any of the requested operations.)

 - Trying to do "git config --descent { --unset <name> | --add <name> <value> }" doesn't work as expected.

 - On older git prior to 1.7.2, having --descent .gitconfig files causes "Unknown option: -c" crashes from git-client. Consider converting "git -c ..." to GIT_CONFIG_PARAMETERS. It might be ignored on older git versions, but at least it won't crash.

 - On older git prior to 1.7.4, having --descent .gitconfig files causes "error: unknown option `local'" crashes from git-client. Consider using the deprecated GIT_CONFIG_NOGLOBAL setting.

 - Investigate converting get_fork_hash common fork sniffer scan to use "git merge-base --fork-point <ref> <commit>" instead of grinding through the logs.

 - Add git-deploy --insecure option to avoid choking with "The authenticity of host can't be established" when running "git fetch" the first time. Use StrictHostKeyChecking=no method instead of sloppy keyscan method. Deprecate --fix-nasty option in favor of new --insecure functionality to encompass both cases.

 - Make git-deploy remove temp files eariler so they won't exist during long waits for a push notification. (un~FD_CLOEXEC unlink /dev/fd/3 anonymous handle?)

 - Make git-deploy handle deploying "locally modified" files by retaining the changes if not conflicting with upstream changes. (git diff HEAD? rebase --autostash?)

 - Make git-deploy gracefully brick over pre-born files that already exist if the end target version is exactly the same. (git diff HEAD? git reset? rm -f?)

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
