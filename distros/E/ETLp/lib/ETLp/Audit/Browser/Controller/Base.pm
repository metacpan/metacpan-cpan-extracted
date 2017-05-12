package ETLp::Audit::Browser::Controller::Base;
use Moose;
BEGIN { extends qw(CGI::Application Moose::Object); }
    with qw(ETLp::Role::Config  ETLp::Role::Schema  ETLp::Role::Audit);

use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::Config::General;
use CGI::Application::Plugin::ParsePath;
use CGI::Application::Plugin::HTMLPrototype;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Forward;
use URI::Escape;
use UNIVERSAL::require;
use Log::Log4perl qw(get_logger);
use FindBin qw($Bin);
use Data::Dumper;
use ETLp::Config;
use ETLp::Schema;
use DBI;
use DBI::Const::GetInfoType;

sub cgiapp_prerun {
    my $self = shift;
    $self->_create_logger unless $self->logger;
    $self->logger->debug($self->dump);
    $self->logger->debug('DSN: ' . $self->conf->param('dsn'));

    my $config = ETLp::Config->instance;

    unless ($config->schema) {
        my $dbh = DBI->connect(
                        $self->conf->param('dsn'),
                        $self->conf->param('user'),
                        $self->conf->param('password')
                    );
        
        if (lc $dbh->get_info($GetInfoType{SQL_DBMS_NAME}) eq 'oracle') {
            $dbh->{LongReadLen} = 1000000;
            $dbh->{LongTruncOk} = 1;
        }
        
        $config->schema(
            ETLp::Schema->connect(
                sub {$dbh},
                {on_connect_call => 'datetime_setup'}
            )
        );
    }

    unless ($config->dbh) {
        $config->dbh(
            DBI->connect_cached(
                $self->conf->param('dsn'),
                $self->conf->param('user'),
                $self->conf->param('password'),
                {RaiseError => 1, session => 1, AutoCommit => 1}
            )
        );
    }

    my $db_type = lc $self->get_driver;

    $self->session_config(
        CGI_SESSION_OPTIONS =>
          ["driver:$db_type", $self->query, {Handle => $config->dbh}],
        COOKIE_PARAMS => {-path => '/',},
        SEND_COOKIE   => 1,
    );

    $self->error_mode('error');
    my @include_path = @{$self->tt_include_path};
    push @include_path, $self->get_include_dir;
    $self->tt_include_path(["$Bin/../view", "$Bin/../view/includes"]);

    unless ($self->session->param('user_id')
        || $self->get_current_runmode =~ /(?:login|validate_login|error)/)
    {
        my $redir =
            $self->conf->param('root_url')
          . '/user/login?next='
          . uri_escape($ENV{'REQUEST_URI'});
        return $self->redirect($redir);
    }

    unless ($self->check_runmode_permissions) {
        $self->param(
            'message' => "You do not have permission to call this function");
        $self->prerun_mode('error');
    }
}

sub cgiapp_init {
    my $self = shift;
    $self->conf->init(
        -ConfigFile       => $self->param('config_file'),
        -CacheConfigFiles => 1,
    );
}

sub cgiapp_postrun {
    my $self = shift;
    $self->session->flush;
    $self->header_add(-type => 'text/html; charset=utf-8');
}

sub tt_pre_process {
    my ($self, $file, $vars) = @_;
    $vars->{script}   = $ENV{SCRIPT_NAME};
    $vars->{module}   = $self->module;
    $vars->{root_url} = $self->conf->param('root_url');
    $vars->{db_type}  = lc $self->get_driver;

    # If we have a message, send it to the template, and then remove it from the
    # stack
    if ($self->session->param('message')) {
        $vars->{message} = $self->session->param('message');
        $self->session->clear('message');
    }

    my $params = $self->query->Vars;
    delete $params->{rm};
    delete $params->{page};

    # This is to add any filter criteria for the paginators
    $vars->{criteria} = '&' . join('&', map "$_=$params->{$_}", keys %$params)
      if %$params;
}

# Created a log4perl logger. Should only be called if the logger doesn't exist
sub _create_logger {
    my $self = shift;
    my $log_dir = "$Bin/../log";

    my $log_conf = qq(
            log4perl.rootLogger=DEBUG,LOGFILE
        
            log4perl.appender.LOGFILE=Log::Dispatch::FileRotate
            log4perl.appender.LOGFILE.filename = $log_dir/runtime_browser.log
            log4perl.appender.LOGFILE.mode=append
            log4perl.appender.LOGFILE.max      = 5
            log4perl.appender.LOGFILE.size     = 10000000
            log4perl.appender.LOGFILE.TZ       = NZT
        
            log4perl.appender.LOGFILE.layout = PatternLayout
            log4perl.appender.LOGFILE.layout.ConversionPattern = %d %l %p> %m%n
        );

    Log::Log4perl::init(\$log_conf);
    my $logger = Log::Log4perl::get_logger("runtime_browser") || die $!;
    ETLp::Config->logger($logger);
}

# returns the model partner of the current controller
sub model {
    my $self = shift;
    unless ($self->param('model')) {
        my $model_name = (caller(0))[0];
        $model_name =~ s/::Controller::/::Model::/;
        $model_name->require || die $@;
        my $pagesize = $self->conf->param('pagesize');
        $self->logger->debug("Pagesize: $pagesize");
        $self->param('model', $model_name->new({pagesize => $pagesize}));
    }
    return $self->param('model');
}

# Determne the directory where the views should be found
sub get_include_dir {
    my $self = shift;
    my $uplevel = shift || 0;

    # the directory is based on the object's package name
    my $dir = File::Spec->catdir(split(/::/, ref($self)));
    $dir =~ s!\\!\/!g;
    return "$Bin/../lib/MEL/View/$dir";
}

# This gets called in the event of an error when a runmode is executing.
# It will not be called if an error occurs before a runmode is executed or
# after it finishes
sub error {
    my $self = shift;
    my $error = shift || $self->session->param('error');
    $self->session->clear('error');
    $self->logger->error($error);
    return $self->tt_process('error.tmpl', {error => $error});
}

# This is required when sub-classing a non-Moose class like CGI::Application
sub new {
    my $class = shift;
    my $obj   = $class->SUPER::new(@_);

  #  $obj->BUILD;

    return $class->meta->new_object(
        __INSTANCE__ => $obj,
        @_,
    );
}
sub check_runmode_permissions {
    my $self = shift;
    my $req_mode = $self->get_current_runmode() || $self->start_mode();
    $self->logger->debug("Requested runmode: $req_mode");
    my $rm = $self->param('run_modes') || return 1;
    my %rm = %$rm;

    # Exit: we don't want to interfere with errors
    return 1 if ($req_mode eq 'error');

    my @valid_permissions = @{$rm{$req_mode}->{authorization}};

    # if no permissions are defined then continue to runmode
    return 1 unless (@valid_permissions > 0);

    # This is for ETL-Pipeline only
    foreach my $allowed_role (@valid_permissions) {
	return 1
	  if (($allowed_role eq 'admin') && $self->session->param('admin'));
    }

    return 0;
}

sub module {
    die 'Error: cannot call abstract method "module"';
}

#     __PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

