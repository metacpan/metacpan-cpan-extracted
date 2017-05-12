#!bin/jspl

require('DBI', 'DBI');
require('POSIX', 'POSIX', -1);

var drivers = DBI.available_drivers();

say("You have the following DBI drivers available:");
for(var i = 0; i < drivers.length; i++)
    say("\t[" + (i+1) + "] " + drivers[i]);

if(drivers.indexOf('SQLite')) {
    say("Lets test SQLite");
    try {
	var name = POSIX.tmpnam(),
	    dbh = DBI.connect(
	    'dbi:SQLite:dbname='+name, '', '', { 
		RaiseError: true,
		PrintError: false
	});
	say("Database ", name, " created");

	dbh.do("create table colors(name text primary key, feeling text)");

	dbh.do("insert into colors values ('green', 'happy')");
	dbh.do("insert into colors values ('black', 'sad')");

	var all_colors = dbh.selectall_hashref('select * from colors', 'name');
	for(var color in all_colors) {
	    say(color + ' is a ' + all_colors[color].feeling + ' color');
	}
	Sys.unlink(name);
	say('Removed.');
    } catch(e) {
	warn("Ups, something fails: ", e);
    }
}
else {
    say("Sad, you don't have SQLite DBD available.");
}
say("Thats all folks.");
