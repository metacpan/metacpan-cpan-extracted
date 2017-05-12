package ETLp;

use MooseX::Declare;

=head1 NAME

ETLp - A framework for managing and auditing ETL processing

=head1 END-USER DOCUMENTATION

For end-user documentation on how to use ETLp refer to
L<http://trac.assembla.com/etlp/wiki> or:

    perldoc ETLp::Manual::Intro

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

This module manages the processing of ETL tasks as a series of pipelines.
The tasks are defined ina one or more configuration files. ETLp is invoked
by providing the details of the pipeline top be executed.

    use ETLp;

    my $etlp = ETLp->new(
        config_directory => "$ENV{'HOME'}/conf",
        app_config_file  => 'sales',
        section          => 'monthly_sales',
        env_config_file  => 'env',
    );
    
    $etlp->run();
    ...
    
=head1 METHODS

=head2 new

=head3 parameters

    * app_config_file. The name of the application configuration file
    * env_config_file. The name of the environment configuration file
    * config_directrory. Optional. The name of the configuration file
        that contains the configuration files
    * section. The name of the section in the application configuration
        that defined the job being executed
    * localize. Optional. Whether to modify the configuration files to
        use the operating system eol markers. Deafults to 0.

=cut

class ETLp with ETLp::Role::Config {
    use FindBin qw($Bin);
    use Config::General qw(ParseConfig);
    use ETLp::Exception;
    use Try::Tiny;
    use Modern::Perl;
    use ETLp::Config;
    use ETLp::Schema;
    use ETLp::Audit::Job;
    use ETLp::ItemBuilder;
    use ETLp::Execute::Iteration;
    use ETLp::Execute::Serial;
    use Cwd 'abs_path';
    use DBI;
    use Log::Log4perl qw();
    use Data::Dumper;
    use UNIVERSAL::require;
    use File::LocalizeNewlines;
    use DBI::Const::GetInfoType;

    our $VERSION = '0.04';
    
    has 'app_config_file'  => (is => 'ro', isa => 'Str', required => 1);
    has 'env_config_file'  => (is => 'ro', isa => 'Str', required => 1);
    has 'section'          => (is => 'ro', isa => 'Str', required => 1);
    has 'config_directory' => (is => 'ro', isa => 'Str', required => 0);
    has 'localize' => (is => 'ro', isa => 'Bool', required => 0, default => 0);

    has 'registered_plugins' => (
        is       => 'rw',
        isa      => 'HashRef',
        required => 0,
        lazy     => 1,
        default  => sub { {} }
    );

    has 'env_conf' => (
        is       => 'rw',
        isa      => 'HashRef',
        required => 0,
        lazy     => 1,
        default  => sub { {} }
    );
    
    has 'config' => (
        is       => 'rw',
        isa      => 'HashRef',
        required => 0,
        lazy     => 1,
        default  => sub { {} }
    );
    
    has 'app_root' => (
        is => 'rw',
        isa => 'Str',
        required => 0,
        default => abs_path("$Bin/..")
    );
    has 'log_dir' => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
        default  => abs_path("$Bin/../log")
    );
    has 'config_directory' => (
        is       => 'ro',
        isa      => 'Str',
        required => 0,
        default  => abs_path("$Bin/../conf")
    );
    
    # Build the application pipeline
    method _build_pipeline {
        # Only include the environment configuration if allowed to - otherwise
        # we may leak sensitive information to plugin writers
        my $env_conf = ($self->env_conf->{allow_env_vars}) ?
            $self->env_conf :
            {};
        
        my $item_builder = ETLp::ItemBuilder->new(
            plugins        => $self->registered_plugins,
            pipeline_type  => $self->config->{type},
            allow_env_vars => $self->env_conf->{allow_env_vars},
            env_conf       => $env_conf,
            app_root       => $self->app_root,
            config         => $self->config, 
        );
        
        my $pipeline = $item_builder->build_pipeline;
        
        return $pipeline;
    }

    # parse the application configuration file
    method _build_app_config(Str $app_config_file, Str $section) {
        ETLpException->throw(error =>
            "No such application configuration file $app_config_file")
            unless -f $app_config_file;

        if ($self->localize) {
            my $localize      = File::LocalizeNewlines->new;
            my $num_localized = $localize->localize($app_config_file);

            my $label;
        }

        my %config;

        try {
            %config = ParseConfig(-ConfigFile => $app_config_file);
        }
        catch {
            ETLpException->throw(error => "Cannot parse $app_config_file: $_");
        };

        my $job = $config{$section};

        # Make sure that the section exists in the configuration
        ETLpException->throw(error => "No section " . $section .
            " in " . $app_config_file) unless ref($job) eq 'HASH';

        # Each job must have a type
        ETLpException->throw(error => "No type for " . $self->section)
            unless $job->{type};

        # The types must be 'iteration' or 'serial'
        ETLpException->throw(error => "Invalid type " . $job->{type})
            unless (($job->{type} eq 'iterative') || ($job->{type} eq 'serial'));
          
        # Update relative directories if required.
        if (defined $job->{config}) {
            foreach my $dir (qw/incoming_dir fail_dir archive_dir
                               controlfile_dir/) {
                if (defined $job->{config}->{$dir}) {
                    if (substr($job->{config}->{$dir}, 0, 1) ne '/') {
                        $job->{config}->{$dir} = $self->app_root . '/' .
                            $job->{config}->{$dir}
                    }
                }
            }
        }

        # All the items within a phase should be an arrayref of hashrefs. This
        # won't be the case if there is only a single item, so make sure
        # items are within an arrayref
        foreach my $phase (qw/pre_process process post_process/) {
            if (exists $job->{$phase}) {
                if (defined $job->{$phase}->{item}) {
                    if (ref $job->{$phase}->{item} eq 'HASH') {
                        $job->{$phase}->{item} = [$job->{$phase}->{item}];
                    }
                }
            }
        }

        # Store the configuration
        return $job;
    }

    # parse the environment configuration file
    method _parse_env_conf(Str $env_config) {
        my %conf;
          try {
            if ($self->localize) {
                my $localize      = File::LocalizeNewlines->new;
                my $num_localized = $localize->localize($env_config);
            }

            %conf = ParseConfig(-ConfigFile => $env_config,);
        }
        catch {
            ETLpException->throw(error => "Cannot parse $env_config: $_");
        };

        return \%conf;
    }

    # Create a connection to the database
    method _create_dbh {
        my $env = $self->env_conf;
        my $dbh;

        try {
            $dbh =
              DBI->connect($env->{'dsn'}, $env->{user}, $env->{password},
                {RaiseError => 1, AutoCommit => 1, PrintError => 0});
        }
        catch {
            ETLpException->throw(error => "Unable to connect to database: $_");
        };

        return $dbh;
    }

    # Create a Log4perl logger.
    method _create_logger() {
        my $log_dir = $self->log_dir;
        my $name  = $self->app_config_file . '_' . $self->section;
        unless (-d $log_dir) {
            ETLpException->throw(error => "No such log directory $log_dir");
        }

        my $layout_pattern = $self->env_conf->{logger_layout_pattern}
          || '%d %l %p> %m%n';
          my $logger_level = $self->env_conf->{logger_level} || 'DEBUG';
          my $admin_email  = $self->env_conf->{admin_email};
          my $email_sender = $self->env_conf->{email_sender};
          my $environment  = $self->env_conf->{environment}
          || '<unkown environment>';
          my $log_conf;

          $admin_email =~ s/@/\@/ if $admin_email;
        $email_sender =~ s/@/\@/ if $email_sender;

        if ($admin_email && $email_sender) {
            $log_conf = qq{
                log4perl.rootLogger=$logger_level,LOGFILE,Mailer
            };
        } else {
            $log_conf = qq{
                log4perl.rootLogger=$logger_level,LOGFILE
            };
        }

        $log_conf .= qq!
            log4perl.appender.LOGFILE=Log::Dispatch::FileRotate
            log4perl.appender.LOGFILE.filename = $log_dir/${name}.log
            log4perl.appender.LOGFILE.mode=append
            log4perl.appender.LOGFILE.max      = 5
            log4perl.appender.LOGFILE.size     = 10000000
        
            log4perl.appender.LOGFILE.layout = PatternLayout
            log4perl.appender.LOGFILE.layout.ConversionPattern = $layout_pattern
        !;

          if ($admin_email && $email_sender) {
            $log_conf .= qq{
                log4perl.appender.Mailer           = Log::Dispatch::Email::MailSendmail
                log4perl.appender.Mailer.from      = $email_sender
                log4perl.appender.Mailer.to        = $admin_email
                log4perl.appender.Mailer.subject   = [$environment] ETLp Error: $name
                log4perl.appender.Mailer.layout    = SimpleLayout
                log4perl.appender.Mailer.Threshold = WARN
            }
        }

        Log::Log4perl::init(\$log_conf);
        my $logger = Log::Log4perl::get_logger("DW_${name}");

        return $logger;

    }

    # Register plugins for processing items
    method _register_plugins(Str $job_type) {
        my $plugin = 'Module::Pluggable';
        my @plugin_ns;

        # A job must be either serial or iterative (and is validated earlier
        # during the build process)
        if ($job_type eq 'serial') {
            push @plugin_ns, 'ETLp::Plugin::Serial';
            push @plugin_ns, $self->env_conf->{'serial_plugin_ns'}
              if defined $self->env_conf->{'serial_plugin_ns'};
        } else {
            push @plugin_ns, 'ETLp::Plugin::Iterative';
            push @plugin_ns, $self->env_conf->{'iterative_plugin_ns'}
              if defined $self->env_conf->{'iterative_plugin_ns'};
        }

        # import all of the plugins
        my $module = "Module::Pluggable";
        $module->require;
        $module->import(search_path => \@plugin_ns, require => 1);
        
        my %plugin_type;
        
        # register each plugin
        foreach my $plugin ($self->plugins) {
            my $class = $plugin->meta->name;
            my $type;
            
            unless ($plugin->can('type')) {
                ETLpException->throw(error => "plugin  $class has no type");
            }
            $type = $plugin->type;
            
            if (exists $plugin_type{$type}) {
                ETLpException->throw(error =>
                    "cannot add plugin $class because $type ".
                   "is already managed by " . $plugin_type{$type});
            }
            
            $plugin_type{$type} = $class;
        }
        
        return \%plugin_type;
    }

=head2 run

Executes the pipeline

=head3 parameters

    * pipeline - An arrayref of items to be executed

=head3 returns

    * void

=cut

    method run {
        my $runner;
        my $pipeline = $self->{pipeline};
        
        #ETLp::Config->schema->storage->dbh->{AutoCommit} = 1;
        
        my $audit = ETLp::Audit::Job->new(
            name => $self->app_config_file,
            section => $self->section,
            config  => $self->config,
        );
        
        # save the audit object to the coniguration
        ETLp::Config->audit($audit);
        
        my $audit_record = ETLp::Config->schema->resultset('EtlpJob')->find($audit->id);
        
        ETLp::Config->logger->info("Config name: " .$audit_record->section->config->config_name);
        #ETLp::Config->logger->info("AutoCommit: " .ETLp::Config->schema->storage->dbh->{AutoCommit});
        
        if ($self->config->{type} eq 'iterative') {
            $runner = ETLp::Execute::Iteration->new(
                pipeline => $pipeline,
                config   => $self->config,
            );
        } else {
            $runner = ETLp::Execute::Serial->new(
                pipeline => $pipeline,
                config   => $self->config,
            );
        }
        
        ETLp::Config->logger->debug(Dumper $runner);
        
        try {
            $runner->run
        } catch {
            #return 0;
            $_->rethrow if ref $_;
            ETLpException->throw(error => $_);
        };
        
        return 1;
    }
    
    method pipeline {
        return $self->{pipeline};
    }
    
    method BUILD {
        my $app_config_file = $self->app_config_file;
        my $env_config_file = $self->env_config_file;

        $app_config_file .= '.conf' unless $app_config_file =~ /\.conf$/;
        $env_config_file .= '.conf' unless $env_config_file =~ /\.conf$/;

        if ($self->config_directory) {
            $app_config_file = $self->config_directory . '/' . $app_config_file;
            $env_config_file = $self->config_directory . '/' . $env_config_file;
        }

        my $app_config =
          $self->_build_app_config($app_config_file, $self->section);
        #$self->pipeline_type($app_config->{type});

        $self->env_conf($self->_parse_env_conf($env_config_file));
        
        my $logger = $self->_create_logger;
        my $dbh    = $self->_create_dbh;
        my $schema_dbh = $self->_create_dbh;
        
        if ($schema_dbh->get_info($GetInfoType{SQL_DBMS_NAME}) &&
            lc $schema_dbh->get_info($GetInfoType{SQL_DBMS_NAME}) eq 'oracle') {
            $schema_dbh->{LongReadLen} = 1000000;
            $schema_dbh->{LongTruncOk} = 1;
        }
        
        my $schema = ETLp::Schema->connect(sub { $schema_dbh },
                {on_connect_call => 'datetime_setup'});
        
        $logger->info("DBH's AutoCommit: " . $dbh->{AutoCommit});
        $schema->storage->dbh->{AutoCommit} = 1;
        $dbh->{AutoCommit} = 0;

        my $config = ETLp::Config->instance;
        ETLp::Config->dbh($dbh);
        ETLp::Config->logger($logger);
        ETLp::Config->schema($schema);
        $self->config($app_config);

        $self->registered_plugins(
            $self->_register_plugins($app_config->{type}));
        
        $self->{pipeline} = $self->_build_pipeline();
        
        my $checkpoint;
        
    };
}

=head1 AUTHOR

Dan Horne, C<< <dan.horne at redbone.co.nz> >>

=head1 BUGS

Please report any bugs or feature requests through
the web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=ETLp>. 

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ETLp

You can also look for information at:

=over 4

=item Project Home Page

L<http://trac.assembla.com/etlp/wiki/>

=item * ETLp Tickets

Please add bug reports, feature requests

L<https://rt.cpan.org/Public/Dist/Display.html?Name=ETLp>

=item * Browse Source Code

L<http://trac.assembla.com/etlp/browser>

=item * Check out the source

svn checkout http://subversion.assembla.com/svn/etlp/ etlp

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut

1;    # End of ETLp
