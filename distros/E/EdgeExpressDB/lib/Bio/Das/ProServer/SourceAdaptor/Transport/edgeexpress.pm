=head1 NAME

 Bio::Das::ProServer::SourceAdaptor::Transport::edgeexpress 
 A transport layer for EdgeExpressDB 

=head1 VERSION

$Revision: 1.7 $

=head1 SYNOPSIS

=head1 DESCRIPTION

 Transport helper class for EdgeExpressDB database access 
 and persistance

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

  [my_eedb]
  transport      = edgeexpress
  eedb_url       = mysql://<user>:<pass>@<host>:<port optional>/<database_name>

=head1 DEPENDENCIES

=over

=item L<DBI>

=item L<DBD::mysql>

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::generic>

=item L<MQdb::Database>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Jessica Severin <severin@gsc.riken.jp>.

=head1 LICENSE AND COPYRIGHT

=head1 APPENDIX

 The rest of the documentation details each of the object methods. 
 Internal methods are usually preceded with a _

=head1 METHODS

=cut

#########
# Author:        Jessica Severin
# Maintainer:    Jessica Severin
# Created:       2008-08-27
#
# Transport layer for EdgeExpressDB
#
package Bio::Das::ProServer::SourceAdaptor::Transport::edgeexpress;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);
use DBI;
use Carp;
use English qw(-no_match_vars);
use MQdb::Database;

our $VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

=head2 init

  Description: Subclass override of init() method. Reads the 'config' and initializes the
               database and transport layer
  Caller     : superclass (not public method)

=cut

sub init {
  my $self = shift;
  my $config   = $self->config();
  my $eeDB = MQdb::Database->new_from_url($config->{eedb_url});
  if($eeDB) {
    printf("MQdb::Database = %s\n", $eeDB->url); 
  } else {
    printf("ERROR configuring edgeexpress database connection [%s]\n", $config->{eedb_url});
  }
  $self->{'_eedb_database'} = $eeDB;
  return $self;
}

=head2 database

  Description: returns the Database object connected to the configured EdgeExpressDB
  Example    : from a SourceAdaptor subclass 
               $eeDB = $self->transport->database;
  Returntype : MQdb::Database object connected to EdgeExpressDB
  Exceptions : none
  Caller     : Bio::Das::ProServer::SourceAdaptor::edgeexpress class

=cut

sub database {
  my $self = shift;
  return $self->{'_eedb_database'};
}


1;

__END__

