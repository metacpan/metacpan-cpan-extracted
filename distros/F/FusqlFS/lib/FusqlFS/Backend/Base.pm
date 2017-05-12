use strict;
use 5.010;

package FusqlFS::Backend::Base;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::Base - base FusqlFS class for database backend implementations

=head1 SYNOPSIS

    use FusqlFS::Backend::PgSQL;
    use parent 'FusqlFS::Backend::Base';

    use FusqlFS::Backend::PgSQL::Tables;
    use FusqlFS::Backend::PgSQL::Views;
    use FusqlFS::Backend::PgSQL::Sequences;
    use FusqlFS::Backend::PgSQL::Roles;

    sub init
    {
        my $self = shift;
        $self->{subpackages} = {
            tables    => new FusqlFS::Backend::PgSQL::Tables(),
            views     => new FusqlFS::Backend::PgSQL::Views(),
            sequences => new FusqlFS::Backend::PgSQL::Sequences(),
            roles     => new FusqlFS::Backend::PgSQL::Roles(),
        };
    }

    sub dsn
    {
        my $self = shift;
        return 'Pg:'.$shift->SUPER::dsn(@_);
    }

    1;

=head1 DESCRIPTION

This is the base abstract class and start point for any FusqlFS database
backend implementation. The instance of this class's subclass is a "root" of
fusqlfs file system.

You start your backend implementation by subclassing C<FusqlFS::Backend::Base>
and overriding some methods as described in L</SYNOPSIS>.

See L</METHODS> section for detailed description of what you should and should
not override.

You should define C<subpackages> instance variable among other operations in
order for your backend class to be usable. The value of this property must be a
hashref which describes root of fusqlfs subsystem: its keys will be file names,
and values will be these files' content (well, the values are usually
L<FusqlFS::Artifact> instances interfacing to different database artifacts, so
"file" here means not only plain file, but directories, symlinks and
pseudopipes as well). See L<FusqlFS::Artifact/autopackages> for a way to
automate this process.

See also L<FusqlFS::Entry> to learn how this instance variable is used, how
file paths are mapped to backend objects and how file type is determined.

=head1 METHODS

=over

=cut

use DBI;
use FusqlFS::Entry;
use FusqlFS::Formatter;

use Carp;

=item new

Class constructor.

Input: %options.
Output: $backend_base_instance.

This method does a lot of initialization work, including DBI connection
initialization and setup of different inner variables, data representation
layer setup etc., so do not override and redefine it unless you really know
what you are doing. And if you really need to override it, consider calling it
with C<$class-E<gt>SUPER::new(...)> at some point to avoid unnecessary work.

If you need to do some initialization work, consider overriding L</init> method
which is created to be overridden and redefined.

=cut
sub new
{
    return $FusqlFS::Artifact::instance if $FusqlFS::Artifact::instance;

    my $class = shift;
    my %options = @_;
    my $dsn = 'DBI:'.$class->dsn(@options{qw(host port database)});
    my $debug = $options{debug}||0;
    my $fnsep = $options{fnsep}||'.';
    my $format = $options{format}||'';

    $Carp::Verbose = $debug > 3;
    my $self = {
        subpackages => {},
        limit       => 0 + ($options{limit}||0),
        charset     => $options{charset}||'',
        fnsep       => $fnsep,
        fnsplit     => qr/[$fnsep]/,
        connect     => sub () {
                           DBI->connect($dsn, @options{qw(user password)},
                           {
                               PrintError  => $debug > 0,
                               PrintWarn   => $debug > 1,
                               ShowErrorStatement => $debug > 2,
                               HandleError => sub { carp(shift); },
                           }) or die "Failed to connect to $dsn: $DBI::err $DBI::state $DBI::errstr";
                       },
    };
    $self->{dbh} = $self->{connect}();

    ($self->{dumper}, $self->{loader}) = FusqlFS::Formatter->init($format);
    $self->{namemap} = $options{namemap};

    bless $self, $class;

    $FusqlFS::Artifact::instance = $self;
    $self->init();
    return $self;
}

=item connect, disconnect, reconnect

These methods can be used to control database connection in runtime.
Please use them instead of direct DBH object access via $fusqlh->{dbh},
as they make some more work, than simple database {dis,re}connection.

They use credentials, provided on first backend object initialization
with L</new> method above, so no parameters are required.

C<connect> establish new database connection and reinitializes backend.
Backend reinitialization is required, because some backends make some
query preparation, linked to current database connection.

C<disconnect> drops database connection, and C<reconnect> drops database
connection is it's active (checked with L<DBI::ping> method) and
then establish connection anew. This method is used in C<HUP>
signal handler to reset database connection.

=cut
sub connect
{
    my $self = shift;
    $self->{dbh} = $self->{connect}();
    $self->init();
}

sub disconnect
{
    $_[0]->{dbh}->disconnect();
}

sub reconnect
{
    my $self = shift;
    $self->disconnect() if $self->{dbh}->ping();
    $self->connect();
}

=item by_path

Returns L<FusqlFS::Entry> entry by path.

Input: $path, $leaf_absent=undef.
Output: $entry_instance.

See L<FusqlFS::Entry> for detailed description. This method is just a
convenient way of constructing C<FusqlFS::Entry>'s instance as you don't need
to pass first C<$fs> argument to it.

=cut
sub by_path
{
    return FusqlFS::Entry->new(@_);
}

=item dsn

Compose DSN string for the L<DBI/connect> method.

Input: $host, $port, $database.
Output: $dsn.

This method composes basic database type agnostic DSN string, e.g. without any
database driver prefix. You should override this method to prepend it with DBD
prefix like `Pg:' or `mysql:' or modify it in some other way as needed.

=begin testing dsn

#!noinst

is FusqlFS::Backend::Base->dsn('host', 'port', 'database'), 'host=host;port=port;database=database;', 'FusqlFS::Backend::Base->dsn is sane';

=end testing
=cut
sub dsn
{
    my $dsn = "";
    $dsn .= "host=$_[1];" if $_[1];
    $dsn .= "port=$_[2];" if $_[2];
    $dsn .= "database=$_[3];";
    return $dsn;
}

=item init

I<Abstract method> called after main initialization work in L</new> is done.

No data is passed to this method, except for class instance reference as first
argument, and all data returned from it are ignored.

This is an abstract method called as instance method after L</new> is done all
initialization work and you should override it if you have some additional
initialization work to do. You will override it most times, actually.

=cut
sub init
{
    return;
}

=item destroy

Destroy instance state variable.

The C<FusqlFS::Backend::Base> class is a singleton. It is initialized only once
and every subsequent call to L</new> method returns the same class instance,
stored in inner state variable.

Sometimes you really need to reset this instance and reinitialize this
singleton. If this is the case, use this method.

Do it only if you really understand all the sequences and you don't have any
other way to do the thing you want to do.

=cut
sub destroy
{
    if ($FusqlFS::Artifact::instance)
    {
        undef $FusqlFS::Artifact::instance;
    }
}

1;

