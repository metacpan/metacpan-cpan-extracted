CREATE TABLE IF NOT EXISTS usage_events (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  request_id TEXT,
  api_format TEXT,
  endpoint TEXT,
  api_key_id TEXT,
  provider TEXT,
  engine TEXT,
  model TEXT,
  node_id TEXT,
  route_url TEXT,
  status_code INTEGER,
  ok BOOLEAN NOT NULL DEFAULT FALSE,
  duration_ms INTEGER,
  input_tokens BIGINT NOT NULL DEFAULT 0,
  output_tokens BIGINT NOT NULL DEFAULT 0,
  total_tokens BIGINT NOT NULL DEFAULT 0,
  tool_calls BIGINT NOT NULL DEFAULT 0,
  cost_input_usd DOUBLE PRECISION NOT NULL DEFAULT 0,
  cost_output_usd DOUBLE PRECISION NOT NULL DEFAULT 0,
  cost_total_usd DOUBLE PRECISION NOT NULL DEFAULT 0,
  error_type TEXT,
  error_message TEXT
);

CREATE INDEX IF NOT EXISTS usage_events_created_at_idx ON usage_events(created_at);
CREATE INDEX IF NOT EXISTS usage_events_api_key_id_idx ON usage_events(api_key_id);
CREATE INDEX IF NOT EXISTS usage_events_model_idx ON usage_events(model);
