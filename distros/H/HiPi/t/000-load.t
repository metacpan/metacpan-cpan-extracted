#!perl

use Test::More tests => 77;

BEGIN {
    use_ok( 'HiPi' );
    use_ok( 'HiPi::RaspberryPi' );
    use_ok( 'HiPi::Constant' );
    use_ok( 'HiPi::Device' );
    use_ok( 'HiPi::Interface' );
    use_ok( 'HiPi::Pin' );
    use_ok( 'HiPi::Device::GPIO' );
    use_ok( 'HiPi::Device::GPIO::Pin' );
    use_ok( 'HiPi::Device::I2C' );
    use_ok( 'HiPi::Device::OneWire' );
    use_ok( 'HiPi::Device::SerialPort' );
    use_ok( 'HiPi::Device::SPI' );
    use_ok( 'HiPi::Energenie' );
    use_ok( 'HiPi::Energenie::Command' );
    use_ok( 'HiPi::Energenie::ENER314' );
    use_ok( 'HiPi::Energenie::ENER314_RT' );
    use_ok( 'HiPi::Graphics::BitmapFont' );
    use_ok( 'HiPi::Graphics::DrawingContext' );
    use_ok( 'HiPi::GPIO' );
    use_ok( 'HiPi::GPIO::Pin' );
    use_ok( 'HiPi::Interface::BME280' );
    use_ok( 'HiPi::Interface::DS18X20' );
    use_ok( 'HiPi::Interface::EnergenieSwitch' );
    use_ok( 'HiPi::Interface::ENER002' );
    use_ok( 'HiPi::Interface::EPaper' );
    use_ok( 'HiPi::Interface::EPaper::DisplayBuffer' );
    use_ok( 'HiPi::Interface::EPaper::Pimoroni::EPDInkyPHAT_V2' );
    use_ok( 'HiPi::Interface::EPaper::TypeA' );
    use_ok( 'HiPi::Interface::EPaper::TypeB' );
    use_ok( 'HiPi::Interface::EPaper::Waveshare::EPD152X152' );
    use_ok( 'HiPi::Interface::EPaper::Waveshare::EPD200X200' );
    use_ok( 'HiPi::Interface::EPaper::Waveshare::EPD200X200B' );
    use_ok( 'HiPi::Interface::EPaper::Waveshare::EPD212X104' );
    use_ok( 'HiPi::Interface::EPaper::Waveshare::EPD250X122' );
    use_ok( 'HiPi::Interface::EPaper::Waveshare::EPD296X128' );
    use_ok( 'HiPi::Interface::EPaper::Waveshare::EPD296X128B' );
    use_ok( 'HiPi::Interface::HobbyTronicsADC' );
    use_ok( 'HiPi::Interface::HobbyTronicsBackpackV2' );
    use_ok( 'HiPi::Interface::HopeRF69' );
    use_ok( 'HiPi::Interface::HTADCI2C' );
    use_ok( 'HiPi::Interface::HTBackpackV2' );
    use_ok( 'HiPi::Interface::IS31FL3730' );
    use_ok( 'HiPi::Interface::LCDBackpackPCF8574' );
    use_ok( 'HiPi::Interface::MAX7219' );
    use_ok( 'HiPi::Interface::MAX7219LEDStrip' );
    use_ok( 'HiPi::Interface::MCP23017' );
    use_ok( 'HiPi::Interface::MCP23S17' );
    use_ok( 'HiPi::Interface::MCP3ADC' );
    use_ok( 'HiPi::Interface::MCP3004' );
    use_ok( 'HiPi::Interface::MCP3008' );
    use_ok( 'HiPi::Interface::MCP4DAC' );
    use_ok( 'HiPi::Interface::MCP49XX' );
    use_ok( 'HiPi::Interface::MFRC522' );
    use_ok( 'HiPi::Interface::MicroDotPHAT' );
    use_ok( 'HiPi::Interface::MicroDotPHAT::Font' );
    use_ok( 'HiPi::Interface::MonoOLED' );
    use_ok( 'HiPi::Interface::MonoOLED::DisplayBuffer' );
    use_ok( 'HiPi::Interface::MPL3115A2' );
    use_ok( 'HiPi::Interface::MS5611' );
    use_ok( 'HiPi::Interface::PCA9544' );
    use_ok( 'HiPi::Interface::PCA9685' );
    use_ok( 'HiPi::Interface::PCF8574' );
    use_ok( 'HiPi::Interface::Seesaw' );
    use_ok( 'HiPi::Interface::SerLCD' );
    use_ok( 'HiPi::Interface::Si470N' );
    use_ok( 'HiPi::Interface::TMP102' );
    use_ok( 'HiPi::Interface::ZeroSeg' );
    use_ok( 'HiPi::RF::OpenThings' );
    use_ok( 'HiPi::RF::OpenThings::Message' );
    use_ok( 'HiPi::Utils::Exec' );
    use_ok( 'HiPi::Utils::Config' );
    use_ok( 'HiPi::Utils' );
}

SKIP: {
    skip 'not linux system', 5 if $^O !~ /^linux/i;
    
    diag('Linux load dependency tests are running');
    
    use_ok( 'HiPi::Utils::OLEDFont' );
    use_ok( 'HiPi::Huawei::E3531' );
    use_ok( 'HiPi::Huawei::Errors' );
    use_ok( 'HiPi::Huawei::HiLink' );
    use_ok( 'HiPi::Huawei::Modem' );
}

1;
