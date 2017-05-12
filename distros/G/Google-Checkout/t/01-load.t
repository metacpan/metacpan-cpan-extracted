#!perl -T

use Test::More qw/no_plan/;

BEGIN {
	use_ok( 'Google::Checkout::Command::AddMerchantOrderNumber' );
	use_ok( 'Google::Checkout::Command::AddTrackingData' );
	use_ok( 'Google::Checkout::Command::ArchiveOrder' );
	use_ok( 'Google::Checkout::Command::CancelOrder' );
	use_ok( 'Google::Checkout::Command::ChargeOrder' );
	use_ok( 'Google::Checkout::Command::DeliverOrder' );
	use_ok( 'Google::Checkout::Command::GCOCommand' );
	use_ok( 'Google::Checkout::Command::ProcessOrder' );
	use_ok( 'Google::Checkout::Command::RefundOrder' );
	use_ok( 'Google::Checkout::Command::SendBuyerMessage' );
	use_ok( 'Google::Checkout::Command::UnarchiveOrder' );

        use_ok( 'Google::Checkout::General::ConfigReader' );
        use_ok( 'Google::Checkout::General::Error' );
        use_ok( 'Google::Checkout::General::FlatRateShipping' );
        use_ok( 'Google::Checkout::General::GCO' ); 
        use_ok( 'Google::Checkout::General::MerchantCalculatedShipping' ); 
        use_ok( 'Google::Checkout::General::MerchantCalculationCallback' ); 
        use_ok( 'Google::Checkout::General::MerchantCalculationResult' ); 
        use_ok( 'Google::Checkout::General::MerchantCalculationResults' ); 
        use_ok( 'Google::Checkout::General::MerchantCalculations' ); 
        use_ok( 'Google::Checkout::General::MerchantCheckoutFlow' ); 
        use_ok( 'Google::Checkout::General::MerchantItem' ); 
        use_ok( 'Google::Checkout::General::Pickup' ); 
        use_ok( 'Google::Checkout::General::Shipping' ); 
        use_ok( 'Google::Checkout::General::ShippingRestrictions' ); 
        use_ok( 'Google::Checkout::General::ShoppingCart' ); 
        use_ok( 'Google::Checkout::General::TaxRule' ); 
        use_ok( 'Google::Checkout::General::TaxTableAreas' ); 
        use_ok( 'Google::Checkout::General::TaxTable' ); 
        use_ok( 'Google::Checkout::General::Util' ); 

        use_ok( 'Google::Checkout::Notification::ChargeAmount' ); 
        use_ok( 'Google::Checkout::Notification::ChargebackAmount' ); 
        use_ok( 'Google::Checkout::Notification::Factory' ); 
        use_ok( 'Google::Checkout::Notification::GCONotification' ); 
        use_ok( 'Google::Checkout::Notification::NewOrder' ); 
        use_ok( 'Google::Checkout::Notification::OrderStateChange' ); 
        use_ok( 'Google::Checkout::Notification::RefundAmount' ); 
        use_ok( 'Google::Checkout::Notification::RiskInformation' );
 
        use_ok( 'Google::Checkout::XML::CheckoutXmlWriter' ); 
        use_ok( 'Google::Checkout::XML::CommandXmlWriter' ); 
        use_ok( 'Google::Checkout::XML::Constants' ); 
        use_ok( 'Google::Checkout::XML::NotificationResponseXmlWriter' ); 
        use_ok( 'Google::Checkout::XML::Writer' ); 
}
