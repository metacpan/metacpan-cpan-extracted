sub connection {
    my $class = shift;
    my $dsn = shift;
    my $user = shift;
    my $passwd = shift;
    my $attr = shift;

    if (not $dsn) {
        my $conf = Lidia::Config->new();
        $dsn = $conf->db->dsn();
        $user = $conf->db->user();
        $passwd = $conf->db->passwd();
    }

    return $class->SUPER::connection( $dsn, $user, $passwd, $attr);
}
