# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
BEGIN {
    eval q{use DBI;};
}
print "1..1\n";

my $__FILE__ = __FILE__;

my $db_user     = undef;
my $db_password = undef;

my $dbh;
eval {
    $dbh = DBI->connect(
        "dbi:SQLite:dbname=:memory:",
        $db_user,
        $db_password,
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        }
    );
};

if (defined $dbh) {
    $dbh->do("create table table1 (key,value)");

    my $sth1 = $dbh->prepare("insert into table1 (key, value) values (?,?)");
    $sth1->execute('1', '111');
    $sth1->execute('2', '222');
    $sth1->execute('3', '333');
    $sth1->finish;

    $dbh->do("update table1 set key = ? where value = ?", undef, '1', '100');
    $dbh->do("delete from table1 where key = ?", undef, '2');

    my $sth2 = $dbh->prepare("select key,value from table1 where key=?");
    $sth2->execute('3');
    while (my($key,$value) = $sth2->fetchrow_array) {
        if ($value eq '333') {
            print qq{ok - 1 DBI SQLite $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 1 DBI SQLite $^X $__FILE__\n};
        }
        last;
    }
    $sth2->finish;

    $dbh->disconnect;
}

else {
    print qq{ok - 1 # SKIP DBI SQLite $^X $__FILE__\n};
}

__END__

