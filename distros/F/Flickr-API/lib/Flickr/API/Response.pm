package Flickr::API::Response;

use strict;
use warnings;
use HTTP::Response;

use parent qw(HTTP::Response);

our $VERSION = '1.28';

sub new {
    my $class = shift;
    my $self = HTTP::Response->new;
    my $options = shift;
    bless $self, $class;
    return $self;
}

sub init_flickr {
    my ($self, $options) = @_;
    $self->{tree} = undef;
    $self->{hash} = undef;
    $self->{success} = 0;
    $self->{error_code} = 0;
    $self->{error_message} = '';
    return;
}

sub set_fail {
    my ($self, $code, $message) = @_;
    $self->{success} = 0;
    $self->{error_code} = $code;
    $self->{error_message} = $message;
    return;
}

sub set_ok {
    my ($self, $tree, $hashref) = @_;
    $self->{success} = 1;
    $self->{tree} = $tree;
    $self->{hash} = $hashref;
    return;
}

#
# some accessors
#
sub as_tree {
    my ($self) = @_;

    if (defined $self->{tree}) {

        return $self->{tree};
    }
    else {
        return;
    }
}


sub as_hash {
    my ($self) = @_;

    if (defined $self->{hash}) {

        return $self->{hash};
    }
    else {
        return;
    }
}

sub error_code {

    my ($self) = @_;
    return $self->{error_code};

}

sub error_message {

    my ($self) = @_;
    my $text = $self->{error_message};
    $text =~ s/\&quot;/\"/g;
    return $text;

}

sub success {

    my ($self) = @_;
    return $self->{success};

}

sub rc {

    my ($self) = @_;
    return $self->{_rc};

}

sub _propagate_status {

    my $self = shift;
    my $stat = shift;

    $stat->{_rc}           = $self->{_rc};           # http response _rc
    $stat->{success}       = $self->{success};       # set by Flickr::API::Response
    $stat->{error_code}    = $self->{error_code};    # Returned by Flickr or set in API
    $stat->{error_message} = $self->error_message(); # use method since it fixes text

    return;

}

1;

__END__

=head1 NAME

Flickr::API::Response - A response from the flickr API.

=head1 SYNOPSIS

  use Flickr::API;
  use Flickr::API::Response;

  my $api = Flickr::API->new({'key' => 'your_api_key'});

  my $response = $api->execute_method('flickr.test.echo', {
                'foo' => 'bar',
                'baz' => 'quux',
        });

  print "Success: $response->{success}\n";

=head1 DESCRIPTION

This object encapsulates a response from the Flickr API. It's
a subclass of L<HTTP::Response> with the following additional
keys:

  {
    'success' => 1,
    'tree' => XML::Parser::Lite::Tree,
    'hash' => Flickr response as a hash,
    'error_code' => 0,
    'error_message' => '',
  }

The C<_request> key contains the request object that this response
was generated from. This request will be a L<Flickr::API::Request>
object, which is a subclass of L<HTTP:Request>.

The C<sucess> key contains 1 or 0, indicating
whether the request succeeded. If it failed, C<error_code> and
C<error_message> explain what went wrong. If it succeeded, C<tree>
contains an L<XML::Parser::Lite::Tree> object of the response XML.


=head1 METHODS

=over



=item C<as_tree()>

Returns the args passed to flickr with the method that produced this response


=item C<as_hash()>

Returns the args passed to flickr with the method that produced this response

=item C<error_code()>

Returns the Flickr Error Code, if any

=item C<error_message()>

Returns the Flickr Error Message, if any

=item C<success()>

Returns the success or lack thereof from Flickr

=item C<rc()>

Returns the Flickr http status code


=item C<_propagate_status(\%hash)>

Returns the entire response status block as a hashref.


=back

=head1 AUTHOR

Copyright (C) 2004, Cal Henderson, E<lt>cal@iamcal.comE<gt>

Copyright (C) 2015-2016, Louis B. Moore, E<lt>lbmoore@cpan.orgE<gt> 
OAuth and accessor methods.

=head1 SEE ALSO

L<Flickr::API>,
L<XML::Parser::Lite>

=cut

