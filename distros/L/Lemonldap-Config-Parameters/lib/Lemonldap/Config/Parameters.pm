package Lemonldap::Config::Parameters;
use strict;
use BerkeleyDB;
use XML::Simple;
use Data::Dumper;
use Storable qw (thaw);
use LWP::UserAgent();

our $VERSION = '3.2.4';
our %IPC_CONFIG;

# Preloaded methods go here.
sub Minus {
                ## this function convert all key in caMel case into lowercase
                ##  it is a recursive function
                ## it keeps all the old keys
                my $rh =shift;
foreach (keys %{$rh}) {
                my $k =$_;
       return unless $k;
                if ($k ne lc ($k)) {
                       $rh->{lc($k)} = $rh->{$k} ;
      }
if (ref  $rh->{$k}) {
Minus ($rh->{$k});
}
}
return ;
}
                


sub _getFromCache {

   my $self  = shift;
   my $cache = $self->{cache};
   my $cog;
   my $ttl;

            tie %IPC_CONFIG, 'BerkeleyDB::Btree',
                         -Filename => $cache ,
                         -Flags => DB_CREATE ;
   unless ( keys(%IPC_CONFIG) ) {

       #first I read the xml file
              $self->_readFile;
       ## write cache
              $self->_writeCache;
       $cog = $self->{config};
   }
   else {

       $ttl                  = $IPC_CONFIG{TTL};
       $self->{ttl}          = $ttl;
#<modif ttl config lastmodified into ismodified>
#
#

  if ($ttl=~ /ifmodified/i ) 
   {
                $self->{ttl} =0;
       $ttl=0;
   }   
       $self->{available}    = $IPC_CONFIG{AVAILABLE};
       $self->{file}         = $IPC_CONFIG{FILE};
       $self->{agent}        = $IPC_CONFIG{SOAPAGENT};
       $self->{lastmodified} = $IPC_CONFIG{LASTMODIFIED};
       $self->{method}       = $IPC_CONFIG{METHOD};
       if ( $self->{method} ) {
           unless ( $self->{i_am_soap_server} ) {
               $self->{on_same} = $IPC_CONFIG{ON_SAME};
           }

           $self->{uri}   = $IPC_CONFIG{SOAPURI};
           $self->{proxy} = $IPC_CONFIG{SOAPPROXY};
       }
       my %tmp    = %IPC_CONFIG;
       my $tmpvar = $tmp{config};
      my $it;
                       $it     = eval $tmpvar if $tmpvar;
       $self->{config} = $it;
       my $__modif__ = ( stat $self->{file} )[9];
       if ( $__modif__ ne $self->{lastmodified} )
       {    # the modified timestamp is different i'll force the  reload
           $IPC_CONFIG{AVAILABLE} = 'RELOAD';
           $self->{lastmodified} = $__modif__;
       }

       if ( $IPC_CONFIG{AVAILABLE} eq 'RELOAD' ) {
           $self->_readFile;
           $self->_writeCache;
           $cog = $self->{config};
           return ($cog);
       }
       if ( $IPC_CONFIG{AVAILABLE} eq 'DESTROY' ) {
           $self->_readFile;
           $self->_deleteCache;
           delete $self->{cache};
           $cog = $self->{config};
           return ($cog);
       }
       $cog = $self->{config};

       # all is good we must compare time and ttl
       return ($cog) if ( $self->{ttl} == 0 );
       my $timenow  = time;
       my $timecalc = $self->{available} + $self->{ttl};
       if ( $timenow > $timecalc ) {    # the cache is too old
           $self->_readFile;
           $self->_writeCache;

       }
       $cog = $self->{config};
       return ($cog);

   }
}

sub destroy {
   my $self = shift;
   $self->_deleteCache;
   delete $self->{cache};
}

#   function used to manage cache conf from command line
sub f_delete {
   my $arg = shift;
   unlink ($arg); 
   return (0);
}

sub f_reload {
   my $arg = shift;

    tie %IPC_CONFIG, 'BerkeleyDB::Btree',
                                      -Filename => $arg ,
                                      -Flags => DB_CREATE ;
  
   $IPC_CONFIG{ttl} = '1';

   $IPC_CONFIG{AVAILABLE} = 'RELOAD';

   untie %IPC_CONFIG ;
   return (0);
}

sub f_dump {
   my $arg = shift;
  tie %IPC_CONFIG, 'BerkeleyDB::Btree',
                                      -Filename => $arg ,
                                      -Flags => DB_CREATE ;

   $Data::Dumper::Indent = 1;
   $Data::Dumper::Terse = 1;
if ($IPC_CONFIG{'QUEUE'}) {  #it's ipc segment for handler cache level 2
my $tmpvar = $IPC_CONFIG{'QUEUE'};
my @tmp ;
if ($tmpvar) {
                @tmp= split /#/,$tmpvar ;
} 
print "Queue : $#tmp\n";
foreach (@tmp) {
                print "=> $_\n";
}
print "\n";

}                 
   my $ligne = Dumper( \%IPC_CONFIG );
   print "$ligne\n";

untie %IPC_CONFIG;
   return "OK\n";
}

sub _retrieve_on_soap {
   my $self  = shift;
   my $uri   = shift;
   my $proxy = shift;
   my $file  = $self->{file};
   my $glue  = $self->{cache};
   require SOAP::Lite;
   my $s  = SOAP::Lite->uri($uri)->proxy($proxy);
   my $hl = $s->SOAP::new(
       file  => $file,
       cache => $glue,
   );

   #my $res=$hl->SOAP::retrieve ;
  return $hl->{config};
}

sub _readFile {
   my $self = shift;
   my ( $uri,          $proxy, $obj );
   my ( $lastmodified, $par,   $config );
   my $file   = $self->{file};
   $self->{lastmodified} = ( stat $self->{file} )[9];
    
   my $cache  = $self->{cache};
   $cache = uc $cache if ($self->{i_am_soap_server}); 
   my $method = $self->{method}||'NONE';
   unless ( $self->{i_am_soap_server} ) {

       if ( $method eq 'SOAP' ) {
           $uri   = $self->{uri};
           $proxy = $self->{proxy};

#unless ($self->{i_am_soap_server})   #the server soap objet must not make soap request on itself
           my $conf_enc = $self->_retrieve_on_soap( $uri, $proxy );
           my $conf_decode = thaw($conf_enc);
           $self->{config} = $conf_decode;
           $self->_writeCache;
### now a rewrite or write my file on disk
### the soap agent on  server must not write file too
           return 1 if ( $self->{i_am_soap_server} );
### the agent config in soap server must not write file
           return 1 if ( $self->{on_same} );
## last precaution
           my $filelock = "$self->{file}.lock";
           return 1 if ( -e $filelock );

           my $xml = XMLout($conf_decode);
           open CONFIG, ">$file" || die "@! $file \n";
           flock( CONFIG, 2 );    # I lock file
           print CONFIG $xml;
           close(CONFIG);         # make the unlock
           return 1;

       }
    }

   $config = XMLin( $file, ForceArray => 1, );

   # I extract info about the cache ttl

   my $cache_param = $config->{cache};

   # there are sereval cache descriptors or one alone
   #
   my $__cache__;
   foreach my $tmp ( keys %{$cache_param} )

   {
       if ( $cache_param->{$tmp}{'ConfigIpcKey'} eq $cache ) {
           $__cache__ = $cache_param->{$tmp};
       }

   }
   $par          = $__cache__->{ConfigTtl};
   if ($par =~ /ismodified/i ) {
                $par =0;
       $lastmodified = 1;
   } 

   $self->{ttl} = $par || '0';
   $self->{method} = $__cache__->{Method}||'NONE';
   if ( $self->{method} eq 'SOAP' ) {
       $self->{uri}   = $__cache__->{SoapUri};
       $self->{proxy} = $__cache__->{SoapProxy};
       $self->{agent} = $__cache__->{SoapAgent};

   }
  # if ( ( $self->{lastmodified} ) and not($lastmodified) ) {
  #     $self->{lasmodified} = 0;
  # }
  # else {
       $self->{lastmodified} = 1 unless $self->{lastmodified};
  # }
   ## call Minus function for lowering case
   Minus($config) ;
    
  
   $self->{config} = $config;
   1;
}

sub _deleteCache {
   my $self  = shift;
   my $cache = $self->{cache};
   
  tie %IPC_CONFIG, 'BerkeleyDB::Btree',
                              -Filename => $cache ,
                              -Flags => DB_CREATE ;
 %IPC_CONFIG ='';
 untie %IPC_CONFIG;
}

sub _writeCache {
   my $self = shift;

#    unless ( $self->{i_am_soap_server} ) {
#        return 1
#          if ( $self->{on_same} )
#          ;    ## the agent config in the soap server must not
#        ## write in cache , there soap agent does this
#        return 1
#          if ( $IPC_CONFIG{ON_SAME} )
#          ;    ## the soap agent may be already write in IPC
#               #with me it's belt and straps of  trousers
#        my $filelock = "$self->{file}.lock";
#        return 1 if ( -e $filelock );
#    }

   my $time   = time;
   my $cache  = $self->{cache};
   my $config = $self->{config};
   $Data::Dumper::Purity = 1;
   $Data::Dumper::Terse  = 1;
   $Data::Dumper::Deepcopy  = 1;
   my $configs      = Dumper($config);
   my $ttl          = $self->{ttl};
   my $lastmodified = $self->{lastmodified};
   my $file         = $self->{file};
   delete $IPC_CONFIG{config};
#    %IPC_CONFIG = '';
   untie %IPC_CONFIG;
unlink ($self->{cache});
    tie %IPC_CONFIG, 'BerkeleyDB::Btree',
                           -Filename => $cache ,
                           -Flags => DB_CREATE ;
   $IPC_CONFIG{config}       = $configs;
   $IPC_CONFIG{TTL}          = $ttl;
   $IPC_CONFIG{AVAILABLE}    = $time;
   $IPC_CONFIG{FILE}         = $file;
   $IPC_CONFIG{SOAPAGENT}    = $self->{agent} if $self->{agent};
   $IPC_CONFIG{LASTMODIFIED} = $lastmodified if $lastmodified;
   $IPC_CONFIG{METHOD}    = $self->{method} if $self->{method};
   $IPC_CONFIG{SOAPURI}   = $self->{uri} if $self->{uri};
   $IPC_CONFIG{SOAPPROXY} = $self->{proxy} if $self->{proxy};    
if ( $self->{method} ) {

       if ( $self->{i_am_soap_server} )
       {    # the soap server  tell that is it for an eventual
               # agent config in the same machine
               # I will create  a empty lock file for
               # avoid recursive call between
               # soap server and agent config

           $file = "$self->{file}.lock";

           open LOCK, ">$file";
           close LOCK;
           $IPC_CONFIG{ON_SAME} = 1;

           #now i 'll notice at all agents the modification
           my @soapagent;
           my $sp ;
            my $tt =  $self->{agent};
            $sp =eval $tt;
           @soapagent = @{$sp};
            my $glue =uc ($self->{cache});
            my $ua = LWP::UserAgent->new (timeout => 30);
            for my $l (@soapagent) {
                     my $res  =$ua->get ("$l?glue=$glue");

             }
             }

   
   }
   untie %IPC_CONFIG;

   return 1;
}

sub new {
   my $class = shift;
   my %conf  = @_;

   my $self = bless {

     },
     ref($class) || $class;
   $self->{file}             = $conf{file}   if $conf{file};
   $self->{cache}            = $conf{cache}  if $conf{cache};
   $self->{i_am_soap_server} = $conf{server} if $conf{server};
   $self->{cache} = lc $self->{cache} if ($self->{i_am_soap_server});
   return $self;
}

sub getDomain {
   my $self   = shift;
   my $domain = shift;
   my $config = $self->getAllConfig;
   unless ($domain) {
       my $d = ( keys %{ $config->{domain} } );
       die "Ambigious domain\n" if ( $d != 1 );
       ($domain) = ( keys %{ $config->{domain} } );
   }

   my $cdomain = $config->{domain}{$domain};
   return ($cdomain);

}

sub findParagraph {
   my ( $self, $chapitre, $motif ) = @_;
   my $config = $self->getAllConfig;
   my $parag;
   if ( $chapitre && $motif ) {
       $parag = $config->{$chapitre}->{$motif};
   }
   else {
       $parag = $config->{$chapitre};
   }
   return ($parag);
}

sub formateLineHash {
   my ( $self, $line, $motif, $replace ) = @_;
   my %cf;
   my $t;
   if ( $line =~ /^\(/ ) {
       $t = $line;
   }
   else {
       $t = "($line );";
   } 

   %cf = eval $t;
   if ($motif) {
       for ( values %cf ) {
           s/$motif/$replace/;
       }
   }
   return ( \%cf );
}

sub formateLineArray {
   my ( $self, $line, $motif, $replace ) = @_;
   my @cf;
   my $t;
   if ( $line =~ /^\[/ ) { $t = $line; }
   else {
       $t = "[$line ];";
   }
   @cf = eval $t;
   if ($motif) {
       for (@cf) {
           s/$motif/$replace/;
       }
   }
   return ( \@cf );
}

sub getAllConfig {
   my $self = shift;
   my $config;
   my $file = $self->{file};
   if ( $self->{cache} ) {    #  cache is available
       $config = $self->_getFromCache;

   }
   else {                     # cache forbidden
      
   $config = XMLin( $file, ForceArray => 1, );

   Minus($config) ;
   }
  unless ($config) {  #at the first time  
   $config = XMLin( $file, ForceArray => 1, );

   Minus($config) ;
   }
   return $config;
}
1;
__END__


=head1 NAME

Lemonldap::Config::Parameters - Backend of configuration for lemonldap SSO system

=head1 SYNOPSIS

 #!/usr/bin/perl 
 use Lemonldap::Config::Parameters;
 use Data::Dumper;
 my $nconfig= Lemonldap::Config::Parameters->new(
                            file  =>'applications.xml',
                            cache => '/tmp/CONF' );
 my $conf= $nconfig->getAllConfig;
 my $cg=$nconfig->getDomain('appli.cp');
 my $ligne= $cg;
 print Dumper( $ligne);
 my $e = $cg->{templates_options} ;
 my $opt= "templates_dir";
 my $va = $cg->{$opt};
 my $ligne= $nconfig->formateLineHash($e,$opt,$va) ;

or by API :

Lemonldap::Config::Parameters::f_delete('/tmp/CONF');

or by command line 

perl -e "use Lemonldap::Config::Parameters;
Lemonldap::Config::Parameters::f_delete('/tmp/CONF');"

=head1 INSTALLATION

 perl Makefile.PL
 make
 make test 
 make install
 

=head1 DESCRIPTION

Lemonldap is a WEB SSO framework system under GPL. 

Login page , handlers must retrieve their configs in an unique file eg
:"applications.xml".

This file has a XML structrure. The parsing phase may be heavy, so lemonldap
can cache the result of parsing in berkeleyDB file. For activing the cache you
must have in the config :

 <cache id="/tmp/CONF"> 
 </cache> 

with :  name='/tmp/CONF' it will be the file name used for berkeley file.

The berkelay cache will be reloaded at every file modification 
You can force the reload off file by the command line bellow:

perl -e "use Lemonldap::Config::Parameters;
Lemonldap::Config::Parameters::f_reload('/tmp/CONF');"

or 

perl -e "use Lemonldap::Config::Parameters;
Lemonldap::Config::Parameters::f_delete('CONF');"

IMPORTANT : the user's ID who runs those scripts MUST be the same of the berkeleyDB file's owner !! 


WITHOUT CACHE SPECIFICATION , LEMONLDAP DOESN'T USE CACHE ! It  will read and
parse config file each time.


=head1 METHODS

=head2  new  (file  =>'/foo/my_xml_file.xml' ,
                cache => '/tmp/CONF' );  # with berkelay cache

or 
       new(file  =>'/foo/my_xml_file.xml');     # without berkeleyDB  cache

=head2 getAllConfig 

Return the  reference of hash  storing whole the config.

=head2  getDomain('foo.bar')

Return the reference of hash of config for domain  
If the config file has only one domain , domain may bo omit .  

eg : 
for the xml config file :
 <domain    name="foo.bar"  
          cookie=".foo.bar"
          path ="/" 
          templates_dir="/opt/apache/portail/templates"
          templates_options =  "ABSOLUTE     => '1', INCLUDE_PATH =>
'templates_dir'"
          login ="http://cportail.foo.bar/portail/accueil.pl"
          menu= "http://cportail.foo.bar/portail/application.pl"   
          ldap_server ="cpldap.foo.bar"
          ldap_port="389"
          DnManager= "cn=Directory Manager"
          passwordManager="secret"
          branch_people="ou=mefi,dc=foo,dc=bar"  
          session="memcached"
         >
 </domain> 

   my $cg = $nconfig->getDomain();

 DB<2> x $cg
  0  HASH(0x89b108c)
   'DnManager' => 'cn=Directory Manager'
   'branch_people' => 'ou=mefi,dc=foo,dc=bar'
   'cookie' => '.foo.bar'
   'ldap_port' => 389
   'ldap_server' => 'cpldap.foo.bar'
   'login' => 'http://cportail.foo.bar/portail/accueil.pl'
   'menu' => 'http://cportail.foo.bar/portail/application.pl'
   'passwordManager' => 'secret'
   'path' => '/'
   'session' => 'memcached'
   'templates_dir' => '/opt/apache/portail/templates'
   'templates_options' => 'ABSOLUTE => \'1\', INCLUDE_PATH => \'templates_dir\'

=head2  ref_of_hash : formateLineHash(string:line);

    or  formateLineHash(string:line,string:motif,string:key);

Return a anonyme reference on  hash  and may replace the motif in the value of
key by the value of another key  :

eg 

my $e = $cg->{templates_options} ;
my $opt= "templates_dir";
my $va = $cg->{$opt};
my $ligne= $nconfig->formateLineHash($e,$opt,$va) ;

gives :  
 DB<1> x $ligne
0  HASH(0x848b778)
  'ABSOLUTE' => 1
  'INCLUDE_PATH' => '/opt/apache/portail/templates'

 $ligne can be use directly like option for somes instructions

=head2  ref_of_array : formateLineArray(string:line);
or  formateLineArray(string:line,string:motif,string:key);

Return a anonyme reference on  array  and may replace the motif in the element
by the value of another key  :

 the return value can be use directly like option for somes instructions

=head2 findParagraph(chapter[,section])
  
Find and return a reference of chapter finds in xml file , a section can be
specified.

=head1 Functions

=head2 Lemonldap::Config::Parameters::f_delete('CONF');

Delete the cache and the restore segment

=head2 Lemonldap::Config::Parameters::f_reload('CONF');

The next acces on cache will need to read file before .

=head2 Lemonldap::Config::Parameters::f_dump('CONF');

Dump of the config 

=head1 SOAP server facility .

 Don't use this ,I 'll rewrite all SOAP facility

 <location /conf_lemonldap>
   Options +execcgi
   SetHandler perl-script
   PerlHandler Apache::SOAP
   PerlSetVar dispatch_to  'SOAPserver'
 </location>

Important : You MUST place SOAPserver.pm under the apache's directory :
eg : /usr/local/apache/
 

  <cache  id="config1"
       ConfigIpcKey="CONF"
       ConfigTtl ="10000000"
       LastModified='1'
       Method="SOAP" 
       SoapUri="http://www.portable.appli.cp/SOAPserver"
       SoapProxy="http://www.portable.appli.cp/conf_lemonldap" 
        SoapAgent="['http://localhost/cgi-bin/refresh.cgi','http://www.portable.appli.cp/perl/refresh.cgi']"
    >

with :SoapUri and SoapProxy : see SOAP::Lite documentation 
      SoapAgent : the list of agents CGI  on lemonldap server who must to be call in the case of modification

 After that agent receive notification , they do a soap request upon the administration server  for reload the lastnew config .
 If it's fail , slave lemonldap uses a local file XML which is the lastest copy of file config .

An agent lemonldap MAY to be in same server that the SOAP manager. So SOAP manager uses 'conf' instead 'CONF' for the IPC glue .
It 'll be two IPC segments 'CONF' and 'conf'  'CONF' for agent 'conf' for SOAP server ,but don't worry it's an internal process ,
stay to use 'CONF' .


=head1 SEE ALSO

Lemonldap(3), Lemonldap::Portal::Standard

http://lemonldap.sourceforge.net/

"Writing Apache Modules with Perl and C" by Lincoln Stein E<amp> Doug
MacEachern - O'REILLY

See the examples directory

=head1 AUTHORS

=over 1

=item Eric German, E<lt>germanlinux@yahoo.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Eric German

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.


=back

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 2 dated June, 1991.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 A copy of the GNU General Public License is available in the source tree;
 if not, write to the Free Software Foundation, Inc.,
 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
