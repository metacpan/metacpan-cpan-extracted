#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define BASE 65521
#define BLOCK_SIZE 10240
#ifdef __cplusplus
}
#endif


MODULE = Digest::XSAdler32	PACKAGE = Digest::XSAdler32		

unsigned long
update_adler32(fp,offset,size)
        FILE * fp
        unsigned long offset
        unsigned long size
    CODE:
        unsigned long m_s1, m_s2;
        m_s1 = 1; m_s2 = 0;
        unsigned int fd = fileno(fp);
        off_t seekpos = lseek(fd, offset, SEEK_SET);
        if(seekpos < 0) 
        {
            RETVAL = -1;
            exit(-1);
        }

        char *buf = (char*) malloc(sizeof(char) * BLOCK_SIZE);
        void* orig_pos = buf;

        memset(buf, '\0', BLOCK_SIZE);
        unsigned long readAmt = 0;
        while(readAmt < size) 
        {
            buf = orig_pos;
            
            unsigned long toRead;
            if ( (readAmt + BLOCK_SIZE) > size ) 
            {
                toRead = (size - readAmt);
            }
            else 
            {
                toRead = BLOCK_SIZE;
            }
            

            int length = read(fd, buf, toRead);
            if(length < 1) {
                break;
            }
            readAmt = readAmt + length;

            unsigned long s1 = m_s1;
            unsigned long s2 = m_s2;

            unsigned char* buf1 = (unsigned char*) buf;

            if (length % 8 != 0)
            {
                    do
                    {
                            s1 += *buf1++;
                            s2 += s1;
                            length--;
                    } while (length % 8 != 0);

                    if (s1 >= BASE)
                            s1 -= BASE;
                    s2 %= BASE;
            }

            while (length > 0)
            {
                    s1 += buf1[0]; s2 += s1;
                    s1 += buf1[1]; s2 += s1;
                    s1 += buf1[2]; s2 += s1;
                    s1 += buf1[3]; s2 += s1;
                    s1 += buf1[4]; s2 += s1;
                    s1 += buf1[5]; s2 += s1;
                    s1 += buf1[6]; s2 += s1;
                    s1 += buf1[7]; s2 += s1;

                    length -= 8;
                    buf1 += 8;

                    if (s1 >= BASE)
                            s1 -= BASE;
                    if (length % 0x8000 == 0)
                            s2 %= BASE;
            }

            m_s1 = s1;
            m_s2 = s2;
        }
        buf = orig_pos;
        free(buf);
        unsigned long final_cksum = (m_s2 << 16 ) | m_s1 ;
        RETVAL = final_cksum;
    OUTPUT:
        RETVAL

