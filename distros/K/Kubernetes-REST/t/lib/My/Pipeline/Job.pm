package My::Pipeline::Job;
# A custom resource whose Kind is also called Job, in its own API group -
# nothing to do with batch/v1 Job. Its status is a plain map without the
# succeeded()/active() accessors of a batch/v1 JobStatus. Used by
# t/17_ensure.t (karr k36).

use IO::K8s::APIObject
    api_version     => 'pipeline.example.com/v1',
    resource_plural => 'jobs';

with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;
