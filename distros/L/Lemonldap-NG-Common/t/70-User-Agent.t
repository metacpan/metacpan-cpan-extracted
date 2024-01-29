use Test::More tests => 3;

BEGIN { use_ok('Lemonldap::NG::Common::UserAgent') }

my $ua = Lemonldap::NG::Common::UserAgent->new();

ok ( $ua->agent =~ /^LemonLDAP-NG/, "Default User Agent");

my $uajedi = Lemonldap::NG::Common::UserAgent->new( { lwpOpts => { agent => "Not-The-Browser-You-Are-Looking-For/1977" } } );

ok ( $uajedi->agent !~ /^LemonLDAP-NG/, "Overriden User Agent");

