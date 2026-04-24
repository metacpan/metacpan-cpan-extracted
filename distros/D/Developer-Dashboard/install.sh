#!/bin/sh

set -eu

SCRIPT_DIR=$(
    CDPATH= cd -- "$(dirname -- "$0")" && pwd
)
APTFILE="$SCRIPT_DIR/aptfile"
APKFILE="$SCRIPT_DIR/apkfile"
DNFILE="$SCRIPT_DIR/dnfile"
BREWFILE="$SCRIPT_DIR/brewfile"
APTFILE_DEFAULT_CONTENT='
# Repo bootstrap packages for Debian-family hosts.
build-essential
ca-certificates
cpanminus
curl
git
libexpat1-dev
libssl-dev
npm
nodejs
perl
perlbrew
pkg-config
zlib1g-dev
'
BREWFILE_DEFAULT_CONTENT='
# Repo bootstrap packages for macOS hosts.
cpanminus
curl
expat
git
node
openssl@3
perl
pkgconf
'
APKFILE_DEFAULT_CONTENT='
# Repo bootstrap packages for Alpine hosts.
alpine-sdk
ca-certificates
curl
expat-dev
git
nodejs
npm
openssl-dev
perl
perl-app-cpanminus
perl-dev
pkgconf
zlib-dev
'
DNFILE_DEFAULT_CONTENT='
# Repo bootstrap packages for Fedora hosts.
ca-certificates
curl
expat-devel
gcc
gcc-c++
git
make
nodejs
openssl-devel
perl
perl-App-cpanminus
perl-devel
pkgconf-pkg-config
zlib-devel
'
INSTALL_ROOT="${HOME:?Missing HOME}/perl5"
CPAN_TARGET="${DD_INSTALL_CPAN_TARGET:-Developer::Dashboard}"
OS_OVERRIDE="${DD_INSTALL_OS_OVERRIDE:-}"
PERLBREW_ROOT="${PERLBREW_ROOT:-$INSTALL_ROOT/perlbrew}"
PERLBREW_HOME="${PERLBREW_HOME:-$PERLBREW_ROOT}"
PERLBREW_APP_DIST_URL="${DD_INSTALL_PERLBREW_APP_DIST_URL:-https://cpan.metacpan.org/authors/id/G/GU/GUGOD/App-perlbrew-1.02.tar.gz}"
PERLBREW_APP_DIST_BASENAME=$(basename "$PERLBREW_APP_DIST_URL")
SYSTEM_PERL_BIN=''
SYSTEM_PERL_ARCHNAME=''
PERLBREW_PERL="${DD_INSTALL_PERLBREW_PERL:-perl-5.38.5}"
MIN_PERL_VERSION='5.038'
PERL_BIN=''
CPANM_SCRIPT=''
RC_FILE=''
ACTIVATION_FILE=''
DASHBOARD_BIN=''
AUTO_SHELL_MODE="${DD_INSTALL_AUTO_SHELL:-auto}"
POST_INSTALL_SHELL_COMMANDS="${DD_INSTALL_SHELL_COMMANDS:-}"
SHELL_BIN_OVERRIDE="${DD_INSTALL_SHELL_BIN:-}"
CURRENT_STEP=''
SUDO_EXPLAINED='0'
PROGRESS_STEPS='detect_platform install_system_packages verify_node_toolchain bootstrap_local_lib install_dashboard_package initialize_dashboard'
PROGRESS_STATUS_detect_platform='pending'
PROGRESS_STATUS_install_system_packages='pending'
PROGRESS_STATUS_verify_node_toolchain='pending'
PROGRESS_STATUS_bootstrap_local_lib='pending'
PROGRESS_STATUS_install_dashboard_package='pending'
PROGRESS_STATUS_initialize_dashboard='pending'
PROGRESS_NOTE_detect_platform=''
PROGRESS_NOTE_install_system_packages=''
PROGRESS_NOTE_verify_node_toolchain=''
PROGRESS_NOTE_bootstrap_local_lib=''
PROGRESS_NOTE_install_dashboard_package=''
PROGRESS_NOTE_initialize_dashboard=''
COLOR_RESET=''
COLOR_GREEN=''
COLOR_RED=''
COLOR_YELLOW=''
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
    COLOR_RESET=$(printf '\033[0m')
    COLOR_GREEN=$(printf '\033[32m')
    COLOR_RED=$(printf '\033[31m')
    COLOR_YELLOW=$(printf '\033[33m')
fi

say() {
    printf '%s\n' "$*"
}

fail() {
    if [ -n "$CURRENT_STEP" ]; then
        progress_fail "$CURRENT_STEP" "$*"
    fi
    printf '%s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

progress_label() {
    case "$1" in
        detect_platform)
            printf '%s\n' 'Detect platform and shell profile'
            ;;
        install_system_packages)
            printf '%s\n' 'Install system packages'
            ;;
        verify_node_toolchain)
            printf '%s\n' 'Verify Node toolchain'
            ;;
        bootstrap_local_lib)
            printf '%s\n' 'Bootstrap Perl user-space runtime'
            ;;
        install_dashboard_package)
            printf '%s\n' 'Install Developer Dashboard'
            ;;
        initialize_dashboard)
            printf '%s\n' 'Initialize dashboard runtime'
            ;;
        *)
            printf '%s\n' "$1"
            ;;
    esac
}

progress_set_state() {
    step=$1
    status=$2
    note=${3-}
    case "$step" in
        detect_platform)
            PROGRESS_STATUS_detect_platform=$status
            PROGRESS_NOTE_detect_platform=$note
            ;;
        install_system_packages)
            PROGRESS_STATUS_install_system_packages=$status
            PROGRESS_NOTE_install_system_packages=$note
            ;;
        verify_node_toolchain)
            PROGRESS_STATUS_verify_node_toolchain=$status
            PROGRESS_NOTE_verify_node_toolchain=$note
            ;;
        bootstrap_local_lib)
            PROGRESS_STATUS_bootstrap_local_lib=$status
            PROGRESS_NOTE_bootstrap_local_lib=$note
            ;;
        install_dashboard_package)
            PROGRESS_STATUS_install_dashboard_package=$status
            PROGRESS_NOTE_install_dashboard_package=$note
            ;;
        initialize_dashboard)
            PROGRESS_STATUS_initialize_dashboard=$status
            PROGRESS_NOTE_initialize_dashboard=$note
            ;;
    esac
}

progress_status() {
    case "$1" in
        detect_platform)
            printf '%s\n' "$PROGRESS_STATUS_detect_platform"
            ;;
        install_system_packages)
            printf '%s\n' "$PROGRESS_STATUS_install_system_packages"
            ;;
        verify_node_toolchain)
            printf '%s\n' "$PROGRESS_STATUS_verify_node_toolchain"
            ;;
        bootstrap_local_lib)
            printf '%s\n' "$PROGRESS_STATUS_bootstrap_local_lib"
            ;;
        install_dashboard_package)
            printf '%s\n' "$PROGRESS_STATUS_install_dashboard_package"
            ;;
        initialize_dashboard)
            printf '%s\n' "$PROGRESS_STATUS_initialize_dashboard"
            ;;
    esac
}

progress_note() {
    case "$1" in
        detect_platform)
            printf '%s\n' "$PROGRESS_NOTE_detect_platform"
            ;;
        install_system_packages)
            printf '%s\n' "$PROGRESS_NOTE_install_system_packages"
            ;;
        verify_node_toolchain)
            printf '%s\n' "$PROGRESS_NOTE_verify_node_toolchain"
            ;;
        bootstrap_local_lib)
            printf '%s\n' "$PROGRESS_NOTE_bootstrap_local_lib"
            ;;
        install_dashboard_package)
            printf '%s\n' "$PROGRESS_NOTE_install_dashboard_package"
            ;;
        initialize_dashboard)
            printf '%s\n' "$PROGRESS_NOTE_initialize_dashboard"
            ;;
    esac
}

progress_render() {
    say "Developer Dashboard install progress"
    for step in $PROGRESS_STEPS; do
        status=$(progress_status "$step")
        note=$(progress_note "$step")
        label=$(progress_label "$step")
        case "$status" in
            done)
                prefix="${COLOR_GREEN}[OK]${COLOR_RESET}"
                ;;
            error)
                prefix="${COLOR_RED}[X]${COLOR_RESET}"
                ;;
            active)
                prefix="${COLOR_YELLOW}->${COLOR_RESET}"
                ;;
            *)
                prefix='[ ]'
                ;;
        esac
        if [ -n "$note" ]; then
            say "$prefix $label ($note)"
        else
            say "$prefix $label"
        fi
    done
}

progress_emit() {
    step=$1
    status=$(progress_status "$step")
    note=$(progress_note "$step")
    label=$(progress_label "$step")
    case "$status" in
        done)
            prefix="${COLOR_GREEN}[OK]${COLOR_RESET}"
            ;;
        error)
            prefix="${COLOR_RED}[X]${COLOR_RESET}"
            ;;
        active)
            prefix="${COLOR_YELLOW}->${COLOR_RESET}"
            ;;
        *)
            prefix='[ ]'
            ;;
    esac
    if [ -n "$note" ]; then
        say "$prefix $label ($note)"
    else
        say "$prefix $label"
    fi
}

progress_start() {
    CURRENT_STEP=$1
    progress_set_state "$1" 'active' "${2-}"
    progress_emit "$1"
}

progress_done() {
    progress_set_state "$1" 'done' "${2-}"
    if [ "$CURRENT_STEP" = "$1" ]; then
        CURRENT_STEP=''
    fi
    progress_emit "$1"
}

progress_fail() {
    progress_set_state "$1" 'error' "${2-}"
    if [ "$CURRENT_STEP" = "$1" ]; then
        CURRENT_STEP=''
    fi
    progress_emit "$1"
}

explain_sudo_requirements() {
    if [ "$SUDO_EXPLAINED" = "1" ] || [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    say "About to use sudo for system package installation."
    say "sudo will ask for your operating-system account password, not a Developer Dashboard password."
    say "This access is only for system package installation so the listed bootstrap packages can be installed."
    SUDO_EXPLAINED='1'
}

node_toolchain_ready() {
    node --version >/dev/null 2>&1 &&
        npm --version >/dev/null 2>&1 &&
        npx --version >/dev/null 2>&1
}

trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

manifest_packages() {
    manifest_path=$1
    if [ -f "$manifest_path" ]; then
        sed \
            -e 's/[[:space:]]*#.*$//' \
            -e '/^[[:space:]]*$/d' \
            "$manifest_path"
        return 0
    fi

    case "$(basename "$manifest_path")" in
        aptfile)
            printf '%s\n' "$APTFILE_DEFAULT_CONTENT" | sed \
                -e 's/[[:space:]]*#.*$//' \
                -e '/^[[:space:]]*$/d'
            return 0
            ;;
        dnfile)
            printf '%s\n' "$DNFILE_DEFAULT_CONTENT" | sed \
                -e 's/[[:space:]]*#.*$//' \
                -e '/^[[:space:]]*$/d'
            return 0
            ;;
        brewfile)
            printf '%s\n' "$BREWFILE_DEFAULT_CONTENT" | sed \
                -e 's/[[:space:]]*#.*$//' \
                -e '/^[[:space:]]*$/d'
            return 0
            ;;
        apkfile)
            printf '%s\n' "$APKFILE_DEFAULT_CONTENT" | sed \
                -e 's/[[:space:]]*#.*$//' \
                -e '/^[[:space:]]*$/d'
            return 0
            ;;
    esac

    fail "Missing manifest: $manifest_path"
}

platform_name() {
    if [ -n "$OS_OVERRIDE" ]; then
        printf '%s\n' "$OS_OVERRIDE"
        return 0
    fi

    uname_s=$(uname -s 2>/dev/null || printf 'unknown')
    case "$uname_s" in
        Darwin)
            printf '%s\n' 'darwin'
            return 0
            ;;
        Linux)
            if [ -f /etc/os-release ]; then
                os_id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"' | head -n 1)
                os_like=$(sed -n 's/^ID_LIKE=//p' /etc/os-release | tr -d '"' | head -n 1)
                case "$os_id $os_like" in
                    *alpine*)
                        printf '%s\n' 'alpine'
                        return 0
                        ;;
                    *fedora*)
                        printf '%s\n' 'fedora'
                        return 0
                        ;;
                    *ubuntu*|*debian*)
                        printf '%s\n' "${os_id:-linux}"
                        return 0
                        ;;
                esac
            fi
            [ -f /etc/alpine-release ] && {
                printf '%s\n' 'alpine'
                return 0
            }
            [ -f /etc/fedora-release ] && {
                printf '%s\n' 'fedora'
                return 0
            }
            [ -f /etc/debian_version ] && {
                printf '%s\n' 'debian'
                return 0
            }
            ;;
    esac

    fail "Unsupported platform. Supported platforms are Alpine, Debian, Ubuntu, Fedora, and macOS."
}

package_runner_prefix() {
    if [ "$(id -u)" -eq 0 ]; then
        printf '\n'
        return 0
    fi
    require_command sudo
    printf '%s\n' 'sudo'
}

choose_rc_file() {
    shell_name=$(basename "${SHELL:-sh}")
    case "$shell_name" in
        bash)
            printf '%s\n' "$HOME/.bashrc"
            return 0
            ;;
        zsh)
            printf '%s\n' "$HOME/.zshrc"
            return 0
            ;;
    esac

    if [ -f "$HOME/.profile" ]; then
        printf '%s\n' "$HOME/.profile"
        return 0
    fi
    if [ -f "$HOME/.bashrc" ]; then
        printf '%s\n' "$HOME/.bashrc"
        return 0
    fi
    if [ -f "$HOME/.zshrc" ]; then
        printf '%s\n' "$HOME/.zshrc"
        return 0
    fi
    printf '%s\n' "$HOME/.profile"
}

choose_activation_file() {
    shell_name=$(basename "${SHELL:-sh}")
    case "$shell_name" in
        bash)
            printf '%s\n' "$HOME/.profile"
            return 0
            ;;
        zsh)
            printf '%s\n' "$HOME/.zshrc"
            return 0
            ;;
    esac

    printf '%s\n' "$HOME/.profile"
}

ensure_shell_activation_bridge() {
    shell_name=$(basename "${SHELL:-sh}")
    case "$shell_name" in
        bash)
            append_block_once \
                "$HOME/.profile" \
                'developer-dashboard-bashrc-bridge' \
                'if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi'
            ;;
    esac
}

perl_meets_minimum() {
    perl_path=$1
    "$perl_path" -e "exit((\$] >= $MIN_PERL_VERSION) ? 0 : 1)" >/dev/null 2>&1
}

append_once() {
    file_path=$1
    line=$2
    touch "$file_path"
    if ! grep -Fqx "$line" "$file_path" 2>/dev/null; then
        printf '%s\n' "$line" >> "$file_path"
    fi
}

append_block_once() {
    file_path=$1
    marker=$2
    block_text=$3

    touch "$file_path"
    if grep -Fq "$marker" "$file_path" 2>/dev/null; then
        return 0
    fi

    printf '\n%s\n%s\n%s\n' \
        "# $marker" \
        "$block_text" \
        "# /$marker" >> "$file_path"
}

run_logged_command() {
    log_file=$(mktemp "${TMPDIR:-/tmp}/developer-dashboard-install.XXXXXX") ||
        fail "Unable to allocate a temporary install log under ${TMPDIR:-/tmp}"

    if "$@" >"$log_file" 2>&1; then
        rm -f "$log_file"
        return 0
    fi

    cat "$log_file" >&2
    rm -f "$log_file"
    return 1
}

download_to_path() {
    url=$1
    destination=$2
    require_command curl
    mkdir -p "$(dirname "$destination")" ||
        fail "Unable to create download directory for $destination"
    run_logged_command curl -fsSL "$url" -o "$destination" ||
        fail "Unable to download $url"
}

install_apt_packages() {
    prefix=$(package_runner_prefix)
    manifest_lines=$(manifest_packages "$APTFILE")
    packages=$(printf '%s\n' "$manifest_lines" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    [ -n "$packages" ] || return 0
    non_node_packages=$(printf '%s\n' "$manifest_lines" | grep -vx 'nodejs' | grep -vx 'npm' || true)
    non_node_list=$(printf '%s\n' "$non_node_packages" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    node_packages=$(printf '%s\n' "$manifest_lines" | grep -E '^(nodejs|npm)$' || true)

    if [ -n "$prefix" ]; then
        explain_sudo_requirements
        $prefix apt-get update
    else
        apt-get update
    fi

    if [ -n "$non_node_list" ]; then
        say "Installing Debian-family packages from $APTFILE: $non_node_list"
        if [ -n "$prefix" ]; then
            $prefix apt-get install -y $non_node_list
        else
            apt-get install -y $non_node_list
        fi
    fi

    install_debian_node_packages "$prefix" "$node_packages"
}

install_debian_node_packages() {
    prefix=$1
    node_packages=$2
    [ -n "$node_packages" ] || return 0

    if node_toolchain_ready; then
        say "Debian-family Node toolchain already available; skipping apt install for: $(printf '%s\n' "$node_packages" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
        return 0
    fi

    if printf '%s\n' "$node_packages" | grep -qx 'nodejs'; then
        say "Installing Debian-family Node runtime from $APTFILE: nodejs"
        if [ -n "$prefix" ]; then
            $prefix apt-get install -y nodejs
        else
            apt-get install -y nodejs
        fi
    fi

    if node_toolchain_ready; then
        return 0
    fi

    if printf '%s\n' "$node_packages" | grep -qx 'npm'; then
        say "Installing Debian-family npm package from $APTFILE: npm"
        if [ -n "$prefix" ]; then
            if ! $prefix apt-get install -y npm; then
                if node_toolchain_ready; then
                    return 0
                fi
                fail "Unable to install npm from Debian-family repositories. Third-party nodejs repositories can conflict with the distro npm package. Ensure node, npm, and npx are available on PATH, then rerun install.sh."
            fi
        else
            if ! apt-get install -y npm; then
                if node_toolchain_ready; then
                    return 0
                fi
                fail "Unable to install npm from Debian-family repositories. Third-party nodejs repositories can conflict with the distro npm package. Ensure node, npm, and npx are available on PATH, then rerun install.sh."
            fi
        fi
    fi
}

install_brew_packages() {
    require_command brew
    packages=$(manifest_packages "$BREWFILE" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    [ -n "$packages" ] || return 0
    say "Installing Homebrew packages from $BREWFILE: $packages"
    brew install $packages
}

install_apk_packages() {
    prefix=$(package_runner_prefix)
    packages=$(manifest_packages "$APKFILE" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    [ -n "$packages" ] || return 0
    say "Installing Alpine packages from $APKFILE: $packages"
    if [ -n "$prefix" ]; then
        explain_sudo_requirements
        $prefix apk add --no-cache $packages
    else
        apk add --no-cache $packages
    fi
}

install_dnf_packages() {
    prefix=$(package_runner_prefix)
    packages=$(manifest_packages "$DNFILE" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    [ -n "$packages" ] || return 0
    say "Installing Fedora packages from $DNFILE: $packages"
    if [ -n "$prefix" ]; then
        explain_sudo_requirements
        $prefix dnf install -y $packages
    else
        dnf install -y $packages
    fi
}

ensure_node_toolchain() {
    node_toolchain_ready || fail "Missing required Node toolchain: node, npm, and npx must all be available on PATH"
}

wrap_bootstrap_perl_tool() {
    tool_path=$1
    [ -x "$tool_path" ] || return 0

    real_tool_path="$tool_path.bootstrap-real"
    if [ ! -f "$real_tool_path" ]; then
        mv "$tool_path" "$real_tool_path" ||
            fail "Unable to prepare bootstrap wrapper for $tool_path"
    fi

    cat > "$tool_path" <<EOF
#!/bin/sh
PERL5LIB="$INSTALL_ROOT/lib/perl5${SYSTEM_PERL_ARCHNAME:+:$INSTALL_ROOT/lib/perl5/$SYSTEM_PERL_ARCHNAME}\${PERL5LIB:+:\$PERL5LIB}"
export PERL5LIB
exec "$real_tool_path" "\$@"
EOF
    chmod 0755 "$tool_path" ||
        fail "Unable to chmod bootstrap wrapper $tool_path"
}

bootstrap_perlbrew_perl() {
    export PERLBREW_ROOT
    export PERLBREW_HOME
    SYSTEM_PERL_BIN=$(command -v perl)
    SYSTEM_PERL_ARCHNAME=$("$SYSTEM_PERL_BIN" -MConfig -e 'print $Config{archname}')

    if ! command -v perlbrew >/dev/null 2>&1; then
        require_command cpanm
        say "perlbrew is not on PATH; installing App::perlbrew into $INSTALL_ROOT"
        perlbrew_dist_path="$INSTALL_ROOT/bootstrap-cache/$PERLBREW_APP_DIST_BASENAME"
        download_to_path "$PERLBREW_APP_DIST_URL" "$perlbrew_dist_path"
        run_cpanm --notest --local-lib-contained "$INSTALL_ROOT" "$perlbrew_dist_path"
        wrap_bootstrap_perl_tool "$INSTALL_ROOT/bin/perlbrew"
        wrap_bootstrap_perl_tool "$INSTALL_ROOT/bin/patchperl"
        PATH="$INSTALL_ROOT/bin:$PATH"
        PERL5LIB="$INSTALL_ROOT/lib/perl5${SYSTEM_PERL_ARCHNAME:+:$INSTALL_ROOT/lib/perl5/$SYSTEM_PERL_ARCHNAME}${PERL5LIB:+:$PERL5LIB}"
        export PATH
        export PERL5LIB
    fi

    require_command perlbrew

    say "System Perl is older than $MIN_PERL_VERSION; bootstrapping $PERLBREW_PERL with perlbrew under $PERLBREW_ROOT"
    mkdir -p "$PERLBREW_ROOT"
    run_logged_command perlbrew init ||
        fail "perlbrew init failed while preparing $PERLBREW_ROOT"
    if perlbrew_list_output=$(perlbrew list 2>/dev/null); then
        :
    else
        fail "perlbrew list failed while checking for $PERLBREW_PERL"
    fi
    if ! printf '%s\n' "$perlbrew_list_output" | grep -Fq "$PERLBREW_PERL"; then
        say "Building $PERLBREW_PERL with perlbrew. This can take a while."
        say "Progress log: $PERLBREW_ROOT/build.$PERLBREW_PERL.log"
        run_logged_command perlbrew --notest install "$PERLBREW_PERL" ||
            fail "perlbrew failed to build $PERLBREW_PERL under $PERLBREW_ROOT"
    fi

    PERL_BIN="$PERLBREW_ROOT/perls/$PERLBREW_PERL/bin/perl"
    [ -x "$PERL_BIN" ] || fail "perlbrew did not create $PERL_BIN"
    if [ ! -x "$PERLBREW_ROOT/bin/cpanm" ]; then
        run_logged_command perlbrew install-cpanm ||
            fail "perlbrew install-cpanm failed under $PERLBREW_ROOT"
    fi
    CPANM_SCRIPT="$PERLBREW_ROOT/bin/cpanm"
    [ -x "$CPANM_SCRIPT" ] || fail "perlbrew did not create $CPANM_SCRIPT"

    PERLBREW_HOME_LINE=$(printf 'export PERLBREW_HOME="%s"' "$PERLBREW_HOME")
    PERLBREW_PATH_LINE=$(printf 'export PATH="%s/perls/%s/bin:$PATH"' "$PERLBREW_ROOT" "$PERLBREW_PERL")
    append_once "$RC_FILE" "$PERLBREW_HOME_LINE"
    append_once "$RC_FILE" "$PERLBREW_PATH_LINE"
    PATH="$PERLBREW_ROOT/bin:$PERLBREW_ROOT/perls/$PERLBREW_PERL/bin:$PATH"
    export PATH
    say "Updated $RC_FILE so perlbrew metadata and $PERLBREW_PERL load automatically in new shells."
}

resolve_perl() {
    if [ "$PLATFORM" = "darwin" ]; then
        brew_perl_prefix=$(brew --prefix perl 2>/dev/null || true)
        if [ -n "$brew_perl_prefix" ] && [ -x "$brew_perl_prefix/bin/perl" ]; then
            PATH="$brew_perl_prefix/bin:$PATH"
            export PATH
        fi
    fi

    require_command perl
    if perl_meets_minimum "$(command -v perl)"; then
        PERL_BIN=$(command -v perl)
        CPANM_SCRIPT=$(command -v cpanm)
        return 0
    fi

    case "$PLATFORM" in
        alpine|debian|ubuntu|fedora)
            bootstrap_perlbrew_perl
            return 0
            ;;
    esac

    fail "Perl $MIN_PERL_VERSION or newer is required."
}

run_cpanm() {
    cpanm_script=${CPANM_SCRIPT:-$(command -v cpanm)}
    [ -n "$cpanm_script" ] || fail "Missing required command: cpanm"
    "$cpanm_script" --no-wget "$@"
}

bootstrap_local_lib() {
    require_command cpanm
    resolve_perl

    mkdir -p "$INSTALL_ROOT"
    run_cpanm --notest --local-lib-contained "$INSTALL_ROOT" local::lib App::cpanminus

    LOCAL_LIB_LINE=$(printf 'eval "$("%s" -I "%s/lib/perl5" -Mlocal::lib)"' "$PERL_BIN" "$INSTALL_ROOT")
    append_once "$RC_FILE" "$LOCAL_LIB_LINE"

    # shellcheck disable=SC2046
    eval "$("$PERL_BIN" -I "$INSTALL_ROOT/lib/perl5" -Mlocal::lib)"
}

install_dashboard() {
    run_cpanm --notest "$CPAN_TARGET"
}

shell_bootstrap_target() {
    shell_name=$(basename "${SHELL:-sh}")
    case "$shell_name" in
        bash)
            printf '%s\n' 'bash'
            return 0
            ;;
        zsh)
            printf '%s\n' 'zsh'
            return 0
            ;;
    esac

    printf '%s\n' 'sh'
}

shell_command_runner() {
    if [ -n "$SHELL_BIN_OVERRIDE" ]; then
        printf '%s\n' "$SHELL_BIN_OVERRIDE"
        return 0
    fi

    if [ -n "${SHELL:-}" ] && [ -x "${SHELL:-}" ]; then
        printf '%s\n' "$SHELL"
        return 0
    fi

    shell_name=$(basename "${SHELL:-sh}")
    resolved_shell=$(command -v "$shell_name" 2>/dev/null || true)
    if [ -n "$resolved_shell" ]; then
        printf '%s\n' "$resolved_shell"
        return 0
    fi

    printf '%s\n' '/bin/sh'
}

write_dashboard_shell_bootstrap() {
    DASHBOARD_BIN="$INSTALL_ROOT/bin/dashboard"
    if [ ! -x "$DASHBOARD_BIN" ]; then
        DASHBOARD_BIN=$(command -v dashboard || true)
    fi
    [ -n "$DASHBOARD_BIN" ] || fail "Developer Dashboard was installed but the dashboard command could not be located"
    [ -x "$DASHBOARD_BIN" ] || fail "Developer Dashboard was installed but $DASHBOARD_BIN is not executable"

    SHELL_BOOTSTRAP_LINE=$(printf 'eval "$("%s" shell %s)"' "$DASHBOARD_BIN" "$(shell_bootstrap_target)")
    append_once "$RC_FILE" "$SHELL_BOOTSTRAP_LINE"
}

run_post_install_shell_commands() {
    [ -n "$POST_INSTALL_SHELL_COMMANDS" ] || return 1

    shell_target=$(shell_bootstrap_target)
    shell_runner=$(shell_command_runner)
    say "Running post-install activation commands through $shell_target."

    case "$shell_target" in
        bash|zsh)
            "$shell_runner" -ilc ". \"$ACTIVATION_FILE\" >/dev/null 2>&1 || . \"$RC_FILE\" >/dev/null 2>&1; $POST_INSTALL_SHELL_COMMANDS"
            ;;
        *)
            ENV="$ACTIVATION_FILE" "$shell_runner" -ic ". \"$ACTIVATION_FILE\" >/dev/null 2>&1 || . \"$RC_FILE\" >/dev/null 2>&1; $POST_INSTALL_SHELL_COMMANDS"
            ;;
    esac || fail "Activated shell commands failed after installation"

    say "Post-install activation commands completed."
    return 0
}

handoff_to_activated_shell() {
    if [ "$AUTO_SHELL_MODE" = '0' ] || [ "$AUTO_SHELL_MODE" = 'false' ] || [ "$AUTO_SHELL_MODE" = 'no' ]; then
        return 1
    fi
    [ -z "$POST_INSTALL_SHELL_COMMANDS" ] || return 1
    if [ ! -t 0 ] || [ ! -t 1 ] || [ ! -t 2 ]; then
        return 1
    fi

    shell_target=$(shell_bootstrap_target)
    shell_runner=$(shell_command_runner)
    [ -x "$shell_runner" ] || return 1

    say "Launching activated $shell_target shell now. Exit once to return to your previous shell."
    case "$shell_target" in
        bash|zsh)
            exec "$shell_runner" -il
            ;;
        *)
            ENV="$ACTIVATION_FILE" exec "$shell_runner" -i
            ;;
    esac
}

initialize_dashboard() {
    require_command dashboard
    dashboard init
}

main() {
    progress_render
    progress_start detect_platform
    PLATFORM=$(platform_name)
    RC_FILE=$(choose_rc_file)
    ACTIVATION_FILE=$(choose_activation_file)
    ensure_shell_activation_bridge
    progress_done detect_platform "$PLATFORM via $(basename "$RC_FILE")"
    progress_start install_system_packages "$PLATFORM"
    case "$PLATFORM" in
        debian|ubuntu)
            install_apt_packages
            ;;
        alpine)
            install_apk_packages
            ;;
        fedora)
            install_dnf_packages
            ;;
        darwin)
            install_brew_packages
            ;;
        *)
            fail "Unsupported platform '$PLATFORM'. Supported platforms are Alpine, Debian, Ubuntu, Fedora, and macOS."
            ;;
    esac
    progress_done install_system_packages "$PLATFORM complete"
    progress_start verify_node_toolchain
    ensure_node_toolchain
    progress_done verify_node_toolchain 'node, npm, and npx ready'
    progress_start bootstrap_local_lib
    bootstrap_local_lib
    progress_done bootstrap_local_lib "$(basename "$PERL_BIN") via $(basename "$RC_FILE")"
    progress_start install_dashboard_package
    install_dashboard
    write_dashboard_shell_bootstrap
    progress_done install_dashboard_package "$CPAN_TARGET"
    progress_start initialize_dashboard
    initialize_dashboard
    progress_done initialize_dashboard "$HOME/.developer-dashboard"
    say "Developer Dashboard is installed and initialized."
    say "Shell setup was written to: $RC_FILE"
    if [ "$ACTIVATION_FILE" != "$RC_FILE" ]; then
        say "Shell activation entry point: $ACTIVATION_FILE"
    fi
    if run_post_install_shell_commands; then
        return 0
    fi
    if handoff_to_activated_shell; then
        return 0
    fi
    say "This installer ran in a child sh process, so your current shell has not loaded the new PATH yet."
    say "Run this now in your current shell:"
    say "  . \"$ACTIVATION_FILE\""
    say "Then verify with:"
    say "  dashboard version"
}

main "$@"
