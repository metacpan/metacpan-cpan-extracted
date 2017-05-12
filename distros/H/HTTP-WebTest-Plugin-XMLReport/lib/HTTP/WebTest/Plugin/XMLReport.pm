package HTTP::WebTest::Plugin::XMLReport;

use strict;
use base qw(HTTP::WebTest::ReportPlugin);
use XML::Writer;
use POSIX qw(strftime);
use vars qw($VERSION);
$VERSION = '1.01';

=head1 NAME

HTTP::WebTest::Plugin::XMLReport - Report plugin for HTTP::WebTest, generates output in XML format

=head2 VERSION

 version 1.00 - $Revision: 1.4 $

Compatible with L<HTTP::WebTest|HTTP::WebTest> version 2.x API

=head1 SYNOPSIS

See L<HTTP::WebTest|HTTP::WebTest>, the section about plugins.

=head1 DESCRIPTION

Generate a WebTest report in XML format.
The document element is the 'testresults' element.
For each test definition, a 'group' element is included,
containig individual test results as children of 'test'
elements.

Example:

 <?xml version="1.0" encoding="UTF-8"?>
 <testresults date="Mon Sep 16 17:00:03 2002">
   <group name="Homepage" url="http://www.mysite.com">
     <test name="Status code check">
       <result status="PASS">200 OK</result>
     </test>
     <test name="Forbidden text">
       <result status="PASS">Premature end of script headers</result>
     </test>
     <test name="Required text">
       <result status="PASS">Please login:</result>
       <result status="PASS">&lt;/html&gt;</result>
     </test>
     <test name="Content size check">
       <result status="PASS">Number of returned bytes ( 30381 ) is &gt; or = 10000 ?</result>
       <result status="PASS">Number of returned bytes ( 30381 ) is &lt; or = 99000 ?</result>
     </test>
     <test name="Response time check">
       <result status="PASS">Response time (  9.14 ) is &gt; or =  0.01 ?</result>
       <result status="FAIL">Response time (  9.14 ) is &lt; or =  8.00 ?</result>
     </test>
   </group>
   [...]
 </testresults>


=head1 GLOBAL PARAMETERS

=head2 xml_report_dtd

This global parameter specifies whether the testresults document
includes the DTD.

For production work this will normally not be advised, but
it can be helpful when validating the report during development,
with a command like:

  xmllint --valid saved_xml_report.xml

(xmllint is a utility program that comes bundled with the Gnome
XML libraries, aka LibXML).

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 default_report

You may want to suppress the default report.
From C<wtscript>:

  default_report no

Or as optional global parameter from Perl:

  $wt = new HTTP::WebTest($defs, { default_report => 'no' });

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<yes>


=head1 TEST PARAMETERS

Note: these are set from the test definitions, see L<HTTP::WebTest|HTTP::WebTest>
for details.

=head2 test_name

The C<test_name> attribute from C<wtscript> will be used for the
C<name> attribute of the C<group> element in the XML output document.

This attribute is the easiest way to identify each test group, so
it is adviced that you define one unique name per group in the
test definitions.

=head1 REPORT DTD

The full Document Type Definition for the output XML:

 <?xml version="1.0" ?>
 <!ELEMENT testresults (group+)>
 <!ATTLIST testresults
   date    CDATA    #REQUIRED >
 
 <!ELEMENT group (test+)>
 <!ATTLIST group
   name    CDATA    #REQUIRED
   url     CDATA    #REQUIRED >
 
 <!ELEMENT test (result+)>
 <!ATTLIST test
   name    CDATA    #REQUIRED >
 
 <!ELEMENT result (#PCDATA)>
 <!ATTLIST result
   status  (PASS | FAIL)  #REQUIRED >

=cut

sub param_types {
    return shift->SUPER::param_types . "\n" .
	   q(default_report yesno
             xml_report_dtd yesno
             test_name      scalar
            );
}

sub _init_xml_writer {
    my $self = shift;

    $self->global_validate_params(qw(fh_out xml_report_dtd output_ref));
    my $fh_out = $self->global_test_param('fh_out');
    if ($self->global_test_param('output_ref')) {
      eval { local $SIG{'__DIE__'}; require IO::Scalar; };
      warn $@ if $@;
      $fh_out = new IO::Scalar($self->global_test_param('output_ref'));
    }
    my $text = join '', @_;

    ${$self->test_output} .= $text;
    my $dtd = $self->global_test_param('xml_report_dtd');
    if ($dtd && ($dtd eq 'yes')) {
      $dtd = sprintf("<!DOCTYPE testresults [\n%s]>\n", &_DTD());
    } else {
      $dtd = undef;
    }

    if (defined $fh_out) {
        $self->{x_out} = new XML::Writer(OUTPUT => $fh_out, DATA_INDENT => 2);
    } else {
        $self->{x_out} = new XML::Writer(DATA_INDENT => 2);
    }
    $self->{x_out}->xmlDecl();
    $self->{x_out}->getOutput()->print($dtd) if $dtd;
}

sub start_tests {
    my $self = shift;

    $self->_init_xml_writer;
    # use RFC822-conformant date string including Time Zone
    $self->{x_out}->startTag('testresults',
             'date' => strftime("%a, %d %b %Y %H:%M:%S %z", localtime()));
    $self->{x_out}->characters("\n");
    $self->SUPER::start_tests;
}

sub report_test {
    my $self = shift;

    $self->validate_params(qw(test_name));

    # get test params we handle
    my $test_name = $self->test_param('test_name', 'untitled');
    my $url       = '';
    if($self->webtest->current_request) {
	$url = $self->webtest->current_request->uri;
    }

    # test header
    $self->{x_out}->startTag('group', 'name' => $test_name, 'url' => $url);
    $self->{x_out}->characters("\n");
    my $out = '';

    for my $result (@{$self->webtest->current_results}) {
	# test results
	my $group_comment = $$result[0] || '';
	my @results       = @$result[1 .. @$result - 1];

	next unless @results;
        $self->{x_out}->startTag('test', 'name' => $group_comment);
        $self->{x_out}->characters("\n");

	for my $subresult (@$result[1 .. @$result - 1]) {
	    my $comment = $subresult->comment || '';
	    my $ok      = $subresult->ok ? 'PASS' : 'FAIL';

            $self->{x_out}->dataElement('result', $comment, 'status' => $ok);
            $self->{x_out}->characters("\n");
	}
        $self->{x_out}->endTag('test');
        $self->{x_out}->characters("\n");
    }
    $self->{x_out}->endTag('group');
    $self->{x_out}->characters("\n");
}

sub end_tests {
    my $self = shift;

    $self->SUPER::end_tests;
    $self->_cleanup();
}

sub _cleanup {
    my $self = shift;
    if ($self->{x_out}) {
        while (my $elt = $self->{x_out}->current_element()) {
            $self->{x_out}->endTag($elt);
        }
      $self->{x_out}->end();
      delete $self->{x_out};
    }
}

sub DESTROY {
  $_[0]->_cleanup();
}

sub _DTD {
  return <<"DTD";
<!ELEMENT testresults (group+)>
<!ATTLIST testresults
   date    CDATA    #REQUIRED >

<!ELEMENT group (test+)>
<!ATTLIST group
   name    CDATA    #REQUIRED
   url     CDATA    #REQUIRED >

<!ELEMENT test (result+)>
<!ATTLIST test
   name    CDATA    #REQUIRED >

<!ELEMENT result (#PCDATA)>
<!ATTLIST result
   status  (PASS | FAIL)  #REQUIRED >
DTD
}

=head1 BUGS

If the test run dies, the resulting XML report is not preperly
terminated, resulting in malformed format which is not parsable
by conforming XML processors.

This can happen for example when a document could not be fetched
and when subsequently a test with the Click plugin is used.

The following limitations apply:

These options from the DefaultReport are missing:

  show_headers
  show_html
  show_cookies

Sending email from this module is not implemented; a work around
would be to parse the resulting XML document and generate an 
email message whenever a test result has status C<FAIL>.


=head1 COPYRIGHT

Copyright (c) 2002 Johannes la Poutre.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest>

L<HTTP::WebTest::API>

L<HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins>

L<XML::Writer>

=cut

1;

