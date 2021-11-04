#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 04-store.t 98 2021-10-07 23:19:53Z minus $
#
#########################################################################
use Test::More tests => 9;
use MToken::Store;
use MToken::Util qw/sha1sum/;

my $dbfile = "mtoken_test.db.tmp";

# Create instance
my $store = MToken::Store->new(
    file => $dbfile,
    attributes => "RaiseError=0; PrintError=0; sqlite_unicode=1",
    do_init => 1,
); #note(explain($store));
ok($store->status, "Create Store instance") or diag($store->error);
ok($store->ping, "Ping") or diag($store->error);

# Add new record #1
{
    ok($store->add(
        file        => "test1.txt",
        size        => 1001,
        mtime       => time(),
        checksum    => sha1sum("Test file content #1"),
        content     => "Test file content #1",
    ), "Add new record 1") or diag($store->error);
}

# Get record data
my %info = ();
{
    %info = $store->get("test1.txt");
    ok($info{id} && $store->status, "Get record data for test1.txt") or diag($store->error);
}
#note(explain(\%info));

# Add new record #2
{
    ok($store->add(
        file        => "test2.txt",
        size        => 1002,
        mtime       => time(),
        checksum    => sha1sum("Test file content #2"),
        content     => "Test file content #2",
    ), "Add new record 2") or diag($store->error);
}

# Update record
{
    ok($store->set(
        file        => "test1.txt",
        size        => 1003,
        mtime       => time(),
        checksum    => sha1sum("Test file content #1 (modified)"),
        content     => "Test file content #1 (modified)",
    ), "Update record 1") or diag($store->error);
}

# Get all records
my @all = ();
{
    @all = $store->getall();
    ok(@all && $store->status, "Get all records") or diag($store->error);
}
#note(explain(\@all));

# Delete record
{
    ok($store->del($info{id}), "Delete record by id") or diag($store->error);
}

# Delete all records
{
    ok($store->truncate(), "Delete all records") or diag($store->error);
}

1;

__END__
