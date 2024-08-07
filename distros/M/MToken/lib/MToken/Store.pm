package MToken::Store; # $Id: Store.pm 116 2021-10-12 15:17:49Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Store - MToken store class

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use MToken::Store;

    my $store = MToken::Store->new(
        file => "/tmp/test.db",
        attributes => "RaiseError=0; PrintError=0; sqlite_unicode=1",
        do_init => 1, # Need to try initialize the db
    );

    my $store = MToken::Store->new(
        dsn => "DBI:mysql:database=MToken;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
    );

    die($store->error) unless $store->status;

=head1 DESCRIPTION

This module provides store methods.

=head2 SQLITE DDL

    CREATE TABLE "mtoken" (
      "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      "file"        CHAR(256) NOT NULL UNIQUE,
      "size"        INTEGER NOT NULL,
      "mtime"       INTEGER NOT NULL,
      "checksum"    CHAR(64) DEFAULT NULL,
      "tags"        CHAR(256) DEFAULT NULL,
      "subject"     CHAR(1024) DEFAULT NULL,
      "content"     TEXT DEFAULT NULL
    );

=head2 MYSQL DDL

    CREATE DATABASE `mtoken` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_bin */;
    CREATE TABLE IF NOT EXISTS `mtoken` (
      `id`          INT(11) NOT NULL AUTO_INCREMENT,
      `file`        VARCHAR(256) COLLATE utf8_bin NOT NULL, -- File name
      `size`        INT(11) NOT NULL, -- File size
      `mtime`       INT(11) NOT NULL, -- Unixtime value of modified time (mtime)
      `checksum`    VARCHAR(64) NOT NULL, -- Checksum (MD5/SHA1/SHA256)
      `tags`        VARCHAR(256) DEFAULT NULL, -- Tags
      `subject`     VARCHAR(1024) DEFAULT NULL, -- Subject
      `content`     TEXT COLLATE utf8_bin DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `file` (`file`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

=head2 POSTGRESQL DDL

    CREATE TABLE IF NOT EXISTS `mtoken` (
      `id`          INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
      `file`        CHAR(256) COLLATE utf8_bin NOT NULL UNIQUE,
      `size`        INTEGER NOT NULL,
      `mtime`       INTEGER NOT NULL,
      `checksum`    CHAR(64) DEFAULT NULL,
      `tags`        CHAR(256) DEFAULT NULL,
      `subject`     CHAR(1024) DEFAULT NULL,
      `content`     TEXT COLLATE utf8_bin DEFAULT NULL
    );

=head1 METHODS

=head2 new

    my $store = MToken::Store->new(
        file => "/tmp/test.db",
        attributes => "RaiseError=0; PrintError=0; sqlite_unicode=1",
        do_init => 1, # Need to try initialize the db
    );

    # ... or MySQL:

    my $store = MToken::Store->new(
        dsn => "DBI:mysql:database=mtoken;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
    );

Creates DBI object

=head2 add

    $store->add(
        file        => "test.txt",
        size        => 1024,
        mtime       => 1590000000,
        checksum    => "1a6f4a41ae8eec2da84dbfa48636e02e33575dbd",
        tags        => "test, example",
        subject     => "Test file for example",
        content     => "...Content of the file...",
    ) or die($store->error);

Add new recored

=head2 count

    print $store->count();

Returns count of records

=head2 del

    $store->del("test.txt") or die($store->error);

Delete record by filename

    $store->del(1) or die($store->error);

Delete record by record id

=head2 dsn

    my $dsn = $store->dsn;

Returns DSN string of current database connection

=head2 error

    my $error = $store->error;

Returns error message

    my $status = $store->error( "Error message" );

Sets error message if argument is provided.
This method in "set" context returns status of the operation as status() method.

=head2 file

    my $file = $store->file;

Returns the file of SQLite database

=head2 get

    my %data = $store->get("test.txt");

Returns data from database by filename

    my %data = $store->get(1);

Returns data from database by record id

=head2 getall

    my @table = $store->getall();
    my @table_100 = $store->getall(100); # row_count
    my @table_100 = $store->getall(100, 100); # offset, row_count

Returns data from database with limit supporting

=head2 is_sqlite

    print $store->is_sqlite ? "Is SQLite" : "Is NOT SQLite"

Returns true if type of current database is SQLite

=head2 ping

    $store->ping ? 'OK' : 'Database session is expired';

Checks the connection to database

=head2 set

    $store->set(
        file        => "test.txt",
        size        => 1024,
        mtime       => 1590000000,
        checksum    => "1a6f4a41ae8eec2da84dbfa48636e02e33575dbd",
        tags        => "test, example",
        subject     => "Test file for example",
        content     => "...New content of the file...",
    ) or die($store->error);

Update recored by document number

    $store->set(
        id          => 1,
        file        => "test.txt",
        size        => 1024,
        mtime       => 1590000000,
        checksum    => "1a6f4a41ae8eec2da84dbfa48636e02e33575dbd",
        tags        => "test, example",
        subject     => "Test file for example",
        content     => "...New content of the file...",
    ) or die($store->error);

Update recored by record id

=head2 status

    my $status = $store->status;
    my $status = $store->status( 1 ); # Sets the status value and returns it

Get/set BOOL status of the operation

=head2 truncate

    $store->truncate or die($store->error);

Delete all records

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::DBI>, L<MToken>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use Carp;
use CTK::DBI;
use CTK::Util qw/ touch /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use File::Spec;

use constant {
    DBFILE_MOD          => 0666,
    DEFAULT_DSN_MASK    => 'DBI:SQLite:dbname=%s',
    DEFAULT_DBI_ATTR    => {
            dsn         => '', # See DEFAULT_DSN_MASK
            user        => '',
            password    => '',
            set         => [
                    'RaiseError 0',
                    'PrintError 0',
                    'sqlite_unicode 1',
                ],
        },
};

use constant DDL_CREATE_TABLE => <<'DDL';
CREATE TABLE IF NOT EXISTS "mtoken" (
    "id"        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    "file"      CHAR(256) NOT NULL UNIQUE,
    "size"      INTEGER NOT NULL,
    "mtime"     INTEGER NOT NULL,
    "checksum"  CHAR(64) DEFAULT NULL,
    "tags"      CHAR(256) DEFAULT NULL,
    "subject"   CHAR(1024) DEFAULT NULL,
    "content"   TEXT DEFAULT NULL
)
DDL
use constant DDL_CREATE_INDEX => <<'DDL';
CREATE UNIQUE INDEX "file" ON "mtoken" (
    "file"
)
DDL

use constant DML_ADD => <<'DML';
INSERT INTO `mtoken`
    (`file`,`size`,`mtime`,`checksum`,`tags`,`subject`,`content`)
VALUES
    (?,?,?,?,?,?,?)
DML

use constant DML_GET_COUNT => <<'DML';
SELECT COUNT(`id`) AS `cnt`
FROM `mtoken`
DML

use constant DML_GET_BY_ID => <<'DML';
SELECT `id`,`file`,`size`,`mtime`,`checksum`,`tags`,`subject`,`content`
FROM `mtoken`
WHERE `id` = ?
DML

use constant DML_GET_BY_FILE => <<'DML';
SELECT `id`,`file`,`size`,`mtime`,`checksum`,`tags`,`subject`,`content`
FROM `mtoken`
WHERE `file` = ?
DML

use constant DML_GETALL => <<'DML';
SELECT `id`,`file`,`size`,`mtime`,`checksum`,`tags`,`subject`
FROM `mtoken`
ORDER BY `file` ASC
DML

use constant DML_DEL_BY_ID => <<'DML';
DELETE FROM `mtoken` WHERE `id` = ?
DML

use constant DML_DEL_BY_FILE => <<'DML';
DELETE FROM `mtoken` WHERE `file` = ?
DML

use constant DML_TRUNCATE => <<'DML';
DELETE FROM `mtoken`
DML

use constant DML_SET_BY_ID => <<'DML';
UPDATE `mtoken`
SET `file` = ?, `size` = ?, `mtime` = ?, `checksum` = ?, `tags` = ?, `subject` = ?, `content` = ?
WHERE `id` = ?
DML

use constant DML_SET_BY_FILE => <<'DML';
UPDATE `mtoken`
SET `file` = ?, `size` = ?, `mtime` = ?, `checksum` = ?, `tags` = ?, `subject` = ?, `content` = ?
WHERE `file` = ?
DML

sub new {
    my $class = shift;
    my %args = @_;
    my $args_set = $args{'set'};
    unless ($args{dsn}) {
        my $dda = DEFAULT_DBI_ATTR;
        foreach (keys %$dda) {
            next if $_ eq 'set';
            $args{$_} //= $dda->{$_}
        }
    }
    my $file = $args{file} // "";
    my $dsn = $args{dsn} || sprintf(DEFAULT_DSN_MASK, $file);
    my %attrs_from_set = _set2attr($args_set);
    my %attrs_from_str = $args{attributes} ? _parseDBAttributes($args{attributes}) : ();
    my %attrs = (%attrs_from_set, %attrs_from_str);
       %attrs = _set2attr(DEFAULT_DBI_ATTR()->{set}) unless %attrs;

    # DB
    my $db = CTK::DBI->new(
        -dsn        => $dsn,
        -debug      => 0,
        -username   => $args{'user'},
        -password   => $args{'password'},
        -attr       => {%attrs},
        $args{timeout} ? (
            -timeout_connect => $args{timeout},
            -timeout_request => $args{timeout},
        ) : (),
    );
    my $dbh = $db->connect if $db;

    # SQLite
    my $fnew = 0;
    my $issqlite = 0;
    my $do_init = $args{do_init} ? 1 : 0;
    if ($dbh && $dsn =~ /SQLite/i) { # If SQLite (default)
        $file = $dbh->sqlite_db_filename();
        if ($do_init) {
            unless ($file && (-e $file) && !(-z $file)) {
                touch($file);
                chmod(DBFILE_MOD, $file);
                $fnew = 1;
            }
        }
        $issqlite = 1;
    }

    # Defaults
    my $status = 1; # Ok
    my $error = "";
    if (!$db) {
        $error = sprintf("Can't init database \"%s\"", $dsn);
        $status = 0;
    } elsif (!$dbh) {
        $error = sprintf("Can't connect to database \"%s\": %s", $dsn, $DBI::errstr || "unknown error");
        $status = 0;
    } elsif ($fnew && $do_init) {
        $db->execute(DDL_CREATE_TABLE);
        $db->execute(DDL_CREATE_INDEX) unless $dbh->err;
        $error = $dbh->errstr();
        $status = 0 if $dbh->err;
    }
    unless ($error) { # No errors
        unless ($dbh->ping) {
            $error = sprintf("Can't init database \"%s\". Ping failed: %s",
                $dsn, $dbh->errstr() || "unknown error");
            $status = 0;
        }
    }

    my $self = bless {
            file    => $file,
            issqlite=> $issqlite,
            dsn     => $dsn,
            error   => $error // "",
            dbi     => $db,
            status  => $status,
        }, $class;

    return $self;
}

sub status {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{status}) unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $value = shift;
    return uv2null($self->{error}) unless defined($value);
    $self->{error} = $value;
    $self->status($value ne "" ? 0 : 1);
    return $value;
}
sub ping {
    my $self = shift;
    return 0 unless $self->{dsn};
    my $dbi = $self->{dbi};
    return 0 unless $dbi;
    my $dbh = $dbi->{dbh};
    return 0 unless $dbh;
    return 0 unless $dbh->can('ping');
    return $dbh->ping();
}
sub dsn {
    my $self = shift;
    return $self->{dsn};
}
sub is_sqlite {
    my $self = shift;
    return $self->{issqlite} ? 1 : 0;
}
sub file {
    my $self = shift;
    return $self->{file};
}

# CRUD Methods

sub add {
    my $self = shift;
    my %data = @_;
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Add
    $dbi->execute(DML_ADD,
        $data{file},
        $data{size} || 0,
        $data{mtime} || time(),
        $data{checksum},
        $data{tags},
        $data{subject},
        $data{content},
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't insert new record: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return 1;
}
sub count {
    my $self = shift;
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    my $cnt = $dbi->field(DML_GET_COUNT) || 0;
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get count: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }

    return $cnt;
}
sub get {
    my $self = shift;
    my $id = shift || 0;
    return () unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    my %rec = $dbi->recordh(is_int($id) ? DML_GET_BY_ID : DML_GET_BY_FILE, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get record: %s", uv2null($dbi->connect->errstr)));
        return ();
    }

    return %rec;
}
sub getall {
    my $self = shift;
    my $row_count = pop;
    my $offset = pop;
    return () unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};
    my $limit = $row_count
        ? $offset
            ? sprintf(" LIMIT %d, %d", $offset, $row_count)
            : sprintf(" LIMIT %d", $row_count)
        : "";

    my @tbl = $dbi->table(sprintf("%s%s", DML_GETALL,  $limit ));
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get records: %s", uv2null($dbi->connect->errstr)));
        return ();
    }
    return @tbl;
}
sub del {
    my $self = shift;
    my $id = shift || 0;
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    $dbi->execute(is_int($id) ? DML_DEL_BY_ID : DML_DEL_BY_FILE, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't delete record: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}
sub truncate {
    my $self = shift;
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    $dbi->execute(DML_TRUNCATE);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't truncate table: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}
sub set {
    my $self = shift;
    my %data = @_;
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Set by id or num
    $dbi->execute($data{id} ? DML_SET_BY_ID : DML_SET_BY_FILE,
        $data{file},
        $data{size} || 0,
        $data{mtime} || time(),
        $data{checksum},
        $data{tags},
        $data{subject},
        $data{content},
        $data{id} || $data{file},
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't update record: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return 1;
}

sub _set2attr {
    my $in = shift;
    my $attr = is_array($in) ? $in : array($in => "set");
    my %attrs;
    foreach (@$attr) {
        $attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    return %attrs;
}
sub _parseDBAttributes { # Example: foo=123, bar=gii,baz;qux=werwe
    my $t = shift || return ();
    my %as = ();
    for ($t ? (split /\s*[,;]\s*/, $t) : ()) {
        my ($k,$v) = (split /\s*=>?\s*|\s*\:\s*/, $_);
        $as{$k} = $v;
    }
    return %as;
}

1;

__END__
