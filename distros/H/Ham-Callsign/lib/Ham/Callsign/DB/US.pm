# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.
package Ham::Callsign::DB::US;

use Ham::Callsign::DB;
use Ham::Callsign;
our @ISA = qw(Ham::Callsign::DB);

use strict;

sub init {
    my ($self) = @_;
    # maybe use dbh to prepare a few things
}

sub do_load_data {
    my ($self, $place) = @_;
    $self->{'import_place'} = $place;
    $self->insert_stuff('HD', 50);
    $self->insert_stuff('EN', 27);
    $self->insert_stuff('AM', 18);
    $self->insert_stuff('VC', 6);
}

sub do_lookup {
    my ($self, $callsign) = @_;
    if (!$self->{'lookupvc'}) {
	$self->{'lookupvc'} = $self->{'dbh'}->prepare("
    select vc.callsign_requested as thecallsign, *
             from PUBACC_VC as vc
        left join PUBACC_HD as hd 
               on hd.unique_system_identifier = vc.unique_system_identifier
        left join PUBACC_EN as en
               on en.unique_system_identifier = vc.unique_system_identifier
        left join PUBACC_AM as am
               on am.unique_system_identifier = vc.unique_system_identifier
            where vc.callsign_requested = ?
        order by vc.unique_system_identifier desc
        limit 1
");
	$self->{'lookuphd'} = $self->{'dbh'}->prepare("
    select hd.call_sign as thecallsign, *
             from PUBACC_HD as hd
        left join PUBACC_VC as vc
               on vc.unique_system_identifier = hd.unique_system_identifier
        left join PUBACC_EN as en
               on en.unique_system_identifier = hd.unique_system_identifier
        left join PUBACC_AM as am
               on am.unique_system_identifier = hd.unique_system_identifier
            where hd.call_sign = ?
        order by hd.unique_system_identifier desc
        limit 1
");
    }

    $self->{'lookupvc'}->execute($callsign);
    my $row1 = $self->{'lookupvc'}->fetchrow_hashref;
    $self->{'lookupvc'}->finish;

    $self->{'lookuphd'}->execute($callsign);
    my $row2 = $self->{'lookuphd'}->fetchrow_hashref;
    $self->{'lookuphd'}->finish;

    my @results;
    if ($row1 && $row2 && !$self->{'USmultiple'}) {
	# take the most recent ULS file number
	if ($row1->{'uls_file_number'} > $row2->{'uls_file_number'}) {
	    $row2 = undef;
	} else {
	    $row1 = undef;
	}
    }
    if ($row1) {
	$row1->{'qth'} = "$row1->{city}, $row1->{state}, USA";
	push @results,new Ham::Callsign(%$row1)
    }
    if ($row2) {
	$row2->{'qth'} = "$row2->{city}, $row2->{state}, USA";
	push @results,new Ham::Callsign(%$row2) if ($row2);
    }
    map { $_->{'FromDB'} = 'US' } @results;
    return \@results;
}

# from fcc docs:
#  EN: Names and Addresses
#  HD: Main form 605 that carries over to license
#  AM: Amature data
#  VC: Vanity Callsign
#
# data can be joined "whenever the column name is the same in both tables"
#   - primary column for joining is the call sign
#   - joining for application data is the ULS file number (we don't load apps)
#   - Each application and license has been assigned a unique 9-digit system id
#     This is useful in cases where a call sign has been reassigned.
sub do_create_tables {
    my ($self) = @_;

    my $dbh = $self->{'dbh'};

    # These SQL statements were pulled from the FCC documentation at
    # http://wireless.fcc.gov/uls/index.htm?job=transaction&page=weekly

    # the FCC updates their schema on a regular basis and this module
    # will need to track those changes.

    $dbh->do("drop table PUBACC_EN");
    $dbh->do("create table PUBACC_EN
(
      record_type               char(2)              not null,
      unique_system_identifier  numeric(9,0)         not null,
      uls_file_number           char(14)             null,
      ebf_number                varchar(30)          null,
      call_sign                 char(10)             null,
      entity_type               char(2)              null,
      licensee_id               char(9)              null,
      entity_name               varchar(200)         null,
      first_name                varchar(20)          null,
      mi                        char(1)              null,
      last_name                 varchar(20)          null,
      suffix                    char(3)              null,
      phone                     char(10)             null,
      fax                       char(10)             null,
      email                     varchar(50)          null,
      street_address            varchar(60)          null,
      city                      varchar(20)          null,
      state                     char(2)              null,
      zip_code                  char(9)              null,
      po_box                    varchar(20)          null,
      attention_line            varchar(35)          null,
      sgin                      char(3)              null,
      frn                       char(10)             null,
      applicant_type_code       char(1)              null,
      applicant_type_other      char(40)             null,
      status_code               char(1)		     null,
      status_date		datetime	     null
)");

    $dbh->do("CREATE index callsign_index_en_id on PUBACC_EN(unique_system_identifier)");


    $dbh->do("drop table PUBACC_AM");
    $dbh->do("create table PUBACC_AM
(
      record_type               char(2)              not null,
      unique_system_identifier  numeric(9,0)         not null,
      uls_file_num              char(14)             null,
      ebf_number                varchar(30)          null,
      callsign                  char(10)             null,
      operator_class            char(1)              null,
      group_code                char(1)              null,
      region_code               tinyint          null,
      trustee_callsign          char(10)             null,
      trustee_indicator         char(1)              null,
      physician_certification   char(1)              null,
      ve_signature              char(1)              null,
      systematic_callsign_change char(1)             null,
      vanity_callsign_change    char(1)              null,
      vanity_relationship       char(12)             null,
      previous_callsign         char(10)             null,
      previous_operator_class   char(1)              null,
      trustee_name              varchar(50)          null
)
");

    $dbh->do("CREATE index callsign_index_am_id on PUBACC_AM(unique_system_identifier)");


    $dbh->do("drop table PUBACC_HD");
    $dbh->do("create table PUBACC_HD
(
      record_type               char(2)              not null,
      unique_system_identifier  numeric(9,0)         not null,
      uls_file_number           char(14)             null,
      ebf_number                varchar(30)          null,
      call_sign                 char(10)             null,
      license_status            char(1)              null,
      radio_service_code        char(2)              null,
      grant_date                char(10)             null,
      expired_date              char(10)             null,
      cancellation_date         char(10)             null,
      eligibility_rule_num      char(10)             null,
      applicant_type_code_reserved       char(1)              null,
      alien                     char(1)              null,
      alien_government          char(1)              null,
      alien_corporation         char(1)              null,
      alien_officer             char(1)              null,
      alien_control             char(1)              null,
      revoked                   char(1)              null,
      convicted                 char(1)              null,
      adjudged                  char(1)              null,
      involved_reserved      char(1)              null,
      common_carrier            char(1)              null,
      non_common_carrier        char(1)              null,
      private_comm              char(1)              null,
      fixed                     char(1)              null,
       mobile                    char(1)              null,
      radiolocation             char(1)              null,
      satellite                 char(1)              null,
      developmental_or_sta      char(1)              null,
      interconnected_service    char(1)              null,
      certifier_first_name      varchar(20)          null,
      certifier_mi              char(1)              null,
      certifier_last_name       varchar(20)          null,
      certifier_suffix          char(3)              null,
      certifier_title           char(40)             null,
      gender                    char(1)              null,
      african_american          char(1)              null,
      native_american           char(1)              null,
      hawaiian                  char(1)              null,
      asian                     char(1)              null,
      white                     char(1)              null,
      ethnicity                 char(1)              null,
      effective_date            char(10)             null,
      last_action_date          char(10)             null,
      auction_id                int              null,
      reg_stat_broad_serv       char(1)              null,
      band_manager              char(1)              null,
      type_serv_broad_serv      char(1)              null,
	alien_ruling              char(1)              null,
      licensee_name_change	char(1)		     null
)");

    $dbh->do("CREATE index callsign_index_hd_id on PUBACC_HD(unique_system_identifier)");
    $dbh->do("CREATE index callsign_index_HD_SIGN on PUBACC_HD(call_sign)");

    $dbh->do("drop table PUBACC_VC");
    $dbh->do("create table PUBACC_VC
(


      record_type               char(2)              null,
      unique_system_identifier  numeric(9,0)         not null,
      uls_file_number           char(14)             null,
      ebf_number                varchar(30)          null,
      request_sequence          int              null,
      callsign_requested        char(10)             null
)
");

    $dbh->do("CREATE index callsign_index_VC_SIGN on PUBACC_VC(callsign_requested)");
    $dbh->do("CREATE index callsign_index_vc_id on PUBACC_VC(unique_system_identifier)");
}

########################################
# DB insertion code
#

# split doesn't always return the right number of entries...  it
# chomps the end for some reason sometimes.  This array fills in the blanks.
#
# XXX: this is likely a problem for some other reason and this is a
# possibly broken hack.
my @fill;

for (my $i = 1; $i <= 100; $i++) {
  for (my $j = 0; $j < $i; $j++) {
    push @{$fill[$i]}, '';
  }
}

# a generic function that inserts $num rows into a table
sub insert_stuff {
    my ($self, $suffix, $num) = @_;

    my $count = 0;
    my @parts;

    my $dbh = $self->{'dbh'};

    my $sth = $dbh->prepare("insert into PUBACC_$suffix values(" .
			    ("?, " x ($num-1)). " ?)");

    $| = 1;
    print "starting $suffix\n";
    open(I,"<$self->{'import_place'}/$suffix.dat");
    $dbh->begin_work();
    while (<I>) {
	chomp;
	s/\r//;
	@parts = split(/\|/);
#	print "parts: $_\n  " . join(",",@parts). "\n" if ($count == 0);
 	my $diff = $num - $#parts - 1;
 	$sth->execute(@parts, @{$fill[$diff]});
#	$sth->execute(@parts);
	$count++;
	if ($count % 10000 == 0) {
	    print ".";
	    $dbh->commit();
	    $dbh->begin_work();
	}
    }
    $dbh->commit();

    print "inserted: $count rows into $suffix\n";
}


1;

=pod

=head1 NAME

=cut


