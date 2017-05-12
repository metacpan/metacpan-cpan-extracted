# $Id: /mirror/gungho/lib/Gungho/Provider/File/Simple.pm 1688 2007-04-17T01:48:44.796031Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider::File::Simple;
use strict;
use warnings;
use base qw(Gungho::Provider);

__PACKAGE__->mk_accessors($_) for qw(read_done requests);

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

sub dispatch
{
    my ($self, $c) = @_;

    if (! $self->read_done) {
        my $filename = $self->config->{filename};
        die "No file specified" unless $filename;
        open(my $fh, $filename) or
            die "Could not open $filename for reading: $!";

        while (<$fh>) {
            chomp;
            s/\s*#.*$//;
            next unless /\S+/;

            my $req = $c->prepare_request(Gungho::Request->new(GET => $_));
            $self->pushback_request($c, $req);
        }
        close($fh);
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

Gungho::Provider::File::Simple - Provide Requests From A Simple File

=head1 SYNOPSIS

  provider:
    module: File::Simple
    config:
      filename: /path/to/filename

  # in file
  http://foo.com
  http://bar.com
  http://baz.com

=head1 DESCRIPTION

This module allows you to put a list of URLs in a plain text file. Gungho
will pick each line up and fetch the URL. You can embed comments via #

=head1 METHODS

=head2 new

Creates a new instance.

=head2 pushback_request

=head2 dispatch

=cut
