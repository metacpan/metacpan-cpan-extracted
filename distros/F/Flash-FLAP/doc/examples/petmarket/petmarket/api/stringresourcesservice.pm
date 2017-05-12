package petmarket::api::stringresourcesservice;


# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

#This is server side for the Macromedia's Petmarket example.
#See http://www.simonf.com/flap for more information.

use warnings;
use strict;

my %bundle;

sub new
{
    my ($proto) = @_;
    my $self = {};
    bless $self, $proto;
    return $self;
}


sub methodTable
{
    return {
        "getAppStrings" => {
            "description" => "Returns app strings",
            "access" => "remote", 
        },
        "getAboutUsStrings" => {
            "description" => "Returns 'about us' strings",
            "access" => "remote", 
        },
        "getLegalStrings" => {
            "description" => "Returns legal strings",
            "access" => "remote", 
        },
        "getAffiliateStrings" => {
            "description" => "Returns affiliate strings",
            "access" => "remote", 
        },	
    };
    
}

sub getAppStrings 
{
    my ($self, $locale) = @_;

    unless (%bundle) 
    {
        my %strings; 

        $strings{"HOME_MODE_TITLE_str"}="Home";
        $strings{"BROWSE_MODE_TITLE_str"}="Browse";
        $strings{"CHECKOUT_MODE_TITLE_str"}="Checkout";
        $strings{"WELCOME_PREFIX_HD_str"}="Welcome to ";
        $strings{"WELCOME_BODY_str"}="Welcome to your online source for pets and pet supplies. Whether you're looking for information or ready to buy, we've created a fun and easy shopping experience. The site is tailored to your interests, so as you browse for pets, you'll see the products and accessories your pet might need. Come back often. There's always something new!";
        $strings{"CHOOSE_ITEM_HINT_str"}="Choose your pet from the list above!";
        $strings{"ADD_ITEM_TO_CART_HINT_str"}="Press the button below or drag this item to your cart!";
        $strings{"ITEM_UNAVAILABLE_HINT_str"}="Unfortunately, we're currently out of stock, please check back soon.";
        $strings{"SEARCH_NO_RESULTS_FOUND_FOR_str"}="no results found for: ";
        $strings{"QTY_AVAILABLE_LBL_str"}="Quantity Available:";
        $strings{"CURRENCY_SYMBOL_str"}="\$";
        $strings{"CURRENCY_DECIMAL_str"}=".";
        $strings{"THOUSANDS_SEPARATOR_str"}="}=";
        $strings{"ITEM_LBL_str"}="Item";
        $strings{"PRICE_LBL_str"}="Price";
        $strings{"QTY_AVAILABLE_LBL_str"}="Qty Available";
        $strings{"QTY_LBL_str"}="Qty";
        $strings{"PRODUCT_LBL_str"}="Product";
        $strings{"ITEMS_IN_CART_LBL_str"}="Items:";
        $strings{"CART_SUBTOTAL_LBL_str"}="Subtotal:";
        $strings{"ADVERT_COPY_DEFAULT_str"}="Keep your pets healthy and happy with\n Pet Market brand pet foods.";
        $strings{"ADVERT_COPY_CONTEXT_str"}="Keep your pet healthy! Try our special formula of pet foods, available in assorted sizes and flavors.";
        $strings{"OK_BTN_LBL_str"}="OK";
        $strings{"EXCEEDS_AVAILABLE_MB_MSG_str"}="The quantity you entered exceeds the number we currently have available. The quantity will be automatically reset to the maximum available at this time.";
        $strings{"EXCEEDS_AVAILABLE_MB_TTL_str"}="Quantity Available Exceeded";
        $strings{"REQUIRED_FIELD_INDICATOR_str"}="*";
        $strings{"ERROR_FIELD_INDICATOR_str"}="<";
        $strings{"NUMBER_SYMBOL_str"}="-";
        $strings{"DATE_SEPARATOR_str"}="/";
        $strings{"ADDRESS_LBL_str"}="Address:";
        $strings{"CITY_LBL_str"}="City:";
        $strings{"STATE_LBL_str"}="State:";
        $strings{"ZIP_LBL_str"}="Zip / Postal Code:";
        $strings{"EMAIL_LBL_str"}="E-mail:";
        $strings{"PHONE_LBL_str"}="Phone:";
        $strings{"CC_NUMBER_LBL_str"}="Credit Card Number:";
        $strings{"CC_EXPIRATION_DATE_LBL_str"}="Expiration Date:";
        $strings{"PROFILE_FLDS_HINT_str"}="If you're a new customer, please provide your email address and a password in order to create your account.  Returning customers, log in using your email address and password.";
        $strings{"PROFILE_FLDS_LOGOUT_1_HINT_str"}="You are currently logged in with the E-mail address: ";
        $strings{"PROFILE_FLDS_LOGOUT_2_HINT_str"}="If this is not correct, you may log in to your existing account or create a new one.";
        $strings{"PROFILE_FLDS_LOGOUT_EDIT_LBL_str"}="Edit";
        $strings{"PASSWORD_LBL_str"}="Password:";
        $strings{"PASSWORD_CONFIRM_LBL_str"}="Confirm Password:";
        $strings{"CREATE_ACCOUNT_BTN_LBL_str"}="Create Account";
        $strings{"LOGIN_BTN_LBL_str"}="Login";
        $strings{"CONTINUE_BTN_LBL_str"}="Continue";
        $strings{"NEW_CUSTOMER_TRUE_RB_LBL_str"}="New Customer";
        $strings{"NEW_CUSTOMER_FALSE_RB_LBL_str"}="Returning Customer";
        $strings{"BILLING_FLDS_HINT_str"}="Please enter your billing address.";
        $strings{"SHIPPING_FLDS_HINT_str"}="Please enter your shipping address.";
        $strings{"USE_THIS_FOR_SHIPPING_CH_LBL_str"}="Use this address for shipping";
        $strings{"USE_BILLING_FOR_SHIPPING_CH_LBL_str"}="Use billing address for shipping";
        $strings{"EDIT_LBL_str"}="Edit";
        $strings{"CHECKOUT_USER_HD_str"}="1) Welcome";
        $strings{"CHECKOUT_BILLING_HD_str"}="2) Customer Details / Billing Address";
        $strings{"CHECKOUT_SHIPPING_HD_str"}="3) Shipping Address";
        $strings{"CHECKOUT_SHIPPING_METHOD_HD_str"}="4) Shipping Options & Promotions";
        $strings{"CHECKOUT_PAYMENT_HD_str"}="5) Payment Method & Confirmation";
        $strings{"SHIPPING_METHODS_FLDS_HINT_str"}="Please select your preferred shipping method.  If you were provided a promotional code, enter it here.";
        $strings{"SHIPPING_METHOD_LBL_str"}="Shipping Method:";
        $strings{"PROMOTION_CODE_LBL_str"}="Promotion Code:";
        $strings{"EST_DELIVERY_DATE_LBL_str"}="Estimated delivery date:";
        $strings{"CHECKOUT_SUBMIT_BTN_LBL_str"}="Place Order";
        $strings{"PAYMENT_METHOD_LBL_str"}="Credit Card Type:";
        $strings{"PAYMENT_METHODS_HINT_str"}="Please review the billing and shipping information you entered above.  Make changes by clicking the Edit button.\n\nComplete your purchase by clicking the Place Order button.";
        $strings{"CHECKOUT_EXIT_BTN_LBL_str"}="Exit Checkout";
        $strings{"ADD_TO_CART_BTN_LBL_str"}="Add To Cart";
        $strings{"HISTORY_WIDGET_LBL_str"}="history";
        $strings{"SEARCH_WIDGET_LBL_str"}="search";
        $strings{"SEARCH_WIDGET_BTN_LBL_str"}="go";
        $strings{"CART_WIDGET_LBL_str"}="cart";
        $strings{"CART_REMOVE_BTN_LBL_str"}="Remove Item";
        $strings{"CART_CHECKOUT_BTN_LBL_str"}="Checkout";
        $strings{"CART_CONTINUE_BTN_LBL_str"}="Shop More";
        $strings{"STATE_CB_NON_US_LBL_str"}="State / Provence:";
        $strings{"STATE_CB_US_LBL_str"}="State:";
        $strings{"COUNTRY_CB_LBL_str"}="Country:";
        $strings{"FULL_NAME_LBL_str"}="Full name:";
        $strings{"FIRST_NAME_LBL_str"}="First name:";
        $strings{"LAST_NAME_LBL_str"}="Last name:";
        $strings{"CHECKOUT_GROUP_HD_str"}="Checkout";
        $strings{"CHARGE_SUMMARY_HD_str"}="Charge Summary";
        $strings{"CHARGE_SUMMARY_HINT_str"}="Please review all charges listed below before completing your purchase.\n\nMake sure that you have selected your preferred shipping method and entered any promotional codes that may entitle you to a discount.";
        $strings{"CHARGE_SUMMARY_SUBTOTAL_LBL_str"}="Cart Subtotal:";
        $strings{"CHARGE_SUMMARY_PROMOTIONS_LBL_str"}="Promotions:";
        $strings{"CHARGE_SUMMARY_SHIPPING_LBL_str"}="Shipping Charges:";
        $strings{"CHARGE_SUMMARY_TAX_LBL_str"}="Taxes:";
        $strings{"CHARGE_SUMMARY_GRAND_TOTAL_LBL_str"}="Total Charges:";
        $strings{"VALIDATE_EMAIL_ERR_TITLE_str"}="E-mail not valid";
        $strings{"VALIDATE_EMAIL_ERR_MSG_str"}="E-mail entered is not valid.\nPlease try again.";
        $strings{"VALIDATE_PASS_ERR_TITLE_str"}="Password invalid";
        $strings{"VALIDATE_PASS_MISMATCH_ERR_MSG_str"}="Passwords do not match.\nPlease try again.";
        $strings{"VALIDATE_PASS_INVALID_ERR_MSG_str"}="Invalid password.\nPlease try again.";
        $strings{"VALIDATE_CREATE_USER_FAILED_TITLE_str"}="Failed to create user";
        $strings{"VALIDATE_CREATE_USER_FAILED_MSG_str"}="An account using this E-mail address already exists.";
        $strings{"VALIDATE_LOGIN_USER_FAILED_TITLE_str"}="Failed to log in";
        $strings{"VALIDATE_LOGIN_USER_FAILED_MSG_str"}="Unable to log in.\nPlease check the E-mail address and password and try again.";
        $strings{"VALIDATE_FIRST_NAME_ERROR_MSG_str"}="Please type in your first name.";
        $strings{"VALIDATE_FIRST_NAME_ERROR_TITLE_str"}="Invalid first name";
        $strings{"VALIDATE_LAST_NAME_ERROR_MSG_STR"}="Please type in your last name.";
        $strings{"VALIDATE_LAST_NAME_ERROR_TITLE_STR"}="Invalid last name";
        $strings{"VALIDATE_ADDRESS_ERROR_MSG_str"}="Please type in an address.";
        $strings{"VALIDATE_ADDRESS_ERROR_TITLE_str"}="Invalid address";
        $strings{"VALIDATE_CITY_ERROR_MSG_str"}="Please type in a city.";
        $strings{"VALIDATE_CITY_ERROR_TITLE_str"}="Invalid city";
        $strings{"VALIDATE_ZIPCODE_ERROR_MSG_str"}="Please enter a valid 5 digit Zip code.";
        $strings{"VALIDATE_ZIPCODE_ERROR_TITLE_str"}="Invalid Zip code";
        $strings{"VALIDATE_PHONE_ERROR_MSG_str"}="Please enter a valid 10 digit telephone number.";
        $strings{"VALIDATE_PHONE_ERROR_TITLE_str"}="Invalid phone number";
        $strings{"VALIDATE_SELECT_CC_TYPE_ERROR_MSG_str"}="Please select a credit card from the list.";
        $strings{"VALIDATE_SELECT_CC_MO_ERROR_MSG_str"}="Please select a credit card expiry month from the list.";
        $strings{"VALIDATE_SELECT_CC_YR_ERROR_MSG_str"}="Please select a credit card expiry year from the list.";
        $strings{"VALIDATE_CC_EXPIRED_ERROR_MSG_str"}="Please select a credit card expiry date that is not in the past.";
        $strings{"VALIDATE_INVALID_CC_ERROR_MSG_str"}="Invalid credit card number.  Please enter valid credit card number.";
        $strings{"VALIDATE_PAYMENT_ERROR_TITLE_str"}="Payment Method Error";
        $strings{"CREATE_USER_PROGRESS_TITLE_str"}="Creating account";
        $strings{"CREATE_USER_PROGRESS_MSG_str"}="Account creation in progress, please wait.";
        $strings{"LOGIN_USER_PROGRESS_TITLE_str"}="Logging in";
        $strings{"LOGIN_USER_PROGRESS_MSG_str"}="Login in progress, please wait.";
        $strings{"SUBMITTING_ORDER_PROGRESS_TITLE_str"}="Submitting order";
        $strings{"SUBMITTING_USER_PROGRESS_MSG_str"}="Order submission in progress: sending user data.\n\nPlease wait.";
        $strings{"SUBMITTING_ORDER_PROGRESS_MSG_str"}="Order submission in progress: sending order info.\n\nPlease wait.";
        $strings{"CONFIRM_ORDER_TITLE_str"}="Thank You";
        $strings{"CONFIRM_ORDER_MSG_str"}="Thank you for shopping at Pet Market.  If this were a real pet store, your order would be completed.";
        $strings{"AFFILIATE_BTN_LBL_str"}="affiliate program";
        $strings{"LEGAL_NOTICES_BTN_LBL_str"}="legal notices";
        $strings{"ABOUT_US_BTN_LBL_str"}="about us";
        $strings{"HOME_BTN_LBL_str"}="home";
        $strings{"EXP_MONTH_CHOOSE_str"}="Month...";
        $strings{"EXP_YEAR_CHOOSE_str"}="Year...";
        

        my @monthNums = ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12");
        my @months = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
        my @weekdays = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday");
        my @years = ("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010");
        
        $strings{"MONTH_NUMS_array"}=\@monthNums;
        $strings{"MONTH_NAMES_array"}=\@months;
        $strings{"WEEKDAY_NAMES_array"}=\@weekdays;
        $strings{"EXP_YEARS_array"}=\@years;
                        
        %bundle = %strings;
    }
    
    return \%bundle;
}

sub getAboutUsStrings()
{
    my ($self) = @_;
    
    my %strings;
    $strings{"HEAD_str"} = "ABOUT US";
    $strings{"BODY_HTML_str"} = "The Pet Market application illustrates how Macromedia MX products work together, and integrate with standard server technologies, to deliver a rich, dynamic Internet application.\n\nWith a demo, code samples, development guidelines, and tutorials, your team can quickly download and access the necessary pieces to build a complete end-to-end application.";
    $strings{"logoFrameLabel"} = "macr";
    $strings{"url"} = "http://www.macromedia.com";
    
    return \%strings;
}

sub getLegalStrings()
{
    my ($self) = @_;
    my %strings;
    $strings{"HEAD_str"} = "LEGAL INFORMATION";
    $strings{"BODY_HTML_str"} = "Copyright © 2001-2002 Macromedia, Inc.  All rights reserved.  Macromedia, the Macromedia logo, and Flash are trademarks or registered trademarks of Macromedia, Inc.\n \nMany of the images used in this experience were provided by PhotoSpin. Check out their complete library at <font color='\"336699'><a href='http://www.photospin.com' target='_blank'>www.photospin.com.</a></font>";
    $strings{"logoFrameLabel"} = "macr";
    $strings{"url"} = "http://www.macromedia.com";
    
    return \%strings;
}


sub getAffiliateStrings()
{
    my ($self) = @_;
    my %strings;
    $strings{"HEAD_str"} = "SITE DESIGN";
    $strings{"BODY_HTML_str"} = "We chose Popular Front to design the Pet Market shopping experience because of their demonstrated ability to enhance user experiences with our technologies. Popular Front has created numerous award-winning solutions to help businesses and organizations reach audiences and build vital customer relationships. Their creative use of Macromedia technologies has included B2B, B2C, and B2E solutions.\n\nTo learn more about Popular Front, visit <font color='\"336699'><a href='http://www.popularfront.com' target='_blank'>www.popularfront.com.</a></font>";
    $strings{"logoFrameLabel"} = "PopularFront";
    $strings{"url"} = "http://www.popularfront.com";
    
    return \%strings;
}



1;
