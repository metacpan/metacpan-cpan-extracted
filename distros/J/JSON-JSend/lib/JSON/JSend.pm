package JSON::JSend;

use 5.006;
use strict;
use JSON;
use warnings FATAL => 'all';

=head1 NAME

JSON::JSend - Simple JSON responses (see: labs.omniti.com/labs/jsend)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use JSON::JSend;

    my $jsend = JSON::JSend->new();

    $jsend->success();
    $jsend->success({
        "post" => { 
            id    => 1, 
            title => 'A blog post', 
            body  => 'Some useful content' 
        }});

    $jsend->fail({ title => 'A title is required' });

    $jsend->error( 'Unable to communicate with the database');
    $jsend->error( 'Unable to communicate with the database', 
                   50001,
                   { some_extra_info => 'Extra info goes here' });
    $jsend->error( 'Unable to communicate with the database',
                   { some_extra_info => 'Extra info goes here' });

=head1 SUBROUTINES/METHODS

=head2 new ( [$options] )

    $jsend = JSON::JSend->new();

    $jsend = JSON::JSend->new(
        json_options => { convert_blessed => 1 }
    );

Creates a new JSend object.

The C<$options> argument contains options to customize the object.
C<json_options> are passed to JSON when converting objects to JSON.

=cut

sub new {
    my $class = shift;
    my %args = ref($_[0]) ? %{$_[0]} : @_;
    my $self = { %args };
    bless $self, $class;
    return $self;
}

=head2 success ( [$data] )

    $jsend->success();
    $jsend->success({
        "post" => { 
            id    => 1, 
            title => 'A blog post', 
            body  => 'Some useful content' 
        }});

The above commands return the following JSON objects:

    {
        "status" : "success",
        "data"   : null 
    }

    {
        "status" : "success",
        "data"   : {
            "post" : { 
                "id"    : 1, 
                "title" : "A blog post", 
                "body"  : "Some useful content" 
            }
        }
     }

The status:"success" key-value pair is automatically included in the success response.
=cut

sub success {
    my $self = shift;
    my $data = shift || undef;
    my $result = { status => 'success',
                   data   => $data };
    return to_json($result, $self->{json_options});
}

=head2 fail ( [$data] )

    $jsend->fail();
    $jsend->fail({ title => 'A title is required' });

The above commands return the following JSON objects:

    {
        "status" : "fail",
        "data"   : null 
    }

    {
        "status" : "fail",
        "data"   : { "title" : "A title is required" }
    }

The status:"fail" key-value pair is automatically included in the fail response.
=cut

sub fail {
    my $self = shift;
    my $data = shift || undef;
    my $result = { status => 'fail',
                   data   => $data };
    return to_json($result, $self->{json_options});
}

=head2 error ( $message, [$code|$data], [$code|$data] )

    $jsend->error( 'Unable to communicate with the database');
    $jsend->error( 'Unable to communicate with the database', 
                   50001,
                   { some_extra_info => 'Extra info goes here' });
    $jsend->error( 'Unable to communicate with the database',
                   { some_extra_info => 'Extra info goes here' });

The first parameter, $message, is mandatory. The second and third optional
parameters, if defined, contain either, $code, the numeric error code or
$data, additional data. The $code parameter must be a scalar while the $data
parameter must be a hashref. 

The above commands return the following JSON objects

    {
        "status"    : "error",
        "message"   : "Unable to communicate with the database"
    }

    {
        "status"    : "error",
        "message"   : "Unable to communicate with the database",
        "code"      : 50001,
        "data"      : { "some_extra_info" : "Extra info goes here" }
    }

    {
        "status"    : "error",
        "message"   : "Unable to communicate with the database"
        "data"      : { "some_extra_info" : "Extra info goes here" }
    }

The "status":"error" key-value pair is included automatically in the error
response.
=cut

sub error {
    my $self = shift;
    my $message = shift;
    my $second = shift;
    my $third = shift;
    my ($code, $data);

    foreach my $param (($second, $third)) {
        if (defined($param)) {
            if (ref($param) eq 'HASH') {
                $data = $param;
            } else {
                $code = $param;
            }
        }
    }

    my $result = { status  => "error",
                   message => $message };
    $result->{code} = $code if defined($code);
    $result->{data} = $data if defined($data);
    return to_json($result, $self->{json_options});
}


=head1 AUTHOR

Hoe-Kit Chew, C<< <hoekit at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-json-jsend at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-JSend>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JSON::JSend

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-JSend>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JSON-JSend>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JSON-JSend>

=item * Search CPAN

L<http://search.cpan.org/dist/JSON-JSend/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Hoe-Kit Chew.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of JSON::JSend
