#!perl

use Test::More tests => 42;

BEGIN {
    use_ok( 'HiPi' );
    use_ok( 'HiPi::RaspberryPi' );
    use_ok( 'HiPi::Constant' );
    use_ok( 'HiPi::Energenie' );
    use_ok( 'HiPi::Device' );
    use_ok( 'HiPi::Interface' );
    use_ok( 'HiPi::Pin' );
    use_ok( 'HiPi::Energenie::Command' );
    use_ok( 'HiPi::Energenie::ENER314' );
    use_ok( 'HiPi::Energenie::ENER314_RT' );
    use_ok( 'HiPi::Device::GPIO' );
    use_ok( 'HiPi::Device::GPIO::Pin' );
    use_ok( 'HiPi::Device::I2C' );
    use_ok( 'HiPi::Device::OneWire' );
    use_ok( 'HiPi::Device::SerialPort' );
    use_ok( 'HiPi::Device::SPI' );
    use_ok( 'HiPi::GPIO' );
    use_ok( 'HiPi::GPIO::Pin' );
    use_ok( 'HiPi::Interface::DS18X20' );
    use_ok( 'HiPi::Interface::EnergenieSwitch' );
    use_ok( 'HiPi::Interface::ENER002' );
    use_ok( 'HiPi::Interface::HobbyTronicsADC' );
    use_ok( 'HiPi::Interface::HobbyTronicsBackpackV2' );
    use_ok( 'HiPi::Interface::HTADCI2C' );
    use_ok( 'HiPi::Interface::HTBackpackV2' );
    use_ok( 'HiPi::Interface::HopeRF69' );
    use_ok( 'HiPi::Interface::MCP23017' );
    use_ok( 'HiPi::Interface::MCP23S17' );
    use_ok( 'HiPi::Interface::MCP3ADC' );
    use_ok( 'HiPi::Interface::MCP3004' );
    use_ok( 'HiPi::Interface::MCP3008' );
    use_ok( 'HiPi::Interface::MCP4DAC' );
    use_ok( 'HiPi::Interface::MCP49XX' );
    use_ok( 'HiPi::Interface::MPL3115A2' );
    use_ok( 'HiPi::Interface::PCA9685' );
    use_ok( 'HiPi::Interface::SerLCD' );
    use_ok( 'HiPi::Interface::Si470N' );
    use_ok( 'HiPi::RF::OpenThings' );
    use_ok( 'HiPi::RF::OpenThings::Message' );
    use_ok( 'HiPi::Utils::Exec' );
    use_ok( 'HiPi::Utils::Config' );
    use_ok( 'HiPi::Utils' );
}

1;
