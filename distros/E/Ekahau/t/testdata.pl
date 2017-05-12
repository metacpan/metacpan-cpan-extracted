our @test_devices = (
      { 
	  props => {
	      'ECLIENT.WLAN_TECHNOLOGY' => 0,
	      'ECLIENT.WLAN_MODEL' => 'Agere',
	      'ECLIENT.COMMON_INTERNALNAME' => 'Wlan_Agere.dll',
	      'NETWORK.MAC' => '00:10:C6:6A:12:3E',
	      'GROUP' => 'ECLIENT',
	      'NETWORK.DNS_NAME' => '141.212.55.129',
	      'ECLIENT.COMMON_OS_VER' => '4.21.1088',
	      'ECLIENT.COMMON_CLIENTID' => '000ea544c3f5ac51cc7e140b5d8',
	      'NETWORK.IP-ADDRESS' => '141.212.55.129',
	      'ECLIENT.COMMON_CLIENT_VER' => '3.2.198',
	  },
	  location_track => static_location({
	      accurateX => 100,
	      accurateY => 100,
	      accurateContextId => '12345',
	      accurateExpectedError => 1,
	      latestX => 100,
	      latestY => 100,
	      latestContextId => 'ctx1',
	      latestExpectedError => 1,
	      speed => 10,
	      heading => 180,
	  }),
	  area_track => static_area([
				     {
					 name => 'area51',
					 probability => '80.00',
					 contextId => '12345',
					 polygon => '100;75;150&100;75;150',
					 property1 => 'value1',
				     },
				     {
					 name => 'pi_r_squared',
					 probability => '20.00',
					 contextId => '23456',
					 polygon => '200;175;250&200;175;250',
					 property2 => 'value2',
				     },
				     ]),
      });

our %test_ctx = (
	  12345 => {
	      name => '12345',
	      address => "building/floor1",
	      mapScale => '10.00',
	      property1 => 'value1',
	  },
	  23456 => {
	      name => '23456',
	      address => "building/floor2",
	      mapScale => '10.00',
	      property2 => 'value2',
	  }
		 );

our %test_maps = (
    12345 => 'Pretend this is a PNG map file',
    23456 => 'All work and no play makes Jack a dull boy' x 1024,
    34567 => ">\r\n>\n>\r>\r\n>>>\r\n>\r\n\r\n>>><\r\n>\r\n>\r\n>",
);


1;
