package HealthCheck::Diagnostic::DBHCheck;

# ABSTRACT: Check a database handle to make sure you have read/write access
use version;
our $VERSION = 'v1.0.0'; # VERSION

use 5.010;
use strict;
use warnings;
use parent 'HealthCheck::Diagnostic';

use Carp;
use Scalar::Util qw( blessed );

sub new {
    my ($class, @params) = @_;

    # Allow either a hashref or even-sized list of params
    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    croak("The 'dbh' parameter should be a coderef!")
      if ($params{dbh} && (ref $params{dbh} ne "CODE"));

    return $class->SUPER::new(
        tags  => [ 'dbh_check' ],
        label =>   'dbh_check',
        %params
    );
}

sub check {
    my ( $self, %params ) = @_;

   # 1st, try to get dbh from provided parameters
    my $dbh = $params{dbh};
    # 2nd, if invoked with an object (not the class), then get dbh from object
    $dbh ||= $self->{dbh} if ref $self;

    croak "Valid 'dbh' is required" unless $dbh;

    croak "The 'dbh' parameter should be a coderef!"
        unless ref $dbh eq "CODE";

    my $db_access = $params{db_access}          # Provided call to check()
        // ((ref $self) && $self->{db_access})  # Value from new()
        || "rw";                                # default value

    croak "The value '$db_access' is not valid for the 'db_access' parameter"
        unless $db_access =~ /^r[ow]$/;

    my $timeout =
        defined $params{timeout}                  ? $params{timeout} :
        (ref $self) && (defined $self->{timeout}) ? $self->{timeout} :
                                                    10;

    local $@;
    eval {
        local $SIG{__DIE__};
        local $SIG{ALRM} = sub { die "timeout after $timeout seconds.\n" };
        alarm $timeout;
        $dbh = $dbh->(%params);
    };
    alarm 0;

    if ( $@ =~ /^timeout/ ) {
        chomp $@;
        return {
            status => 'CRITICAL',
            info   => "Database connection $@",
        };
    }

    # re-throw any other exceptions
    die $@ if $@;

    croak "The 'dbh' coderef should return an object!"
        unless blessed $dbh;

    my $db_class = $params{db_class}            # Provided in call to check()
        // ((ref $self) && $self->{db_class})   # Value from new
        || "DBI::db";                           # default value

    my $isa = ref $dbh;

    croak "The 'dbh' coderef should return a '$db_class', not a '$isa'"
        unless $dbh->isa($db_class);

    my $res = $self->SUPER::check(
        %params,
        dbh       => $dbh,
        db_access => $db_access,
        db_class  => $db_class
    );
    delete $res->{dbh};    # don't include the object in the result

    return $res;
}


sub _read_write_temp_table {
    my (%params) = @_;
    my $dbh      = $params{dbh};
    my $table    = $params{table_name} // "__DBH_CHECK__";
    my $status   = "CRITICAL";

    my $qtable   = $dbh->quote_identifier($table);

    # Drop it like it's hot
    $dbh->do("DROP TEMPORARY TABLE IF EXISTS $qtable");

    $dbh->do(
        join(
            "",
            "CREATE TEMPORARY TABLE IF NOT EXISTS $qtable (",
            "check_id INTEGER PRIMARY KEY,",
            "check_string VARCHAR(64) NOT NULL",
            ")"
        )
    );

    $dbh->do(
        join(
            "",
            "INSERT INTO $qtable ",
            "       (check_id, check_string) ",
            "VALUES (1,        'Hello world')",
        )
    );
    my @row = $dbh->selectrow_array(
        "SELECT check_string FROM $qtable WHERE check_id = 1"
    );

    $status = "OK" if ($row[0] && ($row[0] eq "Hello world"));

    $dbh->do("DROP TEMPORARY TABLE $qtable");

    return $status;
}

sub run {
    my ( $self, %params ) = @_;
    my $dbh = $params{dbh};

    # Get db_access from parameters
    my $read_write = ($params{db_access} =~ /^rw$/i);

    my $status = "OK";

    RUN_TESTS: {

        # See if we can ping the DB connection
        if ($dbh->can("ping") && !$dbh->ping) {
            $status = "CRITICAL";
            last RUN_TESTS;
        }

        # See if a simple SELECT works
        my $value = eval { $dbh->selectrow_array("SELECT 1"); };
        unless (defined $value && $value == 1) {
            $status = "CRITICAL";
            last RUN_TESTS;
        }

        $status = _read_write_temp_table(%params) if $read_write;
    }

    # Generate the human readable info string
    my $info = sprintf(
        "%s %s %s check of %s%s",
        $status eq "OK" ? "Successful" : "Unsuccessful",
        $dbh->{Driver}->{Name},
        $read_write ? "read write" : "read only",
        $dbh->{Name},
        $dbh->{Username} ? " as $dbh->{Username}" : "",
    );

    return { status => $status, info => $info };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::DBHCheck - Check a database handle to make sure you have read/write access

=head1 VERSION

version v1.0.0

=head1 SYNOPSIS

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::DBHCheck->new(
            dbh       => \&connect_to_read_write_db,
            db_access => "rw",
            tags      => [qw< dbh_check_rw >]
            timeout   => 10, # default
        ),
        HealthCheck::Diagnostic::DBHCheck->new(
            dbh       => \&connect_to_read_only_db,
            db_access => "ro",
            tags      => [qw< dbh_check_ro >]
        ),
    ] );

    my $result = $health_check->check;
    $result->{status}; # OK on a successful check or CRITICAL otherwise

=head1 DESCRIPTION

Determines if the database can be used for read and write access, or read only
access.

For read access, a simple SELECT statement is used.

For write access, a temporary table is created, and used for testing.

=head1 ATTRIBUTES

Those inherited from L<HealthCheck::Diagnostic/ATTRIBUTES> plus:

=head2 label

Inherited from L<"label" in HealthCheck::Diagnostic|HealthCheck::Diagnostic/label1>,
defaults to C<dbh_check>.

=head2 tags

Inherited from L<"tags" in HealthCheck::Diagnostic|HealthCheck::Diagnostic/tags1>,
defaults to C<[ 'dbh_check' ]>.

=head2 dbh

A coderef that returns a
L<DBI DATABASE handle object|DBI/DBI-DATABASE-HANDLE-OBJECTS>
or optionally the handle itself.

Can be passed either to C<new> or C<check>.

=head2 db_access

A string indicating the type of access being tested.

A value of C<ro> indicates only read access shoud be tested.

A value of C<rw> indicates both read and write access should be tested.

DEFAULT is C<rw>.

=head2 db_class

The expected class for the database handle returned by the C<dbh> coderef.

Defaults to C<DBI::db>.

=head2 timeout

Sets up an C<ALRM> signal handler used to timeout the initial connection
attempt after the number of seconds provided.

Defaults to 10.

=head1 DEPENDENCIES

L<HealthCheck::Diagnostic>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2023 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
