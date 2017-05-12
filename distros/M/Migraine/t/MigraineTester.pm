package MigraineTester;

use DBI;
use Migraine;

=head1 NAME

MigraineTester - Test class for Migraine

=head1 SYNOPSIS

    # Set MIGRAINE_TESTS_DSN environment variable
    # Possibly set MIGRAINE_TESTS_USER and MIGRAINE_TESTS_PASSWORD too

    use MigraineTester;
    my $migraine_tester = MigraineTester->new(__FILE__, plan => 6);
    my $migrator = $migraine_tester->migrator;

    $migraine_tester->fetch_data("SELECT * FROM some_table");

=head1 DESCRIPTION

Testing class for Migraine. It sets up automatically the C<migrations_dir> to
use (based on the test name: if it is "t/001-something.t", the migrations dir
will be "t/001-migrations/").

It drops and recreates the given database, connecting to the C<mysql> database
and issuing "CREATE DATABASE" AND "DROP DATABASE" commands.

=head1 METHODS

=over 4

=item fetch_data($query)

Fetchs data from the C<$query> and returns it in C<selectall_arrayref> format.

=back

=head1 TODO

Currently it only supports MySQL for the tests.

=cut

use Test::More;

sub new {
    my ($class, $test_name, %user_opts) = @_;

    my ($dsn, $user, $password) = ($ENV{MIGRAINE_TESTS_DSN},
                                   $ENV{MIGRAINE_TESTS_USER},
                                   $ENV{MIGRAINE_TESTS_PASSWORD});
    defined $dsn || return $class->skip_all;
    ($dsn =~ /^dbi:mysql:/) || die "Only mysql is supported for tests";
    $dsn =~ /database=([^;]+)/;
    my $database = $1;
    defined $database || return $class->skip_all;

    # Drop the database and recreate
    my $admin_dsn = $dsn;
    $admin_dsn =~ s/database=([^;]+)/database=mysql/;
    my $dbh = DBI->connect($admin_dsn, $user, $password);
    my $sth_drop = $dbh->prepare("DROP DATABASE IF EXISTS $database");
    $sth_drop->execute;
    my $sth_create = $dbh->prepare("CREATE DATABASE $database");
    $sth_create->execute;

    $test_name =~ m|t/(\d+)-*|;
    my $migrations_dir = "t/$1-migrations";
    my %opts = (migrations_dir => $migrations_dir,
                dbi_options => {PrintError => 0,
                                PrintWarn  => 0,
                                RaiseError => 1},
                %user_opts);
    $opts{user}     = $user     if defined $user;
    $opts{password} = $password if defined $password;
    my $self = {test_name => $test_name,
                database  => $database,
                dsn       => $dsn,
                user      => $user,
                password  => $password,
                migrator  => Migraine->new($dsn, %opts)};

    plan tests => $opts{plan};

    bless $self, $class;
}

sub skip_all {
    my ($class) = @_;
    plan skip_all => "No MIGRAINE_TESTS_DSN environment variable";
    return {}, $class;
}

sub migrator {
    my ($self) = @_;
    $self->{migrator};
}

sub dbh {
    my ($self) = @_;
    $self->{dbh} ||= DBI->connect($self->{dsn},
                                  $self->{user},
                                  $self->{password});
}

sub fetch_data {
    my ($self, $query) = @_;

    $self->dbh->selectall_arrayref($query);
}

1;
