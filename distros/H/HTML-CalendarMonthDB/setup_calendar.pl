#!/usr/bin/perl -w

use strict;

my($clientname, $dbname, $dbhost, $dbuser, $dbpass, $calname, $pubdir, $answer);

## get db info etc
$dbhost = getinput("Enter valid postgres host (leave blank for localhost): ");
$dbname = getinput("Enter valid postgres database name: ", 1);
$dbuser = getinput("Enter valid database username: ", 1);
$dbpass = getinput("Enter valid database password for user $dbuser: ");
$clientname = getinput("Enter client (person owning calendar) name: ", 1);
$calname = getinput("Enter calendar name: ", 1);
$pubdir = getinput("Enter directory to where you wish to publish static calendars: ", 1);

# make postgres setup sql script
makeSql();

# attempt to run sql script?
if (!$dbhost) {
	$answer = getinput("SQL script has been created and stored in ./calendar.sql.\nDo you wish to attempt to run this script now? <yes/no>: [yes]");
	if (($answer eq "yes") || ($answer eq "y") || !$answer) {
		runScript();
	} 
	else {
		print "*** Skipping attempt, please run this script (./calendar.sql) later in order to set up proper database tables.\n\n";
	} 
}
else {
	print "*** SQL script has been created and stored in ./calendar.sql.\nPlease run this later on the database host in order to set up the proper database tables.\n\n";
}

# print out env variables
printEnv();

exit(1);

###################################################################

sub printEnv {
	my $list = "SetEnv DB_NAME \"$dbname\"\nSetEnv DB_HOST \"$dbhost\"\nSetEnv DB_USER \"$dbuser\"\nSetEnv DB_PASS \"$dbpass\"\nSetEnv DB_CLIENT \"$clientname\"\nSetEnv DB_CALENDAR \"$calname\"\nSetEnv CAL_PUB_DIR \"$pubdir\"";
	open (FILE, ">./CAL_ENV.list");
	print FILE $list;
	close(FILE);
	print "The following is a list of environment variables which you either need to add to your webserver configuration, or edit the cgi scripts to include.  This list has also been printed to './CAL_ENV.list'.\n\n";
	print $list."\n\n";

}

sub runScript {
	my $psql = getinput("Please enter path to psql executable: [/usr/local/pgsql/bin/psql] ");
	
	$psql = '/usr/local/pgsql/bin/psql' if !$psql;

	print "\nRunning sql setup script, output below....\n\n";
	`$psql $dbname -U $dbuser < ./calendar.sql`;	
}


sub makeSql {
	open (FILE, ">./calendar.sql") || die("\nCannot open file ./calendar.sql for writing.  Please make sure you have the proper permissions to write into this directory.\n\n");
	
	print FILE '--
-- Selected TOC Entries:
--
\connect - '.$dbuser.'
--
-- TOC Entry ID 2 (OID 18851)
--
-- Name: client_clientid_seq Type: SEQUENCE Owner: '.$dbuser.'
--

CREATE SEQUENCE "client_clientid_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 8 (OID 18870)
--
-- Name: client Type: TABLE Owner: '.$dbuser.'
--

CREATE TABLE "client" (
        "clientid" integer DEFAULT nextval(\'"client_clientid_seq"\'::text) NOT NULL,
        "clientname" character varying(64) NOT NULL,
        Constraint "client_pkey" Primary Key ("clientid")
);

--
-- TOC Entry ID 4 (OID 18977)
--
-- Name: calendar_calendarid_seq Type: SEQUENCE Owner: '.$dbuser.'
--

CREATE SEQUENCE "calendar_calendarid_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 9 (OID 18996)
--
-- Name: calendar Type: TABLE Owner: '.$dbuser.'
--

CREATE TABLE "calendar" (
        "calendarid" integer DEFAULT nextval(\'"calendar_calendarid_seq"\'::text) NOT NULL,
        "clientid" integer NOT NULL,
        "name" character varying(64) NOT NULL,
        "border" integer,
        "width" character varying(8),
        "bgcolor" character varying(12),
        "weekdaycolor" character varying(12),
        "weekendcolor" character varying(12),
        "todaycolor" character varying(12),
        "weekdaybordercolor" character varying(12),
        "weekendbordercolor" character varying(12),
        "todaybordercolor" character varying(12),
        "contentcolor" character varying(12),
        "weekdaycontentcolor" character varying(12),
        "weekendcontentcolor" character varying(12),
        "todaycontentcolor" character varying(12),
        "headercolor" character varying(12),
        "weekdayheadercolor" character varying(12),
        "weekendheadercolor" character varying(12),
        "header" character varying(64),
        "cellalignment" character varying(12),
        "bordercolor" character varying(12),
        Constraint "calendar_pkey" Primary Key ("calendarid")
);

--
-- TOC Entry ID 6 (OID 19030)
--
-- Name: event_eventid_seq Type: SEQUENCE Owner: '.$dbuser.'
--

CREATE SEQUENCE "event_eventid_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1  cache 1 ;

--
-- TOC Entry ID 10 (OID 19049)
--
-- Name: event Type: TABLE Owner: '.$dbuser.'
--

CREATE TABLE "event" (
        "eventid" integer DEFAULT nextval(\'"event_eventid_seq"\'::text) NOT NULL,
        "eventtime" time,
        "calendarid" integer,
        "eventday" integer NOT NULL,
        "eventmonth" integer NOT NULL,
        "eventyear" integer NOT NULL,
        "eventname" character varying(128) NOT NULL,
        "eventdesc" text,
        "eventlink" character varying(128),
        Constraint "event_pkey" Primary Key ("eventid")
);

--
-- Data for TOC Entry ID 11 (OID 18870)
--
-- Name: client Type: TABLE DATA Owner: '.$dbuser.'
--


COPY "client"  FROM stdin;
1	'.$clientname.'
\.
--
-- Data for TOC Entry ID 12 (OID 18996)
--
-- Name: calendar Type: TABLE DATA Owner: '.$dbuser.'
--


COPY "calendar"  FROM stdin;
1	1	'.$calname.'
\.
--
-- TOC Entry ID 3 (OID 18851)
--
-- Name: client_clientid_seq Type: SEQUENCE SET Owner:
--

SELECT setval (\'"client_clientid_seq"\', 1, \'t\');

--
-- TOC Entry ID 5 (OID 18977)
--
-- Name: calendar_calendarid_seq Type: SEQUENCE SET Owner:
--

SELECT setval (\'"calendar_calendarid_seq"\', 1, \'t\');

--
-- TOC Entry ID 7 (OID 19030)
--
-- Name: event_eventid_seq Type: SEQUENCE SET Owner:
--

SELECT setval (\'"event_eventid_seq"\', 60, \'t\');
';

	close(FILE);
}

sub getinput {
	my ($question) = shift;
	my ($required) = shift;
	my($var) = '';
	if ($required) {
		while ($var eq '') {
			print $question;
			$var=<STDIN>;
			chop($var);
		}
	}
	else {
		print $question;
                $var=<STDIN>;
                chop($var);
	}
	return $var;
}
