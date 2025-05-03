# File::Syslogger

## SYNOPSIS

```
filesyslogger [-c <config>]
```

## FLAGS

### -c config file

This is the config file to use. If not specified, '/usr/local/etc/filesyslogger.toml' is
used.

## CONFIG FILE

The file format used is TOML.

The primary and optional keys are as below.

| keys     | default       | description                      |
|----------|---------------|----------------------------------|
| priority | notice        | The priority of the logged item. |
| facility | daemon        | The facility for logging.        |
| program  | fileSyslogger | Name of the program logging.     |
| socket   | /var/run/log  | The syslogd socket.              |

Each file defined in a TOML table. `priority`, `facility`, and `program` can be used like
above.

| keys | default | description          |
|------|---------|----------------------|
| file | undef   | The file to read in. |

Each TOML table is used for specifying what files to tail and forward to syslog. It uses
the same keys as above, minus 'socket', but with the additional key 'file' for specifying
what file.

File rotation is picked up automatically via POE::Wheel::FollowTail.

For priority, below are the various valid values.

    emerg
    emergency
    alert
    crit
    critical
    err
    error
    warning
    notice
    info

For facility, below are the various valid values.

    kern
    user
    mail
    daemon
    auth
    syslog
    lpr
    news
    uucp
    cron
    authpriv
    ftp
    local0
    local1
    local2
    local3
    local4
    local5
    local6
    local7

### EXAMPLE

```
facility="daemon"
priority="alert"
socket="/var/run/log"
[sagan]
program="saganEve"
file="/var/log/sagan/eve"
[suricata]
program="suricataEve"
file="/var/log/suricata/eve"
```

## INSTALLING

### FreeBSD

```
pkg install p5-POE-Wheel-FollowTail p5-TOML p5-Log-Syslog-Fast p5-POE p5-App-cpanminus
cpanminus File::Syslogger
```

### Debian

```
apt-get install cpanminus libpoe-perl libtoml-perl
cpanminus Log::Syslog::Fast File::Syslogger
```

### From Src

```
perl Makefile.PL
make
make test
make install
```
