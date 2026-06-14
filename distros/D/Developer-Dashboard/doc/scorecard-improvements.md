# OpenSSF Scorecard Improvements Guide

This document provides step-by-step instructions for improving the Developer Dashboard repository's OpenSSF Scorecard score through GitHub administrative settings and workflow changes.

## Current Scorecard Status

As of commit `c366e38` and tag `v4.03` (2026-06-05), the live Scorecard result is **7.1 / 10**.

### Open Checks That Need Attention

1. **Branch-Protection**: `0 / 10` — branch protection not enabled on `master`
2. **Code-Review**: `0 / 10` — Scorecard reports `0/30 approved changesets`
3. **Contributors**: `0 / 10` — project has `0` contributing companies or organisations
4. **Maintained**: `0 / 10` — repository is still within the Scorecard age window
5. **CII-Best-Practices**: `0 / 10` — no badge detected
6. **CI-Tests**: `?` — no pull request found
7. **Signed-Releases**: `?` — no GitHub release found

### What's Already Complete

- ✅ OWASP SOW and wording gate
- ✅ Full test suite on `4.03`
- ✅ `100.0 / 100.0 / 100.0` `lib/` coverage
- ✅ `dzil build`
- ✅ `t/44-smart-router-two-stage.t`
- ✅ Blank-environment integration
- ✅ Blank-container tarball install

## Action Items to Improve Score

### 1. Enable Branch Protection on `master` Branch

**Impact**: Addresses `Branch-Protection` check

**Requirements**: Repository admin access via GitHub web UI

**Steps**:

1. Navigate to your repository on GitHub
2. Click **Settings** tab
3. Click **Branches** in the left sidebar
4. Under "Branch protection rules", click **Add rule** (or **Add branch protection rule**)
5. In "Branch name pattern", enter: `master`
6. Configure the following recommended settings:

   **Protect matching branches**:
   - ✅ **Require a pull request before merging**
     - ✅ Require approvals: `1` (or more for higher security)
     - ✅ Dismiss stale pull request approvals when new commits are pushed
     - ✅ Require review from Code Owners (if you have a CODEOWNERS file)
   
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - Select required status checks (e.g., test workflows)
   
   - ✅ **Require conversation resolution before merging**
   
   - ✅ **Require signed commits** (optional but recommended)
   
   - ✅ **Require linear history** (optional)
   
   - ✅ **Do not allow bypassing the above settings**
   
   - ✅ **Restrict who can push to matching branches** (optional)
     - Add yourself and trusted maintainers
   
   - ✅ **Allow force pushes** - LEAVE UNCHECKED
   
   - ✅ **Allow deletions** - LEAVE UNCHECKED

7. Click **Create** (or **Save changes**)

**Alternative via GitHub CLI** (if you have a token with admin permissions):

```bash
gh api repos/:owner/:repo/branches/master/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismissal_restrictions":{},"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  --field restrictions=null \
  --field required_linear_history=false \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

---

### 2. Create a GitHub Release for `v4.03`

**Impact**: Addresses `Signed-Releases` check

**Requirements**: Repository admin access or push/release permissions

**Note**: You already have a `.github/workflows/release-github.yml` workflow that:
- Builds the distribution
- Runs tests
- Verifies 100% lib coverage
- Creates SHA-256 checksums
- Generates GPG signatures
- Creates GitHub releases automatically

**Option A: Via GitHub Web UI**:

1. Navigate to your repository on GitHub
2. Click the **Releases** link (right sidebar or under "Code" tab)
3. Click **Draft a new release**
4. Configure the release:
   - **Choose a tag**: Select `v4.03` from dropdown (or enter it if not listed)
   - **Release title**: `v4.03`
   - **Description**: Click **Generate release notes** for automatic changelog, or write custom notes
   - **Attach binaries**: Upload the following files (if available):
     - `Developer-Dashboard-4.03.tar.gz`
     - `Developer-Dashboard-4.03.tar.gz.sha256`
     - `Developer-Dashboard-4.03.tar.gz.asc` (GPG signature)
5. Click **Publish release**

**Option B: Trigger the Existing Workflow**:

If you pushed the `v4.03` tag recently, the workflow should have run automatically. Check:

```bash
# Check if the workflow ran
gh run list --workflow=release-github.yml --branch=v4.03

# If it failed, view the logs
gh run view <run-id>

# Re-run if needed (requires appropriate permissions)
gh run rerun <run-id>
```

**Option C: Via GitHub CLI** (if you have release permissions):

```bash
# Create release from existing tag
gh release create v4.03 \
  Developer-Dashboard-4.03.tar.gz \
  Developer-Dashboard-4.03.tar.gz.sha256 \
  Developer-Dashboard-4.03.tar.gz.asc \
  --title "v4.03" \
  --generate-notes
```

---

### 3. Establish Pull Request Workflow

**Impact**: Addresses `Code-Review` and `CI-Tests` checks

**Requirements**: Workflow change, no special permissions needed

**Recommended Process**:

1. **Stop pushing directly to `master`**: Once branch protection is enabled, this will be enforced

2. **Use feature branches**:
   ```bash
   git checkout -b feature/my-new-feature
   # Make changes
   git commit -m "Add new feature"
   git push origin feature/my-new-feature
   ```

3. **Create Pull Requests**:
   ```bash
   gh pr create --title "Add new feature" --body "Description of changes"
   ```

4. **Review and approve**: Even for solo maintainers, consider:
   - Waiting for CI to pass
   - Reviewing the diff one more time
   - Explicitly approving the PR

5. **Merge via GitHub UI**: Use "Squash and merge" or "Merge pull request" button

**For Solo Maintainers**:
- You can approve your own PRs on public repos
- Scorecard will count these as reviewed changesets
- This establishes a history of code review for the project

---

### 4. Re-run Scorecard After Changes

**Wait Time**: OpenSSF Scorecard typically updates weekly, but you can request a manual run

**Check Status**:

```bash
# Visit the Scorecard website
# https://securityscorecards.dev/viewer/?uri=github.com/<owner>/<repo>
```

**Request Manual Re-scan** (if urgent):

OpenSSF Scorecard updates automatically, but changes may take time to propagate. The checks look at:
- Last 30 commits for Code-Review
- Recent releases for Signed-Releases  
- Current branch protection settings for Branch-Protection

---

## Expected Score Improvements

After implementing the above changes:

- **Branch-Protection**: Should reach `8-10/10` with proper configuration
- **Signed-Releases**: Should reach `8-10/10` after creating the release with signatures
- **Code-Review**: Will gradually improve as you accumulate reviewed PRs (need ~30 reviewed commits)
- **CI-Tests**: Will show positive status once PRs with passing CI are merged

**Items That May Remain Low**:

- **Contributors**: Requires multiple organizations/companies to contribute (external factor)
- **Maintained**: Based on commit activity age (time-based, will improve naturally)
- **CII-Best-Practices**: Requires applying for and earning the badge (external process)

---

## Token Permission Issues

Your current token limitations:
- ✅ Can push git refs
- ❌ Cannot administer branch protection
- ❌ Cannot create GitHub Releases via REST

**To Fix**:

1. **For Personal Access Tokens (classic)**:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Create new token or edit existing
   - Enable these scopes:
     - `repo` (full control)
     - `admin:repo_hook` (if needed for webhooks)

2. **For Fine-grained Personal Access Tokens**:
   - Repository permissions needed:
     - Contents: Read and write
     - Administration: Read and write (for branch protection)
     - Pull requests: Read and write

3. **For GitHub Apps**:
   - Grant appropriate repository permissions in the app settings

---

## Verification Checklist

After making changes, verify:

- [ ] Branch protection rules show on `master` branch settings
- [ ] `v4.03` release is visible on the Releases page
- [ ] Release includes tarball, checksum, and signature files
- [ ] New commits are being made via PRs (not direct pushes)
- [ ] CI tests are running on PRs
- [ ] PR approvals are being recorded
- [ ] Wait 1-7 days for Scorecard to re-scan
- [ ] Check updated score at https://securityscorecards.dev/

---

## Additional Security Improvements

While working on Scorecard improvements, consider these additional hardening measures:

1. **Add SECURITY.md** (if not present): Already exists ✅
2. **Enable Dependabot**: Check Settings → Security & analysis → Dependabot alerts
3. **Enable CodeQL**: Your `.github/workflows/codeql.yml` already exists ✅
4. **Add CODEOWNERS file**: Defines who must review certain changes
5. **Enable two-factor authentication**: For all maintainers with write access
6. **Use signed commits**: Configure GPG signing for all commits

---

## Summary

The main improvements require GitHub web UI or admin API access:

1. **Branch Protection**: Requires admin access via web UI or admin API token
2. **GitHub Release**: Can use web UI, CLI with release permissions, or wait for workflow
3. **PR Workflow**: Process change, can start immediately with feature branches
4. **Scorecard Re-scan**: Automatic, just wait after making changes

Most of these tasks cannot be automated via code changes or this pull request - they require manual intervention through GitHub's interface or a properly-scoped access token.
