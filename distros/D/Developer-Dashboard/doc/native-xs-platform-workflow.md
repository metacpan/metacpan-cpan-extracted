# Cross-platform XS build and watcher checks

The platform compatibility workflow builds the Dashboard XS extension after
installing project dependencies and before running the complete test suite.
Unix runners use Bash, Perl and make. Windows runners use PowerShell, the Perl
installed by the workflow, and gmake; Git Bash's unrelated Perl must not be
used for the XS build or coverage-tool setup. The normal distribution build
remains the source of the extension mapping.

The Windows ARM64 watcher job runs on windows-11-arm and verifies the runner's
architecture before checking Perl's configured architecture. The hosted image
observed on 2026-10-31 provided an ARM64 runner but only
MSWin32-x64-multi-thread Perl. The workflow therefore emits a visible warning
and skips dependency installation, XS compilation and watcher testing when
native ARM64 Perl is unavailable. It does not report that as a native ARM64
test pass. If a native ARM64 Perl is present, the job builds the extension and
runs the watcher contract test with blib/arch on @INC.

The Windows x64 job must keep XS compilation and Devel::Cover setup in
PowerShell. A hosted run on 2026-10-31 exposed that invoking `perl Makefile.PL`
from Git Bash selected its MSYS Perl, whose @INC lacks ExtUtils::MakeMaker,
even though the workflow's Windows Perl was installed correctly. Separate
Windows and Unix steps now keep each platform on its configured Perl and path
separator. The next hosted run exposed a separate Makefile.PL portability
defect: Windows supplied USERPROFILE but no HOME, and Makefile.PL interpolated
the missing HOME while searching for local::lib. Makefile.PL now prefers HOME,
falls back to USERPROFILE, and safely uses only `.perl5` if neither is set. The
Docker regression covers all three cases. Hosted verification of this fix is
pending.

The active Linux coverage job builds the Linux System Menu helper as part of
the native XS extension. Before `make`, it installs both
`libayatana-appindicator3-dev` and `libgtk-3-dev`; these packages provide the
`ayatana-appindicator3-0.1` and `gtk+-3.0` pkg-config metadata and headers used
by `native/system_menu_helper_linux.c`. This strict setting keeps CI from
silently omitting the helper if dependency installation or pkg-config
detection fails. Ordinary Linux source-distribution builds may omit this
optional desktop helper with an explicit configure notice when the modules are
unavailable, allowing headless CPAN testers to run the rest of the test suite.

macOS continues to install Mac::FSEvents as its platform-specific event
backend. Linux inotify and Windows directory notifications are provided by
the shared XS extension. No workflow job installs or requires
FFI::Platypus or FFI::CheckLib.

Run the watcher test in the development container. The static workflow
contract test (230-native-xs-workflow) was removed on 2026-11-23 together with
the GitHub workflow files it checked:

    d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/669-problem48-inotify-watch.t

The 2026-10-31 Docker verification of version 6.14 passed all 290 test files
and 25,955 tests. Statement, branch, condition, and subroutine coverage each
reached 100.0 percent. The Watch.pm loader regression was included in that full
run, and no module-redefinition warnings were emitted. After the first push,
Linux x64 and ARM64 passed; the Windows x64 build failed in the Git Bash Perl
selection described above, and Windows ARM64 lacked a native Perl runtime.
The Windows shell correction and explicit ARM64-unavailable warning are now
covered by the focused Docker workflow test; both require a hosted rerun before
their results can be claimed.
