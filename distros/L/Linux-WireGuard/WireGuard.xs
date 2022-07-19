#include "easyxs/easyxs.h"

#include "wireguard.h"

#define PERL_NS "Linux::WireGuard"

#define IPV4_STRLEN sizeof( ((struct sockaddr_in*) NULL)->sin_addr.s_addr)
#define IPV6_STRLEN sizeof( ((struct sockaddr_in6*) NULL)->sin6_addr)

static HV* _wgallowedip_to_hv (pTHX_ wg_allowedip* allowedip) {
    HV* ip_hv = newHV();

    hv_stores(ip_hv, "family", newSVuv(allowedip->family));

    SV* addr_sv = NULL;

    switch (allowedip->family) {
        case AF_INET:
            addr_sv = newSVpvn((char*) &allowedip->ip4.s_addr, IPV4_STRLEN);
            break;
        case AF_INET6:
            addr_sv = newSVpvn((char*) &allowedip->ip6.s6_addr, IPV6_STRLEN);
            break;
        default:
            assert(0);
    }

    hv_stores(ip_hv, "addr", addr_sv);
    hv_stores(ip_hv, "cidr", newSVuv(allowedip->cidr));

    return ip_hv;
}

static HV* _wgpeer_to_hv (pTHX_ wg_peer *peer) {
    wg_allowedip* allowedip;

    HV* hv = newHV();

    // hv_stores(hv, "flags", newSViv(peer->flags));

    hv_stores(hv, "public_key", (peer->flags & WGPEER_HAS_PUBLIC_KEY) ? newSVpvn((char*) peer->public_key, sizeof(peer->public_key)) : &PL_sv_undef);
    hv_stores(hv, "preshared_key", (peer->flags & WGPEER_HAS_PRESHARED_KEY) ? newSVpvn( (char*) peer->preshared_key, sizeof(peer->preshared_key)) : &PL_sv_undef);

    unsigned endpoint_len = 0;
    switch (peer->endpoint.addr.sa_family) {
        case 0:
            break;
        case AF_INET:
            endpoint_len = sizeof(struct sockaddr_in);
            break;
        case AF_INET6:
            endpoint_len = sizeof(struct sockaddr_in6);
            break;
        default:
            assert(0);
    }

    hv_stores(hv, "endpoint", endpoint_len ? newSVpvn((char*) &peer->endpoint, endpoint_len) : &PL_sv_undef);

    hv_stores(hv, "rx_bytes", newSVuv(peer->rx_bytes));
    hv_stores(hv, "tx_bytes", newSVuv(peer->tx_bytes));
    hv_stores(hv, "persistent_keepalive_interval", (peer->flags & WGPEER_HAS_PERSISTENT_KEEPALIVE_INTERVAL) ? newSVuv(peer->persistent_keepalive_interval) : &PL_sv_undef);

    hv_stores(hv, "last_handshake_time_sec", newSViv(peer->last_handshake_time.tv_sec));
    hv_stores(hv, "last_handshake_time_nsec", newSViv(peer->last_handshake_time.tv_nsec));

    AV* allowed_ips = newAV();
    hv_stores(hv, "allowed_ips", newRV_noinc((SV*) allowed_ips));

    wg_for_each_allowedip(peer, allowedip) {
        HV* ip_hv = _wgallowedip_to_hv(aTHX_ allowedip);
        av_push(allowed_ips, newRV_noinc((SV*)ip_hv));
    }

    return hv;
}

static HV* _wgdev_to_hv (pTHX_ wg_device *dev) {
    wg_peer *peer;

    HV* dev_hv = newHV();

    hv_stores(dev_hv, "name", newSVpv(dev->name, 0));
    hv_stores(dev_hv, "ifindex", newSVuv(dev->ifindex));

    // hv_stores(dev_hv, "flags", newSViv(dev->flags));

    hv_stores(dev_hv, "public_key", dev->flags & WGDEVICE_HAS_PUBLIC_KEY ? newSVpvn((char*) dev->public_key, sizeof(dev->public_key)) : &PL_sv_undef);
    hv_stores(dev_hv, "private_key", dev->flags & WGDEVICE_HAS_PRIVATE_KEY ? newSVpvn((char*) dev->private_key, sizeof(dev->private_key)) : &PL_sv_undef);

    hv_stores(dev_hv, "fwmark", dev->flags & WGDEVICE_HAS_FWMARK ? newSVuv(dev->fwmark) : &PL_sv_undef);
    hv_stores(dev_hv, "listen_port", dev->flags & WGDEVICE_HAS_LISTEN_PORT ? newSVuv(dev->listen_port) : &PL_sv_undef);

    AV* peers = newAV();
    hv_stores(dev_hv, "peers", newRV_noinc((SV*) peers));

    wg_for_each_peer(dev, peer) {
        HV* peer_hv = _wgpeer_to_hv(aTHX_ peer);
        av_push(peers, newRV_noinc((SV*) peer_hv));
    }

    return dev_hv;
}

// Doesn’t seem to be useful:
#define _LWG_CREATE_CONST_UV(ns, theconst) \
    newCONSTSUB(gv_stashpv(ns, 0), #theconst, newSVuv(theconst));

// ----------------------------------------------------------------------

MODULE = Linux::WireGuard       PACKAGE = Linux::WireGuard

PROTOTYPES: DISABLE

void
list_device_names()
    PPCODE:
        char *device_names, *device_name;
        size_t len;

        device_names = wg_list_device_names();
        if (!device_names) {
            croak("Failed to retrieve device names: %s", strerror(errno));
        }

        unsigned count=0;

        wg_for_each_device_name(device_names, device_name, len) {
            count++;
            mXPUSHp(device_name, len);
        }

        free(device_names);

        XSRETURN(count);

SV*
get_device (SV* name_sv)
    CODE:
        wg_device *dev;

        const char* devname = exs_SvPVbyte_nolen(name_sv);

        if (wg_get_device(&dev, devname) < 0) {
            croak("Failed to retrieve device `%s`: %s", devname, strerror(errno));
        }

        HV* dev_hv = _wgdev_to_hv(aTHX_ dev);

        wg_free_device(dev);

        RETVAL = newRV_noinc((SV*) dev_hv);

    OUTPUT:
        RETVAL

void
add_device (SV* name_sv)
    ALIAS:
        del_device = 1
    CODE:
        const char* devname = exs_SvPVbyte_nolen(name_sv);

        int result = ix ? wg_del_device(devname) : wg_add_device(devname);
        if (result) {
            croak("Failed to %s device `%s`: %s", ix ? "delete" : "add", devname, strerror(errno));
        }

SV*
generate_private_key()
    ALIAS:
        generate_preshared_key = 1
    CODE:
        wg_key key;

        if (ix) {
            wg_generate_preshared_key(key);
        }
        else {
            wg_generate_private_key(key);
        }

        RETVAL = newSVpv((char*) key, sizeof(wg_key));
    OUTPUT:
        RETVAL

SV*
generate_public_key(SV* private_key_sv)
    CODE:
        wg_key public_key;

        if (SvROK(private_key_sv)) {
            croak("Reference is nonsensical here!");
        }

        STRLEN keylen;
        const char* private_key_char = SvPVbyte(private_key_sv, keylen);

        if (keylen != sizeof(wg_key)) {
            croak("Key must be exactly %lu characters, not %lu!", sizeof(wg_key), keylen);
        }

        wg_generate_public_key(public_key, (const void*) private_key_char);

        RETVAL = newSVpv((char*) public_key, sizeof(wg_key));
    OUTPUT:
        RETVAL
