# Data Directory

This directory is required for Lib::Pepper tests and examples.

The config file (examples/config/pepper_config.xml) uses relative paths that expect these subdirectories to exist:

- `logging/` - Log files
- `logging/archive/` - Archived log files
- `runtime/` - Runtime working directory for database and temporary files

These directories are created automatically during `make test`.
