#!/usr/bin/env perl
#
# Test the url decoding for a folder name
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;

use Test::More tests => 16;
use File::Spec;

my $mgr = Mail::Box::Manager->new;

$ENV{USER} = 'Jan';

sub same(@)
{   my $expect = pop @_;
    my $made   = { @_ };

    unless(defined $made)
    {   warn "Nothing produced.";
        return 0;
    }

    foreach (keys %$made)
    {   next if exists $expect->{$_};
        warn "Key $_ made too much.";
        return 0;
    }

#warn sort keys %$made;
#warn sort keys %$expect;
    foreach (keys %$expect)
    {   next if exists $made->{$_};
        warn "Key $_ expected too much.";
        return 0;
    }

    foreach (keys %$made)
    {   next if defined $made->{$_} && defined $expect->{$_}
                &&  $made->{$_} eq $expect->{$_};

        next if !defined $made->{$_} && !defined $expect->{$_};

        warn "Key $_: ",(defined $made->{$_}   ? $made->{$_}   : '<undef>'),
                 ";",   (defined $expect->{$_} ? $expect->{$_} : '<undef>');

        return 0;
    }

    return 1;
}

ok(not defined $mgr->decodeFolderURL('x'));

ok(same($mgr->decodeFolderURL('mbox:x'),
    { type => 'mbox', username => 'Jan', password => ''
    , server_name => 'localhost', server_port => undef, folder => 'x' }
  ));

ok(same($mgr->decodeFolderURL('mbox:/x/y'),
    { type => 'mbox', username => 'Jan', password => ''
    , server_name => 'localhost', server_port => undef, folder => '/x/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3:///x/y'),
    { type => 'pop3', username => 'Jan', password => ''
    , server_name => 'localhost', server_port => undef, folder => '/x/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://'),
    { type => 'pop3', username => 'Jan', password => ''
    , server_name => 'localhost', server_port => undef, folder => '=' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me:secret@host:42/y'),
    { type => 'pop3', username => 'me', password => 'secret'
    , server_name => 'host', server_port => 42, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me:secret@host/y'),
    { type => 'pop3', username => 'me', password => 'secret'
    , server_name => 'host', server_port => undef, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me:secret@:12/y'),
    { type => 'pop3', username => 'me', password => 'secret'
    , server_name => 'localhost', server_port => 12, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me:secret@/y'),
    { type => 'pop3', username => 'me', password => 'secret'
    , server_name => 'localhost', server_port => undef, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me@/y'),
    { type => 'pop3', username => 'me', password => ''
    , server_name => 'localhost', server_port => undef, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me@:42/y'),
    { type => 'pop3', username => 'me', password => ''
    , server_name => 'localhost', server_port => 42, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me@host/y'),
    { type => 'pop3', username => 'me', password => ''
    , server_name => 'host', server_port => undef, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://tux.home.aq:42/y'),
    { type => 'pop3', username => 'Jan', password => ''
    , server_name => 'tux.home.aq', server_port => 42, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://tux.home.aq/y'),
    { type => 'pop3', username => 'Jan', password => ''
    , server_name => 'tux.home.aq', server_port => undef, folder => '/y' }
  ));

ok(same($mgr->decodeFolderURL('pop3://tux.home.aq'),
    { type => 'pop3', username => 'Jan', password => ''
    , server_name => 'tux.home.aq', server_port => undef, folder => '=' }
  ));

ok(same($mgr->decodeFolderURL('pop3://me:secret@tux.home.aq'),
    { type => 'pop3', username => 'me', password => 'secret'
    , server_name => 'tux.home.aq', server_port => undef, folder => '=' }
  ));
