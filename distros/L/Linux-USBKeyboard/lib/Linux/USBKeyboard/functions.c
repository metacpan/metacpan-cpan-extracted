#include <usb.h>

// from /usr/src/linux/drivers/usb/input/usbkbd.c
static const unsigned char usb_kbd_keycode[256] = {
   0,  0,  0,  0, 30, 48, 46, 32, 18, 33, 34, 35, 23, 36, 37, 38,
  50, 49, 24, 25, 16, 19, 31, 20, 22, 47, 17, 45, 21, 44,  2,  3,
   4,  5,  6,  7,  8,  9, 10, 11, 28,  1, 14, 15, 57, 12, 13, 26,
  27, 43, 43, 39, 40, 41, 51, 52, 53, 58, 59, 60, 61, 62, 63, 64,
  65, 66, 67, 68, 87, 88, 99, 70,119,110,102,104,111,107,109,106,
 105,108,103, 69, 98, 55, 74, 78, 96, 79, 80, 81, 75, 76, 77, 71,
  72, 73, 82, 83, 86,127,116,117,183,184,185,186,187,188,189,190,
 191,192,193,194,134,138,130,132,128,129,131,137,133,135,136,113,
 115,114,  0,  0,  0,121,  0, 89, 93,124, 92, 94, 95,  0,  0,  0,
 122,123, 90, 91, 85,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
  29, 42, 56,125, 97, 54,100,126,164,166,165,163,161,115,114,113,
 150,158,159,128,136,177,178,176,142,152,173,140
};

// generated structures:

static const unsigned char kbd_lower[127] = {
'\0', '\0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', // 13
'\x8', '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', // 27
'\n', '\0', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', // 41
'\0', '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', '\0', '*', // 55
'\0', ' ', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0',
'\0', '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', '.',
'\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\n', '\0',
'/', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0'
};
static const unsigned char kbd_upper[127] = {
'\0', '\0', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+',
'\x8', '\0', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}',
'\0', '\0', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~',
'\0', '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', '\0', '\0',
'\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0',
'\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0',
'\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0',
'\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0'
};

char code_to_key(bool shifted, unsigned int kcode) {
  //fprintf(stderr, "try %d\n", kcode);
  if(shifted) {
    //fprintf(stderr, "kbd_upper %c\n", kbd_upper[kcode]);
    return kbd_upper[kcode];
  }
  else {
    //fprintf(stderr, "kbd_lower %d '%c'\n", kcode, kbd_lower[kcode]);
    return kbd_lower[kcode];
  }
}

void cleanup(usb_dev_handle *handle) {
  usb_release_interface(handle, 0);
  usb_close(handle);
}

usb_dev_handle* _find_device (int vendor, int product, int busnum, int devnum, int iface) {
  struct usb_bus *bus;
  struct usb_device *device;
  usb_dev_handle *handle;
  int ret;
  static bool initialized = 0;

  if(!initialized) {
    usb_init();          // do once per process instantiation
    initialized = 1;
  }
  usb_find_busses();
  usb_find_devices();
  // TODO have my own globals for init?
  bus = usb_get_busses();

  for(; bus; bus = bus->next) {
    if (busnum >= 0 && atoi(bus->dirname) != busnum) continue;
    for(device = bus->devices; device; device = device->next) {
      if (devnum >= 0 && device->devnum != devnum) continue;
      if ( (vendor  < 0 || device->descriptor.idVendor  == vendor)  &&
           (product < 0 || device->descriptor.idProduct == product) ) {
        handle = usb_open(device);
        // XXX non-portable, and I guess we don't need to retry
        usb_detach_kernel_driver_np(handle, iface);
        ret = usb_claim_interface(handle, iface);
        if(ret) {
          croak("could not claim device interface %d (%d)", iface, ret);
        }
        // usb_clear_halt(handle, 0x81);
        return(handle);
      }
    }
  }

  char vStr[30] = "", pStr[30] = "", bStr[30] = "", dStr[30] = "";
  if (vendor  >= 0) snprintf(vStr, sizeof(vStr), " vendor=0x%x",  vendor);
  if (product >= 0) snprintf(pStr, sizeof(pStr), " product=0x%x", product);
  if (busnum  >= 0) snprintf(bStr, sizeof(bStr), " busnum=%d",    busnum);
  if (devnum  >= 0) snprintf(dStr, sizeof(dStr), " devnum=%d",    devnum);
  croak("failed to find any device matching:%s%s%s%s", vStr, pStr, bStr, dStr);
}

int fetchInt(HV* hash, const char* key, int len, int defaultVal) {
  SV** valp = hv_fetch(hash, key, len, 0);
  return valp ? (int)SvIV(*valp) : defaultVal;
}

void _usb_init (SV* obj) {
  SV** selectorp = hv_fetch((HV*)SvRV(obj), "selector", 8, 0);
  if (!selectorp) croak("sanity failure: no selector in $self");
  HV* selector = (HV*)SvRV(*selectorp);

  int vendor  = fetchInt(selector, "vendor",  6, -1);
  int product = fetchInt(selector, "product", 7, -1);
  int busnum  = fetchInt(selector, "busnum",  6, -1);
  int devnum  = fetchInt(selector, "devnum",  6, -1);
  int iface   = fetchInt(selector, "iface",   5,  0);

  struct usb_dev_handle *handle = _find_device(vendor, product, busnum, devnum, iface);
  // fprintf(stderr, "got handle %d\n", handle);
  hv_store((HV*)SvRV(obj), "handle", 6, newSViv((IV)handle), 0);
}

#define PACKET_LEN 8

void _dump_packet(const char* packet) {
  int i;
  fprintf(stderr, "packet: 0x");
  for( i=0; i<PACKET_LEN; fprintf(stderr, "%02x ",packet[i++]) );
  fprintf(stderr, "\n");
}

void _keycode(SV* obj, int timeout) {
  Inline_Stack_Vars;
  int prevKeydown = fetchInt((HV*)SvRV(obj), "prevKeydown", 11, 0);
  usb_dev_handle* handle = (usb_dev_handle*) fetchInt((HV*)SvRV(obj), "handle", 6, 0);

  Inline_Stack_Reset;

  // XXX right_super is a lot bigger than 255 for some reason?
  unsigned char packet[PACKET_LEN];
  // croak("handle is %d", handle);
  int latest = usb_interrupt_read(handle, 0x81, packet, PACKET_LEN, timeout);

  // find the most recent keydown (there could be several)
  for (--latest; latest > 1 && packet[latest] == 0; --latest) {}

  // if keydown found and is not a dupe (dupes happen with simultaneous keydowns)
  if(latest > 1 && packet[latest] != prevKeydown) {
    // fprintf(stderr, "read %d bytes\n", ret);
    prevKeydown = packet[latest];
    Inline_Stack_Push(sv_2mortal(newSViv(usb_kbd_keycode[packet[latest]])));
    if(packet[0]) {
      packet[0] ^= packet[0] & 0xffffff00; // ugh
      // _dump_packet(packet);
      Inline_Stack_Push(sv_2mortal(newSViv(packet[0])));
    }
  }
  else {
    Inline_Stack_Push(sv_2mortal(newSViv(-1)));
    if (latest <= 1) prevKeydown = 0;
  }
  hv_store((HV*)SvRV(obj), "prevKeydown", 11, newSViv((IV)prevKeydown), 0);
  Inline_Stack_Done;
}

SV * _char(SV* obj) {
  int prevKeydown = fetchInt((HV*)SvRV(obj), "prevKeydown", 11, 0);
  usb_dev_handle* handle = (usb_dev_handle*) fetchInt((HV*)SvRV(obj), "handle", 6, 0);
  SV * ans;

  char packet[PACKET_LEN];
  int latest = usb_interrupt_read(handle, 0x81, packet, PACKET_LEN, 1000);

  // find the most recent keydown (there could be several)
  for (--latest; latest > 1 && packet[latest] == 0; --latest) {}

  // if keydown found and is not a dupe (dupes happen with simultaneous keydowns)
  if(latest > 1 && packet[latest] != prevKeydown) {
    //fprintf(stderr, "read (%d)\n", ret);
    // 0 is the shift code (maybe also something else)
    prevKeydown = packet[latest];
    char c = code_to_key((packet[0] == 2), usb_kbd_keycode[packet[latest]]);
    if(c) {
      const char str [2] = {c, '\0'};
      ans = newSVpvn( str, 1);
    }
    else {
      ans = newSVpvn( "", 0);
    }
  }
  else {
    ans = newSVpvn( "", 0);
    if (latest <= 1) prevKeydown = 0;
  }
  hv_store((HV*)SvRV(obj), "prevKeydown", 11, newSViv((IV)prevKeydown), 0);
  return ans;
}

void _destroy(SV* obj) {
  usb_dev_handle* handle = (usb_dev_handle*) fetchInt((HV*)SvRV(obj), "handle", 6, 0);
  if(handle)
    cleanup(handle);
}

// vim:ts=2:sw=2:et:sta
