package HTTPD::ADS::DBI;
use strict;

BEGIN {
  use Exporter ();
  use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = 0.6;
  @ISA         = qw (Exporter);
  #Give a hoot don't pollute, do not export more than needed by default
  @EXPORT      = qw ();
  @EXPORT_OK   = qw ();
  %EXPORT_TAGS = ();
}

use base qw(Class::DBI::Pg );
# it inherits from Class::DBI
HTTPD::ADS::DBI->set_db('Main', 'dbi:Pg:dbname=wwwads','','',{AutoCommit =>1});

########################################### main pod documentation begin ##
# Below is the documentation for this module.


=head1 NAME

HTTPD::ADS::DBI - Database objects for the HTTPD Attack Prevention System.

=head1 SYNOPSIS

  use HTTPD::ADS::DBI

Note that this module is not intented for general use but
as a part of the HTTPD::ADS system.

=head1 DESCRIPTION

This module contains the objects for the database. Each table is its
own subclass of HTTPD::ADS::DBI. This module and its classes are built on Class::DBI



=head1 USAGE



=head1 BUGS
It does not appear possible to support multiple WHERE clauses
such as SELECT * FROM foo WHERE x=2 AND WHERE y LIKE foo
(compound WHERE is supported: WHERE cond1 AND cond2, etc. put in operator of choice)
N.B. what about 3 part WHERE?

=head1 SUPPORT



=head1 AUTHOR

	Dana Hudes
	CPAN ID: DHUDES
	dhudes@hudes.org
	http://www.hudes.org

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1). Class::DBI,Class::DBI::Pg,SQL::AbstractSearch

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 HTTPD::ADS::Hosts

 Usage     : How to use this function/method
 Purpose   : database table class for hosts 
 Returns   :class/instances for database table
 Argument  : column names are methods in this class 
 Throws    :
 Comments  : 
           :

See Also   : Class::DBI

=cut

################################################## subroutine header end ##
package HTTPD::ADS::Hosts;
use base 'HTTPD::ADS::DBI';
#HTTPD::ADS::Hosts->set_up_table('hosts');
__PACKAGE__->table('hosts');
__PACKAGE__->columns(Primary =>'ip');
__PACKAGE__->columns(All => qw(ip score score_ts));

#package HTTPD::ADS::Arg_strings;
#use base 'HTTPD::ADS::DBI';
#HTTPD::ADS::Arg_strings->set_up_table('arg_strings');

package HTTPD::ADS::Usernames;
use base 'HTTPD::ADS::DBI';
HTTPD::ADS::Usernames->set_up_table('usernames');
use CLASS;
use Carp;
my %usernames_cache;

#CLASS->table('usernames');
#CLASS->columns(Primary =>'userid');
#CLASS->columns(All => qw (userid username));
#CLASS->sequence('userid');

sub cached_find_or_create {
  my $self = shift;
  my $args = shift;
  my $username = $$args{username};
  my $dbiclass;
  my $userid;
  confess "no username" unless (defined $username);
  unless (exists $usernames_cache{$username}) {
    $dbiclass = CLASS->find_or_create( {username => $username} );
    $userid= $dbiclass->get('userid');
    $usernames_cache{$username}= $userid;
  } else {
    $userid = $usernames_cache{$username}; 
    $dbiclass = CLASS->construct({userid => $userid, username => $username});
  }
  return $dbiclass;
}


package HTTPD::ADS::Request_strings;
use base 'HTTPD::ADS::DBI';
HTTPD::ADS::Request_strings->set_up_table('request_strings');
use CLASS;
use Carp;
my %request_strings_cache;

#CLASS->table('request_strings');
#CLASS->columns(Primary => 'requestid');
#CLASS->columns(All =>qw (requestid request_string));
#CLASS->sequence('requestid');


sub cached_find_or_create  {
  my $self = shift;
  my $args= shift;
  my $request_string = $$args{request_string};
  my $dbiclass;
  my $requestid;
  confess "no request string" unless (defined $request_string);
  unless (exists $request_strings_cache{$request_string}) {
    $dbiclass = CLASS->find_or_create( {request_string => $request_string} );
    $requestid= $dbiclass->get('requestid');
    $request_strings_cache{$request_string}= $requestid;
  } else {
    $requestid = $request_strings_cache{$request_string}; 
    $dbiclass = CLASS->construct({requestid => $requestid, request_string => $request_string});
  }
  return $dbiclass;
}

package HTTPD::ADS::Eventrecords;
 use vars qw ($VERSION);
 $VERSION = 0.8;
use base 'HTTPD::ADS::DBI';
HTTPD::ADS::Eventrecords->set_up_table('eventrecords');

__PACKAGE__->set_sql(count_errors => qq {
SELECT COUNT(eventid) from eventrecords WHERE (status >= 400 ) AND (ip = ?) AND ( ts >= ?)
});

sub count_errors {
  my ($self,@args) = @_;
#  my $sth = $self->sql_single("COUNT(ip) from eventrecords WHERE (status >=400) AND (ip = ?) AND ( ts >= ?) ");
#  my $result = $sth->select_val(\@args,['ip','ts']);
 my $Iterator = $self->search_count_errors(@args);
my $row = $Iterator->next;
return $$row{count};
};


__PACKAGE__->set_sql(first_error_event => qq {
SELECT eventid from __TABLE__ WHERE (status >= 400 ) AND (ip = ?) AND ( ts >= ?)ORDER BY ts LIMIT 1
});

sub first_error_event {
  my ($self,$ip,$ts) = @_;
  my @Rows = $self->search_first_error_event( $ip, $ts );
  return $Rows[0];
}
package HTTPD::ADS::Blacklist;
use base 'HTTPD::ADS::DBI';
#HTTPD::ADS::Blacklist->set_up_table('blacklist');
HTTPD::ADS::Blacklist->columns(Primary => qw /ip blocked_at/ );
HTTPD::ADS::Blacklist->columns(Others => qw /active first_event block_reason unblocked_at unblock_reason/ );
#HTTPD::ADS::Blacklist->might_have(host => HTTPD::ADS::Hosts =>
#				  (qw / nic_handle_notified notice_ts open_proxy open_proxy_test_at freq401 last_freq_computed_at/)				 );
#package HTTPD::ADS::freq401;
#use base 'HTTPD::ADS::DBI';
#HTTPD::ADS::freq401->set_up_table('freq401');

package HTTPD::ADS::notice_templates;
use base 'HTTPD::ADS::DBI';
#HTTPD::ADS::notice_templates->set_up_table('notice_templates');
__PACKAGE__->table('notice_templates');
__PACKAGE__->columns(Primary =>'notice_name');
__PACKAGE__->columns(All => qw(notice_name template));

package HTTPD::ADS::proxy_tested;
use base 'HTTPD::ADS::DBI';
HTTPD::ADS::proxy_tested->set_up_table('proxy_tested');

package HTTPD::ADS::notified;
use base 'HTTPD::ADS::DBI';
#HTTPD::ADS::notified->set_up_table('notified');
__PACKAGE__->table('notified');
__PACKAGE__->columns(Primary =>'ip');
__PACKAGE__->columns(All => qw(ip nic_handle_notified notice_ts notice_name));

package HTTPD::ADS::Whitelist;
#use base 'HTTPD::ADS::DBI';
#HTTPD::ADS::Whitelist->set_up_table('whitelist');
{
  my %whitelist;
  my @whitelisted=qw /0.0.0.0 127.0.0.1 208.45.4.153 208.45.4.154 208.45.4.155 68.167.18.160 68.167.18.161 68.167.18.162 68.167.18.163 68.167.18.164 68.167.18.165 68.167.18.166  68.167.18.167 204.147.80.1 /;	#the author's home subnet and ISP dns server
  my $entry;
  foreach $entry (@whitelisted) {
    $whitelist{$entry}=1;
  }
  ;
  {
		     #whitelist the root name servers of the Internet 
  my ($name,$aliases, $addrtype, $length,@addrs);
  foreach $entry ('A'..'Z') {
    ($name,$aliases, $addrtype, $length,@addrs) = gethostbyname("$entry.ROOT-SERVERS.NET");
    last unless defined $addrs[0];#the root servers are assigned in order w/o gaps
     $whitelist{sprintf "%vd",$addrs[0]} = 1;
  }  ;
}

  sub retrieve # Class method! named for compatibility with naming of Class::DBI
    {
      my ($self,@args) = @_;
      return (exists $whitelist{$args[0]}); 
    }
  ;
}
 

1; #this line is important and will help the module return a true value
__END__

