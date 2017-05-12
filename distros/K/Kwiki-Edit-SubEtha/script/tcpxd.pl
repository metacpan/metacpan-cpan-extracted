foreach (qw(
    2222 5900 6942 6943 6944 6945 6946 6947 6948 6949 6950 6951
)) {
    print "Forwarding $_\n";
    system("./tcpxd-1.2/tcpxd $_ localhost:1$_");
    sleep 1;
}
