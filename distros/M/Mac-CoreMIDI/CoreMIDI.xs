#include "helpers.h"

MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI::Object      PREFIX=MIDI

SV *
MIDIGetName(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        ST(0) = MIDIGetStringProperty(dev, kMIDIPropertyName);

SV *
MIDIGetManufacturer(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        ST(0) = MIDIGetStringProperty(dev, kMIDIPropertyManufacturer);

SV *
MIDIGetModel(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        ST(0) = MIDIGetStringProperty(dev, kMIDIPropertyModel);

SV*
MIDIGetUniqueID(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        ST(0) = MIDIGetIntegerProperty(dev, kMIDIPropertyUniqueID);

SV*
MIDIGetDeviceID(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        ST(0) = MIDIGetIntegerProperty(dev, kMIDIPropertyDeviceID);

SV*
MIDIGetReceiveChannels(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        ST(0) = MIDIGetIntegerProperty(dev, kMIDIPropertyReceiveChannels);

SV*
MIDIGetTransmitChannels(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        ST(0) = MIDIGetIntegerProperty(dev, kMIDIPropertyTransmitChannels);

SV*
MIDIGetMaxSysExSpeed(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev, kMIDIPropertyMaxSysExSpeed);
    OUTPUT:
        RETVAL

SV*
MIDIGetAdvanceScheduleTimeMuSec(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev, 
            kMIDIPropertyAdvanceScheduleTimeMuSec);
    OUTPUT:
        RETVAL

SV*
MIDIIsEmbeddedEntity(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev,
            kMIDIPropertyIsEmbeddedEntity);
    OUTPUT:
        RETVAL

SV*
MIDIIsBroadcast(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev,
            kMIDIPropertyIsBroadcast);
    OUTPUT:
        RETVAL

SV*
MIDIIsSingleRealtimeEntity(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev,
            kMIDIPropertySingleRealtimeEntity);
    OUTPUT:
        RETVAL

# ConnectionUniqueID not yet implemented -- may also be data

SV*
MIDIIsOffline(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev,
            kMIDIPropertyOffline);
    OUTPUT:
        RETVAL

SV*
MIDIIsPrivate(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev,
            kMIDIPropertyPrivate);
    OUTPUT:
        RETVAL

SV *
MIDIGetDriverOwner(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetStringProperty(dev,
            kMIDIPropertyDriverOwner);
    OUTPUT:
        RETVAL

SV*
MIDIGetDriverVersion(dev)
        Mac_CoreMIDI_Object dev
    CODE:
        RETVAL = MIDIGetIntegerProperty(dev,
            kMIDIPropertyDriverVersion);
    OUTPUT:
        RETVAL


MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI::Device     PREFIX = MIDIDevice

ItemCount
MIDIDeviceGetNumberOfEntities(device)
        Mac_CoreMIDI_Device  device
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Entity
MIDIDeviceGetEntity(device, entityIndex0)
        Mac_CoreMIDI_Device  device
        ItemCount            entityIndex0
    OUTPUT:
        RETVAL


MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI::Entity     PREFIX = MIDIEntity

Mac_CoreMIDI_Device
MIDIEntityGetParent(inEntity)
        Mac_CoreMIDI_Entity  inEntity
    PREINIT:
        Mac_CoreMIDI_Device  device;
    CODE:
        OSStatus s = MIDIEntityGetDevice(inEntity, &device);
        ST(0) = sv_setref_iv(sv_newmortal(),
            "Mac::CoreMIDI::Device", (IV) device);

ItemCount
MIDIEntityGetNumberOfSources(entity)
        Mac_CoreMIDI_Entity  entity
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Endpoint
MIDIEntityGetSource(entity, sourceIndex0)
        Mac_CoreMIDI_Entity  entity
        ItemCount            sourceIndex0
    OUTPUT:
        RETVAL

ItemCount
MIDIEntityGetNumberOfDestinations(entity)
        Mac_CoreMIDI_Entity  entity
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Endpoint
MIDIEntityGetDestination(entity, destIndex0)
        Mac_CoreMIDI_Entity  entity
        ItemCount            destIndex0
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------------

MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI::Endpoint   PREFIX=MIDIEndpoint

Mac_CoreMIDI_Entity
MIDIEndpointGetParent(inEndpoint)
        Mac_CoreMIDI_Endpoint  inEndpoint
    PREINIT:
        Mac_CoreMIDI_Entity  entity;
    CODE:
        OSStatus s = MIDIEndpointGetEntity(inEndpoint, &entity);
        ST(0) = sv_setref_iv(sv_newmortal(),
            "Mac::CoreMIDI::Entity", (IV) entity);

Mac_CoreMIDI_Endpoint
MIDIEndpoint_new_source(class, client, name)
        const char *class
        Mac_CoreMIDI_Client client;
        const char *name
    PREINIT:
        CFStringRef str;
        Mac_CoreMIDI_Endpoint me;
        SV* sv;
    CODE:
        str = CFStringCreateWithCString(NULL, name, kCFStringEncodingUTF8);
        OSStatus s = MIDISourceCreate(client, str, &me);
        CFRelease(str);
        RETVAL = me;
    OUTPUT:
        RETVAL

OSStatus
MIDIEndpoint_destroy(endpoint)
        Mac_CoreMIDI_Endpoint endpoint;
    CODE:
        RETVAL = MIDIEndpointDispose(endpoint);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------------

MODULE = Mac::CoreMIDI   PACKAGE = Mac::CoreMIDI::Client  PREFIX=MIDIClient

Mac_CoreMIDI_Client
MIDIClient_new(class, name, callback)
        const char *class
        const char *name
        SV *callback
    PREINIT:
        CFStringRef str;
        Mac_CoreMIDI_Client mc;
        SV* sv;
    CODE:
        str = CFStringCreateWithCString(NULL, name,
            kCFStringEncodingUTF8);
        OSStatus s;
        if (!SvOK(callback)) {
            s = MIDIClientCreate(str, NULL, NULL, &mc);
        } else {
            s = MIDIClientCreate(str, MIDIClientNotify,
                (void *) newSVsv(callback), &mc);
        }
        CFRelease(str);

        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), class, (void *) mc);

OSStatus
MIDIClient_destroy(client)
        Mac_CoreMIDI_Client client;
    CODE:
        RETVAL = MIDIClientDispose(client);
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Endpoint
MIDIClientCreateDestination(client, name, callback)
        Mac_CoreMIDI_Client client
        const char *name
        SV *callback
    PREINIT:
        CFStringRef str;
        Mac_CoreMIDI_Endpoint me;
    CODE:
        str = CFStringCreateWithCString(NULL, name, kCFStringEncodingUTF8);
        OSStatus s;
        if (!SvOK(callback)) {
            s = MIDIDestinationCreate(client, str, NULL, NULL, &me);
        } else {
//        
//            dSP;
//        
//            PUSHMARK(SP);
//            call_sv(callback, G_DISCARD | G_NOARGS);
//

            // sv will be garbage collected, so  we have to create a new
            // SV that is still valid when the callback is called
            s = MIDIDestinationCreate(client, str, MIDIReader,
                (void *) newSVsv(callback), &me);
        }
        CFRelease(str);

        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), "Mac::CoreMIDI::Endpoint", (void *) me);

# ------------------------------------------------------------------------

MODULE = Mac::CoreMIDI   PACKAGE = Mac::CoreMIDI::Port  PREFIX=MIDIPort

Mac_CoreMIDI_Port
MIDIPort_new_input(class, client, name)
        const char *class
        Mac_CoreMIDI_Client client;
        const char *name
    PREINIT:
        CFStringRef str;
        Mac_CoreMIDI_Port mp;
        SV* sv;
    CODE:
        sv = newSViv(42); // allocate a SV to store the object ref in
        str = CFStringCreateWithCString(NULL, name, kCFStringEncodingUTF8);
        OSStatus s = MIDIInputPortCreate(client, str, MIDIReader, (void *) sv, &mp);
        // Store mc as a blessed reference in sv, so the callback can access it
        sv_setref_pv(sv, class, (void *) mp);
        CFRelease(str);
        RETVAL = mp;
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Port
MIDIPort_new_output(class, client, name)
        const char *class
        Mac_CoreMIDI_Client client;
        const char *name
    PREINIT:
        CFStringRef str;
        Mac_CoreMIDI_Port mp;
        SV* sv;
    CODE:
        str = CFStringCreateWithCString(NULL, name, kCFStringEncodingUTF8);
        OSStatus s = MIDIOutputPortCreate(client, str, &mp);
        // Store mc as a blessed reference in sv, so the callback can access it
        CFRelease(str);
        RETVAL = mp;
    OUTPUT:
        RETVAL

OSStatus
MIDIPort_destroy(port)
        Mac_CoreMIDI_Port port;
    CODE:
        RETVAL = MIDIPortDispose(port);
    OUTPUT:
        RETVAL

# ------------------------------------------------------------------------

MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI      PREFIX=MIDI

ItemCount
MIDIGetNumberOfDevices()
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Device
MIDIGetDevice(deviceIndex0)
        ItemCount deviceIndex0
    OUTPUT:
        RETVAL

ItemCount
MIDIGetNumberOfSources()
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Endpoint
MIDIGetSource(sourceIndex0)
        ItemCount  sourceIndex0
    OUTPUT:
        RETVAL

ItemCount
MIDIGetNumberOfDestinations()
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Endpoint
MIDIGetDestination(destIndex0)
        ItemCount  destIndex0
    OUTPUT:
        RETVAL

ItemCount
MIDIGetNumberOfExternalDevices()
    OUTPUT:
        RETVAL

Mac_CoreMIDI_Device
MIDIGetExternalDevice(deviceIndex0)
        ItemCount  deviceIndex0
    OUTPUT:
        RETVAL

SV *
MIDIFindObject(uniqueID)
        SInt32 uniqueID
    PREINIT:
        MIDIObjectRef object;
        MIDIObjectType objectType;
    CODE:
        ST(0) = sv_newmortal();
        
        OSStatus s = MIDIObjectFindByUniqueID(uniqueID, &object, &objectType);
        if (object == NULL) {
            ST(0) = &PL_sv_undef;
        } else {
            # ExternalMask not removed here, in case of future differentiation
            switch (objectType) {
                case kMIDIObjectType_Device:
                case kMIDIObjectType_ExternalDevice:
                    ST(0) = sv_setref_iv(sv_newmortal(),
                        "Mac::CoreMIDI::Device", (IV) object);
                    break;
                case kMIDIObjectType_Entity:
                case kMIDIObjectType_ExternalEntity:
                    ST(0) = sv_setref_iv(sv_newmortal(),
                        "Mac::CoreMIDI::Entity", (IV) object);
                    break;
                case kMIDIObjectType_Source:
                case kMIDIObjectType_ExternalSource:
                case kMIDIObjectType_Destination:
                case kMIDIObjectType_ExternalDestination:
                    ST(0) = sv_setref_iv(sv_newmortal(),
                        "Mac::CoreMIDI::Endpoint", (IV) object);
                    break;
                default:
                    ST(0) = sv_setref_iv(sv_newmortal(),
                        "Mac::CoreMIDI::Object", (IV) object);
            }
        }

OSStatus
MIDIRestart()
    OUTPUT:
        RETVAL

MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI      PREFIX=CF

void
CFRunLoopRun()

MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI      PREFIX=CF_

void
CF_RunLoopStop()
    PREINIT:
        CFRunLoopRef rl;
    CODE:
        rl = CFRunLoopGetCurrent();
        CFRunLoopStop(rl);
        CFRelease(rl);

MODULE = Mac::CoreMIDI    PACKAGE = Mac::CoreMIDI::ThruConnection  PREFIX=MIDIThruConnection

SV *
MIDIThruConnectionnew(class, fromEndpoint, toEndpoint)
        const char *class
        Mac_CoreMIDI_Endpoint fromEndpoint
        Mac_CoreMIDI_Endpoint toEndpoint
    PREINIT:
        OSStatus err;
        MIDIThruConnectionParams params;
        CFDataRef dataRef;
        MIDIThruConnectionRef thru;
    CODE:
        MIDIThruConnectionParamsInitialize(&params);
        params.numSources = 1;
        params.sources[0].endpointRef = fromEndpoint;
        params.numDestinations = 1;
        params.destinations[0].endpointRef = toEndpoint;
        dataRef = CFDataCreate(NULL, (unsigned char*) &params,
            sizeof(MIDIThruConnectionParams));
        # name = persist ? CFSTR("com.apple.thrutest") : NULL
        err = MIDIThruConnectionCreate(NULL, dataRef, &thru);
        CFRelease(dataRef);
        ST(0) = sv_newmortal();
        if (err == 0) {
            sv_setref_pv(ST(0), class, (void *) thru);
        } else {
            ST(0) = &PL_sv_undef;
        }

OSStatus
MIDIThruConnectionDispose(connection)
        Mac_CoreMIDI_ThruConnection connection
    OUTPUT:
        RETVAL
