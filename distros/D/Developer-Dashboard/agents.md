# Priorities

### P0. Hard safety and scope rules

These come first because they decide what is allowed at all.

1. **Stay within project scope**

   * Do not change anything in `OLD_CODE` and Do not copy line by line from the OLD_CODE. 
   * You can read but do not change anything or copy code by code, you read, understand, extract the concept then implement in the new code
   * Do not inspect or change unrelated Docker processes.
   * Ditch all code related to Companies House, EWF, XMLGW, CHIPS, Tuxedo, CHS, Grover, CIDEV, PBS, credentials, and any sensitive data.

2. **Security first**

   * Do a security audit on every change.
   * Never suppress errors.
   * Treat warnings as errors.
   * Make logs explicit.
   * Fix problems rather than hiding or bypassing them.

3. **No silent failures**

   * Expose errors clearly.
   * If something stalls or breaks, fix it properly.

---

### P1. Delivery gates for every code change

These are the real must-pass rules before anything can be considered done.

4. **TDD is mandatory**

   * All changes must be done with Test Driven Development.
   * Add unit tests under `t/`.

5. **Tests and coverage must pass**

   * All tests must pass.
   * Coverage must be 100%.

6. **Documentation is mandatory**

   * Document all changes in `doc/`.
   * Update `README.md`.
   * Update POD in `Developer/Dashboard.pm`.
   * `README.md` and module POD must stay in sync.

7. **Change log and release metadata must be updated**

   * Update `Changes`.
   * Version bump must match `dist.ini`.
   * Record bug fixes in `FIXED_BUGS.md`.
   * Never resuse the samve version number
   * Version Number format always X.XX not X.XX.X or else
   * When update a new version to the software. All Perl Modules inside lib has to be all the same.

---

### P2. Coding standards

These apply while implementing the change.

8. **Perl library rules**

   * Use `JSON::XS` for JSON.
   * Use `LWP::UserAgent` for HTTP/HTTPS.
   * Use `Capture::Tiny` for command output.

9. **Never use**

   * `LWP::Simple`
   * `HTTP::Tiny`
   * `JSON::PP`
   * `capture_merged`

10. **Required Capture::Tiny pattern**

```perl
use Capture::Tiny qw(capture);

my ($stdout, $stderr, $exit) = capture {
   system($command);
};
```

11. **Code documentation standards**

* Every function must have updated comments explaining:

  * what it does
  * input arguments
  * expected output
* Because Perl is loosely typed, this is required.

12. **POD everywhere**

* Scripts, tests, and modules must include or update POD under `__END__`.

---

### P3. Verification and runtime checks

These happen after coding and before release.

13. **Check runtime environment proactively**

* Follow `ELLEN.md`.
* Proactively check for Docker container errors relevant to the work.

14. **Frontend verification**

* For frontend changes, verify in the browser that behaviour is correct and usable.

15. **Integration and packaging verification**

* Run integration tests.
* Follow `doc/integration-test-plan.md`.
* Build tarball with `dzil`.
* Install it in a blank Docker environment using `cpanm` without `--notest`.

16. **Tarball hygiene**

* Keep only the latest generated tarball in the working directory.
* Remove older tarballs.

17. **Kwalitee**

* Fix all kwalitee issues.
* Final state must be clean.

---

### P4. Git and release workflow

These are important, but only after the code is proven good.

18. **Meaningful git commits only**

* No empty commits.
* Every commit must have a meaningful title and context.

19. **Tagging rules**

* Use `MISTAKE.md` references as git tags.

20. **Push after verification**

* Only push after tests, coverage, docs, packaging, and verification are all done.

21. **PAUSE release rules**

* Release locally to PAUSE only when doing an actual release.
* Use version/tagging rules consistently.
* Tag `PAUSE_RELEASED_HERE` after release.

# Development Rules

## 1. Scope and safety

1. Follow `ELLEN.md` as the operating guide.
2. Do not touch or inspect unrelated Docker processes.
3. Do not modify anything in `OLD_CODE`. It is read-only and must not be committed or pushed.
4. Remove or avoid all code related to Companies House, EWF, XMLGW, CHIPS, Tuxedo, CHS, Grover, CIDEV, PBS, credentials, and sensitive data.
5. Always perform a security audit.
6. Never suppress errors.
7. Treat Perl warnings as errors.
8. Make logs explicit and visible.
9. If something is broken, fix it properly rather than hiding it.

## 2. Mandatory delivery rules

10. All work must follow TDD.
11. Add or update unit tests in `t/`.
12. All tests must pass.
13. Coverage must be 100%.
14. Document all changes in `doc/`.
15. Record all bug fixes in `FIXED_BUGS.md`.
16. Update `Changes`.
17. Bump the version and keep it aligned with `dist.ini`.
18. Update both `README.md` and the POD in `Developer/Dashboard.pm`.
19. `README.md` and `Developer/Dashboard.pm` POD must remain identical in content.

## 3. Perl implementation rules

20. Use `JSON::XS` for JSON.
21. Use `LWP::UserAgent` for HTTP and HTTPS.
22. Use `Capture::Tiny` for capturing command output.
23. Never use `LWP::Simple`, `HTTP::Tiny`, `JSON::PP`, or `capture_merged`.
24. Use `Capture::Tiny` in this form:

```perl
use Capture::Tiny qw(capture);
my ($stdout, $stderr, $exit) = capture {
   system($command);
};
```

25. Every function must document:

* purpose
* input arguments
* expected output

## 4. POD and internal documentation

26. Update POD comments for the codebase.
27. Scripts, tests, and modules must include POD under `__END__`.
28. Keep all documentation current and in sync with the implementation.

## 5. Verification rules

29. Proactively check for relevant Docker container errors.
30. For frontend changes, verify behaviour in a browser.
31. Run integration tests according to `doc/integration-test-plan.md`.
32. Build the release tarball with `dzil`.
33. Test install the tarball in a blank Docker container using `cpanm` without `--notest`.
34. Remove old tarballs and keep only the latest one.
35. Fix all kwalitee issues.

## 6. Git and release rules

36. Do not create empty commits.
37. Every commit must be meaningful and have a proper title.
38. Use `MISTAKE.md` references as git tags.
39. Push only after all checks pass.
40. For PAUSE releases, perform the release locally and tag `PAUSE_RELEASED_HERE`.

# Reference: https://chatgpt.com/c/69ce6795-f970-8395-8856-83feab1867b7
