#ifndef MAC_COREMIDI_HELPERS_H
#define MAC_COREMIDI_HELPERS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

// from Mac::Carbon -- these are defined by Perl, too
#undef Move
#undef I_POLL
#undef DEBUG

#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CFRunLoop.h>

typedef MIDIObjectRef   Mac_CoreMIDI_Object;
typedef MIDIDeviceRef   Mac_CoreMIDI_Device;
typedef MIDIEntityRef   Mac_CoreMIDI_Entity;
typedef MIDIEndpointRef Mac_CoreMIDI_Endpoint;
typedef MIDIClientRef   Mac_CoreMIDI_Client;
typedef MIDIPortRef     Mac_CoreMIDI_Port;

typedef MIDIThruConnectionRef Mac_CoreMIDI_ThruConnection;

SV * MIDIGetStringProperty(Mac_CoreMIDI_Object dev, CFStringRef propname);
SV * MIDIGetIntegerProperty(Mac_CoreMIDI_Object dev, CFStringRef propname);

void MIDIClientNotify(const MIDINotification* message, void *refCon);
void MIDIReader(const MIDIPacketList * pktlist,
    void *readProcRefCon, void *srcConnRefCon);

static SV * mySV;

#endif