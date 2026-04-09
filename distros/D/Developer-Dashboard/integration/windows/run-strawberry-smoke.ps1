param(
    [Parameter(Mandatory = $true)]
    [string]$Tarball,

    [string]$Port = "7890",

    [string]$PerlBin = "",

    [string]$DashboardBin = "",

    [string]$StatusRoot = "",

    [switch]$SkipCpanmTests,

    [switch]$KeepTemp
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Purpose: run a command with logging and fail on non-zero exit.
# Input: Command array and an optional label string.
# Output: writes the command to stdout and throws on a non-zero exit code.
function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Command,

        [string]$Label = "command",

        [string]$LogPath = ""
    )

    Write-Host "==> $Label"
    Write-Host ($Command -join ' ')
    $savedErrorActionPreference = $ErrorActionPreference
    $command_args = @()
    if ($Command.Length -gt 1) {
        $command_args = $Command[1..($Command.Length - 1)]
    }
    try {
        $ErrorActionPreference = 'Continue'
        if ($LogPath -ne "") {
            & $Command[0] @command_args 2>&1 | Tee-Object -FilePath $LogPath
        }
        else {
            & $Command[0] @command_args
        }
    }
    finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }

    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        if ($LogPath -ne "" -and (Test-Path $LogPath)) {
            throw "$Label failed with exit code $exitCode; see $LogPath"
        }
        throw "$Label failed with exit code $exitCode"
    }
}

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

# Purpose: resolve an executable path through Windows where.exe for commands
# that PowerShell can see by name but does not expose as a usable filesystem path.
# Input: executable name such as perl.exe.
# Output: returns the first matching filesystem path or an empty string.
function Get-WhereExecutablePath {
    param([Parameter(Mandatory = $true)][string]$CommandName)

    $where = Get-Command where.exe -ErrorAction SilentlyContinue
    if (-not $where) {
        return ""
    }

    $matches = & $where.Source $CommandName 2>$null
    if ($LASTEXITCODE -ne 0) {
        return ""
    }

    foreach ($match in @($matches)) {
        if ($null -ne $match -and $match -ne "" -and (Test-Path $match)) {
            return $match
        }
    }

    return ""
}

# Purpose: resolve the Strawberry Perl interpreter path for the Windows smoke.
# Input: optional explicit Perl interpreter path.
# Output: returns the absolute Perl interpreter path or throws if none is found.
function Get-PerlBin {
    param([string]$Requested)
    if ($Requested -ne "") {
        if (Test-Path $Requested) {
            return $Requested
        }

        $requestedCommand = Get-Command $Requested -ErrorAction SilentlyContinue
        $requestedPath = Get-CommandExecutablePath -CommandInfo $requestedCommand
        if ($requestedPath -ne "") {
            return $requestedPath
        }

        $requestedWherePath = Get-WhereExecutablePath -CommandName $Requested
        if ($requestedWherePath -ne "") {
            return $requestedWherePath
        }
    }

    $candidates = @(
        "perl",
        "C:\Strawberry\perl\bin\perl.exe",
        "C:\Strawberry\c\bin\perl.exe"
    )

    foreach ($candidate in $candidates) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        $commandPath = Get-CommandExecutablePath -CommandInfo $cmd
        if ($commandPath -ne "") {
            return $commandPath
        }
        $wherePath = Get-WhereExecutablePath -CommandName $candidate
        if ($wherePath -ne "") {
            return $wherePath
        }
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "Unable to find a Strawberry Perl interpreter"
}

# Purpose: add the Strawberry Perl runtime directories to PATH for the current
# PowerShell session so batch wrappers like cpanm.bat and dashboard resolve the
# same perl and toolchain that the installer just added.
# Input: resolved Perl interpreter path.
# Output: returns nothing and mutates $env:PATH for the current session.
function Set-StrawberryPath {
    param([AllowEmptyString()][string]$ResolvedPerl = "")

    if ([string]::IsNullOrWhiteSpace($ResolvedPerl)) {
        $ResolvedPerl = Get-PerlBin -Requested "perl"
    }

    if ([string]::IsNullOrWhiteSpace($ResolvedPerl)) {
        throw "Unable to resolve a filesystem path for Perl interpreter [blank]"
    }

    if (-not (Test-Path $ResolvedPerl)) {
        $resolvedCommand = Get-Command $ResolvedPerl -ErrorAction SilentlyContinue
        $commandPath = Get-CommandExecutablePath -CommandInfo $resolvedCommand
        if ($commandPath -eq "") {
            $commandPath = Get-WhereExecutablePath -CommandName $ResolvedPerl
        }
        if ($commandPath -eq "") {
            throw "Unable to resolve a filesystem path for Perl interpreter [$ResolvedPerl]"
        }
        $ResolvedPerl = $commandPath
    }

    $perlBinDir = Split-Path -Parent $ResolvedPerl
    $perlRoot = Split-Path -Parent $perlBinDir
    $strawberryRoot = Split-Path -Parent $perlRoot
    $cBinDir = Join-Path $strawberryRoot "c\\bin"
    $siteBinDir = Join-Path $perlRoot "site\\bin"
    $pathEntries = @($perlBinDir, $siteBinDir, $cBinDir)
    $existing = @($env:PATH -split ';' | Where-Object { $_ -ne '' })

    foreach ($entry in [System.Collections.Generic.List[string]]($pathEntries)) {
        if (-not ($existing -contains $entry) -and (Test-Path $entry)) {
            $existing = @($entry) + $existing
        }
    }

    $env:PATH = ($existing -join ';')
}

# Purpose: resolve the cpanm command path for the Windows smoke, including
# Strawberry-specific installed locations.
# Input: resolved Perl interpreter path.
# Output: returns an executable cpanm command path or $null if none is found.
function Get-CpanmBin {
    param([Parameter(Mandatory = $true)][string]$ResolvedPerl)

    $perlRoot = Split-Path -Parent (Split-Path -Parent $ResolvedPerl)
    $candidates = @(
        "cpanm",
        (Join-Path $perlRoot "bin\\cpanm.bat"),
        (Join-Path $perlRoot "bin\\cpanm"),
        "C:\\Strawberry\\perl\\bin\\cpanm.bat",
        "C:\\Strawberry\\perl\\bin\\cpanm"
    )

    foreach ($candidate in $candidates) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        $commandPath = Get-CommandExecutablePath -CommandInfo $cmd
        if ($commandPath -ne "") {
            return $commandPath
        }
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

# Purpose: ensure cpanm exists so the Windows smoke can install the tarball the
# same way as other integration flows.
# Input: resolved Perl interpreter path.
# Output: returns an executable cpanm command path or throws if bootstrap fails.
function Install-CpanmIfMissing {
    param([Parameter(Mandatory = $true)][string]$ResolvedPerl)

    $cpanm = Get-CpanmBin -ResolvedPerl $ResolvedPerl
    if ($cpanm) {
        return $cpanm
    }

    $env:PERL_MM_USE_DEFAULT = "1"
    Invoke-LoggedCommand -Label "bootstrap App::cpanminus" -Command @(
        $ResolvedPerl,
        "-MCPAN",
        "-e",
        "CPAN::Shell->notest(qw(App::cpanminus))"
    )

    $cpanm = Get-CpanmBin -ResolvedPerl $ResolvedPerl
    if (-not $cpanm) {
        throw "Unable to find cpanm after bootstrapping App::cpanminus"
    }

    return $cpanm
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

# Purpose: assert that a text blob contains a required fragment.
# Input: text to inspect, the required fragment, and a label for error reporting.
# Output: returns nothing and throws if the fragment is absent.
function Invoke-AssertContains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Fragment,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not $Text.Contains($Fragment)) {
        throw "$Label missing fragment [$Fragment]"
    }
}

# Purpose: assert that a text blob omits a forbidden fragment.
# Input: text to inspect, the forbidden fragment, and a label for error reporting.
# Output: returns nothing and throws if the fragment is present.
function Invoke-AssertNotContains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Fragment,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ($Text.Contains($Fragment)) {
        throw "$Label unexpectedly contained [$Fragment]"
    }
}

# Purpose: locate an Edge or Chrome browser binary for DOM smoke checks.
# Input: none.
# Output: returns a browser path or $null when no supported browser exists.
function Get-BrowserBinary {
    $candidates = @(
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

# Purpose: wait until the dashboard HTTP endpoint responds.
# Input: target URL string.
# Output: returns when the URL responds with a non-5xx code or throws on timeout.
function Wait-HttpOk {
    param([Parameter(Mandatory = $true)][string]$Url)

    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return
            }
        }
        catch {
            Start-Sleep -Milliseconds 250
        }
    }

    throw "Timed out waiting for HTTP response from $Url"
}

# Purpose: dump the rendered DOM of a page through a real Windows browser.
# Input: browser path, target URL, and browser user-data directory path.
# Output: returns the dumped DOM as text or throws on browser failure.
function Get-DumpDom {
    param(
        [Parameter(Mandatory = $true)][string]$Browser,
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$UserDataDir
    )

    $dump = & $Browser --headless --disable-gpu --allow-insecure-localhost --user-data-dir=$UserDataDir --dump-dom $Url
    if ($LASTEXITCODE -ne 0) {
        throw "Browser dump-dom failed with exit code $LASTEXITCODE"
    }
    return ($dump | Out-String)
}

# Purpose: copy the source tarball to a local temporary file so cpanm does not
# depend on a UNC path or file:// translation when running under Windows.
# Input: source tarball path, which may point to a network share.
# Output: returns a local temporary tarball path.
function Copy-TarballToLocalTemp {
    param([Parameter(Mandatory = $true)][string]$SourceTarball)

    $destination = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetFileName($SourceTarball))
    Copy-Item -Path $SourceTarball -Destination $destination -Force
    return $destination
}

# Purpose: write the current Windows smoke phase into the shared status root
# when one is available.
# Input: short phase string.
# Output: returns nothing and updates status.txt best-effort.
function Write-PhaseStatus {
    param([Parameter(Mandatory = $true)][string]$Phase)

    if ($StatusRoot -eq "" -or -not (Test-Path $StatusRoot)) {
        return
    }

    Set-Content -Path (Join-Path $StatusRoot "status.txt") -Value $Phase
}

# Purpose: copy a diagnostic artifact into the shared status root when one is
# available.
# Input: source file path and destination file name.
# Output: returns nothing and copies the file best-effort.
function Copy-StatusArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationName
    )

    if ($StatusRoot -eq "" -or -not (Test-Path $StatusRoot) -or -not (Test-Path $SourcePath)) {
        return
    }

    Copy-Item -Path $SourcePath -Destination (Join-Path $StatusRoot $DestinationName) -Force
}

# Purpose: disable the Windows firewall inside the disposable smoke guest so
# CPAN dependency tests that open local listeners do not stall on host policy.
# Input: none.
# Output: returns nothing or throws when the firewall cannot be disabled.
function Disable-WindowsFirewallForSmoke {
    $cmd = Get-Command Set-NetFirewallProfile -ErrorAction SilentlyContinue
    if ($cmd) {
        try {
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
            return
        }
        catch {
            throw "Set-NetFirewallProfile failed: $($_.Exception.Message)"
        }
    }

    Invoke-LoggedCommand -Label "disable Windows firewall for smoke" -Command @(
        "netsh.exe",
        "advfirewall",
        "set",
        "allprofiles",
        "state",
        "off"
    )
}

$Perl = Get-PerlBin -Requested $PerlBin
Set-StrawberryPath -ResolvedPerl $Perl
$Cpanm = Install-CpanmIfMissing -ResolvedPerl $Perl
Disable-WindowsFirewallForSmoke

if (-not (Test-Path $Tarball)) {
    throw "Tarball does not exist: $Tarball"
}

Write-PhaseStatus -Phase "prepare-local-tarball"
$LocalTarball = Copy-TarballToLocalTemp -SourceTarball $Tarball
$cpanmLog = Join-Path ([System.IO.Path]::GetTempPath()) ("dd-win-cpanm-" + [guid]::NewGuid().ToString("N") + ".log")
if ($StatusRoot -ne "" -and (Test-Path $StatusRoot)) {
    $cpanmLog = Join-Path $StatusRoot "cpanm-install.log"
}
try {
    Write-PhaseStatus -Phase "install-tarball"
    $cpanmCommand = @($Cpanm, "--verbose")
    if ($SkipCpanmTests) {
        $cpanmCommand += "--notest"
    }
    $cpanmCommand += $LocalTarball
    Invoke-LoggedCommand -Label "install Developer Dashboard tarball with cpanm" -Command $cpanmCommand -LogPath $cpanmLog
}
catch {
    Copy-StatusArtifact -SourcePath $cpanmLog -DestinationName "cpanm-install.log"
    if (Test-Path $cpanmLog) {
        $cpanmTranscript = Get-Content -Path $cpanmLog -Raw
        throw "$($_.Exception.Message)`n$cpanmTranscript"
    }
    throw
}
Copy-StatusArtifact -SourcePath $cpanmLog -DestinationName "cpanm-install.log"

Write-PhaseStatus -Phase "locate-dashboard-bin"
$Dashboard = Get-DashboardBin -Requested $DashboardBin

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("dd-win-smoke-" + [guid]::NewGuid().ToString("N"))
$homeRoot = Join-Path $tempRoot "home"
$projectRoot = Join-Path $tempRoot "project"
$profileRoot = Join-Path $tempRoot "browser"
$runtimeRoot = Join-Path $projectRoot ".developer-dashboard"
$bookmarkRoot = Join-Path $runtimeRoot "dashboards"
$ajaxRoot = Join-Path $bookmarkRoot "ajax"
$navRoot = Join-Path $bookmarkRoot "nav"
$configRoot = Join-Path $runtimeRoot "config"

New-Item -ItemType Directory -Force -Path $homeRoot, $projectRoot, $bookmarkRoot, $ajaxRoot, $navRoot, $configRoot, $profileRoot | Out-Null
Set-Content -Path (Join-Path $projectRoot ".git") -Value "" -NoNewline

$env:HOME = $homeRoot
$env:USERPROFILE = $homeRoot

$bookmark = @"
BOOKMARK: sample
:--------------------------------------------------------------------------------:
TITLE: Windows Smoke
:--------------------------------------------------------------------------------:
HTML:
<div id="windows-smoke-page">hello from windows smoke</div>
CODE1:
Ajax file => 'hello.ps1', jvar => 'ajax.url', code => q{
Write-Output 'ajax-ok'
};
"@
Set-Content -Path (Join-Path $bookmarkRoot "sample") -Value $bookmark
Set-Content -Path (Join-Path $navRoot "home.tt") -Value '<a href="/app/sample">Home</a>'

$configJson = @"
{
  "collectors": [
    {
      "name": "windows.collector",
      "command": "Write-Output 'collector-ok'",
      "cwd": "home"
    }
  ]
}
"@
Set-Content -Path (Join-Path $configRoot "config.json") -Value $configJson

Write-PhaseStatus -Phase "bootstrap-powershell"
$psBootstrap = & $Dashboard shell ps | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "dashboard shell ps failed with exit code $LASTEXITCODE"
}
Invoke-AssertContains -Text $psBootstrap -Fragment "function prompt {" -Label "PowerShell bootstrap"
Invoke-AssertContains -Text $psBootstrap -Fragment "dashboard ps1 --mode compact" -Label "PowerShell bootstrap"
Invoke-AssertNotContains -Text $psBootstrap -Fragment "PS1=" -Label "PowerShell bootstrap"

$promptText = & $Dashboard ps1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "dashboard ps1 failed with exit code $LASTEXITCODE"
}
if ([string]::IsNullOrWhiteSpace($promptText)) {
    throw "dashboard ps1 returned empty prompt text"
}

Push-Location $projectRoot
try {
    Write-PhaseStatus -Phase "run-page-and-collector-checks"
    Invoke-LoggedCommand -Label "dashboard page list" -Command @($Dashboard, "page", "list")
    Invoke-LoggedCommand -Label "dashboard collector run windows.collector" -Command @($Dashboard, "collector", "run", "windows.collector")

    $collectorOutput = & $Dashboard collector output windows.collector | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "dashboard collector output windows.collector failed with exit code $LASTEXITCODE"
    }
    Invoke-AssertContains -Text $collectorOutput -Fragment "collector-ok" -Label "collector output"

    Invoke-LoggedCommand -Label "dashboard auth add-user helper smoke-pass-123" -Command @($Dashboard, "auth", "add-user", "helper", "smoke-pass-123")

    Write-PhaseStatus -Phase "start-dashboard-server"
    $serve = Start-Process -FilePath $Dashboard -ArgumentList @("serve", "--host", "127.0.0.1", "--port", $Port) -PassThru -NoNewWindow
    try {
        Write-PhaseStatus -Phase "wait-for-http"
        Wait-HttpOk -Url "http://127.0.0.1:$Port/"

        $root = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/"
        Invoke-AssertContains -Text $root.Content -Fragment "textarea" -Label "root editor"

        $page = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/app/sample"
        Invoke-AssertContains -Text $page.Content -Fragment "windows-smoke-page" -Label "saved page"

        $ajax = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/ajax/hello.ps1?type=text"
        Invoke-AssertContains -Text $ajax.Content -Fragment "ajax-ok" -Label "saved Ajax"

        $browser = Get-BrowserBinary
        if ($browser) {
            Write-PhaseStatus -Phase "browser-dom-check"
            $dom = Get-DumpDom -Browser $browser -Url "http://127.0.0.1:$Port/app/sample" -UserDataDir $profileRoot
            Invoke-AssertContains -Text $dom -Fragment "hello from windows smoke" -Label "browser DOM"
        }
        else {
            Write-Warning "No Edge or Chrome browser found; skipping Windows browser DOM smoke"
        }
    }
    finally {
        if ($serve -and -not $serve.HasExited) {
            Stop-Process -Id $serve.Id -Force
            $serve.WaitForExit()
        }
    }
}
finally {
    Pop-Location
    if (-not $KeepTemp) {
        Remove-Item -Recurse -Force $tempRoot
    }
}

Write-PhaseStatus -Phase "success"
Write-Host "Windows Strawberry Perl smoke passed"

<#
__END__

=head1 NAME

run-strawberry-smoke.ps1 - verify the built tarball under Strawberry Perl and PowerShell

=head1 SYNOPSIS

  powershell -ExecutionPolicy Bypass -File integration/windows/run-strawberry-smoke.ps1 -Tarball C:\path\Developer-Dashboard-*.tar.gz

=head1 DESCRIPTION

This script installs the built C<Developer::Dashboard> tarball with C<cpanm>
under Strawberry Perl, verifies C<dashboard shell ps> and C<dashboard ps1>,
checks one PowerShell-backed collector command, starts the dashboard web
service, exercises one saved Ajax PowerShell handler through
C<Invoke-WebRequest>, and optionally dumps DOM through Edge or Chrome when a
browser binary is present on the Windows host.

=cut
#>
