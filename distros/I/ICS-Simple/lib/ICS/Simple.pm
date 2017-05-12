#####  TODO:  expand grammar map

package ICS::Simple;

use strict;
no strict "refs";

eval "use ICS";
die qq{ICS::Simple requires the CyberSource ICS module.\nSee http://www.cybersource.com/support_center/implementation/downloads/scmp_api/.\n} if $@;

=head1 NAME

ICS::Simple - Simple interface to CyberSource ICS2

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Here is some basic code.  Hopefully I'll come back through soon to document it properly.

    use ICS::Simple;
    
    my $ics = ICS::Simple->new(
      ICSPath                 => '/opt/ics',
      MerchantId              => 'v0123456789', # CyberSource supplies this number to you
      Mode                    => 'test',
      Currency                => 'USD',
      Grammar                 => 'UpperCamel', # defaults to raw ICS responses, so you might want to set this
      #ErrorsTo               => 'all-errors@some.fun.place.com',
      CriticalErrorsTo        => 'only-critical-errors@some.fun.place.com',
    );
    
    my $request = {
      OrderId                 => 'order19857219',
      FirstName               => 'Fred',
      LastName                => 'Smith',
      Email                   => 'fred.smith@buyer-of-stuff.com',
      CardNumber              => '4111111111111111',
      CardCVV                 => '123',
      CardExpYear             => '2008',
      CardExpMonth            => '12',
      BillingAddress          => '123 Main St',
      BillingCity             => 'Olympia',
      BillingRegion           => 'WA',
      BillingPostalCode       => '98501',
      BillingCountryCode      => 'US',
      ShippingAddress1        => '6789 Industrial Pl',
      ShippingAddress2        => 'Floor 83, Room 11415',
      ShippingCity            => 'Olympia',
      ShippingRegion          => 'WA',
      ShippingPostalCode      => '98506',
      ShippingCountryCode     => 'US',
      ShippingFee             => '25.05',
      HandlingFee             => '5.00',
      Items                   => [
                                    { Description   => 'Mega Lizard Monster RC',
                                      Price         => '25.00',
                                      SKU           => 'prod15185' },
                                    { Description   => 'Super Racer Parts Kit',
                                      Price         => '15.30',
                                      SKU           => 'prod23523' },
                                    { Description   => 'Uber Space Jacket',
                                      Price         => '72.24',
                                      SKU           => 'prod18718' },
      ],
    };
    
    my $response = $ics->requestBill($request);
    
    if ($response->{success}) {
      print "Woo!  Success!\n";
      $response = $response->{response};
      print "Thanks for your payment of \$$response->{BillAmount}.\n";
    }
    else {
      print "Boo!  Failure!\n";
      print "Error:  $response->{error}->{description}\n";
    }

=head1 FUNCTIONS

=head2 new

=cut

sub new {
  my $class = shift;
  my %args = @_;
  my $self = {};
  bless($self, $class);
  foreach my $arg (keys(%args)) {
    $self->set($arg, $args{$arg}, $self);
  }
  $self->{server_mode} ||= 'test'; # default to test mode
  $self->{icspath} ||= '/opt/ics';
  $self->{cvv_accepted} ||=  $ICS::Simple::cvvAcceptedDefault;
  return $self;
}

=head2 set

=cut

sub set {
  my ($self, $key, $val, $namespace, $mapRequired) = @_;
  my $lookupKey = lc($key);
  $lookupKey =~ s|_||g;
  return undef if ($mapRequired && !$ICS::Simple::fieldMap->{$lookupKey}); # if we require that the name is mapped but it isn't, fail
  $key = $ICS::Simple::fieldMap->{$lookupKey} || $key; # if it has a mapped name, use it instead
  $namespace->{$key} = $val;
  return $key;
}

=head2 requestIcs

=cut

sub requestIcs {
  my $self = shift;
  my $request = shift;
  $request->{server_mode} ||= $self->{server_mode};
  $request->{server_host} ||= $self->{server_host};
  unless ($request->{server_host}) {
    if ($request->{server_mode} =~ m|^\s*prod|i) {
      $request->{server_host} = 'ics2.ic3.com';
      $request->{server_port} = '80';
    } else {
      $request->{server_host} = 'ics2test.ic3.com';
      $request->{server_port} = '80';
    }
  }
  $request->{currency} ||= 'USD';
  $request->{merchant_id} ||= $self->{merchant_id};
  $request->{decline_avs_flags} ||= $self->{decline_avs_flags} || $ICS::Simple::avsRejectedDefault;
  
  my $response = {};
  %{$response} = ICS::ics_send(%{$request});
  
  $ICS::Simple::response->{rmsg} = $response->{auth_rmsg} || $response->{ics_rmsg};
  $response->{success} = ($response->{ics_rcode} == 1 ? 1 : 0);
  if (!$response->{success}) {
    $response->{rmsg} = $ICS::Simple::vitalErrorMap->{$response->{ics_rcode}} || $response->{rmsg};
    $response->{auth_auth_error} = $ICS::Simple::vitalErrorMap->{$response->{auth_auth_response}} || $ICS::Simple::vitalErrorMap->{0};
  }
  
  my $error = {};
  if ($response->{ics_rcode} != 1) { # error
    $error = $self->_handleError($request, $response);
  }
  
  return {
    success => $response->{success},
    request => $request,
    response => $self->_translateResponse($response),
    error => $error
  };
}

=head2 _translateResponse

=cut

sub _translateResponse {
  my $self = shift;
  my $response = shift;
  my $grammar = shift || $self->{x_grammar};
  my $gMap = (ref($grammar) eq 'HASH' ? $grammar : ($ICS::Simple::grammarMap->{lc($grammar)} || $ICS::Simple::grammarMap->{stock} || {}));
  my $mapRequired = ($gMap->{_mapRequired} ? 1 : 0);
  foreach my $key (keys(%{$response})) {
    my $val = $response->{$key};
    delete($response->{$key}); # remove old key
    return undef if ($mapRequired && !$gMap->{$key}); # if we require that the name is mapped but it isn't, fail
    $key = $gMap->{$key} || $key; # if it has a mapped name, use it instead
    $response->{$key} = $val; # insert new key
  }
  return $response;
}

=head2 _resolveApp

=cut

sub _resolveApp {
  my $self = shift;
  my $appVal = shift;
  my @apps = (ref($appVal) eq 'ARRAY' ? @{$appVal} : split(/\s*[,;]+\s*/, $appVal)); # turn it into an array if it isn't one already
  my @appsResolved;
  foreach my $app (@apps) {
    next unless $app; # in case we grabbed an empty one (two delimiters seperated by spaces would cause this)
    my $lookupKey = lc($app);
    $lookupKey =~ s|_||g;
    $app = $ICS::Simple::appMap->{$lookupKey} || $app; # if it has a mapped name, use it instead
    push(@appsResolved, $app);
  }
  return join(',', @appsResolved);
}

=head2 _constructOffers

=cut

sub _constructOffers {
  my $self = shift;
  my $itemsKey = shift;
  my $namespace = shift;
  my $items = $namespace->{$itemsKey};
  my @items = (ref($items) eq 'ARRAY' ? @{$items} : [$items]);
  my @offers;
  my $i = 0;
  foreach my $item (@items) {
    my @offerAttrs;
    foreach my $attr (keys(%{$item})) {
      my $val = $item->{$attr};
      my $lookupKey = lc($attr);
      $lookupKey =~ s|_||g;
      $attr = $ICS::Simple::offerAttrMap->{$lookupKey} || $attr; # if it has a mapped name, use it instead
      push(@offerAttrs, $attr.':'.$val);
    }
    my $offer = join('^', 'offerid:'.$i, @offerAttrs);
    $namespace->{'offer'.$i} = $offer;
    $i++;
  }
  delete($namespace->{$itemsKey});
}

=head2 request

=cut

sub request { # convert the request into ICS format and then send it to requestIcs
  my $self = shift;
  my $request = shift;
  
  # combine input namespaces into one
  my $item = {};
  for my $key (keys(%{$self})) {
    $self->set($key, $self->{$key}, $item, 1);
  }
  for my $key (keys(%{$request})) {
    $self->set($key, $request->{$key}, $item, 1);
  }
 
  @{$item->{x_items}} = (ref($item->{x_items}) eq 'ARRAY' ? @{$item->{x_items}} : [$item->{x_items}]);
  
  if ($item->{x_shipping_handling_fee}) {
    my $offer = {
            Amount      => $item->{x_shipping_handling_fee},
            ProductCode => 'shipping_and_handling',
            ProductName => 'Shipping & Handling',
    };
    delete($item->{x_shipping_handling_fee});
    unshift(@{$item->{x_items}}, $offer);
  }
  
  if ($item->{x_shipping_fee}) {
    my $offer = {
            Amount      => $item->{x_shipping_fee},
            ProductCode => 'shipping_only',
            ProductName => 'Shipping',
    };
    delete($item->{x_shipping_fee});
    unshift(@{$item->{x_items}}, $offer);
  }
  
  if ($item->{x_handling_fee}) {
    my $offer = {
            Amount      => $item->{x_handling_fee},
            ProductCode => 'handling_only',
            ProductName => 'Handling',
    };
    delete($item->{x_handling_fee});
    unshift(@{$item->{x_items}}, $offer);
  }
  
  $self->_constructOffers('x_items', $item);
  
  $item->{ics_applications} = $self->_resolveApp($item->{ics_applications});
  $item->{decline_avs_flags} = $item->{decline_avs_flags} || $self->{decline_avs_flags} || $ICS::Simple::avsRejectedDefault;
  
  return $self->requestIcs($item);
}

=head2 requestBill

=cut

sub requestBill {
  my $self = shift;
  my $request = shift;
  $request->{action} = ['auth', 'bill'];
  return $self->request($request);
}

=head2 requestAuth

=cut

sub requestAuth {
  my $self = shift;
  my $request = shift;
  $request->{action} = ['auth'];
  return $self->request($request);
}

=head2 requestAuthReversal

=cut

sub requestAuthReversal {
  my $self = shift;
  my $request = shift;
  $request->{action} = ['authreversal'];
  return $self->request($request);
}

=head2 requestSettle

=cut

sub requestSettle {
  my $self = shift;
  my $request = shift;
  $request->{action} = ['bill'];
  return $self->request($request);
}

=head2 requestCredit

=cut

sub requestCredit {
  my $self = shift;
  my $request = shift;
  $request->{action} = ['credit'];
  return $self->request($request);
}

=head2 _handleError

=cut

sub _handleError { # it failed, but in a normal kind of way
  my $self = shift;
  my $request = shift; # just so we can pass it through to _handleCriticalError
  my $response = shift;
  
  my $statusCode = lc($response->{ics_rflag});
  $statusCode =~ s|^\s+||;
  $statusCode =~ s|\s+$||;
  
  my $error = $ICS::Simple::errorMap->{$statusCode} || $ICS::Simple::errorMap->{default};
  $error->{statuscode} = $statusCode;
  $error->{data} = $response->{ics_rmsg};

  # mail the error, if we can
  my $sendErrorsTo = $self->{x_errors_to};
  if ($error->{critical} || $response->{ics_rcode} < 0) { # critical!
    $sendErrorsTo = $self->{x_critical_errors_to} || $sendErrorsTo;
  }
  $self->_sendError('CyberSource Error: '.($error->{name} || $statusCode), $sendErrorsTo, $request, $response, $error);
  
  return $error;
}

=head2 _sendError

=cut

sub _sendError {
  my $self = shift;
  my $subject = shift || 'ICS::Simple Error Mail';
  my $sendTo = shift or return undef;
  my $request = shift;
  my $response = shift;
  my $error = shift;

  use Data::Dumper;
  use Mail::Send;
  
  my @mailTo = (ref($sendTo) eq 'ARRAY' ? @{$sendTo} : split(/\s*[,;]+\s*/, $sendTo));
  
  my $msg = Mail::Send->new;
  $msg->to(@mailTo);
  $msg->subject($subject);
  $msg->add('X-Site', $self->{x_site});
  $msg->add('X-IP', $ENV{REMOTE_ADDR});
  
  my $body = $msg->open;
  my $bodyContent = join("\n",
          '['.gmtime().' UTC]',
          'ERROR:', Dumper($error),
          'RESPONSE:', Dumper($response),
          'REQUEST:', Dumper($request),
          'ENV:', Dumper(\%ENV),
          'ICS::Simple:', Dumper($self),
  );
  
  # filter things before we send it out
  $bodyContent =~ s|(customer_cc_number'.*?'[^']{4})([^']+?)([^']{4}')|$1.('x' x length($2)).$3|ge; # keep the first/last 4 characters, replace all else
  $bodyContent =~ s|(customer_cc_cv_number'.*?')([^']+?)(')|$1.('x' x length($2)).$3|ge; # replace all the characters
  
  print $body $bodyContent;
  $body->close;
  
  return $error;
}

=head1 AUTHOR

Dusty Wilson, C<< <cpan-ics-simple at dusty.hey.nu> >>

=head1 BUGS

The documentation needs to be finished.  Or started.  Sorry about that.

Please report any bugs or feature requests to
C<bug-ics-simple at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ICS-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ICS::Simple

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ICS-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ICS-Simple>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ICS-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/ICS-Simple>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dusty Wilson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

$ICS::Simple::fieldMap = {  # not case-sens on the key-side
                            # forced lowercase
                            # stripped underscores
  host                        => 'server_host',
  serverhost                  => 'server_host',
  port                        => 'server_port',
  serverport                  => 'server_port',
  mode                        => 'server_mode',
  servermode                  => 'server_mode',
  icspath                     => 'icspath',
  hostid                      => 'host_id',
  merchantid                  => 'merchant_id',
  orderid                     => 'merchant_ref_number',
  merchantorderid             => 'merchant_ref_number',
  ordernumber                 => 'merchant_ref_number',
  merchantordernumber         => 'merchant_ref_number',
  orderrefnumber              => 'merchant_ref_number',
  merchantorderrefnumber      => 'merchant_ref_number',
  refnumber                   => 'merchant_ref_number',
  merchantrefnumber           => 'merchant_ref_number',
  merchantdescriptor          => 'merchant_descriptor',
  merchantdesc                => 'merchant_descriptor',
  merchantdescriptorcontact   => 'merchant_descriptor_contact',
  merchantdesccontact         => 'merchant_descriptor_contact',
  currency                    => 'currency',
  action                      => 'ics_applications',
  actions                     => 'ics_applications',
  icsapplications             => 'ics_applications',
  declineavs                  => 'decline_avs_flags',
  cvvaccepted                 => 'cvv_accepted',
  firstname                   => 'customer_firstname',
  givenname                   => 'customer_firstname',
  customergivenname           => 'customer_firstname',
  customerfirstname           => 'customer_firstname',
  lastname                    => 'customer_lastname',
  familyname                  => 'customer_lastname',
  customerfamilyname          => 'customer_lastname',
  customerlastname            => 'customer_lastname',
  email                       => 'customer_email',
  customeremail               => 'customer_email',
  billingaddress              => 'bill_address1',
  billingaddress1             => 'bill_address1',
  billingaddress2             => 'bill_address2',
  billaddress                 => 'bill_address1',
  billaddress1                => 'bill_address1',
  billaddress2                => 'bill_address2',
  billingcity                 => 'bill_city',
  billcity                    => 'bill_city',
  billingregion               => 'bill_state',
  billregion                  => 'bill_state',
  billingstateprov            => 'bill_state',
  billstateprov               => 'bill_state',
  billingprov                 => 'bill_state',
  billprov                    => 'bill_state',
  billingprovince             => 'bill_state',
  billprovince                => 'bill_state',
  billingstate                => 'bill_state',
  billstate                   => 'bill_state',
  billingpostalcode           => 'bill_zip',
  billingpostal               => 'bill_zip',
  billpostalcode              => 'bill_zip',
  billpostal                  => 'bill_zip',
  billingcountrycode          => 'bill_country',
  billingcountry              => 'bill_country',
  billcountrycode             => 'bill_country',
  billcountry                 => 'bill_country',
  shippingaddress             => 'ship_to_address1',
  shippingaddress1            => 'ship_to_address1',
  shippingaddress2            => 'ship_to_address2',
  shipaddress                 => 'ship_to_address1',
  shipaddress1                => 'ship_to_address1',
  shipaddress2                => 'ship_to_address2',
  shiptoaddress               => 'ship_to_address1',
  shiptoaddress1              => 'ship_to_address1',
  shiptoaddress2              => 'ship_to_address2',
  shippingcity                => 'ship_to_city',
  shipcity                    => 'ship_to_city',
  shiptocity                  => 'ship_to_city',
  shippingregion              => 'ship_to_state',
  shipregion                  => 'ship_to_state',
  shiptoregion                => 'ship_to_state',
  shippingstateprov           => 'ship_to_state',
  shipstateprov               => 'ship_to_state',
  shiptostateprov             => 'ship_to_state',
  shippingprov                => 'ship_to_state',
  shipprov                    => 'ship_to_state',
  shiptoprov                  => 'ship_to_state',
  shippingprovince            => 'ship_to_state',
  shipprovince                => 'ship_to_state',
  shiptoprovince              => 'ship_to_state',
  shippingstate               => 'ship_to_state',
  shipstate                   => 'ship_to_state',
  shiptostate                 => 'ship_to_state',
  shippingpostalcode          => 'ship_to_zip',
  shippingpostal              => 'ship_to_zip',
  shippostalcode              => 'ship_to_zip',
  shippostal                  => 'ship_to_zip',
  shiptopostalcode            => 'ship_to_zip',
  shiptopostal                => 'ship_to_zip',
  shippingcountrycode         => 'ship_to_country',
  shippingcountry             => 'ship_to_country',
  shipcountrycode             => 'ship_to_country',
  shipcountry                 => 'ship_to_country',
  shiptocountrycode           => 'ship_to_country',
  shiptocountry               => 'ship_to_country',
  cardexpmonth                => 'customer_cc_expmo',
  ccexpmo                     => 'customer_cc_expmo',
  customerccexpmo             => 'customer_cc_expmo',
  cardexpyear                 => 'customer_cc_expyr',
  ccexpyr                     => 'customer_cc_expyr',
  customerccexpyr             => 'customer_cc_expyr',
  cardnumber                  => 'customer_cc_number',
  ccnumber                    => 'customer_cc_number',
  customerccnumber            => 'customer_cc_number',
  cardcvnumber                => 'customer_cc_cv_number',
  cardcv                      => 'customer_cc_cv_number',
  cardcvvnumber               => 'customer_cc_cv_number',
  cardcvv                     => 'customer_cc_cv_number',
  cardcvv2                    => 'customer_cc_cv_number',
  cardcvnnumber               => 'customer_cc_cv_number',
  cardcvn                     => 'customer_cc_cv_number',
  cccvnnumber                 => 'customer_cc_cv_number',
  cccv                        => 'customer_cc_cv_number',
  cccvv                       => 'customer_cc_cv_number',
  cccvn                       => 'customer_cc_cv_number',
  customercccvnnumber         => 'customer_cc_cv_number',
  customercccvvnumber         => 'customer_cc_cv_number',
  customercccvv2number        => 'customer_cc_cv_number',
  customercccvnumber          => 'customer_cc_cv_number',
  ignoreavs                   => 'ignore_avs',
  ignorebadcv                 => 'ignore_bad_cv',
  timeout                     => 'timeout',
  # x_* items are custom (not ICS) fields that are processed before sending
  appname                     => 'x_site',
  app                         => 'x_site',
  sitename                    => 'x_site',
  site                        => 'x_site',
  xsite                       => 'x_site',
  errto                       => 'x_errors_to',
  errorto                     => 'x_errors_to',
  errorsto                    => 'x_errors_to',
  xerrorsto                   => 'x_errors_to',
  criterrto                   => 'x_critical_errors_to',
  criterrorto                 => 'x_critical_errors_to',
  criterrorsto                => 'x_critical_errors_to',
  criticalerrto               => 'x_critical_errors_to',
  criticalerrorto             => 'x_critical_errors_to',
  criticalerrorsto            => 'x_critical_errors_to',
  xcriticalerrorsto           => 'x_critical_errors_to',
  grammar                     => 'x_grammar',
  shippingfee                 => 'x_shipping_fee',
  xshippingfee                => 'x_shipping_fee',
  handlingfee                 => 'x_handling_fee',
  xhandlingfee                => 'x_handling_fee',
  shippinghandlingfee         => 'x_shipping_handling_fee',
  xshippinghandlingfee        => 'x_shipping_handling_fee',
  merch                       => 'x_items',
  offer                       => 'x_items',
  offers                      => 'x_items',
  item                        => 'x_items',
  items                       => 'x_items',
  xitem                       => 'x_items',
  xitems                      => 'x_items',
};

$ICS::Simple::appMap = {  # not case-sens on the key-side
                          # forced lowercase
                          # stripped underscores
  auth                => 'ics_auth',
  icsauth             => 'ics_auth',
  bill                => 'ics_bill',
  icsbill             => 'ics_bill',
  credit              => 'ics_credit',
  icscredit           => 'ics_credit',
  authreversal        => 'ics_auth_reversal',
  icsauthreversal     => 'ics_auth_reversal',
  authrev             => 'ics_auth_reversal',
  icsauthrev          => 'ics_auth_reversal',
  revauth             => 'ics_auth_reversal',
  icsrevauth          => 'ics_auth_reversal',
  reverseauth         => 'ics_auth_reversal',
  icsreverseauth      => 'ics_auth_reversal',
  score               => 'ics_score',
  icsscore            => 'ics_score',
  export              => 'ics_export',
  icsexport           => 'ics_export',
  dav                 => 'ics_dav',
  icsdav              => 'ics_dav',
};

$ICS::Simple::offerAttrMap = {  # not case-sens on the key-side
                                # forced lowercase
                                # stripped underscores
  description         => 'product_name',
  productname         => 'product_name',
  sku                 => 'merchant_product_sku',
  itemsku             => 'merchant_product_sku',
  productid           => 'merchant_product_sku',
  itemid              => 'merchant_product_sku',
  merchantproductsku  => 'merchant_product_sku',
  type                => 'product_code',
  producttype         => 'product_code',
  code                => 'product_code',
  productcode         => 'product_code',
  each                => 'amount',
  price               => 'amount',
  amount              => 'amount',
  count               => 'quantity',
  qty                 => 'quantity',
  quantity            => 'quantity',
  tax                 => 'tax_amount',
  taxamount           => 'tax_amount',
};

$ICS::Simple::grammarMap = {
  stock               => {}, # no change -- raw response
  lowercamel          => {
                            success                           => 'success',
                            request_token                     => 'requestToken',
                            request_id                        => 'requestId',
                            merchant_ref_number               => 'orderNumber',
                            rmsg                              => 'responseMessage',
                            ics_rflag                         => 'icsResponseFlag',
                            ics_rcode                         => 'icsResponseCode',
                            ics_rmsg                          => 'icsResponseMessage',
                            auth_auth_time                    => 'authTime',
                            auth_rflag                        => 'authResponseFlag',
                            auth_rcode                        => 'authResponseCode',
                            auth_rmsg                         => 'authResponseMessage',
                            auth_auth_response                => 'authResponse',
                            auth_auth_error                   => 'authError',
                            auth_auth_amount                  => 'authAmount',
                            auth_auth_code                    => 'authCode',
                            auth_cv_result                    => 'authCvResult',
                            auth_cv_result_raw                => 'authCvRaw',
                            auth_auth_avs                     => 'authAvsResult',
                            auth_avs_raw                      => 'authAvsRaw',
                            auth_factor_code                  => 'authFactorCode',
                            auth_vital_error                  => 'authVitalError',
                            bill_bill_request_time            => 'billRequestTime',
                            bill_rflag                        => 'billResponseFlag',
                            bill_rcode                        => 'billResponseCode',
                            bill_rmsg                         => 'billResponseMessage',
                            bill_trans_ref_no                 => 'billTransactionNumber',
                            bill_bill_amount                  => 'billAmount',
                            currency                          => 'currency',
                         },
  uppercamel          => {
                            success                           => 'Success',
                            request_token                     => 'RequestToken',
                            request_id                        => 'RequestId',
                            merchant_ref_number               => 'OrderNumber',
                            rmsg                              => 'ResponseMessage',
                            ics_rflag                         => 'IcsResponseFlag',
                            ics_rcode                         => 'IcsResponseCode',
                            ics_rmsg                          => 'IcsResponseMessage',
                            auth_auth_time                    => 'AuthTime',
                            auth_rflag                        => 'AuthResponseFlag',
                            auth_rcode                        => 'AuthResponseCode',
                            auth_rmsg                         => 'AuthResponseMessage',
                            auth_auth_response                => 'AuthResponse',
                            auth_auth_error                   => 'AuthError',
                            auth_auth_amount                  => 'AuthAmount',
                            auth_auth_code                    => 'AuthCode',
                            auth_cv_result                    => 'AuthCvResult',
                            auth_cv_result_raw                => 'AuthCvRaw',
                            auth_auth_avs                     => 'AuthAvsResult',
                            auth_avs_raw                      => 'AuthAvsRaw',
                            auth_factor_code                  => 'AuthFactorCode',
                            bill_bill_request_time            => 'BillRequestTime',
                            bill_rflag                        => 'BillResponseFlag',
                            bill_rcode                        => 'BillResponseCode',
                            bill_rmsg                         => 'BillResponseMessage',
                            bill_trans_ref_no                 => 'BillTransactionNumber',
                            bill_bill_amount                  => 'BillAmount',
                            currency                          => 'Currency',
                         },
};

$ICS::Simple::errorMap = {
  default             => {
                            name          => 'UNKNOWN',
                            description   => 'Unable to process order.',
                         },
  esystem             => {
                            name          => 'SYSTEM',
                            description   => 'System error.',
                            critical      => 1,
                         },
  etimeout            => {
                            name          => 'TIMEOUT',
                            description   => 'Communications timeout.  Please wait a few moments, then try again.',
                         },
  dduplicate          => {
                            name          => 'DUPLICATE',
                            description   => 'Duplicate transaction refused.',
                         },
  dinvalid            => {
                            name          => 'INVALIDDATA',
                            description   => 'The provided credit card was declined.  Check your billing address, credit card number, and CVV and try again or use a different card.',
                         },
  dinvaliddata        => {
                            name          => 'INVALIDDATA',
                            description   => 'The provided credit card was declined.  Check your billing address, credit card number, and CVV and try again or use a different card.',
                         },
  dinvalidcard        => {
                            name          => 'INVALIDCARD',
                            description   => 'The provided credit card was declined.  Check your billing address, credit card number, and CVV and try again or use a different card.',
                         },
  dinvalidaddress     => {
                            name          => 'INVALIDADDRESS',
                            description   => 'Invalid address data provided.  Please reenter the necessary data and try again.',
                         },
  dmissingfield       => {
                            name          => 'MISSINGFIELD',
                            description   => 'Required field data missing.  Please reenter the necessary data and try again.',
                         },
  drestricted         => {
                            name          => 'RESTRICTED',
                            description   => 'Unable to process order.',
                         },
  dcardrefused        => {
                            name          => 'CARDREFUSED',
                            description   => 'The provided credit card was declined.  Check your billing address, credit card number, and CVV and try again or use a different card.',
                         },
  dcall               => {
                            name          => 'CALL',
                            description   => 'Unable to process order.',
                         },
  dcardexpired        => {
                            name          => 'CARDEXPIRED',
                            description   => 'The provided credit card is expired.  Please use another card and try again.',
                         },
  davsno              => {
                            name          => 'AVSFAILED',
                            description   => 'The provided credit card was declined.  Check your billing address, credit card number, and CVV and try again or use a different card.',
                         },
  dcv                 => {
                            name          => 'CV',
                            description   => 'The provided credit card was declined.  Check your billing address, credit card number, and CVV and try again or use a different card.',
                         },
  dnoauth             => {
                            name          => 'NOAUTH',
                            description   => 'The requested transaction does not match a valid, existing authorization transaction.',
                         },
  dscore              => {
                            name          => 'SCORE',
                            description   => 'Score exceeds limit.',
                         },
  dsettings           => {
                            name          => 'SETTINGS',
                            description   => 'The provided credit card was declined.  Check your billing address, credit card number, and CVV and try again or use a different card.',
                         },
};

$ICS::Simple::cvvAcceptedDefault = 'M,P,U,X,1';

$ICS::Simple::cvvMap = {
  I                   => {
                            note          => 'Card verification number failed processor\'s data validation check.',
                         },
  M                   => {
                            note          => 'Card verification number matched.',
                         },
  N                   => {
                            note          => 'Card verification number not matched.',
                         },
  P                   => {
                            note          => 'Card verification number not processed.',
                         },
  S                   => {
                            note          => 'Card verification number is on the card but was not included in the request.',
                         },
  U                   => {
                            note          => 'Card verification is not supported by the issuing bank.',
                         },
  X                   => {
                            note          => 'Card verification is not supported by the card association.',
                         },
  1                   => {
                            note          => 'CyberSource does not support card verification for this processor or card type.',
                         },
  2                   => {
                            note          => 'The processor returned an unrecognized value for the card verification response.',
                         },
  3                   => {
                            note          => 'The processor did not return a card verification result code.',
                         },
};

$ICS::Simple::avsRejectedDefault = 'A,C,E,I,N,R,S,U,W,1,2';

$ICS::Simple::avsMap = {
  A                   => {
                            note          => 'Street address matches, but both 5-digit ZIP code and 9-digit ZIP code do not match.',
                         },
  B                   => {
                            note          => 'Street address matches, but postal code not verified. Returned only for non-U.S.-issued Visa cards.',
                         },
  C                   => {
                            note          => 'Street address and postal code do not match. Returned only for non U.S.-issued Visa cards.',
                         },
  D                   => {
                            note          => 'Street address and postal code both match. Returned only for non-U.S.-issued Visa cards.',
                         },
  E                   => {
                            note          => 'AVS data is invalid.',
                         },
  G                   => {
                            note          => 'Non-U.S. issuing bank does not support AVS.',
                         },
  I                   => {
                            note          => 'Address information not verified. Returned only for non-U.S.-issued Visa cards.',
                         },
  J                   => {
                            note          => 'Card member name, billing address, and postal code all match. Ship-to information verified and chargeback protection guaranteed through the Fraud Protection Program. This code is returned only if you are signed up to use AAV+ with the American Express Phoenix processor.',
                         },
  K                   => {
                            note          => 'Card member\'s name matches. Both billing address and billing postal code do not match. This code is returned only if you are signed up to use Enhanced AVS or AAV+ with the American Express Phoenix processor.',
                         },
  L                   => {
                            note          => 'Card member\'s name matches. Billing postal code matches, but billing address does not match. This code is returned only if you are signed up to use Enhanced AVS or AAV+ with the American Express Phoenix processor.',
                         },
  M                   => {
                            note          => 'Street address and postal code both match. Returned only for non-U.S.-issued Visa cards.',
                         },
  N                   => {
                            note          => 'Street address and postal code do not match. Returned only for U.S.-issued Visa cards.',
                         },
  O                   => {
                            note          => 'Card member name matches. Billing address matches, but billing postal code does not match. This code is returned only if you are signed up to use Enhanced AVS or AAV+ with the American Express Phoenix processor.',
                         },
  P                   => {
                            note          => 'Postal code matches, but street address not verified. Returned only for non-U.S.-issued Visa cards.',
                         },
  Q                   => {
                            note          => 'Card member name, billing address, and postal code all match. Ship-to information verified but chargeback protection not guaranteed (Standard program). This code is returned only if you are signed up to use AAV+ with the American Express Phoenix processor.',
                         },
  R                   => {
                            note          => 'System unavailable.',
                         },
  S                   => {
                            note          => 'U.S. issuing bank does not support AVS.',
                         },
  U                   => {
                            note          => 'Address information unavailable. Returned if non-U.S. AVS is not available or if the AVS in a U.S. bank is not functioning properly.',
                         },
  V                   => {
                            note          => 'Card member name matches. Both billing address and billing postal code match. This code is returned only if you are signed up to use Enhanced AVS or AAV+ with the American Express Phoenix processor.',
                         },
  W                   => {
                            note          => 'Street address does not match, but 9-digit ZIP code matches.',
                         },
  X                   => {
                            note          => 'Exact match. Street address and 9-digit ZIP code both match.',
                         },
  Y                   => {
                            note          => 'Street address and 5-digit ZIP code both match.',
                         },
  Z                   => {
                            note          => 'Street address does not match, but 5-digit ZIP code matches.',
                         },
  1                   => {
                            note          => 'CyberSource AVS code. AVS is not supported for this processor or card type.',
                         },
  2                   => {
                            note          => 'CyberSource AVS code. The processor returned an unrecognized value for the AVS response.',
                         },
};

$ICS::Simple::vitalErrorMap = {
  '01'                => {
                            action        => 'decline',
                            note          => 'Refer to Issuer',
                            description   => 'Please call your card issuer.',
                         },
  '02'                => {
                            action        => 'decline',
                            note          => 'Refer to Issuer - Special Condition',
                            description   => 'Please call your card issuer.',
                         },
  '03'                => {
                            action        => 'error',
                            note          => 'Invalid Merchant ID',
                            description   => 'Please call customer service to complete order.',
                         },
  '04'                => {
                            action        => 'decline',
                            note          => 'Pick up card',
                            description   => 'Authorization has been declined.',
                         },
  '05'                => {
                            action        => 'decline',
                            note          => 'Do Not Honor',
                            description   => 'Authorization has been declined.',
                         },
  '06'                => {
                            action        => 'error',
                            note          => 'General Error',
                            description   => 'Please call customer service to complete order.',
                         },
  '07'                => {
                            action        => 'decline',
                            note          => 'Pick up card - Special Condition',
                            description   => 'Authorization has been declined.',
                         },
  '12'                => {
                            action        => 'error',
                            note          => 'Unknown system error',
                            description   => 'Please call customer service to complete order.',
                         },
  '13'                => {
                            action        => 'error',
                            note          => 'Invalid Amount',
                            description   => 'Invalid amount.',
                         },
  '14'                => {
                            action        => 'error',
                            note          => 'Invalid Card Number',
                            description   => 'Invalid card number.',
                         },
  '15'                => {
                            action        => 'error',
                            note          => 'No such issuer',
                            description   => 'Invalid card number.',
                         },
  '19'                => {
                            action        => 'decline',
                            note          => 'Unknown Decline Error',
                            description   => 'Authorization has been declined.',
                         },
  '28'                => {
                            action        => 'error',
                            note          => 'File is temporarily unavailable',
                            description   => 'Please call customer service to complete order.',
                         },
  '39'                => {
                            action        => 'error',
                            note          => 'Invalid Card Number',
                            description   => 'Invalid card number.',
                         },
  '41'                => {
                            action        => 'decline',
                            note          => 'Pick up card - Lost',
                            description   => 'Authorization has been declined.',
                         },
  '43'                => {
                            action        => 'decline',
                            note          => 'Pick up card - Stolen',
                            description   => 'Authorization has been declined.',
                         },
  '51'                => {
                            action        => 'decline',
                            note          => 'Insufficient Funds',
                            description   => 'Authorization has been declined.',
                         },
  '52'                => {
                            action        => 'error',
                            note          => 'Unknown Card Number Error',
                            description   => 'Invalid Card Number',
                         },
  '53'                => {
                            action        => 'error',
                            note          => 'Unknown Card Number Error',
                            description   => 'Invalid Card Number',
                         },
  '54'                => {
                            action        => 'expired',
                            note          => 'Expired Card',
                            description   => 'Expired card.',
                         },
  '55'                => {
                            action        => 'error',
                            note          => 'Incorrect PIN',
                            description   => 'Incorrect Card/PIN combination.', # is it safe to let them know the PIN is wrong?
                         },
  '57'                => {
                            action        => 'decline',
                            note          => 'Transaction Disallowed - Card',
                            description   => 'Authorization has been declined.',
                         },
  '58'                => {
                            action        => 'decline',
                            note          => 'Transaction Disallowed - Term',
                            description   => 'Authorization has been declined.',
                         },
  '61'                => {
                            action        => 'decline',
                            note          => 'Withdrawal Limit Exceeded',
                            description   => 'Withdrawal limit exceeded.',
                         },
  '62'                => {
                            action        => 'decline',
                            note          => 'Invalid Service Code, Restricted',
                            description   => 'Authorization has been declined.',
                         },
  '63'                => {
                            action        => 'decline',
                            note          => 'Unknown Decline Error',
                            description   => 'Authorization has been declined.',
                         },
  '65'                => {
                            action        => 'decline',
                            note          => 'Activity Limit Exceeded',
                            description   => 'Authorization has been declined.',
                         },
  '75'                => {
                            action        => 'decline',
                            note          => 'PIN Attempts Exceeded',
                            description   => 'Authorization has been declined.',
                         },
  '78'                => {
                            action        => 'error',
                            note          => 'Unknown Invalid Card Number Error',
                            description   => 'Invalid Card Number',
                         },
  '79'                => {
                            action        => 'call',
                            note          => 'Unknown Error',
                            description   => 'Please call customer service to complete order.',
                         },
  '80'                => {
                            action        => 'error',
                            note          => 'Invalid Expiration Date',
                            description   => 'Invalid expiration date.',
                         },
  '82'                => {
                            action        => 'decline',
                            note          => 'Cashback Limit Exceeded',
                            description   => 'Cashback limit exceeded.',
                         },
  '83'                => {
                            action        => 'decline',
                            note          => 'Unknown PIN Verification Error',
                            description   => 'Can not verify PIN.',
                         },
  '86'                => {
                            action        => 'decline',
                            note          => 'Unknown PIN Verification Error',
                            description   => 'Can not verify PIN.',
                         },
  '91'                => {
                            action        => 'unavailable',
                            note          => 'Issuer or switch is unavailable',
                            description   => 'Please call customer service to complete order.',
                         },
  '92'                => {
                            action        => 'call',
                            note          => 'Unknown Error',
                            description   => 'Please call customer service to complete order.',
                         },
  '93'                => {
                            action        => 'decline',
                            note          => 'Violation, Cannot Complete',
                            description   => 'Authorization has been declined.',
                         },
  '96'                => {
                            action        => 'error',
                            note          => 'System Malfunction',
                            description   => 'Please call customer service to complete order.',
                         },
  'EA'                => {
                            action        => 'error',
                            note          => 'Verification Error',
                            description   => 'Please call customer service to complete order.',
                         },
  'EB'                => {
                            action        => 'call',
                            note          => 'Unknown Error',
                            description   => 'Please call customer service to complete order.',
                         },
  'EC'                => {
                            action        => 'error',
                            note          => 'Verification Error',
                            description   => 'Please call customer service to complete order.',
                         },
  'N3'                => {
                            action        => 'error',
                            note          => 'Cashback Service Not Available',
                            description   => 'Cashback service is not available.',
                         },
  'N4'                => {
                            action        => 'decline',
                            note          => 'Issuer Withdrawal Limit Exceeded',
                            description   => 'Amount exceeds issuer withdrawal limit.',
                         },
  'N7'                => {
                            action        => 'error',
                            note          => 'Invalid CVV2 Data Supplied',
                            description   => 'Invalid card security code.', # should we let the enduser know this?
                         },
};

1; # End of ICS::Simple
