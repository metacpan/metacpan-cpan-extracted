#====================================================================
# Test script for Lemonldap::Config::Parameters
#
# 2005 (c) Clement OUDOT (LINAGORA)
#====================================================================

#====================================================================
# Perl test modules
#====================================================================
use Test::More tests => 12;

#====================================================================
# Module loading
#====================================================================
BEGIN{ use_ok( Lemonldap::Config::Parameters ); }
BEGIN{ print "--> Version : ".$Lemonldap::Config::Parameters::VERSION."\n"; }

#====================================================================
# Object creation
#====================================================================
my $file = "t/test.xml";
my $config = Lemonldap::Config::Parameters->new( file => $file, cache => '/tmp/TEST' );
my $config_nocache = Lemonldap::Config::Parameters->new( file => $file );

isa_ok( $config, Lemonldap::Config::Parameters );
isa_ok( $config_nocache, Lemonldap::Config::Parameters );

#====================================================================
# Methods
#====================================================================
my @methods = (
	'_getFromCache',
	'destroy',
	'f_delete',
	'f_reload',
	'f_dump',
	'_readFile',
	'_deleteCache',
	'_writeCache',
	'getDomain',
	'findParagraph',
	'formateLineHash',
	'formateLineArray',
	'getAllConfig',
	);

can_ok( $config, @methods );
can_ok( $config_nocache, @methods );

#====================================================================
# Domain
#====================================================================
my $domain = "foo.com";
my $domain_cache = $config->getDomain( $domain );
my $domain_nocache = $config_nocache->getDomain( $domain );

ok( $domain_cache, "getDomain on $domain with cache" );
ok( $domain_nocache, "getDomain on $domain without cache" );
is_deeply( $domain_cache, $domain_nocache, "Equality of the domain (with an without cache)" );

#====================================================================
# Session
#====================================================================
my $session = $domain_cache->{'Session'};
ok( $session, "Read session value in domain paragraph" );

my $session_cache = $config->findParagraph( 'session', $session );
my $session_nocache = $config_nocache->findParagraph( 'session', $session );

ok( $session_cache, "findParagraph session on $session with cache" );
ok( $session_nocache, "findParagraph session on $session without cache" );
is_deeply( $session_cache, $session_nocache, "Equality of the session (with an without cache)" );


