package Kubernetes::REST::Example;
# ABSTRACT: Working examples for Kubernetes::REST with Minikube, K3s, and other clusters
our $VERSION = '1.100';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Example - Working examples for Kubernetes::REST with Minikube, K3s, and other clusters

=head1 VERSION

version 1.100

=head1 DESCRIPTION

This document walks you through setting up L<Kubernetes::REST> with a local
Kubernetes cluster and shows how to manage real resources from Perl using
L<IO::K8s> typed objects.

Every code snippet is ready to copy-paste into a script once you have a
running cluster and the Perl dependencies installed. A comprehensive
runnable demo script is included in C<eg/demo.pl>.

=head1 NAME

Kubernetes::REST::Example - Working examples for Kubernetes::REST with Minikube, K3s, and other clusters

=head1 CLUSTER SETUP

L<Kubernetes::REST> works with any Kubernetes cluster. Below are setup
instructions for common local development environments. All of them write
a kubeconfig to C<~/.kube/config> that L<Kubernetes::REST::Kubeconfig> picks
up automatically.

=head2 Minikube

L<Minikube|https://minikube.sigs.k8s.io/> creates a single-node cluster
inside a Docker container or VM.

    # Install (Debian/Ubuntu)
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube

    # Start with Docker driver
    minikube start --driver=docker

    # Verify
    minikube status

Minikube uses self-signed certificates and token authentication. The
kubeconfig context is named C<minikube>.

B<NodePort access:>

    minikube service <service-name> -n <namespace>

=head2 K3s

L<K3s|https://k3s.io/> is a lightweight Kubernetes distribution from Rancher.
It installs as a single binary and runs directly on the host (no Docker
required).

    # Install
    curl -sfL https://get.k3s.io | sh -

    # K3s writes its own kubeconfig to a different path
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Or copy it so Kubernetes::REST::Kubeconfig finds it automatically
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $USER ~/.kube/config
    chmod 600 ~/.kube/config

    # Verify
    kubectl get nodes

B<Key differences from Minikube:>

=over 4

=item * Kubeconfig lives at C</etc/rancher/k3s/k3s.yaml> (not C<~/.kube/config>)

=item * The server endpoint is C<https://127.0.0.1:6443>

=item * K3s includes Traefik as its default ingress controller

=item * K3s uses C<containerd> instead of Docker

=item * NodePort services are accessible directly on the host IP

=back

B<Connecting from Perl with K3s:>

    use Kubernetes::REST::Kubeconfig;

    # If you copied the kubeconfig to ~/.kube/config:
    my $api = Kubernetes::REST::Kubeconfig->new->api;

    # If using the K3s path directly:
    my $api = Kubernetes::REST::Kubeconfig->new(
        kubeconfig_path => '/etc/rancher/k3s/k3s.yaml',
    )->api;

=head2 Kind (Kubernetes in Docker)

L<Kind|https://kind.sigs.k8s.io/> runs Kubernetes nodes as Docker containers.
Good for CI and testing.

    # Install
    go install sigs.k8s.io/kind@latest

    # Create cluster
    kind create cluster --name perl-test

    # Context is named: kind-perl-test
    my $api = Kubernetes::REST::Kubeconfig->new(
        context_name => 'kind-perl-test',
    )->api;

=head2 Any cluster with a kubeconfig

If you have a kubeconfig (EKS, GKE, AKS, self-managed, etc.):

    use Kubernetes::REST::Kubeconfig;

    # Uses current context from ~/.kube/config
    my $api = Kubernetes::REST::Kubeconfig->new->api;

    # Or specify a context
    my $api = Kubernetes::REST::Kubeconfig->new(
        context_name => 'my-production-cluster',
    )->api;

=head1 INSTALL PERL DEPENDENCIES

    cpanm Kubernetes::REST

=head1 CONNECTING TO THE CLUSTER

=head2 Using the kubeconfig (recommended)

L<Kubernetes::REST::Kubeconfig> parses your kubeconfig and sets up
authentication, SSL certificates, and the server endpoint automatically:

    use Kubernetes::REST::Kubeconfig;

    my $kc  = Kubernetes::REST::Kubeconfig->new;
    my $api = $kc->api;

    say "Cluster version: " . $api->cluster_version;

If you have multiple contexts:

    my $contexts = $kc->contexts;
    say "Available: @$contexts";

    my $api = $kc->api('minikube');  # or 'default', 'kind-test', etc.

=head2 Manual configuration

    use Kubernetes::REST;

    my $api = Kubernetes::REST->new(
        server => {
            endpoint          => 'https://127.0.0.1:6443',
            ssl_verify_server => 0,
        },
        credentials => { token => $token },
        resource_map_from_cluster => 0,
    );

=head1 LISTING RESOURCES

=head2 Namespaces

    my $list = $api->list('Namespace');

    for my $ns ($list->items->@*) {
        printf "%-20s %s\n",
            $ns->metadata->name,
            $ns->status->phase // 'Unknown';
    }

=head2 Pods in a namespace

    my $pods = $api->list('Pod', namespace => 'kube-system');

    for my $pod ($pods->items->@*) {
        my $name   = $pod->metadata->name;
        my $phase  = $pod->status->phase // 'Unknown';
        my $ip     = $pod->status->podIP // 'pending';
        printf "%-45s %-10s %s\n", $name, $phase, $ip;
    }

=head2 Services

    my $services = $api->list('Service', namespace => 'default');

    for my $svc ($services->items->@*) {
        my $name  = $svc->metadata->name;
        my $type  = $svc->spec->type // 'ClusterIP';
        my $ports = join ', ', map {
            $_->port . '/' . ($_->protocol // 'TCP')
        } ($svc->spec->ports // [])->@*;
        printf "%-20s %-12s %s\n", $name, $type, $ports;
    }

=head2 Nodes

    my $nodes = $api->list('Node');

    for my $node ($nodes->items->@*) {
        my $info = $node->status->nodeInfo;
        printf "%-20s OS=%-8s kubelet=%s\n",
            $node->metadata->name,
            $info->operatingSystem // '?',
            $info->kubeletVersion // '?';
    }

=head1 GETTING A SINGLE RESOURCE

C<get()> returns a fully typed L<IO::K8s> object:

    my $pod = $api->get('Pod', 'my-pod', namespace => 'default');

    say "Name:      " . $pod->metadata->name;
    say "Namespace: " . $pod->metadata->namespace;
    say "Kind:      " . $pod->kind;          # "Pod"
    say "API:       " . $pod->api_version;   # "v1"
    say "Phase:     " . $pod->status->phase;
    say "Node:      " . ($pod->spec->nodeName // 'unscheduled');

    # Access labels (hashref)
    my $labels = $pod->metadata->labels // {};
    for my $key (sort keys %$labels) {
        say "  $key = $labels->{$key}";
    }

=head1 CREATING RESOURCES

=head2 Namespace

    my $ns = $api->new_object(Namespace =>
        metadata => { name => 'perl-test' },
    );

    my $created = $api->create($ns);
    say "Created: " . $created->metadata->name;

=head2 ConfigMap

    my $cm = $api->create($api->new_object(ConfigMap =>
        metadata => {
            name      => 'app-config',
            namespace => 'perl-test',
        },
        data => {
            'database.host' => 'postgres.perl-test.svc.cluster.local',
            'database.port' => '5432',
            'app.debug'     => 'true',
        },
    ));

=head2 Secret

    use MIME::Base64 qw(encode_base64);

    my $secret = $api->create($api->new_object(Secret =>
        metadata => {
            name      => 'db-credentials',
            namespace => 'perl-test',
        },
        type => 'Opaque',
        data => {
            username => encode_base64('admin', ''),
            password => encode_base64('s3cret', ''),
        },
    ));

=head2 LimitRange

Set default resource limits for all containers in a namespace:

    my $lr = $api->create($api->new_object(LimitRange =>
        metadata => {
            name      => 'default-limits',
            namespace => 'perl-test',
        },
        spec => {
            limits => [{
                type => 'Container',
                default        => { cpu => '200m', memory => '128Mi' },
                defaultRequest => { cpu => '50m',  memory => '64Mi' },
            }],
        },
    ));

=head2 Deployment with volumes, probes, and ServiceAccount

    my $deploy = $api->create($api->new_object(Deployment =>
        metadata => {
            name      => 'my-app',
            namespace => 'perl-test',
        },
        spec => {
            replicas => 2,
            selector => {
                matchLabels => { app => 'my-app' },
            },
            template => {
                metadata => {
                    labels      => { app => 'my-app' },
                    annotations => { 'managed-by' => 'perl' },
                },
                spec => {
                    serviceAccountName => 'default',
                    containers => [{
                        name  => 'nginx',
                        image => 'nginx:1.27-alpine',
                        ports => [{ containerPort => 80, name => 'http' }],
                        env => [{
                            name => 'APP_ENV',
                            valueFrom => {
                                configMapKeyRef => {
                                    name => 'app-config',
                                    key  => 'app.debug',
                                },
                            },
                        }, {
                            name => 'DB_USER',
                            valueFrom => {
                                secretKeyRef => {
                                    name => 'db-credentials',
                                    key  => 'username',
                                },
                            },
                        }],
                        volumeMounts => [{
                            name      => 'config-volume',
                            mountPath => '/etc/nginx/conf.d',
                        }, {
                            name      => 'data-volume',
                            mountPath => '/data',
                        }],
                        resources => {
                            requests => { cpu => '50m',  memory => '32Mi' },
                            limits   => { cpu => '100m', memory => '64Mi' },
                        },
                        livenessProbe => {
                            httpGet => { path => '/', port => 80 },
                            initialDelaySeconds => 5,
                            periodSeconds => 10,
                        },
                        readinessProbe => {
                            httpGet => { path => '/', port => 80 },
                            initialDelaySeconds => 3,
                            periodSeconds => 5,
                        },
                    }],
                    volumes => [{
                        name => 'config-volume',
                        configMap => {
                            name  => 'app-config',
                            items => [{
                                key  => 'nginx.conf',
                                path => 'default.conf',
                            }],
                        },
                    }, {
                        name => 'data-volume',
                        persistentVolumeClaim => {
                            claimName => 'my-storage',
                        },
                    }],
                },
            },
        },
    ));

=head2 Service (NodePort)

    my $svc = $api->create($api->new_object(Service =>
        metadata => {
            name      => 'my-app',
            namespace => 'perl-test',
        },
        spec => {
            type     => 'NodePort',
            selector => { app => 'my-app' },
            ports    => [{
                port       => 80,
                targetPort => 80,
                protocol   => 'TCP',
            }],
        },
    ));

    my $node_port = $svc->spec->ports->[0]->nodePort;
    say "NodePort: $node_port";

    # Minikube: minikube service my-app -n perl-test
    # K3s:      curl http://localhost:$node_port

=head2 Job

    my $job = $api->create($api->new_object(Job =>
        metadata => {
            name      => 'batch-job',
            namespace => 'perl-test',
        },
        spec => {
            backoffLimit => 2,
            template => {
                spec => {
                    restartPolicy => 'Never',
                    containers => [{
                        name    => 'worker',
                        image   => 'busybox:latest',
                        command => ['sh', '-c', 'echo "done"; exit 0'],
                    }],
                },
            },
        },
    ));

=head2 CronJob

    my $cron = $api->create($api->new_object(CronJob =>
        metadata => {
            name      => 'scheduled-job',
            namespace => 'perl-test',
        },
        spec => {
            schedule => '*/5 * * * *',
            jobTemplate => {
                spec => {
                    template => {
                        spec => {
                            restartPolicy => 'OnFailure',
                            containers => [{
                                name    => 'worker',
                                image   => 'busybox:latest',
                                command => ['sh', '-c', 'date'],
                            }],
                        },
                    },
                },
            },
        },
    ));

=head2 RBAC (Role + RoleBinding)

    my $role = $api->create($api->new_object(Role =>
        metadata => {
            name      => 'pod-reader',
            namespace => 'perl-test',
        },
        rules => [{
            apiGroups => [''],
            resources => ['pods'],
            verbs     => ['get', 'list', 'watch'],
        }],
    ));

    my $binding = $api->create($api->new_object(RoleBinding =>
        metadata => {
            name      => 'read-pods',
            namespace => 'perl-test',
        },
        roleRef => {
            apiGroup => 'rbac.authorization.k8s.io',
            kind     => 'Role',
            name     => 'pod-reader',
        },
        subjects => [{
            kind      => 'ServiceAccount',
            name      => 'default',
            namespace => 'perl-test',
        }],
    ));

=head2 PersistentVolumeClaim

Works out of the box on Minikube (hostpath provisioner) and K3s (local-path
provisioner).

    my $pvc = $api->create($api->new_object(PersistentVolumeClaim =>
        metadata => {
            name      => 'my-storage',
            namespace => 'perl-test',
        },
        spec => {
            accessModes => ['ReadWriteOnce'],
            resources => {
                requests => { storage => '100Mi' },
            },
        },
    ));

=head2 ResourceQuota

    my $quota = $api->create($api->new_object(ResourceQuota =>
        metadata => {
            name      => 'ns-quota',
            namespace => 'perl-test',
        },
        spec => {
            hard => {
                pods               => '20',
                'requests.cpu'     => '2',
                'requests.memory'  => '1Gi',
            },
        },
    ));

=head1 UPDATING RESOURCES

Fetch a resource, modify it, send it back:

    # Scale the deployment
    my $deploy = $api->get('Deployment', 'my-app',
        namespace => 'perl-test',
    );
    $deploy->spec->replicas(3);
    my $updated = $api->update($deploy);
    say "Scaled to " . $updated->spec->replicas . " replicas";

    # Rolling update (change image)
    $deploy = $api->get('Deployment', 'my-app', namespace => 'perl-test');
    $deploy->spec->template->spec->containers->[0]->image('nginx:1.27-bookworm');
    my $ann = $deploy->spec->template->metadata->annotations // {};
    $ann->{'kubernetes.io/change-cause'} = 'Image update via Perl';
    $deploy->spec->template->metadata->annotations($ann);
    $api->update($deploy);

    # Add a label
    my $pod = $api->get('Pod', 'my-pod', namespace => 'perl-test');
    my $labels = $pod->metadata->labels // {};
    $labels->{environment} = 'testing';
    $pod->metadata->labels($labels);
    $api->update($pod);

=head1 PATCHING RESOURCES

C<patch()> modifies specific fields without fetching and replacing the
entire object. This avoids conflicts when multiple clients update the
same resource.

=head2 Strategic Merge Patch (default)

The Kubernetes-native patch type. Arrays are merged intelligently
based on the field's merge strategy.

    # Add a label without touching other labels
    my $patched = $api->patch('Pod', 'my-pod',
        namespace => 'perl-test',
        patch     => {
            metadata => { labels => { environment => 'staging' } },
        },
    );

    # Scale a deployment (one field only)
    $api->patch('Deployment', 'my-app',
        namespace => 'perl-test',
        patch     => { spec => { replicas => 5 } },
    );

=head2 JSON Merge Patch

Simple merge where C<null> deletes a key. Arrays are replaced entirely.

    # Remove an annotation
    use JSON::PP ();
    $api->patch('Pod', 'my-pod',
        namespace => 'perl-test',
        type      => 'merge',
        patch     => {
            metadata => { annotations => { 'old-key' => JSON::PP::null } },
        },
    );

=head2 JSON Patch (RFC 6902)

An array of precise operations for surgical edits.

    $api->patch('Deployment', 'my-app',
        namespace => 'perl-test',
        type      => 'json',
        patch     => [
            { op => 'replace', path => '/spec/replicas', value => 3 },
            { op => 'add', path => '/metadata/labels/version', value => '2.0' },
        ],
    );

=head2 Patch vs Update

Use C<patch()> when you only need to change a few fields - it's safer
because it won't overwrite changes made by other clients between your
C<get()> and C<update()>. Use C<update()> when you need to replace the
entire spec.

=head1 WAITING FOR READINESS

Kubernetes operations are asynchronous. Poll the API to wait for a
desired state:

    # Wait for a deployment's pods to be ready
    for my $i (1..60) {
        my $d = $api->get('Deployment', 'my-app', namespace => 'perl-test');
        my $ready   = $d->status->readyReplicas // 0;
        my $desired = $d->spec->replicas // 1;
        if ($ready == $desired) {
            say "All $ready replicas ready!";
            last;
        }
        sleep 1;
    }

    # Wait for a job to complete
    for my $i (1..60) {
        my $j = $api->get('Job', 'batch-job', namespace => 'perl-test');
        if (($j->status->succeeded // 0) >= 1) {
            say "Job completed at " . $j->status->completionTime;
            last;
        }
        sleep 1;
    }

    # Wait for a pod to reach Running phase
    for my $i (1..30) {
        my $p = $api->get('Pod', 'my-pod', namespace => 'perl-test');
        my $phase = $p->status->phase // 'Unknown';
        if ($phase eq 'Running') {
            say "Pod running on " . $p->spec->nodeName;
            last;
        }
        sleep 2;
    }

=head1 INSPECTING POD STATUS

    my $pod = $api->get('Pod', 'my-pod', namespace => 'perl-test');

    say "Phase: " . ($pod->status->phase // 'Unknown');
    say "IP:    " . ($pod->status->podIP // 'pending');
    say "Node:  " . ($pod->spec->nodeName // 'unscheduled');

    # Container-level status
    for my $cs (($pod->status->containerStatuses // [])->@*) {
        say "Container: " . $cs->name;
        say "  Ready:    " . ($cs->ready ? 'yes' : 'no');
        say "  Restarts: " . ($cs->restartCount // 0);
        say "  Image:    " . $cs->image;
    }

=head1 ERROR HANDLING

C<create()> croaks if the resource already exists. Use C<eval> to handle
this gracefully:

    my $ns = eval {
        $api->create($api->new_object(Namespace =>
            metadata => { name => 'perl-test' },
        ));
    };
    if ($@) {
        say "Already exists, fetching instead";
        $ns = $api->get('Namespace', 'perl-test');
    }

=head1 SERIALIZATION

Every L<IO::K8s> object can be serialized to JSON or YAML:

    my $pod = $api->get('Pod', 'my-pod', namespace => 'perl-test');

    # To JSON
    my $json = JSON::MaybeXS->new(
        canonical => 1, pretty => 1, utf8 => 1,
    )->encode($pod->TO_JSON);

    # To YAML (suitable for kubectl apply -f)
    say $pod->to_yaml;

    # Save to file
    $pod->save('/tmp/my-pod.yaml');

    # Round-trip: hashref -> object
    my $pod2 = $api->inflate($pod->TO_JSON);
    say $pod2->metadata->name;

=head1 WATCHING FOR CHANGES

The Watch API streams events as resources are added, modified, or deleted.
This is the foundation for building Kubernetes controllers.

=head2 Basic watch

    $api->watch('Pod',
        namespace => 'default',
        timeout   => 60,
        on_event  => sub {
            my ($event) = @_;
            printf "%-10s %s\n",
                $event->type,
                $event->object->metadata->name;
        },
    );

=head2 Resumable watch loop

    # Watch indefinitely, surviving timeouts and disconnects
    my $rv;
    while (1) {
        $rv = eval {
            $api->watch('Pod',
                namespace       => 'default',
                resourceVersion => $rv,
                on_event        => sub {
                    my ($event) = @_;
                    say $event->type . ": " . $event->object->metadata->name;
                },
            );
        };
        if ($@ && $@ =~ /410 Gone/) {
            # resourceVersion too old, re-list to get fresh state
            warn "Watch expired, re-listing...\n";
            $api->list('Pod', namespace => 'default');
            $rv = undef;
        } elsif ($@) {
            warn "Watch error: $@\n";
            sleep 5;
        }
        # Normal timeout, just restart the watch
    }

=head2 Watch with selectors

    $api->watch('Pod',
        namespace     => 'default',
        labelSelector => 'app=web',
        fieldSelector => 'status.phase=Running',
        on_event      => sub {
            my ($event) = @_;
            say $event->type . ": " . $event->object->metadata->name;
        },
    );

=head2 Watch any resource type

    # Watch deployments
    $api->watch('Deployment',
        namespace => 'default',
        on_event  => sub {
            my ($event) = @_;
            my $deploy = $event->object;
            printf "%s %s: %d/%d ready\n",
                $event->type,
                $deploy->metadata->name,
                $deploy->status->readyReplicas // 0,
                $deploy->spec->replicas // 0;
        },
    );

    # Watch namespaces (cluster-scoped)
    $api->watch('Namespace',
        on_event => sub {
            my ($event) = @_;
            say $event->type . ": " . $event->object->metadata->name;
        },
    );

=head1 DELETING RESOURCES

    # Delete by object
    $api->delete($pod);

    # Delete by name
    $api->delete('Pod',        'my-pod',    namespace => 'perl-test');
    $api->delete('Deployment', 'my-app',    namespace => 'perl-test');
    $api->delete('Namespace',  'perl-test');

When cleaning up a full namespace, delete dependent resources first to
avoid errors (e.g. delete Pods and Deployments before the ServiceAccount
they reference):

    for my $r (
        ['CronJob',              'scheduled-job'],
        ['Job',                  'batch-job'],
        ['Service',              'my-app'],
        ['Deployment',           'my-app'],
        ['RoleBinding',          'read-pods'],
        ['Role',                 'pod-reader'],
        ['PersistentVolumeClaim','my-storage'],
        ['Secret',               'db-credentials'],
        ['ConfigMap',            'app-config'],
        ['ResourceQuota',        'ns-quota'],
        ['LimitRange',           'default-limits'],
    ) {
        my ($kind, $name) = @$r;
        eval { $api->delete($kind, $name, namespace => 'perl-test') };
    }
    eval { $api->delete('Namespace', 'perl-test') };

=head1 RESOURCE QUOTA INSPECTION

    my $q = $api->get('ResourceQuota', 'ns-quota',
        namespace => 'perl-test',
    );
    my $used = $q->status->used // {};
    my $hard = $q->status->hard // {};
    for my $key (sort keys %$hard) {
        printf "%-25s %s / %s\n", $key,
            $used->{$key} // '0', $hard->{$key};
    }

=head1 CUSTOM RESOURCE DEFINITIONS (CRDs)

L<Kubernetes::REST> can manage Custom Resources the same way it manages
built-in ones. You define a Perl class for your CRD, register it in
the resource map, and use the standard CRUD API.

=head2 Defining the CRD in Kubernetes

First, apply a CRD to your cluster. Example - a C<StaticWebSite> resource
for hosting static websites in your homelab:

    # staticwebsite-crd.yaml
    apiVersion: apiextensions.k8s.io/v1
    kind: CustomResourceDefinition
    metadata:
      name: staticwebsites.homelab.example.com
    spec:
      group: homelab.example.com
      versions:
        - name: v1
          served: true
          storage: true
          schema:
            openAPIV3Schema:
              type: object
              properties:
                spec:
                  type: object
                  required: [domain, image]
                  properties:
                    domain:   { type: string }
                    image:    { type: string }
                    replicas: { type: integer, default: 1 }
                    tls:      { type: boolean, default: false }
                status:
                  type: object
                  properties:
                    readyReplicas: { type: integer }
                    url:           { type: string }
      scope: Namespaced
      names:
        plural: staticwebsites
        singular: staticwebsite
        kind: StaticWebSite
        shortNames: [sw]

    $ kubectl apply -f staticwebsite-crd.yaml

=head2 Writing a CRD class

Create a Perl class using C<IO::K8s::APIObject> with import parameters
for C<api_version> and C<resource_plural>:

    package My::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites';
    with 'IO::K8s::Role::Namespaced';

    k8s spec   => { Str => 1 };
    k8s status => { Str => 1 };
    1;

Key points:

=over 4

=item * C<api_version> - the CRD's C<group/version> (e.g. C<homelab.example.com/v1>)

=item * C<resource_plural> - must match the CRD's C<spec.names.plural>

=item * C<kind> is derived automatically from the class name (last C<::> segment)

=item * Apply C<IO::K8s::Role::Namespaced> for namespace-scoped CRDs

=item * C<spec> and C<status> are opaque hashrefs (C<< { Str => 1 } >>)

=back

=head2 Registering the CRD class

Register your class with the C<+> prefix in the resource map:

    my $api = Kubernetes::REST::Kubeconfig->new->api;
    $api->resource_map->{StaticWebSite} = '+My::StaticWebSite';

Or pass it at construction time:

    my $api = Kubernetes::REST->new(
        server      => { endpoint => '...' },
        credentials => { token => '...' },
        resource_map => {
            %{ IO::K8s->default_resource_map },
            StaticWebSite => '+My::StaticWebSite',
        },
    );

=head2 CRUD on Custom Resources

Once registered, CRDs work exactly like built-in resources:

    use JSON::PP ();

    # Create
    my $site = $api->create($api->new_object(StaticWebSite =>
        metadata => {
            name      => 'my-blog',
            namespace => 'default',
        },
        spec => {
            domain   => 'blog.example.com',
            image    => 'nginx:1.27-alpine',
            replicas => 2,
            tls      => JSON::PP::true,
        },
    ));

    # Get
    my $site = $api->get('StaticWebSite', 'my-blog', namespace => 'default');
    say $site->spec->{domain};    # blog.example.com

    # List
    my $list = $api->list('StaticWebSite', namespace => 'default');
    for my $s ($list->items->@*) {
        say $s->metadata->name . ": " . $s->spec->{domain};
    }

    # Update
    $site->spec->{replicas} = 3;
    $api->update($site);

    # Delete
    $api->delete('StaticWebSite', 'my-blog', namespace => 'default');

B<Note:> For boolean CRD fields, use C<JSON::PP::true> and C<JSON::PP::false>
instead of C<1> and C<0>. The Kubernetes API validates JSON types strictly
for custom resources.

=head2 Serialization

CRD objects support the same serialization as built-in resources:

    say $site->to_yaml;
    # ---
    # apiVersion: homelab.example.com/v1
    # kind: StaticWebSite
    # metadata:
    #   name: my-blog
    #   namespace: default
    # spec:
    #   domain: blog.example.com
    #   ...

    $site->save('/tmp/my-blog.yaml');

=head2 AutoGen (dynamic class generation)

If you don't want to write Perl classes by hand, you can generate them
dynamically using L<IO::K8s::AutoGen>:

    use IO::K8s::AutoGen;

    my $class = IO::K8s::AutoGen::get_or_generate(
        'com.example.homelab.v1.StaticWebSite',  # definition name
        $schema,                                   # OpenAPI schema
        {},                                        # all definitions
        'MyApp::K8s',                              # namespace
        api_version     => 'homelab.example.com/v1',
        kind            => 'StaticWebSite',
        resource_plural => 'staticwebsites',
        is_namespaced   => 1,
    );

    $api->resource_map->{StaticWebSite} = "+$class";

    # Now use it like any other resource
    my $site = $api->k8s->struct_to_object($class, {
        metadata => { name => 'my-blog', namespace => 'default' },
        spec     => { domain => 'blog.example.com', image => 'nginx' },
    });
    $api->create($site);

=head2 More CRD ideas

Custom resources can simplify complex Kubernetes patterns for your homelab:

=over 4

=item * B<BackupSchedule> - wraps CronJob for scheduled backups with retention policies

=item * B<DatabaseCluster> - wraps StatefulSet + PVC + Service for database instances

=item * B<HomeService> - simplified Deployment + Service + optional Ingress

=item * B<DNSRecord> - manages external DNS entries alongside cluster resources

=back

=head1 IO::K8s CLASS REFERENCE

The objects returned by L<Kubernetes::REST> are all L<IO::K8s> classes.
Here are the most commonly used ones:

=over 4

=item L<IO::K8s::Api::Core::V1::Pod> - Pods

=item L<IO::K8s::Api::Core::V1::Service> - Services

=item L<IO::K8s::Api::Core::V1::ConfigMap> - ConfigMaps

=item L<IO::K8s::Api::Core::V1::Secret> - Secrets

=item L<IO::K8s::Api::Core::V1::Namespace> - Namespaces

=item L<IO::K8s::Api::Core::V1::PersistentVolumeClaim> - PersistentVolumeClaims

=item L<IO::K8s::Api::Core::V1::ResourceQuota> - ResourceQuotas

=item L<IO::K8s::Api::Core::V1::LimitRange> - LimitRanges

=item L<IO::K8s::Api::Core::V1::ServiceAccount> - ServiceAccounts

=item L<IO::K8s::Api::Apps::V1::Deployment> - Deployments

=item L<IO::K8s::Api::Batch::V1::Job> - Jobs

=item L<IO::K8s::Api::Batch::V1::CronJob> - CronJobs

=item L<IO::K8s::Api::Rbac::V1::Role> - Roles

=item L<IO::K8s::Api::Rbac::V1::RoleBinding> - RoleBindings

=item L<IO::K8s::Api::Networking::V1::Ingress> - Ingress

=item L<IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta> - object metadata

=back

All classes share these patterns:

    $obj->metadata->name;          # resource name
    $obj->metadata->namespace;     # namespace (if namespaced)
    $obj->metadata->labels;        # hashref of labels
    $obj->metadata->uid;           # unique ID assigned by Kubernetes
    $obj->kind;                    # "Pod", "Service", etc.
    $obj->api_version;             # "v1", "apps/v1", etc.
    $obj->TO_JSON;                 # serialize to hashref
    $obj->to_yaml;                 # serialize to YAML string

See L<IO::K8s> for full documentation on the object system, including
type safety, YAML loading, and custom resource support.

=head1 DEMO SCRIPT

This distribution ships with a comprehensive runnable demo at
C<eg/demo.pl>. It exercises every feature documented above in
20 steps against a live cluster:

    perl eg/demo.pl

The script connects via kubeconfig, creates a dedicated namespace, then
walks through: LimitRange, ResourceQuota, ConfigMap, Secret, ServiceAccount,
Role + RoleBinding, PersistentVolumeClaim, Deployment (2 replicas with
volumes, probes, ConfigMap/Secret env vars), Service (NodePort), pod
inspection, scaling to 3 replicas, rolling image update, Job (run to
completion), CronJob, utility Pod (with volume mounts and env vars from
ConfigMap and Secret), full namespace inventory, YAML/JSON serialization
with round-trip inflate, quota usage inspection, and ordered cleanup.

It works on Minikube, K3s, Kind, or any cluster with a kubeconfig.

=head1 SEE ALSO

L<Kubernetes::REST>, L<Kubernetes::REST::Kubeconfig>, L<IO::K8s>,
L<https://minikube.sigs.k8s.io/>, L<https://k3s.io/>,
L<https://kind.sigs.k8s.io/>, L<https://kubernetes.io/docs/>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org> (JLMARTIN, original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
