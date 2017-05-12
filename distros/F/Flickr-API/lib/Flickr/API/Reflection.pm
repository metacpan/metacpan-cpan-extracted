package Flickr::API::Reflection;

use strict;
use warnings;
use Carp;

use parent qw( Flickr::API );
our $VERSION = '1.28';


sub _initialize {

    my $self = shift;
    $self->_set_status(1,'API::Reflection initialized');
    return;

}


sub methods_list {

    my $self    = shift;
    my $rsp = $self->execute_method('flickr.reflection.getMethods');
    $rsp->_propagate_status($self->{flickr}->{status});
    my $listref = ();

    if ($rsp->success() == 1) {

        $listref = $rsp->as_hash()->{methods}->{method};
        $self->_set_status(1,"flickr.reflection.getMethods returned " . $#{$listref}  . " methods.")

    }
    else {

        $self->_set_status(0,"Flickr::API::Reflection Methods list/hash failed with response error");
        carp "Flickr::API::Reflection Methods list/hash failed with error code: ",$rsp->error_code()," \n ",
            $rsp->error_message(),"\n";

        my $listref = ();
    }

    return $listref;
}




sub methods_hash {

    my $self      = shift;
    my $arrayref  = $self->methods_list();
    my $hashref;


    if ($arrayref) {

        %{$hashref} = map {$_ => 1} @{$arrayref};

    }
    else {

        $hashref = {};

    }
    return $hashref;
}


sub get_method {

    my $self   = shift;
    my $method = shift;
    my $rsp = $self->execute_method('flickr.reflection.getMethodInfo',
                                    {'method_name' => $method});
    my $hash = $rsp->as_hash();
    my $desc = {};

    $rsp->_propagate_status($self->{flickr}->{status});

    my $err;
    my $arg;

    if ($rsp->success() == 1) {

        $self->_set_status(1,"flickr.reflection.getMethodInfo returned was successful");

        $desc->{$method} = $hash->{method};

        foreach $err (@{$hash->{errors}->{error}}) {

            $desc->{$method}->{error}->{$err->{code}}->{message} = $err->{message};
            $desc->{$method}->{error}->{$err->{code}}->{content} = $err->{content};

        }

        if ( ref($hash->{arguments}->{argument}) eq 'ARRAY') {

            foreach $arg (@{$hash->{arguments}->{argument}}) {

                $desc->{$method}->{argument}->{$arg->{name}}->{optional} = $arg->{optional};
                $desc->{$method}->{argument}->{$arg->{name}}->{content}  = $arg->{content};

            }
        }
        else {

            $arg = $hash->{arguments}->{argument};
            $desc->{$method}->{argument}->{$arg->{name}}->{optional} = $arg->{optional};
            $desc->{$method}->{argument}->{$arg->{name}}->{content}  = $arg->{content};

        }
    }
    else {

        $self->_set_status(0,"Flickr::API::Reflection get_method failed with response error");
        carp "Flickr::API::Reflection get method failed with error code: ",$rsp->error_code()," \n ",
            $rsp->error_message(),"\n";

    }

    return $desc;
} # get_method



1;

__END__


=head1 NAME

Flickr::API::Reflection - An interface to the flickr.reflection.* methods.

=head1 SYNOPSIS

  use Flickr::API::Reflection;

  my $api = Flickr::API::Reflection->new({'consumer_key' => 'your_api_key'});

or

  my $api = Flickr::API::Reflection->import_storable_config($config_file);

  my @methods = $api->methods_list();
  my %methods = $api->methods_hash();

  my $method = $api->get_method('flickr.reflection.getMethodInfo');


=head1 DESCRIPTION

This object encapsulates the flickr reflection methods.

C<Flickr::API::Reflection> is a subclass of L<Flickr::API>, so you can access
all of Flickr's reflection goodness while ignoring the nitty-gritty of setting
up the conversation.


=head1 SUBROUTINES/METHODS

=over

=item C<methods_list>

Returns an array of Flickr's API methods.

=item C<methods_hash>

Returns a hash of Flickr's API methods.


=item C<get_method>

Returns a hash reference to a description of the method from Flickr.


=back


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015, Louis B. Moore

This program is released under the Artistic License 2.0 by The Perl Foundation.

=head1 SEE ALSO

L<Flickr::API>.
L<Flickr|http://www.flickr.com/>,
L<http://www.flickr.com/services/api/>
L<https://github.com/iamcal/perl-Flickr-API>


=cut
