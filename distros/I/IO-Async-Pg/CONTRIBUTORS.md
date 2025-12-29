# Contributing to IO::Async::Pg

## Development Setup

### Prerequisites

- Perl 5.18+
- Docker and Docker Compose (for running PostgreSQL)
- Dist::Zilla (for building)

```bash
# Install Dist::Zilla if needed
cpanm Dist::Zilla

# Install dependencies
dzil listdeps --missing | cpanm
```

### Start the Test Database

A Docker Compose file is provided for running PostgreSQL locally:

```bash
# Start PostgreSQL container (runs in background)
docker compose up -d

# Check it's running
docker compose ps

# View logs if needed
docker compose logs -f postgres
```

The container exposes PostgreSQL on `localhost:5432` with:

| Setting | Value |
|---------|-------|
| Host | localhost |
| Port | 5432 |
| User | postgres |
| Password | test |
| Database | test |

### Run the Tests

```bash
# Run all tests
TEST_PG_DSN="postgresql://postgres:test@localhost:5432/test" prove -r -l t/

# Run with verbose output
TEST_PG_DSN="postgresql://postgres:test@localhost:5432/test" prove -r -l -v t/

# Run a specific test file
TEST_PG_DSN="postgresql://postgres:test@localhost:5432/test" prove -l t/integration/connection.t

# Run unit tests only (no database required)
prove -l t/unit/
```

### Stop the Test Database

```bash
# Stop container (preserves data for next time)
docker compose stop

# Stop and remove container (data volume preserved)
docker compose down

# Stop and remove everything including data volume
docker compose down -v
```

### Run Examples

```bash
DATABASE_URL="postgresql://postgres:test@localhost:5432/test" perl -Ilib examples/01-basic-query/app.pl
```

## Building a Release

```bash
# Run tests
dzil test

# Build distribution
dzil build

# Release (if configured)
dzil release
```

## Code Style

- Use `strict` and `warnings`
- 4-space indentation
- Keep lines under 100 characters when reasonable
- Write tests for new functionality

## Commit Messages

Format:
```
Short summary (50 chars or less)

Longer description if needed. Wrap at 72 characters.
```

## Questions?

Open an issue on GitHub or contact the maintainer.
