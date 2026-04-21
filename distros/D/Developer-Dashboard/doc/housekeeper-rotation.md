# Housekeeper Rotation

## Purpose

The built-in `housekeeper` collector now owns two jobs:

- remove stale dashboard-owned temp artefacts from `/tmp`
- rotate persisted collector transcript logs when a collector declares a retention rule

## Collector Config

Housekeeper reads retention from either `rotation` or `rotations` on each
collector definition in `config/config.json`.

Example:

```json
{
  "collectors": [
    {
      "name": "housekeeper",
      "interval": 60,
      "indicator": {
        "icon": "🧹"
      }
    },
    {
      "name": "build.log",
      "command": "./build-status",
      "cwd": "home",
      "interval": 30,
      "rotation": {
        "lines": 100,
        "days": 1
      }
    }
  ]
}
```

## Retention Keys

- `lines`: keep only the trailing `N` lines of the collector transcript
- `minute` or `minutes`
- `hour` or `hours`
- `day` or `days`
- `week` or `weeks`
- `month` or `months`

Time-based keys keep only log entries whose transcript timestamp is newer than
the configured retention window. Multiple time keys are additive, so
`days: 1` plus `hours: 6` keeps the last 30 hours. If both line and time
limits are present, housekeeper applies both rules.

Collector transcript headers now use the machine's local system time with an
explicit numeric timezone offset such as `+0100`. Housekeeper keeps backward
compatibility with older transcript entries that still use UTC `Z`
timestamps, so existing retained logs continue to rotate correctly after the
runtime switches to local-offset collector timestamps.

## Built-In Housekeeper Override

The built-in `housekeeper` collector stays present even when the config file is
otherwise empty. A user override named `housekeeper` now merges with that
built-in definition, so changing only `interval` or adding `indicator`
metadata does not require restating the built-in Perl `code` or `cwd`.

## Verification

Current regression coverage for this contract lives in:

- `t/07-core-units.t`
- `t/05-cli-smoke.t`
