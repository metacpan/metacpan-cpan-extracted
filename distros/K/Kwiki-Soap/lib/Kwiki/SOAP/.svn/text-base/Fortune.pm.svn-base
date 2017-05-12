package Kwiki::SOAP::Fortune;
use Kwiki::SOAP '-Base';
use mixin 'Kwiki::Installer';

# XXX at least some of this should come from preferences
const wsdl => 'http://www.asleep.net/soap/services.php?wsdl';

our $VERSION = 0.01;

const class_title => 'fortune soap retrieval';
const class_id => 'fortunesoap';
const css_file => 'fortunesoap.css';
const method => 'fortune';

sub register {
    my $registry = shift;
    $registry->add(template => 'fortune_soap.html');
    $registry->add(wafl => fortunesoap => 'Kwiki::SOAP::Fortune::Wafl');
}

sub get_result {
    my $type = shift;
    $self->soap(
        $self->wsdl,
        $self->method,
        [$type]
    );
}

package Kwiki::SOAP::Fortune::Wafl;
use base 'Kwiki::SOAP::Wafl';

sub html {
    my ($type) = split(' ', $self->arguments);
    my $result = $self->hub->fortunesoap->get_result($type);

    $self->hub->template->process('fortune_soap.html',
        fortune => $result,
        soap_class  => $self->hub->fortunesoap->class_id,
    );
}

package Kwiki::SOAP::Fortune;
1;

__DATA__

=head1 NAME 

Kwiki::SOAP::Fortune - Experiment with SOAP request to fortune through wafl.

=head1 SYNOPSIS

  {fortunesoap zippy}

Get a fortune from a SOAP service in a WAFL phrase.

=head1 DESCRIPTION

This is provided as an example service.

See http://www.asleep.net/soap/ for a description of the service 
being accessed.

WAFL is 

  {fortunesoap style}

argument can be one of bofh-excuses, calvin, futurama, hitchhiker,
homer, kernelcookies, simpsons-chalkboard, starwars, zippy

Thanks to asleep.net for the example service.

=head1 AUTHORS

Chris Dent

=head1 SEE ALSO

L<Kwiki>
L<Kwiki::SOAP>
L<Kwiki::SOAP::Google>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__css/fortunesoap.css__
div.fortunesoap { background: #d0d0d0; border thin solid black; padding: 1em;}
__template/tt2/fortune_soap.html__
<!-- BEGIN fortune_soap.html -->
<div class="[% soap_class %]">
[% fortune %]
</div>
<!-- END fortune_soap.html -->
