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
```

Now we just need to setup the tables.

```
lilith -a create_tables
```

If using snmpd.

```
extend lilith /usr/local/bin/lilith -a extend
```

## --help

```
--config <ini>     Config INI file.
                   Default :: /usr/local/etc/lilith.ini

-a <action>        Action to perform.
                   Default :: search

Action :: run
Description :: Runs the ingestion loop.

Action :: class_map
Description :: Display class to short class mappings.

Action :: create_tables
Description :: Creates the tables in PostgreSQL.

Action :: event
Description :: Fetch the information for the specified event.
               Either --id or --event is needed.

--id <row id>  Row ID to fetch.
               Default :: undef

--event <id>   Event ID to fetch.
               Default :: undef

Action :: extend
Description :: LibreNMS style SNMP extend.

-m <minutes>    How far backt to go in minutes.
                Default :: 5

-Z              LibreNMS style compression, gzipped and
                then base64 encoded.
                Default :: undef

Action :: search
Description :: Searches the specified table returns the results.

--ouput <return>   Return type. Either table or json.
                   Default :: table

-t <table>         Table to search. suricata/sagan
                   Default :: suricata

-m <minutes>       How far backt to go in minutes.
                   Default :: 1440

--order <clm>      Column to order by.
                   Default :: timestamp

--limit <int>      Limit to return.
                   Default :: undef

--offset <int>     Offset for a limited return.
                   Default :: undef

--orderdir <dir>   Direction to order in.
                   Default :: ASC


* IP Options


--si <src ip>    Source IP.
                 Default :: undef
                 Type :: string

--di <dst ip>    Destination IP.
                 Default :: undef
                 Type :: string

--ip <ip>        IP, either dst or src.
                 Default :: undef
                 Type :: complex


* Port Options

--sp <src port>  Source port.
                 Default :: undef
                 Type :: integer

--dp <dst port>  Destination port.
                 Default :: undef
                 Type :: integer

-p <port>        Port, either dst or src.
                 Default :: undef
                 Type :: complex


* Host Options

--host <host>   Host.
                Default :: undef
                Type :: string

--hostl         Use like for matching host.
                Default :: undef

--hostN         Invert host matching.
                Default :: undef

--ih <host>     Instance host.
                Default :: undef
                Type :: string

--ihl           Use like for matching instance host.
                Default :: undef

--ihN           Invert instance host matching.
                Default :: undef


* Instance Options

--i <instance>  Instance.
                Default :: undef
                Type :: string

--il            Use like for matching instance.
                Default :: undef

--iN            Invert instance matching.
                Default :: undef


* Class Options

-c <class>      Classification.
                Default :: undef
                Type :: string

-cl             Use like for matching classification.
                Default :: undef

--cN            Invert class matching.
                Default :: undef


* Signature Options

-s <sig>        Signature.
                Default :: undef
                Type :: string

-sl             Use like for matching signature.
                Default :: undef

--sN            Invert signature matching.
                Default :: undef


* In Interface Options

-if <if>        Interface.
                Default :: undef
                Type :: string

-ifl            Use like for matching interface.
                Default :: undef

--ifN           Invert interface matching.
                Default :: undef


* App Proto Options

-ap <proto>     App proto.
                Default :: undef
                Type :: string

-apl            Use like for matching app proto.
                Default :: undef

--apN           Invert app proto matching.
                Default :: undef


* Rule Options

--gid <gid>     GID.
                Default :: undef
                Type :: integer

--sid <sid>     SID.
                Default :: undef
                Type :: integer

--rev <rev>     Rev.
                Default :: undef
                Type :: integer

* Types

Integer :: A comma seperated list of integers to check for. Any number
           prefixed with a ! will be negated.
String :: A string to check for. May be matched using like or negated via
          the proper options.
Complex :: A item to match.
```
