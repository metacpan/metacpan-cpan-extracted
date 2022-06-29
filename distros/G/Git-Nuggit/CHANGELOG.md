# 1.0  2021-06

This is a version number update reflecting the significant
improvements made with recent releases.  The prior 0.4/0.5 releases
were effectively release candidates.  This release reflects assorted bugfixes and
documentation improvements on top of the 0.04 version described below.

# 0.04 2021-01

This is a significant update providing more consistent and
user-friendly output, and introducing a new submodule management
strategy aimed at improving reliability and expanding functionality.

NOTE: This release is currently in 'beta' or release-candidate status.
Documentation is still being updated, and some functionality
(including rebase and --branch-first flags) may not be fully tested.

 
- New: Introducing Nuggit submodule strategy
  - Previous Nuggit versions used a "branch-first" strategy, where the state of the branch was considered first-class.  This can still be invoked with “—branch-first” for selected commands
  - The new default behavior is “ref-first”, where operations follow the commit references first.
  - Ngt Strategy option initially available for pull, merge, checkout, rebase, and diff [of commit] commands.
- 'ngt checkout --safe'  option.  This mode allows a branch to be checked out at all levels, conditional that doing so is only a change to the label and not the currently checked out commit. This is the magic that enables much of the ‘ref-first’ strategy
- 'ngt clone' now automatically performs a '--safe' checkout to resolve any detached heads.
- The '--default' flag concept is no longer applicable when using the 'ref-first' strategy.  This also enables new functionality with the following now all valid commands:
   - ngt checkout origin/foo
   - ngt checkout HEAD~1
   - ngt merge $SHA_COMMIT
   - ngt diff taggedVersion
   - ngt diff HEAD...HEAD~1
   - ngt diff --strategy=branch feature/foo
     - This variant will compare 'feature/foo' in each submodule to current, whereas omitting the strategy option will execute the comparison at the root level and follow differences in any submodule commit references.
- NEW/experimental: 'ngt merge --preview branch', or more verbosely 'ngt merge-tree [base] branch [branch2]' to preview merge operations.
- Optimized pull operations to avoid unnecessary recursion into unmodified submodules
- Checkout with ref-first will now work as expected for any SHA or tag known to the root repository
- Cleaner user output throughout nuggit and consistent usage of ANSI Color Themes, which can be customized via environment variable
- 'ngt stash' command for reliable git stash behavior across submodules
- Note: Detached HEADs are now more likely to occur if submodule references become out of date (ie: due to non-ff PRs or checkout of a non-branch reference), but should be handled more reliably by Ngt with checks to prevent accidental commits in this state.
  - This condition may only occur after checkout or clone operations.
  - Typically, creating a new branch ('ngt checkout -b foo') is the easiest resolution of this condition.
  - To force synchronization with the latest remote branch, you can invoke 'ngt checkout --branch-first foo', however be aware that this can result in lost commits under certain conditions.
  - Manual resolution, or at least verification of repository state, is recommended if the cause of the detached HEAD is unknown.

# 0.03 2020-09

- Numerous improvements and expanded OOP backend implementation

# 0.02 2020-02

- First public release of Nuggit

# 0.01 2019-08

- Initial prototype
