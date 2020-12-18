use strict;
use warnings;
use Test::Roo;
use Test::Deep '!blessed';
use Test::FailWarnings;
use Test::Fatal;
use Test::Requires qw/MongoDB/;

use Time::HiRes;
use DateTime;
use Meerkat::DateTime;

my $conn = eval { MongoDB::MongoClient->new; };
plan skip_all => "No MongoDB on localhost"
  unless eval { $conn->get_database("admin")->run_command( [ ismaster => 1 ] ) };

use lib 't/lib';

with 'TestFixtures';

test 'set epoch' => sub {
    my $self = shift;
    my $obj  = $self->create_person;
    my $now  = time - 40 * 365.25 * 24 * 3600; # about 40 years ago
    $obj->update_set( birthday => $now );
    is( $obj->birthday->epoch, $now, "attribute set" );
    isa_ok( $obj->birthday->DateTime, 'DateTime', "inflation" );
};

test 'set DateTime' => sub {
    my $self = shift;
    my $obj  = $self->create_person;
    my $birthday =
      DateTime->new( year => 1973, month => 7, day => 16, time_zone => "UTC" );
    $obj->update_set( birthday => $birthday );
    is( $obj->birthday->epoch, $birthday->epoch, "attribute set" );
};

test 'set DateTime::Tiny' => sub {
    plan skip_all => 'requires DateTime::Tiny'
      unless eval { require DateTime::Tiny; 1 };
    my $self = shift;
    my $obj  = $self->create_person;
    my $birthday =
      DateTime::Tiny->new( year => 1973, month => 7, day => 16, time_zone => "UTC" );
    $obj->update_set( birthday => $birthday );
    is( $obj->birthday->epoch, $birthday->DateTime->epoch, "attribute set" );
};

test 'construct object with epoch' => sub {
    my $self = shift;
    my $now  = time - 40 * 365.25 * 24 * 3600;          # about 40 years ago
    my $obj  = $self->create_person( birthday => $now );
    is( $obj->birthday->epoch, $now, "attribute set" );
};

run_me;
done_testing;
#
# This file is part of Meerkat
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
# vim: ts=4 sts=4 sw=4 et:
