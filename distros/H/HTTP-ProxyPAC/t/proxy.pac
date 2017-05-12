function FindProxyForURL(url,host)
{
	// loopback
	if ( host == "127.0.0.1" || host == "localhost" )
		return "DIRECT";

	if ( dnsDomainIs(host, "intra.example.com") )
		return "PROXY proxy.example.jp:8080; DIRECT";
	if ( isInNet(host, "192.168.108.0","255.255.255.0") )
		return "PROXY proxy.example.jp:8080";
	return "DIRECT";
}
