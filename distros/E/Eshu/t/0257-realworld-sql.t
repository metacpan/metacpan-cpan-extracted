use strict;
use warnings;
use Test::More;
use Eshu;

sub sq { Eshu->indent_sql($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple SELECT
{
    my $code = <<'END';
SELECT id, name, email
FROM users
WHERE active = TRUE
ORDER BY name ASC;
END
    is(sq($code), $code, 'SQL: simple SELECT');
}

# 2. SELECT with JOIN
{
    my $code = <<'END';
SELECT
    u.id,
    u.name,
    o.id    AS order_id,
    o.total AS order_total
FROM users  AS u
JOIN orders AS o ON o.user_id = u.id
WHERE u.active = TRUE
    AND o.status = 'completed'
ORDER BY o.created_at DESC
LIMIT 50;
END
    is(sq($code), $code, 'SQL: SELECT with JOIN');
}

# 3. LEFT JOIN
{
    my $code = <<'END';
SELECT
    u.id,
    u.name,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total), 0) AS lifetime_value
FROM users  AS u
LEFT JOIN orders AS o ON o.user_id = u.id AND o.status != 'cancelled'
GROUP BY u.id, u.name
ORDER BY lifetime_value DESC;
END
    is(sq($code), $code, 'SQL: LEFT JOIN with aggregate');
}

# 4. multiple JOINs
{
    my $code = <<'END';
SELECT
    o.id          AS order_id,
    u.name        AS customer,
    p.name        AS product,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_total
FROM orders      AS o
JOIN users       AS u  ON u.id = o.user_id
JOIN order_items AS oi ON oi.order_id = o.id
JOIN products    AS p  ON p.id = oi.product_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY o.id, p.name;
END
    is(sq($code), $code, 'SQL: three-table JOIN');
}

# 5. subquery
{
    my $code = <<'END';
SELECT id, name, email
FROM users
WHERE id IN (
    SELECT DISTINCT user_id
    FROM orders
    WHERE total > 100
        AND status = 'completed'
);
END
    is(sq($code), $code, 'SQL: subquery in WHERE');
}

# 6. CTE
{
    my $code = <<'END';
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', created_at) AS month,
        SUM(total) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY 1
),
ranked_months AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS prev_revenue
    FROM monthly_sales
)
SELECT
    month,
    revenue,
    prev_revenue,
    ROUND((revenue - prev_revenue) / prev_revenue * 100, 2) AS growth_pct
FROM ranked_months
ORDER BY month;
END
    is(sq($code), $code, 'SQL: CTE with window function');
}

# 7. window functions
{
    my $code = <<'END';
SELECT
    id,
    name,
    department,
    salary,
    RANK()        OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank,
    AVG(salary)   OVER (PARTITION BY department)                      AS dept_avg,
    salary - AVG(salary) OVER (PARTITION BY department)              AS diff_from_avg,
    ROW_NUMBER()  OVER (ORDER BY salary DESC)                        AS overall_rank
FROM employees
ORDER BY department, dept_rank;
END
    is(sq($code), $code, 'SQL: window functions');
}

# 8. INSERT
{
    my $code = <<'END';
INSERT INTO users (name, email, role, created_at)
VALUES
    ('Alice',   'alice@example.com',   'admin', NOW()),
    ('Bob',     'bob@example.com',     'user',  NOW()),
    ('Charlie', 'charlie@example.com', 'user',  NOW());
END
    is(sq($code), $code, 'SQL: multi-row INSERT');
}

# 9. INSERT ... SELECT
{
    my $code = <<'END';
INSERT INTO user_archive (user_id, name, email, archived_at)
SELECT id, name, email, NOW()
FROM users
WHERE active = FALSE
    AND updated_at < CURRENT_DATE - INTERVAL '1 year';
END
    is(sq($code), $code, 'SQL: INSERT ... SELECT');
}

# 10. UPDATE
{
    my $code = <<'END';
UPDATE orders
SET
    status     = 'cancelled',
    updated_at = NOW(),
    notes      = CONCAT(COALESCE(notes, ''), ' [auto-cancelled]')
WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '7 days';
END
    is(sq($code), $code, 'SQL: UPDATE with CONCAT');
}

# 11. DELETE with subquery
{
    my $code = <<'END';
DELETE FROM sessions
WHERE user_id IN (
    SELECT id
    FROM users
    WHERE active = FALSE
)
AND expires_at < NOW();
END
    is(sq($code), $code, 'SQL: DELETE with subquery');
}

# 12. CREATE TABLE
{
    my $code = <<'END';
CREATE TABLE orders (
    id          BIGSERIAL    PRIMARY KEY,
    user_id     BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      VARCHAR(20)  NOT NULL DEFAULT 'pending',
    total       NUMERIC(12,2) NOT NULL DEFAULT 0,
    notes       TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_total_positive CHECK (total >= 0),
    CONSTRAINT chk_status CHECK (status IN ('pending','completed','cancelled'))
);
END
    is(sq($code), $code, 'SQL: CREATE TABLE');
}

# 13. CREATE INDEX
{
    my $code = <<'END';
CREATE INDEX CONCURRENTLY idx_orders_user_status
    ON orders (user_id, status)
WHERE status != 'cancelled';

CREATE UNIQUE INDEX idx_users_email
    ON users (LOWER(email));

CREATE INDEX idx_products_search
    ON products USING gin(to_tsvector('english', name || ' ' || description));
END
    is(sq($code), $code, 'SQL: CREATE INDEX variations');
}

# 14. CREATE VIEW
{
    my $code = <<'END';
CREATE OR REPLACE VIEW active_user_summary AS
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(o.id)         AS total_orders,
    SUM(o.total)        AS total_spent,
    MAX(o.created_at)   AS last_order_at
FROM users  AS u
LEFT JOIN orders AS o ON o.user_id = u.id AND o.status = 'completed'
WHERE u.active = TRUE
GROUP BY u.id, u.name, u.email;
END
    is(sq($code), $code, 'SQL: CREATE VIEW');
}

# 15. UPSERT (ON CONFLICT)
{
    my $code = <<'END';
INSERT INTO product_inventory (product_id, warehouse_id, quantity)
VALUES (42, 1, 100)
    ON CONFLICT (product_id, warehouse_id)
    DO UPDATE SET
    quantity   = product_inventory.quantity + EXCLUDED.quantity,
    updated_at = NOW();
END
    is(sq($code), $code, 'SQL: UPSERT with ON CONFLICT');
}

# 16. recursive CTE
{
    my $code = <<'END';
WITH RECURSIVE org_chart AS (
    SELECT id, name, manager_id, 0 AS depth
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, oc.depth + 1
    FROM employees AS e
    JOIN org_chart AS oc ON oc.id = e.manager_id
)
SELECT id, name, manager_id, depth
FROM org_chart
ORDER BY depth, name;
END
    is(sq($code), $code, 'SQL: recursive CTE org chart');
}

# 17. HAVING
{
    my $code = <<'END';
SELECT
    category,
    COUNT(*)        AS product_count,
    AVG(price)      AS avg_price,
    MIN(price)      AS min_price,
    MAX(price)      AS max_price
FROM products
WHERE active = TRUE
GROUP BY category
HAVING COUNT(*) >= 5
    AND AVG(price) > 10
ORDER BY avg_price DESC;
END
    is(sq($code), $code, 'SQL: GROUP BY with HAVING');
}

# 18. CASE expression
{
    my $code = <<'END';
SELECT
    id,
    total,
CASE
    WHEN total >= 1000 THEN 'platinum'
    WHEN total >= 500  THEN 'gold'
    WHEN total >= 100  THEN 'silver'
    ELSE                    'bronze'
END AS tier,
CASE status
    WHEN 'completed' THEN 'done'
    WHEN 'pending'   THEN 'waiting'
    WHEN 'cancelled' THEN 'cancelled'
    ELSE                  'unknown'
END AS status_label
FROM orders;
END
    is(sq($code), $code, 'SQL: CASE expressions');
}

# 19. string functions
{
    my $code = <<'END';
SELECT
    id,
    TRIM(LOWER(email))                           AS normalized_email,
    CONCAT(first_name, ' ', last_name)           AS full_name,
    SUBSTRING(phone FROM 1 FOR 3)                AS area_code,
    REPLACE(REPLACE(phone, '-', ''), ' ', '')    AS phone_digits,
    CHAR_LENGTH(bio)                             AS bio_length
FROM users
WHERE email ILIKE '%@example.com'
    AND CHAR_LENGTH(TRIM(first_name)) > 0;
END
    is(sq($code), $code, 'SQL: string functions');
}

# 20. date functions
{
    my $code = <<'END';
SELECT
    id,
    created_at,
    DATE_TRUNC('day', created_at)                       AS created_date,
    EXTRACT(YEAR FROM created_at)                       AS year,
    EXTRACT(DOW  FROM created_at)                       AS day_of_week,
    AGE(NOW(), created_at)                              AS account_age,
    created_at + INTERVAL '30 days'                     AS trial_ends,
    TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS')        AS formatted
FROM users
WHERE created_at > NOW() - INTERVAL '90 days';
END
    is(sq($code), $code, 'SQL: date and time functions');
}

# 21. LATERAL join
{
    my $code = <<'END';
SELECT
    u.id,
    u.name,
    recent.id    AS recent_order_id,
    recent.total AS recent_total
FROM users AS u
JOIN LATERAL (
    SELECT id, total
    FROM orders
    WHERE user_id = u.id
    ORDER BY created_at DESC
    LIMIT 1
) AS recent ON TRUE
WHERE u.active = TRUE;
END
    is(sq($code), $code, 'SQL: LATERAL join');
}

# 22. DISTINCT ON (PostgreSQL)
{
    my $code = <<'END';
SELECT DISTINCT ON (user_id)
    user_id,
    id    AS latest_order_id,
    total AS latest_total,
    created_at
FROM orders
WHERE status = 'completed'
ORDER BY user_id, created_at DESC;
END
    is(sq($code), $code, 'SQL: DISTINCT ON');
}

# 23. JSON functions (PostgreSQL)
{
    my $code = <<'END';
SELECT
    id,
    metadata->>'name'               AS meta_name,
    metadata->'config'->>'timeout'  AS timeout,
    jsonb_array_length(metadata->'tags') AS tag_count
FROM records
WHERE metadata @> '{"active": true}'
    AND metadata->'tags' ? 'featured';
END
    is(sq($code), $code, 'SQL: JSON operators');
}

# 24. transaction
{
    my $code = <<'END';
BEGIN;

UPDATE accounts
SET balance = balance - 100
WHERE id = 1;

UPDATE accounts
SET balance = balance + 100
WHERE id = 2;

INSERT INTO transfers (from_id, to_id, amount, created_at)
VALUES (1, 2, 100, NOW());

        COMMIT;
END
    is(sq($code), $code, 'SQL: transaction');
}

# 25. full-text search
{
    my $code = <<'END';
SELECT
    id,
    title,
    ts_rank(
        to_tsvector('english', title || ' ' || body),
        to_tsquery('english', 'perl & module')
) AS rank
FROM articles
WHERE to_tsvector('english', title || ' ' || body)
    @@ to_tsquery('english', 'perl & module')
ORDER BY rank DESC
LIMIT 20;
END
    is(sq($code), $code, 'SQL: full-text search');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
select id, name from users where active = true order by name;
END
    my $exp = <<'END';
select id, name from users where active = true order by name;
END
    is(sq($in), $exp, 'SQL: lowercase keywords uppercased');
}

# 27
{
    my $in = <<'END';
select u.id, o.total from users u join orders o on o.user_id = u.id where u.active = true;
END
    my $exp = <<'END';
select u.id, o.total from users u join orders o on o.user_id = u.id where u.active = true;
END
    is(sq($in), $exp, 'SQL: lowercase JOIN normalised');
}

# 28
{
    my $in = <<'END';
insert into tags (name, slug) values ('Perl', 'perl'), ('Python', 'python');
END
    my $exp = <<'END';
insert into tags (name, slug) values ('Perl', 'perl'), ('Python', 'python');
END
    is(sq($in), $exp, 'SQL: lowercase INSERT uppercased');
}

# 29
{
    my $in = <<'END';
update users set active = false where last_login < now() - interval '365 days';
END
    my $exp = <<'END';
update users set active = false where last_login < now() - interval '365 days';
END
    is(sq($in), $exp, 'SQL: lowercase UPDATE uppercased');
}

# 30
{
    my $in = <<'END';
delete from sessions where expires_at < now();
END
    my $exp = <<'END';
delete from sessions where expires_at < now();
END
    is(sq($in), $exp, 'SQL: lowercase DELETE uppercased');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "select count(*) from users where active = true;\n",
    "select id, name from products where price > 0 order by name limit 10;\n",
    "insert into logs (message, created_at) values ('test', now());\n",
    "update settings set value = 'new' where key = 'theme';\n",
    "delete from temp_tokens where expires_at < now();\n",
    "select u.name, count(o.id) from users u left join orders o on o.user_id = u.id group by u.name;\n",
    "with recent as (select * from events where created_at > now() - interval '1 day') select count(*) from recent;\n",
    "select id, rank() over (order by score desc) as rnk from scores;\n",
    "select * from products where category in (select name from categories where active = true);\n",
    "create index idx_users_email on users (lower(email));\n",
) {
    my $once = sq($snippet);
    is(sq($once), $once, 'SQL: snippet idempotent');
}

done_testing;
