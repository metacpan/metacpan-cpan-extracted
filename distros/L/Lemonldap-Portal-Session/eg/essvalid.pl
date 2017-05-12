#!/usr/bin/perl -w
use strict;
use Lemonldap::Portal::Session;
use XML::Simple;
use Data::Dumper;
use Net::LDAP::Entry;
my $dn ="uid=egerman-cp,ou=personnes,ou=cp,dc=demo,dc=net";
my $entry = Net::LDAP::Entry->new;
$entry->dn($dn);
$entry->add (
          'uid' => 'egerman-cp',
          'mail' => 'germanlinux@yahoo.fr' ,
	  'ou' => '013390',
          'roleprofil' =>"appli;etoile" ,
          'mefiapplicp' => ["appli1;etoile1" ,"appli2;etoile2"]
      						            );

							    

my $file = shift||"application_new.xml";
my $test;
eval {
$test = XMLin( $file,
     'ForceArray' => '1'
			 );		     

} ;

if ($@) { print "ERREUR SUR $file\n"; 
          } else {
		 print "$file:Correct\n"; 
	  }
  	  
my $paramxml = $test->{DefinitionSession} ;
my $obj = Lemonldap::Portal::Session->init ($paramxml,'entry' =>$entry) ;

print Dumper ($obj) ;



