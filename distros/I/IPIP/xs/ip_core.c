#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/stat.h>

struct ipip_s
{
	unsigned char *buffer;
	unsigned char *data;
	unsigned char * offset;
	unsigned int buffer_len;
	unsigned int index;

	unsigned char *last_boundary;
}ipip_info;

int ip_init(char *path)
{
	struct stat st;
	unsigned long filesize = -1;  
	//printf("enter ip_init %s\n",path);
	if (stat(path, &st) == -1) {
		return errno;
	}
	filesize=st.st_size;
	if(filesize>60*1024*1024)
	{
		return EFBIG ;
	}
	int fd=open(path,O_RDONLY);
	if(fd<=0)
	{
		return errno;
	}
	unsigned char *buffer=(unsigned char *)malloc(filesize);
	ssize_t nread=read(fd,buffer,filesize);
	if(nread<filesize)
	{
		return errno;
	}
	close(fd);
	
	int index_len=(buffer[0]<<24)+(buffer[1]<<16)+(buffer[2]<<8)+buffer[3];
	if(index_len>filesize)
	{
		free(buffer);
		return -1;	//文件不完整
	}
	struct ipip_s ipip_bak=ipip_info;
	memset(&ipip_info,0,sizeof(ipip_info));
	ipip_info.buffer=buffer;
	ipip_info.buffer_len=filesize;
	ipip_info.offset=buffer+index_len;
	ipip_info.last_boundary=buffer+filesize;
		
	char temp[16];
	if(ip_datx_find("255.255.255.255",temp,sizeof(temp))<0)
	{
		ipip_info=ipip_bak;
		free(buffer);
		return -2;	//文件不完整
	}
	free(ipip_bak.buffer);
	return 0;
}

void ip_dat_find_u(unsigned int uip,char *output,int output_len)
{
	unsigned char * fip_pos = ipip_info.buffer + 4 + (uip>>24)*4;
	int start = (fip_pos[3]<<24)+
				(fip_pos[2]<<16)+
				(fip_pos[1]<<8)+
				fip_pos[0];	//start
	unsigned char *start_pos=ipip_info.buffer+1028;
//	max_comp_len = ipip_info.offset - buffer - 1028
	unsigned char *end_pos = ipip_info.offset-1028;
	int index_offset = 0 , index_length = 0;
	for (start_pos=start_pos+start*8; start_pos<end_pos; start_pos+=8)
	{
		unsigned int cip = 0;
		memcpy(&cip, start_pos, 4);
		cip = ntohl(cip);
		if (cip >= uip) 
		{
			index_offset=(start_pos[6]<<16)+
						(start_pos[5]<<8)+
						start_pos[4];
			index_length=start_pos[7];
			unsigned char *res_offset = ipip_info.offset + index_offset - 1024;
			int len=index_length<(output_len-1)?index_length:(output_len-1);
			memcpy(output,res_offset,len);
			output[len]='\0';
			break;
		}
	}
}

void ip_dat_find(char* str_ip,char *output,int output_len)
{
	struct sockaddr_in sockaddr={0};
	if(output_len<=0)
	{
		return;
	}
	if(inet_aton(str_ip, &sockaddr.sin_addr) == 0)
	{
		memset(output,'\t',output_len-1);
		output[output_len-1]=0;
		return ;
	}
	unsigned int uip = ntohl(sockaddr.sin_addr.s_addr);
	return ip_dat_find_u(uip,output,output_len);
}

int ip_datx_find_u(unsigned int uip,char *output,int output_len)
{
	unsigned char * fip_pos = ipip_info.buffer + 4 + (uip>>16)*4;
	int start = (fip_pos[3]<<24)+
				(fip_pos[2]<<16)+
				(fip_pos[1]<<8)+
				fip_pos[0];	//start
	unsigned char *start_pos=ipip_info.buffer+256*1024+4;	//9+262144
	unsigned char *end_pos = ipip_info.offset-256*1024-4;
	int index_offset = 0 , index_length = 0;
	for (start_pos=start_pos+start*9; start_pos<end_pos; start_pos+=9)
	{
		unsigned int cip = 0;
		memcpy(&cip, start_pos, 4);
		cip = ntohl(cip);
		if (cip >= uip) 
		{
			index_offset=(start_pos[6]<<16)+
						(start_pos[5]<<8)+
						start_pos[4];
			index_length=(start_pos[7]<<8)+start_pos[8];
			unsigned char *res_offset = ipip_info.offset + index_offset - 262144;
			if(res_offset+index_length>ipip_info.last_boundary)
			{
			//	printf("error last_boundary=%d\n",index_offset);
				memset(output,'\t',output_len-1);				
				output[output_len-1]=0;
				return -1;
			}
			int len=index_length<(output_len-1)?index_length:(output_len-1);
			memcpy(output,res_offset,len);
			output[len]=0;
			break;
		}
	}
	return 0;
}

int ip_datx_find(char* str_ip,char *output,int output_len)
{
	struct sockaddr_in sockaddr={0};
	if(output_len<=0)
	{
		return -1;
	}
	if(inet_aton(str_ip, &sockaddr.sin_addr) == 0)
	{
		memset(output,'\t',output_len-1);
		output[output_len-1]=0;
		return -1;
	}
	unsigned int uip = ntohl(sockaddr.sin_addr.s_addr);
	return ip_datx_find_u(uip,output,output_len);
}

int ip_datx()
{
	char buffer[512];	
	int i=0;
	ip_init("./17monipdb.datx");
	srand(time(NULL));
	for(i=0;i<2000*10000;i++)
	{
		unsigned int x=rand();
		ip_datx_find_u(x<<1,buffer,512);
	}	
	return 0;
}
int ip_dat()
{
	char buffer[512];	
	int i=0;
	ip_init("./17monipdb.dat");
	srand(time(NULL));
	for(i=0;i<100*10000;i++)
	{
		unsigned int x=rand();
		ip_dat_find_u(x<<1,buffer,256);
	}
	return 0;
}

