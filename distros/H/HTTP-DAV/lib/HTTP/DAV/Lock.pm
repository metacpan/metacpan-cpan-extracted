package HTTP::DAV::Lock;

use strict;
use vars qw($VERSION);
use HTTP::DAV::Utils;

$VERSION = '0.09';

###########################################################################

=head1 NAME

HTTP::DAV::Lock - Represents a WebDAV Lock.

=head1 SYNOPSIS

 Need example

=head1 DESCRIPTION

=cut

sub new {
    my $self = {};
    bless $self, shift;
    $self->_init(@_);
    return $self;
}

sub _init {
   my ($self,@p) = @_;
   my($owned) = HTTP::DAV::Utils::rearrange(['OWNED'],@p);
   $self->{_owned} = $owned || 0;
}

###########################################################################

=head1 ACCESSOR METHODS

=over

=cut

# GET
sub get_owner { $_[0]->{_owner}; }
sub get_token { $_[0]->{_token}; }
sub get_depth { $_[0]->{_depth}; }
sub get_timeout { $_[0]->{_timeout}; }
sub get_locktoken { $_[0]->{_locktokens}[0]; }
sub get_locktokens{ $_[0]->{_locktokens}; }

sub set_scope     { $_[0]->{_scope}     = $_[1]; }
sub set_owned     { $_[0]->{_owned}     = $_[1]; }
sub set_type      { $_[0]->{_type}      = $_[1]; }
sub set_owner     { $_[0]->{_owner}     = $_[1]; }
sub set_depth     { $_[0]->{_depth}     = $_[1]; }
sub set_timeout   { $_[0]->{_timeout}   = $_[1]; }
sub set_locktoken { 
   my ($self,$href) = @_;
   # Remove leading and trailing space from "  http://.../..."
   $href =~ s/^\s*//g; $href =~ s/\s*$//g; 
   # Remove < > from around it available
   $href =~ s/^<(.*)>$/$1/g;

   push (@{$self->{_locktokens}}, $href); 
}

# IS
sub is_owned { $_[0]->{_owned}; }

###########################################################################
# Synopsis: 
# Full parameters
# make_lock_xml (
#    -owner => (owner|http://mysite/~mypage/)
#    -timeout => num_of_seconds (e.g. 134123432)
#    -scope => (exclusive|shared)
#    -type =>  (write)
# )
sub make_lock_xml {
   my ($self,@p) = @_;
   my($owner,$timeout,$scope,$type,@other) = 
      HTTP::DAV::Utils::rearrange(['OWNER','TIMEOUT','SCOPE','TYPE'],@p);  

   ####
   # Create a new XML document
   # It may look something like this
   # <?xml version=1.0 encoding="utf-8"?>
   #   <D:lockinfo xmlns:D="DAV:">
   #       <D:lockscope><D:exclusive/></D:lockscope>
   #       <D:locktype><D:write/></D:locktype>
   #       <D:owner>
   #          <D:href>http://mysite/~mypage.html</D:href>
   #       </D:owner>
   #   </D:lockinfo>
   my $xml_request = qq{<?xml version="1.0" encoding="utf-8"?>\n};

   $xml_request .= "<D:lockinfo xmlns:D='DAV:'>\n";
   $xml_request .= "<D:lockscope><D:$scope/></D:lockscope>\n";
   $xml_request .= "<D:locktype><D:$type/></D:locktype>\n";
#$xml_request = <<END;
#<?xml version="1.0" encoding="utf-8"?>
#<lockinfo xmlns='DAV:'>
#<lockscope><$scope/></lockscope>
#<locktype><$type/></locktype>
##</lockinfo>
#END


   # If the owner is an HREF then set it into an <D:href> tag 
   # else just enter it as text.
   my $o = URI->new($owner);
   if ($o->scheme) {
      $xml_request .= "<D:owner><D:href>$owner</D:href></D:owner>\n";
      #$xml_request .= "<owner><href>$owner</href></owner>\n";
   } elsif ( $owner ) {
      $xml_request .= "<D:owner>$owner</D:owner>\n";
      #$xml_request .= "<owner>$owner</owner>\n";
   }

   $xml_request .= "</D:lockinfo>\n";
   #$xml_request .= "</lockinfo>\n";
 
   return ($xml_request);
}

###########################################################################
# Synopsis: @locks = XML_lockdiscovery_parse($node);
# With this XML node:
#<D:lockdiscovery>
#   <D:activelock>
#      <D:locktype><D:write/></D:locktype>
#      <D:lockscope><D:exclusive/></D:lockscope>
#      <D:depth>0</D:depth>
#      <D:timeout>Infinite</D:timeout>
#      <D:owner>pcollins</D:owner>
#      <D:locktoken>
#          <D:href>opaquelocktoken:d3ae67b0-1dd1-a5f7-f067587e98e1</D:href>
#          <D:href>...</D:href>
#      </D:locktoken>
#   </D:activelock>
#</D:lockdiscovery>
# 
# returns an array of locks (will be more than one in shared locks scenarios)

sub XML_lockdiscovery_parse {
   my ($self,$node_lockdiscovery) = @_;
   my @found_locks = ();

   # <!ELEMENT lockdiscovery (activelock)* >
   my @nodes_activelock= HTTP::DAV::Utils::get_elements_by_tag_name($node_lockdiscovery,"D:activelock");

   # <!ELEMENT activelock (lockscope, locktype, depth, owner?, timeout?, locktoken?) >
   foreach my $node_activelock ( @nodes_activelock ) {

      my $lock = HTTP::DAV::Lock->new();
      push(@found_locks,$lock);
   
      my $nodes_lock_params = $node_activelock->getChildNodes();
      next unless $nodes_lock_params;
      my $prop_count = $nodes_lock_params->getLength;

      for (my $prop_num = 0; $prop_num < $prop_count; $prop_num++) {
         my $node_lock_param = $nodes_lock_params->item($prop_num);   

         # $node_lock_param is one of the following
         # 1. <!ELEMENT lockscope (exclusive | shared) >
         # 2. <!ELEMENT locktype (write) >
         # 3. <!ELEMENT depth (#PCDATA) >
         # 4. <!ELEMENT owner ANY >
         # 5. <!ELEMENT timeout (#PCDATA) >
         # 6. <!ELEMENT locktoken (href+) >

         my $lock_prop_name = $node_lock_param->getNodeName();
         $lock_prop_name =~ s/.*:(.*)/$1/g;
   
         # 1. RFC2518 currently only allows locktype of exclusive or shared
         if ( $lock_prop_name eq "lockscope" ) {
            my $node_lock_scope = HTTP::DAV::Utils::get_only_element($node_lock_param);
            my $lock_scope = $node_lock_scope->getNodeName;
            $lock_scope =~ s/.*:(.*)/$1/g;
            $lock->set_scope($lock_scope);
         } 
   
         # 2. RFC2518 currently only allows locktype of "write"
         elsif ( $lock_prop_name eq "locktype" ) {
            my $node_lock_type = HTTP::DAV::Utils::get_only_element($node_lock_param);
            my $lock_type = $node_lock_type->getNodeName;
            $lock_type =~ s/.*:(.*)/$1/g;
            $lock->set_type($lock_type);
         } 
   
         # 3. RFC2518 allows only depth of 0,1,infinity
         elsif ( $lock_prop_name eq "depth" ) {
            my $lock_depth = HTTP::DAV::Utils::get_only_cdata($node_lock_param);
            $lock->set_depth($lock_depth);
         }
   
         # 4. RFC2518 allows anything here.
         # Patrick: I'm just going to convert the XML to a string
         elsif ( $lock_prop_name eq "owner" ) {
            $lock->set_owner( $node_lock_param->getFirstChild->toString );
         }
   
         # 5. RFC2518 (Section 9.8) e.g. Timeout: Second-234234 or Timeout: infinity
         elsif ( $lock_prop_name eq "timeout" ) {
            my $lock_timeout = HTTP::DAV::Utils::get_only_cdata($node_lock_param);
            my $timeout = HTTP::DAV::Lock->interpret_timeout($lock_timeout);
            $lock->set_timeout( $timeout );
            #if ( $HTTP::DAV::DEBUG ) {
            #   $lock->{ "_timeout_val" } = HTTP::Date::time2str($timeout) 
            #}
         }
   
         # 6. RFC2518 allows one or more <href>'s
         # Push them all into the lock object.
         elsif ( $lock_prop_name eq "locktoken" ) {
            my @nodelist_hrefs = HTTP::DAV::Utils::get_elements_by_tag_name($node_lock_param,"D:href");
            foreach my $node ( @nodelist_hrefs) {
               my $href_cdata = HTTP::DAV::Utils::get_only_cdata( $node );
               $lock->set_locktoken( $href_cdata );
            }
         }

      } # Foreach property
   } # Foreach ActiveLock

   return @found_locks;
}

###########################################################################
# Synopsis: $hashref = get_supportedlock_details($node);
#<D:supportedlock>
#   <D:lockentry>
#      <D:lockscope> <D:exclusive/> </D:lockscope>
#      <D:locktype>  <D:write/>     </D:locktype>
#   </D:lockentry>
#   <D:lockentry>
#      <D:lockscope> <D:shared/>    </D:lockscope>
#      <D:locktype>  <D:write/>     </D:locktype>
#   </D:lockentry>
#</D:supportedlock>
#
# Returns something similar to:
#  @supportedlocks'  = (
#    { 'type' => 'write', 'scope' => 'exclusive' },
#    { 'type' => 'write', 'scope' => 'shared'    }
#  );    

sub get_supportedlock_details {
   my ($node_supportedlock) = @_;

   return unless $node_supportedlock;

   # Return values
   my @supportedlocks=();

   my @nodelist_lockentries = HTTP::DAV::Utils::get_elements_by_tag_name($node_supportedlock,"D:lockentry");
   foreach my $i ( 0 .. $#nodelist_lockentries ) {
      my $node_lockentry = $nodelist_lockentries[$i];

      my $lock_prop_name = $node_lockentry->getNodeName();
      next unless $lock_prop_name;

      # RFC2518 currently only allows lockscope of exclusive or shared
      # <D:lockscope> <D:shared|exclusive/>    </D:lockscope>
      my $node_lockscope=HTTP::DAV::Utils::get_only_element($node_lockentry,"D:lockscope");
      if ( $node_lockscope ) {
         my $node_lockscope_param =HTTP::DAV::Utils::get_only_element($node_lockscope);
         my $lockscope = $node_lockscope_param->getNodeName;
         $lockscope =~ s/.*:(.*)/$1/g;
         $supportedlocks[$i]{ "scope" } = $lockscope;
      }

      # RFC2518 currently only allows locktype of "write"
      # <D:locktype>  <D:write/>     </D:locktype>
      my $node_locktype = HTTP::DAV::Utils::get_only_element($node_lockentry,"D:locktype");
      if ( $node_locktype ) {
         my $node_locktype_param =HTTP::DAV::Utils::get_only_element($node_locktype);
         my $locktype = $node_locktype_param->getNodeName;
         $locktype =~ s/.*:(.*)/$1/g;
         $supportedlocks[$i]{ "type" } = $locktype;
      }
   }

   return \@supportedlocks;
}


###########################################################################
=item Timeout
This parameter can take an absolute or relative timeout.
The following forms are all valid for the -timeout field:

Timeouts in:
    300
    30s                              30 seconds from now
    10m                              ten minutes from now
    1h                               one hour from now
    1d                               tomorrow
    3M                               in three months
    10y                              in ten years time
Timeout at:
    2000-02-31 00:40:33              at the indicated time & date
    For more time and date formats that are handled see HTTP::Date

RFC2518 states that the timeout value MUST NOT be greater 
than 2^32-1. If this occurs it will simply set the timeout to infinity
=cut

sub timeout {
   my ($self,$timeout) = @_;
   my $timeoutret;

   return 0 unless $timeout;

   if ($timeout =~ /^\d+[a-zA-Z]$/ ) {
      $timeoutret = _timeout_calc($timeout);
   } 
   elsif ($timeout =~ /infinity/i || $timeout =~ /^\d+$/ ) {
      $timeoutret = $timeout;
   } 
   else {
      my ($epochgmt) = HTTP::Date::str2time($timeout);
      $timeoutret = $epochgmt - time;
   }

   # Timeout value cannot be greater than 2^32-1 as per RFC2518
   if ( $timeoutret =~ /infinity/i || $timeoutret >= 4294967295 ) {
      return "Infinite, Second-4294967295 ";
   } 
   elsif ( $timeoutret <= 0 ) {
      return 0;
   } else {
      return "Second-$timeoutret ";
   }
}

###########################################################################
sub interpret_timeout {
   my ($self,$timeout) = @_;

   return "Infinite" if $timeout =~ /Infinite/i;
   return "Infinite" if !defined $timeout || $timeout eq "";

   if ($timeout =~ /Second\-(\d+)/ ) {
      return time + $1;
   } else {
      HTTP::DAV::Utils::bad("Ugh... can't interpret Timeout value \"timeout: $timeout\"\n");
   }
}

###########################################################################
# This internal routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from
# Mark Fisher.
# Borrowed from Lincoln Stein's CGI.pm

sub _timeout_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "180s" -- in 180 seconds
    # "2m" -- in 2 minutes
    # "12h" -- in 12 hours
    # "1d"  -- in 1 day
    # "3M"  -- in 3 months
    # "2y"  -- in 2 years
    # "3m"  -- 3 minutes
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^(\d+|\d*\.\d*)([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
        return $time;
    }
    return $offset;
}


###########################################################################
=item $r->as_string()

Method returning a textual representation of the request.
Mainly useful for debugging purposes. It takes no arguments.

=cut

sub as_string
{
   my ($self,$space,$debug) = @_;
   my ($str) = "";
   $space = "   " if !defined $space;
   $str .= "${space}Lock Object ($self)\n";
   $space  .= "   ";
   $str .= "${space}'_owned':   " . ($self->{_owned}||"") . "\n";
   $str .= "${space}'_scope':   " . ($self->{_scope}||"") . "\n";
   $str .= "${space}'_type':    " . ($self->{_type} ||"") . "\n";
   $str .= "${space}'_owner':   " . ($self->{_owner}||"") . "\n";
   $str .= "${space}'_depth':   " . ($self->{_depth}||"") . "\n";
   $str .= "${space}'_timeout': " . ($self->{_timeout}||"") . "\n";
   $str .= "${space}'_locktokens': " . join(", ", @{$self->get_locktokens()} ) . "\n";

   $str;
}

sub pretty_print
{
   my ($self,$space) = @_;
   my ($str) = "";
   $str .= "${space}Owner:   $self->{_owner}\n";
   $str .= "${space}Scope:   $self->{_scope}\n";
   $str .= "${space}Type:    $self->{_type}\n";
   $str .= "${space}Depth:   $self->{_depth}\n";
   $str .= "${space}Timeout: $self->{_timeout}\n";
   $str .= "${space}LockTokens: " . join(", ", @{$self->get_locktokens()} ) . "\n";

   $str;
}


###########################################################################
=back

=head1 SEE ALSO

L<HTTP::Headers>, L<HTTP::Message>, L<HTTP::Request::Common>

=head1 COPYRIGHT

Copyright 2000 Patrick Collins.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
