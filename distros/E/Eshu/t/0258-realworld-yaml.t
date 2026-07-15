use strict;
use warnings;
use Test::More;
use Eshu;

sub ym { Eshu->indent_yaml($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. flat mapping
{
    my $code = <<'END';
name: Alice
age: 30
active: true
END
    is(ym($code), $code, 'YAML: flat mapping');
}

# 2. nested mapping
{
    my $code = <<'END';
user:
  id: 1
  name: Bob
  address:
    street: 123 Main St
    city: Springfield
    zip: '12345'
END
    is(ym($code), $code, 'YAML: nested mapping');
}

# 3. sequence of scalars
{
    my $code = <<'END';
languages:
  - perl
  - python
  - javascript
  - rust
  - go
END
    is(ym($code), $code, 'YAML: sequence of strings');
}

# 4. sequence of mappings
{
    my $code = <<'END';
users:
  - id: 1
    name: Alice
    role: admin
  - id: 2
    name: Bob
    role: user
  - id: 3
    name: Carol
    role: user
END
    is(ym($code), $code, 'YAML: sequence of mappings');
}

# 5. Docker Compose v3
{
    my $code = <<'END';
version: '3.9'
services:
  app:
    build: .
    ports:
      - '3000:3000'
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://db/app
    depends_on:
      - db
      - redis
  db:
    image: postgres:15
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: app
      POSTGRES_PASSWORD: secret
  redis:
    image: redis:7-alpine
volumes:
  pgdata: {}
END
    is(ym($code), $code, 'YAML: Docker Compose');
}

# 6. Kubernetes Deployment
{
    my $code = <<'END';
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          ports:
            - containerPort: 8080
          env:
            - name: APP_PORT
              value: '8080'
END
    is(ym($code), $code, 'YAML: Kubernetes Deployment');
}

# 7. GitHub Actions workflow
{
    my $code = <<'END';
name: CI
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm test
END
    is(ym($code), $code, 'YAML: GitHub Actions workflow');
}

# 8. anchor and alias
{
    my $code = <<'END';
defaults: &defaults
  host: localhost
  port: 5432
  timeout: 30

development:
  <<: *defaults
  database: app_dev

test:
  <<: *defaults
  database: app_test

production:
  <<: *defaults
  host: db.prod.example.com
  database: app_prod
END
    is(ym($code), $code, 'YAML: anchors and aliases');
}

# 9. block scalar literal
{
    my $code = <<'END';
script: |
  #!/bin/bash
  set -euo pipefail
  echo "Starting deployment"
  npm ci
  npm run build
  npm test
END
    is(ym($code), $code, 'YAML: block scalar literal |');
}

# 10. block scalar folded
{
    my $code = <<'END';
description: >
  This is a long description that
  will be folded into a single line
  when parsed.

summary: >-
  Another long text that is folded
  with the trailing newline stripped.
END
    is(ym($code), $code, 'YAML: block scalar folded >');
}

# 11. mixed types
{
    my $code = <<'END';
config:
  string: hello
  integer: 42
  float: 3.14
  boolean_true: true
  boolean_false: false
  null_value: ~
  list: [1, 2, 3]
  map: {key: value}
END
    is(ym($code), $code, 'YAML: mixed scalar types');
}

# 12. Kubernetes ConfigMap
{
    my $code = <<'END';
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  APP_PORT: '8080'
  APP_ENV: production
  config.yaml: |
    database:
      host: db
      port: 5432
    cache:
      ttl: 300
END
    is(ym($code), $code, 'YAML: Kubernetes ConfigMap with embedded YAML');
}

# 13. Ansible playbook
{
    my $code = <<'END';
- name: Configure web server
  hosts: webservers
  become: true
  vars:
    nginx_port: 80
    app_user: deploy
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Copy config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: restart nginx
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
END
    is(ym($code), $code, 'YAML: Ansible playbook');
}

# 14. Helm values
{
    my $code = <<'END';
replicaCount: 2
image:
  repository: my-org/my-app
  tag: latest
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
  targetPort: 8080
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
END
    is(ym($code), $code, 'YAML: Helm values');
}

# 15. complex sequence
{
    my $code = <<'END';
pipeline:
  - name: lint
    image: node:20
    commands:
      - npm ci
      - npm run lint
  - name: test
    image: node:20
    commands:
      - npm ci
      - npm test
    depends_on:
      - lint
  - name: build
    image: node:20
    commands:
      - npm run build
    depends_on:
      - test
END
    is(ym($code), $code, 'YAML: nested sequence pipeline');
}

# 16. Travis CI config
{
    my $code = <<'END';
language: perl
perl:
  - '5.36'
  - '5.38'
  - '5.40'
install:
  - cpanm --installdeps --notest .
script:
  - perl Makefile.PL
  - make
  - make test
notifications:
  email:
    on_success: never
    on_failure: always
END
    is(ym($code), $code, 'YAML: Travis CI config');
}

# 17. deeply nested
{
    my $code = <<'END';
a:
  b:
    c:
      d:
        e:
          value: deep
          list:
            - one
            - two
END
    is(ym($code), $code, 'YAML: deeply nested');
}

# 18. quoted strings
{
    my $code = <<'END';
strings:
  plain: hello world
  single_quoted: 'it''s quoted'
  double_quoted: "line1\nline2"
  explicit_string: '42'
  url: 'https://example.com/path?q=1&r=2'
  colon_in_value: 'host: localhost'
END
    is(ym($code), $code, 'YAML: quoted string varieties');
}

# 19. empty and null
{
    my $code = <<'END';
empty_map: {}
empty_list: []
null1: ~
null2:
null3: null
optional: null
END
    is(ym($code), $code, 'YAML: empty and null values');
}

# 20. multiline key
{
    my $code = <<'END';
server:
  host: 0.0.0.0
  port: 8080
  read_timeout_seconds: 30
  write_timeout_seconds: 30
  max_header_bytes: 1048576
  tls:
    enabled: true
    cert_file: /etc/ssl/certs/server.crt
    key_file: /etc/ssl/private/server.key
END
    is(ym($code), $code, 'YAML: server config block');
}

# 21. list of lists
{
    my $code = <<'END';
matrix:
  - - 1
    - 2
    - 3
  - - 4
    - 5
    - 6
  - - 7
    - 8
    - 9
END
    is(ym($code), $code, 'YAML: list of lists');
}

# 22. boolean and integer edge cases
{
    my $code = <<'END';
booleans:
  yes_val: true
  no_val: false
  on_val: 'on'
  off_val: 'off'
integers:
  octal: 0o755
  hex: 0xFF
  plain: 255
floats:
  inf: .inf
  nan: .nan
  normal: 1.5
END
    is(ym($code), $code, 'YAML: boolean and numeric edge cases');
}

# 23. Kubernetes Service
{
    my $code = <<'END';
apiVersion: v1
kind: Service
metadata:
  name: my-service
  labels:
    app: my-app
spec:
  selector:
    app: my-app
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8080
    - name: https
      protocol: TCP
      port: 443
      targetPort: 8443
  type: LoadBalancer
END
    is(ym($code), $code, 'YAML: Kubernetes Service');
}

# 24. flow collections
{
    my $code = <<'END';
point: {x: 1, y: 2}
colors: [red, green, blue]
matrix_row: [1, 0, 0]
flags: {debug: false, verbose: true, dry_run: false}
END
    is(ym($code), $code, 'YAML: flow collections');
}

# 25. CircleCI config
{
    my $code = <<'END';
version: 2.1
orbs:
  node: circleci/node@5
jobs:
  build-and-test:
    executor:
      name: node/default
      tag: '20'
    steps:
      - checkout
      - node/install-packages:
        pkg-manager: npm
      - run:
        name: Run tests
        command: npm test
workflows:
  build-and-test:
    jobs:
      - build-and-test
END
    is(ym($code), $code, 'YAML: CircleCI config');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
name: Alice
    age: 30
    active: true
END
    my $exp = <<'END';
name: Alice
  age: 30
  active: true
END
    is(ym($in), $exp, 'YAML: over-indented flat mapping normalised');
}

# 27
{
    my $in = <<'END';
user:
    id: 1
    name: Bob
    address:
        city: Springfield
END
    my $exp = <<'END';
user:
  id: 1
  name: Bob
  address:
    city: Springfield
END
    is(ym($in), $exp, 'YAML: 4-space indent normalised to 2-space');
}

# 28
{
    my $in = <<'END';
items:
    - alpha
    - beta
    - gamma
END
    my $exp = <<'END';
items:
  - alpha
  - beta
  - gamma
END
    is(ym($in), $exp, 'YAML: over-indented list normalised');
}

# 29
{
    my $in = <<'END';
services:
    web:
        image: nginx
        ports:
            - '80:80'
    db:
        image: postgres
END
    my $exp = <<'END';
services:
  web:
    image: nginx
    ports:
      - '80:80'
  db:
    image: postgres
END
    is(ym($in), $exp, 'YAML: deeply over-indented normalised');
}

# 30
{
    my $in = <<'END';
steps:
  - name: checkout
    uses: actions/checkout@v4
  - name: test
    run: npm test
    env:
        NODE_ENV: test
        CI: 'true'
END
    my $exp = <<'END';
steps:
  - name: checkout
    uses: actions/checkout@v4
  - name: test
    run: npm test
    env:
      NODE_ENV: test
      CI: 'true'
END
    is(ym($in), $exp, 'YAML: mixed indentation normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "name: test\nvalue: 42\n",
    "list:\n  - a\n  - b\n  - c\n",
    "nested:\n  key: value\n  inner:\n    deep: true\n",
    "services:\n  app:\n    image: nginx\n  db:\n    image: postgres\n",
    "items:\n  - id: 1\n    name: first\n  - id: 2\n    name: second\n",
    "config:\n  host: localhost\n  port: 5432\n  ssl: true\n  timeout: 30\n",
    "matrix:\n  include:\n    - os: ubuntu\n      version: '20'\n    - os: macos\n      version: '20'\n",
    "env:\n  production:\n    debug: false\n    log_level: error\n  development:\n    debug: true\n    log_level: debug\n",
    "pipeline:\n  - lint\n  - test\n  - build\n  - deploy\n",
    "credentials:\n  database:\n    host: db.example.com\n    port: 5432\n  cache:\n    host: cache.example.com\n    port: 6379\n",
) {
    my $once = ym($snippet);
    is(ym($once), $once, 'YAML: snippet idempotent');
}

done_testing;
