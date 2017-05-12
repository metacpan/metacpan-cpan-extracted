foreach (qw(
    2222 5900 6942 6943 6944 6945 6946 6947 6948 6949 6950 6951
)) {
    my $local = (/2222/ ? 22 : $_);
    print "Forwarding $_\n";
    system "ssh -N -R 1$_:127.0.0.1:$local www\@blogs &";
    sleep 1;
}
