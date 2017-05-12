package Kwiki::SOAP;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

our $VERSION = 0.05;

const class_title => 'generic soap retrieval';
const class_id => 'soap_access';
const css_file => 'soap.css';

sub register {
    my $registry = shift;
    $registry->add(template => 'base_soap.html');
    $registry->add(wafl => soap => 'Kwiki::SOAP::Wafl');
}

sub soap {
    require SOAP::Lite;
    my $wsdl = shift;
    my $method = shift;
    my $args_list = shift;
    my $soap;
    my $result;

    eval {
        $soap = SOAP::Lite->service($wsdl);
        $result = $soap->$method(@$args_list);
    };
    if ($@) {
        return {error => (split(/\n/,$@))[0]};
    }
    return $result;
}

package Kwiki::SOAP::Wafl;
use base 'Spoon::Formatter::WaflPhrase';

# XXX move most of this up into the top package
# and break it up so tests can access it and 
# some of the soap stuff can be wrapped in evals
# to trap errors (which cause death at the moment)

sub html {
    my ($wsdl, $method, @args) = split(' ', $self->arguments);
    return $self->walf_error
        unless $method;

    my $result = $self->hub->soap_access->soap($wsdl, $method, \@args);

    return $self->pretty($result);
}

sub pretty {
    require YAML;
    my $results = shift;
    $self->hub->template->process('base_soap.html',
        soap_class  => $self->hub->soap_access->class_id,
        soap_output => YAML::Dump($results),
    );
}

package Kwiki::SOAP;
1;

__DATA__

=head1 NAME 

Kwiki::SOAP - Base class for accessing SOAP services from a WAFL phrase

=head1 SYNOPSIS

  {soap <wsdl file> <method> [<arg1> <arg2>]}

=head1 DESCRIPTION

Kwiki::SOAP provides a base class and framework for access SOAP services
from a WAFL phrase. It can be used directly (as shown in the synopsis)
but is designed to be subclassed for special data handling and presentation
management.

You can see Kwiki::SOAP in action at http://www.burningchrome.com/wiki/

This is alpha code that needs some feedback and playing to find its
way in life.

=head1 AUTHORS

Chris Dent <cdent@burningchrome.com>

=head1 SEE ALSO

L<Kwiki>
L<SOAP::Lite>
L<Kwiki::SOAP::Fortune>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__css/dated_announce.css__
div.soap { background: #dddddd; }
__template/tt2/base_soap.html__
<!-- BEGIN base_soap.html -->
<div class="[% soap_class %]">
<pre>
[% soap_output %]
</pre>
</div>
<!-- END base_soap.html -->
