package Google::Checkout::XML::Constants;

#--
#-- Constants of XML strings
#--

use strict;
use warnings;

use Exporter;
our @ISA = qw/Exporter/;

#--
#-- These are config constants
#--
use constant MERCHANT_ID        => "MERCHANT_ID";
use constant MERCHANT_KEY       => "MERCHANT_KEY";
use constant BASE_GCO_SERVER    => "BASE_GCO_SERVER";
use constant XML_SCHEMA         => "XML_SCHEMA";
use constant CURRENCY_SUPPORTED => "CURRENCY_SUPPORTED";

#--
#-- XML constants
#--
use constant CHECKOUT_ROOT    => "checkout-shopping-cart";
use constant SHOPPING_CART    => "shopping-cart";
use constant ITEMS            => "items";
use constant ITEM             => "item";
use constant ITEM_NAME        => "item-name";
use constant ITEM_DESCRIPTION => "item-description";
use constant ITEM_PRICE       => "unit-price";
use constant ITEM_CURRENCY    => "currency";
use constant QUANTITY         => "quantity";
use constant CHECKOUT_FLOW    => "checkout-flow-support";
use constant EXPIRATION       => "cart-expiration";
use constant GOOD_UNTIL       => "good-until-date";
use constant AMOUNT           => "amount";
use constant MERCHANT_ITEM_ID => "merchant-item-id";

use constant MERCHANT_PRIVATE_DATA => "merchant-private-data";
use constant MERCHANT_PRIVATE_NOTE => "merchant-note";
use constant ITEM_PRIVATE_DATA     => "merchant-private-item-data";
use constant ITEM_PRIVATE_NOTE     => "item-note";
use constant ITEM_DATA             => "item-data";
use constant TAX_TABLE_SELECTOR    => "tax-table-selector";

use constant MERCHANT_CHECKOUT_FLOW => "merchant-checkout-flow-support";

use constant NAME               => "name";
use constant PRICE              => "price";
use constant SHIPPING_METHODS   => "shipping-methods";
use constant FLAT_RATE_SHIPPING => "flat-rate-shipping";
use constant PICKUP             => "pickup";

use constant ADDRESS_FILTERS              => "address-filters";
use constant SHIPPING_RESTRICTIONS        => "shipping-restrictions";
use constant MERCHANT_CALCULATED_SHIPPING => "merchant-calculated-shipping";

use constant ALLOWED_AREA        => "allowed-areas";
use constant EXCLUDED_AREA       => "excluded-areas";
use constant US_STATE            => "us-state-area";
use constant STATE               => "state";
use constant US_ZIP_AREA         => "us-zip-area";
use constant US_ZIP_PATTERN      => "zip-pattern";
use constant US_COUNTRY_AREA     => "us-country-area";
use constant COUNTRY_AREA        => "country-area";
use constant WORLD_AREA          => "world-area";
use constant ALLOW_US_PO_BOX     => "allow-us-po-box";
use constant POSTAL_AREA         => "postal-area";
use constant COUNTRY_CODE        => "country-code";
use constant POSTAL_CODE_PATTERN => "postal-code-pattern";

use constant CONTINENTAL_48 => "CONTINENTAL_48";
use constant FULL_50_STATES => "FULL_50_STATES";
use constant ALL_STATES     => "ALL";
use constant EU_COUNTRIES   => "EU_COUNTRIES";

use constant EDIT_CART_URL         => "edit-cart-url";
use constant CONTINUE_SHOPPING_URL => "continue-shopping-url";
use constant BUYER_PHONE_NUMBER    => "request-buyer-phone-number";

use constant TAX_TABLES               => "tax-tables";
use constant DEFAULT_TAX_TABLE        => "default-tax-table";
use constant ALTERNATE_TAX_TABLES     => "alternate-tax-tables";
use constant ALTERNATE_TAX_TABLE      => "alternate-tax-table";
use constant STANDALONE               => "standalone";
use constant TAX_RULES                => "tax-rules";
use constant DEFAULT_TAX_RULE         => "default-tax-rule";
use constant ALTERNATE_TAX_RULES      => "alternate-tax-rules";
use constant ALTERNATE_TAX_RULE       => "alternate-tax-rule";
use constant SHIPPING_TAXED           => "shipping-taxed";
use constant RATE                     => "rate";
use constant TAX_AREA                 => "tax-area";
use constant MERCHANT_CALCULATED      => "merchant-calculated";
use constant MERCHANT_CALCULATION     => "merchant-calculations";
use constant MERCHANT_CALCULATION_URL => "merchant-calculations-url";
use constant ACCEPT_MERCHANT_COUPONS  => "accept-merchant-coupons";
use constant ACCEPT_GIFT_CERTIFICATES => "accept-gift-certificates";

use constant ORDER_NUMBER              => "google-order-number";
use constant CHARGE_ORDER              => "charge-order";
use constant REFUND_ORDER              => "refund-order";
use constant CANCEL_ORDER              => "cancel-order";
use constant PROCESS_ORDER             => "process-order";
use constant DELIVER_ORDER             => "deliver-order";
use constant TRACKING_DATA             => "tracking-data";
use constant ADD_TRACKING_DATA         => "add-tracking-data";
use constant ADD_MERCHANT_ORDER_NUMBER => "add-merchant-order-number";
use constant SEND_BUYER_MESSAGE        => "send-buyer-message";
use constant ARCHIVE_ORDER             => "archive-order";
use constant AUTHORIZE_ORDER           => "authorize-order";
use constant UNARCHIVE_ORDER           => "unarchive-order";
use constant COMMENT                   => "comment";
use constant REASON                    => "reason";
use constant SEND_EMAIL                => "send-email";
use constant CARRIER                   => "carrier";
use constant MESSAGE                   => "message";
use constant TRACKING_NUMBER           => "tracking-number";
use constant MERCHANT_ORDER_NUMBER     => "merchant-order-number";

use constant DHL   => 'DHL';
use constant FedEx => 'FedEx';
use constant UPS   => 'UPS';
use constant USPS  => 'USPS';
use constant Other => 'Other';

use constant SERIAL_NUMBER                           => "serial-number";
use constant ORDER_TOTAL                             => "order-total";
use constant FULFILLMENT_ORDER_STATE                 => "fulfillment-order-state";
use constant FINANCIAL_ORDER_STATE                   => "financial-order-state";
use constant BUYER_ID                                => "buyer-id";
use constant TIMESTAMP                               => "timestamp";
use constant BUYER_MARKETING_PERFERENCES             => "buyer-marketing-preferences";
use constant EMAIL_ALLOWED                           => "email-allowed";
use constant ORDER_ADJUSTMENT                        => "order-adjustment";
use constant MERCHANT_CALCULATION_SUCCESSFUL         => "merchant-calculation-successful";
use constant TOTAL_TAX                               => "total-tax";
use constant ADJUSTMENT_TOTAL                        => "adjustment-total";
use constant MERCHANT_CODES                          => "merchant-codes";
use constant GIFT_CERTIFICATE_ADJUSTMENT             => "gift-certificate-adjustment";
use constant COUPON_ADJUSTMENT                       => "coupon-adjustment";
use constant GIFT_CERTIFICATE_CALCULATED_AMOUNT      => "calculated-amount";
use constant GIFT_CERTIFICATE_APPLIED_AMOUNT         => "applied-amount";
use constant GIFT_CERTIFICATE_CODE                   => "code";
use constant SHIPPING                                => "shipping";
use constant MERCHANT_CALCULATED_SHIPPING_ADJUSTMENT => "merchant-calculated-shipping-adjustment";
use constant FLAT_RATE_SHIPPING_ADJUSTMENT           => "flat-rate-shipping-adjustment";
use constant PICKUP_SHIPPING_ADJUSTMENT              => "pickup-shipping-adjustment";
use constant SHIPPING_NAME                           => "shipping-name";
use constant SHIPPING_COST                           => "shipping-cost";

use constant GET_SHIPPING    => "buyer";
use constant GET_BILLING     => "billing";
use constant BUYER_SHIPPING  => "buyer-shipping-address";
use constant BUYER_BILLING   => "buyer-billing-address";
use constant BILLING_ADDRESS => "billing-address";

use constant BUYER_CONTACT_NAME => "contact-name";
use constant BUYER_COMPANY_NAME => "company-name";
use constant BUYER_EMAIL        => "email";
use constant BUYER_PHONE        => "phone";
use constant BUYER_FAX          => "fax";
use constant BUYER_ADDRESS1     => "address1";
use constant BUYER_ADDRESS2     => "address2";
use constant BUYER_CITY         => "city";
use constant BUYER_REGION       => "region";
use constant BUYER_POSTAL_CODE  => "postal-code";
use constant BUYER_COUNTRY_CODE => "country-code";

use constant RISK_INFORMATION        => "risk-information";
use constant ELIGIBLE_FOR_PROTECTION => "eligible-for-protection";
use constant AVS_RESPONSE            => "avs-response";
use constant CVN_RESPONSE            => "cvn-response";
use constant PARTIAL_CC_NUMBER       => "partial-cc-number";
use constant BUYER_ACCOUNT_AGE       => "buyer-account-age";
use constant IP_ADDRESS              => "ip-address";

use constant NEW_FULFILLMENT_ORDER_STATE      => "new-fulfillment-order-state";
use constant NEW_FINANCIAL_ORDER_STATE        => "new-financial-order-state";
use constant PREVIOUS_FULFILLMENT_ORDER_STATE => "previous-fulfillment-order-state";
use constant PREVIOUS_FINANCIAL_ORDER_STATE   => "previous-financial-order-state";

use constant LATEST_CHARGE_AMOUNT     => "latest-charge-amount";
use constant TOTAL_CHARGE_AMOUNT      => "total-charge-amount";
use constant LATEST_REFUND_AMOUNT     => "latest-refund-amount";
use constant TOTAL_REFUND_AMOUNT      => "total-refund-amount";
use constant LATEST_CHARGEBACK_AMOUNT => "latest-chargeback-amount";
use constant TOTAL_CHARGEBACK_AMOUNT  => "total-chargeback-amount";

use constant NOTIFICATION_ACKNOWLEDGMENT => "notification-acknowledgment";

use constant CHECKOUT_REDIRECT => "checkout-redirect";
use constant REDIRECT_URL      => "redirect-url";
use constant ERROR_MESSAGE     => "error-message";

use constant BUYER_LANGUAGE        => "buyer-language";
use constant CALCULATE             => "calculate";
use constant TAX                   => "tax";
use constant METHOD                => "method";
use constant MERCHANT_CODE_STRINGS => "merchant-code-strings";
use constant MERCHANT_CODE_STRING  => "merchant-code-string";
use constant ADDRESSES             => "addresses";
use constant ANONYMOUS_ADDRESS     => "anonymous-address";
use constant RESULTS               => "results";
use constant RESULT                => "result";
use constant ADDRESS_ID            => "address-id";
use constant SHIPPING_RATE         => "shipping-rate";
use constant SHIPPALBE             => "shippable";
use constant VALID                 => "valid";

use constant MERCHANT_CALCULATION_RESULTS  => "merchant-calculation-results";
use constant MERCHANT_CODE_RESULTS         => "merchant-code-results";
use constant COUPON_RESULT                 => "coupon-result";
use constant GIFT_CERTIFICATE_RESULT       => "gift-certificate-result";
use constant GIFT_CERTIFICATE_SUPPORT      => "gift-certificate-support";
use constant GIFT_CERTIFICATE_ACCEPTED     => "gift-certificate-accepted";
use constant GIFT_CERTIFICATE_NAME         => "gift-certificate-name";
use constant GIFT_CERTIFICATE_PIN_REQUIRED => "gift-certificate-pin-required";
use constant GIFT_CERTIFICATE_PIN          => "pin";

#--
#-- Different kinds of notification
#--
use constant CHARGE_AMOUNT_NOTIFICATION      => "charge-amount-notification";
use constant CHARGE_BACK_NOTIFICATION        => "chargeback-amount-notification";
use constant MERCHANT_CALCULATION_CALLBACK   => "merchant-calculation-callback";
use constant NEW_ORDER_NOTIFICATION          => "new-order-notification";
use constant ORDER_STATE_CHANGE_NOTIFICATION => "order-state-change-notification";
use constant REFUND_AMOUNT_NOTIFICATION      => "refund-amount-notification";
use constant RISK_INFORMATION_NOTIFICATION   => "risk-information-notification";

#--
#-- To support Google Analytics
#--
use constant ANALYTICS_DATA => "analytics-data";

#--
#-- To support parameterized URL
#--
use constant PARAMETERIZED_URLS => "parameterized-urls";
use constant PARAMETERIZED_URL  => "parameterized-url";
use constant URL                => "url";
use constant PARAMETERS         => "parameters";
use constant URL_PARAMETER      => "url-parameter";
use constant TYPE               => "type";

use constant PLATFORM_ID => "platform-id";

#--
#-- Digital content delivery
#--
use constant DIGITAL_CONTENT      => "digital-content";
use constant EMAIL_DELIVERY       => "email-delivery";
use constant DOWNLOAD_INSTRUCTION => "description";
use constant DOWNLOAD_KEY         => "key";
use constant DOWNLOAD_URL         => "url";

1;
