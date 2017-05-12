[![Build Status](https://travis-ci.org/ajiyoshi-vg/MemcacheDB-Dump.svg?branch=master)](https://travis-ci.org/ajiyoshi-vg/MemcacheDB-Dump)
# NAME

MemcacheDB::Dump - It's new $module

# SYNOPSIS

    use MemcacheDB::Dump;

    my $dumper = MemcacheDB::Dump->new('/path/to/db/file');

    my $hashref = $dumper->run;

    my $value = $dumper->get('some key');

    my @keys = $dumper->keys;

# DESCRIPTION

MemcacheDB (http://memcachedb.org/) is a KVS designed for persistent.
MemcacheDB::Dump is dumper for MemcacheDB's backend strage file.

# LICENSE

Copyright (C) ajiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ajiyoshi <yoichi@ajiyoshi.org>
