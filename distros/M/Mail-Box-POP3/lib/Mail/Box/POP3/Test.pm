# Copyrights 2001-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box-POP3.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::POP3::Test;
use vars '$VERSION';
$VERSION = '3.004';

use base 'Exporter';

use strict;
use warnings;

use Mail::Transport::POP3;

use List::Util 'first';
use File::Spec;

our @EXPORT = qw/start_pop3_server start_pop3_client/;

#
# Start POP3 server for tests
#

sub start_pop3_server($;$)
{  my $popbox  = shift;
   my $setting = shift || '';

   my $serverscript = File::Spec->catfile('t', 'server');

   # Some complications to find-out $perl, which must be absolute and
   # untainted for perl5.6.1, but not for the other Perl's.
   my $perl   = $^X;
   unless(File::Spec->file_name_is_absolute($perl))
   {   my @path = split /\:|\;/, $ENV{PATH};
       $perl    = first { -x $_ }
                      map { File::Spec->catfile($_, $^X) }
                           @path;
   }

   $perl =~ m/(.*)/;
   $perl = $1;

   %ENV = ();

   open(my $server, "$perl $serverscript $popbox $setting|")
       or die "Could not start POP3 server\n";

   my $line  = <$server>;
   my $port  = $line =~ m/(\d+)/ ? $1
     : die "Did not get port specification, but '$line'";

   ($server, $port);
}

#
# START_POP3_CLIENT PORT, OPTIONS
#

sub start_pop3_client($@)
{   my ($port, @options) = @_;
    
    Mail::Transport::POP3->new
     ( hostname => '127.0.0.1'
     , port     => $port
     , username => 'user'
     , password => 'password'
     , @options
     );
}

1;
