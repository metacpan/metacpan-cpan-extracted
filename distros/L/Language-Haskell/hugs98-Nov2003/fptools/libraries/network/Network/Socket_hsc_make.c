#include "template-hsc.h"
#line 22 "Socket.hsc"
#include "HsNet.h"
#line 24 "Socket.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
#line 25 "Socket.hsc"
#define WITH_WINSOCK  1
#line 26 "Socket.hsc"
#endif 
#line 28 "Socket.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 29 "Socket.hsc"
#define DOMAIN_SOCKET_SUPPORT 1
#line 30 "Socket.hsc"
#endif 
#line 32 "Socket.hsc"
#if !defined(CALLCONV)
#line 33 "Socket.hsc"
#ifdef WITH_WINSOCK
#line 34 "Socket.hsc"
#define CALLCONV stdcall
#line 35 "Socket.hsc"
#else 
#line 36 "Socket.hsc"
#define CALLCONV ccall
#line 37 "Socket.hsc"
#endif 
#line 38 "Socket.hsc"
#endif 
#line 57 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 59 "Socket.hsc"
#endif 
#line 67 "Socket.hsc"
#ifdef SO_PEERCRED
#line 70 "Socket.hsc"
#endif 
#line 102 "Socket.hsc"
#ifdef DOMAIN_SOCKET_SUPPORT
#line 110 "Socket.hsc"
#endif 
#line 117 "Socket.hsc"
#ifdef SCM_RIGHTS
#line 119 "Socket.hsc"
#endif 
#line 145 "Socket.hsc"
#ifdef __HUGS__
#line 150 "Socket.hsc"
#endif 
#line 169 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
#line 171 "Socket.hsc"
#if defined(mingw32_TARGET_OS)
#line 174 "Socket.hsc"
#endif 
#line 178 "Socket.hsc"
#endif 
#line 316 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 319 "Socket.hsc"
#endif 
#line 322 "Socket.hsc"
#if defined(WITH_WINSOCK) || defined(cygwin32_TARGET_OS)
#line 324 "Socket.hsc"
#elif defined(darwin_TARGET_OS)
#line 326 "Socket.hsc"
#else 
#line 328 "Socket.hsc"
#endif 
#line 333 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 338 "Socket.hsc"
#endif 
#line 347 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 351 "Socket.hsc"
#endif 
#line 358 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 360 "Socket.hsc"
#endif 
#line 364 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 366 "Socket.hsc"
#endif 
#line 403 "Socket.hsc"
#if !defined(__HUGS__)
#line 405 "Socket.hsc"
#endif 
#line 413 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 430 "Socket.hsc"
#if !defined(__HUGS__)
#line 432 "Socket.hsc"
#endif 
#line 438 "Socket.hsc"
#endif 
#line 504 "Socket.hsc"
#if !(defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS))
#line 511 "Socket.hsc"
#else 
#line 521 "Socket.hsc"
#endif 
#line 525 "Socket.hsc"
#if !defined(__HUGS__)
#line 527 "Socket.hsc"
#endif 
#line 588 "Socket.hsc"
#if defined(mingw32_TARGET_OS) && !defined(__HUGS__)
#line 595 "Socket.hsc"
#else 
#line 598 "Socket.hsc"
#if !defined(__HUGS__)
#line 601 "Socket.hsc"
#endif 
#line 603 "Socket.hsc"
#if !defined(__HUGS__)
#line 605 "Socket.hsc"
#endif 
#line 606 "Socket.hsc"
#endif 
#line 611 "Socket.hsc"
#if defined(mingw32_TARGET_OS) && !defined(__HUGS__)
#line 620 "Socket.hsc"
#endif 
#line 634 "Socket.hsc"
#if !defined(__HUGS__)
#line 637 "Socket.hsc"
#endif 
#line 650 "Socket.hsc"
#if !defined(__HUGS__)
#line 653 "Socket.hsc"
#endif 
#line 681 "Socket.hsc"
#if !defined(__HUGS__)
#line 684 "Socket.hsc"
#endif 
#line 696 "Socket.hsc"
#if !defined(__HUGS__)
#line 699 "Socket.hsc"
#endif 
#line 753 "Socket.hsc"
#ifdef SO_DEBUG
#line 755 "Socket.hsc"
#endif 
#line 756 "Socket.hsc"
#ifdef SO_REUSEADDR
#line 758 "Socket.hsc"
#endif 
#line 759 "Socket.hsc"
#ifdef SO_TYPE
#line 761 "Socket.hsc"
#endif 
#line 762 "Socket.hsc"
#ifdef SO_ERROR
#line 764 "Socket.hsc"
#endif 
#line 765 "Socket.hsc"
#ifdef SO_DONTROUTE
#line 767 "Socket.hsc"
#endif 
#line 768 "Socket.hsc"
#ifdef SO_BROADCAST
#line 770 "Socket.hsc"
#endif 
#line 771 "Socket.hsc"
#ifdef SO_SNDBUF
#line 773 "Socket.hsc"
#endif 
#line 774 "Socket.hsc"
#ifdef SO_RCVBUF
#line 776 "Socket.hsc"
#endif 
#line 777 "Socket.hsc"
#ifdef SO_KEEPALIVE
#line 779 "Socket.hsc"
#endif 
#line 780 "Socket.hsc"
#ifdef SO_OOBINLINE
#line 782 "Socket.hsc"
#endif 
#line 783 "Socket.hsc"
#ifdef IP_TTL
#line 785 "Socket.hsc"
#endif 
#line 786 "Socket.hsc"
#ifdef TCP_MAXSEG
#line 788 "Socket.hsc"
#endif 
#line 789 "Socket.hsc"
#ifdef TCP_NODELAY
#line 791 "Socket.hsc"
#endif 
#line 792 "Socket.hsc"
#ifdef SO_LINGER
#line 794 "Socket.hsc"
#endif 
#line 795 "Socket.hsc"
#ifdef SO_REUSEPORT
#line 797 "Socket.hsc"
#endif 
#line 798 "Socket.hsc"
#ifdef SO_RCVLOWAT
#line 800 "Socket.hsc"
#endif 
#line 801 "Socket.hsc"
#ifdef SO_SNDLOWAT
#line 803 "Socket.hsc"
#endif 
#line 804 "Socket.hsc"
#ifdef SO_RCVTIMEO
#line 806 "Socket.hsc"
#endif 
#line 807 "Socket.hsc"
#ifdef SO_SNDTIMEO
#line 809 "Socket.hsc"
#endif 
#line 810 "Socket.hsc"
#ifdef SO_USELOOPBACK
#line 812 "Socket.hsc"
#endif 
#line 817 "Socket.hsc"
#ifdef IP_TTL
#line 819 "Socket.hsc"
#endif 
#line 820 "Socket.hsc"
#ifdef TCP_MAXSEG
#line 822 "Socket.hsc"
#endif 
#line 823 "Socket.hsc"
#ifdef TCP_NODELAY
#line 825 "Socket.hsc"
#endif 
#line 831 "Socket.hsc"
#ifdef SO_DEBUG
#line 833 "Socket.hsc"
#endif 
#line 834 "Socket.hsc"
#ifdef SO_REUSEADDR
#line 836 "Socket.hsc"
#endif 
#line 837 "Socket.hsc"
#ifdef SO_TYPE
#line 839 "Socket.hsc"
#endif 
#line 840 "Socket.hsc"
#ifdef SO_ERROR
#line 842 "Socket.hsc"
#endif 
#line 843 "Socket.hsc"
#ifdef SO_DONTROUTE
#line 845 "Socket.hsc"
#endif 
#line 846 "Socket.hsc"
#ifdef SO_BROADCAST
#line 848 "Socket.hsc"
#endif 
#line 849 "Socket.hsc"
#ifdef SO_SNDBUF
#line 851 "Socket.hsc"
#endif 
#line 852 "Socket.hsc"
#ifdef SO_RCVBUF
#line 854 "Socket.hsc"
#endif 
#line 855 "Socket.hsc"
#ifdef SO_KEEPALIVE
#line 857 "Socket.hsc"
#endif 
#line 858 "Socket.hsc"
#ifdef SO_OOBINLINE
#line 860 "Socket.hsc"
#endif 
#line 861 "Socket.hsc"
#ifdef IP_TTL
#line 863 "Socket.hsc"
#endif 
#line 864 "Socket.hsc"
#ifdef TCP_MAXSEG
#line 866 "Socket.hsc"
#endif 
#line 867 "Socket.hsc"
#ifdef TCP_NODELAY
#line 869 "Socket.hsc"
#endif 
#line 870 "Socket.hsc"
#ifdef SO_LINGER
#line 872 "Socket.hsc"
#endif 
#line 873 "Socket.hsc"
#ifdef SO_REUSEPORT
#line 875 "Socket.hsc"
#endif 
#line 876 "Socket.hsc"
#ifdef SO_RCVLOWAT
#line 878 "Socket.hsc"
#endif 
#line 879 "Socket.hsc"
#ifdef SO_SNDLOWAT
#line 881 "Socket.hsc"
#endif 
#line 882 "Socket.hsc"
#ifdef SO_RCVTIMEO
#line 884 "Socket.hsc"
#endif 
#line 885 "Socket.hsc"
#ifdef SO_SNDTIMEO
#line 887 "Socket.hsc"
#endif 
#line 888 "Socket.hsc"
#ifdef SO_USELOOPBACK
#line 890 "Socket.hsc"
#endif 
#line 915 "Socket.hsc"
#ifdef SO_PEERCRED
#line 932 "Socket.hsc"
#endif 
#line 934 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 940 "Socket.hsc"
#if !defined(__HUGS__)
#line 944 "Socket.hsc"
#else 
#line 946 "Socket.hsc"
#endif 
#line 956 "Socket.hsc"
#if !defined(__HUGS__)
#line 959 "Socket.hsc"
#endif 
#line 974 "Socket.hsc"
#if !defined(__HUGS__)
#line 977 "Socket.hsc"
#endif 
#line 994 "Socket.hsc"
#if !defined(__HUGS__)
#line 997 "Socket.hsc"
#endif 
#line 1013 "Socket.hsc"
#endif 
#line 1062 "Socket.hsc"
#ifdef AF_UNIX
#line 1064 "Socket.hsc"
#endif 
#line 1065 "Socket.hsc"
#ifdef AF_INET
#line 1067 "Socket.hsc"
#endif 
#line 1068 "Socket.hsc"
#ifdef AF_INET6
#line 1070 "Socket.hsc"
#endif 
#line 1071 "Socket.hsc"
#ifdef AF_IMPLINK
#line 1073 "Socket.hsc"
#endif 
#line 1074 "Socket.hsc"
#ifdef AF_PUP
#line 1076 "Socket.hsc"
#endif 
#line 1077 "Socket.hsc"
#ifdef AF_CHAOS
#line 1079 "Socket.hsc"
#endif 
#line 1080 "Socket.hsc"
#ifdef AF_NS
#line 1082 "Socket.hsc"
#endif 
#line 1083 "Socket.hsc"
#ifdef AF_NBS
#line 1085 "Socket.hsc"
#endif 
#line 1086 "Socket.hsc"
#ifdef AF_ECMA
#line 1088 "Socket.hsc"
#endif 
#line 1089 "Socket.hsc"
#ifdef AF_DATAKIT
#line 1091 "Socket.hsc"
#endif 
#line 1092 "Socket.hsc"
#ifdef AF_CCITT
#line 1094 "Socket.hsc"
#endif 
#line 1095 "Socket.hsc"
#ifdef AF_SNA
#line 1097 "Socket.hsc"
#endif 
#line 1098 "Socket.hsc"
#ifdef AF_DECnet
#line 1100 "Socket.hsc"
#endif 
#line 1101 "Socket.hsc"
#ifdef AF_DLI
#line 1103 "Socket.hsc"
#endif 
#line 1104 "Socket.hsc"
#ifdef AF_LAT
#line 1106 "Socket.hsc"
#endif 
#line 1107 "Socket.hsc"
#ifdef AF_HYLINK
#line 1109 "Socket.hsc"
#endif 
#line 1110 "Socket.hsc"
#ifdef AF_APPLETALK
#line 1112 "Socket.hsc"
#endif 
#line 1113 "Socket.hsc"
#ifdef AF_ROUTE
#line 1115 "Socket.hsc"
#endif 
#line 1116 "Socket.hsc"
#ifdef AF_NETBIOS
#line 1118 "Socket.hsc"
#endif 
#line 1119 "Socket.hsc"
#ifdef AF_NIT
#line 1121 "Socket.hsc"
#endif 
#line 1122 "Socket.hsc"
#ifdef AF_802
#line 1124 "Socket.hsc"
#endif 
#line 1125 "Socket.hsc"
#ifdef AF_ISO
#line 1127 "Socket.hsc"
#endif 
#line 1128 "Socket.hsc"
#ifdef AF_OSI
#line 1130 "Socket.hsc"
#endif 
#line 1131 "Socket.hsc"
#ifdef AF_NETMAN
#line 1133 "Socket.hsc"
#endif 
#line 1134 "Socket.hsc"
#ifdef AF_X25
#line 1136 "Socket.hsc"
#endif 
#line 1137 "Socket.hsc"
#ifdef AF_AX25
#line 1139 "Socket.hsc"
#endif 
#line 1140 "Socket.hsc"
#ifdef AF_OSINET
#line 1142 "Socket.hsc"
#endif 
#line 1143 "Socket.hsc"
#ifdef AF_GOSSIP
#line 1145 "Socket.hsc"
#endif 
#line 1146 "Socket.hsc"
#ifdef AF_IPX
#line 1148 "Socket.hsc"
#endif 
#line 1149 "Socket.hsc"
#ifdef Pseudo_AF_XTP
#line 1151 "Socket.hsc"
#endif 
#line 1152 "Socket.hsc"
#ifdef AF_CTF
#line 1154 "Socket.hsc"
#endif 
#line 1155 "Socket.hsc"
#ifdef AF_WAN
#line 1157 "Socket.hsc"
#endif 
#line 1158 "Socket.hsc"
#ifdef AF_SDL
#line 1160 "Socket.hsc"
#endif 
#line 1161 "Socket.hsc"
#ifdef AF_NETWARE
#line 1163 "Socket.hsc"
#endif 
#line 1164 "Socket.hsc"
#ifdef AF_NDD
#line 1166 "Socket.hsc"
#endif 
#line 1167 "Socket.hsc"
#ifdef AF_INTF
#line 1169 "Socket.hsc"
#endif 
#line 1170 "Socket.hsc"
#ifdef AF_COIP
#line 1172 "Socket.hsc"
#endif 
#line 1173 "Socket.hsc"
#ifdef AF_CNT
#line 1175 "Socket.hsc"
#endif 
#line 1176 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
#line 1178 "Socket.hsc"
#endif 
#line 1179 "Socket.hsc"
#ifdef Pseudo_AF_PIP
#line 1181 "Socket.hsc"
#endif 
#line 1182 "Socket.hsc"
#ifdef AF_SIP
#line 1184 "Socket.hsc"
#endif 
#line 1185 "Socket.hsc"
#ifdef AF_ISDN
#line 1187 "Socket.hsc"
#endif 
#line 1188 "Socket.hsc"
#ifdef Pseudo_AF_KEY
#line 1190 "Socket.hsc"
#endif 
#line 1191 "Socket.hsc"
#ifdef AF_NATM
#line 1193 "Socket.hsc"
#endif 
#line 1194 "Socket.hsc"
#ifdef AF_ARP
#line 1196 "Socket.hsc"
#endif 
#line 1197 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
#line 1199 "Socket.hsc"
#endif 
#line 1200 "Socket.hsc"
#ifdef AF_ENCAP
#line 1202 "Socket.hsc"
#endif 
#line 1203 "Socket.hsc"
#ifdef AF_LINK
#line 1205 "Socket.hsc"
#endif 
#line 1206 "Socket.hsc"
#ifdef AF_RAW
#line 1208 "Socket.hsc"
#endif 
#line 1209 "Socket.hsc"
#ifdef AF_RIF
#line 1211 "Socket.hsc"
#endif 
#line 1218 "Socket.hsc"
#ifdef AF_UNIX
#line 1220 "Socket.hsc"
#endif 
#line 1221 "Socket.hsc"
#ifdef AF_INET
#line 1223 "Socket.hsc"
#endif 
#line 1224 "Socket.hsc"
#ifdef AF_INET6
#line 1226 "Socket.hsc"
#endif 
#line 1227 "Socket.hsc"
#ifdef AF_IMPLINK
#line 1229 "Socket.hsc"
#endif 
#line 1230 "Socket.hsc"
#ifdef AF_PUP
#line 1232 "Socket.hsc"
#endif 
#line 1233 "Socket.hsc"
#ifdef AF_CHAOS
#line 1235 "Socket.hsc"
#endif 
#line 1236 "Socket.hsc"
#ifdef AF_NS
#line 1238 "Socket.hsc"
#endif 
#line 1239 "Socket.hsc"
#ifdef AF_NBS
#line 1241 "Socket.hsc"
#endif 
#line 1242 "Socket.hsc"
#ifdef AF_ECMA
#line 1244 "Socket.hsc"
#endif 
#line 1245 "Socket.hsc"
#ifdef AF_DATAKIT
#line 1247 "Socket.hsc"
#endif 
#line 1248 "Socket.hsc"
#ifdef AF_CCITT
#line 1250 "Socket.hsc"
#endif 
#line 1251 "Socket.hsc"
#ifdef AF_SNA
#line 1253 "Socket.hsc"
#endif 
#line 1254 "Socket.hsc"
#ifdef AF_DECnet
#line 1256 "Socket.hsc"
#endif 
#line 1257 "Socket.hsc"
#ifdef AF_DLI
#line 1259 "Socket.hsc"
#endif 
#line 1260 "Socket.hsc"
#ifdef AF_LAT
#line 1262 "Socket.hsc"
#endif 
#line 1263 "Socket.hsc"
#ifdef AF_HYLINK
#line 1265 "Socket.hsc"
#endif 
#line 1266 "Socket.hsc"
#ifdef AF_APPLETALK
#line 1268 "Socket.hsc"
#endif 
#line 1269 "Socket.hsc"
#ifdef AF_ROUTE
#line 1271 "Socket.hsc"
#endif 
#line 1272 "Socket.hsc"
#ifdef AF_NETBIOS
#line 1274 "Socket.hsc"
#endif 
#line 1275 "Socket.hsc"
#ifdef AF_NIT
#line 1277 "Socket.hsc"
#endif 
#line 1278 "Socket.hsc"
#ifdef AF_802
#line 1280 "Socket.hsc"
#endif 
#line 1281 "Socket.hsc"
#ifdef AF_ISO
#line 1283 "Socket.hsc"
#endif 
#line 1284 "Socket.hsc"
#ifdef AF_OSI
#line 1286 "Socket.hsc"
#endif 
#line 1287 "Socket.hsc"
#ifdef AF_NETMAN
#line 1289 "Socket.hsc"
#endif 
#line 1290 "Socket.hsc"
#ifdef AF_X25
#line 1292 "Socket.hsc"
#endif 
#line 1293 "Socket.hsc"
#ifdef AF_AX25
#line 1295 "Socket.hsc"
#endif 
#line 1296 "Socket.hsc"
#ifdef AF_OSINET
#line 1298 "Socket.hsc"
#endif 
#line 1299 "Socket.hsc"
#ifdef AF_GOSSIP
#line 1301 "Socket.hsc"
#endif 
#line 1302 "Socket.hsc"
#ifdef AF_IPX
#line 1304 "Socket.hsc"
#endif 
#line 1305 "Socket.hsc"
#ifdef Pseudo_AF_XTP
#line 1307 "Socket.hsc"
#endif 
#line 1308 "Socket.hsc"
#ifdef AF_CTF
#line 1310 "Socket.hsc"
#endif 
#line 1311 "Socket.hsc"
#ifdef AF_WAN
#line 1313 "Socket.hsc"
#endif 
#line 1314 "Socket.hsc"
#ifdef AF_SDL
#line 1316 "Socket.hsc"
#endif 
#line 1317 "Socket.hsc"
#ifdef AF_NETWARE
#line 1319 "Socket.hsc"
#endif 
#line 1320 "Socket.hsc"
#ifdef AF_NDD
#line 1322 "Socket.hsc"
#endif 
#line 1323 "Socket.hsc"
#ifdef AF_INTF
#line 1325 "Socket.hsc"
#endif 
#line 1326 "Socket.hsc"
#ifdef AF_COIP
#line 1328 "Socket.hsc"
#endif 
#line 1329 "Socket.hsc"
#ifdef AF_CNT
#line 1331 "Socket.hsc"
#endif 
#line 1332 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
#line 1334 "Socket.hsc"
#endif 
#line 1335 "Socket.hsc"
#ifdef Pseudo_AF_PIP
#line 1337 "Socket.hsc"
#endif 
#line 1338 "Socket.hsc"
#ifdef AF_SIP
#line 1340 "Socket.hsc"
#endif 
#line 1341 "Socket.hsc"
#ifdef AF_ISDN
#line 1343 "Socket.hsc"
#endif 
#line 1344 "Socket.hsc"
#ifdef Pseudo_AF_KEY
#line 1346 "Socket.hsc"
#endif 
#line 1347 "Socket.hsc"
#ifdef AF_NATM
#line 1349 "Socket.hsc"
#endif 
#line 1350 "Socket.hsc"
#ifdef AF_ARP
#line 1352 "Socket.hsc"
#endif 
#line 1353 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
#line 1355 "Socket.hsc"
#endif 
#line 1356 "Socket.hsc"
#ifdef AF_ENCAP
#line 1358 "Socket.hsc"
#endif 
#line 1359 "Socket.hsc"
#ifdef AF_LINK
#line 1361 "Socket.hsc"
#endif 
#line 1362 "Socket.hsc"
#ifdef AF_RAW
#line 1364 "Socket.hsc"
#endif 
#line 1365 "Socket.hsc"
#ifdef AF_RIF
#line 1367 "Socket.hsc"
#endif 
#line 1373 "Socket.hsc"
#ifdef AF_UNIX
#line 1375 "Socket.hsc"
#endif 
#line 1376 "Socket.hsc"
#ifdef AF_INET
#line 1378 "Socket.hsc"
#endif 
#line 1379 "Socket.hsc"
#ifdef AF_INET6
#line 1381 "Socket.hsc"
#endif 
#line 1382 "Socket.hsc"
#ifdef AF_IMPLINK
#line 1384 "Socket.hsc"
#endif 
#line 1385 "Socket.hsc"
#ifdef AF_PUP
#line 1387 "Socket.hsc"
#endif 
#line 1388 "Socket.hsc"
#ifdef AF_CHAOS
#line 1390 "Socket.hsc"
#endif 
#line 1391 "Socket.hsc"
#ifdef AF_NS
#line 1393 "Socket.hsc"
#endif 
#line 1394 "Socket.hsc"
#ifdef AF_NBS
#line 1396 "Socket.hsc"
#endif 
#line 1397 "Socket.hsc"
#ifdef AF_ECMA
#line 1399 "Socket.hsc"
#endif 
#line 1400 "Socket.hsc"
#ifdef AF_DATAKIT
#line 1402 "Socket.hsc"
#endif 
#line 1403 "Socket.hsc"
#ifdef AF_CCITT
#line 1405 "Socket.hsc"
#endif 
#line 1406 "Socket.hsc"
#ifdef AF_SNA
#line 1408 "Socket.hsc"
#endif 
#line 1409 "Socket.hsc"
#ifdef AF_DECnet
#line 1411 "Socket.hsc"
#endif 
#line 1412 "Socket.hsc"
#ifdef AF_DLI
#line 1414 "Socket.hsc"
#endif 
#line 1415 "Socket.hsc"
#ifdef AF_LAT
#line 1417 "Socket.hsc"
#endif 
#line 1418 "Socket.hsc"
#ifdef AF_HYLINK
#line 1420 "Socket.hsc"
#endif 
#line 1421 "Socket.hsc"
#ifdef AF_APPLETALK
#line 1423 "Socket.hsc"
#endif 
#line 1424 "Socket.hsc"
#ifdef AF_ROUTE
#line 1426 "Socket.hsc"
#endif 
#line 1427 "Socket.hsc"
#ifdef AF_NETBIOS
#line 1429 "Socket.hsc"
#endif 
#line 1430 "Socket.hsc"
#ifdef AF_NIT
#line 1432 "Socket.hsc"
#endif 
#line 1433 "Socket.hsc"
#ifdef AF_802
#line 1435 "Socket.hsc"
#endif 
#line 1436 "Socket.hsc"
#ifdef AF_ISO
#line 1438 "Socket.hsc"
#endif 
#line 1439 "Socket.hsc"
#ifdef AF_OSI
#line 1440 "Socket.hsc"
#if (!defined(AF_ISO)) || (defined(AF_ISO) && (AF_ISO != AF_OSI))
#line 1442 "Socket.hsc"
#endif 
#line 1443 "Socket.hsc"
#endif 
#line 1444 "Socket.hsc"
#ifdef AF_NETMAN
#line 1446 "Socket.hsc"
#endif 
#line 1447 "Socket.hsc"
#ifdef AF_X25
#line 1449 "Socket.hsc"
#endif 
#line 1450 "Socket.hsc"
#ifdef AF_AX25
#line 1452 "Socket.hsc"
#endif 
#line 1453 "Socket.hsc"
#ifdef AF_OSINET
#line 1455 "Socket.hsc"
#endif 
#line 1456 "Socket.hsc"
#ifdef AF_GOSSIP
#line 1458 "Socket.hsc"
#endif 
#line 1459 "Socket.hsc"
#ifdef AF_IPX
#line 1461 "Socket.hsc"
#endif 
#line 1462 "Socket.hsc"
#ifdef Pseudo_AF_XTP
#line 1464 "Socket.hsc"
#endif 
#line 1465 "Socket.hsc"
#ifdef AF_CTF
#line 1467 "Socket.hsc"
#endif 
#line 1468 "Socket.hsc"
#ifdef AF_WAN
#line 1470 "Socket.hsc"
#endif 
#line 1471 "Socket.hsc"
#ifdef AF_SDL
#line 1473 "Socket.hsc"
#endif 
#line 1474 "Socket.hsc"
#ifdef AF_NETWARE
#line 1476 "Socket.hsc"
#endif 
#line 1477 "Socket.hsc"
#ifdef AF_NDD
#line 1479 "Socket.hsc"
#endif 
#line 1480 "Socket.hsc"
#ifdef AF_INTF
#line 1482 "Socket.hsc"
#endif 
#line 1483 "Socket.hsc"
#ifdef AF_COIP
#line 1485 "Socket.hsc"
#endif 
#line 1486 "Socket.hsc"
#ifdef AF_CNT
#line 1488 "Socket.hsc"
#endif 
#line 1489 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
#line 1491 "Socket.hsc"
#endif 
#line 1492 "Socket.hsc"
#ifdef Pseudo_AF_PIP
#line 1494 "Socket.hsc"
#endif 
#line 1495 "Socket.hsc"
#ifdef AF_SIP
#line 1497 "Socket.hsc"
#endif 
#line 1498 "Socket.hsc"
#ifdef AF_ISDN
#line 1500 "Socket.hsc"
#endif 
#line 1501 "Socket.hsc"
#ifdef Pseudo_AF_KEY
#line 1503 "Socket.hsc"
#endif 
#line 1504 "Socket.hsc"
#ifdef AF_NATM
#line 1506 "Socket.hsc"
#endif 
#line 1507 "Socket.hsc"
#ifdef AF_ARP
#line 1509 "Socket.hsc"
#endif 
#line 1510 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
#line 1512 "Socket.hsc"
#endif 
#line 1513 "Socket.hsc"
#ifdef AF_ENCAP
#line 1515 "Socket.hsc"
#endif 
#line 1516 "Socket.hsc"
#ifdef AF_LINK
#line 1518 "Socket.hsc"
#endif 
#line 1519 "Socket.hsc"
#ifdef AF_RAW
#line 1521 "Socket.hsc"
#endif 
#line 1522 "Socket.hsc"
#ifdef AF_RIF
#line 1524 "Socket.hsc"
#endif 
#line 1534 "Socket.hsc"
#ifdef SOCK_STREAM
#line 1536 "Socket.hsc"
#endif 
#line 1537 "Socket.hsc"
#ifdef SOCK_DGRAM
#line 1539 "Socket.hsc"
#endif 
#line 1540 "Socket.hsc"
#ifdef SOCK_RAW
#line 1542 "Socket.hsc"
#endif 
#line 1543 "Socket.hsc"
#ifdef SOCK_RDM
#line 1545 "Socket.hsc"
#endif 
#line 1546 "Socket.hsc"
#ifdef SOCK_SEQPACKET
#line 1548 "Socket.hsc"
#endif 
#line 1553 "Socket.hsc"
#ifdef SOCK_STREAM
#line 1555 "Socket.hsc"
#endif 
#line 1556 "Socket.hsc"
#ifdef SOCK_DGRAM
#line 1558 "Socket.hsc"
#endif 
#line 1559 "Socket.hsc"
#ifdef SOCK_RAW
#line 1561 "Socket.hsc"
#endif 
#line 1562 "Socket.hsc"
#ifdef SOCK_RDM
#line 1564 "Socket.hsc"
#endif 
#line 1565 "Socket.hsc"
#ifdef SOCK_SEQPACKET
#line 1567 "Socket.hsc"
#endif 
#line 1584 "Socket.hsc"
#ifdef SCM_RIGHTS
#line 1587 "Socket.hsc"
#endif 
#line 1643 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 1648 "Socket.hsc"
#endif 
#line 1672 "Socket.hsc"
#ifndef __PARALLEL_HASKELL__
#line 1675 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
#line 1677 "Socket.hsc"
#endif 
#line 1678 "Socket.hsc"
#ifdef __HUGS__
#line 1680 "Socket.hsc"
#endif 
#line 1681 "Socket.hsc"
#else 
#line 1684 "Socket.hsc"
#endif 
#line 1688 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
#line 1690 "Socket.hsc"
#else 
#line 1692 "Socket.hsc"
#endif 
#line 1712 "Socket.hsc"
#if !defined(WITH_WINSOCK)
#line 1714 "Socket.hsc"
#else 
#line 1725 "Socket.hsc"
#endif 
#line 1739 "Socket.hsc"
#if !defined(WITH_WINSOCK)
#line 1742 "Socket.hsc"
#else 
#line 1745 "Socket.hsc"
#endif 
#line 1779 "Socket.hsc"
#if defined(__GLASGOW_HASKELL__) && !(defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS))
#line 1807 "Socket.hsc"
#else 
#line 1820 "Socket.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
#line 1839 "Socket.hsc"
#if __GLASGOW_HASKELL__
#line 1841 "Socket.hsc"
#else 
#line 1843 "Socket.hsc"
#endif 
#line 1851 "Socket.hsc"
#else 
#line 1853 "Socket.hsc"
#endif 
#line 1854 "Socket.hsc"
#endif /* __GLASGOW_HASKELL */

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsNet.h\"");
#line 24 "Socket.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
    printf ("{-# OPTIONS %s #-}\n", "-optc-DWITH_WINSOCK=1");
#line 26 "Socket.hsc"
#endif 
#line 28 "Socket.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    printf ("{-# OPTIONS %s #-}\n", "-optc-DDOMAIN_SOCKET_SUPPORT=1");
#line 30 "Socket.hsc"
#endif 
#line 32 "Socket.hsc"
#if !defined(CALLCONV)
#line 33 "Socket.hsc"
#ifdef WITH_WINSOCK
    printf ("{-# OPTIONS %s #-}\n", "-optc-DCALLCONV=stdcall");
#line 35 "Socket.hsc"
#else 
    printf ("{-# OPTIONS %s #-}\n", "-optc-DCALLCONV=ccall");
#line 37 "Socket.hsc"
#endif 
#line 38 "Socket.hsc"
#endif 
#line 57 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 59 "Socket.hsc"
#endif 
#line 67 "Socket.hsc"
#ifdef SO_PEERCRED
#line 70 "Socket.hsc"
#endif 
#line 102 "Socket.hsc"
#ifdef DOMAIN_SOCKET_SUPPORT
#line 110 "Socket.hsc"
#endif 
#line 117 "Socket.hsc"
#ifdef SCM_RIGHTS
#line 119 "Socket.hsc"
#endif 
#line 145 "Socket.hsc"
#ifdef __HUGS__
#line 150 "Socket.hsc"
#endif 
#line 169 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
#line 171 "Socket.hsc"
#if defined(mingw32_TARGET_OS)
#line 174 "Socket.hsc"
#endif 
#line 178 "Socket.hsc"
#endif 
#line 316 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 319 "Socket.hsc"
#endif 
#line 322 "Socket.hsc"
#if defined(WITH_WINSOCK) || defined(cygwin32_TARGET_OS)
#line 324 "Socket.hsc"
#elif defined(darwin_TARGET_OS)
#line 326 "Socket.hsc"
#else 
#line 328 "Socket.hsc"
#endif 
#line 333 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 338 "Socket.hsc"
#endif 
#line 347 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 351 "Socket.hsc"
#endif 
#line 358 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 360 "Socket.hsc"
#endif 
#line 364 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 366 "Socket.hsc"
#endif 
#line 403 "Socket.hsc"
#if !defined(__HUGS__)
#line 405 "Socket.hsc"
#endif 
#line 413 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 430 "Socket.hsc"
#if !defined(__HUGS__)
#line 432 "Socket.hsc"
#endif 
#line 438 "Socket.hsc"
#endif 
#line 504 "Socket.hsc"
#if !(defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS))
#line 511 "Socket.hsc"
#else 
#line 521 "Socket.hsc"
#endif 
#line 525 "Socket.hsc"
#if !defined(__HUGS__)
#line 527 "Socket.hsc"
#endif 
#line 588 "Socket.hsc"
#if defined(mingw32_TARGET_OS) && !defined(__HUGS__)
#line 595 "Socket.hsc"
#else 
#line 598 "Socket.hsc"
#if !defined(__HUGS__)
#line 601 "Socket.hsc"
#endif 
#line 603 "Socket.hsc"
#if !defined(__HUGS__)
#line 605 "Socket.hsc"
#endif 
#line 606 "Socket.hsc"
#endif 
#line 611 "Socket.hsc"
#if defined(mingw32_TARGET_OS) && !defined(__HUGS__)
#line 620 "Socket.hsc"
#endif 
#line 634 "Socket.hsc"
#if !defined(__HUGS__)
#line 637 "Socket.hsc"
#endif 
#line 650 "Socket.hsc"
#if !defined(__HUGS__)
#line 653 "Socket.hsc"
#endif 
#line 681 "Socket.hsc"
#if !defined(__HUGS__)
#line 684 "Socket.hsc"
#endif 
#line 696 "Socket.hsc"
#if !defined(__HUGS__)
#line 699 "Socket.hsc"
#endif 
#line 753 "Socket.hsc"
#ifdef SO_DEBUG
#line 755 "Socket.hsc"
#endif 
#line 756 "Socket.hsc"
#ifdef SO_REUSEADDR
#line 758 "Socket.hsc"
#endif 
#line 759 "Socket.hsc"
#ifdef SO_TYPE
#line 761 "Socket.hsc"
#endif 
#line 762 "Socket.hsc"
#ifdef SO_ERROR
#line 764 "Socket.hsc"
#endif 
#line 765 "Socket.hsc"
#ifdef SO_DONTROUTE
#line 767 "Socket.hsc"
#endif 
#line 768 "Socket.hsc"
#ifdef SO_BROADCAST
#line 770 "Socket.hsc"
#endif 
#line 771 "Socket.hsc"
#ifdef SO_SNDBUF
#line 773 "Socket.hsc"
#endif 
#line 774 "Socket.hsc"
#ifdef SO_RCVBUF
#line 776 "Socket.hsc"
#endif 
#line 777 "Socket.hsc"
#ifdef SO_KEEPALIVE
#line 779 "Socket.hsc"
#endif 
#line 780 "Socket.hsc"
#ifdef SO_OOBINLINE
#line 782 "Socket.hsc"
#endif 
#line 783 "Socket.hsc"
#ifdef IP_TTL
#line 785 "Socket.hsc"
#endif 
#line 786 "Socket.hsc"
#ifdef TCP_MAXSEG
#line 788 "Socket.hsc"
#endif 
#line 789 "Socket.hsc"
#ifdef TCP_NODELAY
#line 791 "Socket.hsc"
#endif 
#line 792 "Socket.hsc"
#ifdef SO_LINGER
#line 794 "Socket.hsc"
#endif 
#line 795 "Socket.hsc"
#ifdef SO_REUSEPORT
#line 797 "Socket.hsc"
#endif 
#line 798 "Socket.hsc"
#ifdef SO_RCVLOWAT
#line 800 "Socket.hsc"
#endif 
#line 801 "Socket.hsc"
#ifdef SO_SNDLOWAT
#line 803 "Socket.hsc"
#endif 
#line 804 "Socket.hsc"
#ifdef SO_RCVTIMEO
#line 806 "Socket.hsc"
#endif 
#line 807 "Socket.hsc"
#ifdef SO_SNDTIMEO
#line 809 "Socket.hsc"
#endif 
#line 810 "Socket.hsc"
#ifdef SO_USELOOPBACK
#line 812 "Socket.hsc"
#endif 
#line 817 "Socket.hsc"
#ifdef IP_TTL
#line 819 "Socket.hsc"
#endif 
#line 820 "Socket.hsc"
#ifdef TCP_MAXSEG
#line 822 "Socket.hsc"
#endif 
#line 823 "Socket.hsc"
#ifdef TCP_NODELAY
#line 825 "Socket.hsc"
#endif 
#line 831 "Socket.hsc"
#ifdef SO_DEBUG
#line 833 "Socket.hsc"
#endif 
#line 834 "Socket.hsc"
#ifdef SO_REUSEADDR
#line 836 "Socket.hsc"
#endif 
#line 837 "Socket.hsc"
#ifdef SO_TYPE
#line 839 "Socket.hsc"
#endif 
#line 840 "Socket.hsc"
#ifdef SO_ERROR
#line 842 "Socket.hsc"
#endif 
#line 843 "Socket.hsc"
#ifdef SO_DONTROUTE
#line 845 "Socket.hsc"
#endif 
#line 846 "Socket.hsc"
#ifdef SO_BROADCAST
#line 848 "Socket.hsc"
#endif 
#line 849 "Socket.hsc"
#ifdef SO_SNDBUF
#line 851 "Socket.hsc"
#endif 
#line 852 "Socket.hsc"
#ifdef SO_RCVBUF
#line 854 "Socket.hsc"
#endif 
#line 855 "Socket.hsc"
#ifdef SO_KEEPALIVE
#line 857 "Socket.hsc"
#endif 
#line 858 "Socket.hsc"
#ifdef SO_OOBINLINE
#line 860 "Socket.hsc"
#endif 
#line 861 "Socket.hsc"
#ifdef IP_TTL
#line 863 "Socket.hsc"
#endif 
#line 864 "Socket.hsc"
#ifdef TCP_MAXSEG
#line 866 "Socket.hsc"
#endif 
#line 867 "Socket.hsc"
#ifdef TCP_NODELAY
#line 869 "Socket.hsc"
#endif 
#line 870 "Socket.hsc"
#ifdef SO_LINGER
#line 872 "Socket.hsc"
#endif 
#line 873 "Socket.hsc"
#ifdef SO_REUSEPORT
#line 875 "Socket.hsc"
#endif 
#line 876 "Socket.hsc"
#ifdef SO_RCVLOWAT
#line 878 "Socket.hsc"
#endif 
#line 879 "Socket.hsc"
#ifdef SO_SNDLOWAT
#line 881 "Socket.hsc"
#endif 
#line 882 "Socket.hsc"
#ifdef SO_RCVTIMEO
#line 884 "Socket.hsc"
#endif 
#line 885 "Socket.hsc"
#ifdef SO_SNDTIMEO
#line 887 "Socket.hsc"
#endif 
#line 888 "Socket.hsc"
#ifdef SO_USELOOPBACK
#line 890 "Socket.hsc"
#endif 
#line 915 "Socket.hsc"
#ifdef SO_PEERCRED
#line 932 "Socket.hsc"
#endif 
#line 934 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 940 "Socket.hsc"
#if !defined(__HUGS__)
#line 944 "Socket.hsc"
#else 
#line 946 "Socket.hsc"
#endif 
#line 956 "Socket.hsc"
#if !defined(__HUGS__)
#line 959 "Socket.hsc"
#endif 
#line 974 "Socket.hsc"
#if !defined(__HUGS__)
#line 977 "Socket.hsc"
#endif 
#line 994 "Socket.hsc"
#if !defined(__HUGS__)
#line 997 "Socket.hsc"
#endif 
#line 1013 "Socket.hsc"
#endif 
#line 1062 "Socket.hsc"
#ifdef AF_UNIX
#line 1064 "Socket.hsc"
#endif 
#line 1065 "Socket.hsc"
#ifdef AF_INET
#line 1067 "Socket.hsc"
#endif 
#line 1068 "Socket.hsc"
#ifdef AF_INET6
#line 1070 "Socket.hsc"
#endif 
#line 1071 "Socket.hsc"
#ifdef AF_IMPLINK
#line 1073 "Socket.hsc"
#endif 
#line 1074 "Socket.hsc"
#ifdef AF_PUP
#line 1076 "Socket.hsc"
#endif 
#line 1077 "Socket.hsc"
#ifdef AF_CHAOS
#line 1079 "Socket.hsc"
#endif 
#line 1080 "Socket.hsc"
#ifdef AF_NS
#line 1082 "Socket.hsc"
#endif 
#line 1083 "Socket.hsc"
#ifdef AF_NBS
#line 1085 "Socket.hsc"
#endif 
#line 1086 "Socket.hsc"
#ifdef AF_ECMA
#line 1088 "Socket.hsc"
#endif 
#line 1089 "Socket.hsc"
#ifdef AF_DATAKIT
#line 1091 "Socket.hsc"
#endif 
#line 1092 "Socket.hsc"
#ifdef AF_CCITT
#line 1094 "Socket.hsc"
#endif 
#line 1095 "Socket.hsc"
#ifdef AF_SNA
#line 1097 "Socket.hsc"
#endif 
#line 1098 "Socket.hsc"
#ifdef AF_DECnet
#line 1100 "Socket.hsc"
#endif 
#line 1101 "Socket.hsc"
#ifdef AF_DLI
#line 1103 "Socket.hsc"
#endif 
#line 1104 "Socket.hsc"
#ifdef AF_LAT
#line 1106 "Socket.hsc"
#endif 
#line 1107 "Socket.hsc"
#ifdef AF_HYLINK
#line 1109 "Socket.hsc"
#endif 
#line 1110 "Socket.hsc"
#ifdef AF_APPLETALK
#line 1112 "Socket.hsc"
#endif 
#line 1113 "Socket.hsc"
#ifdef AF_ROUTE
#line 1115 "Socket.hsc"
#endif 
#line 1116 "Socket.hsc"
#ifdef AF_NETBIOS
#line 1118 "Socket.hsc"
#endif 
#line 1119 "Socket.hsc"
#ifdef AF_NIT
#line 1121 "Socket.hsc"
#endif 
#line 1122 "Socket.hsc"
#ifdef AF_802
#line 1124 "Socket.hsc"
#endif 
#line 1125 "Socket.hsc"
#ifdef AF_ISO
#line 1127 "Socket.hsc"
#endif 
#line 1128 "Socket.hsc"
#ifdef AF_OSI
#line 1130 "Socket.hsc"
#endif 
#line 1131 "Socket.hsc"
#ifdef AF_NETMAN
#line 1133 "Socket.hsc"
#endif 
#line 1134 "Socket.hsc"
#ifdef AF_X25
#line 1136 "Socket.hsc"
#endif 
#line 1137 "Socket.hsc"
#ifdef AF_AX25
#line 1139 "Socket.hsc"
#endif 
#line 1140 "Socket.hsc"
#ifdef AF_OSINET
#line 1142 "Socket.hsc"
#endif 
#line 1143 "Socket.hsc"
#ifdef AF_GOSSIP
#line 1145 "Socket.hsc"
#endif 
#line 1146 "Socket.hsc"
#ifdef AF_IPX
#line 1148 "Socket.hsc"
#endif 
#line 1149 "Socket.hsc"
#ifdef Pseudo_AF_XTP
#line 1151 "Socket.hsc"
#endif 
#line 1152 "Socket.hsc"
#ifdef AF_CTF
#line 1154 "Socket.hsc"
#endif 
#line 1155 "Socket.hsc"
#ifdef AF_WAN
#line 1157 "Socket.hsc"
#endif 
#line 1158 "Socket.hsc"
#ifdef AF_SDL
#line 1160 "Socket.hsc"
#endif 
#line 1161 "Socket.hsc"
#ifdef AF_NETWARE
#line 1163 "Socket.hsc"
#endif 
#line 1164 "Socket.hsc"
#ifdef AF_NDD
#line 1166 "Socket.hsc"
#endif 
#line 1167 "Socket.hsc"
#ifdef AF_INTF
#line 1169 "Socket.hsc"
#endif 
#line 1170 "Socket.hsc"
#ifdef AF_COIP
#line 1172 "Socket.hsc"
#endif 
#line 1173 "Socket.hsc"
#ifdef AF_CNT
#line 1175 "Socket.hsc"
#endif 
#line 1176 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
#line 1178 "Socket.hsc"
#endif 
#line 1179 "Socket.hsc"
#ifdef Pseudo_AF_PIP
#line 1181 "Socket.hsc"
#endif 
#line 1182 "Socket.hsc"
#ifdef AF_SIP
#line 1184 "Socket.hsc"
#endif 
#line 1185 "Socket.hsc"
#ifdef AF_ISDN
#line 1187 "Socket.hsc"
#endif 
#line 1188 "Socket.hsc"
#ifdef Pseudo_AF_KEY
#line 1190 "Socket.hsc"
#endif 
#line 1191 "Socket.hsc"
#ifdef AF_NATM
#line 1193 "Socket.hsc"
#endif 
#line 1194 "Socket.hsc"
#ifdef AF_ARP
#line 1196 "Socket.hsc"
#endif 
#line 1197 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
#line 1199 "Socket.hsc"
#endif 
#line 1200 "Socket.hsc"
#ifdef AF_ENCAP
#line 1202 "Socket.hsc"
#endif 
#line 1203 "Socket.hsc"
#ifdef AF_LINK
#line 1205 "Socket.hsc"
#endif 
#line 1206 "Socket.hsc"
#ifdef AF_RAW
#line 1208 "Socket.hsc"
#endif 
#line 1209 "Socket.hsc"
#ifdef AF_RIF
#line 1211 "Socket.hsc"
#endif 
#line 1218 "Socket.hsc"
#ifdef AF_UNIX
#line 1220 "Socket.hsc"
#endif 
#line 1221 "Socket.hsc"
#ifdef AF_INET
#line 1223 "Socket.hsc"
#endif 
#line 1224 "Socket.hsc"
#ifdef AF_INET6
#line 1226 "Socket.hsc"
#endif 
#line 1227 "Socket.hsc"
#ifdef AF_IMPLINK
#line 1229 "Socket.hsc"
#endif 
#line 1230 "Socket.hsc"
#ifdef AF_PUP
#line 1232 "Socket.hsc"
#endif 
#line 1233 "Socket.hsc"
#ifdef AF_CHAOS
#line 1235 "Socket.hsc"
#endif 
#line 1236 "Socket.hsc"
#ifdef AF_NS
#line 1238 "Socket.hsc"
#endif 
#line 1239 "Socket.hsc"
#ifdef AF_NBS
#line 1241 "Socket.hsc"
#endif 
#line 1242 "Socket.hsc"
#ifdef AF_ECMA
#line 1244 "Socket.hsc"
#endif 
#line 1245 "Socket.hsc"
#ifdef AF_DATAKIT
#line 1247 "Socket.hsc"
#endif 
#line 1248 "Socket.hsc"
#ifdef AF_CCITT
#line 1250 "Socket.hsc"
#endif 
#line 1251 "Socket.hsc"
#ifdef AF_SNA
#line 1253 "Socket.hsc"
#endif 
#line 1254 "Socket.hsc"
#ifdef AF_DECnet
#line 1256 "Socket.hsc"
#endif 
#line 1257 "Socket.hsc"
#ifdef AF_DLI
#line 1259 "Socket.hsc"
#endif 
#line 1260 "Socket.hsc"
#ifdef AF_LAT
#line 1262 "Socket.hsc"
#endif 
#line 1263 "Socket.hsc"
#ifdef AF_HYLINK
#line 1265 "Socket.hsc"
#endif 
#line 1266 "Socket.hsc"
#ifdef AF_APPLETALK
#line 1268 "Socket.hsc"
#endif 
#line 1269 "Socket.hsc"
#ifdef AF_ROUTE
#line 1271 "Socket.hsc"
#endif 
#line 1272 "Socket.hsc"
#ifdef AF_NETBIOS
#line 1274 "Socket.hsc"
#endif 
#line 1275 "Socket.hsc"
#ifdef AF_NIT
#line 1277 "Socket.hsc"
#endif 
#line 1278 "Socket.hsc"
#ifdef AF_802
#line 1280 "Socket.hsc"
#endif 
#line 1281 "Socket.hsc"
#ifdef AF_ISO
#line 1283 "Socket.hsc"
#endif 
#line 1284 "Socket.hsc"
#ifdef AF_OSI
#line 1286 "Socket.hsc"
#endif 
#line 1287 "Socket.hsc"
#ifdef AF_NETMAN
#line 1289 "Socket.hsc"
#endif 
#line 1290 "Socket.hsc"
#ifdef AF_X25
#line 1292 "Socket.hsc"
#endif 
#line 1293 "Socket.hsc"
#ifdef AF_AX25
#line 1295 "Socket.hsc"
#endif 
#line 1296 "Socket.hsc"
#ifdef AF_OSINET
#line 1298 "Socket.hsc"
#endif 
#line 1299 "Socket.hsc"
#ifdef AF_GOSSIP
#line 1301 "Socket.hsc"
#endif 
#line 1302 "Socket.hsc"
#ifdef AF_IPX
#line 1304 "Socket.hsc"
#endif 
#line 1305 "Socket.hsc"
#ifdef Pseudo_AF_XTP
#line 1307 "Socket.hsc"
#endif 
#line 1308 "Socket.hsc"
#ifdef AF_CTF
#line 1310 "Socket.hsc"
#endif 
#line 1311 "Socket.hsc"
#ifdef AF_WAN
#line 1313 "Socket.hsc"
#endif 
#line 1314 "Socket.hsc"
#ifdef AF_SDL
#line 1316 "Socket.hsc"
#endif 
#line 1317 "Socket.hsc"
#ifdef AF_NETWARE
#line 1319 "Socket.hsc"
#endif 
#line 1320 "Socket.hsc"
#ifdef AF_NDD
#line 1322 "Socket.hsc"
#endif 
#line 1323 "Socket.hsc"
#ifdef AF_INTF
#line 1325 "Socket.hsc"
#endif 
#line 1326 "Socket.hsc"
#ifdef AF_COIP
#line 1328 "Socket.hsc"
#endif 
#line 1329 "Socket.hsc"
#ifdef AF_CNT
#line 1331 "Socket.hsc"
#endif 
#line 1332 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
#line 1334 "Socket.hsc"
#endif 
#line 1335 "Socket.hsc"
#ifdef Pseudo_AF_PIP
#line 1337 "Socket.hsc"
#endif 
#line 1338 "Socket.hsc"
#ifdef AF_SIP
#line 1340 "Socket.hsc"
#endif 
#line 1341 "Socket.hsc"
#ifdef AF_ISDN
#line 1343 "Socket.hsc"
#endif 
#line 1344 "Socket.hsc"
#ifdef Pseudo_AF_KEY
#line 1346 "Socket.hsc"
#endif 
#line 1347 "Socket.hsc"
#ifdef AF_NATM
#line 1349 "Socket.hsc"
#endif 
#line 1350 "Socket.hsc"
#ifdef AF_ARP
#line 1352 "Socket.hsc"
#endif 
#line 1353 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
#line 1355 "Socket.hsc"
#endif 
#line 1356 "Socket.hsc"
#ifdef AF_ENCAP
#line 1358 "Socket.hsc"
#endif 
#line 1359 "Socket.hsc"
#ifdef AF_LINK
#line 1361 "Socket.hsc"
#endif 
#line 1362 "Socket.hsc"
#ifdef AF_RAW
#line 1364 "Socket.hsc"
#endif 
#line 1365 "Socket.hsc"
#ifdef AF_RIF
#line 1367 "Socket.hsc"
#endif 
#line 1373 "Socket.hsc"
#ifdef AF_UNIX
#line 1375 "Socket.hsc"
#endif 
#line 1376 "Socket.hsc"
#ifdef AF_INET
#line 1378 "Socket.hsc"
#endif 
#line 1379 "Socket.hsc"
#ifdef AF_INET6
#line 1381 "Socket.hsc"
#endif 
#line 1382 "Socket.hsc"
#ifdef AF_IMPLINK
#line 1384 "Socket.hsc"
#endif 
#line 1385 "Socket.hsc"
#ifdef AF_PUP
#line 1387 "Socket.hsc"
#endif 
#line 1388 "Socket.hsc"
#ifdef AF_CHAOS
#line 1390 "Socket.hsc"
#endif 
#line 1391 "Socket.hsc"
#ifdef AF_NS
#line 1393 "Socket.hsc"
#endif 
#line 1394 "Socket.hsc"
#ifdef AF_NBS
#line 1396 "Socket.hsc"
#endif 
#line 1397 "Socket.hsc"
#ifdef AF_ECMA
#line 1399 "Socket.hsc"
#endif 
#line 1400 "Socket.hsc"
#ifdef AF_DATAKIT
#line 1402 "Socket.hsc"
#endif 
#line 1403 "Socket.hsc"
#ifdef AF_CCITT
#line 1405 "Socket.hsc"
#endif 
#line 1406 "Socket.hsc"
#ifdef AF_SNA
#line 1408 "Socket.hsc"
#endif 
#line 1409 "Socket.hsc"
#ifdef AF_DECnet
#line 1411 "Socket.hsc"
#endif 
#line 1412 "Socket.hsc"
#ifdef AF_DLI
#line 1414 "Socket.hsc"
#endif 
#line 1415 "Socket.hsc"
#ifdef AF_LAT
#line 1417 "Socket.hsc"
#endif 
#line 1418 "Socket.hsc"
#ifdef AF_HYLINK
#line 1420 "Socket.hsc"
#endif 
#line 1421 "Socket.hsc"
#ifdef AF_APPLETALK
#line 1423 "Socket.hsc"
#endif 
#line 1424 "Socket.hsc"
#ifdef AF_ROUTE
#line 1426 "Socket.hsc"
#endif 
#line 1427 "Socket.hsc"
#ifdef AF_NETBIOS
#line 1429 "Socket.hsc"
#endif 
#line 1430 "Socket.hsc"
#ifdef AF_NIT
#line 1432 "Socket.hsc"
#endif 
#line 1433 "Socket.hsc"
#ifdef AF_802
#line 1435 "Socket.hsc"
#endif 
#line 1436 "Socket.hsc"
#ifdef AF_ISO
#line 1438 "Socket.hsc"
#endif 
#line 1439 "Socket.hsc"
#ifdef AF_OSI
#line 1440 "Socket.hsc"
#if (!defined(AF_ISO)) || (defined(AF_ISO) && (AF_ISO != AF_OSI))
#line 1442 "Socket.hsc"
#endif 
#line 1443 "Socket.hsc"
#endif 
#line 1444 "Socket.hsc"
#ifdef AF_NETMAN
#line 1446 "Socket.hsc"
#endif 
#line 1447 "Socket.hsc"
#ifdef AF_X25
#line 1449 "Socket.hsc"
#endif 
#line 1450 "Socket.hsc"
#ifdef AF_AX25
#line 1452 "Socket.hsc"
#endif 
#line 1453 "Socket.hsc"
#ifdef AF_OSINET
#line 1455 "Socket.hsc"
#endif 
#line 1456 "Socket.hsc"
#ifdef AF_GOSSIP
#line 1458 "Socket.hsc"
#endif 
#line 1459 "Socket.hsc"
#ifdef AF_IPX
#line 1461 "Socket.hsc"
#endif 
#line 1462 "Socket.hsc"
#ifdef Pseudo_AF_XTP
#line 1464 "Socket.hsc"
#endif 
#line 1465 "Socket.hsc"
#ifdef AF_CTF
#line 1467 "Socket.hsc"
#endif 
#line 1468 "Socket.hsc"
#ifdef AF_WAN
#line 1470 "Socket.hsc"
#endif 
#line 1471 "Socket.hsc"
#ifdef AF_SDL
#line 1473 "Socket.hsc"
#endif 
#line 1474 "Socket.hsc"
#ifdef AF_NETWARE
#line 1476 "Socket.hsc"
#endif 
#line 1477 "Socket.hsc"
#ifdef AF_NDD
#line 1479 "Socket.hsc"
#endif 
#line 1480 "Socket.hsc"
#ifdef AF_INTF
#line 1482 "Socket.hsc"
#endif 
#line 1483 "Socket.hsc"
#ifdef AF_COIP
#line 1485 "Socket.hsc"
#endif 
#line 1486 "Socket.hsc"
#ifdef AF_CNT
#line 1488 "Socket.hsc"
#endif 
#line 1489 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
#line 1491 "Socket.hsc"
#endif 
#line 1492 "Socket.hsc"
#ifdef Pseudo_AF_PIP
#line 1494 "Socket.hsc"
#endif 
#line 1495 "Socket.hsc"
#ifdef AF_SIP
#line 1497 "Socket.hsc"
#endif 
#line 1498 "Socket.hsc"
#ifdef AF_ISDN
#line 1500 "Socket.hsc"
#endif 
#line 1501 "Socket.hsc"
#ifdef Pseudo_AF_KEY
#line 1503 "Socket.hsc"
#endif 
#line 1504 "Socket.hsc"
#ifdef AF_NATM
#line 1506 "Socket.hsc"
#endif 
#line 1507 "Socket.hsc"
#ifdef AF_ARP
#line 1509 "Socket.hsc"
#endif 
#line 1510 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
#line 1512 "Socket.hsc"
#endif 
#line 1513 "Socket.hsc"
#ifdef AF_ENCAP
#line 1515 "Socket.hsc"
#endif 
#line 1516 "Socket.hsc"
#ifdef AF_LINK
#line 1518 "Socket.hsc"
#endif 
#line 1519 "Socket.hsc"
#ifdef AF_RAW
#line 1521 "Socket.hsc"
#endif 
#line 1522 "Socket.hsc"
#ifdef AF_RIF
#line 1524 "Socket.hsc"
#endif 
#line 1534 "Socket.hsc"
#ifdef SOCK_STREAM
#line 1536 "Socket.hsc"
#endif 
#line 1537 "Socket.hsc"
#ifdef SOCK_DGRAM
#line 1539 "Socket.hsc"
#endif 
#line 1540 "Socket.hsc"
#ifdef SOCK_RAW
#line 1542 "Socket.hsc"
#endif 
#line 1543 "Socket.hsc"
#ifdef SOCK_RDM
#line 1545 "Socket.hsc"
#endif 
#line 1546 "Socket.hsc"
#ifdef SOCK_SEQPACKET
#line 1548 "Socket.hsc"
#endif 
#line 1553 "Socket.hsc"
#ifdef SOCK_STREAM
#line 1555 "Socket.hsc"
#endif 
#line 1556 "Socket.hsc"
#ifdef SOCK_DGRAM
#line 1558 "Socket.hsc"
#endif 
#line 1559 "Socket.hsc"
#ifdef SOCK_RAW
#line 1561 "Socket.hsc"
#endif 
#line 1562 "Socket.hsc"
#ifdef SOCK_RDM
#line 1564 "Socket.hsc"
#endif 
#line 1565 "Socket.hsc"
#ifdef SOCK_SEQPACKET
#line 1567 "Socket.hsc"
#endif 
#line 1584 "Socket.hsc"
#ifdef SCM_RIGHTS
#line 1587 "Socket.hsc"
#endif 
#line 1643 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
#line 1648 "Socket.hsc"
#endif 
#line 1672 "Socket.hsc"
#ifndef __PARALLEL_HASKELL__
#line 1675 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
#line 1677 "Socket.hsc"
#endif 
#line 1678 "Socket.hsc"
#ifdef __HUGS__
#line 1680 "Socket.hsc"
#endif 
#line 1681 "Socket.hsc"
#else 
#line 1684 "Socket.hsc"
#endif 
#line 1688 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
#line 1690 "Socket.hsc"
#else 
#line 1692 "Socket.hsc"
#endif 
#line 1712 "Socket.hsc"
#if !defined(WITH_WINSOCK)
#line 1714 "Socket.hsc"
#else 
#line 1725 "Socket.hsc"
#endif 
#line 1739 "Socket.hsc"
#if !defined(WITH_WINSOCK)
#line 1742 "Socket.hsc"
#else 
#line 1745 "Socket.hsc"
#endif 
#line 1779 "Socket.hsc"
#if defined(__GLASGOW_HASKELL__) && !(defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS))
#line 1807 "Socket.hsc"
#else 
#line 1820 "Socket.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
#line 1839 "Socket.hsc"
#if __GLASGOW_HASKELL__
#line 1841 "Socket.hsc"
#else 
#line 1843 "Socket.hsc"
#endif 
#line 1851 "Socket.hsc"
#else 
#line 1853 "Socket.hsc"
#endif 
#line 1854 "Socket.hsc"
#endif /* __GLASGOW_HASKELL */
    hsc_line (1, "Socket.hsc");
    fputs ("{-# OPTIONS -fglasgow-exts #-}\n"
           "", stdout);
    hsc_line (2, "Socket.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  Network.Socket\n"
           "-- Copyright   :  (c) The University of Glasgow 2001\n"
           "-- License     :  BSD-style (see the file libraries/core/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  portable\n"
           "--\n"
           "-- The \"Network.Socket\" module is for when you want full control over\n"
           "-- sockets.  Essentially the entire C socket API is exposed through\n"
           "-- this module; in general the operations follow the behaviour of the C\n"
           "-- functions of the same name (consult your favourite Unix networking book).\n"
           "--\n"
           "-- A higher level interface to networking operations is provided\n"
           "-- through the module \"Network\".\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (23, "Socket.hsc");
    fputs ("\n"
           "", stdout);
#line 24 "Socket.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (25, "Socket.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (26, "Socket.hsc");
    fputs ("", stdout);
#line 26 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (27, "Socket.hsc");
    fputs ("\n"
           "", stdout);
#line 28 "Socket.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (29, "Socket.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (30, "Socket.hsc");
    fputs ("", stdout);
#line 30 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (31, "Socket.hsc");
    fputs ("\n"
           "", stdout);
#line 32 "Socket.hsc"
#if !defined(CALLCONV)
    fputs ("\n"
           "", stdout);
    hsc_line (33, "Socket.hsc");
    fputs ("", stdout);
#line 33 "Socket.hsc"
#ifdef WITH_WINSOCK
    fputs ("\n"
           "", stdout);
    hsc_line (34, "Socket.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (35, "Socket.hsc");
    fputs ("", stdout);
#line 35 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (36, "Socket.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (37, "Socket.hsc");
    fputs ("", stdout);
#line 37 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (38, "Socket.hsc");
    fputs ("", stdout);
#line 38 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (39, "Socket.hsc");
    fputs ("\n"
           "-- In order to process this file, you need to have CALLCONV defined.\n"
           "\n"
           "module Network.Socket (\n"
           "\n"
           "    -- * Types\n"
           "    Socket(..),\t\t-- instance Eq, Show\n"
           "    Family(..),\t\t\n"
           "    SocketType(..),\n"
           "    SockAddr(..),\n"
           "    SocketStatus(..),\n"
           "    HostAddress,\n"
           "    ShutdownCmd(..),\n"
           "    ProtocolNumber,\n"
           "    PortNumber(..),\n"
           "\n"
           "    -- * Socket Operations\n"
           "    socket,\t\t-- :: Family -> SocketType -> ProtocolNumber -> IO Socket \n"
           "", stdout);
#line 57 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (58, "Socket.hsc");
    fputs ("    socketPair,         -- :: Family -> SocketType -> ProtocolNumber -> IO (Socket, Socket)\n"
           "", stdout);
#line 59 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (60, "Socket.hsc");
    fputs ("    connect,\t\t-- :: Socket -> SockAddr -> IO ()\n"
           "    bindSocket,\t\t-- :: Socket -> SockAddr -> IO ()\n"
           "    listen,\t\t-- :: Socket -> Int -> IO ()\n"
           "    accept,\t\t-- :: Socket -> IO (Socket, SockAddr)\n"
           "    getPeerName,\t-- :: Socket -> IO SockAddr\n"
           "    getSocketName,\t-- :: Socket -> IO SockAddr\n"
           "\n"
           "", stdout);
#line 67 "Socket.hsc"
#ifdef SO_PEERCRED
    fputs ("\n"
           "", stdout);
    hsc_line (68, "Socket.hsc");
    fputs ("\t-- get the credentials of our domain socket peer.\n"
           "    getPeerCred,         -- :: Socket -> IO (CUInt{-pid-}, CUInt{-uid-}, CUInt{-gid-})\n"
           "", stdout);
#line 70 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (71, "Socket.hsc");
    fputs ("\n"
           "    socketPort,\t\t-- :: Socket -> IO PortNumber\n"
           "\n"
           "    socketToHandle,\t-- :: Socket -> IOMode -> IO Handle\n"
           "\n"
           "    sendTo,\t\t-- :: Socket -> String -> SockAddr -> IO Int\n"
           "    recvFrom,\t\t-- :: Socket -> Int -> IO (String, Int, SockAddr)\n"
           "    \n"
           "    send,\t\t-- :: Socket -> String -> IO Int\n"
           "    recv,\t\t-- :: Socket -> Int    -> IO String\n"
           "    recvLen,            -- :: Socket -> Int    -> IO (String, Int)\n"
           "\n"
           "    inet_addr,\t\t-- :: String -> IO HostAddress\n"
           "    inet_ntoa,\t\t-- :: HostAddress -> IO String\n"
           "\n"
           "    shutdown,\t\t-- :: Socket -> ShutdownCmd -> IO ()\n"
           "    sClose,\t\t-- :: Socket -> IO ()\n"
           "\n"
           "    -- ** Predicates on sockets\n"
           "    sIsConnected,\t-- :: Socket -> IO Bool\n"
           "    sIsBound,\t\t-- :: Socket -> IO Bool\n"
           "    sIsListening,\t-- :: Socket -> IO Bool \n"
           "    sIsReadable,\t-- :: Socket -> IO Bool\n"
           "    sIsWritable,\t-- :: Socket -> IO Bool\n"
           "\n"
           "    -- * Socket options\n"
           "    SocketOption(..),\n"
           "    getSocketOption,     -- :: Socket -> SocketOption -> IO Int\n"
           "    setSocketOption,     -- :: Socket -> SocketOption -> Int -> IO ()\n"
           "\n"
           "    -- * File descriptor transmission\n"
           "", stdout);
#line 102 "Socket.hsc"
#ifdef DOMAIN_SOCKET_SUPPORT
    fputs ("\n"
           "", stdout);
    hsc_line (103, "Socket.hsc");
    fputs ("    sendFd,              -- :: Socket -> CInt -> IO ()\n"
           "    recvFd,              -- :: Socket -> IO CInt\n"
           "\n"
           "      -- Note: these two will disappear shortly\n"
           "    sendAncillary,       -- :: Socket -> Int -> Int -> Int -> Ptr a -> Int -> IO ()\n"
           "    recvAncillary,       -- :: Socket -> Int -> Int -> IO (Int,Int,Int,Ptr a)\n"
           "\n"
           "", stdout);
#line 110 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (111, "Socket.hsc");
    fputs ("\n"
           "    -- * Special Constants\n"
           "    aNY_PORT,\t\t-- :: PortNumber\n"
           "    iNADDR_ANY,\t\t-- :: HostAddress\n"
           "    sOMAXCONN,\t\t-- :: Int\n"
           "    sOL_SOCKET,         -- :: Int\n"
           "", stdout);
#line 117 "Socket.hsc"
#ifdef SCM_RIGHTS
    fputs ("\n"
           "", stdout);
    hsc_line (118, "Socket.hsc");
    fputs ("    sCM_RIGHTS,         -- :: Int\n"
           "", stdout);
#line 119 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (120, "Socket.hsc");
    fputs ("    maxListenQueue,\t-- :: Int\n"
           "\n"
           "    -- * Initialisation\n"
           "    withSocketsDo,\t-- :: IO a -> IO a\n"
           "    \n"
           "    -- * Very low level operations\n"
           "     -- in case you ever want to get at the underlying file descriptor..\n"
           "    fdSocket,           -- :: Socket -> CInt\n"
           "    mkSocket,           -- :: CInt   -> Family \n"
           "    \t\t\t-- -> SocketType\n"
           "\t\t\t-- -> ProtocolNumber\n"
           "\t\t\t-- -> SocketStatus\n"
           "\t\t\t-- -> IO Socket\n"
           "\n"
           "    -- * Internal\n"
           "\n"
           "    -- | The following are exported ONLY for use in the BSD module and\n"
           "    -- should not be used anywhere else.\n"
           "\n"
           "    packFamily, unpackFamily,\n"
           "    packSocketType,\n"
           "    throwSocketErrorIfMinus1_\n"
           "\n"
           ") where\n"
           "\n"
           "", stdout);
#line 145 "Socket.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (146, "Socket.hsc");
    fputs ("import Hugs.Prelude\n"
           "import Hugs.IO ( openFd )\n"
           "\n"
           "{-# CBITS HsNet.c initWinSock.c ancilData.c winSockErr.c #-}\n"
           "", stdout);
#line 150 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (151, "Socket.hsc");
    fputs ("\n"
           "import Data.Word ( Word8, Word16, Word32 )\n"
           "import Foreign.Ptr ( Ptr, castPtr, plusPtr )\n"
           "import Foreign.Storable ( Storable(..) )\n"
           "import Foreign.C.Error\n"
           "import Foreign.C.String ( withCString, peekCString, peekCStringLen, castCharToCChar )\n"
           "import Foreign.C.Types ( CInt, CUInt, CChar, CSize )\n"
           "import Foreign.Marshal.Alloc ( alloca, allocaBytes )\n"
           "import Foreign.Marshal.Array ( peekArray, pokeArray0 )\n"
           "import Foreign.Marshal.Utils ( with )\n"
           "\n"
           "import System.IO\n"
           "import Control.Monad ( liftM, when )\n"
           "import Data.Ratio ( (%) )\n"
           "\n"
           "import qualified Control.Exception\n"
           "import Control.Concurrent.MVar\n"
           "\n"
           "", stdout);
#line 169 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (170, "Socket.hsc");
    fputs ("import GHC.Conc\t\t(threadWaitRead, threadWaitWrite)\n"
           "", stdout);
#line 171 "Socket.hsc"
#if defined(mingw32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (172, "Socket.hsc");
    fputs ("import GHC.Conc         (asyncDoProc)\n"
           "import Foreign( FunPtr )\n"
           "", stdout);
#line 174 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (175, "Socket.hsc");
    fputs ("import GHC.Handle\n"
           "import GHC.IOBase\n"
           "import qualified System.Posix.Internals\n"
           "", stdout);
#line 178 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (179, "Socket.hsc");
    fputs ("\n"
           "-----------------------------------------------------------------------------\n"
           "-- Socket types\n"
           "\n"
           "-- There are a few possible ways to do this.  The first is convert the\n"
           "-- structs used in the C library into an equivalent Haskell type. An\n"
           "-- other possible implementation is to keep all the internals in the C\n"
           "-- code and use an Int## and a status flag. The second method is used\n"
           "-- here since a lot of the C structures are not required to be\n"
           "-- manipulated.\n"
           "\n"
           "-- Originally the status was non-mutable so we had to return a new\n"
           "-- socket each time we changed the status.  This version now uses\n"
           "-- mutable variables to avoid the need to do this.  The result is a\n"
           "-- cleaner interface and better security since the application\n"
           "-- programmer now can\'t circumvent the status information to perform\n"
           "-- invalid operations on sockets.\n"
           "\n"
           "data SocketStatus\n"
           "  -- Returned Status\tFunction called\n"
           "  = NotConnected\t-- socket\n"
           "  | Bound\t\t-- bindSocket\n"
           "  | Listening\t\t-- listen\n"
           "  | Connected\t\t-- connect/accept\n"
           "    deriving (Eq, Show)\n"
           "\n"
           "data Socket\n"
           "  = MkSocket\n"
           "\t    CInt\t         -- File Descriptor\n"
           "\t    Family\t\t\t\t  \n"
           "\t    SocketType\t\t\t\t  \n"
           "\t    ProtocolNumber\t -- Protocol Number\n"
           "\t    (MVar SocketStatus)  -- Status Flag\n"
           "\n"
           "mkSocket :: CInt\n"
           "\t -> Family\n"
           "\t -> SocketType\n"
           "\t -> ProtocolNumber\n"
           "\t -> SocketStatus\n"
           "\t -> IO Socket\n"
           "mkSocket fd fam sType pNum stat = do\n"
           "   mStat <- newMVar stat\n"
           "   return (MkSocket fd fam sType pNum mStat)\n"
           "\n"
           "instance Eq Socket where\n"
           "  (MkSocket _ _ _ _ m1) == (MkSocket _ _ _ _ m2) = m1 == m2\n"
           "\n"
           "instance Show Socket where\n"
           "  showsPrec n (MkSocket fd _ _ _ _) = \n"
           "\tshowString \"<socket: \" . shows fd . showString \">\"\n"
           "\n"
           "\n"
           "fdSocket :: Socket -> CInt\n"
           "fdSocket (MkSocket fd _ _ _ _) = fd\n"
           "\n"
           "type ProtocolNumber = CInt\n"
           "\n"
           "-- NOTE: HostAddresses are represented in network byte order.\n"
           "--       Functions that expect the address in machine byte order\n"
           "--       will have to perform the necessary translation.\n"
           "type HostAddress = Word32\n"
           "\n"
           "----------------------------------------------------------------------------\n"
           "-- Port Numbers\n"
           "--\n"
           "-- newtyped to prevent accidental use of sane-looking\n"
           "-- port numbers that haven\'t actually been converted to\n"
           "-- network-byte-order first.\n"
           "--\n"
           "newtype PortNumber = PortNum Word16 deriving ( Eq, Ord )\n"
           "\n"
           "instance Show PortNumber where\n"
           "  showsPrec p pn = showsPrec p (portNumberToInt pn)\n"
           "\n"
           "intToPortNumber :: Int -> PortNumber\n"
           "intToPortNumber v = PortNum (htons (fromIntegral v))\n"
           "\n"
           "portNumberToInt :: PortNumber -> Int\n"
           "portNumberToInt (PortNum po) = fromIntegral (ntohs po)\n"
           "\n"
           "foreign import CALLCONV unsafe \"ntohs\" ntohs :: Word16 -> Word16\n"
           "foreign import CALLCONV unsafe \"htons\" htons :: Word16 -> Word16\n"
           "--foreign import CALLCONV unsafe \"ntohl\" ntohl :: Word32 -> Word32\n"
           "foreign import CALLCONV unsafe \"htonl\" htonl :: Word32 -> Word32\n"
           "\n"
           "instance Enum PortNumber where\n"
           "    toEnum   = intToPortNumber\n"
           "    fromEnum = portNumberToInt\n"
           "\n"
           "instance Num PortNumber where\n"
           "   fromInteger i = intToPortNumber (fromInteger i)\n"
           "    -- for completeness.\n"
           "   (+) x y   = intToPortNumber (portNumberToInt x + portNumberToInt y)\n"
           "   (-) x y   = intToPortNumber (portNumberToInt x - portNumberToInt y)\n"
           "   negate x  = intToPortNumber (-portNumberToInt x)\n"
           "   (*) x y   = intToPortNumber (portNumberToInt x * portNumberToInt y)\n"
           "   abs n     = intToPortNumber (abs (portNumberToInt n))\n"
           "   signum n  = intToPortNumber (signum (portNumberToInt n))\n"
           "\n"
           "instance Real PortNumber where\n"
           "    toRational x = toInteger x % 1\n"
           "\n"
           "instance Integral PortNumber where\n"
           "    quotRem a b = let (c,d) = quotRem (portNumberToInt a) (portNumberToInt b) in\n"
           "\t\t  (intToPortNumber c, intToPortNumber d)\n"
           "    toInteger a = toInteger (portNumberToInt a)\n"
           "\n"
           "instance Storable PortNumber where\n"
           "   sizeOf    _ = sizeOf    (undefined :: Word16)\n"
           "   alignment _ = alignment (undefined :: Word16)\n"
           "   poke p (PortNum po) = poke (castPtr p) po\n"
           "   peek p = PortNum `liftM` peek (castPtr p)\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- SockAddr\n"
           "\n"
           "-- The scheme used for addressing sockets is somewhat quirky. The\n"
           "-- calls in the BSD socket API that need to know the socket address\n"
           "-- all operate in terms of struct sockaddr, a `virtual\' type of\n"
           "-- socket address.\n"
           "\n"
           "-- The Internet family of sockets are addressed as struct sockaddr_in,\n"
           "-- so when calling functions that operate on struct sockaddr, we have\n"
           "-- to type cast the Internet socket address into a struct sockaddr.\n"
           "-- Instances of the structure for different families might *not* be\n"
           "-- the same size. Same casting is required of other families of\n"
           "-- sockets such as Xerox NS. Similarly for Unix domain sockets.\n"
           "\n"
           "-- To represent these socket addresses in Haskell-land, we do what BSD\n"
           "-- didn\'t do, and use a union/algebraic type for the different\n"
           "-- families. Currently only Unix domain sockets and the Internet family\n"
           "-- are supported.\n"
           "\n"
           "data SockAddr\t\t-- C Names\t\t\t\t\n"
           "  = SockAddrInet\n"
           "\tPortNumber\t-- sin_port  (network byte order)\n"
           "\tHostAddress\t-- sin_addr  (ditto)\n"
           "", stdout);
#line 316 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (317, "Socket.hsc");
    fputs ("  | SockAddrUnix\n"
           "        String          -- sun_path\n"
           "", stdout);
#line 319 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (320, "Socket.hsc");
    fputs ("  deriving (Eq)\n"
           "\n"
           "", stdout);
#line 322 "Socket.hsc"
#if defined(WITH_WINSOCK) || defined(cygwin32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (323, "Socket.hsc");
    fputs ("type CSaFamily = (", stdout);
#line 323 "Socket.hsc"
    hsc_type (unsigned short);
    fputs (")\n"
           "", stdout);
    hsc_line (324, "Socket.hsc");
    fputs ("", stdout);
#line 324 "Socket.hsc"
#elif defined(darwin_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (325, "Socket.hsc");
    fputs ("type CSaFamily = (", stdout);
#line 325 "Socket.hsc"
    hsc_type (u_char);
    fputs (")\n"
           "", stdout);
    hsc_line (326, "Socket.hsc");
    fputs ("", stdout);
#line 326 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (327, "Socket.hsc");
    fputs ("type CSaFamily = (", stdout);
#line 327 "Socket.hsc"
    hsc_type (sa_family_t);
    fputs (")\n"
           "", stdout);
    hsc_line (328, "Socket.hsc");
    fputs ("", stdout);
#line 328 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (329, "Socket.hsc");
    fputs ("\n"
           "-- we can\'t write an instance of Storable for SockAddr, because the Storable\n"
           "-- class can\'t easily handle alternatives.\n"
           "\n"
           "", stdout);
#line 333 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (334, "Socket.hsc");
    fputs ("pokeSockAddr p (SockAddrUnix path) = do\n"
           "\t(", stdout);
#line 335 "Socket.hsc"
    hsc_poke (struct sockaddr_un, sun_family);
    fputs (") p ((", stdout);
#line 335 "Socket.hsc"
    hsc_const (AF_UNIX);
    fputs (") :: CSaFamily)\n"
           "", stdout);
    hsc_line (336, "Socket.hsc");
    fputs ("\tlet pathC = map castCharToCChar path\n"
           "\tpokeArray0 0 ((", stdout);
#line 337 "Socket.hsc"
    hsc_ptr (struct sockaddr_un, sun_path);
    fputs (") p) pathC\n"
           "", stdout);
    hsc_line (338, "Socket.hsc");
    fputs ("", stdout);
#line 338 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (339, "Socket.hsc");
    fputs ("pokeSockAddr p (SockAddrInet (PortNum port) addr) = do\n"
           "\t(", stdout);
#line 340 "Socket.hsc"
    hsc_poke (struct sockaddr_in, sin_family);
    fputs (") p ((", stdout);
#line 340 "Socket.hsc"
    hsc_const (AF_INET);
    fputs (") :: CSaFamily)\n"
           "", stdout);
    hsc_line (341, "Socket.hsc");
    fputs ("\t(", stdout);
#line 341 "Socket.hsc"
    hsc_poke (struct sockaddr_in, sin_port);
    fputs (") p port\n"
           "", stdout);
    hsc_line (342, "Socket.hsc");
    fputs ("\t(", stdout);
#line 342 "Socket.hsc"
    hsc_poke (struct sockaddr_in, sin_addr);
    fputs (") p addr\t\n"
           "", stdout);
    hsc_line (343, "Socket.hsc");
    fputs ("\n"
           "peekSockAddr p = do\n"
           "  family <- (", stdout);
#line 345 "Socket.hsc"
    hsc_peek (struct sockaddr, sa_family);
    fputs (") p\n"
           "", stdout);
    hsc_line (346, "Socket.hsc");
    fputs ("  case family :: CSaFamily of\n"
           "", stdout);
#line 347 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (348, "Socket.hsc");
    fputs ("\t(", stdout);
#line 348 "Socket.hsc"
    hsc_const (AF_UNIX);
    fputs (") -> do\n"
           "", stdout);
    hsc_line (349, "Socket.hsc");
    fputs ("\t\tstr <- peekCString ((", stdout);
#line 349 "Socket.hsc"
    hsc_ptr (struct sockaddr_un, sun_path);
    fputs (") p)\n"
           "", stdout);
    hsc_line (350, "Socket.hsc");
    fputs ("\t\treturn (SockAddrUnix str)\n"
           "", stdout);
#line 351 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (352, "Socket.hsc");
    fputs ("\t(", stdout);
#line 352 "Socket.hsc"
    hsc_const (AF_INET);
    fputs (") -> do\n"
           "", stdout);
    hsc_line (353, "Socket.hsc");
    fputs ("\t\taddr <- (", stdout);
#line 353 "Socket.hsc"
    hsc_peek (struct sockaddr_in, sin_addr);
    fputs (") p\n"
           "", stdout);
    hsc_line (354, "Socket.hsc");
    fputs ("\t\tport <- (", stdout);
#line 354 "Socket.hsc"
    hsc_peek (struct sockaddr_in, sin_port);
    fputs (") p\n"
           "", stdout);
    hsc_line (355, "Socket.hsc");
    fputs ("\t\treturn (SockAddrInet (PortNum port) addr)\n"
           "\n"
           "-- size of struct sockaddr by family\n"
           "", stdout);
#line 358 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (359, "Socket.hsc");
    fputs ("sizeOfSockAddr_Family AF_UNIX = ", stdout);
#line 359 "Socket.hsc"
    hsc_const (sizeof(struct sockaddr_un));
    fputs ("\n"
           "", stdout);
    hsc_line (360, "Socket.hsc");
    fputs ("", stdout);
#line 360 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (361, "Socket.hsc");
    fputs ("sizeOfSockAddr_Family AF_INET = ", stdout);
#line 361 "Socket.hsc"
    hsc_const (sizeof(struct sockaddr_in));
    fputs ("\n"
           "", stdout);
    hsc_line (362, "Socket.hsc");
    fputs ("\n"
           "-- size of struct sockaddr by SockAddr\n"
           "", stdout);
#line 364 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (365, "Socket.hsc");
    fputs ("sizeOfSockAddr (SockAddrUnix _)   = ", stdout);
#line 365 "Socket.hsc"
    hsc_const (sizeof(struct sockaddr_un));
    fputs ("\n"
           "", stdout);
    hsc_line (366, "Socket.hsc");
    fputs ("", stdout);
#line 366 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (367, "Socket.hsc");
    fputs ("sizeOfSockAddr (SockAddrInet _ _) = ", stdout);
#line 367 "Socket.hsc"
    hsc_const (sizeof(struct sockaddr_in));
    fputs ("\n"
           "", stdout);
    hsc_line (368, "Socket.hsc");
    fputs ("\n"
           "withSockAddr :: SockAddr -> (Ptr SockAddr -> Int -> IO a) -> IO a\n"
           "withSockAddr addr f = do\n"
           " let sz = sizeOfSockAddr addr\n"
           " allocaBytes sz $ \\p -> pokeSockAddr p addr >> f (castPtr p) sz\n"
           "\n"
           "withNewSockAddr :: Family -> (Ptr SockAddr -> Int -> IO a) -> IO a\n"
           "withNewSockAddr family f = do\n"
           " let sz = sizeOfSockAddr_Family family\n"
           " allocaBytes sz $ \\ptr -> f ptr sz\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- Connection Functions\n"
           "\n"
           "-- In the following connection and binding primitives.  The names of\n"
           "-- the equivalent C functions have been preserved where possible. It\n"
           "-- should be noted that some of these names used in the C library,\n"
           "-- \\tr{bind} in particular, have a different meaning to many Haskell\n"
           "-- programmers and have thus been renamed by appending the prefix\n"
           "-- Socket.\n"
           "\n"
           "-- Create an unconnected socket of the given family, type and\n"
           "-- protocol.  The most common invocation of $socket$ is the following:\n"
           "--    ...\n"
           "--    my_socket <- socket AF_INET Stream 6\n"
           "--    ...\n"
           "\n"
           "socket :: Family \t -- Family Name (usually AF_INET)\n"
           "       -> SocketType \t -- Socket Type (usually Stream)\n"
           "       -> ProtocolNumber -- Protocol Number (getProtocolByName to find value)\n"
           "       -> IO Socket\t -- Unconnected Socket\n"
           "\n"
           "socket family stype protocol = do\n"
           "    fd <- throwSocketErrorIfMinus1Retry \"socket\" $\n"
           "\t\tc_socket (packFamily family) (packSocketType stype) protocol\n"
           "", stdout);
#line 403 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (404, "Socket.hsc");
    fputs ("    System.Posix.Internals.setNonBlockingFD fd\n"
           "", stdout);
#line 405 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (406, "Socket.hsc");
    fputs ("    socket_status <- newMVar NotConnected\n"
           "    return (MkSocket fd family stype protocol socket_status)\n"
           "\n"
           "-- Create an unnamed pair of connected sockets, given family, type and\n"
           "-- protocol. Differs from a normal pipe in being a bi-directional channel\n"
           "-- of communication.\n"
           "\n"
           "", stdout);
#line 413 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (414, "Socket.hsc");
    fputs ("socketPair :: Family \t          -- Family Name (usually AF_INET)\n"
           "           -> SocketType \t  -- Socket Type (usually Stream)\n"
           "           -> ProtocolNumber      -- Protocol Number\n"
           "           -> IO (Socket, Socket) -- unnamed and connected.\n"
           "socketPair family stype protocol = do\n"
           "    allocaBytes (2 * sizeOf (1 :: CInt)) $ \\ fdArr -> do\n"
           "    rc <- throwSocketErrorIfMinus1Retry \"socketpair\" $\n"
           "\t\tc_socketpair (packFamily family)\n"
           "\t\t\t     (packSocketType stype)\n"
           "\t\t\t     protocol fdArr\n"
           "    [fd1,fd2] <- peekArray 2 fdArr \n"
           "    s1 <- mkSocket fd1\n"
           "    s2 <- mkSocket fd2\n"
           "    return (s1,s2)\n"
           "  where\n"
           "    mkSocket fd = do\n"
           "", stdout);
#line 430 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (431, "Socket.hsc");
    fputs ("       System.Posix.Internals.setNonBlockingFD fd\n"
           "", stdout);
#line 432 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (433, "Socket.hsc");
    fputs ("       stat <- newMVar Connected\n"
           "       return (MkSocket fd family stype protocol stat)\n"
           "\n"
           "foreign import ccall unsafe \"socketpair\"\n"
           "  c_socketpair :: CInt -> CInt -> CInt -> Ptr CInt -> IO CInt\n"
           "", stdout);
#line 438 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (439, "Socket.hsc");
    fputs ("\n"
           "-----------------------------------------------------------------------------\n"
           "-- Binding a socket\n"
           "--\n"
           "-- Given a port number this {\\em binds} the socket to that port. This\n"
           "-- means that the programmer is only interested in data being sent to\n"
           "-- that port number. The $Family$ passed to $bindSocket$ must\n"
           "-- be the same as that passed to $socket$.\t If the special port\n"
           "-- number $aNY\\_PORT$ is passed then the system assigns the next\n"
           "-- available use port.\n"
           "-- \n"
           "-- Port numbers for standard unix services can be found by calling\n"
           "-- $getServiceEntry$.  These are traditionally port numbers below\n"
           "-- 1000; although there are afew, namely NFS and IRC, which used higher\n"
           "-- numbered ports.\n"
           "-- \n"
           "-- The port number allocated to a socket bound by using $aNY\\_PORT$ can be\n"
           "-- found by calling $port$\n"
           "\n"
           "bindSocket :: Socket\t-- Unconnected Socket\n"
           "\t   -> SockAddr\t-- Address to Bind to\n"
           "\t   -> IO ()\n"
           "\n"
           "bindSocket (MkSocket s _family _stype _protocol socketStatus) addr = do\n"
           " modifyMVar_ socketStatus $ \\ status -> do\n"
           " if status /= NotConnected \n"
           "  then\n"
           "   ioError (userError (\"bindSocket: can\'t peform bind on socket in status \" ++\n"
           "\t show status))\n"
           "  else do\n"
           "   withSockAddr addr $ \\p_addr sz -> do\n"
           "   status <- throwSocketErrorIfMinus1Retry \"bind\" $ c_bind s p_addr (fromIntegral sz)\n"
           "   return Bound\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- Connecting a socket\n"
           "--\n"
           "-- Make a connection to an already opened socket on a given machine\n"
           "-- and port.  assumes that we have already called createSocket,\n"
           "-- otherwise it will fail.\n"
           "--\n"
           "-- This is the dual to $bindSocket$.  The {\\em server} process will\n"
           "-- usually bind to a port number, the {\\em client} will then connect\n"
           "-- to the same port number.  Port numbers of user applications are\n"
           "-- normally agreed in advance, otherwise we must rely on some meta\n"
           "-- protocol for telling the other side what port number we have been\n"
           "-- allocated.\n"
           "\n"
           "connect :: Socket\t-- Unconnected Socket\n"
           "\t-> SockAddr \t-- Socket address stuff\n"
           "\t-> IO ()\n"
           "\n"
           "connect sock@(MkSocket s _family _stype _protocol socketStatus) addr = do\n"
           " modifyMVar_ socketStatus $ \\currentStatus -> do\n"
           " if currentStatus /= NotConnected \n"
           "  then\n"
           "   ioError (userError (\"connect: can\'t peform connect on socket in status \" ++\n"
           "         show currentStatus))\n"
           "  else do\n"
           "   withSockAddr addr $ \\p_addr sz -> do\n"
           "\n"
           "   let  connectLoop = do\n"
           "       \t   r <- c_connect s p_addr (fromIntegral sz)\n"
           "       \t   if r == -1\n"
           "       \t       then do \n"
           "", stdout);
#line 504 "Socket.hsc"
#if !(defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS))
    fputs ("\n"
           "", stdout);
    hsc_line (505, "Socket.hsc");
    fputs ("\t       \t       err <- getErrno\n"
           "\t\t       case () of\n"
           "\t\t\t _ | err == eINTR       -> connectLoop\n"
           "\t\t\t _ | err == eINPROGRESS -> connectBlocked\n"
           "--\t\t\t _ | err == eAGAIN      -> connectBlocked\n"
           "\t\t\t otherwise              -> throwErrno \"connect\"\n"
           "", stdout);
#line 511 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (512, "Socket.hsc");
    fputs ("\t\t       rc <- c_getLastError\n"
           "\t\t       case rc of\n"
           "\t\t         10093 -> do -- WSANOTINITIALISED\n"
           "\t\t\t   withSocketsDo (return ())\n"
           "\t       \t           r <- c_connect s p_addr (fromIntegral sz)\n"
           "\t       \t           if r == -1\n"
           "\t\t\t    then (c_getLastError >>= throwSocketError \"connect\")\n"
           "\t\t\t    else return r\n"
           "\t\t\t _ -> throwSocketError \"connect\" rc\n"
           "", stdout);
#line 521 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (522, "Socket.hsc");
    fputs ("       \t       else return r\n"
           "\n"
           "\tconnectBlocked = do \n"
           "", stdout);
#line 525 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (526, "Socket.hsc");
    fputs ("\t   threadWaitWrite (fromIntegral s)\n"
           "", stdout);
#line 527 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (528, "Socket.hsc");
    fputs ("\t   err <- getSocketOption sock SoError\n"
           "\t   if (err == 0)\n"
           "\t   \tthen return 0\n"
           "\t   \telse do ioError (errnoToIOError \"connect\" \n"
           "\t   \t\t\t(Errno (fromIntegral err))\n"
           "\t   \t\t\tNothing Nothing)\n"
           "\n"
           "   connectLoop\n"
           "   return Connected\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- Listen\n"
           "--\n"
           "-- The programmer must call $listen$ to tell the system software that\n"
           "-- they are now interested in receiving data on this port.  This must\n"
           "-- be called on the bound socket before any calls to read or write\n"
           "-- data are made.\n"
           "\n"
           "-- The programmer also gives a number which indicates the length of\n"
           "-- the incoming queue of unread messages for this socket. On most\n"
           "-- systems the maximum queue length is around 5.  To remove a message\n"
           "-- from the queue for processing a call to $accept$ should be made.\n"
           "\n"
           "listen :: Socket  -- Connected & Bound Socket\n"
           "       -> Int \t  -- Queue Length\n"
           "       -> IO ()\n"
           "\n"
           "listen (MkSocket s _family _stype _protocol socketStatus) backlog = do\n"
           " modifyMVar_ socketStatus $ \\ status -> do\n"
           " if status /= Bound \n"
           "   then\n"
           "    ioError (userError (\"listen: can\'t peform listen on socket in status \" ++\n"
           "          show status))\n"
           "   else do\n"
           "    throwSocketErrorIfMinus1Retry \"listen\" (c_listen s (fromIntegral backlog))\n"
           "    return Listening\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- Accept\n"
           "--\n"
           "-- A call to `accept\' only returns when data is available on the given\n"
           "-- socket, unless the socket has been set to non-blocking.  It will\n"
           "-- return a new socket which should be used to read the incoming data and\n"
           "-- should then be closed. Using the socket returned by `accept\' allows\n"
           "-- incoming requests to be queued on the original socket.\n"
           "\n"
           "accept :: Socket\t\t\t-- Queue Socket\n"
           "       -> IO (Socket,\t\t\t-- Readable Socket\n"
           "\t      SockAddr)\t\t\t-- Peer details\n"
           "\n"
           "accept sock@(MkSocket s family stype protocol status) = do\n"
           " currentStatus <- readMVar status\n"
           " okay <- sIsAcceptable sock\n"
           " if not okay\n"
           "   then\n"
           "     ioError (userError (\"accept: can\'t perform accept on socket (\" ++ (show (family,stype,protocol)) ++\") in status \" ++\n"
           "\t show currentStatus))\n"
           "   else do\n"
           "     let sz = sizeOfSockAddr_Family family\n"
           "     allocaBytes sz $ \\ sockaddr -> do\n"
           "", stdout);
#line 588 "Socket.hsc"
#if defined(mingw32_TARGET_OS) && !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (589, "Socket.hsc");
    fputs ("     paramData <- c_newAcceptParams s (fromIntegral sz) sockaddr\n"
           "     rc        <- asyncDoProc c_acceptDoProc paramData\n"
           "     new_sock  <- c_acceptNewSock    paramData\n"
           "     c_free paramData\n"
           "     when (rc /= 0)\n"
           "          (ioError (errnoToIOError \"Network.Socket.accept\" (Errno (fromIntegral rc)) Nothing Nothing))\n"
           "", stdout);
#line 595 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (596, "Socket.hsc");
    fputs ("     with (fromIntegral sz) $ \\ ptr_len -> do\n"
           "     new_sock <- \n"
           "", stdout);
#line 598 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (599, "Socket.hsc");
    fputs ("                 throwErrnoIfMinus1Retry_repeatOnBlock \"accept\" \n"
           "\t\t\t(threadWaitRead (fromIntegral s))\n"
           "", stdout);
#line 601 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (602, "Socket.hsc");
    fputs ("\t\t\t(c_accept s sockaddr ptr_len)\n"
           "", stdout);
#line 603 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (604, "Socket.hsc");
    fputs ("     System.Posix.Internals.setNonBlockingFD new_sock\n"
           "", stdout);
#line 605 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (606, "Socket.hsc");
    fputs ("", stdout);
#line 606 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (607, "Socket.hsc");
    fputs ("     addr <- peekSockAddr sockaddr\n"
           "     new_status <- newMVar Connected\n"
           "     return ((MkSocket new_sock family stype protocol new_status), addr)\n"
           "\n"
           "", stdout);
#line 611 "Socket.hsc"
#if defined(mingw32_TARGET_OS) && !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (612, "Socket.hsc");
    fputs ("foreign import ccall unsafe \"HsNet.h acceptNewSock\"\n"
           "  c_acceptNewSock :: Ptr () -> IO CInt\n"
           "foreign import ccall unsafe \"HsNet.h newAcceptParams\"\n"
           "  c_newAcceptParams :: CInt -> CInt -> Ptr a -> IO (Ptr ())\n"
           "foreign import ccall unsafe \"HsNet.h &acceptDoProc\"\n"
           "  c_acceptDoProc :: FunPtr (Ptr () -> IO Int)\n"
           "foreign import ccall unsafe \"free\"\n"
           "  c_free:: Ptr a -> IO ()\n"
           "", stdout);
#line 620 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (621, "Socket.hsc");
    fputs ("\n"
           "-----------------------------------------------------------------------------\n"
           "-- sendTo & recvFrom\n"
           "\n"
           "sendTo :: Socket\t-- (possibly) bound/connected Socket\n"
           "       -> String\t-- Data to send\n"
           "       -> SockAddr\n"
           "       -> IO Int\t-- Number of Bytes sent\n"
           "\n"
           "sendTo (MkSocket s _family _stype _protocol status) xs addr = do\n"
           " withSockAddr addr $ \\p_addr sz -> do\n"
           " withCString xs $ \\str -> do\n"
           "   liftM fromIntegral $\n"
           "", stdout);
#line 634 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (635, "Socket.hsc");
    fputs ("     throwErrnoIfMinus1Retry_repeatOnBlock \"sendTo\"\n"
           "\t(threadWaitWrite (fromIntegral s)) $\n"
           "", stdout);
#line 637 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (638, "Socket.hsc");
    fputs ("\tc_sendto s str (fromIntegral $ length xs) 0{-flags-} \n"
           "\t\t\tp_addr (fromIntegral sz)\n"
           "\n"
           "recvFrom :: Socket -> Int -> IO (String, Int, SockAddr)\n"
           "recvFrom sock@(MkSocket s _family _stype _protocol status) nbytes\n"
           " | nbytes <= 0 = ioError (mkInvalidRecvArgError \"Network.Socket.recvFrom\")\n"
           " | otherwise   = \n"
           "  allocaBytes nbytes $ \\ptr -> do\n"
           "    withNewSockAddr AF_INET $ \\ptr_addr sz -> do\n"
           "      alloca $ \\ptr_len -> do\n"
           "      \tpoke ptr_len (fromIntegral sz)\n"
           "        len <- \n"
           "", stdout);
#line 650 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (651, "Socket.hsc");
    fputs ("\t       throwErrnoIfMinus1Retry_repeatOnBlock \"recvFrom\" \n"
           "        \t   (threadWaitRead (fromIntegral s)) $\n"
           "", stdout);
#line 653 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (654, "Socket.hsc");
    fputs ("        \t   c_recvfrom s ptr (fromIntegral nbytes) 0{-flags-} \n"
           "\t\t\t\tptr_addr ptr_len\n"
           "        let len\' = fromIntegral len\n"
           "\tif len\' == 0\n"
           "\t then ioError (mkEOFError \"Network.Socket.recvFrom\")\n"
           "\t else do\n"
           "   \t   flg <- sIsConnected sock\n"
           "\t     -- For at least one implementation (WinSock 2), recvfrom() ignores\n"
           "\t     -- filling in the sockaddr for connected TCP sockets. Cope with \n"
           "\t     -- this by using getPeerName instead.\n"
           "\t   sockaddr <- \n"
           "\t\tif flg then\n"
           "\t\t   getPeerName sock\n"
           "\t\telse\n"
           "\t\t   peekSockAddr ptr_addr \n"
           "           str <- peekCStringLen (ptr,len\')\n"
           "           return (str, len\', sockaddr)\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- send & recv\n"
           "\n"
           "send :: Socket\t-- Bound/Connected Socket\n"
           "     -> String\t-- Data to send\n"
           "     -> IO Int\t-- Number of Bytes sent\n"
           "send (MkSocket s _family _stype _protocol status) xs = do\n"
           " withCString xs $ \\str -> do\n"
           "   liftM fromIntegral $\n"
           "", stdout);
#line 681 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (682, "Socket.hsc");
    fputs ("     throwErrnoIfMinus1Retry_repeatOnBlock \"send\"\n"
           "\t(threadWaitWrite (fromIntegral s)) $\n"
           "", stdout);
#line 684 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (685, "Socket.hsc");
    fputs ("\tc_send s str (fromIntegral $ length xs) 0{-flags-} \n"
           "\n"
           "recv :: Socket -> Int -> IO String\n"
           "recv sock l = recvLen sock l >>= \\ (s,_) -> return s\n"
           "\n"
           "recvLen :: Socket -> Int -> IO (String, Int)\n"
           "recvLen sock@(MkSocket s _family _stype _protocol status) nbytes \n"
           " | nbytes <= 0 = ioError (mkInvalidRecvArgError \"Network.Socket.recv\")\n"
           " | otherwise   = do\n"
           "     allocaBytes nbytes $ \\ptr -> do\n"
           "        len <- \n"
           "", stdout);
#line 696 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (697, "Socket.hsc");
    fputs ("\t       throwErrnoIfMinus1Retry_repeatOnBlock \"recv\" \n"
           "        \t   (threadWaitRead (fromIntegral s)) $\n"
           "", stdout);
#line 699 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (700, "Socket.hsc");
    fputs ("        \t   c_recv s ptr (fromIntegral nbytes) 0{-flags-} \n"
           "        let len\' = fromIntegral len\n"
           "\tif len\' == 0\n"
           "\t then ioError (mkEOFError \"Network.Socket.recv\")\n"
           "\t else do\n"
           "\t   s <- peekCStringLen (ptr,len\')\n"
           "\t   return (s, len\')\n"
           "\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- socketPort\n"
           "--\n"
           "-- The port number the given socket is currently connected to can be\n"
           "-- determined by calling $port$, is generally only useful when bind\n"
           "-- was given $aNY\\_PORT$.\n"
           "\n"
           "socketPort :: Socket\t\t-- Connected & Bound Socket\n"
           "\t   -> IO PortNumber\t-- Port Number of Socket\n"
           "socketPort sock@(MkSocket _ AF_INET _ _ _) = do\n"
           "    (SockAddrInet port _) <- getSocketName sock\n"
           "    return port\n"
           "socketPort (MkSocket _ family _ _ _) =\n"
           "    ioError (userError (\"socketPort: not supported for Family \" ++ show family))\n"
           "\n"
           "\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- getPeerName\n"
           "\n"
           "-- Calling $getPeerName$ returns the address details of the machine,\n"
           "-- other than the local one, which is connected to the socket. This is\n"
           "-- used in programs such as FTP to determine where to send the\n"
           "-- returning data.  The corresponding call to get the details of the\n"
           "-- local machine is $getSocketName$.\n"
           "\n"
           "getPeerName   :: Socket -> IO SockAddr\n"
           "getPeerName (MkSocket s family _ _ _) = do\n"
           " withNewSockAddr family $ \\ptr sz -> do\n"
           "   with (fromIntegral sz) $ \\int_star -> do\n"
           "   throwSocketErrorIfMinus1Retry \"getPeerName\" $ c_getpeername s ptr int_star\n"
           "   sz <- peek int_star\n"
           "   peekSockAddr ptr\n"
           "    \n"
           "getSocketName :: Socket -> IO SockAddr\n"
           "getSocketName (MkSocket s family _ _ _) = do\n"
           " withNewSockAddr family $ \\ptr sz -> do\n"
           "   with (fromIntegral sz) $ \\int_star -> do\n"
           "   throwSocketErrorIfMinus1Retry \"getSocketName\" $ c_getsockname s ptr int_star\n"
           "   peekSockAddr ptr\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- Socket Properties\n"
           "\n"
           "data SocketOption\n"
           "    = DummySocketOption__\n"
           "", stdout);
#line 753 "Socket.hsc"
#ifdef SO_DEBUG
    fputs ("\n"
           "", stdout);
    hsc_line (754, "Socket.hsc");
    fputs ("    | Debug         {- SO_DEBUG     -}\n"
           "", stdout);
#line 755 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (756, "Socket.hsc");
    fputs ("", stdout);
#line 756 "Socket.hsc"
#ifdef SO_REUSEADDR
    fputs ("\n"
           "", stdout);
    hsc_line (757, "Socket.hsc");
    fputs ("    | ReuseAddr     {- SO_REUSEADDR -}\n"
           "", stdout);
#line 758 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (759, "Socket.hsc");
    fputs ("", stdout);
#line 759 "Socket.hsc"
#ifdef SO_TYPE
    fputs ("\n"
           "", stdout);
    hsc_line (760, "Socket.hsc");
    fputs ("    | Type          {- SO_TYPE      -}\n"
           "", stdout);
#line 761 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (762, "Socket.hsc");
    fputs ("", stdout);
#line 762 "Socket.hsc"
#ifdef SO_ERROR
    fputs ("\n"
           "", stdout);
    hsc_line (763, "Socket.hsc");
    fputs ("    | SoError       {- SO_ERROR     -}\n"
           "", stdout);
#line 764 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (765, "Socket.hsc");
    fputs ("", stdout);
#line 765 "Socket.hsc"
#ifdef SO_DONTROUTE
    fputs ("\n"
           "", stdout);
    hsc_line (766, "Socket.hsc");
    fputs ("    | DontRoute     {- SO_DONTROUTE -}\n"
           "", stdout);
#line 767 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (768, "Socket.hsc");
    fputs ("", stdout);
#line 768 "Socket.hsc"
#ifdef SO_BROADCAST
    fputs ("\n"
           "", stdout);
    hsc_line (769, "Socket.hsc");
    fputs ("    | Broadcast     {- SO_BROADCAST -}\n"
           "", stdout);
#line 770 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (771, "Socket.hsc");
    fputs ("", stdout);
#line 771 "Socket.hsc"
#ifdef SO_SNDBUF
    fputs ("\n"
           "", stdout);
    hsc_line (772, "Socket.hsc");
    fputs ("    | SendBuffer    {- SO_SNDBUF    -}\n"
           "", stdout);
#line 773 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (774, "Socket.hsc");
    fputs ("", stdout);
#line 774 "Socket.hsc"
#ifdef SO_RCVBUF
    fputs ("\n"
           "", stdout);
    hsc_line (775, "Socket.hsc");
    fputs ("    | RecvBuffer    {- SO_RCVBUF    -}\n"
           "", stdout);
#line 776 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (777, "Socket.hsc");
    fputs ("", stdout);
#line 777 "Socket.hsc"
#ifdef SO_KEEPALIVE
    fputs ("\n"
           "", stdout);
    hsc_line (778, "Socket.hsc");
    fputs ("    | KeepAlive     {- SO_KEEPALIVE -}\n"
           "", stdout);
#line 779 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (780, "Socket.hsc");
    fputs ("", stdout);
#line 780 "Socket.hsc"
#ifdef SO_OOBINLINE
    fputs ("\n"
           "", stdout);
    hsc_line (781, "Socket.hsc");
    fputs ("    | OOBInline     {- SO_OOBINLINE -}\n"
           "", stdout);
#line 782 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (783, "Socket.hsc");
    fputs ("", stdout);
#line 783 "Socket.hsc"
#ifdef IP_TTL
    fputs ("\n"
           "", stdout);
    hsc_line (784, "Socket.hsc");
    fputs ("    | TimeToLive    {- IP_TTL       -}\n"
           "", stdout);
#line 785 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (786, "Socket.hsc");
    fputs ("", stdout);
#line 786 "Socket.hsc"
#ifdef TCP_MAXSEG
    fputs ("\n"
           "", stdout);
    hsc_line (787, "Socket.hsc");
    fputs ("    | MaxSegment    {- TCP_MAXSEG   -}\n"
           "", stdout);
#line 788 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (789, "Socket.hsc");
    fputs ("", stdout);
#line 789 "Socket.hsc"
#ifdef TCP_NODELAY
    fputs ("\n"
           "", stdout);
    hsc_line (790, "Socket.hsc");
    fputs ("    | NoDelay       {- TCP_NODELAY  -}\n"
           "", stdout);
#line 791 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (792, "Socket.hsc");
    fputs ("", stdout);
#line 792 "Socket.hsc"
#ifdef SO_LINGER
    fputs ("\n"
           "", stdout);
    hsc_line (793, "Socket.hsc");
    fputs ("    | Linger        {- SO_LINGER    -}\n"
           "", stdout);
#line 794 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (795, "Socket.hsc");
    fputs ("", stdout);
#line 795 "Socket.hsc"
#ifdef SO_REUSEPORT
    fputs ("\n"
           "", stdout);
    hsc_line (796, "Socket.hsc");
    fputs ("    | ReusePort     {- SO_REUSEPORT -}\n"
           "", stdout);
#line 797 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (798, "Socket.hsc");
    fputs ("", stdout);
#line 798 "Socket.hsc"
#ifdef SO_RCVLOWAT
    fputs ("\n"
           "", stdout);
    hsc_line (799, "Socket.hsc");
    fputs ("    | RecvLowWater  {- SO_RCVLOWAT  -}\n"
           "", stdout);
#line 800 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (801, "Socket.hsc");
    fputs ("", stdout);
#line 801 "Socket.hsc"
#ifdef SO_SNDLOWAT
    fputs ("\n"
           "", stdout);
    hsc_line (802, "Socket.hsc");
    fputs ("    | SendLowWater  {- SO_SNDLOWAT  -}\n"
           "", stdout);
#line 803 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (804, "Socket.hsc");
    fputs ("", stdout);
#line 804 "Socket.hsc"
#ifdef SO_RCVTIMEO
    fputs ("\n"
           "", stdout);
    hsc_line (805, "Socket.hsc");
    fputs ("    | RecvTimeOut   {- SO_RCVTIMEO  -}\n"
           "", stdout);
#line 806 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (807, "Socket.hsc");
    fputs ("", stdout);
#line 807 "Socket.hsc"
#ifdef SO_SNDTIMEO
    fputs ("\n"
           "", stdout);
    hsc_line (808, "Socket.hsc");
    fputs ("    | SendTimeOut   {- SO_SNDTIMEO  -}\n"
           "", stdout);
#line 809 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (810, "Socket.hsc");
    fputs ("", stdout);
#line 810 "Socket.hsc"
#ifdef SO_USELOOPBACK
    fputs ("\n"
           "", stdout);
    hsc_line (811, "Socket.hsc");
    fputs ("    | UseLoopBack   {- SO_USELOOPBACK -}\n"
           "", stdout);
#line 812 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (813, "Socket.hsc");
    fputs ("\n"
           "socketOptLevel :: SocketOption -> CInt\n"
           "socketOptLevel so = \n"
           "  case so of\n"
           "", stdout);
#line 817 "Socket.hsc"
#ifdef IP_TTL
    fputs ("\n"
           "", stdout);
    hsc_line (818, "Socket.hsc");
    fputs ("    TimeToLive   -> ", stdout);
#line 818 "Socket.hsc"
    hsc_const (IPPROTO_IP);
    fputs ("\n"
           "", stdout);
    hsc_line (819, "Socket.hsc");
    fputs ("", stdout);
#line 819 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (820, "Socket.hsc");
    fputs ("", stdout);
#line 820 "Socket.hsc"
#ifdef TCP_MAXSEG
    fputs ("\n"
           "", stdout);
    hsc_line (821, "Socket.hsc");
    fputs ("    MaxSegment   -> ", stdout);
#line 821 "Socket.hsc"
    hsc_const (IPPROTO_TCP);
    fputs ("\n"
           "", stdout);
    hsc_line (822, "Socket.hsc");
    fputs ("", stdout);
#line 822 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (823, "Socket.hsc");
    fputs ("", stdout);
#line 823 "Socket.hsc"
#ifdef TCP_NODELAY
    fputs ("\n"
           "", stdout);
    hsc_line (824, "Socket.hsc");
    fputs ("    NoDelay      -> ", stdout);
#line 824 "Socket.hsc"
    hsc_const (IPPROTO_TCP);
    fputs ("\n"
           "", stdout);
    hsc_line (825, "Socket.hsc");
    fputs ("", stdout);
#line 825 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (826, "Socket.hsc");
    fputs ("    _            -> ", stdout);
#line 826 "Socket.hsc"
    hsc_const (SOL_SOCKET);
    fputs ("\n"
           "", stdout);
    hsc_line (827, "Socket.hsc");
    fputs ("\n"
           "packSocketOption :: SocketOption -> CInt\n"
           "packSocketOption so =\n"
           "  case so of\n"
           "", stdout);
#line 831 "Socket.hsc"
#ifdef SO_DEBUG
    fputs ("\n"
           "", stdout);
    hsc_line (832, "Socket.hsc");
    fputs ("    Debug         -> ", stdout);
#line 832 "Socket.hsc"
    hsc_const (SO_DEBUG);
    fputs ("\n"
           "", stdout);
    hsc_line (833, "Socket.hsc");
    fputs ("", stdout);
#line 833 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (834, "Socket.hsc");
    fputs ("", stdout);
#line 834 "Socket.hsc"
#ifdef SO_REUSEADDR
    fputs ("\n"
           "", stdout);
    hsc_line (835, "Socket.hsc");
    fputs ("    ReuseAddr     -> ", stdout);
#line 835 "Socket.hsc"
    hsc_const (SO_REUSEADDR);
    fputs ("\n"
           "", stdout);
    hsc_line (836, "Socket.hsc");
    fputs ("", stdout);
#line 836 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (837, "Socket.hsc");
    fputs ("", stdout);
#line 837 "Socket.hsc"
#ifdef SO_TYPE
    fputs ("\n"
           "", stdout);
    hsc_line (838, "Socket.hsc");
    fputs ("    Type          -> ", stdout);
#line 838 "Socket.hsc"
    hsc_const (SO_TYPE);
    fputs ("\n"
           "", stdout);
    hsc_line (839, "Socket.hsc");
    fputs ("", stdout);
#line 839 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (840, "Socket.hsc");
    fputs ("", stdout);
#line 840 "Socket.hsc"
#ifdef SO_ERROR
    fputs ("\n"
           "", stdout);
    hsc_line (841, "Socket.hsc");
    fputs ("    SoError       -> ", stdout);
#line 841 "Socket.hsc"
    hsc_const (SO_ERROR);
    fputs ("\n"
           "", stdout);
    hsc_line (842, "Socket.hsc");
    fputs ("", stdout);
#line 842 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (843, "Socket.hsc");
    fputs ("", stdout);
#line 843 "Socket.hsc"
#ifdef SO_DONTROUTE
    fputs ("\n"
           "", stdout);
    hsc_line (844, "Socket.hsc");
    fputs ("    DontRoute     -> ", stdout);
#line 844 "Socket.hsc"
    hsc_const (SO_DONTROUTE);
    fputs ("\n"
           "", stdout);
    hsc_line (845, "Socket.hsc");
    fputs ("", stdout);
#line 845 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (846, "Socket.hsc");
    fputs ("", stdout);
#line 846 "Socket.hsc"
#ifdef SO_BROADCAST
    fputs ("\n"
           "", stdout);
    hsc_line (847, "Socket.hsc");
    fputs ("    Broadcast     -> ", stdout);
#line 847 "Socket.hsc"
    hsc_const (SO_BROADCAST);
    fputs ("\n"
           "", stdout);
    hsc_line (848, "Socket.hsc");
    fputs ("", stdout);
#line 848 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (849, "Socket.hsc");
    fputs ("", stdout);
#line 849 "Socket.hsc"
#ifdef SO_SNDBUF
    fputs ("\n"
           "", stdout);
    hsc_line (850, "Socket.hsc");
    fputs ("    SendBuffer    -> ", stdout);
#line 850 "Socket.hsc"
    hsc_const (SO_SNDBUF);
    fputs ("\n"
           "", stdout);
    hsc_line (851, "Socket.hsc");
    fputs ("", stdout);
#line 851 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (852, "Socket.hsc");
    fputs ("", stdout);
#line 852 "Socket.hsc"
#ifdef SO_RCVBUF
    fputs ("\n"
           "", stdout);
    hsc_line (853, "Socket.hsc");
    fputs ("    RecvBuffer    -> ", stdout);
#line 853 "Socket.hsc"
    hsc_const (SO_RCVBUF);
    fputs ("\n"
           "", stdout);
    hsc_line (854, "Socket.hsc");
    fputs ("", stdout);
#line 854 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (855, "Socket.hsc");
    fputs ("", stdout);
#line 855 "Socket.hsc"
#ifdef SO_KEEPALIVE
    fputs ("\n"
           "", stdout);
    hsc_line (856, "Socket.hsc");
    fputs ("    KeepAlive     -> ", stdout);
#line 856 "Socket.hsc"
    hsc_const (SO_KEEPALIVE);
    fputs ("\n"
           "", stdout);
    hsc_line (857, "Socket.hsc");
    fputs ("", stdout);
#line 857 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (858, "Socket.hsc");
    fputs ("", stdout);
#line 858 "Socket.hsc"
#ifdef SO_OOBINLINE
    fputs ("\n"
           "", stdout);
    hsc_line (859, "Socket.hsc");
    fputs ("    OOBInline     -> ", stdout);
#line 859 "Socket.hsc"
    hsc_const (SO_OOBINLINE);
    fputs ("\n"
           "", stdout);
    hsc_line (860, "Socket.hsc");
    fputs ("", stdout);
#line 860 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (861, "Socket.hsc");
    fputs ("", stdout);
#line 861 "Socket.hsc"
#ifdef IP_TTL
    fputs ("\n"
           "", stdout);
    hsc_line (862, "Socket.hsc");
    fputs ("    TimeToLive    -> ", stdout);
#line 862 "Socket.hsc"
    hsc_const (IP_TTL);
    fputs ("\n"
           "", stdout);
    hsc_line (863, "Socket.hsc");
    fputs ("", stdout);
#line 863 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (864, "Socket.hsc");
    fputs ("", stdout);
#line 864 "Socket.hsc"
#ifdef TCP_MAXSEG
    fputs ("\n"
           "", stdout);
    hsc_line (865, "Socket.hsc");
    fputs ("    MaxSegment    -> ", stdout);
#line 865 "Socket.hsc"
    hsc_const (TCP_MAXSEG);
    fputs ("\n"
           "", stdout);
    hsc_line (866, "Socket.hsc");
    fputs ("", stdout);
#line 866 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (867, "Socket.hsc");
    fputs ("", stdout);
#line 867 "Socket.hsc"
#ifdef TCP_NODELAY
    fputs ("\n"
           "", stdout);
    hsc_line (868, "Socket.hsc");
    fputs ("    NoDelay       -> ", stdout);
#line 868 "Socket.hsc"
    hsc_const (TCP_NODELAY);
    fputs ("\n"
           "", stdout);
    hsc_line (869, "Socket.hsc");
    fputs ("", stdout);
#line 869 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (870, "Socket.hsc");
    fputs ("", stdout);
#line 870 "Socket.hsc"
#ifdef SO_LINGER
    fputs ("\n"
           "", stdout);
    hsc_line (871, "Socket.hsc");
    fputs ("    Linger\t  -> ", stdout);
#line 871 "Socket.hsc"
    hsc_const (SO_LINGER);
    fputs ("\n"
           "", stdout);
    hsc_line (872, "Socket.hsc");
    fputs ("", stdout);
#line 872 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (873, "Socket.hsc");
    fputs ("", stdout);
#line 873 "Socket.hsc"
#ifdef SO_REUSEPORT
    fputs ("\n"
           "", stdout);
    hsc_line (874, "Socket.hsc");
    fputs ("    ReusePort     -> ", stdout);
#line 874 "Socket.hsc"
    hsc_const (SO_REUSEPORT);
    fputs ("\n"
           "", stdout);
    hsc_line (875, "Socket.hsc");
    fputs ("", stdout);
#line 875 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (876, "Socket.hsc");
    fputs ("", stdout);
#line 876 "Socket.hsc"
#ifdef SO_RCVLOWAT
    fputs ("\n"
           "", stdout);
    hsc_line (877, "Socket.hsc");
    fputs ("    RecvLowWater  -> ", stdout);
#line 877 "Socket.hsc"
    hsc_const (SO_RCVLOWAT);
    fputs ("\n"
           "", stdout);
    hsc_line (878, "Socket.hsc");
    fputs ("", stdout);
#line 878 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (879, "Socket.hsc");
    fputs ("", stdout);
#line 879 "Socket.hsc"
#ifdef SO_SNDLOWAT
    fputs ("\n"
           "", stdout);
    hsc_line (880, "Socket.hsc");
    fputs ("    SendLowWater  -> ", stdout);
#line 880 "Socket.hsc"
    hsc_const (SO_SNDLOWAT);
    fputs ("\n"
           "", stdout);
    hsc_line (881, "Socket.hsc");
    fputs ("", stdout);
#line 881 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (882, "Socket.hsc");
    fputs ("", stdout);
#line 882 "Socket.hsc"
#ifdef SO_RCVTIMEO
    fputs ("\n"
           "", stdout);
    hsc_line (883, "Socket.hsc");
    fputs ("    RecvTimeOut   -> ", stdout);
#line 883 "Socket.hsc"
    hsc_const (SO_RCVTIMEO);
    fputs ("\n"
           "", stdout);
    hsc_line (884, "Socket.hsc");
    fputs ("", stdout);
#line 884 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (885, "Socket.hsc");
    fputs ("", stdout);
#line 885 "Socket.hsc"
#ifdef SO_SNDTIMEO
    fputs ("\n"
           "", stdout);
    hsc_line (886, "Socket.hsc");
    fputs ("    SendTimeOut   -> ", stdout);
#line 886 "Socket.hsc"
    hsc_const (SO_SNDTIMEO);
    fputs ("\n"
           "", stdout);
    hsc_line (887, "Socket.hsc");
    fputs ("", stdout);
#line 887 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (888, "Socket.hsc");
    fputs ("", stdout);
#line 888 "Socket.hsc"
#ifdef SO_USELOOPBACK
    fputs ("\n"
           "", stdout);
    hsc_line (889, "Socket.hsc");
    fputs ("    UseLoopBack   -> ", stdout);
#line 889 "Socket.hsc"
    hsc_const (SO_USELOOPBACK);
    fputs ("\n"
           "", stdout);
    hsc_line (890, "Socket.hsc");
    fputs ("", stdout);
#line 890 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (891, "Socket.hsc");
    fputs ("\n"
           "setSocketOption :: Socket \n"
           "\t\t-> SocketOption -- Option Name\n"
           "\t\t-> Int\t\t-- Option Value\n"
           "\t\t-> IO ()\n"
           "setSocketOption (MkSocket s _ _ _ _) so v = do\n"
           "   with (fromIntegral v) $ \\ptr_v -> do\n"
           "   throwErrnoIfMinus1_ \"setSocketOption\" $\n"
           "       c_setsockopt s (socketOptLevel so) (packSocketOption so) ptr_v \n"
           "\t  (fromIntegral (sizeOf v))\n"
           "   return ()\n"
           "\n"
           "\n"
           "getSocketOption :: Socket\n"
           "\t\t-> SocketOption  -- Option Name\n"
           "\t\t-> IO Int\t -- Option Value\n"
           "getSocketOption (MkSocket s _ _ _ _) so = do\n"
           "   alloca $ \\ptr_v ->\n"
           "     with (fromIntegral (sizeOf (undefined :: CInt))) $ \\ptr_sz -> do\n"
           "       throwErrnoIfMinus1 \"getSocketOption\" $\n"
           "\t c_getsockopt s (socketOptLevel so) (packSocketOption so) ptr_v ptr_sz\n"
           "       fromIntegral `liftM` peek ptr_v\n"
           "\n"
           "\n"
           "", stdout);
#line 915 "Socket.hsc"
#ifdef SO_PEERCRED
    fputs ("\n"
           "", stdout);
    hsc_line (916, "Socket.hsc");
    fputs ("-- | Returns the processID, userID and groupID of the socket\'s peer.\n"
           "--\n"
           "-- Only available on platforms that support SO_PEERCRED on domain sockets.\n"
           "getPeerCred :: Socket -> IO (CUInt, CUInt, CUInt)\n"
           "getPeerCred sock = do\n"
           "  let fd = fdSocket sock\n"
           "  let sz = (fromIntegral (", stdout);
#line 922 "Socket.hsc"
    hsc_const (sizeof(struct ucred));
    fputs ("))\n"
           "", stdout);
    hsc_line (923, "Socket.hsc");
    fputs ("  with sz $ \\ ptr_cr -> \n"
           "   alloca       $ \\ ptr_sz -> do\n"
           "     poke ptr_sz sz\n"
           "     throwErrnoIfMinus1 \"getPeerCred\" $\n"
           "       c_getsockopt fd (", stdout);
#line 927 "Socket.hsc"
    hsc_const (SOL_SOCKET);
    fputs (") (", stdout);
#line 927 "Socket.hsc"
    hsc_const (SO_PEERCRED);
    fputs (") ptr_cr ptr_sz\n"
           "", stdout);
    hsc_line (928, "Socket.hsc");
    fputs ("     pid <- (", stdout);
#line 928 "Socket.hsc"
    hsc_peek (struct ucred, pid);
    fputs (") ptr_cr\n"
           "", stdout);
    hsc_line (929, "Socket.hsc");
    fputs ("     uid <- (", stdout);
#line 929 "Socket.hsc"
    hsc_peek (struct ucred, uid);
    fputs (") ptr_cr\n"
           "", stdout);
    hsc_line (930, "Socket.hsc");
    fputs ("     gid <- (", stdout);
#line 930 "Socket.hsc"
    hsc_peek (struct ucred, gid);
    fputs (") ptr_cr\n"
           "", stdout);
    hsc_line (931, "Socket.hsc");
    fputs ("     return (pid, uid, gid)\n"
           "", stdout);
#line 932 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (933, "Socket.hsc");
    fputs ("\n"
           "", stdout);
#line 934 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (935, "Socket.hsc");
    fputs ("-- sending/receiving ancillary socket data; low-level mechanism\n"
           "-- for transmitting file descriptors, mainly.\n"
           "sendFd :: Socket -> CInt -> IO ()\n"
           "sendFd sock outfd = do\n"
           "  let fd = fdSocket sock\n"
           "", stdout);
#line 940 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (941, "Socket.hsc");
    fputs ("  throwErrnoIfMinus1Retry_repeatOnBlock \"sendFd\"\n"
           "     (threadWaitWrite (fromIntegral fd)) $\n"
           "     c_sendFd fd outfd\n"
           "", stdout);
#line 944 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (945, "Socket.hsc");
    fputs ("  c_sendFd fd outfd\n"
           "", stdout);
#line 946 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (947, "Socket.hsc");
    fputs ("   -- Note: If Winsock supported FD-passing, thi would have been \n"
           "   -- incorrect (since socket FDs need to be closed via closesocket().)\n"
           "  c_close outfd\n"
           "  return ()\n"
           "  \n"
           "recvFd :: Socket -> IO CInt\n"
           "recvFd sock = do\n"
           "  let fd = fdSocket sock\n"
           "  theFd <- \n"
           "", stdout);
#line 956 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (957, "Socket.hsc");
    fputs ("    throwErrnoIfMinus1Retry_repeatOnBlock \"recvFd\" \n"
           "        (threadWaitRead (fromIntegral fd)) $\n"
           "", stdout);
#line 959 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (960, "Socket.hsc");
    fputs ("         c_recvFd fd\n"
           "  return theFd\n"
           "\n"
           "\n"
           "sendAncillary :: Socket\n"
           "\t      -> Int\n"
           "\t      -> Int\n"
           "\t      -> Int\n"
           "\t      -> Ptr a\n"
           "\t      -> Int\n"
           "\t      -> IO ()\n"
           "sendAncillary sock level ty flags datum len = do\n"
           "  let fd = fdSocket sock\n"
           "  _ <-\n"
           "", stdout);
#line 974 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (975, "Socket.hsc");
    fputs ("   throwErrnoIfMinus1Retry_repeatOnBlock \"sendAncillary\"\n"
           "     (threadWaitWrite (fromIntegral fd)) $\n"
           "", stdout);
#line 977 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (978, "Socket.hsc");
    fputs ("     c_sendAncillary fd (fromIntegral level) (fromIntegral ty)\n"
           "     \t\t\t(fromIntegral flags) datum (fromIntegral len)\n"
           "  return ()\n"
           "\n"
           "recvAncillary :: Socket\n"
           "\t      -> Int\n"
           "\t      -> Int\n"
           "\t      -> IO (Int,Int,Ptr a,Int)\n"
           "recvAncillary sock flags len = do\n"
           "  let fd = fdSocket sock\n"
           "  alloca      $ \\ ptr_len   ->\n"
           "   alloca      $ \\ ptr_lev   ->\n"
           "    alloca      $ \\ ptr_ty    ->\n"
           "     alloca      $ \\ ptr_pData -> do\n"
           "      poke ptr_len (fromIntegral len)\n"
           "      _ <- \n"
           "", stdout);
#line 994 "Socket.hsc"
#if !defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (995, "Socket.hsc");
    fputs ("        throwErrnoIfMinus1Retry_repeatOnBlock \"recvAncillary\" \n"
           "            (threadWaitRead (fromIntegral fd)) $\n"
           "", stdout);
#line 997 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (998, "Socket.hsc");
    fputs ("\t    c_recvAncillary fd ptr_lev ptr_ty (fromIntegral flags) ptr_pData ptr_len\n"
           "      len <- fromIntegral `liftM` peek ptr_len\n"
           "      lev <- fromIntegral `liftM` peek ptr_lev\n"
           "      ty  <- fromIntegral `liftM` peek ptr_ty\n"
           "      pD  <- peek ptr_pData\n"
           "      return (lev,ty,pD, len)\n"
           "foreign import ccall unsafe \"sendAncillary\"\n"
           "  c_sendAncillary :: CInt -> CInt -> CInt -> CInt -> Ptr a -> CInt -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"recvAncillary\"\n"
           "  c_recvAncillary :: CInt -> Ptr CInt -> Ptr CInt -> CInt -> Ptr (Ptr a) -> Ptr CInt -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"sendFd\" c_sendFd :: CInt -> CInt -> IO CInt\n"
           "foreign import ccall unsafe \"recvFd\" c_recvFd :: CInt -> IO CInt\n"
           "\n"
           "", stdout);
#line 1013 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1014, "Socket.hsc");
    fputs ("\n"
           "\n"
           "{-\n"
           "A calling sequence table for the main functions is shown in the table below.\n"
           "\n"
           "\\begin{figure}[h]\n"
           "\\begin{center}\n"
           "\\begin{tabular}{|l|c|c|c|c|c|c|c|}d\n"
           "\\hline\n"
           "{\\bf A Call to} & socket & connect & bindSocket & listen & accept & read & write \\\\\n"
           "\\hline\n"
           "{\\bf Precedes} & & & & & & & \\\\\n"
           "\\hline \n"
           "socket &\t&\t  &\t       &\t&\t &\t& \\\\\n"
           "\\hline\n"
           "connect & +\t&\t  &\t       &\t&\t &\t& \\\\\n"
           "\\hline\n"
           "bindSocket & +\t&\t  &\t       &\t&\t &\t& \\\\\n"
           "\\hline\n"
           "listen &\t&\t  & +\t       &\t&\t &\t& \\\\\n"
           "\\hline\n"
           "accept &\t&\t  &\t       &  +\t&\t &\t& \\\\\n"
           "\\hline\n"
           "read   &\t&   +\t  &\t       &  +\t&  +\t &  +\t& + \\\\\n"
           "\\hline\n"
           "write  &\t&   +\t  &\t       &  +\t&  +\t &  +\t& + \\\\\n"
           "\\hline\n"
           "\\end{tabular}\n"
           "\\caption{Sequence Table for Major functions of Socket}\n"
           "\\label{tab:api-seq}\n"
           "\\end{center}\n"
           "\\end{figure}\n"
           "-}\n"
           "\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- OS Dependent Definitions\n"
           "    \n"
           "unpackFamily\t:: CInt -> Family\n"
           "packFamily\t:: Family -> CInt\n"
           "\n"
           "packSocketType\t:: SocketType -> CInt\n"
           "\n"
           "-- | Address Families.\n"
           "--\n"
           "-- This data type might have different constructors depending on what is\n"
           "-- supported by the operating system.\n"
           "data Family\n"
           "\t= AF_UNSPEC\t-- unspecified\n"
           "", stdout);
#line 1062 "Socket.hsc"
#ifdef AF_UNIX
    fputs ("\n"
           "", stdout);
    hsc_line (1063, "Socket.hsc");
    fputs ("\t| AF_UNIX\t-- local to host (pipes, portals\n"
           "", stdout);
#line 1064 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1065, "Socket.hsc");
    fputs ("", stdout);
#line 1065 "Socket.hsc"
#ifdef AF_INET
    fputs ("\n"
           "", stdout);
    hsc_line (1066, "Socket.hsc");
    fputs ("\t| AF_INET\t-- internetwork: UDP, TCP, etc\n"
           "", stdout);
#line 1067 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1068, "Socket.hsc");
    fputs ("", stdout);
#line 1068 "Socket.hsc"
#ifdef AF_INET6
    fputs ("\n"
           "", stdout);
    hsc_line (1069, "Socket.hsc");
    fputs ("        | AF_INET6\t-- Internet Protocol version 6\n"
           "", stdout);
#line 1070 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1071, "Socket.hsc");
    fputs ("", stdout);
#line 1071 "Socket.hsc"
#ifdef AF_IMPLINK
    fputs ("\n"
           "", stdout);
    hsc_line (1072, "Socket.hsc");
    fputs ("\t| AF_IMPLINK\t-- arpanet imp addresses\n"
           "", stdout);
#line 1073 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1074, "Socket.hsc");
    fputs ("", stdout);
#line 1074 "Socket.hsc"
#ifdef AF_PUP
    fputs ("\n"
           "", stdout);
    hsc_line (1075, "Socket.hsc");
    fputs ("\t| AF_PUP\t-- pup protocols: e.g. BSP\n"
           "", stdout);
#line 1076 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1077, "Socket.hsc");
    fputs ("", stdout);
#line 1077 "Socket.hsc"
#ifdef AF_CHAOS
    fputs ("\n"
           "", stdout);
    hsc_line (1078, "Socket.hsc");
    fputs ("\t| AF_CHAOS\t-- mit CHAOS protocols\n"
           "", stdout);
#line 1079 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1080, "Socket.hsc");
    fputs ("", stdout);
#line 1080 "Socket.hsc"
#ifdef AF_NS
    fputs ("\n"
           "", stdout);
    hsc_line (1081, "Socket.hsc");
    fputs ("\t| AF_NS\t\t-- XEROX NS protocols \n"
           "", stdout);
#line 1082 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1083, "Socket.hsc");
    fputs ("", stdout);
#line 1083 "Socket.hsc"
#ifdef AF_NBS
    fputs ("\n"
           "", stdout);
    hsc_line (1084, "Socket.hsc");
    fputs ("\t| AF_NBS\t-- nbs protocols\n"
           "", stdout);
#line 1085 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1086, "Socket.hsc");
    fputs ("", stdout);
#line 1086 "Socket.hsc"
#ifdef AF_ECMA
    fputs ("\n"
           "", stdout);
    hsc_line (1087, "Socket.hsc");
    fputs ("\t| AF_ECMA\t-- european computer manufacturers\n"
           "", stdout);
#line 1088 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1089, "Socket.hsc");
    fputs ("", stdout);
#line 1089 "Socket.hsc"
#ifdef AF_DATAKIT
    fputs ("\n"
           "", stdout);
    hsc_line (1090, "Socket.hsc");
    fputs ("\t| AF_DATAKIT\t-- datakit protocols\n"
           "", stdout);
#line 1091 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1092, "Socket.hsc");
    fputs ("", stdout);
#line 1092 "Socket.hsc"
#ifdef AF_CCITT
    fputs ("\n"
           "", stdout);
    hsc_line (1093, "Socket.hsc");
    fputs ("\t| AF_CCITT\t-- CCITT protocols, X.25 etc\n"
           "", stdout);
#line 1094 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1095, "Socket.hsc");
    fputs ("", stdout);
#line 1095 "Socket.hsc"
#ifdef AF_SNA
    fputs ("\n"
           "", stdout);
    hsc_line (1096, "Socket.hsc");
    fputs ("\t| AF_SNA\t-- IBM SNA\n"
           "", stdout);
#line 1097 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1098, "Socket.hsc");
    fputs ("", stdout);
#line 1098 "Socket.hsc"
#ifdef AF_DECnet
    fputs ("\n"
           "", stdout);
    hsc_line (1099, "Socket.hsc");
    fputs ("\t| AF_DECnet\t-- DECnet\n"
           "", stdout);
#line 1100 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1101, "Socket.hsc");
    fputs ("", stdout);
#line 1101 "Socket.hsc"
#ifdef AF_DLI
    fputs ("\n"
           "", stdout);
    hsc_line (1102, "Socket.hsc");
    fputs ("\t| AF_DLI\t-- Direct data link interface\n"
           "", stdout);
#line 1103 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1104, "Socket.hsc");
    fputs ("", stdout);
#line 1104 "Socket.hsc"
#ifdef AF_LAT
    fputs ("\n"
           "", stdout);
    hsc_line (1105, "Socket.hsc");
    fputs ("\t| AF_LAT\t-- LAT\n"
           "", stdout);
#line 1106 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1107, "Socket.hsc");
    fputs ("", stdout);
#line 1107 "Socket.hsc"
#ifdef AF_HYLINK
    fputs ("\n"
           "", stdout);
    hsc_line (1108, "Socket.hsc");
    fputs ("\t| AF_HYLINK\t-- NSC Hyperchannel\n"
           "", stdout);
#line 1109 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1110, "Socket.hsc");
    fputs ("", stdout);
#line 1110 "Socket.hsc"
#ifdef AF_APPLETALK
    fputs ("\n"
           "", stdout);
    hsc_line (1111, "Socket.hsc");
    fputs ("\t| AF_APPLETALK\t-- Apple Talk\n"
           "", stdout);
#line 1112 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1113, "Socket.hsc");
    fputs ("", stdout);
#line 1113 "Socket.hsc"
#ifdef AF_ROUTE
    fputs ("\n"
           "", stdout);
    hsc_line (1114, "Socket.hsc");
    fputs ("\t| AF_ROUTE\t-- Internal Routing Protocol \n"
           "", stdout);
#line 1115 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1116, "Socket.hsc");
    fputs ("", stdout);
#line 1116 "Socket.hsc"
#ifdef AF_NETBIOS
    fputs ("\n"
           "", stdout);
    hsc_line (1117, "Socket.hsc");
    fputs ("\t| AF_NETBIOS\t-- NetBios-style addresses\n"
           "", stdout);
#line 1118 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1119, "Socket.hsc");
    fputs ("", stdout);
#line 1119 "Socket.hsc"
#ifdef AF_NIT
    fputs ("\n"
           "", stdout);
    hsc_line (1120, "Socket.hsc");
    fputs ("\t| AF_NIT\t-- Network Interface Tap\n"
           "", stdout);
#line 1121 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1122, "Socket.hsc");
    fputs ("", stdout);
#line 1122 "Socket.hsc"
#ifdef AF_802
    fputs ("\n"
           "", stdout);
    hsc_line (1123, "Socket.hsc");
    fputs ("\t| AF_802\t-- IEEE 802.2, also ISO 8802\n"
           "", stdout);
#line 1124 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1125, "Socket.hsc");
    fputs ("", stdout);
#line 1125 "Socket.hsc"
#ifdef AF_ISO
    fputs ("\n"
           "", stdout);
    hsc_line (1126, "Socket.hsc");
    fputs ("\t| AF_ISO\t-- ISO protocols\n"
           "", stdout);
#line 1127 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1128, "Socket.hsc");
    fputs ("", stdout);
#line 1128 "Socket.hsc"
#ifdef AF_OSI
    fputs ("\n"
           "", stdout);
    hsc_line (1129, "Socket.hsc");
    fputs ("\t| AF_OSI\t-- umbrella of all families used by OSI\n"
           "", stdout);
#line 1130 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1131, "Socket.hsc");
    fputs ("", stdout);
#line 1131 "Socket.hsc"
#ifdef AF_NETMAN
    fputs ("\n"
           "", stdout);
    hsc_line (1132, "Socket.hsc");
    fputs ("\t| AF_NETMAN\t-- DNA Network Management \n"
           "", stdout);
#line 1133 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1134, "Socket.hsc");
    fputs ("", stdout);
#line 1134 "Socket.hsc"
#ifdef AF_X25
    fputs ("\n"
           "", stdout);
    hsc_line (1135, "Socket.hsc");
    fputs ("\t| AF_X25\t-- CCITT X.25\n"
           "", stdout);
#line 1136 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1137, "Socket.hsc");
    fputs ("", stdout);
#line 1137 "Socket.hsc"
#ifdef AF_AX25
    fputs ("\n"
           "", stdout);
    hsc_line (1138, "Socket.hsc");
    fputs ("\t| AF_AX25\n"
           "", stdout);
#line 1139 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1140, "Socket.hsc");
    fputs ("", stdout);
#line 1140 "Socket.hsc"
#ifdef AF_OSINET
    fputs ("\n"
           "", stdout);
    hsc_line (1141, "Socket.hsc");
    fputs ("\t| AF_OSINET\t-- AFI\n"
           "", stdout);
#line 1142 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1143, "Socket.hsc");
    fputs ("", stdout);
#line 1143 "Socket.hsc"
#ifdef AF_GOSSIP
    fputs ("\n"
           "", stdout);
    hsc_line (1144, "Socket.hsc");
    fputs ("\t| AF_GOSSIP\t-- US Government OSI\n"
           "", stdout);
#line 1145 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1146, "Socket.hsc");
    fputs ("", stdout);
#line 1146 "Socket.hsc"
#ifdef AF_IPX
    fputs ("\n"
           "", stdout);
    hsc_line (1147, "Socket.hsc");
    fputs ("\t| AF_IPX\t-- Novell Internet Protocol\n"
           "", stdout);
#line 1148 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1149, "Socket.hsc");
    fputs ("", stdout);
#line 1149 "Socket.hsc"
#ifdef Pseudo_AF_XTP
    fputs ("\n"
           "", stdout);
    hsc_line (1150, "Socket.hsc");
    fputs ("\t| Pseudo_AF_XTP\t-- eXpress Transfer Protocol (no AF) \n"
           "", stdout);
#line 1151 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1152, "Socket.hsc");
    fputs ("", stdout);
#line 1152 "Socket.hsc"
#ifdef AF_CTF
    fputs ("\n"
           "", stdout);
    hsc_line (1153, "Socket.hsc");
    fputs ("\t| AF_CTF\t-- Common Trace Facility \n"
           "", stdout);
#line 1154 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1155, "Socket.hsc");
    fputs ("", stdout);
#line 1155 "Socket.hsc"
#ifdef AF_WAN
    fputs ("\n"
           "", stdout);
    hsc_line (1156, "Socket.hsc");
    fputs ("\t| AF_WAN\t-- Wide Area Network protocols \n"
           "", stdout);
#line 1157 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1158, "Socket.hsc");
    fputs ("", stdout);
#line 1158 "Socket.hsc"
#ifdef AF_SDL
    fputs ("\n"
           "", stdout);
    hsc_line (1159, "Socket.hsc");
    fputs ("        | AF_SDL\t-- SGI Data Link for DLPI\n"
           "", stdout);
#line 1160 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1161, "Socket.hsc");
    fputs ("", stdout);
#line 1161 "Socket.hsc"
#ifdef AF_NETWARE
    fputs ("\n"
           "", stdout);
    hsc_line (1162, "Socket.hsc");
    fputs ("        | AF_NETWARE\t\n"
           "", stdout);
#line 1163 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1164, "Socket.hsc");
    fputs ("", stdout);
#line 1164 "Socket.hsc"
#ifdef AF_NDD
    fputs ("\n"
           "", stdout);
    hsc_line (1165, "Socket.hsc");
    fputs ("        | AF_NDD\t\t\n"
           "", stdout);
#line 1166 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1167, "Socket.hsc");
    fputs ("", stdout);
#line 1167 "Socket.hsc"
#ifdef AF_INTF
    fputs ("\n"
           "", stdout);
    hsc_line (1168, "Socket.hsc");
    fputs ("        | AF_INTF\t-- Debugging use only \n"
           "", stdout);
#line 1169 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1170, "Socket.hsc");
    fputs ("", stdout);
#line 1170 "Socket.hsc"
#ifdef AF_COIP
    fputs ("\n"
           "", stdout);
    hsc_line (1171, "Socket.hsc");
    fputs ("        | AF_COIP         -- connection-oriented IP, aka ST II\n"
           "", stdout);
#line 1172 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1173, "Socket.hsc");
    fputs ("", stdout);
#line 1173 "Socket.hsc"
#ifdef AF_CNT
    fputs ("\n"
           "", stdout);
    hsc_line (1174, "Socket.hsc");
    fputs ("        | AF_CNT\t-- Computer Network Technology\n"
           "", stdout);
#line 1175 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1176, "Socket.hsc");
    fputs ("", stdout);
#line 1176 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
    fputs ("\n"
           "", stdout);
    hsc_line (1177, "Socket.hsc");
    fputs ("        | Pseudo_AF_RTIP  -- Help Identify RTIP packets\n"
           "", stdout);
#line 1178 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1179, "Socket.hsc");
    fputs ("", stdout);
#line 1179 "Socket.hsc"
#ifdef Pseudo_AF_PIP
    fputs ("\n"
           "", stdout);
    hsc_line (1180, "Socket.hsc");
    fputs ("        | Pseudo_AF_PIP   -- Help Identify PIP packets\n"
           "", stdout);
#line 1181 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1182, "Socket.hsc");
    fputs ("", stdout);
#line 1182 "Socket.hsc"
#ifdef AF_SIP
    fputs ("\n"
           "", stdout);
    hsc_line (1183, "Socket.hsc");
    fputs ("        | AF_SIP          -- Simple Internet Protocol\n"
           "", stdout);
#line 1184 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1185, "Socket.hsc");
    fputs ("", stdout);
#line 1185 "Socket.hsc"
#ifdef AF_ISDN
    fputs ("\n"
           "", stdout);
    hsc_line (1186, "Socket.hsc");
    fputs ("        | AF_ISDN         -- Integrated Services Digital Network\n"
           "", stdout);
#line 1187 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1188, "Socket.hsc");
    fputs ("", stdout);
#line 1188 "Socket.hsc"
#ifdef Pseudo_AF_KEY
    fputs ("\n"
           "", stdout);
    hsc_line (1189, "Socket.hsc");
    fputs ("        | Pseudo_AF_KEY   -- Internal key-management function\n"
           "", stdout);
#line 1190 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1191, "Socket.hsc");
    fputs ("", stdout);
#line 1191 "Socket.hsc"
#ifdef AF_NATM
    fputs ("\n"
           "", stdout);
    hsc_line (1192, "Socket.hsc");
    fputs ("        | AF_NATM         -- native ATM access\n"
           "", stdout);
#line 1193 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1194, "Socket.hsc");
    fputs ("", stdout);
#line 1194 "Socket.hsc"
#ifdef AF_ARP
    fputs ("\n"
           "", stdout);
    hsc_line (1195, "Socket.hsc");
    fputs ("        | AF_ARP          -- (rev.) addr. res. prot. (RFC 826)\n"
           "", stdout);
#line 1196 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1197, "Socket.hsc");
    fputs ("", stdout);
#line 1197 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
    fputs ("\n"
           "", stdout);
    hsc_line (1198, "Socket.hsc");
    fputs ("        | Pseudo_AF_HDRCMPLT -- Used by BPF to not rewrite hdrs in iface output\n"
           "", stdout);
#line 1199 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1200, "Socket.hsc");
    fputs ("", stdout);
#line 1200 "Socket.hsc"
#ifdef AF_ENCAP
    fputs ("\n"
           "", stdout);
    hsc_line (1201, "Socket.hsc");
    fputs ("        | AF_ENCAP \n"
           "", stdout);
#line 1202 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1203, "Socket.hsc");
    fputs ("", stdout);
#line 1203 "Socket.hsc"
#ifdef AF_LINK
    fputs ("\n"
           "", stdout);
    hsc_line (1204, "Socket.hsc");
    fputs ("\t| AF_LINK\t-- Link layer interface \n"
           "", stdout);
#line 1205 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1206, "Socket.hsc");
    fputs ("", stdout);
#line 1206 "Socket.hsc"
#ifdef AF_RAW
    fputs ("\n"
           "", stdout);
    hsc_line (1207, "Socket.hsc");
    fputs ("        | AF_RAW\t-- Link layer interface\n"
           "", stdout);
#line 1208 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1209, "Socket.hsc");
    fputs ("", stdout);
#line 1209 "Socket.hsc"
#ifdef AF_RIF
    fputs ("\n"
           "", stdout);
    hsc_line (1210, "Socket.hsc");
    fputs ("        | AF_RIF\t-- raw interface \n"
           "", stdout);
#line 1211 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1212, "Socket.hsc");
    fputs ("\tderiving (Eq, Ord, Read, Show)\n"
           "\n"
           "------ ------\n"
           "\t\t\t\n"
           "packFamily f = case f of\n"
           "\tAF_UNSPEC -> ", stdout);
#line 1217 "Socket.hsc"
    hsc_const (AF_UNSPEC);
    fputs ("\n"
           "", stdout);
    hsc_line (1218, "Socket.hsc");
    fputs ("", stdout);
#line 1218 "Socket.hsc"
#ifdef AF_UNIX
    fputs ("\n"
           "", stdout);
    hsc_line (1219, "Socket.hsc");
    fputs ("\tAF_UNIX -> ", stdout);
#line 1219 "Socket.hsc"
    hsc_const (AF_UNIX);
    fputs ("\n"
           "", stdout);
    hsc_line (1220, "Socket.hsc");
    fputs ("", stdout);
#line 1220 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1221, "Socket.hsc");
    fputs ("", stdout);
#line 1221 "Socket.hsc"
#ifdef AF_INET
    fputs ("\n"
           "", stdout);
    hsc_line (1222, "Socket.hsc");
    fputs ("\tAF_INET -> ", stdout);
#line 1222 "Socket.hsc"
    hsc_const (AF_INET);
    fputs ("\n"
           "", stdout);
    hsc_line (1223, "Socket.hsc");
    fputs ("", stdout);
#line 1223 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1224, "Socket.hsc");
    fputs ("", stdout);
#line 1224 "Socket.hsc"
#ifdef AF_INET6
    fputs ("\n"
           "", stdout);
    hsc_line (1225, "Socket.hsc");
    fputs ("        AF_INET6 -> ", stdout);
#line 1225 "Socket.hsc"
    hsc_const (AF_INET6);
    fputs ("\n"
           "", stdout);
    hsc_line (1226, "Socket.hsc");
    fputs ("", stdout);
#line 1226 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1227, "Socket.hsc");
    fputs ("", stdout);
#line 1227 "Socket.hsc"
#ifdef AF_IMPLINK
    fputs ("\n"
           "", stdout);
    hsc_line (1228, "Socket.hsc");
    fputs ("\tAF_IMPLINK -> ", stdout);
#line 1228 "Socket.hsc"
    hsc_const (AF_IMPLINK);
    fputs ("\n"
           "", stdout);
    hsc_line (1229, "Socket.hsc");
    fputs ("", stdout);
#line 1229 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1230, "Socket.hsc");
    fputs ("", stdout);
#line 1230 "Socket.hsc"
#ifdef AF_PUP
    fputs ("\n"
           "", stdout);
    hsc_line (1231, "Socket.hsc");
    fputs ("\tAF_PUP -> ", stdout);
#line 1231 "Socket.hsc"
    hsc_const (AF_PUP);
    fputs ("\n"
           "", stdout);
    hsc_line (1232, "Socket.hsc");
    fputs ("", stdout);
#line 1232 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1233, "Socket.hsc");
    fputs ("", stdout);
#line 1233 "Socket.hsc"
#ifdef AF_CHAOS
    fputs ("\n"
           "", stdout);
    hsc_line (1234, "Socket.hsc");
    fputs ("\tAF_CHAOS -> ", stdout);
#line 1234 "Socket.hsc"
    hsc_const (AF_CHAOS);
    fputs ("\n"
           "", stdout);
    hsc_line (1235, "Socket.hsc");
    fputs ("", stdout);
#line 1235 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1236, "Socket.hsc");
    fputs ("", stdout);
#line 1236 "Socket.hsc"
#ifdef AF_NS
    fputs ("\n"
           "", stdout);
    hsc_line (1237, "Socket.hsc");
    fputs ("\tAF_NS -> ", stdout);
#line 1237 "Socket.hsc"
    hsc_const (AF_NS);
    fputs ("\n"
           "", stdout);
    hsc_line (1238, "Socket.hsc");
    fputs ("", stdout);
#line 1238 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1239, "Socket.hsc");
    fputs ("", stdout);
#line 1239 "Socket.hsc"
#ifdef AF_NBS
    fputs ("\n"
           "", stdout);
    hsc_line (1240, "Socket.hsc");
    fputs ("\tAF_NBS -> ", stdout);
#line 1240 "Socket.hsc"
    hsc_const (AF_NBS);
    fputs ("\n"
           "", stdout);
    hsc_line (1241, "Socket.hsc");
    fputs ("", stdout);
#line 1241 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1242, "Socket.hsc");
    fputs ("", stdout);
#line 1242 "Socket.hsc"
#ifdef AF_ECMA
    fputs ("\n"
           "", stdout);
    hsc_line (1243, "Socket.hsc");
    fputs ("\tAF_ECMA -> ", stdout);
#line 1243 "Socket.hsc"
    hsc_const (AF_ECMA);
    fputs ("\n"
           "", stdout);
    hsc_line (1244, "Socket.hsc");
    fputs ("", stdout);
#line 1244 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1245, "Socket.hsc");
    fputs ("", stdout);
#line 1245 "Socket.hsc"
#ifdef AF_DATAKIT
    fputs ("\n"
           "", stdout);
    hsc_line (1246, "Socket.hsc");
    fputs ("\tAF_DATAKIT -> ", stdout);
#line 1246 "Socket.hsc"
    hsc_const (AF_DATAKIT);
    fputs ("\n"
           "", stdout);
    hsc_line (1247, "Socket.hsc");
    fputs ("", stdout);
#line 1247 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1248, "Socket.hsc");
    fputs ("", stdout);
#line 1248 "Socket.hsc"
#ifdef AF_CCITT
    fputs ("\n"
           "", stdout);
    hsc_line (1249, "Socket.hsc");
    fputs ("\tAF_CCITT -> ", stdout);
#line 1249 "Socket.hsc"
    hsc_const (AF_CCITT);
    fputs ("\n"
           "", stdout);
    hsc_line (1250, "Socket.hsc");
    fputs ("", stdout);
#line 1250 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1251, "Socket.hsc");
    fputs ("", stdout);
#line 1251 "Socket.hsc"
#ifdef AF_SNA
    fputs ("\n"
           "", stdout);
    hsc_line (1252, "Socket.hsc");
    fputs ("\tAF_SNA -> ", stdout);
#line 1252 "Socket.hsc"
    hsc_const (AF_SNA);
    fputs ("\n"
           "", stdout);
    hsc_line (1253, "Socket.hsc");
    fputs ("", stdout);
#line 1253 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1254, "Socket.hsc");
    fputs ("", stdout);
#line 1254 "Socket.hsc"
#ifdef AF_DECnet
    fputs ("\n"
           "", stdout);
    hsc_line (1255, "Socket.hsc");
    fputs ("\tAF_DECnet -> ", stdout);
#line 1255 "Socket.hsc"
    hsc_const (AF_DECnet);
    fputs ("\n"
           "", stdout);
    hsc_line (1256, "Socket.hsc");
    fputs ("", stdout);
#line 1256 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1257, "Socket.hsc");
    fputs ("", stdout);
#line 1257 "Socket.hsc"
#ifdef AF_DLI
    fputs ("\n"
           "", stdout);
    hsc_line (1258, "Socket.hsc");
    fputs ("\tAF_DLI -> ", stdout);
#line 1258 "Socket.hsc"
    hsc_const (AF_DLI);
    fputs ("\n"
           "", stdout);
    hsc_line (1259, "Socket.hsc");
    fputs ("", stdout);
#line 1259 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1260, "Socket.hsc");
    fputs ("", stdout);
#line 1260 "Socket.hsc"
#ifdef AF_LAT
    fputs ("\n"
           "", stdout);
    hsc_line (1261, "Socket.hsc");
    fputs ("\tAF_LAT -> ", stdout);
#line 1261 "Socket.hsc"
    hsc_const (AF_LAT);
    fputs ("\n"
           "", stdout);
    hsc_line (1262, "Socket.hsc");
    fputs ("", stdout);
#line 1262 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1263, "Socket.hsc");
    fputs ("", stdout);
#line 1263 "Socket.hsc"
#ifdef AF_HYLINK
    fputs ("\n"
           "", stdout);
    hsc_line (1264, "Socket.hsc");
    fputs ("\tAF_HYLINK -> ", stdout);
#line 1264 "Socket.hsc"
    hsc_const (AF_HYLINK);
    fputs ("\n"
           "", stdout);
    hsc_line (1265, "Socket.hsc");
    fputs ("", stdout);
#line 1265 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1266, "Socket.hsc");
    fputs ("", stdout);
#line 1266 "Socket.hsc"
#ifdef AF_APPLETALK
    fputs ("\n"
           "", stdout);
    hsc_line (1267, "Socket.hsc");
    fputs ("\tAF_APPLETALK -> ", stdout);
#line 1267 "Socket.hsc"
    hsc_const (AF_APPLETALK);
    fputs ("\n"
           "", stdout);
    hsc_line (1268, "Socket.hsc");
    fputs ("", stdout);
#line 1268 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1269, "Socket.hsc");
    fputs ("", stdout);
#line 1269 "Socket.hsc"
#ifdef AF_ROUTE
    fputs ("\n"
           "", stdout);
    hsc_line (1270, "Socket.hsc");
    fputs ("\tAF_ROUTE -> ", stdout);
#line 1270 "Socket.hsc"
    hsc_const (AF_ROUTE);
    fputs ("\n"
           "", stdout);
    hsc_line (1271, "Socket.hsc");
    fputs ("", stdout);
#line 1271 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1272, "Socket.hsc");
    fputs ("", stdout);
#line 1272 "Socket.hsc"
#ifdef AF_NETBIOS
    fputs ("\n"
           "", stdout);
    hsc_line (1273, "Socket.hsc");
    fputs ("\tAF_NETBIOS -> ", stdout);
#line 1273 "Socket.hsc"
    hsc_const (AF_NETBIOS);
    fputs ("\n"
           "", stdout);
    hsc_line (1274, "Socket.hsc");
    fputs ("", stdout);
#line 1274 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1275, "Socket.hsc");
    fputs ("", stdout);
#line 1275 "Socket.hsc"
#ifdef AF_NIT
    fputs ("\n"
           "", stdout);
    hsc_line (1276, "Socket.hsc");
    fputs ("\tAF_NIT -> ", stdout);
#line 1276 "Socket.hsc"
    hsc_const (AF_NIT);
    fputs ("\n"
           "", stdout);
    hsc_line (1277, "Socket.hsc");
    fputs ("", stdout);
#line 1277 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1278, "Socket.hsc");
    fputs ("", stdout);
#line 1278 "Socket.hsc"
#ifdef AF_802
    fputs ("\n"
           "", stdout);
    hsc_line (1279, "Socket.hsc");
    fputs ("\tAF_802 -> ", stdout);
#line 1279 "Socket.hsc"
    hsc_const (AF_802);
    fputs ("\n"
           "", stdout);
    hsc_line (1280, "Socket.hsc");
    fputs ("", stdout);
#line 1280 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1281, "Socket.hsc");
    fputs ("", stdout);
#line 1281 "Socket.hsc"
#ifdef AF_ISO
    fputs ("\n"
           "", stdout);
    hsc_line (1282, "Socket.hsc");
    fputs ("\tAF_ISO -> ", stdout);
#line 1282 "Socket.hsc"
    hsc_const (AF_ISO);
    fputs ("\n"
           "", stdout);
    hsc_line (1283, "Socket.hsc");
    fputs ("", stdout);
#line 1283 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1284, "Socket.hsc");
    fputs ("", stdout);
#line 1284 "Socket.hsc"
#ifdef AF_OSI
    fputs ("\n"
           "", stdout);
    hsc_line (1285, "Socket.hsc");
    fputs ("\tAF_OSI -> ", stdout);
#line 1285 "Socket.hsc"
    hsc_const (AF_OSI);
    fputs ("\n"
           "", stdout);
    hsc_line (1286, "Socket.hsc");
    fputs ("", stdout);
#line 1286 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1287, "Socket.hsc");
    fputs ("", stdout);
#line 1287 "Socket.hsc"
#ifdef AF_NETMAN
    fputs ("\n"
           "", stdout);
    hsc_line (1288, "Socket.hsc");
    fputs ("\tAF_NETMAN -> ", stdout);
#line 1288 "Socket.hsc"
    hsc_const (AF_NETMAN);
    fputs ("\n"
           "", stdout);
    hsc_line (1289, "Socket.hsc");
    fputs ("", stdout);
#line 1289 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1290, "Socket.hsc");
    fputs ("", stdout);
#line 1290 "Socket.hsc"
#ifdef AF_X25
    fputs ("\n"
           "", stdout);
    hsc_line (1291, "Socket.hsc");
    fputs ("\tAF_X25 -> ", stdout);
#line 1291 "Socket.hsc"
    hsc_const (AF_X25);
    fputs ("\n"
           "", stdout);
    hsc_line (1292, "Socket.hsc");
    fputs ("", stdout);
#line 1292 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1293, "Socket.hsc");
    fputs ("", stdout);
#line 1293 "Socket.hsc"
#ifdef AF_AX25
    fputs ("\n"
           "", stdout);
    hsc_line (1294, "Socket.hsc");
    fputs ("\tAF_AX25 -> ", stdout);
#line 1294 "Socket.hsc"
    hsc_const (AF_AX25);
    fputs ("\n"
           "", stdout);
    hsc_line (1295, "Socket.hsc");
    fputs ("", stdout);
#line 1295 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1296, "Socket.hsc");
    fputs ("", stdout);
#line 1296 "Socket.hsc"
#ifdef AF_OSINET
    fputs ("\n"
           "", stdout);
    hsc_line (1297, "Socket.hsc");
    fputs ("\tAF_OSINET -> ", stdout);
#line 1297 "Socket.hsc"
    hsc_const (AF_OSINET);
    fputs ("\n"
           "", stdout);
    hsc_line (1298, "Socket.hsc");
    fputs ("", stdout);
#line 1298 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1299, "Socket.hsc");
    fputs ("", stdout);
#line 1299 "Socket.hsc"
#ifdef AF_GOSSIP
    fputs ("\n"
           "", stdout);
    hsc_line (1300, "Socket.hsc");
    fputs ("\tAF_GOSSIP -> ", stdout);
#line 1300 "Socket.hsc"
    hsc_const (AF_GOSSIP);
    fputs ("\n"
           "", stdout);
    hsc_line (1301, "Socket.hsc");
    fputs ("", stdout);
#line 1301 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1302, "Socket.hsc");
    fputs ("", stdout);
#line 1302 "Socket.hsc"
#ifdef AF_IPX
    fputs ("\n"
           "", stdout);
    hsc_line (1303, "Socket.hsc");
    fputs ("\tAF_IPX -> ", stdout);
#line 1303 "Socket.hsc"
    hsc_const (AF_IPX);
    fputs ("\n"
           "", stdout);
    hsc_line (1304, "Socket.hsc");
    fputs ("", stdout);
#line 1304 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1305, "Socket.hsc");
    fputs ("", stdout);
#line 1305 "Socket.hsc"
#ifdef Pseudo_AF_XTP
    fputs ("\n"
           "", stdout);
    hsc_line (1306, "Socket.hsc");
    fputs ("\tPseudo_AF_XTP -> ", stdout);
#line 1306 "Socket.hsc"
    hsc_const (Pseudo_AF_XTP);
    fputs ("\n"
           "", stdout);
    hsc_line (1307, "Socket.hsc");
    fputs ("", stdout);
#line 1307 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1308, "Socket.hsc");
    fputs ("", stdout);
#line 1308 "Socket.hsc"
#ifdef AF_CTF
    fputs ("\n"
           "", stdout);
    hsc_line (1309, "Socket.hsc");
    fputs ("\tAF_CTF -> ", stdout);
#line 1309 "Socket.hsc"
    hsc_const (AF_CTF);
    fputs ("\n"
           "", stdout);
    hsc_line (1310, "Socket.hsc");
    fputs ("", stdout);
#line 1310 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1311, "Socket.hsc");
    fputs ("", stdout);
#line 1311 "Socket.hsc"
#ifdef AF_WAN
    fputs ("\n"
           "", stdout);
    hsc_line (1312, "Socket.hsc");
    fputs ("\tAF_WAN -> ", stdout);
#line 1312 "Socket.hsc"
    hsc_const (AF_WAN);
    fputs ("\n"
           "", stdout);
    hsc_line (1313, "Socket.hsc");
    fputs ("", stdout);
#line 1313 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1314, "Socket.hsc");
    fputs ("", stdout);
#line 1314 "Socket.hsc"
#ifdef AF_SDL
    fputs ("\n"
           "", stdout);
    hsc_line (1315, "Socket.hsc");
    fputs ("        AF_SDL -> ", stdout);
#line 1315 "Socket.hsc"
    hsc_const (AF_SDL);
    fputs ("\n"
           "", stdout);
    hsc_line (1316, "Socket.hsc");
    fputs ("", stdout);
#line 1316 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1317, "Socket.hsc");
    fputs ("", stdout);
#line 1317 "Socket.hsc"
#ifdef AF_NETWARE
    fputs ("\n"
           "", stdout);
    hsc_line (1318, "Socket.hsc");
    fputs ("        AF_NETWARE -> ", stdout);
#line 1318 "Socket.hsc"
    hsc_const (AF_NETWARE	);
    fputs ("\n"
           "", stdout);
    hsc_line (1319, "Socket.hsc");
    fputs ("", stdout);
#line 1319 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1320, "Socket.hsc");
    fputs ("", stdout);
#line 1320 "Socket.hsc"
#ifdef AF_NDD
    fputs ("\n"
           "", stdout);
    hsc_line (1321, "Socket.hsc");
    fputs ("        AF_NDD -> ", stdout);
#line 1321 "Socket.hsc"
    hsc_const (AF_NDD		);
    fputs ("\n"
           "", stdout);
    hsc_line (1322, "Socket.hsc");
    fputs ("", stdout);
#line 1322 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1323, "Socket.hsc");
    fputs ("", stdout);
#line 1323 "Socket.hsc"
#ifdef AF_INTF
    fputs ("\n"
           "", stdout);
    hsc_line (1324, "Socket.hsc");
    fputs ("        AF_INTF -> ", stdout);
#line 1324 "Socket.hsc"
    hsc_const (AF_INTF);
    fputs ("\n"
           "", stdout);
    hsc_line (1325, "Socket.hsc");
    fputs ("", stdout);
#line 1325 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1326, "Socket.hsc");
    fputs ("", stdout);
#line 1326 "Socket.hsc"
#ifdef AF_COIP
    fputs ("\n"
           "", stdout);
    hsc_line (1327, "Socket.hsc");
    fputs ("        AF_COIP -> ", stdout);
#line 1327 "Socket.hsc"
    hsc_const (AF_COIP);
    fputs ("\n"
           "", stdout);
    hsc_line (1328, "Socket.hsc");
    fputs ("", stdout);
#line 1328 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1329, "Socket.hsc");
    fputs ("", stdout);
#line 1329 "Socket.hsc"
#ifdef AF_CNT
    fputs ("\n"
           "", stdout);
    hsc_line (1330, "Socket.hsc");
    fputs ("        AF_CNT -> ", stdout);
#line 1330 "Socket.hsc"
    hsc_const (AF_CNT);
    fputs ("\n"
           "", stdout);
    hsc_line (1331, "Socket.hsc");
    fputs ("", stdout);
#line 1331 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1332, "Socket.hsc");
    fputs ("", stdout);
#line 1332 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
    fputs ("\n"
           "", stdout);
    hsc_line (1333, "Socket.hsc");
    fputs ("        Pseudo_AF_RTIP -> ", stdout);
#line 1333 "Socket.hsc"
    hsc_const (Pseudo_AF_RTIP);
    fputs ("\n"
           "", stdout);
    hsc_line (1334, "Socket.hsc");
    fputs ("", stdout);
#line 1334 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1335, "Socket.hsc");
    fputs ("", stdout);
#line 1335 "Socket.hsc"
#ifdef Pseudo_AF_PIP
    fputs ("\n"
           "", stdout);
    hsc_line (1336, "Socket.hsc");
    fputs ("        Pseudo_AF_PIP -> ", stdout);
#line 1336 "Socket.hsc"
    hsc_const (Pseudo_AF_PIP);
    fputs ("\n"
           "", stdout);
    hsc_line (1337, "Socket.hsc");
    fputs ("", stdout);
#line 1337 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1338, "Socket.hsc");
    fputs ("", stdout);
#line 1338 "Socket.hsc"
#ifdef AF_SIP
    fputs ("\n"
           "", stdout);
    hsc_line (1339, "Socket.hsc");
    fputs ("        AF_SIP -> ", stdout);
#line 1339 "Socket.hsc"
    hsc_const (AF_SIP);
    fputs ("\n"
           "", stdout);
    hsc_line (1340, "Socket.hsc");
    fputs ("", stdout);
#line 1340 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1341, "Socket.hsc");
    fputs ("", stdout);
#line 1341 "Socket.hsc"
#ifdef AF_ISDN
    fputs ("\n"
           "", stdout);
    hsc_line (1342, "Socket.hsc");
    fputs ("        AF_ISDN -> ", stdout);
#line 1342 "Socket.hsc"
    hsc_const (AF_ISDN);
    fputs ("\n"
           "", stdout);
    hsc_line (1343, "Socket.hsc");
    fputs ("", stdout);
#line 1343 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1344, "Socket.hsc");
    fputs ("", stdout);
#line 1344 "Socket.hsc"
#ifdef Pseudo_AF_KEY
    fputs ("\n"
           "", stdout);
    hsc_line (1345, "Socket.hsc");
    fputs ("        Pseudo_AF_KEY -> ", stdout);
#line 1345 "Socket.hsc"
    hsc_const (Pseudo_AF_KEY);
    fputs ("\n"
           "", stdout);
    hsc_line (1346, "Socket.hsc");
    fputs ("", stdout);
#line 1346 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1347, "Socket.hsc");
    fputs ("", stdout);
#line 1347 "Socket.hsc"
#ifdef AF_NATM
    fputs ("\n"
           "", stdout);
    hsc_line (1348, "Socket.hsc");
    fputs ("        AF_NATM -> ", stdout);
#line 1348 "Socket.hsc"
    hsc_const (AF_NATM);
    fputs ("\n"
           "", stdout);
    hsc_line (1349, "Socket.hsc");
    fputs ("", stdout);
#line 1349 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1350, "Socket.hsc");
    fputs ("", stdout);
#line 1350 "Socket.hsc"
#ifdef AF_ARP
    fputs ("\n"
           "", stdout);
    hsc_line (1351, "Socket.hsc");
    fputs ("        AF_ARP -> ", stdout);
#line 1351 "Socket.hsc"
    hsc_const (AF_ARP);
    fputs ("\n"
           "", stdout);
    hsc_line (1352, "Socket.hsc");
    fputs ("", stdout);
#line 1352 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1353, "Socket.hsc");
    fputs ("", stdout);
#line 1353 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
    fputs ("\n"
           "", stdout);
    hsc_line (1354, "Socket.hsc");
    fputs ("        Pseudo_AF_HDRCMPLT -> ", stdout);
#line 1354 "Socket.hsc"
    hsc_const (Pseudo_AF_HDRCMPLT);
    fputs ("\n"
           "", stdout);
    hsc_line (1355, "Socket.hsc");
    fputs ("", stdout);
#line 1355 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1356, "Socket.hsc");
    fputs ("", stdout);
#line 1356 "Socket.hsc"
#ifdef AF_ENCAP
    fputs ("\n"
           "", stdout);
    hsc_line (1357, "Socket.hsc");
    fputs ("        AF_ENCAP -> ", stdout);
#line 1357 "Socket.hsc"
    hsc_const (AF_ENCAP );
    fputs ("\n"
           "", stdout);
    hsc_line (1358, "Socket.hsc");
    fputs ("", stdout);
#line 1358 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1359, "Socket.hsc");
    fputs ("", stdout);
#line 1359 "Socket.hsc"
#ifdef AF_LINK
    fputs ("\n"
           "", stdout);
    hsc_line (1360, "Socket.hsc");
    fputs ("\tAF_LINK -> ", stdout);
#line 1360 "Socket.hsc"
    hsc_const (AF_LINK);
    fputs ("\n"
           "", stdout);
    hsc_line (1361, "Socket.hsc");
    fputs ("", stdout);
#line 1361 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1362, "Socket.hsc");
    fputs ("", stdout);
#line 1362 "Socket.hsc"
#ifdef AF_RAW
    fputs ("\n"
           "", stdout);
    hsc_line (1363, "Socket.hsc");
    fputs ("        AF_RAW -> ", stdout);
#line 1363 "Socket.hsc"
    hsc_const (AF_RAW);
    fputs ("\n"
           "", stdout);
    hsc_line (1364, "Socket.hsc");
    fputs ("", stdout);
#line 1364 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1365, "Socket.hsc");
    fputs ("", stdout);
#line 1365 "Socket.hsc"
#ifdef AF_RIF
    fputs ("\n"
           "", stdout);
    hsc_line (1366, "Socket.hsc");
    fputs ("        AF_RIF -> ", stdout);
#line 1366 "Socket.hsc"
    hsc_const (AF_RIF);
    fputs ("\n"
           "", stdout);
    hsc_line (1367, "Socket.hsc");
    fputs ("", stdout);
#line 1367 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1368, "Socket.hsc");
    fputs ("\n"
           "--------- ----------\n"
           "\n"
           "unpackFamily f = case f of\n"
           "\t(", stdout);
#line 1372 "Socket.hsc"
    hsc_const (AF_UNSPEC);
    fputs (") -> AF_UNSPEC\n"
           "", stdout);
    hsc_line (1373, "Socket.hsc");
    fputs ("", stdout);
#line 1373 "Socket.hsc"
#ifdef AF_UNIX
    fputs ("\n"
           "", stdout);
    hsc_line (1374, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1374 "Socket.hsc"
    hsc_const (AF_UNIX);
    fputs (") -> AF_UNIX\n"
           "", stdout);
    hsc_line (1375, "Socket.hsc");
    fputs ("", stdout);
#line 1375 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1376, "Socket.hsc");
    fputs ("", stdout);
#line 1376 "Socket.hsc"
#ifdef AF_INET
    fputs ("\n"
           "", stdout);
    hsc_line (1377, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1377 "Socket.hsc"
    hsc_const (AF_INET);
    fputs (") -> AF_INET\n"
           "", stdout);
    hsc_line (1378, "Socket.hsc");
    fputs ("", stdout);
#line 1378 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1379, "Socket.hsc");
    fputs ("", stdout);
#line 1379 "Socket.hsc"
#ifdef AF_INET6
    fputs ("\n"
           "", stdout);
    hsc_line (1380, "Socket.hsc");
    fputs ("        (", stdout);
#line 1380 "Socket.hsc"
    hsc_const (AF_INET6);
    fputs (") -> AF_INET6\n"
           "", stdout);
    hsc_line (1381, "Socket.hsc");
    fputs ("", stdout);
#line 1381 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1382, "Socket.hsc");
    fputs ("", stdout);
#line 1382 "Socket.hsc"
#ifdef AF_IMPLINK
    fputs ("\n"
           "", stdout);
    hsc_line (1383, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1383 "Socket.hsc"
    hsc_const (AF_IMPLINK);
    fputs (") -> AF_IMPLINK\n"
           "", stdout);
    hsc_line (1384, "Socket.hsc");
    fputs ("", stdout);
#line 1384 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1385, "Socket.hsc");
    fputs ("", stdout);
#line 1385 "Socket.hsc"
#ifdef AF_PUP
    fputs ("\n"
           "", stdout);
    hsc_line (1386, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1386 "Socket.hsc"
    hsc_const (AF_PUP);
    fputs (") -> AF_PUP\n"
           "", stdout);
    hsc_line (1387, "Socket.hsc");
    fputs ("", stdout);
#line 1387 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1388, "Socket.hsc");
    fputs ("", stdout);
#line 1388 "Socket.hsc"
#ifdef AF_CHAOS
    fputs ("\n"
           "", stdout);
    hsc_line (1389, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1389 "Socket.hsc"
    hsc_const (AF_CHAOS);
    fputs (") -> AF_CHAOS\n"
           "", stdout);
    hsc_line (1390, "Socket.hsc");
    fputs ("", stdout);
#line 1390 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1391, "Socket.hsc");
    fputs ("", stdout);
#line 1391 "Socket.hsc"
#ifdef AF_NS
    fputs ("\n"
           "", stdout);
    hsc_line (1392, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1392 "Socket.hsc"
    hsc_const (AF_NS);
    fputs (") -> AF_NS\n"
           "", stdout);
    hsc_line (1393, "Socket.hsc");
    fputs ("", stdout);
#line 1393 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1394, "Socket.hsc");
    fputs ("", stdout);
#line 1394 "Socket.hsc"
#ifdef AF_NBS
    fputs ("\n"
           "", stdout);
    hsc_line (1395, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1395 "Socket.hsc"
    hsc_const (AF_NBS);
    fputs (") -> AF_NBS\n"
           "", stdout);
    hsc_line (1396, "Socket.hsc");
    fputs ("", stdout);
#line 1396 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1397, "Socket.hsc");
    fputs ("", stdout);
#line 1397 "Socket.hsc"
#ifdef AF_ECMA
    fputs ("\n"
           "", stdout);
    hsc_line (1398, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1398 "Socket.hsc"
    hsc_const (AF_ECMA);
    fputs (") -> AF_ECMA\n"
           "", stdout);
    hsc_line (1399, "Socket.hsc");
    fputs ("", stdout);
#line 1399 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1400, "Socket.hsc");
    fputs ("", stdout);
#line 1400 "Socket.hsc"
#ifdef AF_DATAKIT
    fputs ("\n"
           "", stdout);
    hsc_line (1401, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1401 "Socket.hsc"
    hsc_const (AF_DATAKIT);
    fputs (") -> AF_DATAKIT\n"
           "", stdout);
    hsc_line (1402, "Socket.hsc");
    fputs ("", stdout);
#line 1402 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1403, "Socket.hsc");
    fputs ("", stdout);
#line 1403 "Socket.hsc"
#ifdef AF_CCITT
    fputs ("\n"
           "", stdout);
    hsc_line (1404, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1404 "Socket.hsc"
    hsc_const (AF_CCITT);
    fputs (") -> AF_CCITT\n"
           "", stdout);
    hsc_line (1405, "Socket.hsc");
    fputs ("", stdout);
#line 1405 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1406, "Socket.hsc");
    fputs ("", stdout);
#line 1406 "Socket.hsc"
#ifdef AF_SNA
    fputs ("\n"
           "", stdout);
    hsc_line (1407, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1407 "Socket.hsc"
    hsc_const (AF_SNA);
    fputs (") -> AF_SNA\n"
           "", stdout);
    hsc_line (1408, "Socket.hsc");
    fputs ("", stdout);
#line 1408 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1409, "Socket.hsc");
    fputs ("", stdout);
#line 1409 "Socket.hsc"
#ifdef AF_DECnet
    fputs ("\n"
           "", stdout);
    hsc_line (1410, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1410 "Socket.hsc"
    hsc_const (AF_DECnet);
    fputs (") -> AF_DECnet\n"
           "", stdout);
    hsc_line (1411, "Socket.hsc");
    fputs ("", stdout);
#line 1411 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1412, "Socket.hsc");
    fputs ("", stdout);
#line 1412 "Socket.hsc"
#ifdef AF_DLI
    fputs ("\n"
           "", stdout);
    hsc_line (1413, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1413 "Socket.hsc"
    hsc_const (AF_DLI);
    fputs (") -> AF_DLI\n"
           "", stdout);
    hsc_line (1414, "Socket.hsc");
    fputs ("", stdout);
#line 1414 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1415, "Socket.hsc");
    fputs ("", stdout);
#line 1415 "Socket.hsc"
#ifdef AF_LAT
    fputs ("\n"
           "", stdout);
    hsc_line (1416, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1416 "Socket.hsc"
    hsc_const (AF_LAT);
    fputs (") -> AF_LAT\n"
           "", stdout);
    hsc_line (1417, "Socket.hsc");
    fputs ("", stdout);
#line 1417 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1418, "Socket.hsc");
    fputs ("", stdout);
#line 1418 "Socket.hsc"
#ifdef AF_HYLINK
    fputs ("\n"
           "", stdout);
    hsc_line (1419, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1419 "Socket.hsc"
    hsc_const (AF_HYLINK);
    fputs (") -> AF_HYLINK\n"
           "", stdout);
    hsc_line (1420, "Socket.hsc");
    fputs ("", stdout);
#line 1420 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1421, "Socket.hsc");
    fputs ("", stdout);
#line 1421 "Socket.hsc"
#ifdef AF_APPLETALK
    fputs ("\n"
           "", stdout);
    hsc_line (1422, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1422 "Socket.hsc"
    hsc_const (AF_APPLETALK);
    fputs (") -> AF_APPLETALK\n"
           "", stdout);
    hsc_line (1423, "Socket.hsc");
    fputs ("", stdout);
#line 1423 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1424, "Socket.hsc");
    fputs ("", stdout);
#line 1424 "Socket.hsc"
#ifdef AF_ROUTE
    fputs ("\n"
           "", stdout);
    hsc_line (1425, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1425 "Socket.hsc"
    hsc_const (AF_ROUTE);
    fputs (") -> AF_ROUTE\n"
           "", stdout);
    hsc_line (1426, "Socket.hsc");
    fputs ("", stdout);
#line 1426 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1427, "Socket.hsc");
    fputs ("", stdout);
#line 1427 "Socket.hsc"
#ifdef AF_NETBIOS
    fputs ("\n"
           "", stdout);
    hsc_line (1428, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1428 "Socket.hsc"
    hsc_const (AF_NETBIOS);
    fputs (") -> AF_NETBIOS\n"
           "", stdout);
    hsc_line (1429, "Socket.hsc");
    fputs ("", stdout);
#line 1429 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1430, "Socket.hsc");
    fputs ("", stdout);
#line 1430 "Socket.hsc"
#ifdef AF_NIT
    fputs ("\n"
           "", stdout);
    hsc_line (1431, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1431 "Socket.hsc"
    hsc_const (AF_NIT);
    fputs (") -> AF_NIT\n"
           "", stdout);
    hsc_line (1432, "Socket.hsc");
    fputs ("", stdout);
#line 1432 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1433, "Socket.hsc");
    fputs ("", stdout);
#line 1433 "Socket.hsc"
#ifdef AF_802
    fputs ("\n"
           "", stdout);
    hsc_line (1434, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1434 "Socket.hsc"
    hsc_const (AF_802);
    fputs (") -> AF_802\n"
           "", stdout);
    hsc_line (1435, "Socket.hsc");
    fputs ("", stdout);
#line 1435 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1436, "Socket.hsc");
    fputs ("", stdout);
#line 1436 "Socket.hsc"
#ifdef AF_ISO
    fputs ("\n"
           "", stdout);
    hsc_line (1437, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1437 "Socket.hsc"
    hsc_const (AF_ISO);
    fputs (") -> AF_ISO\n"
           "", stdout);
    hsc_line (1438, "Socket.hsc");
    fputs ("", stdout);
#line 1438 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1439, "Socket.hsc");
    fputs ("", stdout);
#line 1439 "Socket.hsc"
#ifdef AF_OSI
    fputs ("\n"
           "", stdout);
    hsc_line (1440, "Socket.hsc");
    fputs ("", stdout);
#line 1440 "Socket.hsc"
#if (!defined(AF_ISO)) || (defined(AF_ISO) && (AF_ISO != AF_OSI))
    fputs ("\n"
           "", stdout);
    hsc_line (1441, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1441 "Socket.hsc"
    hsc_const (AF_OSI);
    fputs (") -> AF_OSI\n"
           "", stdout);
    hsc_line (1442, "Socket.hsc");
    fputs ("", stdout);
#line 1442 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1443, "Socket.hsc");
    fputs ("", stdout);
#line 1443 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1444, "Socket.hsc");
    fputs ("", stdout);
#line 1444 "Socket.hsc"
#ifdef AF_NETMAN
    fputs ("\n"
           "", stdout);
    hsc_line (1445, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1445 "Socket.hsc"
    hsc_const (AF_NETMAN);
    fputs (") -> AF_NETMAN\n"
           "", stdout);
    hsc_line (1446, "Socket.hsc");
    fputs ("", stdout);
#line 1446 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1447, "Socket.hsc");
    fputs ("", stdout);
#line 1447 "Socket.hsc"
#ifdef AF_X25
    fputs ("\n"
           "", stdout);
    hsc_line (1448, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1448 "Socket.hsc"
    hsc_const (AF_X25);
    fputs (") -> AF_X25\n"
           "", stdout);
    hsc_line (1449, "Socket.hsc");
    fputs ("", stdout);
#line 1449 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1450, "Socket.hsc");
    fputs ("", stdout);
#line 1450 "Socket.hsc"
#ifdef AF_AX25
    fputs ("\n"
           "", stdout);
    hsc_line (1451, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1451 "Socket.hsc"
    hsc_const (AF_AX25);
    fputs (") -> AF_AX25\n"
           "", stdout);
    hsc_line (1452, "Socket.hsc");
    fputs ("", stdout);
#line 1452 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1453, "Socket.hsc");
    fputs ("", stdout);
#line 1453 "Socket.hsc"
#ifdef AF_OSINET
    fputs ("\n"
           "", stdout);
    hsc_line (1454, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1454 "Socket.hsc"
    hsc_const (AF_OSINET);
    fputs (") -> AF_OSINET\n"
           "", stdout);
    hsc_line (1455, "Socket.hsc");
    fputs ("", stdout);
#line 1455 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1456, "Socket.hsc");
    fputs ("", stdout);
#line 1456 "Socket.hsc"
#ifdef AF_GOSSIP
    fputs ("\n"
           "", stdout);
    hsc_line (1457, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1457 "Socket.hsc"
    hsc_const (AF_GOSSIP);
    fputs (") -> AF_GOSSIP\n"
           "", stdout);
    hsc_line (1458, "Socket.hsc");
    fputs ("", stdout);
#line 1458 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1459, "Socket.hsc");
    fputs ("", stdout);
#line 1459 "Socket.hsc"
#ifdef AF_IPX
    fputs ("\n"
           "", stdout);
    hsc_line (1460, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1460 "Socket.hsc"
    hsc_const (AF_IPX);
    fputs (") -> AF_IPX\n"
           "", stdout);
    hsc_line (1461, "Socket.hsc");
    fputs ("", stdout);
#line 1461 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1462, "Socket.hsc");
    fputs ("", stdout);
#line 1462 "Socket.hsc"
#ifdef Pseudo_AF_XTP
    fputs ("\n"
           "", stdout);
    hsc_line (1463, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1463 "Socket.hsc"
    hsc_const (Pseudo_AF_XTP);
    fputs (") -> Pseudo_AF_XTP\n"
           "", stdout);
    hsc_line (1464, "Socket.hsc");
    fputs ("", stdout);
#line 1464 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1465, "Socket.hsc");
    fputs ("", stdout);
#line 1465 "Socket.hsc"
#ifdef AF_CTF
    fputs ("\n"
           "", stdout);
    hsc_line (1466, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1466 "Socket.hsc"
    hsc_const (AF_CTF);
    fputs (") -> AF_CTF\n"
           "", stdout);
    hsc_line (1467, "Socket.hsc");
    fputs ("", stdout);
#line 1467 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1468, "Socket.hsc");
    fputs ("", stdout);
#line 1468 "Socket.hsc"
#ifdef AF_WAN
    fputs ("\n"
           "", stdout);
    hsc_line (1469, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1469 "Socket.hsc"
    hsc_const (AF_WAN);
    fputs (") -> AF_WAN\n"
           "", stdout);
    hsc_line (1470, "Socket.hsc");
    fputs ("", stdout);
#line 1470 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1471, "Socket.hsc");
    fputs ("", stdout);
#line 1471 "Socket.hsc"
#ifdef AF_SDL
    fputs ("\n"
           "", stdout);
    hsc_line (1472, "Socket.hsc");
    fputs ("        (", stdout);
#line 1472 "Socket.hsc"
    hsc_const (AF_SDL);
    fputs (") -> AF_SDL\n"
           "", stdout);
    hsc_line (1473, "Socket.hsc");
    fputs ("", stdout);
#line 1473 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1474, "Socket.hsc");
    fputs ("", stdout);
#line 1474 "Socket.hsc"
#ifdef AF_NETWARE
    fputs ("\n"
           "", stdout);
    hsc_line (1475, "Socket.hsc");
    fputs ("        (", stdout);
#line 1475 "Socket.hsc"
    hsc_const (AF_NETWARE);
    fputs (") -> AF_NETWARE\t\n"
           "", stdout);
    hsc_line (1476, "Socket.hsc");
    fputs ("", stdout);
#line 1476 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1477, "Socket.hsc");
    fputs ("", stdout);
#line 1477 "Socket.hsc"
#ifdef AF_NDD
    fputs ("\n"
           "", stdout);
    hsc_line (1478, "Socket.hsc");
    fputs ("        (", stdout);
#line 1478 "Socket.hsc"
    hsc_const (AF_NDD);
    fputs (") -> AF_NDD\t\t\n"
           "", stdout);
    hsc_line (1479, "Socket.hsc");
    fputs ("", stdout);
#line 1479 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1480, "Socket.hsc");
    fputs ("", stdout);
#line 1480 "Socket.hsc"
#ifdef AF_INTF
    fputs ("\n"
           "", stdout);
    hsc_line (1481, "Socket.hsc");
    fputs ("        (", stdout);
#line 1481 "Socket.hsc"
    hsc_const (AF_INTF);
    fputs (") -> AF_INTF\n"
           "", stdout);
    hsc_line (1482, "Socket.hsc");
    fputs ("", stdout);
#line 1482 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1483, "Socket.hsc");
    fputs ("", stdout);
#line 1483 "Socket.hsc"
#ifdef AF_COIP
    fputs ("\n"
           "", stdout);
    hsc_line (1484, "Socket.hsc");
    fputs ("        (", stdout);
#line 1484 "Socket.hsc"
    hsc_const (AF_COIP);
    fputs (") -> AF_COIP\n"
           "", stdout);
    hsc_line (1485, "Socket.hsc");
    fputs ("", stdout);
#line 1485 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1486, "Socket.hsc");
    fputs ("", stdout);
#line 1486 "Socket.hsc"
#ifdef AF_CNT
    fputs ("\n"
           "", stdout);
    hsc_line (1487, "Socket.hsc");
    fputs ("        (", stdout);
#line 1487 "Socket.hsc"
    hsc_const (AF_CNT);
    fputs (") -> AF_CNT\n"
           "", stdout);
    hsc_line (1488, "Socket.hsc");
    fputs ("", stdout);
#line 1488 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1489, "Socket.hsc");
    fputs ("", stdout);
#line 1489 "Socket.hsc"
#ifdef Pseudo_AF_RTIP
    fputs ("\n"
           "", stdout);
    hsc_line (1490, "Socket.hsc");
    fputs ("        (", stdout);
#line 1490 "Socket.hsc"
    hsc_const (Pseudo_AF_RTIP);
    fputs (") -> Pseudo_AF_RTIP\n"
           "", stdout);
    hsc_line (1491, "Socket.hsc");
    fputs ("", stdout);
#line 1491 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1492, "Socket.hsc");
    fputs ("", stdout);
#line 1492 "Socket.hsc"
#ifdef Pseudo_AF_PIP
    fputs ("\n"
           "", stdout);
    hsc_line (1493, "Socket.hsc");
    fputs ("        (", stdout);
#line 1493 "Socket.hsc"
    hsc_const (Pseudo_AF_PIP);
    fputs (") -> Pseudo_AF_PIP\n"
           "", stdout);
    hsc_line (1494, "Socket.hsc");
    fputs ("", stdout);
#line 1494 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1495, "Socket.hsc");
    fputs ("", stdout);
#line 1495 "Socket.hsc"
#ifdef AF_SIP
    fputs ("\n"
           "", stdout);
    hsc_line (1496, "Socket.hsc");
    fputs ("        (", stdout);
#line 1496 "Socket.hsc"
    hsc_const (AF_SIP);
    fputs (") -> AF_SIP\n"
           "", stdout);
    hsc_line (1497, "Socket.hsc");
    fputs ("", stdout);
#line 1497 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1498, "Socket.hsc");
    fputs ("", stdout);
#line 1498 "Socket.hsc"
#ifdef AF_ISDN
    fputs ("\n"
           "", stdout);
    hsc_line (1499, "Socket.hsc");
    fputs ("        (", stdout);
#line 1499 "Socket.hsc"
    hsc_const (AF_ISDN);
    fputs (") -> AF_ISDN\n"
           "", stdout);
    hsc_line (1500, "Socket.hsc");
    fputs ("", stdout);
#line 1500 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1501, "Socket.hsc");
    fputs ("", stdout);
#line 1501 "Socket.hsc"
#ifdef Pseudo_AF_KEY
    fputs ("\n"
           "", stdout);
    hsc_line (1502, "Socket.hsc");
    fputs ("        (", stdout);
#line 1502 "Socket.hsc"
    hsc_const (Pseudo_AF_KEY);
    fputs (") -> Pseudo_AF_KEY\n"
           "", stdout);
    hsc_line (1503, "Socket.hsc");
    fputs ("", stdout);
#line 1503 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1504, "Socket.hsc");
    fputs ("", stdout);
#line 1504 "Socket.hsc"
#ifdef AF_NATM
    fputs ("\n"
           "", stdout);
    hsc_line (1505, "Socket.hsc");
    fputs ("        (", stdout);
#line 1505 "Socket.hsc"
    hsc_const (AF_NATM);
    fputs (") -> AF_NATM\n"
           "", stdout);
    hsc_line (1506, "Socket.hsc");
    fputs ("", stdout);
#line 1506 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1507, "Socket.hsc");
    fputs ("", stdout);
#line 1507 "Socket.hsc"
#ifdef AF_ARP
    fputs ("\n"
           "", stdout);
    hsc_line (1508, "Socket.hsc");
    fputs ("        (", stdout);
#line 1508 "Socket.hsc"
    hsc_const (AF_ARP);
    fputs (") -> AF_ARP\n"
           "", stdout);
    hsc_line (1509, "Socket.hsc");
    fputs ("", stdout);
#line 1509 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1510, "Socket.hsc");
    fputs ("", stdout);
#line 1510 "Socket.hsc"
#ifdef Pseudo_AF_HDRCMPLT
    fputs ("\n"
           "", stdout);
    hsc_line (1511, "Socket.hsc");
    fputs ("        (", stdout);
#line 1511 "Socket.hsc"
    hsc_const (Pseudo_AF_HDRCMPLT);
    fputs (") -> Pseudo_AF_HDRCMPLT\n"
           "", stdout);
    hsc_line (1512, "Socket.hsc");
    fputs ("", stdout);
#line 1512 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1513, "Socket.hsc");
    fputs ("", stdout);
#line 1513 "Socket.hsc"
#ifdef AF_ENCAP
    fputs ("\n"
           "", stdout);
    hsc_line (1514, "Socket.hsc");
    fputs ("        (", stdout);
#line 1514 "Socket.hsc"
    hsc_const (AF_ENCAP);
    fputs (") -> AF_ENCAP \n"
           "", stdout);
    hsc_line (1515, "Socket.hsc");
    fputs ("", stdout);
#line 1515 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1516, "Socket.hsc");
    fputs ("", stdout);
#line 1516 "Socket.hsc"
#ifdef AF_LINK
    fputs ("\n"
           "", stdout);
    hsc_line (1517, "Socket.hsc");
    fputs ("\t(", stdout);
#line 1517 "Socket.hsc"
    hsc_const (AF_LINK);
    fputs (") -> AF_LINK\n"
           "", stdout);
    hsc_line (1518, "Socket.hsc");
    fputs ("", stdout);
#line 1518 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1519, "Socket.hsc");
    fputs ("", stdout);
#line 1519 "Socket.hsc"
#ifdef AF_RAW
    fputs ("\n"
           "", stdout);
    hsc_line (1520, "Socket.hsc");
    fputs ("        (", stdout);
#line 1520 "Socket.hsc"
    hsc_const (AF_RAW);
    fputs (") -> AF_RAW\n"
           "", stdout);
    hsc_line (1521, "Socket.hsc");
    fputs ("", stdout);
#line 1521 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1522, "Socket.hsc");
    fputs ("", stdout);
#line 1522 "Socket.hsc"
#ifdef AF_RIF
    fputs ("\n"
           "", stdout);
    hsc_line (1523, "Socket.hsc");
    fputs ("        (", stdout);
#line 1523 "Socket.hsc"
    hsc_const (AF_RIF);
    fputs (") -> AF_RIF\n"
           "", stdout);
    hsc_line (1524, "Socket.hsc");
    fputs ("", stdout);
#line 1524 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1525, "Socket.hsc");
    fputs ("\n"
           "-- Socket Types.\n"
           "\n"
           "-- | Socket Types.\n"
           "--\n"
           "-- This data type might have different constructors depending on what is\n"
           "-- supported by the operating system.\n"
           "data SocketType\n"
           "\t= NoSocketType\n"
           "", stdout);
#line 1534 "Socket.hsc"
#ifdef SOCK_STREAM
    fputs ("\n"
           "", stdout);
    hsc_line (1535, "Socket.hsc");
    fputs ("\t| Stream \n"
           "", stdout);
#line 1536 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1537, "Socket.hsc");
    fputs ("", stdout);
#line 1537 "Socket.hsc"
#ifdef SOCK_DGRAM
    fputs ("\n"
           "", stdout);
    hsc_line (1538, "Socket.hsc");
    fputs ("\t| Datagram\n"
           "", stdout);
#line 1539 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1540, "Socket.hsc");
    fputs ("", stdout);
#line 1540 "Socket.hsc"
#ifdef SOCK_RAW
    fputs ("\n"
           "", stdout);
    hsc_line (1541, "Socket.hsc");
    fputs ("\t| Raw \n"
           "", stdout);
#line 1542 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1543, "Socket.hsc");
    fputs ("", stdout);
#line 1543 "Socket.hsc"
#ifdef SOCK_RDM
    fputs ("\n"
           "", stdout);
    hsc_line (1544, "Socket.hsc");
    fputs ("\t| RDM \n"
           "", stdout);
#line 1545 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1546, "Socket.hsc");
    fputs ("", stdout);
#line 1546 "Socket.hsc"
#ifdef SOCK_SEQPACKET
    fputs ("\n"
           "", stdout);
    hsc_line (1547, "Socket.hsc");
    fputs ("\t| SeqPacket\n"
           "", stdout);
#line 1548 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1549, "Socket.hsc");
    fputs ("\tderiving (Eq, Ord, Read, Show)\n"
           "\t\n"
           "packSocketType stype = case stype of\n"
           "\tNoSocketType -> 0\n"
           "", stdout);
#line 1553 "Socket.hsc"
#ifdef SOCK_STREAM
    fputs ("\n"
           "", stdout);
    hsc_line (1554, "Socket.hsc");
    fputs ("\tStream -> ", stdout);
#line 1554 "Socket.hsc"
    hsc_const (SOCK_STREAM);
    fputs ("\n"
           "", stdout);
    hsc_line (1555, "Socket.hsc");
    fputs ("", stdout);
#line 1555 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1556, "Socket.hsc");
    fputs ("", stdout);
#line 1556 "Socket.hsc"
#ifdef SOCK_DGRAM
    fputs ("\n"
           "", stdout);
    hsc_line (1557, "Socket.hsc");
    fputs ("\tDatagram -> ", stdout);
#line 1557 "Socket.hsc"
    hsc_const (SOCK_DGRAM);
    fputs ("\n"
           "", stdout);
    hsc_line (1558, "Socket.hsc");
    fputs ("", stdout);
#line 1558 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1559, "Socket.hsc");
    fputs ("", stdout);
#line 1559 "Socket.hsc"
#ifdef SOCK_RAW
    fputs ("\n"
           "", stdout);
    hsc_line (1560, "Socket.hsc");
    fputs ("\tRaw -> ", stdout);
#line 1560 "Socket.hsc"
    hsc_const (SOCK_RAW);
    fputs ("\n"
           "", stdout);
    hsc_line (1561, "Socket.hsc");
    fputs ("", stdout);
#line 1561 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1562, "Socket.hsc");
    fputs ("", stdout);
#line 1562 "Socket.hsc"
#ifdef SOCK_RDM
    fputs ("\n"
           "", stdout);
    hsc_line (1563, "Socket.hsc");
    fputs ("\tRDM -> ", stdout);
#line 1563 "Socket.hsc"
    hsc_const (SOCK_RDM);
    fputs ("\n"
           "", stdout);
    hsc_line (1564, "Socket.hsc");
    fputs ("", stdout);
#line 1564 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1565, "Socket.hsc");
    fputs ("", stdout);
#line 1565 "Socket.hsc"
#ifdef SOCK_SEQPACKET
    fputs ("\n"
           "", stdout);
    hsc_line (1566, "Socket.hsc");
    fputs ("\tSeqPacket -> ", stdout);
#line 1566 "Socket.hsc"
    hsc_const (SOCK_SEQPACKET);
    fputs ("\n"
           "", stdout);
    hsc_line (1567, "Socket.hsc");
    fputs ("", stdout);
#line 1567 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1568, "Socket.hsc");
    fputs ("\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Utility Functions\n"
           "\n"
           "aNY_PORT :: PortNumber \n"
           "aNY_PORT = 0\n"
           "\n"
           "iNADDR_ANY :: HostAddress\n"
           "iNADDR_ANY = htonl (", stdout);
#line 1576 "Socket.hsc"
    hsc_const (INADDR_ANY);
    fputs (")\n"
           "", stdout);
    hsc_line (1577, "Socket.hsc");
    fputs ("\n"
           "sOMAXCONN :: Int\n"
           "sOMAXCONN = ", stdout);
#line 1579 "Socket.hsc"
    hsc_const (SOMAXCONN);
    fputs ("\n"
           "", stdout);
    hsc_line (1580, "Socket.hsc");
    fputs ("\n"
           "sOL_SOCKET :: Int\n"
           "sOL_SOCKET = ", stdout);
#line 1582 "Socket.hsc"
    hsc_const (SOL_SOCKET);
    fputs ("\n"
           "", stdout);
    hsc_line (1583, "Socket.hsc");
    fputs ("\n"
           "", stdout);
#line 1584 "Socket.hsc"
#ifdef SCM_RIGHTS
    fputs ("\n"
           "", stdout);
    hsc_line (1585, "Socket.hsc");
    fputs ("sCM_RIGHTS :: Int\n"
           "sCM_RIGHTS = ", stdout);
#line 1586 "Socket.hsc"
    hsc_const (SCM_RIGHTS);
    fputs ("\n"
           "", stdout);
    hsc_line (1587, "Socket.hsc");
    fputs ("", stdout);
#line 1587 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1588, "Socket.hsc");
    fputs ("\n"
           "maxListenQueue :: Int\n"
           "maxListenQueue = sOMAXCONN\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "\n"
           "data ShutdownCmd \n"
           " = ShutdownReceive\n"
           " | ShutdownSend\n"
           " | ShutdownBoth\n"
           "\n"
           "sdownCmdToInt :: ShutdownCmd -> CInt\n"
           "sdownCmdToInt ShutdownReceive = 0\n"
           "sdownCmdToInt ShutdownSend    = 1\n"
           "sdownCmdToInt ShutdownBoth    = 2\n"
           "\n"
           "shutdown :: Socket -> ShutdownCmd -> IO ()\n"
           "shutdown (MkSocket s _ _ _ _) stype = do\n"
           "  throwSocketErrorIfMinus1Retry \"shutdown\" (c_shutdown s (sdownCmdToInt stype))\n"
           "  return ()\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "\n"
           "sClose\t :: Socket -> IO ()\n"
           "sClose (MkSocket s _ _ _ _) = do c_close s; return ()\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "\n"
           "sIsConnected :: Socket -> IO Bool\n"
           "sIsConnected (MkSocket _ _ _ _ status) = do\n"
           "    value <- readMVar status\n"
           "    return (value == Connected)\t\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Socket Predicates\n"
           "\n"
           "sIsBound :: Socket -> IO Bool\n"
           "sIsBound (MkSocket _ _ _ _ status) = do\n"
           "    value <- readMVar status\n"
           "    return (value == Bound)\t\n"
           "\n"
           "sIsListening :: Socket -> IO Bool\n"
           "sIsListening (MkSocket _ _ _  _ status) = do\n"
           "    value <- readMVar status\n"
           "    return (value == Listening)\t\n"
           "\n"
           "sIsReadable  :: Socket -> IO Bool\n"
           "sIsReadable (MkSocket _ _ _ _ status) = do\n"
           "    value <- readMVar status\n"
           "    return (value == Listening || value == Connected)\n"
           "\n"
           "sIsWritable  :: Socket -> IO Bool\n"
           "sIsWritable = sIsReadable -- sort of.\n"
           "\n"
           "sIsAcceptable :: Socket -> IO Bool\n"
           "", stdout);
#line 1643 "Socket.hsc"
#if defined(DOMAIN_SOCKET_SUPPORT)
    fputs ("\n"
           "", stdout);
    hsc_line (1644, "Socket.hsc");
    fputs ("sIsAcceptable (MkSocket _ AF_UNIX Stream _ status) = do\n"
           "    value <- readMVar status\n"
           "    return (value == Connected || value == Bound || value == Listening)\n"
           "sIsAcceptable (MkSocket _ AF_UNIX _ _ _) = return False\n"
           "", stdout);
#line 1648 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1649, "Socket.hsc");
    fputs ("sIsAcceptable (MkSocket _ _ _ _ status) = do\n"
           "    value <- readMVar status\n"
           "    return (value == Connected || value == Listening)\n"
           "    \n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Internet address manipulation routines:\n"
           "\n"
           "inet_addr :: String -> IO HostAddress\n"
           "inet_addr ipstr = do\n"
           "   withCString ipstr $ \\str -> do\n"
           "   had <- c_inet_addr str\n"
           "   if had == -1\n"
           "    then ioError (userError (\"inet_addr: Malformed address: \" ++ ipstr))\n"
           "    else return had  -- network byte order\n"
           "\n"
           "inet_ntoa :: HostAddress -> IO String\n"
           "inet_ntoa haddr = do\n"
           "  pstr <- c_inet_ntoa haddr\n"
           "  peekCString pstr\n"
           "\n"
           "-- socketHandle turns a Socket into a Haskell IO Handle. By default, the new\n"
           "-- handle is unbuffered. Use hSetBuffering to alter this.\n"
           "\n"
           "", stdout);
#line 1672 "Socket.hsc"
#ifndef __PARALLEL_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (1673, "Socket.hsc");
    fputs ("socketToHandle :: Socket -> IOMode -> IO Handle\n"
           "socketToHandle s@(MkSocket fd _ _ _ _) mode = do\n"
           "", stdout);
#line 1675 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (1676, "Socket.hsc");
    fputs ("    openFd (fromIntegral fd) (Just System.Posix.Internals.Stream) (show s) mode True{-bin-} False{-no truncate-}\n"
           "", stdout);
#line 1677 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1678, "Socket.hsc");
    fputs ("", stdout);
#line 1678 "Socket.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (1679, "Socket.hsc");
    fputs ("    openFd (fromIntegral fd) True{-is a socket-} mode True{-bin-}\n"
           "", stdout);
#line 1680 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1681, "Socket.hsc");
    fputs ("", stdout);
#line 1681 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (1682, "Socket.hsc");
    fputs ("socketToHandle (MkSocket s family stype protocol status) m =\n"
           "  error \"socketToHandle not implemented in a parallel setup\"\n"
           "", stdout);
#line 1684 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1685, "Socket.hsc");
    fputs ("\n"
           "mkInvalidRecvArgError :: String -> IOError\n"
           "mkInvalidRecvArgError loc = IOError Nothing \n"
           "", stdout);
#line 1688 "Socket.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (1689, "Socket.hsc");
    fputs ("\t\t\t\t    InvalidArgument\n"
           "", stdout);
#line 1690 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (1691, "Socket.hsc");
    fputs ("\t\t\t\t    IllegalOperation\n"
           "", stdout);
#line 1692 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1693, "Socket.hsc");
    fputs ("\t\t\t\t    loc \"non-positive length\" Nothing\n"
           "\n"
           "mkEOFError :: String -> IOError\n"
           "mkEOFError loc = IOError Nothing EOF loc \"end of file\" Nothing\n"
           "\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- WinSock support\n"
           "\n"
           "{-| On Windows operating systems, the networking subsystem has to be\n"
           "initialised using \'withSocketsDo\' before any networking operations can\n"
           "be used.  eg.\n"
           "\n"
           "> main = withSocketsDo $ do {...}\n"
           "\n"
           "Although this is only strictly necessary on Windows platforms, it is\n"
           "harmless on other platforms, so for portability it is good practice to\n"
           "use it all the time.\n"
           "-}\n"
           "withSocketsDo :: IO a -> IO a\n"
           "", stdout);
#line 1712 "Socket.hsc"
#if !defined(WITH_WINSOCK)
    fputs ("\n"
           "", stdout);
    hsc_line (1713, "Socket.hsc");
    fputs ("withSocketsDo x = x\n"
           "", stdout);
#line 1714 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (1715, "Socket.hsc");
    fputs ("withSocketsDo act = do\n"
           "   x <- initWinSock\n"
           "   if ( x /= 0 ) then\n"
           "     ioError (userError \"Failed to initialise WinSock\")\n"
           "    else do\n"
           "      act `Control.Exception.finally` shutdownWinSock\n"
           "\n"
           "foreign import ccall unsafe \"initWinSock\" initWinSock :: IO Int\n"
           "foreign import ccall unsafe \"shutdownWinSock\" shutdownWinSock :: IO ()\n"
           "\n"
           "", stdout);
#line 1725 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1726, "Socket.hsc");
    fputs ("\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- foreign imports from the C library\n"
           "\n"
           "foreign import ccall unsafe \"my_inet_ntoa\"\n"
           "  c_inet_ntoa :: HostAddress -> IO (Ptr CChar)\n"
           "\n"
           "foreign import CALLCONV unsafe \"inet_addr\"\n"
           "  c_inet_addr :: Ptr CChar -> IO HostAddress\n"
           "\n"
           "foreign import CALLCONV unsafe \"shutdown\"\n"
           "  c_shutdown :: CInt -> CInt -> IO CInt \n"
           "\n"
           "", stdout);
#line 1739 "Socket.hsc"
#if !defined(WITH_WINSOCK)
    fputs ("\n"
           "", stdout);
    hsc_line (1740, "Socket.hsc");
    fputs ("foreign import ccall unsafe \"close\"\n"
           "  c_close :: CInt -> IO CInt\n"
           "", stdout);
#line 1742 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (1743, "Socket.hsc");
    fputs ("foreign import stdcall unsafe \"closesocket\"\n"
           "  c_close :: CInt -> IO CInt\n"
           "", stdout);
#line 1745 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1746, "Socket.hsc");
    fputs ("\n"
           "foreign import CALLCONV unsafe \"socket\"\n"
           "  c_socket :: CInt -> CInt -> CInt -> IO CInt\n"
           "foreign import CALLCONV unsafe \"bind\"\n"
           "  c_bind :: CInt -> Ptr SockAddr -> CInt{-CSockLen\?\?\?-} -> IO CInt\n"
           "foreign import CALLCONV unsafe \"connect\"\n"
           "  c_connect :: CInt -> Ptr SockAddr -> CInt{-CSockLen\?\?\?-} -> IO CInt\n"
           "foreign import CALLCONV unsafe \"accept\"\n"
           "  c_accept :: CInt -> Ptr SockAddr -> Ptr CInt{-CSockLen\?\?\?-} -> IO CInt\n"
           "foreign import CALLCONV unsafe \"listen\"\n"
           "  c_listen :: CInt -> CInt -> IO CInt\n"
           "\n"
           "foreign import CALLCONV unsafe \"send\"\n"
           "  c_send :: CInt -> Ptr CChar -> CSize -> CInt -> IO CInt\n"
           "foreign import CALLCONV unsafe \"sendto\"\n"
           "  c_sendto :: CInt -> Ptr CChar -> CSize -> CInt -> Ptr SockAddr -> CInt -> IO CInt\n"
           "foreign import CALLCONV unsafe \"recv\"\n"
           "  c_recv :: CInt -> Ptr CChar -> CSize -> CInt -> IO CInt\n"
           "foreign import CALLCONV unsafe \"recvfrom\"\n"
           "  c_recvfrom :: CInt -> Ptr CChar -> CSize -> CInt -> Ptr SockAddr -> Ptr CInt -> IO CInt\n"
           "foreign import CALLCONV unsafe \"getpeername\"\n"
           "  c_getpeername :: CInt -> Ptr SockAddr -> Ptr CInt -> IO CInt\n"
           "foreign import CALLCONV unsafe \"getsockname\"\n"
           "  c_getsockname :: CInt -> Ptr SockAddr -> Ptr CInt -> IO CInt\n"
           "\n"
           "foreign import CALLCONV unsafe \"getsockopt\"\n"
           "  c_getsockopt :: CInt -> CInt -> CInt -> Ptr CInt -> Ptr CInt -> IO CInt\n"
           "foreign import CALLCONV unsafe \"setsockopt\"\n"
           "  c_setsockopt :: CInt -> CInt -> CInt -> Ptr CInt -> CInt -> IO CInt\n"
           "\n"
           "-----------------------------------------------------------------------------\n"
           "-- Support for thread-safe blocking operations in GHC.\n"
           "\n"
           "", stdout);
#line 1779 "Socket.hsc"
#if defined(__GLASGOW_HASKELL__) && !(defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS))
    fputs ("\n"
           "", stdout);
    hsc_line (1780, "Socket.hsc");
    fputs ("\n"
           "\n"
           "{-# SPECIALISE \n"
           "    throwErrnoIfMinus1Retry_mayBlock\n"
           "\t :: String -> IO CInt -> IO CInt -> IO CInt #-}\n"
           "throwErrnoIfMinus1Retry_mayBlock :: Num a => String -> IO a -> IO a -> IO a\n"
           "throwErrnoIfMinus1Retry_mayBlock name on_block act = do\n"
           "    res <- act\n"
           "    if res == -1\n"
           "        then do\n"
           "            err <- getErrno\n"
           "            if err == eINTR\n"
           "                then throwErrnoIfMinus1Retry_mayBlock name on_block act\n"
           "\t        else if err == eWOULDBLOCK || err == eAGAIN\n"
           "\t\t        then on_block\n"
           "                        else throwErrno name\n"
           "        else return res\n"
           "\n"
           "throwErrnoIfMinus1Retry_repeatOnBlock :: Num a => String -> IO b -> IO a -> IO a\n"
           "throwErrnoIfMinus1Retry_repeatOnBlock name on_block act = do\n"
           "  throwErrnoIfMinus1Retry_mayBlock name (on_block >> repeat) act\n"
           "  where repeat = throwErrnoIfMinus1Retry_repeatOnBlock name on_block act\n"
           "\n"
           "throwSocketErrorIfMinus1Retry name act = throwErrnoIfMinus1Retry name act\n"
           "\n"
           "throwSocketErrorIfMinus1_ :: Num a => String -> IO a -> IO ()\n"
           "throwSocketErrorIfMinus1_ = throwErrnoIfMinus1_\n"
           "", stdout);
#line 1807 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (1808, "Socket.hsc");
    fputs ("\n"
           "throwErrnoIfMinus1Retry_mayBlock name _ act\n"
           "  = throwSocketErrorIfMinus1Retry name act\n"
           "\n"
           "throwErrnoIfMinus1Retry_repeatOnBlock name _ act\n"
           "  = throwSocketErrorIfMinus1Retry name act\n"
           "\n"
           "throwSocketErrorIfMinus1_ :: Num a => String -> IO a -> IO ()\n"
           "throwSocketErrorIfMinus1_ name act = do\n"
           "  throwSocketErrorIfMinus1Retry name act\n"
           "  return ()\n"
           "\n"
           "", stdout);
#line 1820 "Socket.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (1821, "Socket.hsc");
    fputs ("throwSocketErrorIfMinus1Retry name act = do\n"
           "  r <- act\n"
           "  if (r == -1) \n"
           "   then do\n"
           "    rc   <- c_getLastError\n"
           "    case rc of\n"
           "      10093 -> do -- WSANOTINITIALISED\n"
           "        withSocketsDo (return ())\n"
           "\tr <- act\n"
           "\tif (r == -1)\n"
           "\t then (c_getLastError >>= throwSocketError name)\n"
           "\t else return r\n"
           "      _ -> throwSocketError name rc\n"
           "   else return r\n"
           "\n"
           "throwSocketError name rc = do\n"
           "    pstr <- c_getWSError rc\n"
           "    str  <- peekCString pstr\n"
           "", stdout);
#line 1839 "Socket.hsc"
#if __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (1840, "Socket.hsc");
    fputs ("    ioError (IOError Nothing OtherError name str Nothing)\n"
           "", stdout);
#line 1841 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (1842, "Socket.hsc");
    fputs ("    ioError (userError (name ++ \": socket error - \" ++ str))\n"
           "", stdout);
#line 1843 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1844, "Socket.hsc");
    fputs ("foreign import CALLCONV unsafe \"WSAGetLastError\"\n"
           "  c_getLastError :: IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"getWSErrorDescr\"\n"
           "  c_getWSError :: CInt -> IO (Ptr CChar)\n"
           "\n"
           "\n"
           "", stdout);
#line 1851 "Socket.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (1852, "Socket.hsc");
    fputs ("throwSocketErrorIfMinus1Retry name act = throwErrnoIfMinus1Retry name act\n"
           "", stdout);
#line 1853 "Socket.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (1854, "Socket.hsc");
    fputs ("", stdout);
#line 1854 "Socket.hsc"
#endif /* __GLASGOW_HASKELL */
    fputs ("\n"
           "", stdout);
    hsc_line (1855, "Socket.hsc");
    fputs ("\n"
           "", stdout);
    return 0;
}
