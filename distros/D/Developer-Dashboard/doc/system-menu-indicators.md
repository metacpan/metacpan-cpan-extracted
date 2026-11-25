# System menu indicator configuration

`Developer::Dashboard::SystemMenu->items_for_platform` is a deterministic
configuration projection. The private `web-foreground` runtime passes its
merged configuration and shared indicator store to
`Developer::Dashboard::SystemMenu::Runner`; the runner starts the menu only
when at least one current indicator is enabled for the host platform.

The method accepts the merged dashboard configuration, an array of current
indicator records, and a platform key. For each configured indicator it reads
the matching opt-in selector from `indicator`:

1. `macos`
2. `windows`
3. `ubuntu`

Only JSON booleans or scalar `0` and `1` are accepted when a selector is
defined. Missing and false selectors disable the entry. Invalid supported
selectors fail visibly, including selectors for platforms other than the
requested platform. The result keeps configuration order and includes only
enabled indicators that have a current state, represented by their name and
icon. Other platform names return an empty list.

Example configuration:

```json
{
  "indicators": [
    { "name": "build", "indicator": { "macos": true, "windows": true } },
    { "name": "tests", "indicator": { "ubuntu": true } }
  ]
}
```

The projection is independent of AppKit, Windows notification-area APIs, and
GTK. It does not launch the native UI by itself. `d2 serve` launches its
foreground web-service process, which owns the menu worker for the service's
lifetime and stops and joins that worker on normal server exit or error. A
disabled or unsupported host selection does not load the native adapter, and
the existing `d2 ps1` output is unchanged. The native System::Menu
adapter starts the platform helper in a controlled GoRoutine worker and
forwards the projected entries while owning helper shutdown. On Ubuntu,
the helper uses Ayatana AppIndicator3 and a GTK menu; rendered status icons are
kept in a private temporary icon-theme directory and removed when the helper
shuts down. Building the helper requires the Ayatana AppIndicator3 and GTK3
development packages, and runtime requires a desktop session with AppIndicator
support. On Linux, `Makefile.PL` checks for both pkg-config modules and omits
the optional helper target with a visible notice when they are missing. This
allows CPAN testers without desktop development headers to build and test the
distribution; invoking the System Menu without its helper still reports a
clear error. Set `DD_REQUIRE_SYSTEM_MENU_HELPER=1` to make missing modules
fatal, as the Linux coverage workflow does.
The helper reports a clear error when no desktop session is available.
Source-contract and compile tests do not prove that a desktop shell visibly
displayed the menu.

The focused test runs inside the project development container:

```sh
  d2 docker compose exec --workdir /work dev prove -lv t/239-system-menu-config.t t/241-system-menu-runner.t t/242-system-menu-bundle.t t/243-system-menu-linux-indicator-api.t
```

The development image, Linux GitHub workflows, and the published Docker image
install `libayatana-appindicator3-dev` and `libgtk-3-dev` before building the
native helper. Linux workflow jobs require the helper and fail if detection
does not find both GTK and Ayatana modules. The macOS helper is compiled with Objective-C ARC and deprecated
AppKit API diagnostics treated as errors. Windows runs its full test suite with
Test::Harness but omits Devel::Cover because that instrumentation distribution
does not configure on the supported Windows runner.
