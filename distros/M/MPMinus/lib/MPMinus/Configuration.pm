package MPMinus::Configuration; # $Id: Configuration.pm 278 2019-05-11 19:52:16Z minus $
use strict;

use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Configuration - Configuration of MPMinus

=head1 VERSION

Version 1.34

=head1 SYNOPSIS

    package MPM::foo::Handlers;
    use strict;

    sub handler {
        my $r = shift;
        my $m = MPMinus->m;
        $m->conf_init($r, __PACKAGE__);
        ...
        my $project = $m->conf('project');
        ...
    }

...or:

    use MPMinus::Configuration;

    my $config = new MPMinus::Configuration(
            config  => "foo.conf",
            confdir => "conf",
        );

=head1 DESCRIPTION

The module works with the configuration data of the resource on the platform mod_perl.
The configuration data are relevant at the global level, and they are the same for all
users at once!

=head2 new

    my $config = new MPMinus::Configuration(
            r       => $r,
            config  => "/path/to/config/file.conf", # Or modperlroot relative, e.g, "file.conf"
            confdir => "/path/to/config/directory", # Or modperlroot relative, e.g, "conf"
            options => {... Config::General options ...},
        );

In case of non MPMinus context returns MPMinus::Configuration object

Example foo.conf file:

    Foo     1
    Bar     test
    Flag    true

Example of the "conf" structure of $config object:

    print Dumper($config->{conf});
    $VAR1 = {
        'sid' => 'f4c11c107caa00d0',
        'modperlroot' => '/var/www/foo.localhost',
        'modperl_root' => '/var/www/foo.localhost',
        'hitime' => '1555517289.83407',
        'confdir' => '/var/www/foo.localhost/conf',
        'config' => '/var/www/foo.localhost/foo.conf',
        'foo' => 1
        'bar' => 'test',
        'flag' => 1,
    }

=over 8

=item config

Specifies absolute or relative path to config-file.
If the value is not set then the value gets from dir_config() will be used - "Config"

=item confdir

Specifies absolute or relative path to config-dir.
If the value is not set then the value gets from dir_config() will be used - "ConfDir"

=item options

Options of L<Config::General>

=item r

Optional. Apache2::Request object

=back

=head1 METHODS

=over 8

=item B<config_error>

    my $error = $config->config_error;

Returns error string if occurred any errors while creating the object or reading the configuration file

=item B<conf_init>

    $m->conf_init( $r, $pkg );

NOTE! For MPMinus context only!

=item B<conf, get_conf, config, get_config, val>

In MPMinus context:

    my $value = $m->conf( 'key' );
    my $config_hash = $m->config(); # Returns hash structure

In MPMinus::Configuration context:

    my $value = $config->val( 'key' );
    my $value = $config->conf( 'key' );
    my $config_hash = $config->config(); # Returns hash structure

Gets value from config structure/object by key or config-hash

=item B<set_conf, set_config>

    $m->set_conf( 'key', "value" );
    $config->set_conf( 'key', "value" );

Sets value to config structure/object by key

=back

=head1 HISTORY

=over 8

=item B<1.00 / 27.02.2008>

Init version on base mod_main 1.00.0002

=item B<1.10 / 01.04.2008>

Module is merged into the global module level

=item B<1.20 / 19.04.2010>

Added new type (DSN) support: Oracle

=item B<1.30 / 08.01.2012>

Added server_port variable

=item B<1.31 / Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=item B<1.32 / Wed May  8 12:25:30 2013 MSK>

Added locked_keys parameter

=back

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>, L<CTK>, L<Config::General>, L<Try::Tiny>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<mod_perl2>, L<CTK::Util>, L<Config::General>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = 1.34;

use Apache2::ServerRec ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use APR::Table ();
use APR::Pool ();

use Config::General;
use Try::Tiny;
use File::Spec ();

use Carp;
use CTK::Util qw/ :BASE /;
use MPMinus::Util qw/getHiTime getSID/;

use constant {
    CONF_DIR    => "conf",
    LOG_DIR     => "log",
    LOCKED      => [qw/
            hitime sid
        /],
    VALID_DVARS => { # KEY => "DEFAULT"
        modperlroot => undef,
        config      => undef,
        confdir     => undef,
        debug       => undef,
    },
};

sub new {
    my $class = shift;
    my %args = @_;
    my $r = $args{r} // Apache2::RequestUtil->request;

    # Set %ENV
    # $r->subprocess_env() unless exists($ENV{REQUEST_METHOD});

    # Set DVars
    my %tmp = %{(VALID_DVARS)};
    my %dvars = ();
    while(my ($key, $val) = each %tmp) { $dvars{$key} = $r->dir_config($key) // $val }

    # Debug
    $dvars{"debug"} = ($dvars{"debug"} && $dvars{"debug"} =~ /^(1|on|y|t|enable)/i) ? 1 : 0;

    # Create object
    my $self = bless {
        status  => 0,
        error   => "",
        files   => [],
        conf    => {
            %dvars,
            hitime => getHiTime(),
            sid    => getSID(16, 'm'),
        },
    }, $class;

    # Set paths
    my $root = $dvars{modperlroot} // $r->document_root // '.';
    $self->{conf}->{modperlroot} = $root;
    $self->{conf}->{modperl_root} = $root;
    my $confdir = $args{confdir} || $dvars{confdir} || CONF_DIR;
    $confdir = File::Spec->catdir($root, $confdir) unless File::Spec->file_name_is_absolute($confdir);
    $self->{conf}->{confdir} = $confdir;
    my $fileconf = $args{config} || $dvars{config} || $r->dir_config('FileConf');
    unless ($fileconf) {
        $self->{error} = "Config file not specified";
        return $self;
    }
    $fileconf = File::Spec->catfile($root, $fileconf) unless File::Spec->file_name_is_absolute($fileconf);
    $self->{conf}->{config} = $fileconf;
    unless (-e $fileconf) {
        $self->{error} = sprintf("Config file not found: %s", $fileconf);
        return $self;
    }

    # Loading
    my $tmpopts = $args{options} || {};
    my %options = %$tmpopts;
    $options{"-ConfigFile"}         = $fileconf;
    $options{"-ConfigPath"}         ||= [$root, $confdir, CONF_DIR];
    $options{"-ApacheCompatible"}   = 1 unless exists $options{"-ApacheCompatible"};
    $options{"-LowerCaseNames"}     = 1 unless exists $options{"-LowerCaseNames"};
    $options{"-AutoTrue"}           = 1 unless exists $options{"-AutoTrue"};
    my $cfg;
    try {
        $cfg = new Config::General( %options );
    } catch {
        $self->{error} = $_;
        return $self;
    };
    my %newconfig = $cfg->getall if $cfg && $cfg->can('getall');
    $self->{files} = [$cfg->files] if $cfg && $cfg->can('files');

    # Set only unlocked keys
    my %lkeys = ();
    foreach my $k (keys(%dvars), @{(LOCKED)}) { $lkeys{$k} = 1 }
    foreach my $k (keys(%newconfig)) { $self->{conf}->{$k} = $newconfig{$k} if $k && !$lkeys{$k} }
    $self->{status} = 1;
    $self->{error} = "";

    return $self;
}

sub conf_init {
    my $m = shift;
    croak("The conf_init() method can only be called for the MPMinus object") unless ref($m) =~ /MPMinus/;
    my $r = shift;
    croak("Apache2::RequestRec Object is not defined") unless ref($r) eq 'Apache2::RequestRec';
    my $pkg = shift || ''; # Caller package
    carp("Package name missing!") && return 0 unless $pkg && $pkg =~ /Handlers$/;

    # Set %ENV
    unless ($r->is_perl_option_enabled('SetupEnv')) {
        $r->subprocess_env() unless exists($ENV{REQUEST_METHOD});
    }

    # Set Apache2::RequestRec object as node of MPMinus
    $m->set(r => $r);
    my $s = $r->server;
    my $c = $r->connection;

    # Temp hash
    my %conf;

    ##########################################################################
    ## Session-context variables
    ##########################################################################

    # Package name and iterator
    my $i = $m->conf('package') ? ($m->conf('package')->[1] + 1) : 0;
    $i = 1 if $i > 65534;
    $conf{package} = [$pkg,$i];

    # SID and HITime
    $conf{hitime} = getHiTime();
    $conf{sid}    = getSID(16, 'm'); # Session ID (SID) - For session control

    #
    # NON EDITABLE variables
    #
    my $prj = '';
    if ($pkg =~ /([^\:]+?)\:\:Handlers$/) {
        $prj = $1;
        $conf{project} = $prj;
        $conf{prefix} = lc($prj);
    } else {
        $conf{project} = '';
        $conf{prefix} = '';
    }

    #
    # Apache ENVs
    #
    $conf{request_uri}    = $r->uri() // "";
    $conf{request_method} = $r->method() || "";
    $conf{remote_addr}    = $c->remote_ip || "";
    $conf{remote_user}    = $r->user() // "";
    $conf{server_admin}   = $s->server_admin() || "";
    $conf{server_name}    = $s->server_hostname() // "";
    $conf{server_port}    = $s->port() || $r->subprocess_env('SERVER_PORT') || 80;
    $conf{http_host}      = $r->hostname() // "";
    $conf{https}          = exists($ENV{HTTPS}) && $ENV{HTTPS} ? 1 : 0;
    unless ($conf{https}) {
        my $req_scheme = $r->subprocess_env('REQUEST_SCHEME') || "http";
        $conf{https} = $req_scheme =~ /ps/ ? 1 : 0;
    }
    $conf{document_root}  = $r->document_root // '';
    $conf{modperl_root}   = $r->dir_config('ModperlRoot') // $conf{document_root};

    # List of LOCKED keys
    my @locked_keys = keys %conf;

    # Nothing to do if iterator > 0
    if ($i > 0) {
        my %tconf = %{$m->get('conf')};
        foreach (keys %conf) { $tconf{$_} = $conf{$_} }
        $m->set(conf=>{%tconf});
        return 1
    }

    ##########################################################################
    ## Instance-context variables
    ##########################################################################
    my $modperl_root = $conf{modperl_root};

    # Name of configuration file, e.g., foo.conf
    $conf{fileconf} = $r->dir_config('Config') || $r->dir_config('FileConf') || File::Spec->catfile($modperl_root, $conf{prefix}.".conf");
    $conf{configloadstatus} = 0; # See _loadconfig

    # Absolute paths
    my $logdir = syslogdir();
    unless (-e $logdir) {
        $logdir = File::Spec->catdir($modperl_root, LOG_DIR);
        preparedir($logdir) unless -e $logdir;
    }
    $conf{logdir} = $logdir;
    $conf{confdir} = $r->dir_config('ConfDir') || File::Spec->catdir($modperl_root, CONF_DIR);

    # NON EDITABLE file names

    # URLs
    my $url_mask = "%s://%s";
    my $scheme = ($conf{https} || $conf{server_port} == 443) ? "https" : "http";
    my ($p_host, $p_port) = ($conf{server_name}, $conf{server_port});
    if ($conf{http_host} =~ /^(.+?)\:(\d+)$/) { ($p_host, $p_port) = ($1, $2) }
    elsif ($conf{http_host} =~ /^(.+?)$/) { $p_host = $1 }
    if ($p_port != 80 and $p_port != 443) { # port = ***
        $conf{url} = sprintf($url_mask, $scheme, join(':', $p_host, $p_port));
    } else { # port is std
        $conf{url} = sprintf($url_mask, $scheme, $p_host);
    }

    # Flags (directives with _ as prefix and suffix)
    $conf{"debug"} = $r->dir_config('Debug') // 0;
    $conf{"debug"} = ($conf{"debug"} && $conf{"debug"} =~ /^(1|on|y|t|enable)/i) ? 1 : 0;
    push @locked_keys, qw/debug/; # Block!

    push @locked_keys, grep {/dir|file|log|url/} keys(%conf); # Block!
    push @locked_keys, qw/configloadstatus locked_keys/;
    $conf{locked_keys} = [sort(@locked_keys)];

    # Loading from file and merge with config-data
    _loadconfig(\%conf, @locked_keys);
    $m->set(conf=>{%conf});

    return 1;
}
sub conf {
    my $self = shift;
    my $key  = shift;
    return undef unless $self->{conf};
    return $self->{conf} unless defined $key;
    return $self->{conf}->{$key};
}
sub val {
    my $self = shift;
    my $key  = shift;
    if (ref($self) eq 'MPMinus') {
        carp("This method for calls via MPMinus::Configuration object only");
        return undef;
    }
    return undef unless $self->{conf};
    return undef unless defined $key;
    return $self->{conf}->{$key};
}
sub get_conf { goto &conf };
sub config { goto &conf };
sub get_config { goto &conf };
sub set_conf {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    $self->{conf} = {} unless $self->{conf};
    $self->{conf}->{$key} = $val;
}
sub set_config { goto &set_conf };
sub config_error {
    my $self = shift;
    return $self->{error} // "";
}

sub _loadconfig {
    my $lconf = shift;
    return 0 unless $lconf && ref($lconf) eq 'HASH';
    return 0 unless $lconf->{fileconf} && -e $lconf->{fileconf};
    my %lkeys = ();
    for (@_) { $lkeys{$_} = 1 }

    my $cfg;
    try {
        $cfg = new Config::General(
            -ConfigFile         => $lconf->{fileconf},
            -ConfigPath         => [$lconf->{modperl_root}, $lconf->{confdir}],
            -ApacheCompatible   => 1,
            -LowerCaseNames     => 1,
            -AutoTrue           => 1,
        );
    } catch {
        carp($_);
    };

    my %newconfig = $cfg->getall if $cfg && $cfg->can('getall');
    $lconf->{configfiles} = [];
    $lconf->{configfiles} = [$cfg->files] if $cfg && $cfg->can('files');

    # Set only unlocked keys
    foreach my $k (keys(%newconfig)) { $lconf->{$k} = $newconfig{$k} if $k && !$lkeys{$k} }

    $lconf->{configloadstatus} = 1 if %newconfig;
    return 1;
}

1;
