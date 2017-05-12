# $Id: /mirror/gungho/lib/Gungho/Provider/YAML.pm 1743 2007-05-28T06:34:14.539886Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider::YAML;
use strict;
use warnings;
use base qw(Gungho::Provider);
use Best [
    [ qw(YAML::Syck YAML) ],
    qw(LoadFile)
];

__PACKAGE__->mk_classdata($_) for qw(read_done requests);

sub new
{
    my $class = shift;
    my $self = $class->next::method(@_);

    $self->has_requests(1);
    $self->read_done(0);
    $self->requests([]);
    $self;
}

sub pushback_request
{
    my ($self, $c, $req) = @_;

    my $list = $self->requests;
    push @$list, $req;
    $self->has_requests(1);
}

sub _load_from_yaml
{
    my ($self, $c) = @_;
    my $filename = $self->config->{filename};
    die "No file specified" unless $filename;

    my $config = eval { LoadFile($filename) };
    if ($@ || !$config) {
        die "Could not read YAML file $filename: $@";
    }
}

sub dispatch
{
    my ($self, $c) = @_;

    if (! $self->read_done) {
        my $config = $self->_load_from_yaml();

        foreach my $conf (@{ $config->{requests} || []}) {
            my $req = Gungho::Request->new(
                $conf->{method} || 'GET',
                $conf->{url}
            );

            my($name, $value);
            while (($name, $value) = keys %{ $conf->{headers} || {} }) {
                $req->push_header($name, $value);
            }

            while (($name, $value) = each %$conf) {
                next if $name =~ /^(?:method|url|headers)$/;
                if (my $code = $req->can($name)) {
                    $code->($req, $value);
                }
            }

            $req = $c->prepare_request($req);
            $self->pushback_request($c, $req);
        }
        $self->read_done(1)
    }

    my $requests = $self->requests;
    $self->requests([]);
    while (@$requests) {
        $self->dispatch_request($c, shift @$requests);
    }

    if (scalar @{ $self->requests } <= 0) {
        $c->is_running(0);
    }
}

1;

__END__

=head1 NAME 

Gungho::Provider::YAML - Specify requests in YAML format

=head1 SYNOPSIS

  # config.yml
  ---
  provider:
    module: YAML
    config: 
      filename: url.yml

  # url.yml
  ---
  requests:
    - method: POST
      url: http://example.com/post/to/me
      headers:
        X-MyHeader: foo
        Host: hoge
      content:
    - url: http://example.com/get/me

=head1 DESCRIPTION

Gungho::Provider::YAML allows you to write down requests in an YAML file

=head1 METHODS

=head2 new

=head2 dispatch

=head2 pushback_request

=cut