You've been using git for years, you really don't need `git status` to tell you things like:

<pre>
(use "git reset HEAD <file>..." to unstage)
(use "git add <file>..." to update what will be committed)
(use "git checkout -- <file>..." to discard changes in working directory)
(use "git add <file>..." to include in what will be committed)
</pre>

So use this instead which gives you what you really want, concisely.

<pre>
UntrackedFiles:
 README.md

WorkingTreeChanges:
  lib/Git/Status/Tackle.pm |   30 +++++++++++++++++++++++++++++-
 1 files changed, 29 insertions(+), 1 deletions(-)

IndexChanges:
  lib/Git/Status/Tackle.pm |    5 +++++
 1 files changed, 5 insertions(+), 0 deletions(-)

UnpushedBranches:
 master: +1
</pre>

You can also control exactly which status you want to see (and in which order) on a per-repository level:

<pre>
[status-tackle]
    plugins = UntrackedFiles WorkingTreeChanges IndexChanges UnpushedBranches CompletedFeatureBranches UnmergedFeatureBranches
</pre>
