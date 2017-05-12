package Jenkins::Notification;
use warnings;
use strict;
use Moose;
use Net::Jenkins::Utils qw(build_job_object build_build_object);
use Net::Jenkins::Job;
use Net::Jenkins::Job::Build;

# job name
has name => ( is => 'rw' , isa => 'Str' );

# job url
has url => ( is => 'rw', isa => 'Str' );

has build => ( is => 'rw' , isa => 'Net::Jenkins::Job::Build' );

has job => ( is => 'rw', isa => 'Net::Jenkins::Job' );

has status => ( is => 'rw' , isa => 'Str' , default => 'UNKNOWN' );

has phase => ( is => 'rw' , isa => 'Str' );

has parameters => ( is => 'rw' );

has api => ( is => 'rw', isa => 'Net::Jenkins' );


# raw json
has raw_json => ( is => 'rw', isa => 'Str' );

sub BUILDARGS {
    my ($self,%args) = @_;

    my $build_args = delete $args{build};
    my $build_url = $build_args->{full_url};

    $args{job} = build_job_object $build_url;
    $args{url} = $args{job}->url;
    $args{build} = build_build_object $build_url;

    $args{status} = $build_args->{status} if $build_args->{status};
    $args{phase} = $build_args->{phase} if $build_args->{phase};
    $args{api} = $args{build}->api;
    return \%args;
}

sub to_hashref {
    my ($self,$with_details) = @_;
    return {
        name => $self->name,
        url => $self->url,
        build => $self->build->to_hashref( $with_details ),
        job => $self->job->to_hashref( $with_details ),
        status => $self->status,
        phase => $self->phase,
        parameters => $self->parameters,
    };
}

1;
__END__

=head1 NAME

Jenkins::Notification

=head1 ATTRIBUTES

=head2 name (Str)

Job name

=head2 url (Str)

Job url

=head2 build

L<Net::Jenkins::Job::Build> object

=head2 job

L<Net::Jenkins::Job> object

=head2 status (Str)

Build Status

=head2 phase (Str)

Build Phase

=head2 parameters (HashRef)

=head2 api

L<Net::Jenkins> object

=cut
