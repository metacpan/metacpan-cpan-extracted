# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::FiltertableSupport;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use URI::Escape;

our $VERSION = 0.995;


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
        
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    
    $self->register_prefilter("prefilter");
    return;
}

sub serializedToCGIParam {
    my ($self, $cgi, $query) = @_;

    my @pairs=split("&", $query);
    my %parms;
    
    foreach my $pair (@pairs) {
        my ($name, $val)=split("=", $pair);
        $val =~ s/\+/ /go;
        if(!defined($parms{$name})) {
            my @tmp;
            $parms{$name} = \@tmp;
        }
        $val=uri_unescape($val);
        push @{$parms{$name}}, $val;
    }
    
    foreach my $key (keys %parms) {
        $cgi->param($key, @{$parms{$key}});
    }

    return;
}

sub prefilter {
    my ($self, $cgi) = @_;
    
    my $filterserial = $cgi->param("xx_filter_table_xx") || '';
    if($filterserial ne '') {
        print STDERR "Decoding filter table data\n";
        $self->serializedToCGIParam($cgi, $filterserial);
    }

    return;
    
}

1;
__END__

=head1 NAME

Maplat::Web::FiltertableSupport - alternative way of submitting hidden filterTable rows

=head1 SYNOPSIS

Alternative way of submitting filterTable hidden rows via serialization.

=head1 DESCRIPTION

The dataTable/filterTable jQuery plugin normally submits only visible rows. 

There are multiple ways to force it to submit the hidden rows, too. Currently, this rows are re-added
to the table before submitting the webform.

This module supports an alternative way. Just add a hidden input field called "xx_filter_table_xx" and fill it
with a jQuery serialization of the hidden rows data fields before submit. The FiltertableSupport module then takes
this input field during the prefilter phase, de-serializes it and re-injects all fields into the CGI params hash,
effectivly making the whole process (mostly) transparent to the actual rendering modules.

=head1 Configuration

    <module>
        <modname>filtertablesupport</modname>
        <pm>FiltertableSupport</pm>
        <options>
            <!-- no options required -->
        </options>
    </module>

=head1 A note of caution

This module is highly experimental and did not work on every webform i tested. But in some special cases it might be worth the effort:
Re-injecting a huge number of table rows at once into the DOM might trigger problems in the browser.

=head2 prefilter

Internal function

=head2 serializedToCGIParam

Internal function

=head1 Dependencies

This module does not depend on other webgui modules.

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
