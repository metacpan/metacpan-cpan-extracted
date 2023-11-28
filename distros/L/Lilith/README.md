# Lilith

Lilith reads in EVE files from Suricata and Sagan into PostgreSQL.

From there that data can then be searched and information on specific
events fetched.

## Intalation

### Debian

```
apt-get install zlib1g-dev cpanminus libjson-perl libtoml-perl \
 libdbi-perl libfile-readbackwards-perl libdigest-sha-perl libpoe-perl \
 libfile-slurp-perl libdbd-pg-perl
cpanm Lilith
```

### FreeBSD

```
pkg install p5-App-cpanminus p5-JSON p5-TOML p5-DBI \
 p5-File-ReadBackwards p5-Digest-SHA p5-POE \
 p5-MIME-Base64 p5-Gzip-Faster p5-DBD-Pg p5-File-Slurp
cpanm Lilith
```

### Source

```
perl Makefile.PL
make
make test
make install
```

## Setup

First you need to setup your PostgreSQL server.

```
createuser -D -l -P -R -S lilith
createdb -E UTF8 -O lilith lilith
```

Setup `/usr/local/etc/lilith.toml`

```
dsn="dbi:Pg:dbname=lilith;host=192.168.1.2"
pass="WhateverYouSetAsApassword"
user="lilith"
# a handy one to ignore for the extend as it is spammy
class_ignore=["Generic Protocol Command Decode"]

# add a suricata instance to monitor
[suricata-eve]
instance="foo-pie"
type="suricata"
eve="/var/log/suricata/alert.json"

# add a second suricata instance to monitor
[another-eve]
instance="foo2-pie"
type="suricata"
eve="/var/log/suricata/alert2.json"

# add a sagan eve to monitor
# instance name is 'foo-lae', given there is no value for instance
[foo-lae]
type="sagan"
eve="/var/log/sagan/alert.json"
```

Now we just need to setup the tables.

```
lilith -a create_tables
```

If using snmpd.

```
extend lilith /usr/local/bin/lilith -a extend
```

### Config File

The default config file is `/usr/local/etc/lilith.toml`.

| Variable     | Description                                                                                                            |
|--------------|------------------------------------------------------------------------------------------------------------------------|
| dsn          | A DSN connection string to be used by [DBI][https://metacpan.org/pod/DBI]. [DBD::Pg][https://metacpan.org/pod/DBD::Pg] |
| pass         | Password to use for the connection.                                                                                    |
| user         | User to use for the connetion.                                                                                         |
| class_ignore | Array of classes to ignore.                                                                                            |

Sub hashes are then treated as a instance. The following values are
available for that.

| Variable | Required | Description                                                        |
|----------|----------|--------------------------------------------------------------------|
| eve      | yes      | The EVE file to follow.                                            |
| type     | yes      | `sagan` or `suricata`, depending on which it is.                   |
| instance | no       | The name for the instance. If not specified the hash name is used. |

## Options

### SYNOPSIS

lilith \[-c \<config\>\] -a run

lilith -a class_map

lilith \[-c \<config\>\] -a create_tables

lilith \[-c \<config\>\] -a dump_self

lilith \[-c \<config>\] -a event \[-t \<table\>\] --id \<row_id\> \[--raw\]
\[\[--virani \<remote\>\] \[--pcap \<output file\>\] \[--buffer \<buffer secodns\>\]\]

lilith \[-c \<config\>\] -a event \[-t \<table\>\] --event \<event_id\> \[--raw\]
\[\[--virani \<remote\>\] \[--pcap \<output file\>\] \[--buffer \<buffer secodns\>\]\]

lilith \[-c \<config\>\] -a extend \[-Z\] \[-m \<minutes\>\]

lilith -a generate_baphomet_yamls --dir \<dir\>

lilith \[-c \<config\>\] -a get_short_class_snmp_list

lilith \[-c \<config\>\] -a search \[--output \<return\>\] \[-t \<table\>\]
\[-m \<minutes\>\] \[--order \<clm\>\] \[--limit \<int\>\] \[--offset \<int\>\]
\[--orderdir \<dir\>\] \[--si \<src_ip\>\] \[--di \<dst_ip\>\] \[--ip \<ip\>\]
\[--sp \<src_port\>\] \[--dp \<dst_port\>\] \[--port \<port\>\] \[--host \<host\>\]
\[--hostl\] \[--hosN\] \[--ih \<host\>\] \[--ihl\] \[--ihN\] \[-i \<instance\>\]
\[-il\] \[-iN\] \[-c \<class\>\] \[--cl\] \[--cN\] \[-s \<sig\>\] \[--sl\]
\[--sN\] \[--if \<if\>\] \[--ifl\] \[--ifN\] \[--ap \<proto\>\] \[--apl\] \[--apN\]
\[--gid \<gid\>\] \[--sid \<sid\>\] \[--rev \<rev\>\]

### GENERAL SWITCHES

#### -a <action>

The action to perform.

    - Default :: search

#### -c <config>

The config file to use.

    - Default :: /usr/local/etc/lilith.toml

#### -t <table>

Table to operate on.

    - Default :: suricata

### ACTIONS

#### run

Start processing the EVE logs and daemonize.

#### class_map

Print a table of class mapping from long name to the short name used for display in the search results.

#### create_tables

Create the tables in the DB.

#### dump_self

Initiate Lilith and then dump it via Data::Dumper.

#### event

Fetches a event. The table to use can be specified via -t.

##### --id <row_id>

Fetch event via row ID.

##### --event <event_id>

Fetch the event via the event ID.

##### --raw

Do not decode the EVE JSON.

##### --pcap <file>

Fetch the remote PCAP via Virani and write it to the file. Only usable for with Suricata tables.

Default :: undef

##### --virani <conf>

Virani setting to pass to -r.

Default :: instance name in alert

##### --buffer <secs>

How many seconds to pad the start and end time with.

Default :: 60

#### extend

Prints a LibreNMS style extend.

##### -Z

Enable Gzip+Base64 LibreNMS style extend compression.

##### -m <minutes>

How far back to search. For the extend action, 5 minutes
is the default.

#### generate_baphomet_yamls

Generate the YAMLs for Baphomet.

##### -d <dir>

The directory to write it out too.

#### get_short_class_snmp_list

Print a list of shorted class names for use wit SNMP.

#### search

Search the DB. The table may be specified via -t.

The common option types for search are as below.

    - Integer :: A comma seperated list of integers to check for. Any number
                 prefixed with a ! will be negated.
    - String :: A string to check for. May be matched using like or negated via
                the proper options.
    - Complex :: A item to match.

##### General Search Options

###### --output <return>

The output type.

    - Values :: table,json
    - Default :: table

###### -m <minute>

How far back to to in minutes.

    - Default :: 1440

    - Default, extend :: 5

###### --order <column>

Column to use for sorting by.

    - Default :: timestamp

###### --orderdir <direction>

Direction to order in.

    - Values :: ASC,DSC
    - Default :: ASC

##### IP Options

###### --si <src IP>

Source IP.

    - Default :: undef
    - Type :: string

######  --di <dst IP>

Destination IP.

    - Default :: undef
    - Type :: string

######  --ip <IP>

IP, either dst or src.

    - Default :: undef
    - Type :: complex

#####  Port Options

###### --sp <src port>

Source port.

    - Default :: undef
    - Type :: integer

######  --dp <dst port>

Destination port.

    - Default :: undef
    - Type :: integer

###### -p <port>

Port, either dst or src.

    - Default :: undef
    - Type :: complex

##### Host Options

    Sagan :: Host is the sending system and instance host is the host the
             instance is running on.

    Suricata :: Host is the system the instance is running on. There is no
                instance host.

###### --host <host>

Host.

    - Default :: undef
    - Type :: string

###### --hostl

Use like for matching host.

    - Default :: undef

###### --hostN

Invert host matching.

    - Default :: undef

##### Instance Options

###### --ih <host>

Instance host.

    - Default :: undef
    - Type :: string

###### --ihl

Use like for matching instance host.

    - Default :: undef

###### --ihN

Invert instance host matching.

    - Default :: undef

##### Instance Options

=head4 -i  <instance>

Instance.

    - Default :: undef
    - Type :: string

###### --il

Use like for matching instance.

    - Default :: undef

###### --iN

Invert instance matching.

    - Default :: undef

##### Class Options

###### -c <class>

Classification.

    - Default :: undef
    - Type :: string

###### --cl

Use like for matching classification.

    - Default :: undef

###### --cN

Invert class matching.

    - Default :: undef

##### Signature Options

###### -s <sig>

Signature.

    - Default :: undef
    - Type :: string

###### --sl

Use like for matching signature.

    - Default :: undef

###### --sN

Invert signature matching.

    - Default :: undef

##### In Interface Options

###### --if <if>

Interface.

    - Default :: undef
    - Type :: string

###### --ifl

Use like for matching interface.

    - Default :: undef

###### --ifN

Invert interface matching.

    - Default :: undef

##### App Proto Options

###### --ap <proto>

App proto.

    - Default :: undef
    - Type :: string

###### --apl

Use like for matching app proto.

    - Default :: undef

###### --apN

Invert app proto matching.

    - Default :: undef

##### Rule Options

###### --gid <gid>

GID.

    - Default :: undef
    - Type :: integer

###### --sid <sid>

SID.

    - Default :: undef
    - Type :: integer

###### --rev <rev>

Rev.

    - Default :: undef
    - Type :: integer

## ENVIROMENTAL VARIABLES

### Lilith_table_color

The L<Text::ANSITable> table color to use.

    - Default :: Text::ANSITable::Standard::NoGradation

### Lilith_table_border

The L<Text::ANSITable> border type to use.

    - Default :: ASCII::None

### Lilith_IP_color

Perl boolean for if IPs should be colored or not.

    - Default :: 1

### Lilith_IP_private_color

ANSI color to use for private IPs.

    - Default :: bright_green

### Lilith_IP_remote_color

ANSI color to use for remote IPs.

    - Default :: bright_yellow

### Lilith_IP_local_color

ANSI color to use for local IPs.

    - Default :: bright_red

### Lilith_timesamp_drop_micro

Perl boolean for if microseconds should be dropped or not.

    - Default :: 1

### Lilith_instance_color

If the lilith instance colomn info should be colored.

    - Default :: 1

### Lilith_instance_type_color

Color for the instance name.

    - Default :: bright_blue

### Lilith_instance_slug_color

Color for the insance slug.

    - Default :: bright_magenta

### Lilith_instance_loc_color

Color for the insance loc.

	- Default :: bright_cyan.

