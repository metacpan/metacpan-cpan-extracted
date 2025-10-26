#!/usr/bin/env pwsh
# Requires PowerShell 5.1+ or PowerShell 7+
# Equivalent to the Bash installer for JQ-Lite

param(
    [string]$Prefix = "$env:USERPROFILE\.local",
    [switch]$SkipTests,
    [string]$Tarball
)

function Show-Usage {
    @"
Usage: install-jq-lite.ps1 [-Prefix <path>] [--SkipTests] [<tarball>]

Installs JQ-Lite from a pre-downloaded tarball.
If no tarball is specified, the latest JQ-Lite-*.tar.gz file in the current directory is used.

Options:
  -Prefix <path>   Installation prefix (default: \$env:USERPROFILE\.local)
  --SkipTests      Skip running make test
  -h, --help       Show this help message
"@
}

if ($args -contains '-h' -or $args -contains '--help') {
    Show-Usage
    exit 0
}

# --- Locate tarball ---
if (-not $Tarball) {
    $Tarball = Get-ChildItem -Filter 'JQ-Lite-*.tar.gz' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName }
}

if (-not $Tarball) {
    Write-Error "No JQ-Lite tarball found in current directory."
    exit 1
}

if (-not (Test-Path $Tarball)) {
    Write-Error "Tarball '$Tarball' not found."
    exit 1
}

# --- Tools check ---
$tools = @('tar', 'perl', 'make')
foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "'$tool' not found in PATH."
        exit 1
    }
}

$RunTests = if ($SkipTests) { $false } else { $true }

if ($RunTests -and -not (Get-Command 'prove' -ErrorAction SilentlyContinue)) {
    Write-Warning "'prove' not found; skipping tests."
    $RunTests = $false
}

# --- Prepare working directory ---
$WorkDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ("jq-lite-" + [System.Guid]::NewGuid().ToString()) -Force
$WorkDirPath = $WorkDir.FullName
Write-Host "[INFO] Working in $WorkDirPath"
Push-Location $WorkDirPath

try {
    # --- Detect distribution directory ---
    $TarList = tar tzf $Tarball 2>$null
    if (-not $TarList) {
        Write-Error "Unable to list tarball contents."
        exit 1
    }
    $DistDir = ($TarList[0] -split '/')[0]
    if (-not $DistDir) {
        Write-Error "Unable to determine distribution directory from tarball."
        exit 1
    }

    # --- Extract safely ---
    Write-Host "[INFO] Extracting $Tarball..."
    tar xzf $Tarball

    Set-Location $DistDir

    Write-Host "[INFO] Installing to $Prefix..."
    perl Makefile.PL PREFIX="$Prefix" | Out-Null
    make

    if ($RunTests) {
        make test
    } else {
        Write-Host "[INFO] Skipping tests."
    }

    make install

    Write-Host ""
    Write-Host "[INFO] Installation complete."
    Write-Host ""
    Write-Host "To enable jq-lite, add the following to your PowerShell profile:"
    Write-Host "  `$env:PATH = '$Prefix\\bin;' + `$env:PATH"
    Write-Host "  `$env:PERL5LIB = '$Prefix\\lib\\perl5\\site_perl;' + `$env:PERL5LIB"
    Write-Host ""
    Write-Host "Then restart your shell or run:"
    Write-Host "  . `$PROFILE"
    Write-Host ""
    Write-Host "Verify installation with:"
    Write-Host "  jq-lite -v"
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $WorkDirPath
}
