#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/ethtool.h>
#include <linux/sockios.h>

static int _do_ioctl(const char *dev, void *data)
{
	int sock = socket(AF_INET, SOCK_DGRAM, 0);
	if(sock == -1)
	{
		return 0;
	}
	
	struct ifreq ifr;
	strcpy(ifr.ifr_name, dev);
	ifr.ifr_data = data;
	
	if(ioctl(sock, SIOCETHTOOL, &ifr) == -1)
	{
		close(sock);
		return 0;
	}
	
	close(sock);
	return 1;
}
