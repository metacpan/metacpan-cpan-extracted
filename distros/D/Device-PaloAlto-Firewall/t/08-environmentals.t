#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 3;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# VM Env
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( env_vm() )->simplify( forcearray => ['entry'] )->{result} } );

warning_is { $test->environmentals() } "No environmentals - is this a VM? Returning success", "VM environmentals warns";
{ 
    # Supress the warning output
    no warnings 'redefine';
    local *Device::PaloAlto::Firewall::Test::carp = sub { };
    ok( $test->environmentals(), "Environmentals on a VM returns true");
}

# 5060 Env no alarms
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( env_5060() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->environmentals(), "Environmentals with no alarms" );

sub env_vm {
    return <<'END'
<response status="success"><result/></response>
END
}

sub env_5060 {
   return <<'END'
<response status="success"><result>
  <fantray>
    <Slot1>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <Inserted>True</Inserted>
        <description>Fan Tray</description>
        <min>1</min>
      </entry>
    </Slot1>
  </fantray>
  <power-supply>
    <Slot1>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <Inserted>True</Inserted>
        <description>Power Supply #1 (left)</description>
        <min>True</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <Inserted>True</Inserted>
        <description>Power Supply #2 (right)</description>
        <min>True</min>
      </entry>
    </Slot1>
  </power-supply>
  <thermal>
    <Slot1>
      <entry>
        <slot>1</slot>
        <description>Temperature @ 10G Phys [U171]</description>
        <min>5.0</min>
        <max>60.0</max>
        <alarm>False</alarm>
        <DegreesC>34.5</DegreesC>
      </entry>
      <entry>
        <slot>1</slot>
        <description>Temperature @ Jaguar [U172]</description>
        <min>5.0</min>
        <max>60.0</max>
        <alarm>False</alarm>
        <DegreesC>46.0</DegreesC>
      </entry>
      <entry>
        <slot>1</slot>
        <description>Temperature @ Tiger [U173]</description>
        <min>5.0</min>
        <max>60.0</max>
        <alarm>False</alarm>
        <DegreesC>43.0</DegreesC>
      </entry>
      <entry>
        <slot>1</slot>
        <description>Temperature @ Dune [U174]</description>
        <min>5.0</min>
        <max>60.0</max>
        <alarm>False</alarm>
        <DegreesC>36.2</DegreesC>
      </entry>
    </Slot1>
  </thermal>
  <fan>
    <Slot1>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #1 RPM</description>
        <RPMs>6136</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #2 RPM</description>
        <RPMs>5336</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #3 RPM</description>
        <RPMs>6145</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #4 RPM</description>
        <RPMs>5421</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #5 RPM</description>
        <RPMs>6164</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #6 RPM</description>
        <RPMs>5321</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #7 RPM</description>
        <RPMs>6136</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #8 RPM</description>
        <RPMs>5421</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #9 RPM</description>
        <RPMs>6099</RPMs>
        <min>2500</min>
      </entry>
      <entry>
        <slot>1</slot>
        <alarm>False</alarm>
        <description>Fan #10 RPM</description>
        <RPMs>5450</RPMs>
        <min>2500</min>
      </entry>
    </Slot1>
  </fan>
  <power>
    <Slot1>
      <entry>
        <slot>1</slot>
        <description>1.0V Power Rail</description>
        <min>0.9</min>
        <Volts>1.00066666667</Volts>
        <alarm>False</alarm>
        <max>1.1</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>1.2V Power Rail</description>
        <min>1.08</min>
        <Volts>1.17533333333</Volts>
        <alarm>False</alarm>
        <max>1.32</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>1.8V Power Rail</description>
        <min>1.62</min>
        <Volts>1.778</Volts>
        <alarm>False</alarm>
        <max>1.98</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>2.5V Power Rail</description>
        <min>2.25</min>
        <Volts>2.456</Volts>
        <alarm>False</alarm>
        <max>2.75</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>3.3V Power Rail</description>
        <min>2.97</min>
        <Volts>3.33333333333</Volts>
        <alarm>False</alarm>
        <max>3.63</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>5.0V Power Rail</description>
        <min>4.5</min>
        <Volts>5.018</Volts>
        <alarm>False</alarm>
        <max>5.5</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>1.15V Power Rail</description>
        <min>1.035</min>
        <Volts>1.15</Volts>
        <alarm>False</alarm>
        <max>1.265</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>1.1V Power Rail</description>
        <min>0.99</min>
        <Volts>1.102</Volts>
        <alarm>False</alarm>
        <max>1.21</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>1.05V Power Rail</description>
        <min>0.945</min>
        <Volts>1.06133333333</Volts>
        <alarm>False</alarm>
        <max>1.155</max>
      </entry>
      <entry>
        <slot>1</slot>
        <description>3.3V_SD Power Rail</description>
        <min>2.97</min>
        <Volts>3.32266666667</Volts>
        <alarm>False</alarm>
        <max>3.63</max>
      </entry>
    </Slot1>
  </power>
</result></response>
END
}
