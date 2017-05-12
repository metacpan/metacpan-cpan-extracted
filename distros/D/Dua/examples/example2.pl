#!/bham/pd/bin/perl -w
#
# This is a just a quick example to illustrate the use of the Dua module
# without using objects. It's very similar to version 1 of the Dua module
# except each function has an additional argument 'session' which is created
# by dua_create and destroyed by dua_free.
#
use Dua qw(dua_create dua_open dua_errstr dua_find dua_show 
	   dua_close dua_free);

# Where to contact...

$dsa = "ldap.cs.bham.ac.uk";
$port = 0;                # Defaults to "ldap"

# Who to bind as...anonymous in this case...
$bind_dn = "";
$bind_passwd = "";

# Create a session structure.

$session = dua_create() || die('Unable to create dua');

# Attempt to bind to the DSA...

dua_open($session,$dsa, $port, $bind_dn, $bind_passwd) || 
     die("Can't connect to  DUA: ",dua_errstr($session));

# Where to search from...
$base = "\@c=gb\@o=The University of Birmingham\@ou=Computer Science";

# What to search for...
$filter="sn=Pillinger";

$scope = 1;     # Search the entire sub-tree.
$all = 0;       # Only return the DN's of matching objects.

# Do the search

%results = dua_find($session,$base, $filter,$scope,$all);

if (! %results ) 
{
  print "Nothing found\n";
  dua_close($session);
  exit;
}

print "Found ",scalar keys %results," match(es) \n\n";

# Look up each DN and extract a value...

foreach $dn (values %results)
{
  print $dn,"\n";

  # The DN will need reversing and separating by @'s. The ldap stuff seems
  # to put quotes around entries with spaces in them, so they need removing.

  $dn = "@" . join("@",reverse(split(/,\s*/,$dn)));
  $dn =~ s/\"//g;

  %results = dua_show($session,$dn);
  if (! %results)
  { print "No details found\n"; }
  else 
  {
    print $results{"sn"},"\n";
  }
}
print "\n";
dua_close($session);
dua_free($session);
