=head1 NAME

Log::Handler::Output::DBI - Log messages to a database.

=head1 SYNOPSIS

    use Log::Handler::Output::DBI;

    my $db = Log::Handler::Output::DBI->new(
        # database source
        database    => "database",
        driver      => "mysql",
        host        => "127.0.0.1",
        port        => 3306,

        # or with "dbname" instead of "database"
        dbname      => "database",
        driver      => "Pg",
        host        => "127.0.0.1",
        port        => 5432,

        # or with data_source
        data_source => "dbi:mysql:database=database;host=127.0.0.1;port=3306",

        # Username and password
        user        => "user",
        password    => "password",

        # debugging
        debug       => 1,

        # table, columns and values (as string)
        table       => "messages",
        columns     => "level ctime cdate pid hostname progname message",
        values      => "%level %time %date %pid %hostname %progname %message",

        # table, columns and values (as array reference)
        table       => "messages",
        columns     => [ qw/level ctime cdate pid hostname progname message/ ],
        values      => [ qw/%level %time %date %pid %hostname %progname %message/ ],

        # table, columns and values (your own statement)
        statement   => "insert into messages (level,ctime,cdate,pid,hostname,progname,message) values (?,?,?,?,?,?,?)",
        values      => [ qw/%level %time %date %pid %hostname %progname %message/ ],

        # if you like persistent connections and want to re-connect
        persistent  => 1,
    );

    my %message = (
        level       => "ERROR",
        time        => "10:12:13",
        date        => "1999-12-12",
        pid         => $$,
        hostname    => "localhost",
        progname    => $0,
        message     => "an error here"
    );

    $db->log(\%message);

=head1 DESCRIPTION

With this output you can insert messages into a database table.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::DBI object.

The following options are possible:

=over 4

=item B<data_source>

Set the dsn (data source name).

You can use this parameter instead of C<database>, C<driver>, C<host>
and C<port>.

=item B<database> or B<dbname>

Pass the database name.

=item B<driver>

Pass the database driver.

=item B<host>

Pass the hostname where the database is running.

=item B<port>

Pass the port where the database is listened.

=item B<user>

Pass the database user for the connect.

=item B<password>

Pass the users password.

=item B<table> and B<columns>

With this options you can pass the table name for the insert and the columns.
You can pass the columns as string or as array. Example:

    # the table name
    table => "messages",

    # columns as string
    columns => "level, ctime, cdate, pid, hostname, progname, message",

    # columns as array
    columns => [ qw/level ctime cdate pid hostname progname message/ ],

The statement would created as follows

    insert into message (level, ctime, cdate, pid, hostname, progname, mtime, message)
                 values (?,?,?,?,?,?,?)

=item B<statement>

With this option you can pass your own statement if you don't want to you the
options C<table> and C<columns>.

    statement => "insert into message (level, ctime, cdate, pid, hostname, progname, mtime, message)"
                 ." values (?,?,?,?,?,?,?)"

=item B<values>

With this option you have to set the values for the insert.

        values => "%level, %time, %date, %pid, %hostname, %progname, %message",

        # or

        values => [ qw/%level %time %date %pid %hostname %progname %message/ ],

The placeholders are identical with the pattern names that you have to pass
with the option C<message_pattern> from L<Log::Handler>.

    %L   level
    %T   time
    %D   date
    %P   pid
    %H   hostname
    %N   newline
    %C   caller
    %p   package
    %f   filename
    %l   line
    %s   subroutine
    %S   progname
    %r   runtime
    %t   mtime
    %m   message

Take a look to the documentation of L<Log::Handler> for all possible patterns.

=item B<persistent>

With this option you can enable or disable a persistent database connection and
re-connect if the connection was lost.

This option is set to 1 on default.

=item B<dbi_params>

This option is useful if you want to pass arguments to L<DBI>. The default is
set to

    {
        PrintError => 0,
        AutoCommit => 1
    }

C<PrintError> is deactivated because this would print error messages as
warnings to STDERR.

You can pass your own arguments - and overwrite it - with

    dbi_params => { PrintError => 1, AutoCommit => 0 }

=item B<debug>

With this option it's possible to enable debugging. The information can be
intercepted with C<$SIG{__WARN__}>.

=back

=head2 log()

Log a message to the database.

    my $db = Log::Handler::Output::DBI->new(
        database   => "database",
        driver     => "mysql",
        user       => "user",
        password   => "password",
        host       => "127.0.0.1",
        port       => 3306,
        table      => "messages",
        columns    => [ qw/level ctime message/ ],
        values     => [ qw/%level %time %message/ ],
        persistent => 1,
    );

    $db->log(
        message => "your message",
        level   => "INFO",
        time    => "2008-10-10 10:12:23",
    );

Or you can connect to the database yourself. You should
notice that if the database connection lost then the
logger can't re-connect to the database and would return
an error. Use C<dbi_handle> at your own risk.

    my $dbh = DBI->connect(...);

    my $db = Log::Handler::Output::DBI->new(
        dbi_handle => $dbh,
        table      => "messages",
        columns    => [ qw/level ctime message/ ],
        values     => [ qw/%level %time %message/ ],
    );

=head2 connect()

Connect to the database.

=head2 disconnect()

Disconnect from the database.

=head2 validate()

Validate a configuration.

=head2 reload()

Reload with a new configuration.

=head2 errstr()

This function returns the last error message.

=head1 PREREQUISITES

    Carp
    Params::Validate
    DBI
    your DBI driver you want to use

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output::DBI;

use strict;
use warnings;
use DBI;
use Carp;
use Params::Validate qw();

our $VERSION = "0.12";
our $ERRSTR  = "";

sub new {
    my $class = shift;
    my $opts  = $class->_validate(@_);
    my $self  = bless $opts, $class;

    if ($self->{debug}) {
        warn "Create a new Log::Handler::Output::DBI object";
    }

    return $self;
}

sub log {
    my $self    = shift;
    my $message = @_ > 1 ? {@_} : shift;
    my @values  = ();

    foreach my $v (@{$self->{values}}) {
        if (ref($v) eq "CODE") {
            push @values, &$v();
        } elsif ($v =~ /^%(.+)/ && exists $message->{$1}) {
            push @values, $message->{$1};
        } else {
            push @values, $v;
        }
    }

    if ($self->{debug}) {
        warn "execute: ".@values." bind values";
    }

    $self->connect or return undef;

    if ( ! $self->{sth}->execute(@values) ) {
        return $self->_raise_error("DBI execute error: ".DBI->errstr);
    }

    if (!$self->{persistent} && !$self->{dbi_handle}) {
        $self->disconnect or return undef;
    }

    return 1;
}

sub connect {
    my $self = shift;

    if ($self->{persistent} && $self->{dbh}) {
        if ($self->{use_ping}) {
            if ($self->{dbh}->ping) {
                return 1;
            }
        } else {
            eval { $self->{dbh}->do($self->{pingstmt}) or die DBI->errstr };
            return 1 unless $@;
        }
    }

    if ($self->{debug}) {
        warn "Connect to the database: $self->{cstr}->[0] ...";
    }

    my $dbh;

    if ($self->{dbi_handle}) {
        # If db ping failed and dbi_handle and dbi is set
        # then it seems that the database is down.
        if ($self->{dbi}) {
            return $self->_raise_error("dbi_handle - lost connection");
        }
        $dbh = $self->{dbi_handle};
    } else {
        $dbh = DBI->connect(@{$self->{cstr}})
            or return $self->_raise_error("DBI connect error: ".DBI->errstr);
    }

    my $sth = $dbh->prepare($self->{statement})
        or return $self->_raise_error("DBI prepare error: ".$dbh->errstr);

    $self->{dbh} = $dbh;
    $self->{sth} = $sth;

    return 1;
}

sub disconnect {
    my $self = shift;

    if ($self->{sth}) {
        $self->{sth}->finish
            or return $self->_raise_error("DBI finish error: ".$self->{sth}->errstr);

        delete $self->{sth};
    }

    if ($self->{dbh}) {
        if ($self->{debug}) {
            warn "Disconnect from database";
        }

        $self->{dbh}->disconnect
            or return $self->_raise_error("DBI disconnect error: ".DBI->errstr);;

        delete $self->{dbh};
    }

    return 1;
}

sub validate {
    my $self = shift;
    my $opts = ();

    eval { $opts = $self->_validate(@_) };

    if ($@) {
        return $self->_raise_error($@);
    }

    return $opts;
}

sub reload {
    my $self = shift;
    my $opts = $self->validate(@_);

    if (!$opts) {
        return undef;
    }

    $self->disconnect;

    foreach my $key (keys %$opts) {
        $self->{$key} = $opts->{$key};
    }

    return 1;
}

sub errstr {
    return $ERRSTR;
}

#
# private stuff
#

sub _validate {
    my $class = shift;

    my %options = Params::Validate::validate(@_, {
        dbi_handle => {
            type => Params::Validate::OBJECT,
            optional => 1,
        },
        data_source => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        database => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        dbname => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        driver => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        user => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        password => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        host => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        port => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        table => {
            type => Params::Validate::SCALAR,
            depends => [ "columns" ],
            optional => 1,
        },
        columns => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
            depends => [ "table" ],
            optional => 1,
        },
        values => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
        },
        statement => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        persistent => {
            type => Params::Validate::SCALAR,
            default => 1,
        },
        dbi_params => {
            type => Params::Validate::HASHREF,
            default => { PrintError => 0, AutoCommit => 1 },
        },
        use_ping => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
        debug => {
            type => Params::Validate::SCALAR,
            regex => qr/^[01]\z/,
            default => 0,
        },
    });

    if (!$options{table} && !$options{statement}) {
        Carp::croak "Missing one of the mandatory options: 'statement' or 'table' and 'columns'";
    }

    # build the connect string (data source name)
    my @cstr = ();

    if (defined $options{data_source}) {
        @cstr = ($options{data_source});
    } elsif ($options{driver} && ($options{database} || $options{dbname})) {
        $cstr[0] = "dbi:$options{driver}:";

        if ($options{database}) {
            $cstr[0] .= "database=$options{database}";
        } else {
            $cstr[0] .= "dbname=$options{dbname}";
        }

        if ($options{host}) {
            $cstr[0] .= ";host=$options{host}";
            if ($options{port}) {
                $cstr[0] .= ";port=$options{port}";
            }
        }
    } elsif (!defined $options{dbi_handle}) {
        Carp::croak "Missing mandatory options data_source or database/dbname";
    }

    if ($options{user}) {
        $cstr[1] = $options{user};
        if ($options{password}) {
            $cstr[2] = $options{password};
        }
    }

    $cstr[3] = $options{dbi_params};
    $options{cstr} = \@cstr;

    # build the statement

    if (!ref($options{values})) {
        $options{values} = [ split /[\s,]+/, $options{values} ];
    }

    if (!$options{statement}) {

        $options{statement} = "insert into $options{table} (";

        if (ref($options{columns})) {
            $options{statement} .= join(",", @{$options{columns}});
        } else {
            $options{statement} .= join(",", split /[\s,]+/, $options{columns});
        }

        $options{statement} .= ") values (";

        my @binds;
        foreach my $v (@{$options{values}}) {
            $v =~ s/^\s+//;
            $v =~ s/\s+\z//;
            push @binds, "?";
        }

        $options{statement} .= join(",", @binds);
        $options{statement} .= ")";
    }

    if ($options{driver} && $options{driver} =~ /oracle/i) {
        $options{pingstmt} = "select 1 from dual";
    } else {
        $options{pingstmt} = "select 1";
    }

    return \%options;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

1;
