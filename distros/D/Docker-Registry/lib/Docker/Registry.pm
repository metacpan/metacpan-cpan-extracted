package Docker::Registry;
  our $VERSION = '0.05';

1;

### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Docker::Registry - A client for talking to Docker Registries

=head1 SYNOPSIS

  # Use AWSs Elastic Container Registry
  use Docker::Registry::ECR;
  my $reg = Docker::Registry::ECR->new(
    region => 'us-west-2',
    account_id => '0123456789',
  );
  my $repo_list = $reg->repositories;

  # Use Google Container Registry (GCR)
  use Docker::Registry::GCE;
  my $reg = Docker::Registry::GCE->new;
  my $repo_list $reg->repositories;

=head1 DESCRIPTION

This module helps you talk to different Docker Registries from different cloud providers.

Docker Registry APIs are standard, but authentication methods differ from vendor to vendor.
This set of modules helps manage that for you.

=head1 WARNING

Consider this code Alpha quality. It works, but only some read-only methods have been implemented, and the API
may still change. Be careful if you start depending on this module.

=head1 METHODS

=head2 repositories

Returns a L<Docker::Registry::Result::Repositories> object with the list of repositories

=head2 repository_tags(name => $repo_name)

Returns a L<Docker::Registry::Result::RepositoryTags> object with the list of tags

=head1 AUTHENITCATION

Each registry class has it's authentication providers. See:

L<Docker::Registry::GCE>

L<Docker::Registry::ECR>

L<Docker::Registry::Gitlab>

for details

=head1 SEE ALSO

L<https://docs.docker.com/registry/spec/api/>

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 Contributors

Wesley Schwengle (waterkip) has implemented the GitLab provider, as well as refactored code

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/kubectl-cliwrapper>

Please report bugs to: L<https://github.com/pplu/kubectl-cliwrapper/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
