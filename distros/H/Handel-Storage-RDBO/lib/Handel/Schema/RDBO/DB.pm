# $Id$
## no critic (ProhibitPostfixControls, ProhibitExcessComplexity)
package Handel::Schema::RDBO::DB;
use strict;
use warnings;

BEGIN {
    use base qw/Rose::DB/;
    use Handel::ConfigReader;
    require DBI;
};
__PACKAGE__->use_private_registry;
__PACKAGE__->default_connect_options(PrintError => 0, Warn => 0);

foreach my $driver (qw/pg mysql sqlite informix oracle/) {
    __PACKAGE__->register_db(
        domain     => 'handel',
        type       => $driver,
        driver     => $driver,
        autocommit => 1
    );
};

# this needs to be factored into ConfigReader!
sub get_db {
    my ($self, $dsn, $user, $pass, $opts) = @_;
    my $cfg = Handel::ConfigReader->instance;
    my %args = (
        dsn             => $dsn,
        username        => $user,
        password        => $pass,
        connect_options => $opts
    );

    ## I hate this vs. ||=, but it just wouldn't cover on some perl versions
    if (!$args{'dsn'}) {
        $args{'dsn'} = $cfg->{'HandelDBIDSN'} || $cfg->{'db_dsn'};
    };
    if (!$args{'username'}) {
        $args{'username'} = $cfg->{'HandelDBIUser'} || $cfg->{'db_user'};
    };
    if (!$args{'password'}) {
        $args{'password'} = $cfg->{'HandelDBIPassword'} || $cfg->{'db_pass'};
    };
    if (!$args{'connect_options'}) {
        $args{'connect_options'} = {AutoCommit => 1};
    };

    if ($args{'dsn'}) {
        my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($args{'dsn'});
        $args{'driver'} = $driver;
        $args{'connect_options'} = {%{$args{'connect_options'}}, %{$attr_hash || {}}};

        if ($driver_dsn =~ /^(.*)@(.*)$/) {
            $args{'database'} = $1;
            ($args{'host'} , $args{'port'}) = split(/:/, $2);
        } elsif ($driver_dsn =~ /(;|=)/) {
            if ($driver_dsn =~ /(dbname|db|database)=(.*?)(;|$)/i) {
                $args{'database'} = $2;
            };
            if ($driver_dsn =~ /port=(.*?)(;|$)/i) {
                $args{'port'} = $1;
            };
            if ($driver_dsn =~ /(host|hostname|server)=(.*?)(;|$)/i) {
                $args{'host'} = $2;
            };
        } else {
            $args{'database'} =  $driver_dsn;
        };
    } else {
        $args{'driver'}   = $cfg->{'HandelDBIDriver'} || $cfg->{'db_driver'} || 'SQLite';
        $args{'host'}     = $cfg->{'HandelDBIHost'}   || $cfg->{'db_host'}   || '';
        $args{'port'}     = $cfg->{'HandelDBIPort'}   || $cfg->{'db_port'}   || '';
        $args{'database'} = $cfg->{'HandelDBIName'}   || $cfg->{'db_name'}   || '';

        $args{'dsn'} = 'dbi:' . $args{'driver'} . ':dbname=' . $args{'database'};

        if ($args{'host'}) {
            $args{'dsn'} .= ';host=' . $args{'host'};
        };

        if ($args{'host'} && $args{'port'}) {
            $args{'dsn'} .= ';port=' . $args{'port'};
        };
    };

    ## not using dsn due now that recent Rose::DB knows more about dsns
    ## than we do
    delete $args{'dsn'};

    return $self->new(
        domain => 'handel',
        type   => lc($args{'driver'}),
        %args
    );
};

1;
__END__

=head1 NAME

Handel::Schema::RDBO::DB - RDBO DB class for the Handel::Storage::RDBO

=head1 SYNOPSIS

    use Handel::Schema::RDBO::DB;
    use strict;
    use warnings;

    my $db = Handel::Schema::RDBO::DB->new(
        domain => 'handel', type => 'bogus'
    );

=head1 DESCRIPTION

Handel::Schema::RDBO::DB is a generic Rose::DB class for use as the default
connections used in Handel::Storage::RDBO classes.

=head1 METHODS

=head2 get_db

Returns a new pre configured db object. If no connection information is supplied,
the connection information will be read from C<ENV> or ModPerl using the
configuration options available in the specified C<config_class>. By default,
this will be L<Handel::ConfigReader|Handel::ConfigReader>.

=head1 SEE ALSO

L<Rose::DB>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
