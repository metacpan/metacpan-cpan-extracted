# this might live in /path/to/checkout/.re.pl/project.rc
# see: http://chainsawblues.vox.com/library/post/develrepl-part-4---script-options-rc-files-profiles-and-packaging.html

# load my global ~/.re.pl/repl.rc
Devel::REPL::Script->current->load_rcfile('repl.rc');

use lib 'lib'; # to get at the lib/Project.pm, lib/Project/* perl modules
use Project::Schema; # load the DBIC schema

Project::Schema->connection('dbi:Pg:dbname=project_matthewt_test','matthewt',''); # connect to db
Project::Schema->stacktrace(1); # turn on stack traces for DBI errors

sub schema { 'Project::Schema' } # shortcut so things like schema->sources works
sub rs { Project::Schema->resultset(shift); } # shortcut so rs('Foo')->find(1); works
sub cols { Project::Schema->source(shift)->columns; } # cols('Foo') returns a column list

