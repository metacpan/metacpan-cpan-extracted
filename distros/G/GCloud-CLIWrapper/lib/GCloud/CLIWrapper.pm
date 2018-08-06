package GCloud::CLIWrapper;
  use Moose;
  use JSON::MaybeXS;
  use IPC::Open3;
  use GCloud::CLIWrapper::Result;

  our $VERSION = '0.01';

  has gcloud => (is => 'ro', isa => 'Str', default => 'gcloud');

  has gcloud_options => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub { [ ] });

  sub command_for {
    my ($self, @params) = @_;
    return ($self->gcloud, @{ $self->gcloud_options }, @params);
  }

  sub run {
    my ($self, @command) = @_;
    return $self->input(undef, @command);
  }
 
  sub json {
    my ($self, @command) = @_;
 
    my $result = $self->run(@command);

    my $struct = eval {
      JSON->new->decode($result->output);
    };
    if ($@) {
      return GCloud::CLIWrapper::Result->new(
        rc => $result->rc,
        output => $result->output,
        success => 0
      );
    }
 
    return GCloud::CLIWrapper::Result->new(
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

    die "Unexpected contents in stderr:\n $err" if ($err);
 
    waitpid( $pid, 0 );
    my $rc = $? >> 8;
 
    return GCloud::CLIWrapper::Result->new(
      rc => $rc,
      output => $out,
    );
  }

1;
### main pod documentation begin ###
 
=encoding UTF-8
 
=head1 NAME
 
GCloud::CLIWrapper - Module to use Google Cloud APIs via the gcloud CLI
 
=head1 SYNOPSIS
 
  use GCloud::CLIWrapper;
 
  my $api = GCloud::CLIWrapper->new();
 
  my $result = $api->run('info');
  # $result->success == 1 if the command executed correctly
  # $result->output contains the output of the command
 
  my $result = $api->json('info', '--format', 'json');
  # $result->success == 1 if the command executed correctly
  # $result->output contains the output of the command
  # $result->json is a hashref with the result of the parsed JSON output of the command
 
=head1 DESCRIPTION
 
This module helps you use the GCloud API. It sends all it's commands
via the CLI command line tool C<gcloud>. 
 
=head1 ATTRIBUTES
 
=head2 glcloud
 
By default initialized to C<gcloud>. It will try to find kubectl in the PATH. You can
set it explicitly to a specific gcloud excecutable.
 
=head2 gcloud_options
 
An ArrayRef of options to always add to the command line invocations.
 
  my $api = GCloud::CLIWrapper->new(
    gcloud_options => [ 'info' ],
  );
 
  my $result = $api->run;
  # $result->success == 1 if the command executed correctly
  # $result->output contains the output of the command
 
  my $result = $api->json('--format', 'json');
  # $result->success == 1 if the command executed correctly
  # $result->output contains the output of the command
  # $result->json is a hashref with the result of the parsed JSON output of the command
 
=head1 METHODS
 
=head2 run(@parameters)
 
Will run gcloud with the parameters. Returns a L<GCloud::CLIWrapper::Result> object
with C<output> set to the output of the command, and C<success> a Boolean to indicate
if the command reported successful execution.
 
=head2 json(@parameters)
 
Will run gcloud with the parameters, trying to parse the output as json. Note that you are
responsible for passing the command-line option to output in a json format. Returns a L<Kubectl::CLIWrapper::Result> object
with C<output> set to the output of the command, and C<json> set to a hashref with the parsed
JSON. C<success> will be false if JSON parsing fails.
 
=head1 SEE ALSO
 
L<https://cloud.google.com/sdk/gcloud/>
 
=head1 AUTHOR
 
    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com
 
=head1 BUGS and SOURCE
 
The source code is located here: L<>
 
Please report bugs to: L<>
 
=head1 COPYRIGHT and LICENSE
 
Copyright (c) 2018 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.
 
=cut
