#ifndef _LOCAL_TYPES_H
#define _LOCAL_TYPES_H

#ifdef INET6
#include <libiptc/libip6tc.h>
#define ENTRY_MATCH struct ip6t_entry_match
#define ENTRY_TARGET struct ip6t_entry_target
#define ENTRY struct ip6t_entry
#define HANDLE ip6tc_handle_t
#define ALIGN IP6T_ALIGN
#define INV_PROTO IP6T_INV_PROTO
#define CHAIN_LABEL ip6t_chainlabel
#define GET_TARGET ip6tc_get_target
#define IS_CHAIN ip6tc_is_chain

#define NFC_IPx_SRC NFC_IP6_SRC
#define NFC_IPx_DST NFC_IP6_DST
#define NFC_IPx_IF_IN NFC_IP6_IF_IN
#define NFC_IPx_IF_OUT NFC_IP6_IF_OUT
#define NFC_IPx_TOS NFC_IP6_TOS
#define NFC_IPx_PROTO NFC_IP6_PROTO
#define NFC_IPx_OPTIONS NFC_IP6_OPTIONS
#define NFC_IPx_TCPFLAGS NFC_IP6_TCPFLAGS
#define NFC_IPx_SRC_PT NFC_IP6_SRC_PT
#define NFC_IPx_DST_PT NFC_IP6_DST_PT
#define NFC_IPx_PROTO_UNKNOWN NFC_IP6_PROTO_UNKNOWN

#define INV_SRCIP IP6T_INV_SRCIP
#define INV_DSTIP IP6T_INV_DSTIP
#define INV_VIA_IN IP6T_INV_VIA_IN
#define INV_VIA_OUT IP6T_INV_VIA_OUT

#define ADDR_FAMILY AF_INET6
#define ADDR_STRLEN INET6_ADDRSTRLEN
#define TARGET_NAME_LEN IP6T_FUNCTION_MAXNAMELEN
#define ADDR_TYPE struct in6_addr

#define ENTRY_ADDR(e) (e)->ipv6

#else /* !INET6 */
#include <libiptc/libiptc.h>
#define ENTRY_MATCH struct ipt_entry_match
#define ENTRY_TARGET struct ipt_entry_target
#define ENTRY struct ipt_entry
#define HANDLE iptc_handle_t
#define ALIGN IPT_ALIGN
#define INV_PROTO IPT_INV_PROTO
#define TARGET_NAME_LEN IPT_FUNCTION_MAXNAMELEN
#define CHAIN_LABEL ipt_chainlabel
#define GET_TARGET iptc_get_target
#define IS_CHAIN iptc_is_chain

#define NFC_IPx_SRC NFC_IP_SRC
#define NFC_IPx_DST NFC_IP_DST
#define NFC_IPx_IF_IN NFC_IP_IF_IN
#define NFC_IPx_IF_OUT NFC_IP_IF_OUT
#define NFC_IPx_TOS NFC_IP_TOS
#define NFC_IPx_PROTO NFC_IP_PROTO
#define NFC_IPx_OPTIONS NFC_IP_OPTIONS
#define NFC_IPx_TCPFLAGS NFC_IP_TCPFLAGS
#define NFC_IPx_SRC_PT NFC_IP_SRC_PT
#define NFC_IPx_DST_PT NFC_IP_DST_PT
#define NFC_IPx_PROTO_UNKNOWN NFC_IP_PROTO_UNKNOWN

#define INV_SRCIP IPT_INV_SRCIP
#define INV_DSTIP IPT_INV_DSTIP
#define INV_VIA_IN IPT_INV_VIA_IN
#define INV_VIA_OUT IPT_INV_VIA_OUT

#define ADDR_FAMILY AF_INET
#define ADDR_STRLEN INET_ADDRSTRLEN
#define ADDR_TYPE struct in_addr

#define ENTRY_ADDR(e) (e)->ip

#endif /* INET6 */

#endif /* _LOCAL_TYPES_H */
