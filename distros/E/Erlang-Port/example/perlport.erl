% -----------------------------------------------------------------------------
% perlport.erl
% -----------------------------------------------------------------------------
% Mastering programmed by YAMASHINA Hio
%
% Copyright 2007 YAMASHINA Hio
% -----------------------------------------------------------------------------
% $Id
% -----------------------------------------------------------------------------
-module(perlport).
-export([start/0, start/1, start/2, call/1, call/2, stop/0, stop/1, test/0]).

% -----------------------------------------------------------------------------
% test().
%
test() ->
	start()
	, io:format("~p~n", [call(1)])
	, io:format("~p~n", [call(atom)])
	, io:format("~p~n", [call("text")])
	, io:format("~p~n", [call([])])
	, io:format("~p~n", [call([1,2,3])])
	, io:format("~p~n", [call([<<"bin">>])])
	, io:format("~p~n", [call(list_to_tuple(lists:seq(1,300)))])
	, io:format("~p~n", [call(1.23)])
	, io:format("~p (self=~p)~n", [call(self()), self()])
	.

% -----------------------------------------------------------------------------
% call(Msg).
%
call(Msg) ->
	call(Msg, perlport).
call(Msg, PortName) ->
	case whereis(PortName) of
	undefined -> undefined;
	Port -> 
		Port ! { self(), { command, term_to_binary(Msg) } },
		receive
			{Port, {data, Any}} -> binary_to_term(Any)
		end
	end.

% -----------------------------------------------------------------------------
% start(). % ./perlport.pl, perlport.
% start(Script).
% start(Script, PortName).
%
start() ->
	start("./perlport.pl").
start(Script) ->
	start(Script, perlport).
start(Script, PortName) ->
	start(Script, PortName, whereis(PortName)).
start(Script, PortName, undefined) ->
	% Script:   "./perlport.pl".
	% PortName: perlport
	Pid = open_port({spawn, Script},[{packet,2}, binary]),
	register(PortName,Pid),
	Pid;
start(_Script, _PortName, Pid) ->
	Pid.

% -----------------------------------------------------------------------------
% stop().
%
stop() ->
	stop(perlport).
stop(PortName) ->
	case whereis(PortName) of
	undefined -> ok;
	Port -> Port ! { self(), close }
	end.

% -----------------------------------------------------------------------------
% End of Module.
% -----------------------------------------------------------------------------
