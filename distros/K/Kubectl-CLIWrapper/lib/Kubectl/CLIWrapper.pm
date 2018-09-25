package Kubectl::CLIWrapper {
  use Moose;
  use JSON::MaybeXS;
  use IPC::Open3;
  use Kubectl::CLIWrapper::Result;

  our $VERSION = '0.03';

  has kubeconfig => (is => 'ro', isa => 'Str', predicate => 'has_kubeconfig');
  has kubectl => (is => 'ro', isa => 'Str', default => 'kubectl');
  has namespace => (is => 'ro', isa => 'Str', predicate => 'has_namespace');
  has password => (is => 'ro', isa => 'Str', predicate => 'has_password');
  has server => (is => 'ro', isa => 'Str', predicate => 'has_server');
  has token => (is => 'ro', isa => 'Str', predicate => 'has_token');
  has username => (is => 'ro', isa => 'Str', predicate => 'has_username');

  has insecure_tls => (is => 'ro', isa => 'Bool', default => 0);

  has kube_options => (
        is      => 'ro',
        isa     => 'ArrayRef[Str]',
        lazy    => 1,
        builder => 'build_options',
  );

  sub build_options {
    my $self = shift;
    my %options = ();

    $options{server}     = $self->server     if $self->has_server;
    $options{username}   = $self->username   if $self->has_username;
    $options{password}   = $self->password   if $self->has_password;
    $options{namespace}  = $self->namespace  if $self->has_namespace;
    $options{kubeconfig} = $self->kubeconfig if $self->has_kubeconfig;
    $options{'insecure-skip-tls-verify'} = 'true' if $self->insecure_tls;

    return [ map { "--$_=$options{ $_ }" } keys %options ];
  }

  sub command_for {
    my ($self, @params) = @_;
    return ($self->kubectl, @{ $self->kube_options }, @params);
  }

  sub run {
    my ($self, @command) = @_;
    return $self->input(undef, @command);
  }

  sub json {
    my ($self, @command) = @_;

    push @command, '-o=json';

    my $result = $self->run(@command);
    my $struct = eval {
      JSON->new->decode($result->output);
    };
    if ($@) {
      return Kubectl::CLIWrapper::Result->new(
        rc => $result->rc,
        output => $result->output,
        success => 0
      );
    }

    return Kubectl::CLIWrapper::Result->new(
      rc => $result->rc,
      output => $result->output,
      json => $struct
    );
  }

  sub input {
    my ($self, $input, @params) = @_;

    my @final_command = $self->command_for(@params);

    my ($stdin, $stdout, $stderr);
    my $pid = open3($stdin, $stdout, $stderr, @final_command);
    print $stdin $input  if(defined $input);
    close $stdin;

    my $out = join '', <$stdout>;
    my $err = join '', <$stderr> if ($stderr);

    die "Unexpected contents in stderr $err" if ($err);

    waitpid( $pid, 0 );
    my $rc = $? >> 8;

    return Kubectl::CLIWrapper::Result->new(
      rc => $rc,
      output => $out,
    );
  }

}
1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Kubectl::CLIWrapper - Module to use the Kubernetes API via the kubectl CLI

=head1 SYNOPSIS

  use Kubectl::CLIWrapper;

  my $kube = Kubectl::CLIWrapper->new(
    server => 'https://kubernetes.example.org/',
    username => 'user',
    password => 'pass',
  );

  my $result = $kube->run('explain', 'service');
  # $result->success == 1 if the command executed correctly
  # $result->output contains the output of the command

  my $result = $kube->json('get', 'pods');
  # $result->success == 1 if the command executed correctly
  # $result->output contains the output of the command
  # $result->json is a hashref with the result of the parsed JSON output of the command

  my $result = $kube->input('{"kind":"Service" ... }', 'create', '-f', '-');
  # $result->success == 1 if the command executed correctly
  # $result->output contains the output of the command 

=head1 DESCRIPTION

This module helps you use the Kubernetes API. It sends all it's commands
via the CLI command line tool C<kubectl>. You can find kubectl installation instructions
here L<https://kubernetes.io/docs/tasks/tools/install-kubectl/>.

=head1 CREDENTIALS

Kubectl::CLIWrapper attributes are mainly the options you can pass C<kubectl> to control
how it authenticates to the Kubernetes server. Run C<kubectl options> to discover what these
options do. If you don't initialize any attributes, kubectl will behave just like on the command 
line (loading ~/.kube/config) which may be already set to point to a Kubernetes server

=head1 ATTRIBUTES

=head2 kubectl

By default initialized to C<kubectl>. It will try to find kubectl in the PATH. You can
set it explicitly to specific kubectl excecutable.

=head2 kubeconfig

Path to your kube configuration, defaults to C<$HOME/.kube/config> via kubectl.

=head2 server

The URL of the Kubernetes service

=head2 username

The username for Basic Authentication

=head2 password

The password for Basic Authentication

=head2 token

The Bearer token for authentication

=head2 insecure_tls

A Boolean flag that tells kubectl to not verify the certificate of the server it connects to

=head2 namespace

The Kubernetes namespace to operate in.

=head1 METHODS

=head2 run(@parameters)

Will run kubectl with the parameters. Returns a L<Kubectl::CLIWrapper::Result> object
with C<output> set to the output of the command, and C<success> a Boolean to indicate
if the command reported successful execution.

=head2 json(@parameters)

Will run kubectl with the parameters, and C<'-o=json'>. Returns a L<Kubectl::CLIWrapper::Result> object
with C<output> set to the output of the command, and C<json> set to a hashref with the parsed
JSON. C<success> will be false if JSON parsing fails.

=head2 input($input_to_kubectl, @parameters)

Will run kubectl with the parametes, sending $input_to_kubectl on it's STDIN. 
Returns a L<Kubectl::CLIWrapper::Result> object with C<output> set to the output of the command. 
C<success> will be set accordingly.

=head1 SEE ALSO

L<https://kubernetes.io/docs/tasks/tools/install-kubectl/>

L<IO::K8s>

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/>

L<Net::Kubernetes>

=head1 CONTRIBUTORS

waterkip: adding the possiblity to set a kubeconfig file

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/kubectl-cliwrapper>

Please report bugs to: L<https://github.com/pplu/kubectl-cliwrapper/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
