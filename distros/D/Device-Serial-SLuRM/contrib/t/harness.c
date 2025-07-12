#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "slurm.h"

#define streq(a,b) (!strcmp(a,b))
#define strstartswith(a,b) (!strncmp(a,b,strlen(b)))

static size_t sscanf_d_sp(const char *s, int *ip)
{
  size_t eaten = 0;
  sscanf(s, "%d %n", ip, &eaten);
  return eaten;
}

static void printf_v02X(uint8_t b[], uint8_t len)
{
  while(len)
    printf("%02X", b[0]), b++, len--;
}

static size_t inplace_hex2bytes(char *s)
{
  char *inpos = s, *outpos = s;

  while(*inpos) {
    unsigned int ch;
    if(sscanf(inpos, "%2x", &ch) < 1)
      break;
    *outpos = ch;
    outpos += 1; inpos += 2;
  }

  return outpos - s;
}

/* SLuRM integration */

size_t  output_len = 0;
uint8_t output_buffer[256];

void on_slurm_notify(uint8_t b[], uint8_t len)
{
  printf("notify ");
  printf_v02X(b, len);
  printf("\n");
}

void on_slurm_request(uint8_t seqno, uint8_t b[], uint8_t len)
{
  printf("request %d ", seqno);
  printf_v02X(b, len);
  printf("\n");
}

void on_slurm_need_tasks(void)
{
  printf("needtasks\n");
}

void do_slurm_send(uint8_t b)
{
  output_buffer[output_len] = b;
  output_len++;
}

/* Test system */

int main(int argc, char **argv)
{
  char line[1024] = {0};

  setvbuf(stdout, NULL, _IONBF, 0);

  while(fgets(line, sizeof line, stdin)) {
    char *nl;
    if((nl = strchr(line, '\n')))
      *nl = '\0';

    bool err = false;

    if(strstartswith(line, "CONF ")) {
      char *bytes = line + 5;
#ifdef SLURM_MULTIDROP
      int node_id; bytes += sscanf_d_sp(bytes, &node_id);
      slurm_configure(node_id);
#else
      err = true;
#endif
    }
    if(strstartswith(line, "RECV ")) {
      char *bytes = line + 5;
      size_t len = inplace_hex2bytes(bytes);
      while(len) {
        isr_slurm_recv(*bytes);
        bytes++, len--;
      }
    }
    else if(strstartswith(line, "NOTIFY ")) {
      char *bytes = line + 7;
      size_t len = inplace_hex2bytes(bytes);

      slurm_notify(bytes, len);
    }
    else if(strstartswith(line, "RESPOND ")) {
      char *bytes = line + 8;
      int seqno; bytes += sscanf_d_sp(bytes, &seqno);
      size_t len = inplace_hex2bytes(bytes);

      slurm_respond(seqno, bytes, len);
    }
    else if(strstartswith(line, "ERR ")) {
      char *bytes = line + 4;
      int seqno; bytes += sscanf_d_sp(bytes, &seqno);
      size_t len = inplace_hex2bytes(bytes);

      slurm_responderr(seqno, bytes, len);
    }
    else if(strstartswith(line, "TASKS")) {
      slurm_do_tasks();
    }
    else
      err = true;

    if(output_len) {
      printf("send ");
      printf_v02X(output_buffer, output_len);
      output_len = 0;
      printf("\n");
    }

    printf(err ? "?\n" : "DONE\n");
  }
}
