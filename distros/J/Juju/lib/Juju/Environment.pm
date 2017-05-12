package Juju::Environment;
BEGIN {
  $Juju::Environment::AUTHORITY = 'cpan:ADAMJS';
}
$Juju::Environment::VERSION = '2.002';
# ABSTRACT: Exposed juju api environment


use Moose;
use JSON::PP;
use YAML::Tiny qw(Dump);
use Function::Parameters;
use Juju::Util;
use Juju::Error::Environment;
use namespace::autoclean;
with 'Juju::RPC';


has password         => (is => 'ro', isa => 'Str', required => 1);
has is_authenticated => (is => 'rw', isa => 'Int', default  => 0);
has endpoint         => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'wss://localhost:17070',
    required => 1
);
has username => (is => 'ro', isa => 'Str', default => 'user-admin');
has Jobs => (
    is      => 'ro',
    isa     => 'HashRef',
    builder => '_build_Jobs',
    lazy    => 1
);

method _build_Jobs {
    return {
        HostUnits     => 'JobHostUnits',
        ManageEnviron => 'JobManageEnviron',
        ManageState   => 'JobManageSate'
    };
}

has util =>
  (is => 'ro', isa => 'Juju::Util', lazy => 1, builder => '_build_util');

method _build_util { Juju::Util->new };



method _prepare_constraints (HashRef $constraints) {
    foreach my $key (keys %{$constraints}) {
        if ($key =~ /^(cpu-cores|cpu-power|mem|root-disk)/) {
            $constraints->{k} = int($constraints->{k});
        }
    }
    return $constraints;
}


method login {
    my $params = {
        "Type"      => "Admin",
        "Request"   => "Login",
        "RequestId" => $self->request_id,
        "Params"    => {
            "AuthTag"  => $self->username,
            "Password" => $self->password
        }
    };

    # block
    my $res = $self->call($params);
    if (defined($res->{Error})) {
        Juju::Error::Environment->throw(
            error_message => 'Failed to login: ' . $res->{Error},
            method_name   => 'login'
        );
    }
    $self->is_authenticated(1)
      unless !defined($res->{Response}->{EnvironTag});
}



method reconnect {
    $self->close;
    $self->login;
    $self->request_id = 1;
}


method environment_info($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "EnvironmentInfo"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method environment_uuid ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "EnvironmentUUID"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method environment_unset (HashRef $items, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentUnset",
        "Params"  => $items
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method find_tools (Int $major, Int $minor, Str $series, Str $arch, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentUnset",
        "Params"  => {
            MajorVersion => int($major),
            MinorVersion => int($minor),
            Arch         => $arch,
            Series       => $series
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method agent_version ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "AgentVersion"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method abort_current_upgrade ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "AbortCurrentUpgrade"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method status ($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "FullStatus"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method client_api_host_ports ($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "APIHostPorts"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method get_watcher ($cb = undef) {
    my $params = {"Type" => "Client", "Request" => "WatchAll"};

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method get_watched_tasks (Int $watcher_id, $cb = undef) {
    die "Unable to run synchronously, provide a callback" unless $cb;

    my $params =
      {"Type" => "AllWatcher", "Request" => "Next", "Id" => $watcher_id};

    # non-block
    return $self->call($params, $cb);
}



method add_charm (Str $charm_url, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "AddCharm",
        "Params"  => {"URL" => $charm_url}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method get_charm (Str $charm_url, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "CharmInfo",
        "Params"  => {"CharmURL" => $charm_url}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method get_environment_constraints ($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "GetEnvironmentConstraints"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);

}


method set_environment_constraints (HashRef $constraints, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "SetEnvironmentConstraints",
        "Params"  => $constraints
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method environment_get ($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentGet"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method environment_set (HashRef $config, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "EnvironmentSet",
        "Params"  => {"Config" => $config}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method add_machine ($series, HashRef $constraints = +{}, Str $machine_spec = "", Str $parent_id = "", Str $container_type = "", $cb = undef) {
    my $params = {
        "Series"        => $series,
        "Jobs"          => [$self->Jobs->{HostUnits}],
        "ParentId"      => "",
        "ContainerType" => ""
    };

    # validate constraints
    $params->{Constraints} = $self->_prepare_constraints($constraints);

    # if we're here then assume constraints is good and we can check the
    # rest of the arguments
    if (defined($machine_spec)) {
        die "Cant specify machine spec with container_type/parent_id"
          if $parent_id or $container_type;
        ($params->{ParentId}, $params->{ContainerType}) = split /:/,
          $machine_spec;
    }

    return $self->add_machines([$params]) unless $cb;
    return $self->add_machines([$params], $cb);
}


method add_machines (ArrayRef $machines, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "AddMachines",
        "Params"  => {"MachineParams" => $machines}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method destroy_environment ($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "DestroyEnvironment"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);

}


method destroy_machines (ArrayRef $machine_ids, $force = 0, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "DestroyMachines",
        "Params"  => {"MachineNames" => $machine_ids}
    };

    if ($force) {
        $params->{Params}->{Force} = 1;
    }

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);

}



method provisioning_script($cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ProvisioningScript"
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method retry_provisioning (ArrayRef $machines, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "RetryProvisioning",
        "Params"  => @{$machines}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method add_relation (Str $endpoint_a, Str $endpoint_b, $cb = undef) {
    my $params = {
        'Type'    => 'Client',
        'Request' => 'AddRelation',
        'Params'  => {'Endpoints' => [$endpoint_a, $endpoint_b]}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method destroy_relation (Str $endpoint_a, Str $endpoint_b, $cb = undef) {
    my $params = {
        'Type'    => 'Client',
        'Request' => 'DestroyRelation',
        'Params'  => {'Endpoints' => [$endpoint_a, $endpoint_b]}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method deploy (Str $charm, Str $service_name, Int $num_units = 1, Str $config_yaml = "", HashRef $constraints = "", Str $machine_spec = "", $cb = undef) {
    my $params = {
        Type    => "Client",
        Request => "ServiceDeploy",
        Params  => {ServiceName => $service_name}
    };

    # Check for series format
    my (@charm_args) = $charm =~ /(\w+)\/(\w+)/i;
    my $_charm_url = undef;
    if (scalar @charm_args == 2) {
        $_charm_url = $self->util->query_cs($charm_args[1], $charm_args[0]);
    }
    else {
        $_charm_url = $self->util->query_cs($charm);
    }

    $params->{Params}->{CharmUrl}   = $_charm_url->{charm}->{url};
    $params->{Params}->{NumUnits}   = $num_units;
    $params->{Params}->{ConfigYAML} = $config_yaml;
    $params->{Params}->{Constraints} =
      $self->_prepare_constraints($constraints);
    $params->{Params}->{ToMachineSpec} = "$machine_spec";

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method service_set (Str $service_name, HashRef $config = +{}, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceSet",
        "Params"  => {
            "ServiceName" => $service_name,
            "Options"     => $config
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method unset_config (Str $service_name, HashRef $config_keys, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceUnset",
        "Params"  => {
            "ServiceName" => $service_name,
            "Options"     => $config_keys
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method set_charm (Str $service_name, Str $charm_url, Int $force = 0, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceSetCharm",
        "Params"  => {
            "ServiceName" => $service_name,
            "CharmUrl"    => $charm_url,
            "Force"       => $force
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method service_get (Str $service_name, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceGet",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method get_config (Str $service_name, $cb = undef) {
    my $svc = $self->service_get($service_name);
    return $svc->{Config} unless $cb;
    return $cb->($svc->{Config});
}


method get_service_constraints (Str $service_name, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "GetServiceConstraints",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method set_service_constraints (Str $service_name, HashRef $constraints, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "SetServiceConstraints",
        "Params"  => {
            "ServiceName" => $service_name,
            "Constraints" => $self->_prepare_constraints($constraints)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method share_environment (ArrayRef $users, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ShareEnvironment",
        "Params"  => $users
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method unshare_environment (ArrayRef $users, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "UnshareEnvironment",
        "Params"  => $users
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method service_destroy (Str $service_name, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceDestroy",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method service_expose (Str $service_name, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceExpose",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method service_unexpose (Str $service_name, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceUnexpose",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method service_charm_relations (Str $service_name, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceCharmRelations",
        "Params"  => {"ServiceName" => $service_name}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method add_service_units (Str $service_name, Int $num_units = 1, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "AddServiceUnits",
        "Params"  => {
            "ServiceName" => $service_name,
            "NumUnits"    => $num_units
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method add_service_unit (Str $service_name, Str $machine_spec = "", $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "AddServiceUnits",
        "Params"  => {
            "ServiceName" => $service_name,
            "NumUnits"    => 1
        }
    };

    if ($machine_spec) {
        $params->{Params}->{ToMachineSpec} = $machine_spec;
    }

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method destroy_service_units (ArrayRef $unit_names, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "DestroyServiceUnits",
        "Params"  => {"UnitNames" => $unit_names}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method resolved (Str $unit_name, Int $retry = 0, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "Resolved",
        "Params"  => {
            "UnitName" => $unit_name,
            "Retry"    => $retry
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}



method run (Str $command, Int $timeout, ArrayRef $machines = +[], ArrayRef $services = +[], ArrayRef $units = +[], $cb = undef) {
    my $params = {
        Type    => "Client",
        Request => "Run",
        Params  => {
            Commands => $command,
            Timeout  => $timeout,
            Machines => $machines,
            Services => $services,
            Units    => $units
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method run_on_all_machines (Str $command, Int $timeout, $cb = undef) {
    my $params = {
        Type    => "Client",
        Request => "RunOnAllMachines",
        Params  => {
            Commands => $command,
            Timeout  => int($timeout)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method set_annotations (Str $entity, Str $entity_type, Str $annotation, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "SetAnnotations",
        "Params"  => {
            "Tag"   => sprintf("%s-%s", $entity_type, $entity =~ s|/|-|g),
            "Pairs" => $annotation
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method get_annotations (Str $entity, Str $entity_type, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "GetAnnotations",
        "Params"  => {
            "Tag" => "Tag" =>
              sprintf("%s-%s", $entity_type, $entity =~ s|/|-|g)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method private_address (Str $target, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "PrivateAddress",
        "Params"  => {"Target" => $target}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method public_address (Str $target, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "PublicAddress",
        "Params"  => {"Target" => $target}
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}


method service_set_yaml (Str $service, Str $yaml, $cb = undef) {
    my $params = {
        "Type"    => "Client",
        "Request" => "ServiceSetYAML",
        "Params"  => {
            "ServiceName" => $service,
            "Config"      => Dump($yaml)
        }
    };

    # block
    return $self->call($params) unless $cb;

    # non-block
    return $self->call($params, $cb);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Juju::Environment - Exposed juju api environment

=head1 VERSION

version 2.002

=head1 SYNOPSIS

  use Juju;

  my $juju =
    Juju->new(endpoint => 'wss://localhost:17070', password => 's3cr3t');

=head1 ATTRIBUTES

=head2 endpoint

Websocket address

=head2 username

Juju admin user, this is a tag and should not need changing from the
default.

B<Note> This will be changing once multiple user support is released.

=head2 password

Password of juju administrator, found in your environments configuration
under B<password>

=head2 is_authenticated

Stores if user has authenticated with juju api server

=head2 Jobs

Supported juju jobs

=head2 util

L<Juju::Util> wrapper

=head1 METHODS

=head2 _prepare_constraints

Makes sure cpu-cores, cpu-power, mem are integers

B<Params>

=over 4

=item *

C<constraints>

hash of service constraints

=back

=head2 login

Login to juju, will die on a failed login attempt.

=head2 reconnect

Reconnects to API server in case of timeout, this also resets the RequestId.

=head2 environment_info

Return Juju Environment information

=head2 environment_uuid

Environment UUID from client connection

=head2 environment_unset

Unset Environment settings

B<Params>

=over 4

=item *

C<items>

=back

=head2 find_tools

Returns list containing all tools matching specified parameters

B<Params>

=over 4

=item *

C<major_verison>

major version int

=item *

C<minor_verison>

minor version int

=item *

C<series>

Distribution series (eg, trusty)

=item *

C<arch>

architecture

=back

=head2 agent_version

Returns version of api server

=head2 abort_current_upgrade

Aborts and archives the current upgrade synchronization record, if any.

=head2 status

Returns juju environment status

=head2 client_api_host_ports

Returns network hostports for each api server

=head2 get_watcher

Returns watcher

=head2 get_watched_tasks

List of all watches for Id

B<Params>

=over 4

C<watcher_id>

=back

=head2 add_charm

Add charm

B<Params>

=over 4

=item *

C<charm_url>

url of charm

=back

=head2 get_charm

Get charm

B<Params>

=over 4

=item *

C<charm_url>

url of charm

=back

=head2 get_environment_constraints

Get environment constraints

=head2 set_environment_constraints

Set environment constraints

B<Params>

=over 4

=item *

C<constraints>

environment constraints

=back

=head2 environment_get

Returns all environment settings

=head2 environment_set

Sets the given key-value pairs in the environment.

B<Params>

=over 4

=item *

C<config>

Config parameters

=back

=head2 add_machine

Allocate new machine from the iaas provider (i.e. MAAS)

B<Params>

=over 4

=item *

C<series>

OS series (i.e precise)

=item *

C<constraints>

machine constraints

=item *

C<machine_spec>

specific machine

=item *

C<parent_id>

id of parent

=item *

C<container_type>

kvm or lxc container type

=back

=head2 add_machines

Add multiple machines from iaas provider

B<Params>

=over 4

=item *

C<machines>

List of machines

=back

=head2 destroy_environment

Destroys Juju environment

=head2 destroy_machines

Destroy machines

B<Params>

=over 4

=item *

C<machine_ids>

List of machines

=item *

C<force>

Force destroy

=back

=head2 provisioning_script

Returns a shell script that, when run, provisions a machine agent on
the machine executing the script.

=head2 retry_provisioning

Updates the provisioning status of a machine allowing the provisioner
to retry.

B<Params>

=over 4

=item *

C<machines>

Array of machines

=back

=head2 add_relation

Sets a relation between units

B<Params>

=over 4

=item *

C<endpoint_a>

First unit endpoint

=item *

C<endpoint_b>

Second unit endpoint

=back

=head2 destroy_relation

Removes relation between endpoints

B<Params>

=over 4

=item *

C<endpoint_a>

First unit endpoint

=item *

C<endpoint_b>

Second unit endpoint

=back

=head2 deploy

Deploys a charm to service

    $juju->deploy(
        'mysql',
        'mysql',
        1,
        undef,
        undef,
        undef,
        sub {
            my $val = shift;
            print Dumper($val) if defined($val->{Error});
        }
    );

B<Params>

=over 4

=item *

C<charm>

charm to deploy, can be in the format of B<series/charm> if needing to specify a different series

=item *

C<service_name>

name of service to set. same name as charm

=item *

C<num_units>

(optional) number of service units

=item *

C<config_yaml>

(optional) A YAML formatted string of charm options

=item *

C<constraints>

(optional) Machine hardware constraints

=item *

C<machine_spec>

(optional) Machine specification

=back

More information on deploying can be found by running C<juju help deploy>.

=head2 service_set

Set's configuration parameters for unit

B<Params>

=over 4

=item *

C<service_name>

name of service (ie. blog)

=item *

C<config>

hash of config parameters

=back

=head2 service_unset

Unsets configuration value for service to restore charm defaults

B<Params>

=over 4

=item *

C<service_name>

name of service

=item *

C<config_keys>

config items to unset

=back

=head2 service_set_charm

Sets charm url for service

B<Params>

=over 4

=item *

C<service_name>

name of service

=item *

C<charm_url> 

charm location (ie. cs:precise/wordpress)

=item *

C<force>

(optional) for setting charm url, overrides any existing charm url already set.

=back

=head2 service_get

Returns information on charm, config, constraints, service keys.

B<Params>

=over 4

=item *

C<service_name> - name of service

=back

=head2 get_config

Get service configuration

B<Params>

=over 4

=item *

C<service_name>

name of service

=back

=head2 get_service_constraints

Returns the constraints for the given service.

B<Params>

=over 4

=item *

C<service_name>

Name of service

=back

=head2 set_service_constraints

Specifies the constraints for the given service.

B<Params>

=over 4

=item *

C<service_name>

Name of service

=item *

C<constraints>

Service constraints

=back

=head2 share_environment

Allows the given users access to the environment.

B<Params>

=over 4

=item *

C<users>

List of users to allow access

=back

=head2 unshare_environment

Removes the given users access to the environment.

B<Params>

=over 4

=item *

C<users>

List of users to remove access

=back

=head2 service_destroy

Destroys a service

B<Params>

=over 4

=item *

C<service_name>

name of service

=back

=head2 service_expose

Expose service

B<Params>

=over 4

=item *

C<service_name>

Name of service

=back

=head2 service_unexpose

Unexpose service

B<Params>

=over 4

=item *

C<service_name>

Name of service

=back

=head2 service_charm_relations

All possible relation names of a service

B<Params>

=over 4

=item *

C<service_name>

Name of service

=back

=head2 add_service_units

Adds given number of units to a service

B<Params>

=over 4

=item *

C<service_name>

Name of service

=item *

C<num_units>

Number of units to add

=back

=head2 add_service_unit

Add unit to specific machine

B<Params>

=over 4

=item *

C<service_name>

Name of service

=item *

C<machine_spec>

Machine to add unit to

=back

=head2 destroy_service_units

Decreases number of units dedicated to a service

B<Params>

=over 4

=item *

C<unit_names>

List of units to destroy

=back

=head2 resolved

Clear errors on unit

B<Params>

=over 4

=item *

C<unit_name>

id of unit (eg, mysql/0)

=item *

C<retry>

Boolean to force a retry

=back

=head2 run

Run the Commands specified on the machines identified through the ids
provided in the machines, services and units slices.

Required parameters B<Commands>, B<Timeout>, and at B<least one>
C<Machine>, C<Service>, or C<Unit>.

    {
       command => "",
       timeout => TIMEDURATION
       machines => [MACHINE_IDS],
       services => [SERVICES_IDS],
       units => [UNITS_ID]
    }

Requires named parameters

B<Params>

=over 4

=item *

C<command>

command to run

=item *

C<timeout>

timeout

=item *

C<machines>

(optional) List of machine ids

=item *

C<services>

(optional) List of services ids

=item *

C<units>

(optional) List of unit ids

=item *

C<cb>

(optional) callback

=back

=head2 run_on_all_machines

Runs the command on all the machines with the specified timeout.

B<Params>

=over 4

=item *

C<command>

command to run

=item *

C<timeout>

timeout

=back

=head2 set_annotations

Set annotations on entity, valid types are C<service>, C<unit>,
C<machine>, C<environment>

B<Params>

=over 4

=item *

C<entity>

=item *

C<entity_type>

=item *

C<annotation>

=back

=head2 get_annotations

Returns annotations that have been set on the given entity.

B<Params>

=over 4

=item *

C<entity>

=item *

C<entity_type>

=back

=head2 private_address

Get private address of machine or unit

  $self->private_address('1');  # get address of machine 1
  $self->private_address('mysql/0');  # get address of first unit of mysql

B<Params>

=over 4

=item *

C<target>

Target machine

=back

=head2 public_address

Returns the public address of the specified machine or unit. For a
machine, target is an id not a tag.

  $self->public_address('1');  # get address of machine 1
  $self->public_address('mysql/0');  # get address of first unit of mysql

B<Params>

=over 4

=item *

C<target>

Target machine

=back

=head2 service_set_yaml

Sets configuration options on a service given options in YAML format.

B<Params>

=over 4

=item *

C<service>

Service Name

=item *

C<yaml>

YAML formatted string of options

=back

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Adam Stokes.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Juju|Juju>

=back

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
