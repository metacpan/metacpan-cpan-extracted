package FSSM::SOAPClient::Config;
use strict;
use warnings;

=head1 NAME

FSSM::SOAPClient::Config - Exports config vars to FSSM::SOAPClient

=head1 SYNOPSIS

Used by L<FSSM::SOAPClient>.

=head1 DESCRIPTION

This module contains configuration information for L<FSSM::SOAPClient>.

=head1 AUTHOR - Mark A. Jensen

 Mark A. Jensen
 Fortinbras Research
 http://fortinbras.us

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<FSSM::SOAPClient>

=cut

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw($SERVICE_URL $WSDL_NS $WSDL_URL %PARAM_VALUES %XPND_TBL);
}

our $SERVICE_URL = 'http://fortinbras.us/cgi-bin/fssm/soap_adaptor.pl';
our $WSDL_NS = 'http://fortinbras.us/soap/fssm/1.0';
our $WSDL_URL = $WSDL_NS.'/fssm.wsdl';
our %PARAM_VALUES = (
    'predictor' => ['subtype B X4/R5',
		    'subtype B SI/NSI',
		    'subtype B X4/R5 (Poveda2009)',
		    'subtype B SI/NSI (Poveda2009)',
		    'subtype C SI/NSI'],
    'expansion' => ['none', 'avg', 'full'],
    'search'    => ['none', 'fast', 'align'],
    'seqtype'   => ['aa', 'nt']
    );

our %XPND_TBL = (
    'none' => '',
    'avg' => 'avg_only_q',
    'full' => 'xseq_all_q'
    );
1;
