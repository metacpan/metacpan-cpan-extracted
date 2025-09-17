# Git::Server

INSTALL
=======

Server Side:
------------

1. Create an unprivileged user for the git server to run as:

```
[admin@gitsrvhost ~]$ sudo useradd git
[admin@gitsrvhost ~]$ sudo su - git
[git@gitsrvhost ~]$
```

2. Download git-server for this user:

```
[git@gitsrvhost ~]$ cd
[git@gitsrvhost ~]$ git clone https://github.com/hookbot/git-server
[git@gitsrvhost ~]$
```

3. Using one of the following methods, setup a repository
for git clients to access on this server:

A. You can create a brand new naked project:

```
[git@gitsrvhost ~]$ git init --initial-branch=main --bare ProjX
Initialized empty Git repository in /home/git/ProjX/
[git@gitsrvhost ~]$
```

B. Or you can migrate an existing project git repository
from a remote server to this server:

```
[git@gitsrvhost ~]$ git clone --bare https://github.com/user/ProjX ProjX
remote[...]
Receiving[...]
[git@gitsrvhost ~]$ cd ProjX
[git@gitsrvhost ProjX]$ git remote rm origin
[git@gitsrvhost ProjX]$ git config proxy.url https://github.com/user/ProjX
[git@gitsrvhost ProjX]$ cd
[git@gitsrvhost ~]$
```

You may want to make sure this "git" user has access
to the proxy.url repo just to be safe:

```
[git@gitsrvhost ~]$ git clone https://github.com/user/ProjX /tmp/ProjX-test
remote[...]
Receiving[...]
[git@gitsrvhost ~]$ cd /tmp/ProjX-test
[git@gitsrvhost ProjX-testt]$ git pull
[git@gitsrvhost ProjX-testt]$ cd
[git@gitsrvhost ~]$ rm -rf /tmp/ProjX-test
[git@gitsrvhost ~]$
```

The git-server will only be able to proxy sync from
remote git repo to local git repo if it has READ access.
If you want two-way sync both directions, then this
"git" user needs to have WRITE access too.

If the remote git repo is SSH and this "git" user doesn't
have SSH client access to the proxy.url, then it will try
to utilize the Agent Forwarding of the real git client
connection in order to reach the remote repo. It can be
tricky for some git clients to setup Agent Forwarding.
Failure to have write access to the proxy.url repo may
cause the repos to become out of sync, so it may not
be the best long-term solution to use the proxy feature.

C. Or if you already have the project checked out locally
on this server, then switch it to bare:

```
[git@gitsrvhost ~]$ git clone --bare /tmp/ProjX ~/ProjX
[git@gitsrvhost ~]$ rm -rfv /tmp/ProjX
[git@gitsrvhost ~]$
```

You can repeat this to create unlimited git repositories
hosted by this server.

4. Authorize Git Clients

Put something like the following on a single line in ~git/.ssh/authorized_keys:

```
command="~/git-server/git-server KEY=user1" ssh-ed25519 AAAA_OAX+blah_pub__ user1@workstation
```

You can add unlimited client users and SSH public keys.

5. HOOKS

By default, the entire "hooks" folder will be symlinked
to utilize these git-server features provided, but you
may symlink it to wherever you wish. For example:

```
[git@gitsrvhost ~]$ cd ProjX
[git@gitsrvhost ProjX]$ mv -v hooks hooks.SAMPLES_OLD
[git@gitsrvhost ProjX]$ ln -s -v ~/git-server/hooks .
[git@gitsrvhost ProjX]$ cd
[git@gitsrvhost ~]$
```

Then configure each git repository with whatever
ACL settings you wish. For example:

```
[admin@gitsrvhost ~]$ sudo su - git
[git@gitsrvhost ~]$ cd ~/ProjX
[git@gitsrvhost ProjX]$ git config acl.readers billy,bob
[git@gitsrvhost ProjX]$ git config acl.writers alice,user1,admin
[git@gitsrvhost ProjX]$ git config acl.deploy push_notification_key1
[git@gitsrvhost ProjX]$ git config acl.restrictemail '@github.com'
[git@gitsrvhost ProjX]$ git config restrictedbranch.'master'.pushers admin
[git@gitsrvhost ProjX]$ git config restrictedbranch.'master'.forcers NOBODY
[git@gitsrvhost ProjX]$ git config restrictedfile.'*Makefile*'.pushers alice
[git@gitsrvhost ProjX]$ git config log.logfile logs/access_log
[git@gitsrvhost ProjX]$ git config log.daily true
[git@gitsrvhost ProjX]$ git config log.rotate 61
[git@gitsrvhost ProjX]$ git config log.compress true
[git@gitsrvhost ProjX]$ git config webhook."https://site.io/op.cgi".method post
[git@gitsrvhost ProjX]$ cd
[git@gitsrvhost ~]$
```


Client Side
===========

1. To utilize the git server, clone a repository:

```
[user1@devbox ~]$ git clone git@gitsrvhost:ProjX
remote[...]
Receiving[...]
[user1@devbox ~]$ cd ProjX
[user1@devbox ProjX]$ git status
[user1@devbox ProjX]$ git log
[user1@devbox ProjX]$
```

2. Optional Wrapper

To use the "git-client" wrapper for improved "-o" support and .gitconfig overrides:

```
[admin@devbox ~]$ sudo wget -N -P /usr/local/bin https://raw.githubusercontent.com/hookbot/git-server/master/git-client
[admin@devbox ~]$ sudo chmod 755 /usr/local/bin/git-client
[admin@devbox ~]$ sudo ln -s -v git-client /usr/local/bin/git
[admin@devbox ~]$
```


Config Directives
=================

On the git server host, make sure you get into the --bare repo
folder of the unprivileged user (created above) before
configuring any directives.

```
[admin@box ~]$ ssh git@gitsrvhost #  OR
[admin@gitsrvhost ~]$ sudo su - git
Last login: [...]
[git@gitsrvhost ~]$ cd ~/ProjX
[git@gitsrvhost ProjX]$ git config --list
```

### acl.readers

Comma-delimited list of KEY settings from ~/.ssh/authorized_keys
for all users you wish to allow read access to the repository.

For example, these users can run: `git pull`

```
git config acl.readers 'jr,leaderboard'
```

### acl.deploy

Comma-delimited list of users who you wish to receive instant
updates immediately after someone pushes a change.
All **deploy** users will also implicitly have **readers** access
since they are required to read from the repository.

For example, these users can run: `git deploy`

```
git config acl.deploy 'deploykeywww1'
```

### acl.writers

Comma-delimited list of users allowed to make changes to the
respository. All **writers** users will implicitly have **readers**
access since they must be able to read in order to make changes.

For example, these users will be able to run: `git push`

```
git config acl.writers 'admin,seniordev'
```

### log.logfile

Optional path to logfile where timestamps and operations and
IP addresses for git server operation will be logged.
Default is to not log anywhere.

```
git config log.logfile 'logs/access_log'
```

### log.rotate

Specify how many log files to keep after rotating the log.
You can set log.rotate "0" to mean unlimited log files.
The default is to keep 10 rotated log files.

```
git config log.rotate 91
```

### log.compress

Specify true or false whether to compress the rotated logfiles.
The default is NO.

```
git config log.compress true
```

### log.daily

Specify to rotate logs every day.
The default is NO.

```
git config log.daily true
```

### log.weekly

Specify to rotate logs every week.
The default is YES unless log.daily is set.

```
git config log.weekly true
```

### acl.restrictemail

Restrict committer user.email address to whitelist specified.
Multiple acceptable emails can be specified in a comma-delimited list.
Or "\*" can be used as wildcard match, like "\*@github\*".
Or you can provide a regular expression in slashes, like "/bob@/".
Default is no restrictions, meaning any email will be allowed.

```
git config acl.restrictemail 'alice@gmail.com,bob@yahoo.com' # Must be either one
  # or
git config acl.restrictemail '*@cpan.org,/billy@*.com/'      # Wildcard or RegExp
```

### acl.restrictip

Restrict read and write access to the IP Address whitelist specified.
The value can be a single IP address or a CIDR network block definition.
Or a comma-delimited list of all networks you wish to allow.
Default is no restrictions, meaning any IP will be allowed to push and pull.

```
git config acl.restrictip '127.0.0.1,10.0.0.0/8,192.168.0.0/16'  # Allow Private Networks
  # or
git config acl.restrictip '2a00:1450:400e:800::/56,96.0.0.0/8'   # Supports both IPv4 and IPv6 CIDR
```

### restrictedbranch.BRANCH.pushers

Specify which branches to block all **writers** from making
changes to unless allowed in the pushers comma-delimited list.
Default is no restrictions, meaning anyone can push to any branch.

```
git config restrictedbranch.'master'.pushers 'alice'           # Only `alice` can make any changes to `master` branch.
git config restrictedbranch.'release/*'.pushers 'bob,qa'       # Only `bob` and `qa` users will be able to push to any branch beginning with `release/` such as `release/v2.00.09`.
git config restrictedbranch.'/^jira\/\d+/'.pushers 'bugmaster' # Use RegularExpression to determine that no branch or tag beneath the jira/ reference can be modified except by the 'bugmaster' user
```

### restrictedbranch.BRANCH.forcers

Block --force from being used on specified branch.
Warning: Those in the [forcers] comma-delimited list will be able
to rewrite git history by editing previously-pushed comments and
edit authors and can even undo commits by rolling backwards.
Any branches NOT protected with [forcers] will be exposed to the
security danger of some commits on the branch being overwritten
or lost forever and may diminish proof of work.
Default is no restrictions, meaning anyone can rewrite history using --force.

```
git config restrictedbranch.'*'.forcers NOBODY          # Block everyone from using 'git push --force' to rewrite git history on any branch (since KEY=NOBODY doesn't exist).
git config restrictedbranch.'main'.forcers NOBODY       # Prevent anyone from using 'git push --force' to rewrite the 'main' branch git history.
git config restrictedbranch.'/permanent/'.forcers admin # Block all **writers** except for the 'admin' user from rewriting git history for any branch or tag matching the RegExp.
git config restrictedbranch.'release/*'.forcers NOBODY  # Block everyone from losing or reverting any commits already pushed into any of the branches beginning with 'release/'.
```

### restrictedfile.FILE.pushers

Specify which file to block all **writers** from making
changes to unless allowed in the pushers comma-delimited list.
You can also specify a pattern or regex to restrict.
Default is no restrictions, meaning anyone can commit changes to any file.

```
git config restrictedfile.'lib/config.php'.pushers 'alice'       # Only `alice` can push any changes to config.php on any branch.
git config restrictedfile.'*.html'.pushers 'art,dev'             # Only `art` or `dev` can push changes to any html file, such as `htdocs/index.html`.
git config restrictedfile.'/^(templates|docs)\//'.pushers 'sam'  # Use RegularExpression to block anyone from pushing changes to any file within either the `templates` or the `docs` folders and their descent, except 'sam'
```


PUSH NOTIFICATION INSTANT DEPLOY
================================

1. Install git-deploy on the deploy host:

```
[admin@deploy-host ~]$ sudo wget -N -P /usr/local/bin https://raw.githubusercontent.com/hookbot/git-server/master/git-deploy
[admin@deploy-host ~]$ sudo chmod 755 /usr/local/bin/git-deploy
[admin@deploy-host ~]$
```

2. Create a deploy SSH key on the deploy host:

It should have no passphrase so it can easily be used from cron.

```
[admin@deploy-host ~]$ sudo su - puller
[puller@deploy-host ~]$ ssh-keygen -t ed25519
Generating public/private dsa key pair.
Enter file in which to save the key (/home/puller/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/puller/.ssh/id_ed25519.
Your public key has been saved in /home/puller/.ssh/id_ed25519.pub.
[puller@deploy-host ~]$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC1NTE5/FiREggu4HKIZPpJSe puller@deploy-host
[puller@deploy-host ~]$
```

3. Install the deploy SSH key on the git server host:

Think of a name for this key, such as "push_notification_key1", and
ensure this name is in the acl.deploy comma-delimited list.

```
[admin@gitsrvhost ~]$ sudo su - git
[git@gitsrvhost ~]$ echo 'command="~/git-server/git-server KEY=push_notification_key1" ssh-ed25519 AAAAC1NTE5/FiREggu4HKIZPpJSe puller@deploy-host' >> ~/.ssh/authorized_keys
[git@gitsrvhost ~]$ cd ~/ProjX
[git@gitsrvhost ProjX]$ git config acl.deploy
srv7
[git@gitsrvhost ProjX]$ git config acl.deploy srv7,push_notification_key1
[git@gitsrvhost ProjX]$ git config acl.deploy
srv7,push_notification_key1
[git@gitsrvhost ProjX]$ git config --list | grep push_notification_key1
acl.deploy=srv7,push_notification_key1
[git@gitsrvhost ProjX]$ cd
[git@gitsrvhost ~]$

```

4. Verify Client:

Ensure the deploy key was installed properly.

```
[puller@deploy-host ~]$ git clone ssh://git@gitsrvhost/ProjX
[puller@deploy-host ~]$ cd ProjX
[puller@deploy-host ProjX]$ git deploy &
```

Hopefully, if everything is working properly, the "git deploy"
command should just block. This means it is successfully
waiting for one of the "writers" to push...

5. Test push notification:

Find another user with "writers" access to perform a push:

```
[alice@dev ProjX]$ git push
Tue Jun 23 07:54:45 2015: [alice] git-server: RUNNING PUSH ...
Counting objects: 4, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (4/4), 387 bytes | 0 bytes/s, done.
Total 4 (delta 1), reused 0 (delta 0)
remote: Tue Jun 23 07:54:45 2015: Sending push notification to 222.222.222.222-push_notification_key1 ...
To git@git-host:projectz
   f60b258..d759447  master -> master
[alice@dev ProjX]$
```

Hopefully, that other "git pull" process on deploy-host that was blocked will
immediately finish and deploy this fresh push. Then you know everything is
configured perfectly for the "deploy" user and for the "writers" user.
And you can append a cron to keep the deployment daemon running.

6. Install Deploy Cron:

A cron can ensure the latest version is always immediately deployed.

```
[puller@deploy-host ProjX]$ (crontab -l 2>/dev/null ; echo ; echo "0 * * * * git deploy --chdir ~/ProjX >/dev/null 2>/dev/null") | crontab -
[puller@deploy-host ProjX]$
```

You can do this on multiple deployment systems.
If different deployment systems will appear to come from the
same IP from the gitsrvhost point of view (such as machines
behind a NAT), then that will infinite grind the gitsrvhost.
To avoid this problem, make sure each machine coming from
this same IP that is in the acl.deploy list has a distinct
deployment SSH pubkey and KEY setting in authorized_keys.


DEBUG
=====

To enable optional debugging, run this on any client host:

```
[user1@devbox ProjX]$ git config --global core.SshCommand 'ssh -o SendEnv=XMODIFIERS'
# -AND/OR- for super annoying SSH debugging on local repo:
[user1@devbox ProjX]$ git config --local core.SshCommand 'ssh -v -o SendEnv=XMODIFIERS'
# -AND/OR- you can use ENV if you don't want to mess with the git config:
[user1@devbox ProjX]$ export GIT_SSH_COMMAND='ssh -o SendEnv=XMODIFIERS'
[user1@devbox ProjX]$ export XMODIFIERS=DEBUG=1
[user1@devbox ProjX]$
```

