use strict;

use CGI::EncryptForm;

package HTML::EP::CGIEncryptForm;
$HTML::EP::CGIEncryptForm::VERSION = '1.00';
@HTML::EP::CGIEncryptForm::ISA = 'HTML::EP';

sub _handle {
    my $self = shift; my $attr = shift;
    return $self->{'_ep_cgiencryptform_handle'} if exists
	$self->{'_ep_cgiencryptform_handle'};
    my $cfo = $self->{'_ep_cgiencryptform_handle'} =
	CGI::EncryptForm->new();
    $cfo->secret_key($attr->{'secret_key'}) if exists $attr->{'secret_key'};
    $cfo->usecharset($attr->{'usecharset'}) if exists $attr->{'usecharset'};
    $cfo->charset($attr->{'charset'}) if exists $attr->{'charset'};
    $cfo;
}

sub _ep_cef_encrypt {
    my($self, $attr) = @_;

    my $dest = $attr->{'dest'};
    my $source = $attr->{'source'};
    die "Missing attribute 'source' (Source Hash Reference Variable)"
	unless defined $source;
    $source = ref($source) ? $source :
	($source =~ /^(\w+)((?:\-\>\w+)+)$/) ?
	    $self->FindVar($1, $2) : $self->{$source};

    my $cfo = $self->_handle($attr);
    my $output = $cfo->encrypt($source) || die $cfo->error();
    if ($dest) {
	$self->{$dest} = $output;
	'';
    } else {
	$output;
    }
}

sub _ep_cef_decrypt {
    my($self, $attr) = @_;

    my $dest = $attr->{'dest'};
    my $source = $attr->{'source'};
    die "Missing attribute 'source' (Source String Variable)"
	unless defined $source;
    $source = ref($source) ? $source :
	($source =~ /^(\w+)((?:\-\>\w+)+)$/) ?
	    $self->FindVar($1, $2) : $self->{$source};

    my $debug = $self->{'debug'};
    my $cfo = $self->_handle($attr);

    my $output = $cfo->decrypt($source) || die $cfo->error();
    if ($dest) {
	$self->{$dest} = $output;
	'';
    } else {
	$output;
    }
}


__END__

=pod

=head1 NAME

HTML::EP::CGIEncryptForm - An EP interface to the CGI::EncryptForm module


=head1 SYNOPSIS

  <!--
    This is the first page. We receive some complex data
    here from an HTML form and want to pass it to nextpage.ep.
    Start with loading the package.
  -->
  <ep-package name="HTML::EP::CGIEncryptForm">

  <ep-perl>
    # Process some CGI input and store the results in the
    # hash ref $_->{'form'}, aka EP variable "form".
    ...
  </ep-perl>
  <form action=nextpage.ep method=post>
    <ep-cef-encrypt source=form dest=enc_form>
    <input type=hidden name=myform value="$@enc_form$">
    ...
  </form>


  <!--
    This is the second page. We want to get the data from
    the first page, in other words, restore the variable
    "form" and its contents. That's easy.
  -->
  <ep-package name="HTML::EP::CGIEncryptForm">
  <ep-cef-decrypt source="cgi->myform" dest=form>


=head1 DESCRIPTION

This package is rather similar to the HTML::EP::Session module. In fact,
so similar, that they may be merged in the future. It was contributed
by Peter Marelas <maral@phase-one.com.au>, the author of the
CGI::Encryptform module.

The modules idea is as follows: Suggest you are building a wizard.
In other words, an application gathering information on several
HTML forms. As HTTP is a stateless protocol, the burden of moving
the collected information from page to page is up to you. The
HTML::EP::CGIEncryptForm module will greatly help you in this.

The idea is as follows: The collected information is stored in a
single, structured variable, for example a hash ref. For example,
you could have three pages for configuring an hosts network settings:
The first page contains a form where the user enters IP address and
network mask. The second page allows to add the DNS servers and
the third page the routes. With HTML::EP::CGIEncryptForm, these pages
could look like this (most details omitted):

  <!-- This is the first page  -->
  <!-- No EP here, just simple HTML -->
  <form action=page2.ep method=post>
    <table><tr><th>IP address</th>
               <td><input name="ipaddress" size=15></td></tr>
           <tr><th>Network mask</th>
               <td><input name="netmask" size=15></td></tr>
    </table>
  </form>


  <!-- This is the second page, page2.ep. We start with
       loading the package:
  -->
  <ep-package name="HTML::EP::CGIEncryptForm">
  <!-- Now, collect the information in $self->{settings}: -->
  <ep-perl>
    my $self = $_;
    my $cgi = $self->{cgi};
    $self->{settings}->{ipaddress} = $cgi->param('ipaddress');
    $self->{settings}->{netmask} = $cgi->param('netmask');
    ''
  </ep-perl>
  <!-- Encode the settings into a string: -->
  <ep-cef-encrypt source=settings dest=enc_settings
                  secret_key="Whatakey?">
  <!-- Finally, pass the settings variable to the next page
       by using a hidden field:
  -->
  <form action=page3.ep method=post>
    <table><tr><th>DNS Server 1:</th>
               <td><input name="dns1" size=15></td></tr>
           <tr><th>DNS Server 2:</th>
               <td><input name="dns2" size=15></td></tr>
    </table>
    <input type=hidden name=settings value="$@enc_settings$">
  </form>
  <p>So far, you have created the following settings:</p>
  <table>
    <tr><th>IP address:</th><td>$settings->ipaddress$</td></tr>
    <tr><th>Netmask:</th><td>$settings->netmask$</td></tr>
  </table>

  <!-- And, finally, this is page3.ep. We start with retrieving
       the collected data:
  -->
  <ep-package name="HTML::EP::CGIEncryptForm">
  <ep-cef-decrypt source="cgi->settings" dest="settings"
                  secret_key="Whatakey?">
  <!-- Add the DNS servers to the settings variable:  -->
  <ep-perl>
    my $self = $_;
    my $cgi = $self->{cgi};
    $self->{settings}->{dns1} = $cgi->param('dns1');
    $self->{settings}->{dns2} = $cgi->param('dns2');
    ''
  </ep-perl>
  <p>So far, you have created the following settings:</p>
  <table>
    <tr><th>IP address:</th><td>$settings->ipaddress$</td></tr>
    <tr><th>Netmask:</th><td>$settings->netmask$</td></tr>
    <tr><th>DNS Server 1:</th><td>$settings->dns1$</td></tr>
    <tr><th>DNS Server 2:</th><td>$settings->dns1$</td></tr>
  </table>


The main advantage of CGI::EncryptForm is that it is not only serializing
data, but encrypting and decrypting as well.


=head1 METHOD INTERFACE

These are the methods offered by the HTML::EP::CGIEncryptForm class:


=head2 Encrypting a structured variable into a string

  <ep-cef-encrypt source="source_var" dest="dest_var"
                  secret_key="somekey" usecharset=1>

or, from within ep-perl:

  $self->_ep_cef_encrypt({'source' => 'source_var',
			  'dest' => 'dest_var',
			  'secret_key' => 'some_key',
			  'usecharset' => 1});

(Instance method) Takes the complex EP variable $source_var$ (aka
$self->{'source_var'}) and encrypts it into a string. The I<secret_key>
attribute is used for encrypting the string. The optional attributes
I<usecharset> and I<charset> are passed to the corresponding methods
of CGI::EncryptForm.

If the I<dest> attribute is present, the string is stored in the EP
variable $dest_var$. If not, the output is returned and possibly
inserted into the HTML stream.


=head2 Decrypting a structured variable from a string

  <ep-cef-decrypt source="source_var" dest="dest_var"
                  secret_key="somekey" usecharset=1>

or, from within ep-perl:

  $self->_ep_cef_decrypt({'source' => 'source_var',
			  'dest' => 'dest_var',
			  'secret_key' => 'some_key',
			  'usecharset' => 1});

(Instance method) Takes the EP variable $source_var$ (aka
$self->{'source_var'}) and decrypts it into a complex Perl object.
The I<secret_key> attribute is used for decrypting the string. The
optional attributes I<usecharset> and I<charset> are passed to the
corresponding methods of CGI::EncryptForm.

If the I<dest> attribute is present, the Perl object is stored in
the EP variable $dest_var$. If not, the output is returned and
possibly inserted into the HTML stream.


=head1 SEE ALSO

  L<CGI::EncryptForm>, L<HTML::EP>, L<HTML::EP::Session>


=cut
