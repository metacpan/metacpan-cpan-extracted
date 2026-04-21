## SECURITY_CHECKS.md

# Pre-Build Security Validation Protocol
**Role:** AI Security Auditor
**Objective:** Execute 3-tier security validation before running `dzil build`.
**Mandate:** If any "Critical" check fails, the build MUST be aborted.
---## 1. OpenSSF Scorecard (Automated Supply Chain Check)**Tool:** `scorecard` CLI
**Execution:**
```bash
scorecard --repo=https://github.com/[owner]/[repo] --format json > scorecard_results.json

AI Instructions:

* Scan scorecard_results.json for any check with a score < 5.
* Fail Build if: Maintained score is 0 or Dangerous-Workflow is detected.
* Action: Fix branch protection or pin dependencies by hash if flagged.

------------------------------
## 2. OWASP ASVS Level 1 (Technical Control Verification)
Tool: owasp-asvs-check (or manual audit against ASVS_L1_Checklist.json)
Execution:
Verify the following "Bare Minimum" controls are implemented in the code:

* V2.1.1 (Auth): Verify all pages require authentication except those specifically public.
* V5.1.3 (Input): Verify all input data is validated against a strict allowlist.
* V13.2.1 (API): Verify all API responses include the X-Content-Type-Options: nosniff header.

AI Instructions:

* Perform a grep-based audit on the lib/ directory for these controls.
* Fail Build if: Raw SQL queries are found without parameterization (V5.3.1).

------------------------------
## 3. OpenSSF Best Practices (Project Hygiene)
Tool: Best Practices Badge API
Execution:

curl -s "https://coreinfrastructure.org[ID].json" | jq '.badge_level'

AI Instructions:

* Ensure the project has at least a "passing" status.
* Manual Verification: Confirm SECURITY.md exists and contains a clear vulnerability disclosure policy.
* Fail Build if: No SECURITY.md is found in the repository root.

------------------------------
## Final Build Trigger
ONLY if all above checks pass, proceed to:

dzil build


### Integration Tips
*   **Automation:** You can have the AI agent run these commands sequentially. For the **OpenSSF Scorecard**, the CLI can be installed via Go or run as a Docker container.
*   **DistZilla Integration:** To make this even more robust, you can add `[Run::BeforeBuild]` to your `dist.ini` file to force these checks:
    ```ini
    [Run::BeforeBuild]
    run = ./scripts/run_security_checks.sh
    ```
*   **The "Passing" Badge:** If you haven't yet, you must register your project at [bestpractices.coreinfrastructure.org](https://coreinfrastructure.org) to get the Project ID needed for the API check.

Would you like me to help you write the **shell script** that the AI agent would actually execute to automate these checks?

