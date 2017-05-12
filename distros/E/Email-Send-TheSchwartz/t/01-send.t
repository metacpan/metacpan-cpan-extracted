# $Id: 01-send.t 3 2007-05-04 01:54:52Z btrott $

use strict;
use Test::More tests => 11;

use Carp qw( croak );
use DBI;
use Email::Send;
use Email::Send::TheSchwartz;

ok( Email::Send::TheSchwartz->is_available, 'Email::Send::TheSchwartz is available' );

my $email = <<'EOF';
To:   Ben Trott <ben@sixapart.com>
From: Ben Trott <ben@sixapart.com>
Subject: This should never show up in my inbox

blah blah blah
EOF

## Sending should fail if the client hasn't been initialized.
{
    my $sender = Email::Send->new({ mailer => 'TheSchwartz' });
    my $return = $sender->send($email);
    ok !$return, "send() failed because $return";
    like $return, qr/unless client is initialized/, "error message says what we expect";
}

## Test sending with an actual SQLite database set up for TheSchwartz.
SKIP:
{
    skip "Live tests require DBD::SQLite", 7
        unless eval { require DBD::SQLite };
    my $client = sch_client();

    my $sender = Email::Send->new({ mailer => 'TheSchwartz' });
    $sender->mailer_args([ _client => $client ]);
    my $return = $sender->send($email);
    ok $return, 'send() succeeded with Schwartz client configured as _client';
    my $handle = $return->prop('handle');
    isa_ok $handle, 'TheSchwartz::JobHandle';

    my $job = $client->lookup_job( $handle->as_string );
    isa_ok $job, 'TheSchwartz::Job';
    is $job->funcname, 'TheSchwartz::Worker::SendEmail';
    is $job->coalesce, 'sixapart.com@ben';
    is_deeply $job->arg->{rcpts}, [ 'ben@sixapart.com' ];
    is $job->arg->{env_from}, 'ben@sixapart.com';
    my $email = Email::Simple->new( $job->arg->{data} );
    like $email->body, qr/blah blah blah/;
}

sub sch_args {
    return databases => [ {
        dsn     => dsn_for('email'),
        user    => 'root',
        pass    => '',
    } ];
}

sub sch_client {
    setup_db('email');
    return TheSchwartz->new( sch_args() );
    END { teardown_db('email') }
}

sub dsn_for {
    return 'dbi:SQLite:dbname=' . $_[0] . '.db';
}

sub setup_db {
    teardown_db($_[0]);
    my $dbh = DBI->connect(dsn_for($_[0]), 'root', '', {
        RaiseError => 1, PrintError => 0,
    }) or croak "Couldn't connect: $DBI::errstr";
    our $SQL ||= load_sql();
    for my $sql (@$SQL) {
        $dbh->do($sql);
    }
    $dbh->disconnect;
}

sub load_sql {
    my $sql = do { local $/; <DATA> };
    return [ split /;\s*/, $sql ];
}

sub teardown_db {
    unlink $_[0] . '.db';
}

__DATA__
CREATE TABLE funcmap (
        funcid         INTEGER PRIMARY KEY AUTOINCREMENT,
        funcname       VARCHAR(255) NOT NULL,
        UNIQUE(funcname)
);

CREATE TABLE job (
        jobid           INTEGER PRIMARY KEY AUTOINCREMENT,
        funcid          INTEGER UNSIGNED NOT NULL,
        arg             MEDIUMBLOB,
        uniqkey         VARCHAR(255) NULL,
        insert_time     INTEGER UNSIGNED,
        run_after       INTEGER UNSIGNED NOT NULL,
        grabbed_until   INTEGER UNSIGNED NOT NULL,
        priority        SMALLINT UNSIGNED,
        coalesce        VARCHAR(255),
        UNIQUE(funcid,uniqkey)
);

CREATE TABLE error (
        error_time      INTEGER UNSIGNED NOT NULL,
        jobid           INTEGER NOT NULL,
        message         VARCHAR(255) NOT NULL,
        funcid          INT UNSIGNED NOT NULL DEFAULT 0
);

CREATE TABLE exitstatus (
        jobid           INTEGER PRIMARY KEY NOT NULL,
        funcid          INT UNSIGNED NOT NULL DEFAULT 0,
        status          SMALLINT UNSIGNED,
        completion_time INTEGER UNSIGNED,
        delete_after    INTEGER UNSIGNED
);
