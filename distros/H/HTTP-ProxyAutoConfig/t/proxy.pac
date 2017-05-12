// from HTTP::ProxyPAC testing
function FindProxyForURL(url,host)
{
	// loopback
	if ( host == "127.0.0.1" || host == "localhost" )
		return "DIRECT";

	if ( dnsDomainIs(host, "intra.example.com") )
	    // with ProxyAutoConfig, proxies have to answer to be returned
		return "PROXY google.com:80; DIRECT";
	if ( isInNet(host, "192.168.108.0", "255.255.255.0") )
		return "PROXY yahoo.com:80";
	return "DIRECT";
}
