& {
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$DefaultBootstrapRepository = 'https://github.com/manif3station/developer-dashboard.git'
$CpanTarget = if ([string]::IsNullOrWhiteSpace($env:DD_INSTALL_CPAN_TARGET)) { '' } else { $env:DD_INSTALL_CPAN_TARGET }
$InstallRoot = if ([string]::IsNullOrWhiteSpace($env:DD_INSTALL_ROOT)) { '' } else { $env:DD_INSTALL_ROOT }
$ProfilePath = if ([string]::IsNullOrWhiteSpace($env:DD_INSTALL_PROFILE_PATH)) { '' } else { $env:DD_INSTALL_PROFILE_PATH }
$PreferredShell = if ([string]::IsNullOrWhiteSpace($env:DD_INSTALL_PREFERRED_SHELL)) { 'powershell' } else { $env:DD_INSTALL_PREFERRED_SHELL }
$ShellCommands = if ([string]::IsNullOrWhiteSpace($env:DD_INSTALL_SHELL_COMMANDS)) { '' } else { $env:DD_INSTALL_SHELL_COMMANDS }

function Resolve-HomeDirectory {
    # Purpose: determine the current user's home directory for the Windows bootstrap.
    # Input: the current PowerShell environment and .NET user-profile APIs.
    # Output: returns a non-empty absolute home-directory path string.
    if (-not [string]::IsNullOrWhiteSpace($HOME)) {
        return $HOME
    }

    $resolvedHome = [Environment]::GetFolderPath('UserProfile')
    if (-not [string]::IsNullOrWhiteSpace($resolvedHome)) {
        return $resolvedHome
    }

    throw 'Unable to resolve the current user home directory for install.ps1'
}

function Resolve-CommandPath {
    # Purpose: resolve a runnable command path for the requested executable names.
    # Input: one or more command names to search through Get-Command.
    # Output: returns the first filesystem-backed command path or an empty string.
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $command) {
            continue
        }

        foreach ($propertyName in @('Source', 'Path', 'Definition')) {
            $candidate = $command.$propertyName
            if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path $candidate)) {
                return $candidate
            }
        }
    }

    return ''
}

function Refresh-ProcessPathFromEnvironment {
    # Purpose: refresh the current PowerShell PATH from machine, user, and process scopes after winget installs.
    # Input: the current Windows environment plus machine and user PATH values from .NET.
    # Output: updates $env:PATH in-process and returns nothing.
    $pathSegments = [System.Collections.Generic.List[string]]::new()
    foreach ($scope in @('Machine', 'User', 'Process')) {
        $scopePath = [Environment]::GetEnvironmentVariable('Path', $scope)
        if ([string]::IsNullOrWhiteSpace($scopePath)) {
            continue
        }

        foreach ($segment in ($scopePath -split ';')) {
            if ([string]::IsNullOrWhiteSpace($segment)) {
                continue
            }
            if (-not $pathSegments.Contains($segment)) {
                $null = $pathSegments.Add($segment)
            }
        }
    }

    if ($pathSegments.Count -gt 0) {
        $env:PATH = ($pathSegments -join ';')
    }
}

function Join-ScriptText {
    # Purpose: normalize command output that may arrive as one string or multiple lines into one PowerShell script string.
    # Input: any scalar or array output captured from a command invocation.
    # Output: returns one newline-joined string with empty values removed.
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [System.Array]) {
        return (($Value | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
    }

    return [string]$Value
}

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Join-Path (Resolve-HomeDirectory) 'perl5'
}

if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
    $ProfilePath = $PROFILE.CurrentUserCurrentHost
}

$script:ProgressSteps = [System.Collections.Generic.List[object]]::new()
$null = $script:ProgressSteps.Add([pscustomobject]@{ Id = 'detect_profile'; Label = 'Detect PowerShell profile'; Status = 'pending'; Detail = '' })
$null = $script:ProgressSteps.Add([pscustomobject]@{ Id = 'install_bootstrap'; Label = 'Install Windows bootstrap packages'; Status = 'pending'; Detail = '' })
$null = $script:ProgressSteps.Add([pscustomobject]@{ Id = 'verify_node'; Label = 'Verify Node toolchain'; Status = 'pending'; Detail = '' })
$null = $script:ProgressSteps.Add([pscustomobject]@{ Id = 'bootstrap_perl'; Label = 'Bootstrap Perl user-space runtime'; Status = 'pending'; Detail = '' })
$null = $script:ProgressSteps.Add([pscustomobject]@{ Id = 'install_dashboard'; Label = 'Install Developer Dashboard'; Status = 'pending'; Detail = '' })
$null = $script:ProgressSteps.Add([pscustomobject]@{ Id = 'initialize_dashboard'; Label = 'Initialize dashboard runtime'; Status = 'pending'; Detail = '' })

$script:ProgressPrinted = $false

function Get-StepPrefix {
    # Purpose: choose the visible progress prefix for a step status.
    # Input: a status token such as pending, running, ok, or error.
    # Output: returns the human-readable status prefix string for terminal output.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    switch ($Status) {
        'ok' { return '[OK]' }
        'error' { return '[X]' }
        'running' { return '->' }
        default { return '[ ]' }
    }
}

function Get-StepColor {
    # Purpose: choose the terminal color for a step status.
    # Input: a status token such as pending, running, ok, or error.
    # Output: returns a PowerShell ConsoleColor name for Write-Host.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    switch ($Status) {
        'ok' { return 'Green' }
        'error' { return 'Red' }
        'running' { return 'Yellow' }
        default { return 'Gray' }
    }
}

function Show-ProgressBoard {
    # Purpose: print the initial progress board once before any work starts.
    # Input: the in-memory progress-step list.
    # Output: writes the progress title plus the full pending checklist to the terminal.
    if ($script:ProgressPrinted) {
        return
    }

    Write-Host 'Developer Dashboard install progress'
    foreach ($step in $script:ProgressSteps) {
        Write-Host ("{0} {1}" -f (Get-StepPrefix -Status $step.Status), $step.Label) -ForegroundColor (Get-StepColor -Status $step.Status)
    }
    $script:ProgressPrinted = $true
}

function Set-StepStatus {
    # Purpose: update one progress step and emit a visible transition line.
    # Input: the step id, a new status token, and an optional detail string.
    # Output: mutates the in-memory progress step and writes the new state to the terminal.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [string]$Detail = ''
    )

    $step = $script:ProgressSteps | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    if (-not $step) {
        throw "Unknown install.ps1 progress step id: $Id"
    }

    $step.Status = $Status
    $step.Detail = $Detail

    Show-ProgressBoard

    $line = "{0} {1}" -f (Get-StepPrefix -Status $Status), $step.Label
    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        $line = "$line ($Detail)"
    }
    Write-Host $line -ForegroundColor (Get-StepColor -Status $Status)
}

function Ensure-ParentDirectory {
    # Purpose: create the parent directory for a path when it does not exist yet.
    # Input: a filesystem path whose parent directory should be ensured.
    # Output: creates the parent directory tree and returns nothing.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }
}

function Invoke-NativeCommand {
    # Purpose: run a native command verbosely and fail on non-zero exit status.
    # Input: a label plus an executable path/name and its argument array.
    # Output: writes the command, streams native output, and throws on failure.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $display = if ($Arguments.Count -gt 0) { "$FilePath $($Arguments -join ' ')" } else { $FilePath }
    Write-Host $display -ForegroundColor DarkGray
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $FilePath @Arguments 2>&1 | ForEach-Object { Write-Host $_ }
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

function Invoke-InstallerCommand {
    # Purpose: run a Windows GUI or MSI installer and wait for its real process exit without piping through a console stream.
    # Input: a label plus an installer executable path and its argument array.
    # Output: writes the command, waits for completion, and throws on non-zero exit status.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $display = if ($Arguments.Count -gt 0) { "$FilePath $($Arguments -join ' ')" } else { $FilePath }
    Write-Host $display -ForegroundColor DarkGray

    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        throw "$Label failed with exit code $($process.ExitCode)"
    }
}

function Format-ExitCode {
    # Purpose: render a native Windows exit code in both decimal and unsigned hexadecimal forms.
    # Input: a signed integer exit code captured from $LASTEXITCODE.
    # Output: returns a string like "-1978335138 (0x8A15005E)" for clearer diagnostics.
    param(
        [Parameter(Mandatory = $true)]
        [int]$ExitCode
    )

    $unsigned = [System.BitConverter]::ToUInt32([System.BitConverter]::GetBytes($ExitCode), 0)
    return ('{0} (0x{1:X8})' -f $ExitCode, $unsigned)
}

function Set-TlsSecurityProtocol {
    # Purpose: enable modern TLS protocols before any Windows bootstrap HTTP request runs.
    # Input: the current .NET ServicePointManager state.
    # Output: updates the process security protocol flags to include TLS 1.2 and TLS 1.3 when available.
    $protocol = [Net.SecurityProtocolType]::Tls12
    if ([enum]::GetNames([Net.SecurityProtocolType]) -contains 'Tls13') {
        $protocol = $protocol -bor [Net.SecurityProtocolType]::Tls13
    }

    [Net.ServicePointManager]::SecurityProtocol = $protocol
}

function Get-RemoteText {
    # Purpose: fetch UTF-8 text over HTTPS for Windows bootstrap metadata without depending on one fragile transport.
    # Input: a URL string plus an optional label for diagnostics.
    # Output: returns the fetched response body text or throws after all supported transports fail.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [string]$Label = 'remote text request'
    )

    Set-TlsSecurityProtocol

    try {
        return (Invoke-WebRequest -UseBasicParsing -Uri $Uri).Content
    }
    catch {
        Write-Host ("Invoke-WebRequest failed for {0}: {1}" -f $Label, $_.Exception.Message) -ForegroundColor Yellow
    }

    $webClient = New-Object System.Net.WebClient
    try {
        return $webClient.DownloadString($Uri)
    }
    catch {
        throw ("{0} failed for {1}: {2}" -f $Label, $Uri, $_.Exception.Message)
    }
    finally {
        $webClient.Dispose()
    }
}

function Download-RemoteFile {
    # Purpose: download a Windows bootstrap installer or helper script robustly even when one HTTP client path is unreliable.
    # Input: a URL string, a destination file path, and an optional diagnostic label.
    # Output: writes the file to disk or throws after Invoke-WebRequest, curl, and WebClient all fail.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        [string]$Label = 'remote file download'
    )

    Ensure-ParentDirectory -Path $DestinationPath
    Set-TlsSecurityProtocol

    $curlPath = Resolve-CommandPath -Names @('curl.exe', 'curl')
    if (-not [string]::IsNullOrWhiteSpace($curlPath)) {
        try {
            Invoke-NativeCommand -Label "$Label via curl" -FilePath $curlPath -Arguments @(
                '--fail',
                '--location',
                '--silent',
                '--show-error',
                '--output', $DestinationPath,
                $Uri
            )
            if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -gt 0)) {
                return
            }
            throw "curl created an empty file for $Uri"
        }
        catch {
            if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -eq 0)) {
                Remove-Item -Force $DestinationPath
            }
            Write-Host ("curl failed for {0}: {1}" -f $Label, $_.Exception.Message) -ForegroundColor Yellow
        }
    }

    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $DestinationPath
        if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -gt 0)) {
            return
        }
        throw "Invoke-WebRequest created an empty file for $Uri"
    }
    catch {
        if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -eq 0)) {
            Remove-Item -Force $DestinationPath
        }
        Write-Host ("Invoke-WebRequest failed for {0}: {1}" -f $Label, $_.Exception.Message) -ForegroundColor Yellow
    }

    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.DownloadFile($Uri, $DestinationPath)
        if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -gt 0)) {
            return
        }
        throw "WebClient created an empty file for $Uri"
    }
    catch {
        if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -eq 0)) {
            Remove-Item -Force $DestinationPath
        }
        throw ("{0} failed for {1}: {2}" -f $Label, $Uri, $_.Exception.Message)
    }
    finally {
        $webClient.Dispose()
    }
}

function Get-RemoteJson {
    # Purpose: fetch JSON metadata for Windows bootstrap decisions through the shared resilient downloader.
    # Input: a URL string plus an optional label for diagnostics.
    # Output: returns the decoded PowerShell object graph from the remote JSON payload.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [string]$Label = 'remote JSON request'
    )

    $jsonText = Get-RemoteText -Uri $Uri -Label $Label
    return ($jsonText | ConvertFrom-Json)
}

function Resolve-StrawberryPerlMsiUrl {
    # Purpose: resolve the latest 64-bit Strawberry Perl MSI URL from the official release feed.
    # Input: none.
    # Output: returns an https MSI URL string or throws when no supported release is available.
    $releases = Get-RemoteJson -Uri 'https://strawberryperl.com/releases.json' -Label 'Strawberry Perl releases feed'
    foreach ($release in $releases) {
        if ($release.archname -ne 'MSWin32-x64-multi-thread') {
            continue
        }

        $url = $release.edition.msi.url
        if (-not [string]::IsNullOrWhiteSpace($url)) {
            return $url
        }
    }

    throw 'Unable to resolve a 64-bit Strawberry Perl MSI URL from the official release feed.'
}

function Resolve-GitForWindowsInstallerUrl {
    # Purpose: resolve the current 64-bit Git for Windows installer URL from the latest release page.
    # Input: none.
    # Output: returns an https EXE URL string or throws when the latest release page no longer exposes the expected asset.
    Set-TlsSecurityProtocol

    $releaseUrl = 'https://github.com/git-for-windows/git/releases/latest'
    $releasePage = ''
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $releaseUrl
        $releasePage = $response.Content
        if ($response.BaseResponse -and $response.BaseResponse.ResponseUri) {
            $releaseUrl = $response.BaseResponse.ResponseUri.AbsoluteUri
        }
    }
    catch {
        $releasePage = Get-RemoteText -Uri $releaseUrl -Label 'Git for Windows latest release page'
    }

    if ($releasePage -match 'Git-[0-9][^"''<]*-64-bit\.exe') {
        $assetName = $matches[0]
        if ($releaseUrl -match '/tag/([^/?#]+)') {
            return ('https://github.com/git-for-windows/git/releases/download/{0}/{1}' -f $matches[1], $assetName)
        }
    }

    throw 'Unable to resolve the latest 64-bit Git for Windows installer URL from the release page.'
}

function Resolve-NodeLtsMsiUrl {
    # Purpose: resolve the latest Windows x64 Node.js LTS MSI URL from the official Node.js release index.
    # Input: none.
    # Output: returns an https MSI URL string or throws when no supported LTS release is available.
    $releases = Get-RemoteJson -Uri 'https://nodejs.org/dist/index.json' -Label 'Node.js release index'
    foreach ($release in $releases) {
        if (-not $release.lts) {
            continue
        }
        if ($release.files -notcontains 'win-x64-msi') {
            continue
        }

        return ('https://nodejs.org/dist/{0}/node-{1}-x64.msi' -f $release.version, $release.version)
    }

    throw 'Unable to resolve a Windows x64 Node.js LTS MSI URL from the official release index.'
}

function Install-WindowsPackageFallback {
    # Purpose: install a required Windows bootstrap package directly from the official vendor download when winget source metadata is broken.
    # Input: package id and user-facing label.
    # Output: downloads and installs the package or throws if no fallback is available.
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) 'developer-dashboard-bootstrap'
    Ensure-ParentDirectory -Path (Join-Path $tempRoot 'bootstrap.marker')
    $installerPath = ''
    $arguments = @()
    $installLabel = ''

    switch ($PackageId) {
        'Git.Git' {
            $uri = Resolve-GitForWindowsInstallerUrl
            $installerPath = Join-Path $tempRoot 'Git-64-bit.exe'
            Write-Host "Downloading official Git for Windows installer to $installerPath"
            Download-RemoteFile -Uri $uri -DestinationPath $installerPath -Label 'Git for Windows fallback installer download'
            $arguments = @('/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-')
            $installLabel = 'Git for Windows fallback installer'
        }
        'StrawberryPerl.StrawberryPerl' {
            $uri = Resolve-StrawberryPerlMsiUrl
            $installerPath = Join-Path $tempRoot ([IO.Path]::GetFileName($uri))
            Write-Host "Downloading official Strawberry Perl MSI to $installerPath"
            Download-RemoteFile -Uri $uri -DestinationPath $installerPath -Label 'Strawberry Perl fallback installer download'
            $arguments = @('/i', $installerPath, '/qn', '/norestart')
            $installLabel = 'Strawberry Perl fallback installer'
            Invoke-InstallerCommand -Label $installLabel -FilePath 'msiexec.exe' -Arguments $arguments
            return
        }
        'OpenJS.NodeJS.LTS' {
            $uri = Resolve-NodeLtsMsiUrl
            $installerPath = Join-Path $tempRoot ([IO.Path]::GetFileName($uri))
            Write-Host "Downloading official Node.js LTS MSI to $installerPath"
            Download-RemoteFile -Uri $uri -DestinationPath $installerPath -Label 'Node.js LTS fallback installer download'
            $arguments = @('/i', $installerPath, '/qn', '/norestart')
            $installLabel = 'Node.js LTS fallback installer'
            Invoke-InstallerCommand -Label $installLabel -FilePath 'msiexec.exe' -Arguments $arguments
            return
        }
        default {
            throw "No official fallback installer is defined for $Label ($PackageId)"
        }
    }

    Invoke-InstallerCommand -Label $installLabel -FilePath $installerPath -Arguments $arguments
}

function Repair-WingetSources {
    # Purpose: repair the default winget sources after a bootstrap install fails because source metadata or certificates are broken.
    # Input: a resolved winget executable path.
    # Output: resets and refreshes the winget source catalog or throws if repair fails.
    param(
        [Parameter(Mandatory = $true)]
        [string]$WingetPath
    )

    Write-Host 'Repairing winget sources before retrying the Windows bootstrap install.' -ForegroundColor Yellow
    Invoke-NativeCommand -Label 'winget source reset' -FilePath $WingetPath -Arguments @(
        'source',
        'reset',
        '--force'
    )
    Invoke-NativeCommand -Label 'winget source update winget' -FilePath $WingetPath -Arguments @(
        'source',
        'update',
        'winget'
    )
}

function Ensure-WingetPackage {
    # Purpose: install a missing Windows package through winget without user prompts.
    # Input: the winget package id, a human label, and the command names that prove it is already present.
    # Output: installs the package when needed and returns the resolved command path when one exists.
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string[]]$CommandNames
    )

    $resolved = Resolve-CommandPath -Names $CommandNames
    if (-not [string]::IsNullOrWhiteSpace($resolved)) {
        return $resolved
    }

    $winget = Resolve-CommandPath -Names @('winget.exe', 'winget')
    if ([string]::IsNullOrWhiteSpace($winget)) {
        throw "winget is required to install missing Windows package: $Label ($PackageId)"
    }

    Write-Host "Installing missing Windows package via winget: $Label ($PackageId)"
    $installArguments = @(
        'install',
        '--id', $PackageId,
        '--exact',
        '--source', 'winget',
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--disable-interactivity'
    )
    $installLabel = "winget install $PackageId"
    $installFailed = $false
    try {
        Invoke-NativeCommand -Label $installLabel -FilePath $winget -Arguments $installArguments
    }
    catch {
        $installFailed = $true
        $firstExitCode = $LASTEXITCODE
        Write-Host ("winget install failed for {0}: {1}" -f $PackageId, (Format-ExitCode -ExitCode $firstExitCode)) -ForegroundColor Yellow
        Write-Host 'A broken msstore source or stale source metadata can block winget even for community packages. Resetting sources and retrying once.' -ForegroundColor Yellow
        Repair-WingetSources -WingetPath $winget
    }

    if ($installFailed) {
        try {
            Invoke-NativeCommand -Label "$installLabel retry" -FilePath $winget -Arguments $installArguments
        }
        catch {
            $retryExitCode = $LASTEXITCODE
            Write-Host ("winget install failed again for {0}: {1}" -f $PackageId, (Format-ExitCode -ExitCode $retryExitCode)) -ForegroundColor Yellow
            Write-Host "Falling back to the official $Label installer because winget source metadata is still broken." -ForegroundColor Yellow
            Install-WindowsPackageFallback -PackageId $PackageId -Label $Label
        }
    }

    Refresh-ProcessPathFromEnvironment
    $resolved = Resolve-CommandPath -Names $CommandNames
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        throw "Installed Windows package did not expose command on PATH: $Label ($PackageId)"
    }

    return $resolved
}

function Resolve-DefaultDashboardCheckout {
    # Purpose: materialize the current GitHub master source into a local checkout for streamed Windows installs.
    # Input: a writable temp directory plus the canonical Developer Dashboard Git repository URL.
    # Output: returns the local checkout path that cpanm should install when no explicit target override is set.
    $gitPath = Resolve-CommandPath -Names @('git.exe', 'git')
    if ([string]::IsNullOrWhiteSpace($gitPath)) {
        throw 'git is required before resolving the default Windows checkout bootstrap target'
    }

    $checkoutRoot = Join-Path ([IO.Path]::GetTempPath()) 'developer-dashboard-install'
    if (Test-Path $checkoutRoot) {
        Remove-Item -Recurse -Force $checkoutRoot
    }

    Invoke-NativeCommand -Label 'git clone Developer Dashboard checkout' -FilePath $gitPath -Arguments @(
        'clone',
        '--depth', '1',
        '--branch', 'master',
        $DefaultBootstrapRepository,
        $checkoutRoot
    )
    return $checkoutRoot
}

function Add-StrawberryPaths {
    # Purpose: add the Strawberry Perl toolchain directories to the current PATH.
    # Input: a resolved Strawberry perl.exe path.
    # Output: prepends perl/bin, perl/site/bin, and c/bin to PATH when they exist.
    param(
        [Parameter(Mandatory = $true)]
        [string]$PerlPath
    )

    $perlBin = Split-Path -Parent $PerlPath
    $perlRoot = Split-Path -Parent $perlBin
    $strawberryRoot = Split-Path -Parent $perlRoot
    $candidateDirs = @(
        $perlBin,
        (Join-Path $perlRoot 'site\bin'),
        (Join-Path $strawberryRoot 'c\bin')
    ) | Select-Object -Unique

    foreach ($dir in $candidateDirs) {
        if (-not (Test-Path $dir)) {
            continue
        }
        $escaped = [Regex]::Escape($dir)
        if ($env:PATH -notmatch "(?i)(^|;)$escaped(;|$)") {
            $env:PATH = "$dir;$env:PATH"
        }
    }
}

function Ensure-NodeToolchain {
    # Purpose: make sure node, npm, and npx all exist before dashboard skills need package.json support.
    # Input: the current PATH and optional winget package manager.
    # Output: returns nothing after the Node toolchain is available or throws on failure.
    $nodePath = Resolve-CommandPath -Names @('node.exe', 'node')
    $npmPath = Resolve-CommandPath -Names @('npm.cmd', 'npm.exe', 'npm')
    $npxPath = Resolve-CommandPath -Names @('npx.cmd', 'npx.exe', 'npx')

    if (-not [string]::IsNullOrWhiteSpace($nodePath) -and -not [string]::IsNullOrWhiteSpace($npmPath) -and -not [string]::IsNullOrWhiteSpace($npxPath)) {
        return
    }

    $null = Ensure-WingetPackage -PackageId 'OpenJS.NodeJS.LTS' -Label 'Node.js LTS' -CommandNames @('node.exe', 'node')
    $npmPath = Resolve-CommandPath -Names @('npm.cmd', 'npm.exe', 'npm')
    $npxPath = Resolve-CommandPath -Names @('npx.cmd', 'npx.exe', 'npx')
    if ([string]::IsNullOrWhiteSpace($npmPath) -or [string]::IsNullOrWhiteSpace($npxPath)) {
        throw 'Node.js was installed but npm and npx are still unavailable on PATH'
    }
}

function Ensure-ProfileContains {
    # Purpose: keep exactly one managed Developer Dashboard bootstrap block in the PowerShell profile.
    # Input: the profile path, the literal block text, and a stable marker label that brackets the managed block.
    # Output: creates the profile file when needed, replaces any older managed block, and appends the current block once.
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetProfile,
        [Parameter(Mandatory = $true)]
        [string]$Block,
        [Parameter(Mandatory = $true)]
        [string]$Marker
    )

    Ensure-ParentDirectory -Path $TargetProfile
    if (-not (Test-Path $TargetProfile)) {
        Set-Content -Path $TargetProfile -Value '' -Encoding UTF8
    }

    $existing = Get-Content -Path $TargetProfile -Raw
    $beginMarker = "# >>> $Marker >>>"
    $endMarker = "# <<< $Marker <<<"
    $beginMarkerPattern = [Regex]::Escape($beginMarker)
    $endMarkerPattern = [Regex]::Escape($endMarker)
    $managedPattern = "(?ms)$beginMarkerPattern.*?$endMarkerPattern\s*"
    $legacyManagedPattern = '(?ms)^# Developer Dashboard bootstrap\r?\n.*?(?=^\s*$|\z)'
    $sanitized = [Regex]::Replace($existing, $managedPattern, '')
    $sanitized = [Regex]::Replace($sanitized, $legacyManagedPattern, '')
    $sanitized = $sanitized.TrimEnd()

    if ($sanitized -eq $Block) {
        return
    }

    $combined = if ([string]::IsNullOrWhiteSpace($sanitized)) {
        $Block
    }
    else {
        $sanitized + [Environment]::NewLine + [Environment]::NewLine + $Block
    }

    Set-Content -Path $TargetProfile -Value ($combined + [Environment]::NewLine) -Encoding UTF8
}

function Ensure-CurrentUserPowerShellExecutionPolicy {
    # Purpose: make sure the current user can load the generated PowerShell profile script in future sessions.
    # Input: the current-user PowerShell execution policy state.
    # Output: sets the CurrentUser execution policy to RemoteSigned when it is undefined or restricted.
    $currentUserPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentUserPolicy -in @('RemoteSigned', 'Unrestricted', 'Bypass')) {
        return $currentUserPolicy
    }

    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    }
    catch {
        if ($_.FullyQualifiedErrorId -notlike 'ExecutionPolicyOverride*') {
            throw
        }
        Write-Host 'Current PowerShell session already overrides execution policy; kept the saved CurrentUser policy and continued.'
    }
    return (Get-ExecutionPolicy -Scope CurrentUser)
}

function Download-CpanmScript {
    # Purpose: fetch the cpanminus bootstrap script into the user-space install root.
    # Input: the install root where the cpanm script should be written.
    # Output: returns the downloaded cpanm script path.
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetInstallRoot
    )

    $binDir = Join-Path $TargetInstallRoot 'bin'
    if (-not (Test-Path $binDir)) {
        $null = New-Item -ItemType Directory -Path $binDir -Force
    }

    $cpanmScript = Join-Path $binDir 'cpanm'
    Write-Host "Downloading cpanminus bootstrap script to $cpanmScript"
    Download-RemoteFile -Uri 'https://cpanmin.us/' -DestinationPath $cpanmScript -Label 'cpanm bootstrap script download'
    return $cpanmScript
}

function Set-EnvironmentValue {
    # Purpose: update a process environment variable in one place.
    # Input: an environment variable name and the value it should carry for this PowerShell process.
    # Output: writes the process-scoped environment value and returns nothing.
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Set-Item -Path ("Env:{0}" -f $Name) -Value $Value
}

function Sync-LocalLibEnvironmentFromPerl {
    # Purpose: ask perl local::lib for the canonical Windows environment block instead of hand-assembling INSTALL_BASE values.
    # Input: a resolved perl executable path plus the install root where local::lib should live.
    # Output: refreshes PATH, PERL5LIB, PERL_LOCAL_LIB_ROOT, PERL_MB_OPT, and PERL_MM_OPT for the current PowerShell process.
    param(
        [Parameter(Mandatory = $true)]
        [string]$PerlPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetInstallRoot
    )

    $libDir = Join-Path $TargetInstallRoot 'lib\perl5'
    $normalizedInstallRoot = $TargetInstallRoot -replace '\\', '/'
$dumpCode = @'
for my $key (qw(PATH PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT)) {
    next unless exists $ENV{$key};
    print $key, q(=), $ENV{$key}, chr(10);
}
'@
    $lines = & $PerlPath "-I$libDir" "-Mlocal::lib=$normalizedInstallRoot" '-e' $dumpCode
    if ($LASTEXITCODE -ne 0) {
        throw "perl local::lib environment sync failed with exit code $LASTEXITCODE"
    }

    foreach ($line in $lines) {
        if ($line -match '^([^=]+)=(.*)$') {
            Set-EnvironmentValue -Name $matches[1] -Value $matches[2]
        }
    }
}

Show-ProgressBoard

Set-StepStatus -Id 'detect_profile' -Status 'running'
Ensure-ParentDirectory -Path $ProfilePath
$currentUserExecutionPolicy = Ensure-CurrentUserPowerShellExecutionPolicy
Set-StepStatus -Id 'detect_profile' -Status 'ok' -Detail ("profile: {0}; policy: {1}" -f $ProfilePath, $currentUserExecutionPolicy)

Set-StepStatus -Id 'install_bootstrap' -Status 'running'
$null = Ensure-WingetPackage -PackageId 'Git.Git' -Label 'Git' -CommandNames @('git.exe', 'git')
$perlPath = Ensure-WingetPackage -PackageId 'StrawberryPerl.StrawberryPerl' -Label 'Strawberry Perl' -CommandNames @('perl.exe', 'perl')
Add-StrawberryPaths -PerlPath $perlPath
Set-StepStatus -Id 'install_bootstrap' -Status 'ok' -Detail 'Git and Strawberry Perl ready'

Set-StepStatus -Id 'verify_node' -Status 'running'
Ensure-NodeToolchain
Set-StepStatus -Id 'verify_node' -Status 'ok' -Detail 'node, npm, and npx ready'

Set-StepStatus -Id 'bootstrap_perl' -Status 'running'
if (-not (Test-Path $InstallRoot)) {
    $null = New-Item -ItemType Directory -Path $InstallRoot -Force
}
$cpanmScript = Download-CpanmScript -TargetInstallRoot $InstallRoot
Invoke-NativeCommand -Label 'cpanm local::lib bootstrap' -FilePath $perlPath -Arguments @(
    $cpanmScript,
    '--notest',
    '--local-lib-contained', $InstallRoot,
    'local::lib',
    'File::ShareDir::Install'
)
Sync-LocalLibEnvironmentFromPerl -PerlPath $perlPath -TargetInstallRoot $InstallRoot

$profilePerlBin = Split-Path -Parent $perlPath
$profilePerlRoot = Split-Path -Parent $profilePerlBin
$profileStrawberryRoot = Split-Path -Parent $profilePerlRoot
$profilePerlRuntimePaths = @(
    $profilePerlBin,
    (Join-Path $profilePerlRoot 'site\bin'),
    (Join-Path $profileStrawberryRoot 'c\bin')
) | Select-Object -Unique
$profilePerlRuntimePathLines = ($profilePerlRuntimePaths | ForEach-Object { "    '{0}'" -f $_ }) -join [Environment]::NewLine

$profileBlock = @"
# >>> Developer Dashboard bootstrap >>>
`$ddInstallRoot = '$InstallRoot'
`$ddInstallRootForward = `$ddInstallRoot -replace '\\', '/'
`$ddPerlBin = Join-Path `$ddInstallRoot 'bin'
`$ddPerlLib = Join-Path `$ddInstallRoot 'lib\perl5'
`$ddPerlRuntimePaths = @(
$profilePerlRuntimePathLines
)
`$ddHomeHelper = Join-Path `$HOME '.developer-dashboard\cli\dd\_dashboard-core'
if (Test-Path `$ddPerlBin) {
    if (`$env:PATH -notlike "*`$ddPerlBin*") {
        `$env:PATH = "`$ddPerlBin;`$env:PATH"
    }
}
foreach (`$ddPerlRuntimePath in `$ddPerlRuntimePaths) {
    if (-not [string]::IsNullOrWhiteSpace(`$ddPerlRuntimePath) -and (Test-Path `$ddPerlRuntimePath) -and `$env:PATH -notlike "*`$ddPerlRuntimePath*") {
        `$env:PATH = "`$ddPerlRuntimePath;`$env:PATH"
    }
}
`$ddPerlCommand = Get-Command perl.exe -ErrorAction SilentlyContinue
if (`$ddPerlCommand -and (Test-Path `$ddPerlLib)) {
    `$ddLocalLibDump = & `$ddPerlCommand.Source "-I`$ddPerlLib" "-Mlocal::lib=`$ddInstallRootForward" '-e' 'for my `$key (qw(PATH PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT)) { next unless exists `$ENV{`$key}; print `$key, q(=), `$ENV{`$key}, chr(10); }'
    foreach (`$ddLine in `$ddLocalLibDump) {
        if (`$ddLine -match '^([^=]+)=(.*)$') {
            Set-Item -Path ("Env:{0}" -f `$matches[1]) -Value `$matches[2]
        }
    }
}
if ((Get-Command dashboard -ErrorAction SilentlyContinue) -and (Test-Path `$ddHomeHelper)) {
    `$ddShellBootstrap = & dashboard shell ps
    `$ddShellBootstrapText = ((@(`$ddShellBootstrap | Where-Object { `$null -ne `$_ } | ForEach-Object { [string]`$_ })) -join [Environment]::NewLine)
    if (-not [string]::IsNullOrWhiteSpace(`$ddShellBootstrapText)) {
        Invoke-Expression `$ddShellBootstrapText
    }
}
# <<< Developer Dashboard bootstrap <<<
"@
Set-StepStatus -Id 'bootstrap_perl' -Status 'ok' -Detail 'cpanm, local::lib, and configure prereqs ready'

$dashboardCommand = Resolve-CommandPath -Names @('dashboard.bat', 'dashboard', 'dashboard.cmd')
if ([string]::IsNullOrWhiteSpace($dashboardCommand)) {
    $candidate = Join-Path $InstallRoot 'bin\dashboard.bat'
    if (Test-Path $candidate) {
        $dashboardCommand = $candidate
    }
}

Set-StepStatus -Id 'install_dashboard' -Status 'running'
$effectiveCpanTarget = $CpanTarget
if ([string]::IsNullOrWhiteSpace($effectiveCpanTarget)) {
    $effectiveCpanTarget = Resolve-DefaultDashboardCheckout
    Push-Location $effectiveCpanTarget
    try {
        Invoke-NativeCommand -Label 'cpanm Developer Dashboard install' -FilePath $perlPath -Arguments @(
            $cpanmScript,
            '--notest',
            '--local-lib-contained', $InstallRoot,
            '.'
        )
    }
    finally {
        Pop-Location
    }
}
else {
    Invoke-NativeCommand -Label 'cpanm Developer Dashboard install' -FilePath $perlPath -Arguments @(
        $cpanmScript,
        '--notest',
        '--local-lib-contained', $InstallRoot,
        $effectiveCpanTarget
    )
}
$dashboardCommand = Resolve-CommandPath -Names @('dashboard.bat', 'dashboard', 'dashboard.cmd')
if ([string]::IsNullOrWhiteSpace($dashboardCommand)) {
    $candidate = Join-Path $InstallRoot 'bin\dashboard.bat'
    if (-not (Test-Path $candidate)) {
        throw 'Developer Dashboard installed but dashboard command is still unavailable on PATH'
    }
    $dashboardCommand = $candidate
}
Ensure-ProfileContains -TargetProfile $ProfilePath -Block $profileBlock -Marker 'Developer Dashboard bootstrap'
Set-StepStatus -Id 'install_dashboard' -Status 'ok' -Detail ("target: {0}" -f $effectiveCpanTarget)

Set-StepStatus -Id 'initialize_dashboard' -Status 'running'
Invoke-NativeCommand -Label 'dashboard init' -FilePath $dashboardCommand -Arguments @('init')
$dashboardShellBootstrap = & $dashboardCommand shell ps
$dashboardShellBootstrapText = Join-ScriptText -Value $dashboardShellBootstrap
if (-not [string]::IsNullOrWhiteSpace($dashboardShellBootstrapText)) {
    Invoke-Expression $dashboardShellBootstrapText
}
if (-not [string]::IsNullOrWhiteSpace($ShellCommands)) {
    Write-Host 'Running post-install activation commands through PowerShell.'
    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ". '$ProfilePath'; $ShellCommands"
    if ($LASTEXITCODE -ne 0) {
        throw "Post-install activation commands failed with exit code $LASTEXITCODE"
    }
}
Set-StepStatus -Id 'initialize_dashboard' -Status 'ok' -Detail 'dashboard init completed'

Write-Host ("Shell setup was written to: {0}" -f $ProfilePath)
Write-Host 'Developer Dashboard is installed and initialized.'
Write-Host 'Open a new PowerShell window or run this in the current shell:'
Write-Host (". '{0}'" -f $ProfilePath)
Write-Host 'Then verify with:'
Write-Host 'dashboard version'
} @args
