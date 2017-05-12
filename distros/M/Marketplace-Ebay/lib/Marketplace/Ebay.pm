package Marketplace::Ebay;

use 5.010001;
use strict;
use warnings FATAL => 'all';

use HTTP::Thin;
use HTTP::Request;
use HTTP::Headers;
use XML::LibXML;
use XML::Compile::Schema;
use XML::Compile::Util qw/pack_type/;
use Data::Dumper;
use XML::LibXML::Simple;
use Marketplace::Ebay::Response;
use Marketplace::Ebay::Order;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Marketplace::Ebay - Making API calls to eBay (with XSD validation)

=head1 VERSION

Version 0.191

=cut

our $VERSION = '0.191';

=head1 SYNOPSIS

  my $ebay = Marketplace::Ebay->new(
                                    production => 0,
                                    site_id => 77,
                                    developer_key => '1234',
                                    application_key => '6789',
                                    certificate_key => '6666',
                                    token => 'asd12348',
                                    xsd_file => 'ebay.xsd',
                                   );
  my $res = $ebay->api_call('GeteBayOfficialTime', {});
  print Dumper($res);


L<http://developer.ebay.com/Devzone/XML/docs/Concepts/MakingACall.html>

=head1 DESCRIPTION

=head2 International Selling

Products propagate from your local selling account to all Ebay sites
where you are going to ship your items to:

L<http://sellercentre.ebay.co.uk/advanced-international-selling>

=head1 ACCESSORS

=head2 Credentials

The following are required for a successful API call.

=head3 developer_key

=head3 application_key

=head3 certificate_key

=head3 token

=head3 site_id

The id of the site. E.g., Germany is 77.

L<https://developer.ebay.com/DevZone/merchandising/docs/Concepts/SiteIDToGlobalID.html>

=head3 xsd_file

Path to the XSD file with the eBay definitions.

http://developer.ebay.com/webservices/latest/ebaySvc.xsd

=head3 production

Boolean. Default to false.

By default, the API calls are done against the sandbox. Set it to true
in production.

=head3 endpoint

Set lazily by the class depending on the C<production> value.

=head3 compatibility_level

The version of API and XSD used. Please keep this in sync with the XSD.

=head3 last_response

You can get the HTTP::Response object of the last call using this
accessor.

=head2 last_request

You can get the HTTP::Request object of the last call using this
accessor.

=head3 last_parsed_response

Return a L<Marketplace::Ebay::Response> object (or undef on failure)
out of the return value of the last C<api_call>.

=head3 log_file

A filename where to log requests and responses.

=head3 name_from_shipping_address

Passed to L<Marketplace::Ebay::Order>. Defaults to true.

=cut

has developer_key =>   (is => 'ro', required => 1);
has application_key => (is => 'ro', required => 1);
has certificate_key => (is => 'ro', required => 1);
has token =>           (is => 'ro', required => 1);
has site_id =>         (is => 'ro', required => 1);
has site_code => (is => 'lazy');
has name_from_shipping_address => (is => 'ro', isa => Bool, default => sub { 1 });

sub _build_site_code {
    my $self = shift;
    my $code = $self->ebay_sites_id_to_name->{$self->site_id};
    die $self->site_id . " doesn't map to a site name!" unless $code;
    return $code;
}

# totally random, as per Net::eBay
has compatibility_level => (is => 'ro',
                          default => sub { '655' });

has session_certificate => (is => 'lazy');
has production => (is => 'ro', default => sub { 0 });
has endpoint => (is => 'lazy');

has last_response => (is => 'rwp');
has last_parsed_response => (is => 'rwp');
has last_request => (is => 'rwp');
has log_file => (is => 'rw');

sub _build_endpoint {
    my $self = shift;
    if ($self->production) {
        return 'https://api.ebay.com/ws/api.dll';
    }
    else {
        return 'https://api.sandbox.ebay.com/ws/api.dll';
    }
}

sub _build_session_certificate {
    my $self = shift;
    return join(';',
                $self->developer_key,
                $self->application_key,
                $self->certificate_key);
}

has xsd_file => (is => 'ro', required => 1);

has schema => (is => 'lazy');

sub _build_schema {
    my $self = shift;
    my $xsd_file = $self->xsd_file;
    die "$xsd_file is not a file" unless -f $xsd_file;
    return XML::Compile::Schema->new($self->xsd_file);
}


=head1 METHODS

=head2 api_call($name, \%data, \%options)

Do the API call $name with payload in %data. Return the data structure
of the L<Marketplace::Ebay::Response> object. In case of failure,
return nothing. In this case, you can inspect the details of the
failure inspecting, e.g.,

  $self->last_response->status_line;

With option C<requires_struct> set to a true value, the method doesn't
return the object, but a plain hashref with the structure returned
(old behaviour).

With an option C<no_validate>, the XML is parsed using XMLin, not the
schema, so the result could be unstable, but on the other hand, you
get something out of XML which doesn't comply with the schema.

=head2 prepare_xml($name, \%data)

Create the XML document to send for the API call $name.

=head2 show_xml_template($call, $call_type)

Utility for development. Show the expected structure for the API call
$call. The second argument is optional, and may be Request or
Response, defaulting to Request.

=head2 log_event(@data)

Append the arguments to the C<log_file>, if it was defined.

=cut

sub api_call {
    my ($self, $call, $data, $options) = @_;
    $options ||= {};
    $self->log_event("Preparing call to $call for " . Dumper($data));
    my $xml = $self->prepare_xml($call, $data);
    my $headers = $self->_prepare_headers($call);
    my $request = HTTP::Request->new(POST => $self->endpoint, $headers, $xml);
    $self->_set_last_request($request);
    $self->log_event("Doing $call request\n" . $request->as_string);
    my $response = HTTP::Thin->new->request($request);
    $self->_set_last_response($response);
    $self->log_event("Retrieving $call response\n" . $response->as_string);
    $self->_set_last_parsed_response(undef);
    if ($response->is_success) {
        my $struct;
        my $xml = $response->decoded_content;
        if ($call eq 'GetOrders') {
            # until they don't publish an updated xsd
            $xml =~ s!<GuaranteedShipping>(false|true)</GuaranteedShipping>!!g;
        }
        if ($options->{no_validate}) {
            $struct = XMLin($xml);
        }
        else {
            $struct = $self->_parse_response($call, $xml);
        }
        if ($struct) {
            my $obj = Marketplace::Ebay::Response->new(struct => $struct);
            $self->_set_last_parsed_response($obj);
            $self->log_event("Got response:" . Dumper($struct));
            if ($options->{requires_struct}) {
                return $struct;
            }
            else {
                return $obj;
            }
        }
    }
    return;
}

sub _parse_response {
    my ($self, $call, $xml) = @_;
    my $reader = $self->schema->compile(READER => $self->_xml_type($call,
                                                                   'Response'));
    my $struct;
    eval {
        $struct = $reader->($xml);
    };
    return $struct;
}

sub log_event {
    my ($self, @strings) = @_;
    if (my $file = $self->log_file) {
        open (my $fh, '>>', $file) or die "Cannot open $file $!";
        my $now = "\n" . localtime() . "\n";
        print $fh $now, @strings;
        close $fh or die "Cannot close $file $!";
    }
}

sub _prepare_headers {
    my ($self, $call) = @_;
    my $headers = HTTP::Headers->new;
    $headers->push_header('X-EBAY-API-COMPATIBILITY-LEVEL' => $self->compatibility_level);
    $headers->push_header('X-EBAY-API-DEV-NAME' => $self->developer_key);
    $headers->push_header('X-EBAY-API-APP-NAME' => $self->application_key);
    $headers->push_header('X-EBAY-API-CERT-NAME' => $self->certificate_key);
    $headers->push_header('X-EBAY-API-CALL-NAME' => $call);
    $headers->push_header('X-EBAY-API-SITEID' => $self->site_id);
    $headers->push_header('Content-Type' => 'text/xml');
    return $headers;
}

sub show_xml_template {
    my ($self, $call, $call_type) = @_;
    return $self->schema->template(PERL => $self->_xml_type($call, $call_type),
                                   use_default_namespace => 1);
}

sub _xml_type {
    my ($self, $call, $call_type) = @_;
    $call_type ||= 'Request';
    die "Second argument must be Request or Response, defaulting to Request"
      unless ($call_type eq 'Request' or $call_type eq 'Response');
    return pack_type('urn:ebay:apis:eBLBaseComponents', $call . $call_type);
}

sub prepare_xml {
    my ($self, $name, $data) = @_;
    $data ||= {};
    # inject the token
    $data->{RequesterCredentials}->{eBayAuthToken} = $self->token;
    my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $type = $self->_xml_type($name);
    my $write  = $self->schema->compile(WRITER => $type,
                                        use_default_namespace => 1);
    my $xml    = $write->($doc, $data);
    $doc->setDocumentElement($xml);
    return $doc->toString(1);
}

=head1 CONVENIENCE METHODS

=cut

=head2 api_call_wrapper($call, $data, @ids)

Call Ebay's API $call with data $data. Then check the response and
return it. This ends calling $self->api_call($call, $data), but after
that the response is checked and diagnostics are printed out. If you
want something quiet and which is not going to die, or you're
expecting invalid structures, you should use C<api_call> directly.

Return the response object. If no response object is found, it will
die.

=head2 api_call_wrapper_silent($call, $data, @ids)

Same as C<api_call_wrapper>, but do not emit "warn" on warnings. Just
print them out. Also, do not print ids or fees.

=cut

sub api_call_wrapper_silent {
    my ($self, $call, $data, @identifiers) = @_;
    my $res = $self->api_call($call, $data);
    my $message = $call;
    if (@identifiers) {
        $message .= " on " . join(' ', @identifiers);
    }
    if ($res) {
        if ($res->request_ok) {
            if ($res->is_success) {
                print "$message OK\n";
            }
            elsif ($res->errors) {
                print "$message:\n" . $res->errors_as_string;
            }
            else {
                print "$message not a success but no errors found (OK?)\n";
            }
        }
        elsif ($res->errors) {
            warn "$message:\n" . $res->errors_as_string;
        }
        else {
            die "$message: Nor success, nor errors!" . Dumper($res);
        }
    }
    else {
        die "No response found!" . $self->last_response->status_line
          . "\n" . $self->last_response->content;
    }
    return $res;
}


sub api_call_wrapper {
    my ($self, $call, $data, @identifiers) = @_;
    my $res = $self->api_call($call, $data);
    my $message = $call;
    if (@identifiers) {
        $message .= " on " . join(' ', @identifiers);
    }
    if ($res) {
        if ($res->is_success) {
            print "$message OK\n";
        }
        elsif ($res->errors) {
            warn "$message:\n" . $res->errors_as_string;
        }
        else {
            die "$message: Nor success, nor errors!" . Dumper($res);
        }
        if (my $item_id = $res->item_id) {
            print "$message: ebay id: $item_id\n";
        }
        my $fee = $res->total_listing_fee;
        if (defined $fee) {
            print "$message Fee is $fee\n";
        }
    }
    else {
        die "No response found!" . $self->last_response->status_line
          . "\n" . $self->last_response->content;
    }
    return $res;
}

=head2 cancel_item($identifier, $id, $reason)

$identifier is mandatory and can be C<SKU> or C<ItemID> (depending if
you do tracking by sku (this is possible only if the sku was uploaded
with InventoryTrackingMethod = SKU) or by ebay item id. The $id is
mandatory and is the sku or the ebay_id.

Reason can be one of the following, defaulting to OtherListingError: Incorrect, LostOrBroken, NotAvailable, OtherListingError, SellToHighBidder, Sold.

It calls EndFixedPriceItem, so this method is useful only for shops.

=cut

sub cancel_item {
    my ($self, $key, $value, $reason) = @_;
    die "Missing SKU or ItemID" unless $key;
    my %mapping = (
                   SKU => 'sku',
                   ItemID => 'ebay_sku',
                  );
    my %reasons = (
                   Incorrect => 1,
                   LostOrBroken => 1,
                   NotAvailable => 1,
                   OtherListingError => 1,
                   SellToHighBidder => 1,
                   Sold => 1,
                  );
    die "Invalid key $key" unless $mapping{$key};
    unless ($reason && $reasons{$reason}) {
        $reason = 'OtherListingError';
    }
    die "Missing $key" unless $value;
    my $res = $self
      ->api_call_wrapper(EndFixedPriceItem => {
                                               EndingReason => $reason,
                                               ErrorLanguage => 'en_US',
                                               $key => $value,
                                              }, $key, $value);
    return $res;
}

=head2 delete_sku_variations($sku, \@list_of_sku_variations)

It uses ReviseFixedPriceItem to cancel variations of a given sku, not
passing asking for a deletion, but instead setting the quantity to 0.
This because deleting a variation is not possible if a purchase has
been done against it.

=cut

sub delete_sku_variations {
    my ($self, $sku, $list) = @_;
    die unless $sku && $list;
    my @delete = map { +{
                         Quantity => 0,
                         SKU => $_,
                        }  } @$list;
    my $data = {
                ErrorLanguage => 'en_US',
                WarningLevel => 'High',
                Item => {
                         SKU => $sku,
                         Variations => {
                                        Variation => \@delete,
                                       }
                        },
               };
    my $res = $self->api_call_wrapper(ReviseFixedPriceItem => $data, $sku, "delete variations");
    return $res;
}

=head2 get_category_specifics($id)

Return a dump of the structure found in the GetCategorySpecifics

=cut

sub get_category_specifics {
    my ($self, $id) = @_;
    die "Missing category id" unless $id;
    my $res = $self->api_call_wrapper(GetCategorySpecifics => {
                                                               CategoryID => $id,
                                                              }, "category id $id");
    return $res;
}

=head2 get_orders($number_of_days)

Retrieve the last orders in the last number of days, defaulting to 7.
Return a list of L<Marketplace::Ebay::Order> objects. You can access
the raw structures with $object->order.

=cut

sub get_orders {
    my ($self, $backlog) = @_;
    $backlog ||= 7;
    my $request = {
                   NumberOfDays => $backlog,
                   Pagination => {
                                  PageNumber => 1,
                                  EntriesPerPage => 100,
                                 },
                   ErrorLanguage => 'en_US',
                  };
    my $repeat = 1;
    my @orders;
    do {
        # we use the silent variant because it's a known warning spammer.
        my $obj = $self->api_call_wrapper_silent(GetOrders => $request);
        my $res = $obj->struct;
        if (exists $res->{OrderArray} and
            exists $res->{OrderArray}->{Order}) {
            foreach my $ord (@{$res->{OrderArray}->{Order}}) {
                push @orders, Marketplace::Ebay::Order->new(order => $ord,
                                                            name_from_shipping_address => $self->name_from_shipping_address);
            }
        }
        $repeat = $res->{HasMoreOrders};
        $request->{Pagination}->{PageNumber}++;
    } while ($repeat);

    return @orders;
}

=head2 get_orders_for_site

Like get_orders, but filter the orders by the site_id of the object
(otherwise you pull the orders from all the international sites).

=cut

sub get_orders_for_site {
    my ($self, $backlog) = @_;
    my @orders = $self->get_orders($backlog);
    my $name = $self->site_code;
    return grep { $_->ebay_site eq $name } @orders;
}

=head2 ebay_site_code_types (internal)

L<http://developer.ebay.com/devzone/XML/docs/Reference/ebay/types/SiteCodeType.html>
turned into an hashref to map the site name to an id.

=head2 ebay_sites_name_to_id

Return an hashref for mapping ebay site names and abbreviations to a numeric id.

=head2 ebay_sites_id_to_name

Return an hashref for mapping ebay site id to its name.
# http://developer.ebay.com/devzone/XML/docs/Reference/ebay/types/SiteCodeType.html

=cut

sub ebay_site_code_types {

    my %codes = (
                 Australia  => { id => 15, abbreviation => "AU" },
                 Austria  => { id => 16, abbreviation => "AT" },
                 Belgium_Dutch  => { id => 123, abbreviation => "BENL" },
                 Belgium_French  => { id => 23, abbreviation => "BEFR" },
                 Canada  => { id => 2, abbreviation => "CA" },
                 CanadaFrench  => { id => 210, abbreviation => "CAFR" },
                 France  => { id => 71, abbreviation => "FR" },
                 Germany  => { id => 77, abbreviation => "DE" },
                 HongKong  => { id => 201, abbreviation => "HK" },
                 India  => { id => 203, abbreviation => "IN" },
                 Ireland  => { id => 205, abbreviation => "IE" },
                 Italy  => { id => 101, abbreviation => "IT" },
                 Malaysia  => { id => 207, abbreviation => "MY" },
                 Netherlands  => { id => 146, abbreviation => "NL" },
                 Philippines  => { id => 211, abbreviation => "PH" },
                 Poland  => { id => 212, abbreviation => "PL" },
                 Russia  => { id => 215, abbreviation => "RU" },
                 Singapore  => { id => 216, abbreviation => "SG" },
                 Spain  => { id => 186, abbreviation => "ES" },
                 Switzerland  => { id => 193, abbreviation => "CH" },
                 UK  => { id => 3, abbreviation => "UK" },
                 US  => { id => 0, abbreviation => "US" },
                );
    return %codes;
}

sub ebay_sites_name_to_id {
    my $self = shift;
    my %out;
    my %codes = $self->ebay_site_code_types;
    foreach my $k (keys %codes) {
        $out{$k} = $codes{$k}{id};
        $out{$codes{$k}{abbreviation}} = $codes{$k}{id};
    }
    return \%out;
}

sub ebay_sites_id_to_name {
    my $self = shift;
    my %codes = $self->ebay_site_code_types;
    my %out;
    foreach my $k (keys %codes) {
        $out{$codes{$k}{id}} = $k;
    }
    return \%out;
}

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-marketplace-ebay at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Marketplace-Ebay>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Marketplace::Ebay


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marketplace-Ebay>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Marketplace-Ebay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Marketplace-Ebay>

=item * Search CPAN

L<http://search.cpan.org/dist/Marketplace-Ebay/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Marketplace::Ebay
