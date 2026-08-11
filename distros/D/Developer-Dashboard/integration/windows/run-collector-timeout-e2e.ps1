param(
    [string]$DashboardBin = "",

    [string]$PerlBin = "",

    [int]$TimeoutSeconds = 10,

    [int]$CleanupGraceSeconds = 30,

    [switch]$KeepTemp
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# One unique namespace per run so a persistent guest (windev/dockur) can never
# confuse leftovers from an earlier run with the processes under test.
$Marker = 'dd-timeout-e2e-' + [guid]::NewGuid().ToString('N')

# Purpose: resolve a PowerShell command object into a usable filesystem path.
# Input: a command object returned by Get-Command.
# Output: returns an executable path string or an empty string when no path exists.
function Get-CommandExecutablePath {
    param($CommandInfo)

    if (-not $CommandInfo) {
        return ""
    }

    foreach ($propertyName in @("Source", "Path", "Definition")) {
        $value = $CommandInfo.$propertyName
        if ($null -ne $value -and $value -ne "" -and (Test-Path $value)) {
            return $value
        }
    }

    return ""
}

# Purpose: resolve the Perl interpreter that will run the blocking collector command.
# Input: optional explicit Perl interpreter path.
# Output: returns the absolute Perl interpreter path or throws if none is found.
function Get-PerlBin {
    param([string]$Requested)

    $candidates = @()
    if ($Requested -ne "") {
        $candidates += $Requested
    }
    $candidates += @(
        "perl",
        "C:\Strawberry\perl\bin\perl.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        $commandPath = Get-CommandExecutablePath -CommandInfo $cmd
        if ($commandPath -ne "") {
            return $commandPath
        }
    }

    throw "Unable to find a Perl interpreter for the blocking collector command"
}

# Purpose: resolve the installed dashboard command path.
# Input: optional explicit dashboard executable path.
# Output: returns the dashboard executable path or throws if it is missing from PATH.
function Get-DashboardBin {
    param([string]$Requested)

    if ($Requested -ne "") {
        return $Requested
    }

    $cmd = Get-Command dashboard -ErrorAction SilentlyContinue
    $commandPath = Get-CommandExecutablePath -CommandInfo $cmd
    if ($commandPath -ne "") {
        return $commandPath
    }

    throw "Unable to find installed dashboard command in PATH"
}

# Purpose: throw with a labelled message when a condition does not hold.
# Input: boolean condition and a failure label.
# Output: returns nothing and throws when the condition is false.
function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not $Condition) {
        throw "ASSERT FAILED: $Label"
    }
    Write-Host "ASSERT OK: $Label"
}

# Purpose: list real guest processes whose command line carries a fragment.
# Input: command-line fragment string.
# Output: returns matching Win32_Process rows, never including this script's
# process. Callers must wrap the call in @() because PowerShell unrolls a
# returned empty array into nothing, which strict mode then treats as $null.
function Get-ProcessesMatching {
    param([Parameter(Mandatory = $true)][string]$Fragment)

    $escaped = [regex]::Escape($Fragment)
    return @(
        Get-CimInstance Win32_Process |
            Where-Object {
                ($null -ne $_.CommandLine) -and
                ($_.CommandLine -match $escaped) -and
                ($_.ProcessId -ne $PID)
            }
    )
}

# Purpose: apply the persistent-guest clean-slate rule by force-stopping stray
# dashboard runtime processes left behind by earlier smokes or E2E runs.
# Input: none.
# Output: returns nothing; logs and stops each stray process best-effort.
function Stop-StrayDashboardProcesses {
    foreach ($fragment in @('dd-timeout-e2e-', '.developer-dashboard', 'dashboard collector')) {
        foreach ($stray in @( Get-ProcessesMatching -Fragment $fragment )) {
            Write-Host ("clean-slate: stopping stray pid {0}: {1}" -f $stray.ProcessId, $stray.CommandLine)
            Stop-Process -Id $stray.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
}

# Purpose: prove the timed-out collector command subtree is really gone by
# polling live process state until the marker namespace is empty.
# Input: marker string and a bounded grace period in seconds.
# Output: returns nothing or throws when marker processes survive the grace period.
function Assert-MarkerProcessesGone {
    param(
        [Parameter(Mandatory = $true)][string]$MarkerText,
        [Parameter(Mandatory = $true)][int]$GraceSeconds
    )

    $deadline = (Get-Date).AddSeconds($GraceSeconds)
    while ((Get-Date) -lt $deadline) {
        $survivors = @( Get-ProcessesMatching -Fragment $MarkerText )
        if ($survivors.Count -eq 0) {
            Assert-True -Condition $true -Label "no process carrying marker $MarkerText survived the timeout"
            return
        }
        Start-Sleep -Milliseconds 500
    }

    $survivors = @( Get-ProcessesMatching -Fragment $MarkerText )
    foreach ($survivor in $survivors) {
        Write-Host ("SURVIVOR pid {0}: {1}" -f $survivor.ProcessId, $survivor.CommandLine)
    }
    throw "ASSERT FAILED: $($survivors.Count) marker process(es) survived $GraceSeconds seconds after the timeout"
}

# Purpose: run one dashboard CLI invocation and return its stdout text.
# Input: dashboard executable path plus argument array and a label.
# Output: returns captured stdout and throws on a non-zero exit code.
function Invoke-Dashboard {
    param(
        [Parameter(Mandatory = $true)][string]$Dashboard,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Write-Host "==> $Label"
    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $Dashboard @Arguments 2>&1 | Out-String
    }
    finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code ${LASTEXITCODE}:`n$output"
    }
    return $output
}

$Perl = Get-PerlBin -Requested $PerlBin
$Dashboard = Get-DashboardBin -Requested $DashboardBin
Write-Host "perl:      $Perl"
Write-Host "dashboard: $Dashboard"
Write-Host "marker:    $Marker"

Write-Host "==> clean-slate: stop stray dashboard processes from earlier runs"
Stop-StrayDashboardProcesses

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) $Marker
$homeRoot = Join-Path $tempRoot "home"
$projectRoot = Join-Path $tempRoot "project"
$flagRoot = Join-Path $tempRoot "flags"
$runtimeRoot = Join-Path $projectRoot ".developer-dashboard"
$configRoot = Join-Path $runtimeRoot "config"
New-Item -ItemType Directory -Force -Path $homeRoot, $projectRoot, $flagRoot, $configRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot ".git") | Out-Null

$env:HOME = $homeRoot
$env:USERPROFILE = $homeRoot
# Runtime state roots are namespaced by a username the dashboard reads from
# DD_STATE_ROOT_USER, USER, or LOGNAME before falling back to getpwuid, which
# Windows does not implement. A non-interactive Windows session (a job runner,
# an SSH command, a service) sets none of the first three, so pin the explicit
# seam here: without it every dashboard invocation in the guest dies before it
# can even reach the collector under test.
$env:DD_STATE_ROOT_USER = 'dd-timeout-e2e'

# The blocking collector command: a Perl blocker that first spawns an
# asynchronous descendant (so taskkill's tree mode is really exercised), then
# records both pids as proof the subtree existed, then blocks far longer than
# the configured timeout. Only a real interrupt can bring the run back early.
$blockerPath = Join-Path $tempRoot "dd-timeout-blocker.pl"
@'
use strict;
use warnings;

$| = 1;
my ( $marker, $flag_dir ) = @ARGV;
die "Usage: dd-timeout-blocker.pl <marker> <flag-dir>\n" if !defined $flag_dir;
my $descendant_pid = system( 1, $^X, '-e', 'sleep 1 for 1 .. 3600', "descendant-$marker" );
open my $descendant_fh, '>', "$flag_dir/descendant.pid" or die "Unable to write descendant pid: $!";
print {$descendant_fh} $descendant_pid;
close $descendant_fh or die "Unable to close descendant pid file: $!";
open my $blocker_fh, '>', "$flag_dir/blocker.pid" or die "Unable to write blocker pid: $!";
print {$blocker_fh} $$;
close $blocker_fh or die "Unable to close blocker pid file: $!";
print "blocker-output-before-deadline\n";
sleep 1 for 1 .. 3600;
'@ | Set-Content -Path $blockerPath -Encoding ASCII

$config = [ordered]@{
    collectors = @(
        [ordered]@{
            name    = "timeout.e2e"
            command = "& '$Perl' '$blockerPath' '$Marker' '$flagRoot'"
            timeout = $TimeoutSeconds
            cwd     = "home"
        },
        [ordered]@{
            name    = "alive.e2e"
            command = "Write-Output 'agent-alive-ok'"
            timeout = 60
            cwd     = "home"
        }
    )
}
$config | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $configRoot "config.json") -Encoding ASCII

Push-Location $projectRoot
try {
    Write-Host "==> trigger the blocking collector (timeout ${TimeoutSeconds}s, block 3600s)"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $runOutput = Invoke-Dashboard -Dashboard $Dashboard -Arguments @("collector", "run", "timeout.e2e") -Label "dashboard collector run timeout.e2e"
    $stopwatch.Stop()
    $elapsed = [int]$stopwatch.Elapsed.TotalSeconds
    Write-Host "collector run returned after ${elapsed}s"
    Write-Host "collector run result:"
    Write-Host $runOutput

    # The run command returning at all with exit 0 proves the collector agent
    # did not crash; the elapsed bound proves the blocking command really was
    # interrupted near the configured timeout instead of running to completion.
    Assert-True -Condition ($elapsed -ge $TimeoutSeconds) -Label "run blocked at least as long as the configured timeout (${elapsed}s >= ${TimeoutSeconds}s)"
    Assert-True -Condition ($elapsed -le ($TimeoutSeconds + 120)) -Label "run was interrupted near the configured timeout (${elapsed}s <= $($TimeoutSeconds + 120)s, not the 3600s block)"

    $runResult = $runOutput | ConvertFrom-Json
    Assert-True -Condition ($runResult.timed_out -eq 1) -Label "collector run result reports timed_out=1"
    Assert-True -Condition ($runResult.exit_code -eq 124) -Label "collector run result reports the canonical timeout exit code 124"
    Assert-True -Condition ($runResult.stdout -match 'blocker-output-before-deadline') -Label "stdout emitted before the deadline is preserved on the timed-out result"

    # Prove the blocker really started and really spawned its descendant, so a
    # command that never ran cannot masquerade as a passing timeout.
    Assert-True -Condition (Test-Path (Join-Path $flagRoot "blocker.pid")) -Label "blocker recorded its pid before blocking"
    Assert-True -Condition (Test-Path (Join-Path $flagRoot "descendant.pid")) -Label "blocker spawned and recorded its asynchronous descendant"

    Write-Host "==> verify the whole marker-tagged command subtree is gone"
    Assert-MarkerProcessesGone -MarkerText $Marker -GraceSeconds $CleanupGraceSeconds
    foreach ($pidFile in @("blocker.pid", "descendant.pid")) {
        $recordedPid = [int](Get-Content -Path (Join-Path $flagRoot $pidFile))
        $alive = Get-Process -Id $recordedPid -ErrorAction SilentlyContinue
        Assert-True -Condition ($null -eq $alive) -Label "$pidFile process $recordedPid is no longer alive"
    }

    Write-Host "==> verify the cached collector status reflects the timeout"
    $statusOutput = Invoke-Dashboard -Dashboard $Dashboard -Arguments @("collector", "status", "timeout.e2e") -Label "dashboard collector status timeout.e2e"
    Write-Host $statusOutput
    $status = $statusOutput | ConvertFrom-Json
    Assert-True -Condition ($status.timed_out -eq 1) -Label "cached collector status reports timed_out=1"
    Assert-True -Condition ($status.last_exit_code -eq 124) -Label "cached collector status reports last_exit_code=124"
    Assert-True -Condition ($status.running -eq 0) -Label "cached collector status reports running=0 after the timeout"

    Write-Host "==> verify the collector agent survived: run a healthy collector after the timeout"
    $aliveOutput = Invoke-Dashboard -Dashboard $Dashboard -Arguments @("collector", "run", "alive.e2e") -Label "dashboard collector run alive.e2e"
    Write-Host $aliveOutput
    $aliveResult = $aliveOutput | ConvertFrom-Json
    Assert-True -Condition ($aliveResult.exit_code -eq 0) -Label "post-timeout healthy collector run exits 0"
    Assert-True -Condition ($aliveResult.timed_out -eq 0) -Label "post-timeout healthy collector run is not marked timed out"
    Assert-True -Condition ($aliveResult.stdout -match 'agent-alive-ok') -Label "post-timeout healthy collector run captured its output"
}
finally {
    Pop-Location
    foreach ($leftover in @( Get-ProcessesMatching -Fragment $Marker )) {
        Write-Host ("cleanup: stopping leftover pid {0}: {1}" -f $leftover.ProcessId, $leftover.CommandLine)
        Stop-Process -Id $leftover.ProcessId -Force -ErrorAction SilentlyContinue
    }
    if (-not $KeepTemp) {
        try {
            Remove-Item -Recurse -Force $tempRoot
        }
        catch {
            Write-Warning ("Unable to remove timeout E2E temp root {0}: {1}" -f $tempRoot, $_.Exception.Message)
        }
    }
}

Write-Host "Windows collector timeout E2E passed"

<#
__END__

=head1 NAME

run-collector-timeout-e2e.ps1 - prove collector command timeouts interrupt a blocking command on real Windows

=head1 SYNOPSIS

  powershell -ExecutionPolicy Bypass -File integration/windows/run-collector-timeout-e2e.ps1
  powershell -ExecutionPolicy Bypass -File integration/windows/run-collector-timeout-e2e.ps1 -TimeoutSeconds 10 -KeepTemp

=head1 DESCRIPTION

This in-guest End-to-End script validates the collector command timeout on a
real QEMU Windows guest against an installed C<Developer::Dashboard>. It
applies the persistent-guest clean-slate rule first (stray dashboard runtime
processes are stopped), then provisions a hermetic temporary Windows home and
project layer, pins the C<DD_STATE_ROOT_USER> seam so a non-interactive Windows
session never reaches the POSIX-only C<getpwuid> username fallback, and writes a
config that defines one collector with a short timeout whose
command blocks for an hour: a Perl blocker that spawns an asynchronous
descendant process, records both pids, prints one line of output, and sleeps.
Every process in that command subtree carries a unique per-run marker on its
command line.

The script then triggers C<dashboard collector run> and asserts the full
timeout contract with real process-state evidence, not just exit codes: the
run returns near the configured timeout instead of the one-hour block, the
structured result reports C<timed_out> with exit code 124 and preserves the
pre-deadline stdout, the blocker and its descendant are both really gone from
C<Win32_Process> within a bounded grace period, the cached collector status
reflects the timeout, and a healthy collector run afterwards proves the
collector agent itself survived without crashing.

Run it over SSH on a prepared QEMU guest, through the C<windev> guest, or
through the Dockur Windows guest's shared-folder job channel. The installed
C<dashboard> and a Perl interpreter are resolved from PATH unless
C<-DashboardBin> or C<-PerlBin> point at explicit executables. The companion
host-side driver F<run-dockur-collector-timeout-e2e.sh> installs a freshly built
tarball into the Dockur guest and runs this script there in one repeatable step.

=cut
#>
