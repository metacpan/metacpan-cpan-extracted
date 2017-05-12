package HTTP::WebTest::Plugin::Sticky;

use warnings;
use strict;

=head1 NAME

HTTP::WebTest::Plugin::Sticky - Propagate hidden and text form fields

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    plugins = ( ::Sticky )

    test_name = Some test
        sticky = yes
        click_button = Next
        params = (
                name => 'This is a new text field'
        )
    end_test

=head1 DESCRIPTION

This plugin for the HTTP::WebTest module let you post a form that
includes all the inputs from the page, including hidden ones. 

Also you can add new inputs using the "params" hash.

In case of inputs of type "checkbox", they are included only if
they have the "checked" property. In other case, you must set it
on purpose using the normal "params" hash.

=head1 TEST PARAMETERS
    
=head2 sticky

Allow/disallows the fields propagation. Values allowed: yes / no.
    
=cut


use HTML::TokeParser;

use base qw(HTTP::WebTest::Plugin);

sub param_types {
    return 'sticky yesno
            params hashlist';
}

sub prepare_request {
    my $self = shift;
    $self->validate_params(qw(sticky params));

    my $request = $self->webtest->current_request;

    my $prev_test_num = $self->webtest->current_test_num - 1;
    return if $prev_test_num < 0;

    my $response = $self->webtest->tests->[$prev_test_num]->response;

    return unless defined $response;

    return unless $response->content_type eq 'text/html';

    my $sticky = $self->test_param('sticky');

    return unless defined($sticky);
    return unless $sticky eq 'yes';

    my $params = $self->test_param('params');

    my $content = $response->content;

    my %inputs = ();
    my $parser = HTML::TokeParser->new(\$content);
    while(my $token = $parser->get_tag('input')) {
        my $type  = $token->[1]{type};
        next unless defined $type;
        my $name  = $token->[1]{name};
        next unless defined $name;
        my $value = $token->[1]{value};
        next unless defined $value;

        next if (lc($type) eq 'checkbox') and  not defined($token->[1]{checked});

        $inputs{$name} = $value;
    }
    if(defined $params) {
        my %params = ref($params) eq "ARRAY" ? @$params : %$params;
        for my $key (keys(%params)) {
            $inputs{$key} = $params{$key};
        }
    }
    my @inputs = %inputs;
    $request->params(\@inputs);
    return [];
}




=head1 AUTHOR

Hugo Salgado H., C<< <huguei at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-http-webtest-plugin-sticky at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-WebTest-Plugin-Sticky>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::WebTest::Plugin::Sticky

You can also look for general information at:

    perldoc HTTP::WebTest

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-WebTest-Plugin-Sticky>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-WebTest-Plugin-Sticky>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-WebTest-Plugin-Sticky>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-WebTest-Plugin-Sticky>

=back

=head1 ACKNOWLEDGEMENTS

The code was based in a lost posting on the webtest mailing list. Thanks
to whoever was responsible for that.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hugo Salgado H., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

=cut

1; # End of HTTP::WebTest::Plugin::Sticky

