# Lifecycle fixture

This disposable graph demonstrates `service_healthy` followed by `service_completed_successfully`. The preparation command is explicitly a stand-in, not a database migration implementation. No ports or persistent volumes are published/created by the model.

Run `docker compose -f compose.yaml config -q` first. A live test is `docker compose -f compose.yaml up` in this directory; inspect logs to confirm dependency readiness, successful preparation, and subsequent app startup. Stop with Ctrl-C and run `docker compose -f compose.yaml down` for this lab only.

For a negative test in a temporary copy, change the preparation command to exit nonzero and verify the application does not start. Do not enable automatic retries to hide the failure. Image tags are teaching defaults; pin approved digests for reproducible tests.
