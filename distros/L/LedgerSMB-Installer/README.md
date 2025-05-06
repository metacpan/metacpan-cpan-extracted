
# NAME

ledgersmb-installer - An installer for LedgerSMB, targetting as many platforms as possible
on which the LedgerSMB server can run.

The user instructions for downloading the most recent version of `ledgersmb-installer` are available at https://get.ledgersmb.org.

# SYNOPSIS

```bash
  ledgersmb-installer install --log-level=error --target=/srv/ledgersmb --version=1.12.0
```
# COMMANDS

## compute

```plain
  ledgersmb-installer compute --version=1.12.0
```

Computes the list of packages fulfilling the module dependencies.

**Note**: The computation currently does not take the module versions into account.

## download

## install

```plain
  ledgersmb-installer install --version=1.12.0
  ledgersmb-installer --version=1.12.0
```

Downloads, unpacks and installs the indicated version, if possible with the
necessary O/S packages.

## help

### Options

```plain
  --[no-]system-packages
  --target=<install directory>
  --local-lib=<installation directory for CPAN modules>
  --log-level=[fatal,error,warning,info,debug,trace]
  --[no-]verify-sig
  --version=<version>
```


# INSTALLER PROCESS

```mermaid
flowchart TD
    pre_A@{ shape: start }
    --> pre_A5(Check have compiler)
    --> pre_A7(Check have C library headers)
    --> pre_A6(Check have make)
    --> pre_A4(Check have pg_config and Pg headers)
    --> pre_A8(Check have xml2-config and libxml2 headers)
    --> pre_B(Load platform support)
    pre_B --> pre_B1{Running system Perl}
    pre_B1 --> |Yes| pre_C{"Have precomputed deps<br>(implies suitable system perl)"}
    pre_B1 --> |No| pre_D(Grab 'cpanfile' from GitHub)
    pre_C --> |Yes| pre_C1{Can install pkgs}
    pre_C --> |No| pre_D
    pre_C1 --> |Yes| pre_omicron(Check & install builder environment) --> pre_K
    pre_C1 --> |No| pre_D
    pre_D --> pre_E{Running suitable perl}

    pre_E --> |Yes| pre_omega(Check & install builder environment) --> pre_alpha{Running suitable **system** perl}
    pre_E --> |No| pre_beta{Have suitable perl}
    pre_beta --> |No: assert other prereqs| pre_E1b
    pre_beta --> |Yes| pre_gamma(Self-invoke with suitable perl)
    --> pre_Z2@{ shape: stop }

    pre_alpha --> |Yes| pre_F{Can install pkgs && <br>Have 'pkg compute' prereqs}
    pre_alpha --> |No| pre_E1a{Have DBD::Pg}

    pre_E1a --> |Yes| pre_delta
    pre_E1a --> |No| pre_E1b{Have libpq prereq}
    pre_E1b --> |Yes| pre_E1d
    pre_E1b --> |No| pre_E1c{Can install pkgs}
    pre_E1c --> |Yes| pre_E1d(Install libpq)
    pre_E1c --> |No| pre_J("**bail**<br><span style="font-size:small">(Unchanged system state;<br>no cleanup)</span>") --> pre_Z4@{ shape: stop }
    pre_E1d --> pre_delta{Have LaTeX::Driver}
    pre_delta --> |Yes| pre_E2{Running suitable Perl}
    pre_delta --> pre_epsilon{Have or install 'latex' binary}
    pre_epsilon --> |Yes| pre_E2
    pre_epsilon --> |No| pre_J
    pre_E2 --> |Yes| pre_E2b{Have libxml2}
    pre_E2 --> |No| pre_E2a(Install perlbrew) --> pre_E2c(Self-invoke with suitable perl) --> pre_Z3@{ shape: stop }
    pre_E2b --> |Yes| pre_M(Install latex)
    pre_E2b --> |No| pre_E3{Can install pkgs}
    pre_E3 --> |Yes| pre_E4(Install libxml2)
    pre_E3 --> |No| pre_E5(Install Alien::LibXML)
    pre_E4 --> pre_M
    pre_E5 --> pre_M

    pre_F --> |Yes| pre_H(Map pkg deps)
    pre_F --> |No| pre_E1a

    pre_H --> pre_K(Install packaged modules)
    pre_K --> pre_K1(Download & Install tarball)
    pre_K1 --> pre_N(Install CPAN modules)
    pre_M --> pre_K1
    pre_N --> pre_O(Cleanup: Remove build modules)
    --> pre_Z
    pre_Z@{ shape: stop }
```
