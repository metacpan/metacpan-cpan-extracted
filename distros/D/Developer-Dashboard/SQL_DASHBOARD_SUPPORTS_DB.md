# SQL Dashboard Database Support Report

## Purpose

This file is the living checklist for SQL Dashboard database support. It tracks
what is already proven in the real browser workflow, what optional drivers a
user must install, what host-side setup is required for deeper verification,
and what remains to improve.

## Current Status

| Database | Support | Verified In Browser | Driver | Extra Native Client Requirement | Notes |
|----------|---------|---------------------|--------|---------------------------------|-------|
| SQLite | 100% | Yes | `DBD::SQLite` | No | Best zero-config path. Blank-user profiles are supported. |
| MySQL | 100% | Yes | `DBD::mysql` | No | Verified through Docker-backed browser coverage. |
| PostgreSQL | 100% | Yes | `DBD::Pg` | No | Verified through Docker-backed browser coverage. |
| MSSQL | 100% | Yes | `DBD::ODBC` | Yes | Verified through Docker-backed browser coverage with user-space `unixODBC` and `FreeTDS`. |
| Oracle | 100% | Yes | `DBD::Oracle` | Yes | Verified through Docker-backed browser coverage with user-space Oracle client libraries and `ORACLE_HOME`. |

These `100%` scores mean the core SQL Dashboard browser workflow is proven for
that database family in this release:

- create or load a profile
- connect with the selected driver
- run SQL from the visible editor
- render results in the browser
- browse schema metadata
- save and reload SQL collections
- keep share-state and profile UX usable

They do not mean every vendor-specific SQL feature is abstracted by the
bookmark. SQL dialect differences are still the user's responsibility.

## What SQL Dashboard Supports Well

- generic `DBI` execution from the SQL editor
- profile storage under `config/sql-dashboard/<profile-name>.json`
- collection storage under `config/sql-dashboard/collections/<collection>.json`
- owner-only profile and collection permissions
- blank-user profiles for DSNs that do not require a user, such as SQLite
- shareable browser URL state without leaking passwords
- schema browsing through `table_info` and `column_info`
- driver dropdown based on installed `DBD::*` modules
- driver-specific DSN examples for SQLite, MySQL, PostgreSQL, MSSQL/ODBC, and Oracle
- programmable result handling through `SQLS_SEP`, `INSTRUCTION_SEP`, `STASH`, `ROW`, `BEFORE`, and `AFTER`

## Driver Installation Model

SQL Dashboard stays generic. The base release does not ship database drivers.
Install only what you need.

Project-local runtime install:

```bash
dashboard cpan DBD::SQLite
dashboard cpan DBD::mysql
dashboard cpan DBD::Pg
dashboard cpan DBD::ODBC
dashboard cpan DBD::Oracle
```

User-home install:

```bash
cpanm -L ~/perl5 DBI DBD::SQLite
cpanm -L ~/perl5 DBI DBD::mysql
cpanm -L ~/perl5 DBI DBD::Pg
cpanm -L ~/perl5 DBI DBD::ODBC
cpanm -L ~/perl5 DBI DBD::Oracle
```

For MSSQL and Oracle on this host, the Perl driver alone is not enough. The
native client libraries must also be available from user space.

## Verified Browser Coverage

### SQLite

File: `t/31-sql-dashboard-sqlite-playwright.t`

Current depth:

- 51 real SQLite browser cases
- blank-user profile save and reload
- merged workspace UX
- collection and saved-SQL behavior
- invalid SQL handling
- shared-route restoration
- on-disk permission checks

### MySQL, PostgreSQL, MSSQL, Oracle

File: `t/32-sql-dashboard-rdbms-playwright.t`

Current depth:

- MySQL through `mysql:5.7`
- PostgreSQL through `postgres:16`
- MSSQL through `mcr.microsoft.com/mssql/server:2022-latest`
- Oracle through `gvenzl/oracle-xe:21-slim-faststart`
- real browser workflow on the host
- real database services in Docker
- schema browsing, query execution, saved SQL, and driver guidance checks

## Host-Side Notes For MSSQL And Oracle

### MSSQL

Required pieces on this host:

- `DBD::ODBC`
- `unixODBC`
- `FreeTDS`

They are intentionally built or installed in user space, not through `apt`, and
not shipped in the release tarball.

### Oracle

Required pieces on this host:

- `DBD::Oracle`
- Oracle client libraries exposed through `ORACLE_HOME`
- supporting shared libraries on `LD_LIBRARY_PATH`

They are intentionally kept out of the shipped runtime prerequisites.

## UX Status

Current UX strengths:

- one merged `SQL Workspace` instead of split navigation
- large auto-resizing editor
- quiet action row under the editor
- saved SQL list kept next to the active collection
- active saved-SQL label remains visible
- compact inline delete
- driver-specific DSN guidance
- share-safe connection model that excludes passwords

Current UX rule:

- no hidden SQL generation
- no background query rewriting
- user-authored SQL remains explicit

## Programmatic Result Use

SQL Dashboard supports programmatic result shaping through the existing bookmark
instruction model. Use `SQLS_SEP` and `INSTRUCTION_SEP` blocks with `STASH`,
`ROW`, `BEFORE`, and `AFTER` to transform rows into derived output.

Typical use cases:

- create HTML links from result rows
- create button-like controls from result data
- merge row data into bookmark output
- keep vendor-specific SQL in the query while shaping the rendered result in the bookmark

The bookmark intentionally does not ship sensitive historical examples. The generic
pattern is:

1. run explicit user-authored SQL
2. capture rows
3. transform rows through the instruction hooks
4. render the final HTML fragment or page body

## What Was Learned

- generic `DBI` support is not enough to claim a database family works
- real browser proof matters more than unit-only confidence
- MSSQL and Oracle need host-specific setup discipline
- schema metadata calls can behave differently across drivers
- DSN examples are part of UX, not optional documentation fluff

## Remaining Work

Functional blockers for core DB-family support:

- none known for SQLite, MySQL, PostgreSQL, MSSQL, or Oracle

Nice-to-have follow-up work:

- add more vendor-specific example queries to docs
- add more large-result UX checks
- add more explain-plan and long-running-query UX checks
- expand guidance for SSL/TLS DSN variants per vendor

## Quick Checklist

- [x] SQLite live browser workflow verified
- [x] MySQL live browser workflow verified
- [x] PostgreSQL live browser workflow verified
- [x] MSSQL live browser workflow verified
- [x] Oracle live browser workflow verified
- [x] drivers kept out of shipped base runtime prerequisites
- [x] project-local `dashboard cpan DBD::Driver` path supported
- [x] user-space `cpanm -L ~/perl5` path documented
- [x] schema browsing verified across the supported database families
- [x] driver-specific DSN guidance shown in the profile editor

## Related Files

- `share/seeded-pages/sql-dashboard.page`
- `t/26-sql-dashboard.t`
- `t/27-sql-dashboard-playwright.t`
- `t/31-sql-dashboard-sqlite-playwright.t`
- `t/32-sql-dashboard-rdbms-playwright.t`
- `README.md`
- `lib/Developer/Dashboard.pm`
- `doc/testing.md`
- `doc/integration-test-plan.md`
