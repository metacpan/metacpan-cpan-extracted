# make sure we load before threads.pm
require Devel::GlobalPhase;

require './t/threads.t';
