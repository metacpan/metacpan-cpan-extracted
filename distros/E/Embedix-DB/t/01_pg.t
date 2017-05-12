use Test;
use Embedix::DB;
use vars qw($psql_not_ok);

BEGIN { 
    eval {
        my %ad = map { $_ => 1 } DBI->available_drivers;
        die if not defined $ad{Pg};
        my %ds = map { m/=(.*?)$/; $1 => 1 } DBI->data_sources('Pg');
        die if not defined $ds{embedix_test};
    };
    $psql_not_ok = $@;

    if ($psql_not_ok) {
        plan tests => 1;
        ok(1);
        exit;
    } else {
        plan tests => 11;
    }
}

# new
my $edb = Embedix::DB->new (
    backend => 'Pg',
    source  => [ 
        'dbi:Pg:dbname=embedix_test', 
        undef, undef, 
        { AutoCommit => 0 } 
    ],
);
ok($edb);
my $dbh = $edb->{dbh};

my @distro;

# addDistro
$distro[0] = $edb->addDistro (
    name        => 'Embedix 1.2', 
    board       => 'i386',
    description => "Lineo's main embedded Linux distribution"
);
ok($distro[0]);

# addDistro again
$distro[1] = $edb->addDistro (
    name        => 'uClinux 2.4', 
    board       => 'm68k',
    description => "Linux for MMU-less architectures"
);
ok($distro[1]);

# workOnDistro
$distro[2] = $edb->workOnDistro(name => 'Embedix 1.2', board => 'i386');
ok($distro[0]{distro_id}, $distro[2]{distro_id});

# workOnDistro again
$distro[3] = $edb->workOnDistro(name => 'uClinux 2.4', board => 'm68k');
ok($distro[1]{distro_id}, $distro[3]{distro_id});

# workOnDistro one more time
$distro[4] = $edb->workOnDistro(name => 'Embedix 1.2', board => 'i386');
ok($distro[0]{distro_id}, $distro[4]{distro_id});

# updateDistro
my $ecd = Embedix::ECD->newFromFile('t/data/textutils.ecd');
eval { $edb->updateDistro(ecd => $ecd) };
ok($@ ? 0 : 1);

# see if update works by repeating the previous action
my $textutils = $ecd->Textprocessing->Tools->textutils;
$textutils->type('bool');
$textutils->default_value(1);
$textutils->prompt('busybox makes me jealous');
eval { $edb->updateDistro(ecd => $ecd) };
ok($@ ? 0 : 1);

# udpateDistro, yet again to see if the buildvars got in
$ecd = Embedix::ECD->newFromFile('t/data/tinylogin.ecd');
eval { $edb->updateDistro(ecd => $ecd) };
ok($@ ? 0 : 1);

# getNodePath
my $cheat = $dbh->selectall_arrayref("
    select n.node_id from node n where n.node_name = 'tinylogin';
");
my $path = $edb->getNodePath($cheat->[0][0]);
ok($path, "/System/Utilities/tinylogin");

# cloneDistro
my $clone = $edb->cloneDistro(board => 'ppc');
ok($clone);

# TODO:getComponentList

# TODO:getDistroList

# cleanup
if (1) {
    $dbh->do(qq|
        drop trigger node_delete_trigger on node;
        delete from build_vars;
        delete from choicelist;
        delete from distro;
        delete from keeplist;
        delete from license;
        delete from node;
        delete from node_distro;
        delete from node_license;
        delete from node_parent;
        delete from provides;
        create trigger node_delete_trigger before delete on node 
            for each row execute procedure node_dependencies_delete();
    |);
    $dbh->commit;
}

# vim:syntax=perl
