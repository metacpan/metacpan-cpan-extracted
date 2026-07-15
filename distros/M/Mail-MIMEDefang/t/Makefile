# Makefile — MIMEDefang SMTP Integration Test Suite
# ════════════════════════════════════════════════════════════════════════════
# Targets:
#   make up          – Build images and start the stack (detached)
#   make test        – Run the full test suite inside Docker
#   make test-quick  – Run only fast tests (skip stress & fixtures)
#   make test-file FILE=t/07-smtp-session.t  – Run one test file
#   make logs        – Tail the MIMEDefang/Postfix container logs
#   make mailhog     – Open MailHog web UI in the browser
#   make down        – Stop and remove containers
#   make clean       – Stop containers and remove images + volumes
#   make shell       – Open a shell in the test runner container
#   make filter-lint – Syntax-check the filter without starting Docker
#   make debug       – Run tests with MD_TEST_DEBUG=1 (verbose SMTP)

COMPOSE       := docker compose
COMPOSE_FILE  := docker-compose.yml
MH_PORT       := 8025
SMTP_HOST     := 127.0.0.1
SMTP_PORT     := 2525

.PHONY: up down clean test test-quick test-file test-smtp test-tls \
        logs mailhog shell filter-lint debug status wait

# ── Stack lifecycle ────────────────────────────────────────────────────────────

up:
	@echo "▶ Building images and starting stack..."
	$(COMPOSE) -f $(COMPOSE_FILE) up --build -d mailhog mimedefang
	@$(MAKE) wait

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

clean:
	$(COMPOSE) -f $(COMPOSE_FILE) down -v --rmi local
	@echo "✓ Containers, volumes, and local images removed."

# ── Running tests ─────────────────────────────────────────────────────────────

# Full suite (runs all t/*.t via the tests container)
test: up
	@echo "▶ Running full test suite..."
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm \
		-e PROVE_ARGS="-v --timer" \
		tests /scripts/run-tests.sh

# Quick run — skip slow tests
test-quick: up
	@echo "▶ Running quick tests (no stress / fixtures)..."
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm \
		-e PROVE_ARGS="-v" \
		tests bash -c "cd /tests && prove -v -I /tests/lib \
		    01-basic-delivery.t 02-header-rewriting.t \
		    03-attachment-filtering.t 04-sender-policy.t \
		    07-smtp-session.t 08-tls-auth.t"

# Run a single test file: make test-file FILE=t/07-smtp-session.t
test-file: up
	@test -n "$(FILE)" || (echo "Usage: make test-file FILE=t/07-smtp-session.t" && exit 1)
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm \
		-v "$(PWD)/$(FILE):/tests/$(notdir $(FILE)):ro" \
		tests bash -c "cd /tests && prove -v -I /tests/lib $(notdir $(FILE))"

# Run only SMTP session / protocol tests (no MailHog needed)
test-smtp: up
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm tests \
		bash -c "cd /tests && prove -v -I /tests/lib 07-smtp-session.t"

# Run TLS/AUTH tests
test-tls: up
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm tests \
		bash -c "cd /tests && prove -v -I /tests/lib 08-tls-auth.t"

# Run with verbose SMTP debug output
debug: up
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm \
		-e MD_TEST_DEBUG=1 \
		-e PROVE_ARGS="-v" \
		tests /scripts/run-tests.sh

# ── Utilities ─────────────────────────────────────────────────────────────────

# Wait for both services to be healthy
wait:
	@echo "  Waiting for services to be healthy..."
	@for i in $$(seq 1 60); do \
		mdf=$$($(COMPOSE) -f $(COMPOSE_FILE) ps --format json mimedefang 2>/dev/null \
		       | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0].get('Health',''))" 2>/dev/null || echo ''); \
		mhg=$$($(COMPOSE) -f $(COMPOSE_FILE) ps --format json mailhog 2>/dev/null \
		       | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0].get('Health',''))" 2>/dev/null || echo ''); \
		if [ "$$mdf" = "healthy" ] && [ "$$mhg" = "healthy" ]; then \
			echo "  ✓ Stack is healthy"; break; \
		fi; \
		if [ $$i -eq 60 ]; then echo "  ✗ Stack never became healthy"; exit 1; fi; \
		sleep 1; \
	done

logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f mimedefang

mailhog:
	@echo "Opening MailHog at http://localhost:$(MH_PORT)..."
	@open "http://localhost:$(MH_PORT)" 2>/dev/null \
		|| xdg-open "http://localhost:$(MH_PORT)" 2>/dev/null \
		|| echo "Visit http://localhost:$(MH_PORT) in your browser"

shell:
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm tests bash

status:
	$(COMPOSE) -f $(COMPOSE_FILE) ps

# Syntax-check filter.pl locally (no Docker needed)
filter-lint:
	@echo "▶ Checking filter syntax..."
	@perl -c filters/filter.pl && echo "✓ Filter syntax OK"

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "MIMEDefang SMTP Test Suite"
	@echo "══════════════════════════"
	@echo "  make up              Start the Docker stack"
	@echo "  make test            Run all tests"
	@echo "  make test-quick      Run fast tests only"
	@echo "  make test-file FILE= Run one test file"
	@echo "  make test-smtp       Protocol-only tests (07)"
	@echo "  make test-tls        TLS/AUTH tests (08)"
	@echo "  make debug           Verbose SMTP output"
	@echo "  make logs            Tail container logs"
	@echo "  make mailhog         Open MailHog web UI"
	@echo "  make shell           Shell in test container"
	@echo "  make filter-lint     Check filter.pl syntax"
	@echo "  make down            Stop containers"
	@echo "  make clean           Remove everything"
	@echo ""
