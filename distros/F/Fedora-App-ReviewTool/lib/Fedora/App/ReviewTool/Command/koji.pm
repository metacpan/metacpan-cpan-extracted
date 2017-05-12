#!/usr/bin/perl

package Fedora::App::ReviewTool::Command::koji;

=head1 NAME

Fedora::App::ReviewTool::Command::koji - handle koji builds

=cut

use Moose;

# debugging...
#use Smart::Comments;

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command }; 

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Koji';

has post => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'post results to review bug',
);

has post_on_success => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => 'post results to review bug on successful build',
);

sub run {
    my ($self, $opts, $args) = shift @_;
   
    die 'Not quite ready for prime time yet';

    ### $args
    #$self->koji_run_scratch($args->[0]);
    $self->koji_run_scratch($self->package);

    ### uri: $self->_koji_uri
    ### suc: $self->_koji_success

    if (! $self->_koji_success) {

        die "Koji build failed!\n\n" . join("\n", $self->_koji_output);
    }
}

sub __get_config_from_file {
    my ($class, $file) = @_;

    my $config = Config::Tiny->read($file);

    ### hmm: $config
    return {
        %{ $config->{bugzilla} },
        %{ $config->{branch} },
    };
}

sub _sections { qw{ bugzilla koji } }

1;

