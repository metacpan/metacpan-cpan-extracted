package HTTP::Exception::Loader;
$HTTP::Exception::Loader::VERSION = '0.04006';
use strict;
use warnings;

use HTTP::Exception::Base;
use HTTP::Exception::1XX;
use HTTP::Exception::2XX;
use HTTP::Exception::3XX;
use HTTP::Exception::4XX;
use HTTP::Exception::5XX;
use HTTP::Status;

################################################################################
# little bit messy, but solid
# - first create packages for Exception::Class, so it can create them on its own
# - then extend those packages by putting methods into the same namespace
sub _make_exceptions {
    my %tags = @_;
    my (@http_statuses, @exception_classes);
    {
        no strict 'refs';
        @http_statuses = grep { /^HTTP_/ } (keys %{"HTTP::Status::"});
    }

    my $code = '';
    for my $http_status (@http_statuses) {
        my $statuscode              = HTTP::Status->$http_status;
        my $http_status_message     = HTTP::Status::status_message($statuscode);
        my $statuscode_range        = $statuscode;

        # remove HTTP_ for exception classname
        $http_status                =~ s/^HTTP_//;
        # replace the last 2 digits with XX for basename creation
        $statuscode_range           =~ s/\d{2}$/XX/;
        # poor mans escaping, because of HTTP: 418 / I'm a teapot :\
        $http_status_message        =~ s/'/\\'/g;

        # only create requested classes
        next unless (exists $tags{$statuscode_range});

        my $package_name_code       = 'HTTP::Exception::'.$statuscode;
        my $package_name_base       = 'HTTP::Exception::'.$statuscode_range;
        my $package_name_message    = 'HTTP::Exception::'.$http_status;

        # create a Package like HTTP::Exception::404,
        # but also a Package HTTP::Exception::NOT_FOUND,
        # which inherits from HTTP::Exception::404
        # HTTP::Exception::404 inherits from HTTP::Exception::4XX
        push @exception_classes,
            $package_name_code      => {isa => $package_name_base},
            $package_name_message   => {isa => $package_name_code};

        # TODO check whether evaled subs with a ()-prototype are compiled to constants
        $code .= qq~

            package $package_name_code;
            sub code            () { $statuscode }
            sub _status_message () { '$http_status_message' }

            package $package_name_message;
            use Scalar::Util qw(blessed);
            sub caught {
                my \$self = shift;
                my \$e = \$@;
                return \$e if (blessed \$e && \$e->isa('$package_name_code'));
                \$self->SUPER::caught(\@_);
            }

        ~;
    }

    # RT https://rt.cpan.org/Ticket/Display.html?id=79021
    # silence warnings about "subroutine redefined" in a mod_perl environment
    {
        no warnings 'redefine';
        eval $code;
    }
    return @exception_classes;
}

################################################################################
sub import {
    my ($class, @tags) = @_;
    my %tags;

    if (@tags) {
        my %known_tags  = (
            '1XX'           => ['1XX'],
            '2XX'           => ['2XX'],
            '3XX'           => ['3XX'],
            '4XX'           => ['4XX'],
            '5XX'           => ['5XX'],
            'REDIRECTION'   => ['3XX'],
            'CLIENT_ERROR'  => ['4XX'],
            'SERVER_ERROR'  => ['5XX'],
            'ERROR'         => ['4XX', '5XX'],
            'ALL'           => [qw~1XX 2XX 3XX 4XX 5XX~],
        );

        for my $import_tag (@tags) {
            next unless ($known_tags{$import_tag});
            $tags{$_} = undef for (@{ $known_tags{$import_tag} });
        }
    } else {
        @tags{qw~1XX 2XX 3XX 4XX 5XX~} = ();
    }

    require Exception::Class;
    Exception::Class->import(
        'HTTP::Exception' => { isa => 'HTTP::Exception::Base' },
        _make_exceptions(%tags)
    );
}


1;


=head1 NAME

HTTP::Exception::Loader - Creates HTTP::Exception subclasses

=head1 VERSION

version 0.04006

=head1 DESCRIPTION

This Class Creates all L<HTTP::Exception> subclasses.

DON'T USE THIS PACKAGE DIRECTLY. 'use HTTP::Exception' does this for you.
This Package does its job as soon as you call 'use HTTP::Exception'.

Please refer to the Documentation of L<HTTP::Exception/"NAMING SCHEME">.
The Naming Scheme of all subclasses created, as well as the caveats can
be found there.

=head1 AUTHOR

Thomas Mueller, C<< <tmueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-http-exception at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Exception>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Exception::Base

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Exception>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Exception>

=item * Search CPAN

L<https://metacpan.org/release/HTTP-Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Thomas Mueller.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
