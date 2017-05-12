#!/usr/bin/env perl -w

use strict;
use warnings;

use Erlang::Parser;

use Test::Simple tests => 5;

my $data = do { local $/; <DATA> };
my @nodes = Erlang::Parser->parse($data);

ok( @nodes,		'the test data should parse' );

open my $fh, ">", \my $pp;
$_->print($fh) for (@nodes);
close $fh;

ok( $pp,		'the test data should pretty-print' );

my @pp_nodes = Erlang::Parser->parse($pp);

ok( @pp_nodes,		'the pretty-printed test data should parse' );

open my $fh2, ">", \my $pp2;
$_->print($fh2) for (@pp_nodes);
close $fh2;

ok( $pp2,		'the parsed pretty-printed test data should pretty-print' );

ok( $pp eq $pp2,	'the pretty-printed test data should equal the pretty-printed parsed pretty-printed test data' );

__END__

%% The below code used to test Erlang::Parser comes from mochiweb.
%% I sourced it from github.com/mochi/mochiweb on October 11th, 2011.
%% It's revision 57f6d12edc3aaaaf8e6bac9b6a9c1d89dae784ba.
%% mochiweb's COPYING follows:

%% This is the MIT license.
%% 
%% Copyright (c) 2007 Mochi Media, Inc.
%% 
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights to
%% use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
%% of the Software, and to permit persons to whom the Software is furnished to do
%% so, subject to the following conditions:
%% 
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%% SOFTWARE.


%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2008 Mochi Media, Inc.

%% @doc String Formatting for Erlang, inspired by Python 2.6
%%      (<a href="http://www.python.org/dev/peps/pep-3101/">PEP 3101</a>).
%%
-module(mochifmt).
-author('bob@mochimedia.com').
-export([format/2, format_field/2, convert_field/2, get_value/2, get_field/2]).
-export([tokenize/1, format/3, get_field/3, format_field/3]).
-export([bformat/2, bformat/3]).
-export([f/2, f/3]).

-record(conversion, {length, precision, ctype, align, fill_char, sign}).

%% @spec tokenize(S::string()) -> tokens()
%% @doc Tokenize a format string into mochifmt's internal format.
tokenize(S) ->
    {?MODULE, tokenize(S, "", [])}.

%% @spec convert_field(Arg, Conversion::conversion()) -> term()
%% @doc Process Arg according to the given explicit conversion specifier.
convert_field(Arg, "") ->
    Arg;
convert_field(Arg, "r") ->
    repr(Arg);
convert_field(Arg, "s") ->
    str(Arg).

%% @spec get_value(Key::string(), Args::args()) -> term()
%% @doc Get the Key from Args. If Args is a tuple then convert Key to
%%      an integer and get element(1 + Key, Args). If Args is a list and Key
%%      can be parsed as an integer then use lists:nth(1 + Key, Args),
%%      otherwise try and look for Key in Args as a proplist, converting
%%      Key to an atom or binary if necessary.
get_value(Key, Args) when is_tuple(Args) ->
    element(1 + list_to_integer(Key), Args);
get_value(Key, Args) when is_list(Args) ->
    try lists:nth(1 + list_to_integer(Key), Args)
    catch error:_ ->
            {_K, V} = proplist_lookup(Key, Args),
            V
    end.

%% @spec get_field(Key::string(), Args) -> term()
%% @doc Consecutively call get_value/2 on parts of Key delimited by ".",
%%      replacing Args with the result of the previous get_value. This
%%      is used to implement formats such as {0.0}.
get_field(Key, Args) ->
    get_field(Key, Args, ?MODULE).

%% @spec get_field(Key::string(), Args, Module) -> term()
%% @doc Consecutively call Module:get_value/2 on parts of Key delimited by ".",
%%      replacing Args with the result of the previous get_value. This
%%      is used to implement formats such as {0.0}.
get_field(Key, Args, Module) ->
    {Name, Next} = lists:splitwith(fun (C) -> C =/= $. end, Key),
    Res = try Module:get_value(Name, Args)
          catch error:undef -> get_value(Name, Args) end,
    case Next of
        "" ->
            Res;
        "." ++ S1 ->
            get_field(S1, Res, Module)
    end.

%% @spec format(Format::string(), Args) -> iolist()
%% @doc Format Args with Format.
format(Format, Args) ->
    format(Format, Args, ?MODULE).

%% @spec format(Format::string(), Args, Module) -> iolist()
%% @doc Format Args with Format using Module.
format({?MODULE, Parts}, Args, Module) ->
    format2(Parts, Args, Module, []);
format(S, Args, Module) ->
    format(tokenize(S), Args, Module).

%% @spec format_field(Arg, Format) -> iolist()
%% @doc Format Arg with Format.
format_field(Arg, Format) ->
    format_field(Arg, Format, ?MODULE).

%% @spec format_field(Arg, Format, _Module) -> iolist()
%% @doc Format Arg with Format.
format_field(Arg, Format, _Module) ->
    F = default_ctype(Arg, parse_std_conversion(Format)),
    fix_padding(fix_sign(convert2(Arg, F), F), F).

%% @spec f(Format::string(), Args) -> string()
%% @doc Format Args with Format and return a string().
f(Format, Args) ->
    f(Format, Args, ?MODULE).

%% @spec f(Format::string(), Args, Module) -> string()
%% @doc Format Args with Format using Module and return a string().
f(Format, Args, Module) ->
    case lists:member(${, Format) of
        true ->
            binary_to_list(bformat(Format, Args, Module));
        false ->
            Format
    end.

%% @spec bformat(Format::string(), Args) -> binary()
%% @doc Format Args with Format and return a binary().
bformat(Format, Args) ->
    iolist_to_binary(format(Format, Args)).

%% @spec bformat(Format::string(), Args, Module) -> binary()
%% @doc Format Args with Format using Module and return a binary().
bformat(Format, Args, Module) ->
    iolist_to_binary(format(Format, Args, Module)).

%% Internal API

add_raw("", Acc) ->
    Acc;
add_raw(S, Acc) ->
    [{raw, lists:reverse(S)} | Acc].

tokenize([], S, Acc) ->
    lists:reverse(add_raw(S, Acc));
tokenize("{{" ++ Rest, S, Acc) ->
    tokenize(Rest, "{" ++ S, Acc);
tokenize("{" ++ Rest, S, Acc) ->
    {Format, Rest1} = tokenize_format(Rest),
    tokenize(Rest1, "", [{format, make_format(Format)} | add_raw(S, Acc)]);
tokenize("}}" ++ Rest, S, Acc) ->
    tokenize(Rest, "}" ++ S, Acc);
tokenize([C | Rest], S, Acc) ->
    tokenize(Rest, [C | S], Acc).

tokenize_format(S) ->
    tokenize_format(S, 1, []).

tokenize_format("}" ++ Rest, 1, Acc) ->
    {lists:reverse(Acc), Rest};
tokenize_format("}" ++ Rest, N, Acc) ->
    tokenize_format(Rest, N - 1, "}" ++ Acc);
tokenize_format("{" ++ Rest, N, Acc) ->
    tokenize_format(Rest, 1 + N, "{" ++ Acc);
tokenize_format([C | Rest], N, Acc) ->
    tokenize_format(Rest, N, [C | Acc]).

make_format(S) ->
    {Name0, Spec} = case lists:splitwith(fun (C) -> C =/= $: end, S) of
                        {_, ""} ->
                            {S, ""};
                        {SN, ":" ++ SS} ->
                            {SN, SS}
                    end,
    {Name, Transform} = case lists:splitwith(fun (C) -> C =/= $! end, Name0) of
                            {_, ""} ->
                                {Name0, ""};
                            {TN, "!" ++ TT} ->
                                {TN, TT}
                        end,
    {Name, Transform, Spec}.

proplist_lookup(S, P) ->
    A = try list_to_existing_atom(S)
        catch error:_ -> make_ref() end,
    B = try list_to_binary(S)
        catch error:_ -> make_ref() end,
    proplist_lookup2({S, A, B}, P).

proplist_lookup2({KS, KA, KB}, [{K, V} | _])
  when KS =:= K orelse KA =:= K orelse KB =:= K ->
    {K, V};
proplist_lookup2(Keys, [_ | Rest]) ->
    proplist_lookup2(Keys, Rest).

format2([], _Args, _Module, Acc) ->
    lists:reverse(Acc);
format2([{raw, S} | Rest], Args, Module, Acc) ->
    format2(Rest, Args, Module, [S | Acc]);
format2([{format, {Key, Convert, Format0}} | Rest], Args, Module, Acc) ->
    Format = f(Format0, Args, Module),
    V = case Module of
            ?MODULE ->
                V0 = get_field(Key, Args),
                V1 = convert_field(V0, Convert),
                format_field(V1, Format);
            _ ->
                V0 = try Module:get_field(Key, Args)
                     catch error:undef -> get_field(Key, Args, Module) end,
                V1 = try Module:convert_field(V0, Convert)
                     catch error:undef -> convert_field(V0, Convert) end,
                try Module:format_field(V1, Format)
                catch error:undef -> format_field(V1, Format, Module) end
        end,
    format2(Rest, Args, Module, [V | Acc]).

default_ctype(_Arg, C=#conversion{ctype=N}) when N =/= undefined ->
    C;
default_ctype(Arg, C) when is_integer(Arg) ->
    C#conversion{ctype=decimal};
default_ctype(Arg, C) when is_float(Arg) ->
    C#conversion{ctype=general};
default_ctype(_Arg, C) ->
    C#conversion{ctype=string}.

fix_padding(Arg, #conversion{length=undefined}) ->
    Arg;
fix_padding(Arg, F=#conversion{length=Length, fill_char=Fill0, align=Align0,
                               ctype=Type}) ->
    Padding = Length - iolist_size(Arg),
    Fill = case Fill0 of
               undefined ->
                   $\s;
               _ ->
                   Fill0
           end,
    Align = case Align0 of
                undefined ->
                    case Type of
                        string ->
                            left;
                        _ ->
                            right
                    end;
                _ ->
                    Align0
            end,
    case Padding > 0 of
        true ->
            do_padding(Arg, Padding, Fill, Align, F);
        false ->
            Arg
    end.

do_padding(Arg, Padding, Fill, right, _F) ->
    [lists:duplicate(Padding, Fill), Arg];
do_padding(Arg, Padding, Fill, center, _F) ->
    LPadding = lists:duplicate(Padding div 2, Fill),
    RPadding = case Padding band 1 of
                   1 ->
                       [Fill | LPadding];
                   _ ->
                       LPadding
               end,
    [LPadding, Arg, RPadding];
do_padding([$- | Arg], Padding, Fill, sign_right, _F) ->
    [[$- | lists:duplicate(Padding, Fill)], Arg];
do_padding(Arg, Padding, Fill, sign_right, #conversion{sign=$-}) ->
    [lists:duplicate(Padding, Fill), Arg];
do_padding([S | Arg], Padding, Fill, sign_right, #conversion{sign=S}) ->
    [[S | lists:duplicate(Padding, Fill)], Arg];
do_padding(Arg, Padding, Fill, sign_right, #conversion{sign=undefined}) ->
    [lists:duplicate(Padding, Fill), Arg];
do_padding(Arg, Padding, Fill, left, _F) ->
    [Arg | lists:duplicate(Padding, Fill)].

fix_sign(Arg, #conversion{sign=$+}) when Arg >= 0 ->
    [$+, Arg];
fix_sign(Arg, #conversion{sign=$\s}) when Arg >= 0 ->
    [$\s, Arg];
fix_sign(Arg, _F) ->
    Arg.

ctype($\%) -> percent;
ctype($s) -> string;
ctype($b) -> bin;
ctype($o) -> oct;
ctype($X) -> upper_hex;
ctype($x) -> hex;
ctype($c) -> char;
ctype($d) -> decimal;
ctype($g) -> general;
ctype($f) -> fixed;
ctype($e) -> exp.

align($<) -> left;
align($>) -> right;
align($^) -> center;
align($=) -> sign_right.

convert2(Arg, F=#conversion{ctype=percent}) ->
    [convert2(100.0 * Arg, F#conversion{ctype=fixed}), $\%];
convert2(Arg, #conversion{ctype=string}) ->
    str(Arg);
convert2(Arg, #conversion{ctype=bin}) ->
    erlang:integer_to_list(Arg, 2);
convert2(Arg, #conversion{ctype=oct}) ->
    erlang:integer_to_list(Arg, 8);
convert2(Arg, #conversion{ctype=upper_hex}) ->
    erlang:integer_to_list(Arg, 16);
convert2(Arg, #conversion{ctype=hex}) ->
    string:to_lower(erlang:integer_to_list(Arg, 16));
convert2(Arg, #conversion{ctype=char}) when Arg < 16#80 ->
    [Arg];
convert2(Arg, #conversion{ctype=char}) ->
    xmerl_ucs:to_utf8(Arg);
convert2(Arg, #conversion{ctype=decimal}) ->
    integer_to_list(Arg);
convert2(Arg, #conversion{ctype=general, precision=undefined}) ->
    try mochinum:digits(Arg)
    catch error:undef -> io_lib:format("~g", [Arg]) end;
convert2(Arg, #conversion{ctype=fixed, precision=undefined}) ->
    io_lib:format("~f", [Arg]);
convert2(Arg, #conversion{ctype=exp, precision=undefined}) ->
    io_lib:format("~e", [Arg]);
convert2(Arg, #conversion{ctype=general, precision=P}) ->
    io_lib:format("~." ++ integer_to_list(P) ++ "g", [Arg]);
convert2(Arg, #conversion{ctype=fixed, precision=P}) ->
    io_lib:format("~." ++ integer_to_list(P) ++ "f", [Arg]);
convert2(Arg, #conversion{ctype=exp, precision=P}) ->
    io_lib:format("~." ++ integer_to_list(P) ++ "e", [Arg]).

str(A) when is_atom(A) ->
    atom_to_list(A);
str(I) when is_integer(I) ->
    integer_to_list(I);
str(F) when is_float(F) ->
    try mochinum:digits(F)
    catch error:undef -> io_lib:format("~g", [F]) end;
str(L) when is_list(L) ->
    L;
str(B) when is_binary(B) ->
    B;
str(P) ->
    repr(P).

repr(P) when is_float(P) ->
    try mochinum:digits(P)
    catch error:undef -> float_to_list(P) end;
repr(P) ->
    io_lib:format("~p", [P]).

parse_std_conversion(S) ->
    parse_std_conversion(S, #conversion{}).

parse_std_conversion("", Acc) ->
    Acc;
parse_std_conversion([Fill, Align | Spec], Acc)
  when Align =:= $< orelse Align =:= $> orelse Align =:= $= orelse Align =:= $^ ->
    parse_std_conversion(Spec, Acc#conversion{fill_char=Fill,
                                              align=align(Align)});
parse_std_conversion([Align | Spec], Acc)
  when Align =:= $< orelse Align =:= $> orelse Align =:= $= orelse Align =:= $^ ->
    parse_std_conversion(Spec, Acc#conversion{align=align(Align)});
parse_std_conversion([Sign | Spec], Acc)
  when Sign =:= $+ orelse Sign =:= $- orelse Sign =:= $\s ->
    parse_std_conversion(Spec, Acc#conversion{sign=Sign});
parse_std_conversion("0" ++ Spec, Acc) ->
    Align = case Acc#conversion.align of
                undefined ->
                    sign_right;
                A ->
                    A
            end,
    parse_std_conversion(Spec, Acc#conversion{fill_char=$0, align=Align});
parse_std_conversion(Spec=[D|_], Acc) when D >= $0 andalso D =< $9 ->
    {W, Spec1} = lists:splitwith(fun (C) -> C >= $0 andalso C =< $9 end, Spec),
    parse_std_conversion(Spec1, Acc#conversion{length=list_to_integer(W)});
parse_std_conversion([$. | Spec], Acc) ->
    case lists:splitwith(fun (C) -> C >= $0 andalso C =< $9 end, Spec) of
        {"", Spec1} ->
            parse_std_conversion(Spec1, Acc);
        {P, Spec1} ->
            parse_std_conversion(Spec1,
                                 Acc#conversion{precision=list_to_integer(P)})
    end;
parse_std_conversion([Type], Acc) ->
    parse_std_conversion("", Acc#conversion{ctype=ctype(Type)}).


%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

tokenize_test() ->
    {?MODULE, [{raw, "ABC"}]} = tokenize("ABC"),
    {?MODULE, [{format, {"0", "", ""}}]} = tokenize("{0}"),
    {?MODULE, [{raw, "ABC"}, {format, {"1", "", ""}}, {raw, "DEF"}]} =
        tokenize("ABC{1}DEF"),
    ok.

format_test() ->
    <<"  -4">> = bformat("{0:4}", [-4]),
    <<"   4">> = bformat("{0:4}", [4]),
    <<"   4">> = bformat("{0:{0}}", [4]),
    <<"4   ">> = bformat("{0:4}", ["4"]),
    <<"4   ">> = bformat("{0:{0}}", ["4"]),
    <<"1.2yoDEF">> = bformat("{2}{0}{1}{3}", {yo, "DE", 1.2, <<"F">>}),
    <<"cafebabe">> = bformat("{0:x}", {16#cafebabe}),
    <<"CAFEBABE">> = bformat("{0:X}", {16#cafebabe}),
    <<"CAFEBABE">> = bformat("{0:X}", {16#cafebabe}),
    <<"755">> = bformat("{0:o}", {8#755}),
    <<"a">> = bformat("{0:c}", {97}),
    %% Horizontal ellipsis
    <<226, 128, 166>> = bformat("{0:c}", {16#2026}),
    <<"11">> = bformat("{0:b}", {3}),
    <<"11">> = bformat("{0:b}", [3]),
    <<"11">> = bformat("{three:b}", [{three, 3}]),
    <<"11">> = bformat("{three:b}", [{"three", 3}]),
    <<"11">> = bformat("{three:b}", [{<<"three">>, 3}]),
    <<"\"foo\"">> = bformat("{0!r}", {"foo"}),
    <<"2008-5-4">> = bformat("{0.0}-{0.1}-{0.2}", {{2008,5,4}}),
    <<"2008-05-04">> = bformat("{0.0:04}-{0.1:02}-{0.2:02}", {{2008,5,4}}),
    <<"foo6bar-6">> = bformat("foo{1}{0}-{1}", {bar, 6}),
    <<"-'atom test'-">> = bformat("-{arg!r}-", [{arg, 'atom test'}]),
    <<"2008-05-04">> = bformat("{0.0:0{1.0}}-{0.1:0{1.1}}-{0.2:0{1.2}}",
                               {{2008,5,4}, {4, 2, 2}}),
    ok.

std_test() ->
    M = mochifmt_std:new(),
    <<"01">> = bformat("{0}{1}", [0, 1], M),
    ok.

records_test() ->
    M = mochifmt_records:new([{conversion, record_info(fields, conversion)}]),
    R = #conversion{length=long, precision=hard, sign=peace},
    long = M:get_value("length", R),
    hard = M:get_value("precision", R),
    peace = M:get_value("sign", R),
    <<"long hard">> = bformat("{length} {precision}", R, M),
    <<"long hard">> = bformat("{0.length} {0.precision}", [R], M),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2008 Mochi Media, Inc.

%% @doc Formatter that understands records.
%%
%% Usage:
%%
%%    1> M = mochifmt_records:new([{rec, record_info(fields, rec)}]),
%%    M:format("{0.bar}", [#rec{bar=foo}]).
%%    foo

-module(mochifmt_records, [Recs]).
-author('bob@mochimedia.com').
-export([get_value/2]).

get_value(Key, Rec) when is_tuple(Rec) and is_atom(element(1, Rec)) ->
    try begin
            Atom = list_to_existing_atom(Key),
            {_, Fields} = proplists:lookup(element(1, Rec), Recs),
            element(get_rec_index(Atom, Fields, 2), Rec)
        end
    catch error:_ -> mochifmt:get_value(Key, Rec)
    end;
get_value(Key, Args) ->
    mochifmt:get_value(Key, Args).

get_rec_index(Atom, [Atom | _], Index) ->
    Index;
get_rec_index(Atom, [_ | Rest], Index) ->
    get_rec_index(Atom, Rest, 1 + Index).


%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2008 Mochi Media, Inc.

%% @doc Template module for a mochifmt formatter.

-module(mochifmt_std, []).
-author('bob@mochimedia.com').
-export([format/2, get_value/2, format_field/2, get_field/2, convert_field/2]).

format(Format, Args) ->
    mochifmt:format(Format, Args, THIS).

get_field(Key, Args) ->
    mochifmt:get_field(Key, Args, THIS).

convert_field(Key, Args) ->
    mochifmt:convert_field(Key, Args).

get_value(Key, Args) ->
    mochifmt:get_value(Key, Args).

format_field(Arg, Format) ->
    mochifmt:format_field(Arg, Format, THIS).

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2010 Mochi Media, Inc.
%% @doc Abuse module constant pools as a "read-only shared heap" (since erts 5.6)
%%      <a href="http://www.erlang.org/pipermail/erlang-questions/2009-March/042503.html">[1]</a>.
-module(mochiglobal).
-author("Bob Ippolito <bob@mochimedia.com>").
-export([get/1, get/2, put/2, delete/1]).

-spec get(atom()) -> any() | undefined.
%% @equiv get(K, undefined)
get(K) ->
    get(K, undefined).

-spec get(atom(), T) -> any() | T.
%% @doc Get the term for K or return Default.
get(K, Default) ->
    get(K, Default, key_to_module(K)).

get(_K, Default, Mod) ->
    try Mod:term()
    catch error:undef ->
            Default
    end.

-spec put(atom(), any()) -> ok.
%% @doc Store term V at K, replaces an existing term if present.
put(K, V) ->
    put(K, V, key_to_module(K)).

put(_K, V, Mod) ->
    Bin = compile(Mod, V),
    code:purge(Mod),
    {module, Mod} = code:load_binary(Mod, atom_to_list(Mod) ++ ".erl", Bin),
    ok.

-spec delete(atom()) -> boolean().
%% @doc Delete term stored at K, no-op if non-existent.
delete(K) ->
    delete(K, key_to_module(K)).

delete(_K, Mod) ->
    code:purge(Mod),
    code:delete(Mod).

-spec key_to_module(atom()) -> atom().
key_to_module(K) ->
    list_to_atom("mochiglobal:" ++ atom_to_list(K)).

-spec compile(atom(), any()) -> binary().
compile(Module, T) ->
    {ok, Module, Bin} = compile:forms(forms(Module, T),
                                      [verbose, report_errors]),
    Bin.

-spec forms(atom(), any()) -> [erl_syntax:syntaxTree()].
forms(Module, T) ->
    [erl_syntax:revert(X) || X <- term_to_abstract(Module, term, T)].

-spec term_to_abstract(atom(), atom(), any()) -> [erl_syntax:syntaxTree()].
term_to_abstract(Module, Getter, T) ->
    [%% -module(Module).
     erl_syntax:attribute(
       erl_syntax:atom(module),
       [erl_syntax:atom(Module)]),
     %% -export([Getter/0]).
     erl_syntax:attribute(
       erl_syntax:atom(export),
       [erl_syntax:list(
         [erl_syntax:arity_qualifier(
            erl_syntax:atom(Getter),
            erl_syntax:integer(0))])]),
     %% Getter() -> T.
     erl_syntax:function(
       erl_syntax:atom(Getter),
       [erl_syntax:clause([], none, [erl_syntax:abstract(T)])])].

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
get_put_delete_test() ->
    K = '$$test$$mochiglobal',
    delete(K),
    ?assertEqual(
       bar,
       get(K, bar)),
    try
        ?MODULE:put(K, baz),
        ?assertEqual(
           baz,
           get(K, bar)),
        ?MODULE:put(K, wibble),
        ?assertEqual(
           wibble,
           ?MODULE:get(K))
    after
        delete(K)
    end,
    ?assertEqual(
       bar,
       get(K, bar)),
    ?assertEqual(
       undefined,
       ?MODULE:get(K)),
    ok.
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2006 Mochi Media, Inc.

%% @doc Utilities for working with hexadecimal strings.

-module(mochihex).
-author('bob@mochimedia.com').

-export([to_hex/1, to_bin/1, to_int/1, dehex/1, hexdigit/1]).

%% @type iolist() = [char() | binary() | iolist()]
%% @type iodata() = iolist() | binary()

%% @spec to_hex(integer | iolist()) -> string()
%% @doc Convert an iolist to a hexadecimal string.
to_hex(0) ->
    "0";
to_hex(I) when is_integer(I), I > 0 ->
    to_hex_int(I, []);
to_hex(B) ->
    to_hex(iolist_to_binary(B), []).

%% @spec to_bin(string()) -> binary()
%% @doc Convert a hexadecimal string to a binary.
to_bin(L) ->
    to_bin(L, []).

%% @spec to_int(string()) -> integer()
%% @doc Convert a hexadecimal string to an integer.
to_int(L) ->
    erlang:list_to_integer(L, 16).

%% @spec dehex(char()) -> integer()
%% @doc Convert a hex digit to its integer value.
dehex(C) when C >= $0, C =< $9 ->
    C - $0;
dehex(C) when C >= $a, C =< $f ->
    C - $a + 10;
dehex(C) when C >= $A, C =< $F ->
    C - $A + 10.

%% @spec hexdigit(integer()) -> char()
%% @doc Convert an integer less than 16 to a hex digit.
hexdigit(C) when C >= 0, C =< 9 ->
    C + $0;
hexdigit(C) when C =< 15 ->
    C + $a - 10.

%% Internal API

to_hex(<<>>, Acc) ->
    lists:reverse(Acc);
to_hex(<<C1:4, C2:4, Rest/binary>>, Acc) ->
    to_hex(Rest, [hexdigit(C2), hexdigit(C1) | Acc]).

to_hex_int(0, Acc) ->
    Acc;
to_hex_int(I, Acc) ->
    to_hex_int(I bsr 4, [hexdigit(I band 15) | Acc]).

to_bin([], Acc) ->
    iolist_to_binary(lists:reverse(Acc));
to_bin([C1, C2 | Rest], Acc) ->
    to_bin(Rest, [(dehex(C1) bsl 4) bor dehex(C2) | Acc]).



%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

to_hex_test() ->
    "ff000ff1" = to_hex([255, 0, 15, 241]),
    "ff000ff1" = to_hex(16#ff000ff1),
    "0" = to_hex(16#0),
    ok.

to_bin_test() ->
    <<255, 0, 15, 241>> = to_bin("ff000ff1"),
    <<255, 0, 10, 161>> = to_bin("Ff000aA1"),
    ok.

to_int_test() ->
    16#ff000ff1 = to_int("ff000ff1"),
    16#ff000aa1 = to_int("FF000Aa1"),
    16#0 = to_int("0"),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Yet another JSON (RFC 4627) library for Erlang. mochijson2 works
%%      with binaries as strings, arrays as lists (without an {array, _})
%%      wrapper and it only knows how to decode UTF-8 (and ASCII).
%%
%%      JSON terms are decoded as follows (javascript -> erlang):
%%      <ul>
%%          <li>{"key": "value"} ->
%%              {struct, [{&lt;&lt;"key">>, &lt;&lt;"value">>}]}</li>
%%          <li>["array", 123, 12.34, true, false, null] ->
%%              [&lt;&lt;"array">>, 123, 12.34, true, false, null]
%%          </li>
%%      </ul>
%%      <ul>
%%          <li>Strings in JSON decode to UTF-8 binaries in Erlang</li>
%%          <li>Objects decode to {struct, PropList}</li>
%%          <li>Numbers decode to integer or float</li>
%%          <li>true, false, null decode to their respective terms.</li>
%%      </ul>
%%      The encoder will accept the same format that the decoder will produce,
%%      but will also allow additional cases for leniency:
%%      <ul>
%%          <li>atoms other than true, false, null will be considered UTF-8
%%              strings (even as a proplist key)
%%          </li>
%%          <li>{json, IoList} will insert IoList directly into the output
%%              with no validation
%%          </li>
%%          <li>{array, Array} will be encoded as Array
%%              (legacy mochijson style)
%%          </li>
%%          <li>A non-empty raw proplist will be encoded as an object as long
%%              as the first pair does not have an atom key of json, struct,
%%              or array
%%          </li>
%%      </ul>

-module(mochijson2).
-author('bob@mochimedia.com').
-export([encoder/1, encode/1]).
-export([decoder/1, decode/1, decode/2]).

%% This is a macro to placate syntax highlighters..
-define(Q, $\").
-define(ADV_COL(S, N), S#decoder{offset=N+S#decoder.offset,
                                 column=N+S#decoder.column}).
-define(INC_COL(S), S#decoder{offset=1+S#decoder.offset,
                              column=1+S#decoder.column}).
-define(INC_LINE(S), S#decoder{offset=1+S#decoder.offset,
                               column=1,
                               line=1+S#decoder.line}).
-define(INC_CHAR(S, C),
        case C of
            $\n ->
                S#decoder{column=1,
                          line=1+S#decoder.line,
                          offset=1+S#decoder.offset};
            _ ->
                S#decoder{column=1+S#decoder.column,
                          offset=1+S#decoder.offset}
        end).
-define(IS_WHITESPACE(C),
        (C =:= $\s orelse C =:= $\t orelse C =:= $\r orelse C =:= $\n)).

%% @type iolist() = [char() | binary() | iolist()]
%% @type iodata() = iolist() | binary()
%% @type json_string() = atom | binary()
%% @type json_number() = integer() | float()
%% @type json_array() = [json_term()]
%% @type json_object() = {struct, [{json_string(), json_term()}]}
%% @type json_eep18_object() = {[{json_string(), json_term()}]}
%% @type json_iolist() = {json, iolist()}
%% @type json_term() = json_string() | json_number() | json_array() |
%%                     json_object() | json_eep18_object() | json_iolist()

-record(encoder, {handler=null,
                  utf8=false}).

-record(decoder, {object_hook=null,
                  offset=0,
                  line=1,
                  column=1,
                  state=null}).

%% @spec encoder([encoder_option()]) -> function()
%% @doc Create an encoder/1 with the given options.
%% @type encoder_option() = handler_option() | utf8_option()
%% @type utf8_option() = boolean(). Emit unicode as utf8 (default - false)
encoder(Options) ->
    State = parse_encoder_options(Options, #encoder{}),
    fun (O) -> json_encode(O, State) end.

%% @spec encode(json_term()) -> iolist()
%% @doc Encode the given as JSON to an iolist.
encode(Any) ->
    json_encode(Any, #encoder{}).

%% @spec decoder([decoder_option()]) -> function()
%% @doc Create a decoder/1 with the given options.
decoder(Options) ->
    State = parse_decoder_options(Options, #decoder{}),
    fun (O) -> json_decode(O, State) end.

%% @spec decode(iolist(), [{format, proplist | eep18 | struct}]) -> json_term()
%% @doc Decode the given iolist to Erlang terms using the given object format
%%      for decoding, where proplist returns JSON objects as [{binary(), json_term()}]
%%      proplists, eep18 returns JSON objects as {[binary(), json_term()]}, and struct
%%      returns them as-is.
decode(S, Options) ->
    json_decode(S, parse_decoder_options(Options, #decoder{})).

%% @spec decode(iolist()) -> json_term()
%% @doc Decode the given iolist to Erlang terms.
decode(S) ->
    json_decode(S, #decoder{}).

%% Internal API

parse_encoder_options([], State) ->
    State;
parse_encoder_options([{handler, Handler} | Rest], State) ->
    parse_encoder_options(Rest, State#encoder{handler=Handler});
parse_encoder_options([{utf8, Switch} | Rest], State) ->
    parse_encoder_options(Rest, State#encoder{utf8=Switch}).

parse_decoder_options([], State) ->
    State;
parse_decoder_options([{object_hook, Hook} | Rest], State) ->
    parse_decoder_options(Rest, State#decoder{object_hook=Hook});
parse_decoder_options([{format, Format} | Rest], State)
  when Format =:= struct orelse Format =:= eep18 orelse Format =:= proplist ->
    parse_decoder_options(Rest, State#decoder{object_hook=Format}).

json_encode(true, _State) ->
    <<"true">>;
json_encode(false, _State) ->
    <<"false">>;
json_encode(null, _State) ->
    <<"null">>;
json_encode(I, _State) when is_integer(I) ->
    integer_to_list(I);
json_encode(F, _State) when is_float(F) ->
    mochinum:digits(F);
json_encode(S, State) when is_binary(S); is_atom(S) ->
    json_encode_string(S, State);
json_encode([{K, _}|_] = Props, State) when (K =/= struct andalso
                                             K =/= array andalso
                                             K =/= json) ->
    json_encode_proplist(Props, State);
json_encode({struct, Props}, State) when is_list(Props) ->
    json_encode_proplist(Props, State);
json_encode({Props}, State) when is_list(Props) ->
    json_encode_proplist(Props, State);
json_encode({}, State) ->
    json_encode_proplist([], State);
json_encode(Array, State) when is_list(Array) ->
    json_encode_array(Array, State);
json_encode({array, Array}, State) when is_list(Array) ->
    json_encode_array(Array, State);
json_encode({json, IoList}, _State) ->
    IoList;
json_encode(Bad, #encoder{handler=null}) ->
    exit({json_encode, {bad_term, Bad}});
json_encode(Bad, State=#encoder{handler=Handler}) ->
    json_encode(Handler(Bad), State).

json_encode_array([], _State) ->
    <<"[]">>;
json_encode_array(L, State) ->
    F = fun (O, Acc) ->
                [$,, json_encode(O, State) | Acc]
        end,
    [$, | Acc1] = lists:foldl(F, "[", L),
    lists:reverse([$\] | Acc1]).

json_encode_proplist([], _State) ->
    <<"{}">>;
json_encode_proplist(Props, State) ->
    F = fun ({K, V}, Acc) ->
                KS = json_encode_string(K, State),
                VS = json_encode(V, State),
                [$,, VS, $:, KS | Acc]
        end,
    [$, | Acc1] = lists:foldl(F, "{", Props),
    lists:reverse([$\} | Acc1]).

json_encode_string(A, State) when is_atom(A) ->
    L = atom_to_list(A),
    case json_string_is_safe(L) of
        true ->
            [?Q, L, ?Q];
        false ->
            json_encode_string_unicode(xmerl_ucs:from_utf8(L), State, [?Q])
    end;
json_encode_string(B, State) when is_binary(B) ->
    case json_bin_is_safe(B) of
        true ->
            [?Q, B, ?Q];
        false ->
            json_encode_string_unicode(xmerl_ucs:from_utf8(B), State, [?Q])
    end;
json_encode_string(I, _State) when is_integer(I) ->
    [?Q, integer_to_list(I), ?Q];
json_encode_string(L, State) when is_list(L) ->
    case json_string_is_safe(L) of
        true ->
            [?Q, L, ?Q];
        false ->
            json_encode_string_unicode(L, State, [?Q])
    end.

json_string_is_safe([]) ->
    true;
json_string_is_safe([C | Rest]) ->
    case C of
        ?Q ->
            false;
        $\\ ->
            false;
        $\b ->
            false;
        $\f ->
            false;
        $\n ->
            false;
        $\r ->
            false;
        $\t ->
            false;
        C when C >= 0, C < $\s; C >= 16#7f, C =< 16#10FFFF ->
            false;
        C when C < 16#7f ->
            json_string_is_safe(Rest);
        _ ->
            false
    end.

json_bin_is_safe(<<>>) ->
    true;
json_bin_is_safe(<<C, Rest/binary>>) ->
    case C of
        ?Q ->
            false;
        $\\ ->
            false;
        $\b ->
            false;
        $\f ->
            false;
        $\n ->
            false;
        $\r ->
            false;
        $\t ->
            false;
        C when C >= 0, C < $\s; C >= 16#7f ->
            false;
        C when C < 16#7f ->
            json_bin_is_safe(Rest)
    end.

json_encode_string_unicode([], _State, Acc) ->
    lists:reverse([$\" | Acc]);
json_encode_string_unicode([C | Cs], State, Acc) ->
    Acc1 = case C of
               ?Q ->
                   [?Q, $\\ | Acc];
               %% Escaping solidus is only useful when trying to protect
               %% against "</script>" injection attacks which are only
               %% possible when JSON is inserted into a HTML document
               %% in-line. mochijson2 does not protect you from this, so
               %% if you do insert directly into HTML then you need to
               %% uncomment the following case or escape the output of encode.
               %%
               %% $/ ->
               %%    [$/, $\\ | Acc];
               %%
               $\\ ->
                   [$\\, $\\ | Acc];
               $\b ->
                   [$b, $\\ | Acc];
               $\f ->
                   [$f, $\\ | Acc];
               $\n ->
                   [$n, $\\ | Acc];
               $\r ->
                   [$r, $\\ | Acc];
               $\t ->
                   [$t, $\\ | Acc];
               C when C >= 0, C < $\s ->
                   [unihex(C) | Acc];
               C when C >= 16#7f, C =< 16#10FFFF, State#encoder.utf8 ->
                   [xmerl_ucs:to_utf8(C) | Acc];
               C when  C >= 16#7f, C =< 16#10FFFF, not State#encoder.utf8 ->
                   [unihex(C) | Acc];
               C when C < 16#7f ->
                   [C | Acc];
               _ ->
                   exit({json_encode, {bad_char, C}})
           end,
    json_encode_string_unicode(Cs, State, Acc1).

hexdigit(C) when C >= 0, C =< 9 ->
    C + $0;
hexdigit(C) when C =< 15 ->
    C + $a - 10.

unihex(C) when C < 16#10000 ->
    <<D3:4, D2:4, D1:4, D0:4>> = <<C:16>>,
    Digits = [hexdigit(D) || D <- [D3, D2, D1, D0]],
    [$\\, $u | Digits];
unihex(C) when C =< 16#10FFFF ->
    N = C - 16#10000,
    S1 = 16#d800 bor ((N bsr 10) band 16#3ff),
    S2 = 16#dc00 bor (N band 16#3ff),
    [unihex(S1), unihex(S2)].

json_decode(L, S) when is_list(L) ->
    json_decode(iolist_to_binary(L), S);
json_decode(B, S) ->
    {Res, S1} = decode1(B, S),
    {eof, _} = tokenize(B, S1#decoder{state=trim}),
    Res.

decode1(B, S=#decoder{state=null}) ->
    case tokenize(B, S#decoder{state=any}) of
        {{const, C}, S1} ->
            {C, S1};
        {start_array, S1} ->
            decode_array(B, S1);
        {start_object, S1} ->
            decode_object(B, S1)
    end.

make_object(V, #decoder{object_hook=N}) when N =:= null orelse N =:= struct ->
    V;
make_object({struct, P}, #decoder{object_hook=eep18}) ->
    {P};
make_object({struct, P}, #decoder{object_hook=proplist}) ->
    P;
make_object(V, #decoder{object_hook=Hook}) ->
    Hook(V).

decode_object(B, S) ->
    decode_object(B, S#decoder{state=key}, []).

decode_object(B, S=#decoder{state=key}, Acc) ->
    case tokenize(B, S) of
        {end_object, S1} ->
            V = make_object({struct, lists:reverse(Acc)}, S1),
            {V, S1#decoder{state=null}};
        {{const, K}, S1} ->
            {colon, S2} = tokenize(B, S1),
            {V, S3} = decode1(B, S2#decoder{state=null}),
            decode_object(B, S3#decoder{state=comma}, [{K, V} | Acc])
    end;
decode_object(B, S=#decoder{state=comma}, Acc) ->
    case tokenize(B, S) of
        {end_object, S1} ->
            V = make_object({struct, lists:reverse(Acc)}, S1),
            {V, S1#decoder{state=null}};
        {comma, S1} ->
            decode_object(B, S1#decoder{state=key}, Acc)
    end.

decode_array(B, S) ->
    decode_array(B, S#decoder{state=any}, []).

decode_array(B, S=#decoder{state=any}, Acc) ->
    case tokenize(B, S) of
        {end_array, S1} ->
            {lists:reverse(Acc), S1#decoder{state=null}};
        {start_array, S1} ->
            {Array, S2} = decode_array(B, S1),
            decode_array(B, S2#decoder{state=comma}, [Array | Acc]);
        {start_object, S1} ->
            {Array, S2} = decode_object(B, S1),
            decode_array(B, S2#decoder{state=comma}, [Array | Acc]);
        {{const, Const}, S1} ->
            decode_array(B, S1#decoder{state=comma}, [Const | Acc])
    end;
decode_array(B, S=#decoder{state=comma}, Acc) ->
    case tokenize(B, S) of
        {end_array, S1} ->
            {lists:reverse(Acc), S1#decoder{state=null}};
        {comma, S1} ->
            decode_array(B, S1#decoder{state=any}, Acc)
    end.

tokenize_string(B, S=#decoder{offset=O}) ->
    case tokenize_string_fast(B, O) of
        {escape, O1} ->
            Length = O1 - O,
            S1 = ?ADV_COL(S, Length),
            <<_:O/binary, Head:Length/binary, _/binary>> = B,
            tokenize_string(B, S1, lists:reverse(binary_to_list(Head)));
        O1 ->
            Length = O1 - O,
            <<_:O/binary, String:Length/binary, ?Q, _/binary>> = B,
            {{const, String}, ?ADV_COL(S, Length + 1)}
    end.

tokenize_string_fast(B, O) ->
    case B of
        <<_:O/binary, ?Q, _/binary>> ->
            O;
        <<_:O/binary, $\\, _/binary>> ->
            {escape, O};
        <<_:O/binary, C1, _/binary>> when C1 < 128 ->
            tokenize_string_fast(B, 1 + O);
        <<_:O/binary, C1, C2, _/binary>> when C1 >= 194, C1 =< 223,
                C2 >= 128, C2 =< 191 ->
            tokenize_string_fast(B, 2 + O);
        <<_:O/binary, C1, C2, C3, _/binary>> when C1 >= 224, C1 =< 239,
                C2 >= 128, C2 =< 191,
                C3 >= 128, C3 =< 191 ->
            tokenize_string_fast(B, 3 + O);
        <<_:O/binary, C1, C2, C3, C4, _/binary>> when C1 >= 240, C1 =< 244,
                C2 >= 128, C2 =< 191,
                C3 >= 128, C3 =< 191,
                C4 >= 128, C4 =< 191 ->
            tokenize_string_fast(B, 4 + O);
        _ ->
            throw(invalid_utf8)
    end.

tokenize_string(B, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, ?Q, _/binary>> ->
            {{const, iolist_to_binary(lists:reverse(Acc))}, ?INC_COL(S)};
        <<_:O/binary, "\\\"", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$\" | Acc]);
        <<_:O/binary, "\\\\", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$\\ | Acc]);
        <<_:O/binary, "\\/", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$/ | Acc]);
        <<_:O/binary, "\\b", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$\b | Acc]);
        <<_:O/binary, "\\f", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$\f | Acc]);
        <<_:O/binary, "\\n", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$\n | Acc]);
        <<_:O/binary, "\\r", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$\r | Acc]);
        <<_:O/binary, "\\t", _/binary>> ->
            tokenize_string(B, ?ADV_COL(S, 2), [$\t | Acc]);
        <<_:O/binary, "\\u", C3, C2, C1, C0, Rest/binary>> ->
            C = erlang:list_to_integer([C3, C2, C1, C0], 16),
            if C > 16#D7FF, C < 16#DC00 ->
                %% coalesce UTF-16 surrogate pair
                <<"\\u", D3, D2, D1, D0, _/binary>> = Rest,
                D = erlang:list_to_integer([D3,D2,D1,D0], 16),
                [CodePoint] = xmerl_ucs:from_utf16be(<<C:16/big-unsigned-integer,
                    D:16/big-unsigned-integer>>),
                Acc1 = lists:reverse(xmerl_ucs:to_utf8(CodePoint), Acc),
                tokenize_string(B, ?ADV_COL(S, 12), Acc1);
            true ->
                Acc1 = lists:reverse(xmerl_ucs:to_utf8(C), Acc),
                tokenize_string(B, ?ADV_COL(S, 6), Acc1)
            end;
        <<_:O/binary, C1, _/binary>> when C1 < 128 ->
            tokenize_string(B, ?INC_CHAR(S, C1), [C1 | Acc]);
        <<_:O/binary, C1, C2, _/binary>> when C1 >= 194, C1 =< 223,
                C2 >= 128, C2 =< 191 ->
            tokenize_string(B, ?ADV_COL(S, 2), [C2, C1 | Acc]);
        <<_:O/binary, C1, C2, C3, _/binary>> when C1 >= 224, C1 =< 239,
                C2 >= 128, C2 =< 191,
                C3 >= 128, C3 =< 191 ->
            tokenize_string(B, ?ADV_COL(S, 3), [C3, C2, C1 | Acc]);
        <<_:O/binary, C1, C2, C3, C4, _/binary>> when C1 >= 240, C1 =< 244,
                C2 >= 128, C2 =< 191,
                C3 >= 128, C3 =< 191,
                C4 >= 128, C4 =< 191 ->
            tokenize_string(B, ?ADV_COL(S, 4), [C4, C3, C2, C1 | Acc]);
        _ ->
            throw(invalid_utf8)
    end.

tokenize_number(B, S) ->
    case tokenize_number(B, sign, S, []) of
        {{int, Int}, S1} ->
            {{const, list_to_integer(Int)}, S1};
        {{float, Float}, S1} ->
            {{const, list_to_float(Float)}, S1}
    end.

tokenize_number(B, sign, S=#decoder{offset=O}, []) ->
    case B of
        <<_:O/binary, $-, _/binary>> ->
            tokenize_number(B, int, ?INC_COL(S), [$-]);
        _ ->
            tokenize_number(B, int, S, [])
    end;
tokenize_number(B, int, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, $0, _/binary>> ->
            tokenize_number(B, frac, ?INC_COL(S), [$0 | Acc]);
        <<_:O/binary, C, _/binary>> when C >= $1 andalso C =< $9 ->
            tokenize_number(B, int1, ?INC_COL(S), [C | Acc])
    end;
tokenize_number(B, int1, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, C, _/binary>> when C >= $0 andalso C =< $9 ->
            tokenize_number(B, int1, ?INC_COL(S), [C | Acc]);
        _ ->
            tokenize_number(B, frac, S, Acc)
    end;
tokenize_number(B, frac, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, $., C, _/binary>> when C >= $0, C =< $9 ->
            tokenize_number(B, frac1, ?ADV_COL(S, 2), [C, $. | Acc]);
        <<_:O/binary, E, _/binary>> when E =:= $e orelse E =:= $E ->
            tokenize_number(B, esign, ?INC_COL(S), [$e, $0, $. | Acc]);
        _ ->
            {{int, lists:reverse(Acc)}, S}
    end;
tokenize_number(B, frac1, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, C, _/binary>> when C >= $0 andalso C =< $9 ->
            tokenize_number(B, frac1, ?INC_COL(S), [C | Acc]);
        <<_:O/binary, E, _/binary>> when E =:= $e orelse E =:= $E ->
            tokenize_number(B, esign, ?INC_COL(S), [$e | Acc]);
        _ ->
            {{float, lists:reverse(Acc)}, S}
    end;
tokenize_number(B, esign, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, C, _/binary>> when C =:= $- orelse C=:= $+ ->
            tokenize_number(B, eint, ?INC_COL(S), [C | Acc]);
        _ ->
            tokenize_number(B, eint, S, Acc)
    end;
tokenize_number(B, eint, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, C, _/binary>> when C >= $0 andalso C =< $9 ->
            tokenize_number(B, eint1, ?INC_COL(S), [C | Acc])
    end;
tokenize_number(B, eint1, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary, C, _/binary>> when C >= $0 andalso C =< $9 ->
            tokenize_number(B, eint1, ?INC_COL(S), [C | Acc]);
        _ ->
            {{float, lists:reverse(Acc)}, S}
    end.

tokenize(B, S=#decoder{offset=O}) ->
    case B of
        <<_:O/binary, C, _/binary>> when ?IS_WHITESPACE(C) ->
            tokenize(B, ?INC_CHAR(S, C));
        <<_:O/binary, "{", _/binary>> ->
            {start_object, ?INC_COL(S)};
        <<_:O/binary, "}", _/binary>> ->
            {end_object, ?INC_COL(S)};
        <<_:O/binary, "[", _/binary>> ->
            {start_array, ?INC_COL(S)};
        <<_:O/binary, "]", _/binary>> ->
            {end_array, ?INC_COL(S)};
        <<_:O/binary, ",", _/binary>> ->
            {comma, ?INC_COL(S)};
        <<_:O/binary, ":", _/binary>> ->
            {colon, ?INC_COL(S)};
        <<_:O/binary, "null", _/binary>> ->
            {{const, null}, ?ADV_COL(S, 4)};
        <<_:O/binary, "true", _/binary>> ->
            {{const, true}, ?ADV_COL(S, 4)};
        <<_:O/binary, "false", _/binary>> ->
            {{const, false}, ?ADV_COL(S, 5)};
        <<_:O/binary, "\"", _/binary>> ->
            tokenize_string(B, ?INC_COL(S));
        <<_:O/binary, C, _/binary>> when (C >= $0 andalso C =< $9)
                                         orelse C =:= $- ->
            tokenize_number(B, S);
        <<_:O/binary>> ->
            trim = S#decoder.state,
            {eof, S}
    end.
%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").


%% testing constructs borrowed from the Yaws JSON implementation.

%% Create an object from a list of Key/Value pairs.

obj_new() ->
    {struct, []}.

is_obj({struct, Props}) ->
    F = fun ({K, _}) when is_binary(K) -> true end,
    lists:all(F, Props).

obj_from_list(Props) ->
    Obj = {struct, Props},
    ?assert(is_obj(Obj)),
    Obj.

%% Test for equivalence of Erlang terms.
%% Due to arbitrary order of construction, equivalent objects might
%% compare unequal as erlang terms, so we need to carefully recurse
%% through aggregates (tuples and objects).

equiv({struct, Props1}, {struct, Props2}) ->
    equiv_object(Props1, Props2);
equiv(L1, L2) when is_list(L1), is_list(L2) ->
    equiv_list(L1, L2);
equiv(N1, N2) when is_number(N1), is_number(N2) -> N1 == N2;
equiv(B1, B2) when is_binary(B1), is_binary(B2) -> B1 == B2;
equiv(A, A) when A =:= true orelse A =:= false orelse A =:= null -> true.

%% Object representation and traversal order is unknown.
%% Use the sledgehammer and sort property lists.

equiv_object(Props1, Props2) ->
    L1 = lists:keysort(1, Props1),
    L2 = lists:keysort(1, Props2),
    Pairs = lists:zip(L1, L2),
    true = lists:all(fun({{K1, V1}, {K2, V2}}) ->
                             equiv(K1, K2) and equiv(V1, V2)
                     end, Pairs).

%% Recursively compare tuple elements for equivalence.

equiv_list([], []) ->
    true;
equiv_list([V1 | L1], [V2 | L2]) ->
    equiv(V1, V2) andalso equiv_list(L1, L2).

decode_test() ->
    [1199344435545.0, 1] = decode(<<"[1199344435545.0,1]">>),
    <<16#F0,16#9D,16#9C,16#95>> = decode([34,"\\ud835","\\udf15",34]).

e2j_vec_test() ->
    test_one(e2j_test_vec(utf8), 1).

test_one([], _N) ->
    %% io:format("~p tests passed~n", [N-1]),
    ok;
test_one([{E, J} | Rest], N) ->
    %% io:format("[~p] ~p ~p~n", [N, E, J]),
    true = equiv(E, decode(J)),
    true = equiv(E, decode(encode(E))),
    test_one(Rest, 1+N).

e2j_test_vec(utf8) ->
    [
     {1, "1"},
     {3.1416, "3.14160"}, %% text representation may truncate, trail zeroes
     {-1, "-1"},
     {-3.1416, "-3.14160"},
     {12.0e10, "1.20000e+11"},
     {1.234E+10, "1.23400e+10"},
     {-1.234E-10, "-1.23400e-10"},
     {10.0, "1.0e+01"},
     {123.456, "1.23456E+2"},
     {10.0, "1e1"},
     {<<"foo">>, "\"foo\""},
     {<<"foo", 5, "bar">>, "\"foo\\u0005bar\""},
     {<<"">>, "\"\""},
     {<<"\n\n\n">>, "\"\\n\\n\\n\""},
     {<<"\" \b\f\r\n\t\"">>, "\"\\\" \\b\\f\\r\\n\\t\\\"\""},
     {obj_new(), "{}"},
     {obj_from_list([{<<"foo">>, <<"bar">>}]), "{\"foo\":\"bar\"}"},
     {obj_from_list([{<<"foo">>, <<"bar">>}, {<<"baz">>, 123}]),
      "{\"foo\":\"bar\",\"baz\":123}"},
     {[], "[]"},
     {[[]], "[[]]"},
     {[1, <<"foo">>], "[1,\"foo\"]"},

     %% json array in a json object
     {obj_from_list([{<<"foo">>, [123]}]),
      "{\"foo\":[123]}"},

     %% json object in a json object
     {obj_from_list([{<<"foo">>, obj_from_list([{<<"bar">>, true}])}]),
      "{\"foo\":{\"bar\":true}}"},

     %% fold evaluation order
     {obj_from_list([{<<"foo">>, []},
                     {<<"bar">>, obj_from_list([{<<"baz">>, true}])},
                     {<<"alice">>, <<"bob">>}]),
      "{\"foo\":[],\"bar\":{\"baz\":true},\"alice\":\"bob\"}"},

     %% json object in a json array
     {[-123, <<"foo">>, obj_from_list([{<<"bar">>, []}]), null],
      "[-123,\"foo\",{\"bar\":[]},null]"}
    ].

%% test utf8 encoding
encoder_utf8_test() ->
    %% safe conversion case (default)
    [34,"\\u0001","\\u0442","\\u0435","\\u0441","\\u0442",34] =
        encode(<<1,"\321\202\320\265\321\201\321\202">>),

    %% raw utf8 output (optional)
    Enc = mochijson2:encoder([{utf8, true}]),
    [34,"\\u0001",[209,130],[208,181],[209,129],[209,130],34] =
        Enc(<<1,"\321\202\320\265\321\201\321\202">>).

input_validation_test() ->
    Good = [
        {16#00A3, <<?Q, 16#C2, 16#A3, ?Q>>}, %% pound
        {16#20AC, <<?Q, 16#E2, 16#82, 16#AC, ?Q>>}, %% euro
        {16#10196, <<?Q, 16#F0, 16#90, 16#86, 16#96, ?Q>>} %% denarius
    ],
    lists:foreach(fun({CodePoint, UTF8}) ->
        Expect = list_to_binary(xmerl_ucs:to_utf8(CodePoint)),
        Expect = decode(UTF8)
    end, Good),

    Bad = [
        %% 2nd, 3rd, or 4th byte of a multi-byte sequence w/o leading byte
        <<?Q, 16#80, ?Q>>,
        %% missing continuations, last byte in each should be 80-BF
        <<?Q, 16#C2, 16#7F, ?Q>>,
        <<?Q, 16#E0, 16#80,16#7F, ?Q>>,
        <<?Q, 16#F0, 16#80, 16#80, 16#7F, ?Q>>,
        %% we don't support code points > 10FFFF per RFC 3629
        <<?Q, 16#F5, 16#80, 16#80, 16#80, ?Q>>,
        %% escape characters trigger a different code path
        <<?Q, $\\, $\n, 16#80, ?Q>>
    ],
    lists:foreach(
      fun(X) ->
              ok = try decode(X) catch invalid_utf8 -> ok end,
              %% could be {ucs,{bad_utf8_character_code}} or
              %%          {json_encode,{bad_char,_}}
              {'EXIT', _} = (catch encode(X))
      end, Bad).

inline_json_test() ->
    ?assertEqual(<<"\"iodata iodata\"">>,
                 iolist_to_binary(
                   encode({json, [<<"\"iodata">>, " iodata\""]}))),
    ?assertEqual({struct, [{<<"key">>, <<"iodata iodata">>}]},
                 decode(
                   encode({struct,
                           [{key, {json, [<<"\"iodata">>, " iodata\""]}}]}))),
    ok.

big_unicode_test() ->
    UTF8Seq = list_to_binary(xmerl_ucs:to_utf8(16#0001d120)),
    ?assertEqual(
       <<"\"\\ud834\\udd20\"">>,
       iolist_to_binary(encode(UTF8Seq))),
    ?assertEqual(
       UTF8Seq,
       decode(iolist_to_binary(encode(UTF8Seq)))),
    ok.

custom_decoder_test() ->
    ?assertEqual(
       {struct, [{<<"key">>, <<"value">>}]},
       (decoder([]))("{\"key\": \"value\"}")),
    F = fun ({struct, [{<<"key">>, <<"value">>}]}) -> win end,
    ?assertEqual(
       win,
       (decoder([{object_hook, F}]))("{\"key\": \"value\"}")),
    ok.

atom_test() ->
    %% JSON native atoms
    [begin
         ?assertEqual(A, decode(atom_to_list(A))),
         ?assertEqual(iolist_to_binary(atom_to_list(A)),
                      iolist_to_binary(encode(A)))
     end || A <- [true, false, null]],
    %% Atom to string
    ?assertEqual(
       <<"\"foo\"">>,
       iolist_to_binary(encode(foo))),
    ?assertEqual(
       <<"\"\\ud834\\udd20\"">>,
       iolist_to_binary(encode(list_to_atom(xmerl_ucs:to_utf8(16#0001d120))))),
    ok.

key_encode_test() ->
    %% Some forms are accepted as keys that would not be strings in other
    %% cases
    ?assertEqual(
       <<"{\"foo\":1}">>,
       iolist_to_binary(encode({struct, [{foo, 1}]}))),
    ?assertEqual(
       <<"{\"foo\":1}">>,
       iolist_to_binary(encode({struct, [{<<"foo">>, 1}]}))),
    ?assertEqual(
       <<"{\"foo\":1}">>,
       iolist_to_binary(encode({struct, [{"foo", 1}]}))),
	?assertEqual(
       <<"{\"foo\":1}">>,
       iolist_to_binary(encode([{foo, 1}]))),
    ?assertEqual(
       <<"{\"foo\":1}">>,
       iolist_to_binary(encode([{<<"foo">>, 1}]))),
    ?assertEqual(
       <<"{\"foo\":1}">>,
       iolist_to_binary(encode([{"foo", 1}]))),
    ?assertEqual(
       <<"{\"\\ud834\\udd20\":1}">>,
       iolist_to_binary(
         encode({struct, [{[16#0001d120], 1}]}))),
    ?assertEqual(
       <<"{\"1\":1}">>,
       iolist_to_binary(encode({struct, [{1, 1}]}))),
    ok.

unsafe_chars_test() ->
    Chars = "\"\\\b\f\n\r\t",
    [begin
         ?assertEqual(false, json_string_is_safe([C])),
         ?assertEqual(false, json_bin_is_safe(<<C>>)),
         ?assertEqual(<<C>>, decode(encode(<<C>>)))
     end || C <- Chars],
    ?assertEqual(
       false,
       json_string_is_safe([16#0001d120])),
    ?assertEqual(
       false,
       json_bin_is_safe(list_to_binary(xmerl_ucs:to_utf8(16#0001d120)))),
    ?assertEqual(
       [16#0001d120],
       xmerl_ucs:from_utf8(
         binary_to_list(
           decode(encode(list_to_atom(xmerl_ucs:to_utf8(16#0001d120))))))),
    ?assertEqual(
       false,
       json_string_is_safe([16#110000])),
    ?assertEqual(
       false,
       json_bin_is_safe(list_to_binary(xmerl_ucs:to_utf8([16#110000])))),
    %% solidus can be escaped but isn't unsafe by default
    ?assertEqual(
       <<"/">>,
       decode(<<"\"\\/\"">>)),
    ok.

int_test() ->
    ?assertEqual(0, decode("0")),
    ?assertEqual(1, decode("1")),
    ?assertEqual(11, decode("11")),
    ok.

large_int_test() ->
    ?assertEqual(<<"-2147483649214748364921474836492147483649">>,
        iolist_to_binary(encode(-2147483649214748364921474836492147483649))),
    ?assertEqual(<<"2147483649214748364921474836492147483649">>,
        iolist_to_binary(encode(2147483649214748364921474836492147483649))),
    ok.

float_test() ->
    ?assertEqual(<<"-2147483649.0">>, iolist_to_binary(encode(-2147483649.0))),
    ?assertEqual(<<"2147483648.0">>, iolist_to_binary(encode(2147483648.0))),
    ok.

handler_test() ->
    ?assertEqual(
       {'EXIT',{json_encode,{bad_term,{x,y}}}},
       catch encode({x,y})),
    F = fun ({x,y}) -> [] end,
    ?assertEqual(
       <<"[]">>,
       iolist_to_binary((encoder([{handler, F}]))({x, y}))),
    ok.

encode_empty_test_() ->
    [{A, ?_assertEqual(<<"{}">>, iolist_to_binary(encode(B)))}
     || {A, B} <- [{"eep18 {}", {}},
                   {"eep18 {[]}", {[]}},
                   {"{struct, []}", {struct, []}}]].

encode_test_() ->
    P = [{<<"k">>, <<"v">>}],
    JSON = iolist_to_binary(encode({struct, P})),
    [{atom_to_list(F),
      ?_assertEqual(JSON, iolist_to_binary(encode(decode(JSON, [{format, F}]))))}
     || F <- [struct, eep18, proplist]].

format_test_() ->
    P = [{<<"k">>, <<"v">>}],
    JSON = iolist_to_binary(encode({struct, P})),
    [{atom_to_list(F),
      ?_assertEqual(A, decode(JSON, [{format, F}]))}
     || {F, A} <- [{struct, {struct, P}},
                   {eep18, {P}},
                   {proplist, P}]].

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2006 Mochi Media, Inc.

%% @doc Yet another JSON (RFC 4627) library for Erlang.
-module(mochijson).
-author('bob@mochimedia.com').
-export([encoder/1, encode/1]).
-export([decoder/1, decode/1]).
-export([binary_encoder/1, binary_encode/1]).
-export([binary_decoder/1, binary_decode/1]).

% This is a macro to placate syntax highlighters..
-define(Q, $\").
-define(ADV_COL(S, N), S#decoder{column=N+S#decoder.column}).
-define(INC_COL(S), S#decoder{column=1+S#decoder.column}).
-define(INC_LINE(S), S#decoder{column=1, line=1+S#decoder.line}).

%% @type iolist() = [char() | binary() | iolist()]
%% @type iodata() = iolist() | binary()
%% @type json_string() = atom | string() | binary()
%% @type json_number() = integer() | float()
%% @type json_array() = {array, [json_term()]}
%% @type json_object() = {struct, [{json_string(), json_term()}]}
%% @type json_term() = json_string() | json_number() | json_array() |
%%                     json_object()
%% @type encoding() = utf8 | unicode
%% @type encoder_option() = {input_encoding, encoding()} |
%%                          {handler, function()}
%% @type decoder_option() = {input_encoding, encoding()} |
%%                          {object_hook, function()}
%% @type bjson_string() = binary()
%% @type bjson_number() = integer() | float()
%% @type bjson_array() = [bjson_term()]
%% @type bjson_object() = {struct, [{bjson_string(), bjson_term()}]}
%% @type bjson_term() = bjson_string() | bjson_number() | bjson_array() |
%%                      bjson_object()
%% @type binary_encoder_option() = {handler, function()}
%% @type binary_decoder_option() = {object_hook, function()}

-record(encoder, {input_encoding=unicode,
                  handler=null}).

-record(decoder, {input_encoding=utf8,
                  object_hook=null,
                  line=1,
                  column=1,
                  state=null}).

%% @spec encoder([encoder_option()]) -> function()
%% @doc Create an encoder/1 with the given options.
encoder(Options) ->
    State = parse_encoder_options(Options, #encoder{}),
    fun (O) -> json_encode(O, State) end.

%% @spec encode(json_term()) -> iolist()
%% @doc Encode the given as JSON to an iolist.
encode(Any) ->
    json_encode(Any, #encoder{}).

%% @spec decoder([decoder_option()]) -> function()
%% @doc Create a decoder/1 with the given options.
decoder(Options) ->
    State = parse_decoder_options(Options, #decoder{}),
    fun (O) -> json_decode(O, State) end.

%% @spec decode(iolist()) -> json_term()
%% @doc Decode the given iolist to Erlang terms.
decode(S) ->
    json_decode(S, #decoder{}).

%% @spec binary_decoder([binary_decoder_option()]) -> function()
%% @doc Create a binary_decoder/1 with the given options.
binary_decoder(Options) ->
    mochijson2:decoder(Options).

%% @spec binary_encoder([binary_encoder_option()]) -> function()
%% @doc Create a binary_encoder/1 with the given options.
binary_encoder(Options) ->
    mochijson2:encoder(Options).

%% @spec binary_encode(bjson_term()) -> iolist()
%% @doc Encode the given as JSON to an iolist, using lists for arrays and
%%      binaries for strings.
binary_encode(Any) ->
    mochijson2:encode(Any).

%% @spec binary_decode(iolist()) -> bjson_term()
%% @doc Decode the given iolist to Erlang terms, using lists for arrays and
%%      binaries for strings.
binary_decode(S) ->
    mochijson2:decode(S).

%% Internal API

parse_encoder_options([], State) ->
    State;
parse_encoder_options([{input_encoding, Encoding} | Rest], State) ->
    parse_encoder_options(Rest, State#encoder{input_encoding=Encoding});
parse_encoder_options([{handler, Handler} | Rest], State) ->
    parse_encoder_options(Rest, State#encoder{handler=Handler}).

parse_decoder_options([], State) ->
    State;
parse_decoder_options([{input_encoding, Encoding} | Rest], State) ->
    parse_decoder_options(Rest, State#decoder{input_encoding=Encoding});
parse_decoder_options([{object_hook, Hook} | Rest], State) ->
    parse_decoder_options(Rest, State#decoder{object_hook=Hook}).

json_encode(true, _State) ->
    "true";
json_encode(false, _State) ->
    "false";
json_encode(null, _State) ->
    "null";
json_encode(I, _State) when is_integer(I) ->
    integer_to_list(I);
json_encode(F, _State) when is_float(F) ->
    mochinum:digits(F);
json_encode(L, State) when is_list(L); is_binary(L); is_atom(L) ->
    json_encode_string(L, State);
json_encode({array, Props}, State) when is_list(Props) ->
    json_encode_array(Props, State);
json_encode({struct, Props}, State) when is_list(Props) ->
    json_encode_proplist(Props, State);
json_encode(Bad, #encoder{handler=null}) ->
    exit({json_encode, {bad_term, Bad}});
json_encode(Bad, State=#encoder{handler=Handler}) ->
    json_encode(Handler(Bad), State).

json_encode_array([], _State) ->
    "[]";
json_encode_array(L, State) ->
    F = fun (O, Acc) ->
                [$,, json_encode(O, State) | Acc]
        end,
    [$, | Acc1] = lists:foldl(F, "[", L),
    lists:reverse([$\] | Acc1]).

json_encode_proplist([], _State) ->
    "{}";
json_encode_proplist(Props, State) ->
    F = fun ({K, V}, Acc) ->
                KS = case K of 
                         K when is_atom(K) ->
                             json_encode_string_utf8(atom_to_list(K));
                         K when is_integer(K) ->
                             json_encode_string(integer_to_list(K), State);
                         K when is_list(K); is_binary(K) ->
                             json_encode_string(K, State)
                     end,
                VS = json_encode(V, State),
                [$,, VS, $:, KS | Acc]
        end,
    [$, | Acc1] = lists:foldl(F, "{", Props),
    lists:reverse([$\} | Acc1]).

json_encode_string(A, _State) when is_atom(A) ->
    json_encode_string_unicode(xmerl_ucs:from_utf8(atom_to_list(A)));
json_encode_string(B, _State) when is_binary(B) ->
    json_encode_string_unicode(xmerl_ucs:from_utf8(B));
json_encode_string(S, #encoder{input_encoding=utf8}) ->
    json_encode_string_utf8(S);
json_encode_string(S, #encoder{input_encoding=unicode}) ->
    json_encode_string_unicode(S).

json_encode_string_utf8(S) ->
    [?Q | json_encode_string_utf8_1(S)].

json_encode_string_utf8_1([C | Cs]) when C >= 0, C =< 16#7f ->
    NewC = case C of
               $\\ -> "\\\\";
               ?Q -> "\\\"";
               _ when C >= $\s, C < 16#7f -> C;
               $\t -> "\\t";
               $\n -> "\\n";
               $\r -> "\\r";
               $\f -> "\\f";
               $\b -> "\\b";
               _ when C >= 0, C =< 16#7f -> unihex(C);
               _ -> exit({json_encode, {bad_char, C}})
           end,
    [NewC | json_encode_string_utf8_1(Cs)];
json_encode_string_utf8_1(All=[C | _]) when C >= 16#80, C =< 16#10FFFF ->
    [?Q | Rest] = json_encode_string_unicode(xmerl_ucs:from_utf8(All)),
    Rest;
json_encode_string_utf8_1([]) ->
    "\"".

json_encode_string_unicode(S) ->
    [?Q | json_encode_string_unicode_1(S)].

json_encode_string_unicode_1([C | Cs]) ->
    NewC = case C of
               $\\ -> "\\\\";
               ?Q -> "\\\"";
               _ when C >= $\s, C < 16#7f -> C;
               $\t -> "\\t";
               $\n -> "\\n";
               $\r -> "\\r";
               $\f -> "\\f";
               $\b -> "\\b";
               _ when C >= 0, C =< 16#10FFFF -> unihex(C);
               _ -> exit({json_encode, {bad_char, C}})
           end,
    [NewC | json_encode_string_unicode_1(Cs)];
json_encode_string_unicode_1([]) ->
    "\"".

dehex(C) when C >= $0, C =< $9 ->
    C - $0;
dehex(C) when C >= $a, C =< $f ->
    C - $a + 10;
dehex(C) when C >= $A, C =< $F ->
    C - $A + 10.

hexdigit(C) when C >= 0, C =< 9 ->
    C + $0;
hexdigit(C) when C =< 15 ->
    C + $a - 10.

unihex(C) when C < 16#10000 ->
    <<D3:4, D2:4, D1:4, D0:4>> = <<C:16>>,
    Digits = [hexdigit(D) || D <- [D3, D2, D1, D0]],
    [$\\, $u | Digits];
unihex(C) when C =< 16#10FFFF ->
    N = C - 16#10000,
    S1 = 16#d800 bor ((N bsr 10) band 16#3ff),
    S2 = 16#dc00 bor (N band 16#3ff),
    [unihex(S1), unihex(S2)].

json_decode(B, S) when is_binary(B) ->
    json_decode(binary_to_list(B), S);
json_decode(L, S) ->
    {Res, L1, S1} = decode1(L, S),
    {eof, [], _} = tokenize(L1, S1#decoder{state=trim}),
    Res.

decode1(L, S=#decoder{state=null}) ->
    case tokenize(L, S#decoder{state=any}) of
        {{const, C}, L1, S1} ->
            {C, L1, S1};
        {start_array, L1, S1} ->
            decode_array(L1, S1#decoder{state=any}, []);
        {start_object, L1, S1} ->
            decode_object(L1, S1#decoder{state=key}, [])
    end.

make_object(V, #decoder{object_hook=null}) ->
    V;
make_object(V, #decoder{object_hook=Hook}) ->
    Hook(V).

decode_object(L, S=#decoder{state=key}, Acc) ->
    case tokenize(L, S) of
        {end_object, Rest, S1} ->
            V = make_object({struct, lists:reverse(Acc)}, S1),
            {V, Rest, S1#decoder{state=null}};
        {{const, K}, Rest, S1} when is_list(K) ->
            {colon, L2, S2} = tokenize(Rest, S1),
            {V, L3, S3} = decode1(L2, S2#decoder{state=null}),
            decode_object(L3, S3#decoder{state=comma}, [{K, V} | Acc])
    end;
decode_object(L, S=#decoder{state=comma}, Acc) ->
    case tokenize(L, S) of
        {end_object, Rest, S1} ->
            V = make_object({struct, lists:reverse(Acc)}, S1),
            {V, Rest, S1#decoder{state=null}};
        {comma, Rest, S1} ->
            decode_object(Rest, S1#decoder{state=key}, Acc)
    end.

decode_array(L, S=#decoder{state=any}, Acc) ->
    case tokenize(L, S) of
        {end_array, Rest, S1} ->
            {{array, lists:reverse(Acc)}, Rest, S1#decoder{state=null}};
        {start_array, Rest, S1} ->
            {Array, Rest1, S2} = decode_array(Rest, S1#decoder{state=any}, []),
            decode_array(Rest1, S2#decoder{state=comma}, [Array | Acc]);
        {start_object, Rest, S1} ->
            {Array, Rest1, S2} = decode_object(Rest, S1#decoder{state=key}, []),
            decode_array(Rest1, S2#decoder{state=comma}, [Array | Acc]);
        {{const, Const}, Rest, S1} ->
            decode_array(Rest, S1#decoder{state=comma}, [Const | Acc])
    end;
decode_array(L, S=#decoder{state=comma}, Acc) ->
    case tokenize(L, S) of
        {end_array, Rest, S1} ->
            {{array, lists:reverse(Acc)}, Rest, S1#decoder{state=null}};
        {comma, Rest, S1} ->
            decode_array(Rest, S1#decoder{state=any}, Acc)
    end.

tokenize_string(IoList=[C | _], S=#decoder{input_encoding=utf8}, Acc)
  when is_list(C); is_binary(C); C >= 16#7f ->
    List = xmerl_ucs:from_utf8(iolist_to_binary(IoList)),
    tokenize_string(List, S#decoder{input_encoding=unicode}, Acc);
tokenize_string("\"" ++ Rest, S, Acc) ->
    {lists:reverse(Acc), Rest, ?INC_COL(S)};
tokenize_string("\\\"" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$\" | Acc]);
tokenize_string("\\\\" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$\\ | Acc]);
tokenize_string("\\/" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$/ | Acc]);
tokenize_string("\\b" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$\b | Acc]);
tokenize_string("\\f" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$\f | Acc]);
tokenize_string("\\n" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$\n | Acc]);
tokenize_string("\\r" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$\r | Acc]);
tokenize_string("\\t" ++ Rest, S, Acc) ->
    tokenize_string(Rest, ?ADV_COL(S, 2), [$\t | Acc]);
tokenize_string([$\\, $u, C3, C2, C1, C0 | Rest], S, Acc) ->
    % coalesce UTF-16 surrogate pair?
    C = dehex(C0) bor
        (dehex(C1) bsl 4) bor
        (dehex(C2) bsl 8) bor 
        (dehex(C3) bsl 12),
    tokenize_string(Rest, ?ADV_COL(S, 6), [C | Acc]);
tokenize_string([C | Rest], S, Acc) when C >= $\s; C < 16#10FFFF ->
    tokenize_string(Rest, ?ADV_COL(S, 1), [C | Acc]).
    
tokenize_number(IoList=[C | _], Mode, S=#decoder{input_encoding=utf8}, Acc)
  when is_list(C); is_binary(C); C >= 16#7f ->
    List = xmerl_ucs:from_utf8(iolist_to_binary(IoList)),
    tokenize_number(List, Mode, S#decoder{input_encoding=unicode}, Acc);
tokenize_number([$- | Rest], sign, S, []) ->
    tokenize_number(Rest, int, ?INC_COL(S), [$-]);
tokenize_number(Rest, sign, S, []) ->
    tokenize_number(Rest, int, S, []);
tokenize_number([$0 | Rest], int, S, Acc) ->
    tokenize_number(Rest, frac, ?INC_COL(S), [$0 | Acc]);
tokenize_number([C | Rest], int, S, Acc) when C >= $1, C =< $9 ->
    tokenize_number(Rest, int1, ?INC_COL(S), [C | Acc]);
tokenize_number([C | Rest], int1, S, Acc) when C >= $0, C =< $9 ->
    tokenize_number(Rest, int1, ?INC_COL(S), [C | Acc]);
tokenize_number(Rest, int1, S, Acc) ->
    tokenize_number(Rest, frac, S, Acc);
tokenize_number([$., C | Rest], frac, S, Acc) when C >= $0, C =< $9 ->
    tokenize_number(Rest, frac1, ?ADV_COL(S, 2), [C, $. | Acc]);
tokenize_number([E | Rest], frac, S, Acc) when E == $e; E == $E ->
    tokenize_number(Rest, esign, ?INC_COL(S), [$e, $0, $. | Acc]);
tokenize_number(Rest, frac, S, Acc) ->
    {{int, lists:reverse(Acc)}, Rest, S};
tokenize_number([C | Rest], frac1, S, Acc) when C >= $0, C =< $9 ->
    tokenize_number(Rest, frac1, ?INC_COL(S), [C | Acc]);
tokenize_number([E | Rest], frac1, S, Acc) when E == $e; E == $E ->
    tokenize_number(Rest, esign, ?INC_COL(S), [$e | Acc]);
tokenize_number(Rest, frac1, S, Acc) ->
    {{float, lists:reverse(Acc)}, Rest, S};
tokenize_number([C | Rest], esign, S, Acc) when C == $-; C == $+ ->
    tokenize_number(Rest, eint, ?INC_COL(S), [C | Acc]);
tokenize_number(Rest, esign, S, Acc) ->
    tokenize_number(Rest, eint, S, Acc);
tokenize_number([C | Rest], eint, S, Acc) when C >= $0, C =< $9 ->
    tokenize_number(Rest, eint1, ?INC_COL(S), [C | Acc]);
tokenize_number([C | Rest], eint1, S, Acc) when C >= $0, C =< $9 ->
    tokenize_number(Rest, eint1, ?INC_COL(S), [C | Acc]);
tokenize_number(Rest, eint1, S, Acc) ->
    {{float, lists:reverse(Acc)}, Rest, S}.

tokenize([], S=#decoder{state=trim}) ->
    {eof, [], S};
tokenize([L | Rest], S) when is_list(L) ->
    tokenize(L ++ Rest, S);
tokenize([B | Rest], S) when is_binary(B) ->
    tokenize(xmerl_ucs:from_utf8(B) ++ Rest, S);
tokenize("\r\n" ++ Rest, S) ->
    tokenize(Rest, ?INC_LINE(S));
tokenize("\n" ++ Rest, S) ->
    tokenize(Rest, ?INC_LINE(S));
tokenize([C | Rest], S) when C == $\s; C == $\t ->
    tokenize(Rest, ?INC_COL(S));
tokenize("{" ++ Rest, S) ->
    {start_object, Rest, ?INC_COL(S)};
tokenize("}" ++ Rest, S) ->
    {end_object, Rest, ?INC_COL(S)};
tokenize("[" ++ Rest, S) ->
    {start_array, Rest, ?INC_COL(S)};
tokenize("]" ++ Rest, S) ->
    {end_array, Rest, ?INC_COL(S)};
tokenize("," ++ Rest, S) ->
    {comma, Rest, ?INC_COL(S)};
tokenize(":" ++ Rest, S) ->
    {colon, Rest, ?INC_COL(S)};
tokenize("null" ++ Rest, S) ->
    {{const, null}, Rest, ?ADV_COL(S, 4)};
tokenize("true" ++ Rest, S) ->
    {{const, true}, Rest, ?ADV_COL(S, 4)};
tokenize("false" ++ Rest, S) ->
    {{const, false}, Rest, ?ADV_COL(S, 5)};
tokenize("\"" ++ Rest, S) ->
    {String, Rest1, S1} = tokenize_string(Rest, ?INC_COL(S), []),
    {{const, String}, Rest1, S1};
tokenize(L=[C | _], S) when C >= $0, C =< $9; C == $- ->
    case tokenize_number(L, sign, S, []) of
        {{int, Int}, Rest, S1} ->
            {{const, list_to_integer(Int)}, Rest, S1};
        {{float, Float}, Rest, S1} ->
            {{const, list_to_float(Float)}, Rest, S1}
    end.


%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

%% testing constructs borrowed from the Yaws JSON implementation.

%% Create an object from a list of Key/Value pairs.

obj_new() ->
    {struct, []}.

is_obj({struct, Props}) ->
    F = fun ({K, _}) when is_list(K) ->
                true;
            (_) ->
                false
        end,    
    lists:all(F, Props).

obj_from_list(Props) ->
    Obj = {struct, Props},
    case is_obj(Obj) of
        true -> Obj;
        false -> exit(json_bad_object)
    end.

%% Test for equivalence of Erlang terms.
%% Due to arbitrary order of construction, equivalent objects might
%% compare unequal as erlang terms, so we need to carefully recurse
%% through aggregates (tuples and objects).

equiv({struct, Props1}, {struct, Props2}) ->
    equiv_object(Props1, Props2);
equiv({array, L1}, {array, L2}) ->
    equiv_list(L1, L2);
equiv(N1, N2) when is_number(N1), is_number(N2) -> N1 == N2;
equiv(S1, S2) when is_list(S1), is_list(S2)     -> S1 == S2;
equiv(true, true) -> true;
equiv(false, false) -> true;
equiv(null, null) -> true.

%% Object representation and traversal order is unknown.
%% Use the sledgehammer and sort property lists.

equiv_object(Props1, Props2) ->
    L1 = lists:keysort(1, Props1),
    L2 = lists:keysort(1, Props2),
    Pairs = lists:zip(L1, L2),
    true = lists:all(fun({{K1, V1}, {K2, V2}}) ->
        equiv(K1, K2) and equiv(V1, V2)
    end, Pairs).

%% Recursively compare tuple elements for equivalence.

equiv_list([], []) ->
    true;
equiv_list([V1 | L1], [V2 | L2]) ->
    equiv(V1, V2) andalso equiv_list(L1, L2).

e2j_vec_test() ->
    test_one(e2j_test_vec(utf8), 1).

issue33_test() ->
    %% http://code.google.com/p/mochiweb/issues/detail?id=33
    Js = {struct, [{"key", [194, 163]}]},
    Encoder = encoder([{input_encoding, utf8}]),
    "{\"key\":\"\\u00a3\"}" = lists:flatten(Encoder(Js)).

test_one([], _N) ->
    %% io:format("~p tests passed~n", [N-1]),
    ok;
test_one([{E, J} | Rest], N) ->
    %% io:format("[~p] ~p ~p~n", [N, E, J]),
    true = equiv(E, decode(J)),
    true = equiv(E, decode(encode(E))),
    test_one(Rest, 1+N).

e2j_test_vec(utf8) ->
    [
    {1, "1"},
    {3.1416, "3.14160"}, % text representation may truncate, trail zeroes
    {-1, "-1"},
    {-3.1416, "-3.14160"},
    {12.0e10, "1.20000e+11"},
    {1.234E+10, "1.23400e+10"},
    {-1.234E-10, "-1.23400e-10"},
    {10.0, "1.0e+01"},
    {123.456, "1.23456E+2"},
    {10.0, "1e1"},
    {"foo", "\"foo\""},
    {"foo" ++ [5] ++ "bar", "\"foo\\u0005bar\""},
    {"", "\"\""},
    {"\"", "\"\\\"\""},
    {"\n\n\n", "\"\\n\\n\\n\""},
    {"\\", "\"\\\\\""},
    {"\" \b\f\r\n\t\"", "\"\\\" \\b\\f\\r\\n\\t\\\"\""},
    {obj_new(), "{}"},
    {obj_from_list([{"foo", "bar"}]), "{\"foo\":\"bar\"}"},
    {obj_from_list([{"foo", "bar"}, {"baz", 123}]),
     "{\"foo\":\"bar\",\"baz\":123}"},
    {{array, []}, "[]"},
    {{array, [{array, []}]}, "[[]]"},
    {{array, [1, "foo"]}, "[1,\"foo\"]"},

    % json array in a json object
    {obj_from_list([{"foo", {array, [123]}}]),
     "{\"foo\":[123]}"},

    % json object in a json object
    {obj_from_list([{"foo", obj_from_list([{"bar", true}])}]),
     "{\"foo\":{\"bar\":true}}"},

    % fold evaluation order
    {obj_from_list([{"foo", {array, []}},
                     {"bar", obj_from_list([{"baz", true}])},
                     {"alice", "bob"}]),
     "{\"foo\":[],\"bar\":{\"baz\":true},\"alice\":\"bob\"}"},

    % json object in a json array
    {{array, [-123, "foo", obj_from_list([{"bar", {array, []}}]), null]},
     "[-123,\"foo\",{\"bar\":[]},null]"}
    ].

-endif.
%% @copyright Copyright (c) 2010 Mochi Media, Inc.
%% @author David Reid <dreid@mochimedia.com>

%% @doc Utility functions for dealing with proplists.

-module(mochilists).
-author("David Reid <dreid@mochimedia.com>").
-export([get_value/2, get_value/3, is_defined/2, set_default/2, set_defaults/2]).

%% @spec set_default({Key::term(), Value::term()}, Proplist::list()) -> list()
%%
%% @doc Return new Proplist with {Key, Value} set if not is_defined(Key, Proplist).
set_default({Key, Value}, Proplist) ->
    case is_defined(Key, Proplist) of
        true ->
            Proplist;
        false ->
            [{Key, Value} | Proplist]
    end.

%% @spec set_defaults([{Key::term(), Value::term()}], Proplist::list()) -> list()
%%
%% @doc Return new Proplist with {Key, Value} set if not is_defined(Key, Proplist).
set_defaults(DefaultProps, Proplist) ->
    lists:foldl(fun set_default/2, Proplist, DefaultProps).


%% @spec is_defined(Key::term(), Proplist::list()) -> bool()
%%
%% @doc Returns true if Propist contains at least one entry associated
%%      with Key, otherwise false is returned.
is_defined(Key, Proplist) ->
    lists:keyfind(Key, 1, Proplist) =/= false.


%% @spec get_value(Key::term(), Proplist::list()) -> term() | undefined
%%
%% @doc Return the value of <code>Key</code> or undefined
get_value(Key, Proplist) ->
    get_value(Key, Proplist, undefined).

%% @spec get_value(Key::term(), Proplist::list(), Default::term()) -> term()
%%
%% @doc Return the value of <code>Key</code> or <code>Default</code>
get_value(_Key, [], Default) ->
    Default;
get_value(Key, Proplist, Default) ->
    case lists:keyfind(Key, 1, Proplist) of
        false ->
            Default;
        {Key, Value} ->
            Value
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

set_defaults_test() ->
    ?assertEqual(
       [{k, v}],
       set_defaults([{k, v}], [])),
    ?assertEqual(
       [{k, v}],
       set_defaults([{k, vee}], [{k, v}])),
    ?assertEqual(
       lists:sort([{kay, vee}, {k, v}]),
       lists:sort(set_defaults([{k, vee}, {kay, vee}], [{k, v}]))),
    ok.

set_default_test() ->
    ?assertEqual(
       [{k, v}],
       set_default({k, v}, [])),
    ?assertEqual(
       [{k, v}],
       set_default({k, vee}, [{k, v}])),
    ok.

get_value_test() ->
    ?assertEqual(
       undefined,
       get_value(foo, [])),
    ?assertEqual(
       undefined,
       get_value(foo, [{bar, baz}])),
    ?assertEqual(
       bar,
       get_value(foo, [{foo, bar}])),
    ?assertEqual(
       default,
       get_value(foo, [], default)),
    ?assertEqual(
       default,
       get_value(foo, [{bar, baz}], default)),
    ?assertEqual(
       bar,
       get_value(foo, [{foo, bar}], default)),
    ok.

-endif.

%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2010 Mochi Media, Inc.

%% @doc Write newline delimited log files, ensuring that if a truncated
%%      entry is found on log open then it is fixed before writing. Uses
%%      delayed writes and raw files for performance.
-module(mochilogfile2).
-author('bob@mochimedia.com').

-export([open/1, write/2, close/1, name/1]).

%% @spec open(Name) -> Handle
%% @doc Open the log file Name, creating or appending as necessary. All data
%%      at the end of the file will be truncated until a newline is found, to
%%      ensure that all records are complete.
open(Name) ->
    {ok, FD} = file:open(Name, [raw, read, write, delayed_write, binary]),
    fix_log(FD),
    {?MODULE, Name, FD}.

%% @spec name(Handle) -> string()
%% @doc Return the path of the log file.
name({?MODULE, Name, _FD}) ->
    Name.

%% @spec write(Handle, IoData) -> ok
%% @doc Write IoData to the log file referenced by Handle.
write({?MODULE, _Name, FD}, IoData) ->
    ok = file:write(FD, [IoData, $\n]),
    ok.

%% @spec close(Handle) -> ok
%% @doc Close the log file referenced by Handle.
close({?MODULE, _Name, FD}) ->
    ok = file:sync(FD),
    ok = file:close(FD),
    ok.

fix_log(FD) ->
    {ok, Location} = file:position(FD, eof),
    Seek = find_last_newline(FD, Location),
    {ok, Seek} = file:position(FD, Seek),
    ok = file:truncate(FD),
    ok.

%% Seek backwards to the last valid log entry
find_last_newline(_FD, N) when N =< 1 ->
    0;
find_last_newline(FD, Location) ->
    case file:pread(FD, Location - 1, 1) of
	{ok, <<$\n>>} ->
            Location;
	{ok, _} ->
	    find_last_newline(FD, Location - 1)
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
name_test() ->
    D = mochitemp:mkdtemp(),
    FileName = filename:join(D, "open_close_test.log"),
    H = open(FileName),
    ?assertEqual(
       FileName,
       name(H)),
    close(H),
    file:delete(FileName),
    file:del_dir(D),
    ok.

open_close_test() ->
    D = mochitemp:mkdtemp(),
    FileName = filename:join(D, "open_close_test.log"),
    OpenClose = fun () ->
                        H = open(FileName),
                        ?assertEqual(
                           true,
                           filelib:is_file(FileName)),
                        ok = close(H),
                        ?assertEqual(
                           {ok, <<>>},
                           file:read_file(FileName)),
                        ok
                end,
    OpenClose(),
    OpenClose(),
    file:delete(FileName),
    file:del_dir(D),
    ok.

write_test() ->
    D = mochitemp:mkdtemp(),
    FileName = filename:join(D, "write_test.log"),
    F = fun () ->
                H = open(FileName),
                write(H, "test line"),
                close(H),
                ok
        end,
    F(),
    ?assertEqual(
       {ok, <<"test line\n">>},
       file:read_file(FileName)),
    F(),
    ?assertEqual(
       {ok, <<"test line\ntest line\n">>},
       file:read_file(FileName)),
    file:delete(FileName),
    file:del_dir(D),
    ok.

fix_log_test() ->
    D = mochitemp:mkdtemp(),
    FileName = filename:join(D, "write_test.log"),
    file:write_file(FileName, <<"first line good\nsecond line bad">>),
    F = fun () ->
                H = open(FileName),
                write(H, "test line"),
                close(H),
                ok
        end,
    F(),
    ?assertEqual(
       {ok, <<"first line good\ntest line\n">>},
       file:read_file(FileName)),
    file:write_file(FileName, <<"first line bad">>),
    F(),
    ?assertEqual(
       {ok, <<"test line\n">>},
       file:read_file(FileName)),
    F(),
    ?assertEqual(
       {ok, <<"test line\ntest line\n">>},
       file:read_file(FileName)),
    ok.

-endif.
%% @copyright 2007 Mochi Media, Inc.
%% @author Bob Ippolito <bob@mochimedia.com>

%% @doc Useful numeric algorithms for floats that cover some deficiencies
%% in the math module. More interesting is digits/1, which implements
%% the algorithm from:
%% http://www.cs.indiana.edu/~burger/fp/index.html
%% See also "Printing Floating-Point Numbers Quickly and Accurately"
%% in Proceedings of the SIGPLAN '96 Conference on Programming Language
%% Design and Implementation.

-module(mochinum).
-author("Bob Ippolito <bob@mochimedia.com>").
-export([digits/1, frexp/1, int_pow/2, int_ceil/1]).

%% IEEE 754 Float exponent bias
-define(FLOAT_BIAS, 1022).
-define(MIN_EXP, -1074).
-define(BIG_POW, 4503599627370496).

%% External API

%% @spec digits(number()) -> string()
%% @doc  Returns a string that accurately represents the given integer or float
%%       using a conservative amount of digits. Great for generating
%%       human-readable output, or compact ASCII serializations for floats.
digits(N) when is_integer(N) ->
    integer_to_list(N);
digits(0.0) ->
    "0.0";
digits(Float) ->
    {Frac1, Exp1} = frexp_int(Float),
    [Place0 | Digits0] = digits1(Float, Exp1, Frac1),
    {Place, Digits} = transform_digits(Place0, Digits0),
    R = insert_decimal(Place, Digits),
    case Float < 0 of
        true ->
            [$- | R];
        _ ->
            R
    end.

%% @spec frexp(F::float()) -> {Frac::float(), Exp::float()}
%% @doc  Return the fractional and exponent part of an IEEE 754 double,
%%       equivalent to the libc function of the same name.
%%       F = Frac * pow(2, Exp).
frexp(F) ->
    frexp1(unpack(F)).

%% @spec int_pow(X::integer(), N::integer()) -> Y::integer()
%% @doc  Moderately efficient way to exponentiate integers.
%%       int_pow(10, 2) = 100.
int_pow(_X, 0) ->
    1;
int_pow(X, N) when N > 0 ->
    int_pow(X, N, 1).

%% @spec int_ceil(F::float()) -> integer()
%% @doc  Return the ceiling of F as an integer. The ceiling is defined as
%%       F when F == trunc(F);
%%       trunc(F) when F &lt; 0;
%%       trunc(F) + 1 when F &gt; 0.
int_ceil(X) ->
    T = trunc(X),
    case (X - T) of
        Pos when Pos > 0 -> T + 1;
        _ -> T
    end.


%% Internal API

int_pow(X, N, R) when N < 2 ->
    R * X;
int_pow(X, N, R) ->
    int_pow(X * X, N bsr 1, case N band 1 of 1 -> R * X; 0 -> R end).

insert_decimal(0, S) ->
    "0." ++ S;
insert_decimal(Place, S) when Place > 0 ->
    L = length(S),
    case Place - L of
         0 ->
            S ++ ".0";
        N when N < 0 ->
            {S0, S1} = lists:split(L + N, S),
            S0 ++ "." ++ S1;
        N when N < 6 ->
            %% More places than digits
            S ++ lists:duplicate(N, $0) ++ ".0";
        _ ->
            insert_decimal_exp(Place, S)
    end;
insert_decimal(Place, S) when Place > -6 ->
    "0." ++ lists:duplicate(abs(Place), $0) ++ S;
insert_decimal(Place, S) ->
    insert_decimal_exp(Place, S).

insert_decimal_exp(Place, S) ->
    [C | S0] = S,
    S1 = case S0 of
             [] ->
                 "0";
             _ ->
                 S0
         end,
    Exp = case Place < 0 of
              true ->
                  "e-";
              false ->
                  "e+"
          end,
    [C] ++ "." ++ S1 ++ Exp ++ integer_to_list(abs(Place - 1)).


digits1(Float, Exp, Frac) ->
    Round = ((Frac band 1) =:= 0),
    case Exp >= 0 of
        true ->
            BExp = 1 bsl Exp,
            case (Frac =/= ?BIG_POW) of
                true ->
                    scale((Frac * BExp * 2), 2, BExp, BExp,
                          Round, Round, Float);
                false ->
                    scale((Frac * BExp * 4), 4, (BExp * 2), BExp,
                          Round, Round, Float)
            end;
        false ->
            case (Exp =:= ?MIN_EXP) orelse (Frac =/= ?BIG_POW) of
                true ->
                    scale((Frac * 2), 1 bsl (1 - Exp), 1, 1,
                          Round, Round, Float);
                false ->
                    scale((Frac * 4), 1 bsl (2 - Exp), 2, 1,
                          Round, Round, Float)
            end
    end.

scale(R, S, MPlus, MMinus, LowOk, HighOk, Float) ->
    Est = int_ceil(math:log10(abs(Float)) - 1.0e-10),
    %% Note that the scheme implementation uses a 326 element look-up table
    %% for int_pow(10, N) where we do not.
    case Est >= 0 of
        true ->
            fixup(R, S * int_pow(10, Est), MPlus, MMinus, Est,
                  LowOk, HighOk);
        false ->
            Scale = int_pow(10, -Est),
            fixup(R * Scale, S, MPlus * Scale, MMinus * Scale, Est,
                  LowOk, HighOk)
    end.

fixup(R, S, MPlus, MMinus, K, LowOk, HighOk) ->
    TooLow = case HighOk of
                 true ->
                     (R + MPlus) >= S;
                 false ->
                     (R + MPlus) > S
             end,
    case TooLow of
        true ->
            [(K + 1) | generate(R, S, MPlus, MMinus, LowOk, HighOk)];
        false ->
            [K | generate(R * 10, S, MPlus * 10, MMinus * 10, LowOk, HighOk)]
    end.

generate(R0, S, MPlus, MMinus, LowOk, HighOk) ->
    D = R0 div S,
    R = R0 rem S,
    TC1 = case LowOk of
              true ->
                  R =< MMinus;
              false ->
                  R < MMinus
          end,
    TC2 = case HighOk of
              true ->
                  (R + MPlus) >= S;
              false ->
                  (R + MPlus) > S
          end,
    case TC1 of
        false ->
            case TC2 of
                false ->
                    [D | generate(R * 10, S, MPlus * 10, MMinus * 10,
                                  LowOk, HighOk)];
                true ->
                    [D + 1]
            end;
        true ->
            case TC2 of
                false ->
                    [D];
                true ->
                    case R * 2 < S of
                        true ->
                            [D];
                        false ->
                            [D + 1]
                    end
            end
    end.

unpack(Float) ->
    <<Sign:1, Exp:11, Frac:52>> = <<Float:64/float>>,
    {Sign, Exp, Frac}.

frexp1({_Sign, 0, 0}) ->
    {0.0, 0};
frexp1({Sign, 0, Frac}) ->
    Exp = log2floor(Frac),
    <<Frac1:64/float>> = <<Sign:1, ?FLOAT_BIAS:11, (Frac-1):52>>,
    {Frac1, -(?FLOAT_BIAS) - 52 + Exp};
frexp1({Sign, Exp, Frac}) ->
    <<Frac1:64/float>> = <<Sign:1, ?FLOAT_BIAS:11, Frac:52>>,
    {Frac1, Exp - ?FLOAT_BIAS}.

log2floor(Int) ->
    log2floor(Int, 0).

log2floor(0, N) ->
    N;
log2floor(Int, N) ->
    log2floor(Int bsr 1, 1 + N).


transform_digits(Place, [0 | Rest]) ->
    transform_digits(Place, Rest);
transform_digits(Place, Digits) ->
    {Place, [$0 + D || D <- Digits]}.


frexp_int(F) ->
    case unpack(F) of
        {_Sign, 0, Frac} ->
            {Frac, ?MIN_EXP};
        {_Sign, Exp, Frac} ->
            {Frac + (1 bsl 52), Exp - 53 - ?FLOAT_BIAS}
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

int_ceil_test() ->
    ?assertEqual(1, int_ceil(0.0001)),
    ?assertEqual(0, int_ceil(0.0)),
    ?assertEqual(1, int_ceil(0.99)),
    ?assertEqual(1, int_ceil(1.0)),
    ?assertEqual(-1, int_ceil(-1.5)),
    ?assertEqual(-2, int_ceil(-2.0)),
    ok.

int_pow_test() ->
    ?assertEqual(1, int_pow(1, 1)),
    ?assertEqual(1, int_pow(1, 0)),
    ?assertEqual(1, int_pow(10, 0)),
    ?assertEqual(10, int_pow(10, 1)),
    ?assertEqual(100, int_pow(10, 2)),
    ?assertEqual(1000, int_pow(10, 3)),
    ok.

digits_test() ->
    ?assertEqual("0",
                 digits(0)),
    ?assertEqual("0.0",
                 digits(0.0)),
    ?assertEqual("1.0",
                 digits(1.0)),
    ?assertEqual("-1.0",
                 digits(-1.0)),
    ?assertEqual("0.1",
                 digits(0.1)),
    ?assertEqual("0.01",
                 digits(0.01)),
    ?assertEqual("0.001",
                 digits(0.001)),
    ?assertEqual("1.0e+6",
                 digits(1000000.0)),
    ?assertEqual("0.5",
                 digits(0.5)),
    ?assertEqual("4503599627370496.0",
                 digits(4503599627370496.0)),
    %% small denormalized number
    %% 4.94065645841246544177e-324 =:= 5.0e-324
    <<SmallDenorm/float>> = <<0,0,0,0,0,0,0,1>>,
    ?assertEqual("5.0e-324",
                 digits(SmallDenorm)),
    ?assertEqual(SmallDenorm,
                 list_to_float(digits(SmallDenorm))),
    %% large denormalized number
    %% 2.22507385850720088902e-308
    <<BigDenorm/float>> = <<0,15,255,255,255,255,255,255>>,
    ?assertEqual("2.225073858507201e-308",
                 digits(BigDenorm)),
    ?assertEqual(BigDenorm,
                 list_to_float(digits(BigDenorm))),
    %% small normalized number
    %% 2.22507385850720138309e-308
    <<SmallNorm/float>> = <<0,16,0,0,0,0,0,0>>,
    ?assertEqual("2.2250738585072014e-308",
                 digits(SmallNorm)),
    ?assertEqual(SmallNorm,
                 list_to_float(digits(SmallNorm))),
    %% large normalized number
    %% 1.79769313486231570815e+308
    <<LargeNorm/float>> = <<127,239,255,255,255,255,255,255>>,
    ?assertEqual("1.7976931348623157e+308",
                 digits(LargeNorm)),
    ?assertEqual(LargeNorm,
                 list_to_float(digits(LargeNorm))),
    %% issue #10 - mochinum:frexp(math:pow(2, -1074)).
    ?assertEqual("5.0e-324",
                 digits(math:pow(2, -1074))),
    ok.

frexp_test() ->
    %% zero
    ?assertEqual({0.0, 0}, frexp(0.0)),
    %% one
    ?assertEqual({0.5, 1}, frexp(1.0)),
    %% negative one
    ?assertEqual({-0.5, 1}, frexp(-1.0)),
    %% small denormalized number
    %% 4.94065645841246544177e-324
    <<SmallDenorm/float>> = <<0,0,0,0,0,0,0,1>>,
    ?assertEqual({0.5, -1073}, frexp(SmallDenorm)),
    %% large denormalized number
    %% 2.22507385850720088902e-308
    <<BigDenorm/float>> = <<0,15,255,255,255,255,255,255>>,
    ?assertEqual(
       {0.99999999999999978, -1022},
       frexp(BigDenorm)),
    %% small normalized number
    %% 2.22507385850720138309e-308
    <<SmallNorm/float>> = <<0,16,0,0,0,0,0,0>>,
    ?assertEqual({0.5, -1021}, frexp(SmallNorm)),
    %% large normalized number
    %% 1.79769313486231570815e+308
    <<LargeNorm/float>> = <<127,239,255,255,255,255,255,255>>,
    ?assertEqual(
        {0.99999999999999989, 1024},
        frexp(LargeNorm)),
    %% issue #10 - mochinum:frexp(math:pow(2, -1074)).
    ?assertEqual(
       {0.5, -1073},
       frexp(math:pow(2, -1074))),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2010 Mochi Media, Inc.

%% @doc Create temporary files and directories. Requires crypto to be started.

-module(mochitemp).
-export([gettempdir/0]).
-export([mkdtemp/0, mkdtemp/3]).
-export([rmtempdir/1]).
%% -export([mkstemp/4]).
-define(SAFE_CHARS, {$a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m,
                     $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z,
                     $A, $B, $C, $D, $E, $F, $G, $H, $I, $J, $K, $L, $M,
                     $N, $O, $P, $Q, $R, $S, $T, $U, $V, $W, $X, $Y, $Z,
                     $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $_}).
-define(TMP_MAX, 10000).

-include_lib("kernel/include/file.hrl").

%% TODO: An ugly wrapper over the mktemp tool with open_port and sadness?
%%       We can't implement this race-free in Erlang without the ability
%%       to issue O_CREAT|O_EXCL. I suppose we could hack something with
%%       mkdtemp, del_dir, open.
%% mkstemp(Suffix, Prefix, Dir, Options) ->
%%    ok.

rmtempdir(Dir) ->
    case file:del_dir(Dir) of
        {error, eexist} ->
            ok = rmtempdirfiles(Dir),
            ok = file:del_dir(Dir);
        ok ->
            ok
    end.

rmtempdirfiles(Dir) ->
    {ok, Files} = file:list_dir(Dir),
    ok = rmtempdirfiles(Dir, Files).

rmtempdirfiles(_Dir, []) ->
    ok;
rmtempdirfiles(Dir, [Basename | Rest]) ->
    Path = filename:join([Dir, Basename]),
    case filelib:is_dir(Path) of
        true ->
            ok = rmtempdir(Path);
        false ->
            ok = file:delete(Path)
    end,
    rmtempdirfiles(Dir, Rest).

mkdtemp() ->
    mkdtemp("", "tmp", gettempdir()).

mkdtemp(Suffix, Prefix, Dir) ->
    mkdtemp_n(rngpath_fun(Suffix, Prefix, Dir), ?TMP_MAX).



mkdtemp_n(RngPath, 1) ->
    make_dir(RngPath());
mkdtemp_n(RngPath, N) ->
    try make_dir(RngPath())
    catch throw:{error, eexist} ->
            mkdtemp_n(RngPath, N - 1)
    end.

make_dir(Path) ->
    case file:make_dir(Path) of
        ok ->
            ok;
        E={error, eexist} ->
            throw(E)
    end,
    %% Small window for a race condition here because dir is created 777
    ok = file:write_file_info(Path, #file_info{mode=8#0700}),
    Path.

rngpath_fun(Prefix, Suffix, Dir) ->
    fun () ->
            filename:join([Dir, Prefix ++ rngchars(6) ++ Suffix])
    end.

rngchars(0) ->
    "";
rngchars(N) ->
    [rngchar() | rngchars(N - 1)].

rngchar() ->
    rngchar(crypto:rand_uniform(0, tuple_size(?SAFE_CHARS))).

rngchar(C) ->
    element(1 + C, ?SAFE_CHARS).

%% @spec gettempdir() -> string()
%% @doc Get a usable temporary directory using the first of these that is a directory:
%%      $TMPDIR, $TMP, $TEMP, "/tmp", "/var/tmp", "/usr/tmp", ".".
gettempdir() ->
    gettempdir(gettempdir_checks(), fun normalize_dir/1).

gettempdir_checks() ->
    [{fun os:getenv/1, ["TMPDIR", "TMP", "TEMP"]},
     {fun gettempdir_identity/1, ["/tmp", "/var/tmp", "/usr/tmp"]},
     {fun gettempdir_cwd/1, [cwd]}].

gettempdir_identity(L) ->
    L.

gettempdir_cwd(cwd) ->
    {ok, L} = file:get_cwd(),
    L.

gettempdir([{_F, []} | RestF], Normalize) ->
    gettempdir(RestF, Normalize);
gettempdir([{F, [L | RestL]} | RestF], Normalize) ->
    case Normalize(F(L)) of
        false ->
            gettempdir([{F, RestL} | RestF], Normalize);
        Dir ->
            Dir
    end.

normalize_dir(False) when False =:= false orelse False =:= "" ->
    %% Erlang doesn't have an unsetenv, wtf.
    false;
normalize_dir(L) ->
    Dir = filename:absname(L),
    case filelib:is_dir(Dir) of
        false ->
            false;
        true ->
            Dir
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

pushenv(L) ->
    [{K, os:getenv(K)} || K <- L].
popenv(L) ->
    F = fun ({K, false}) ->
                %% Erlang doesn't have an unsetenv, wtf.
                os:putenv(K, "");
            ({K, V}) ->
                os:putenv(K, V)
        end,
    lists:foreach(F, L).

gettempdir_fallback_test() ->
    ?assertEqual(
       "/",
       gettempdir([{fun gettempdir_identity/1, ["/--not-here--/"]},
                   {fun gettempdir_identity/1, ["/"]}],
                  fun normalize_dir/1)),
    ?assertEqual(
       "/",
       %% simulate a true os:getenv unset env
       gettempdir([{fun gettempdir_identity/1, [false]},
                   {fun gettempdir_identity/1, ["/"]}],
                  fun normalize_dir/1)),
    ok.

gettempdir_identity_test() ->
    ?assertEqual(
       "/",
       gettempdir([{fun gettempdir_identity/1, ["/"]}], fun normalize_dir/1)),
    ok.

gettempdir_cwd_test() ->
    {ok, Cwd} = file:get_cwd(),
    ?assertEqual(
       normalize_dir(Cwd),
       gettempdir([{fun gettempdir_cwd/1, [cwd]}], fun normalize_dir/1)),
    ok.

rngchars_test() ->
    crypto:start(),
    ?assertEqual(
       "",
       rngchars(0)),
    ?assertEqual(
       10,
       length(rngchars(10))),
    ok.

rngchar_test() ->
    ?assertEqual(
       $a,
       rngchar(0)),
    ?assertEqual(
       $A,
       rngchar(26)),
    ?assertEqual(
       $_,
       rngchar(62)),
    ok.

mkdtemp_n_failonce_test() ->
    crypto:start(),
    D = mkdtemp(),
    Path = filename:join([D, "testdir"]),
    %% Toggle the existence of a dir so that it fails
    %% the first time and succeeds the second.
    F = fun () ->
                case filelib:is_dir(Path) of
                    true ->
                        file:del_dir(Path);
                    false ->
                        file:make_dir(Path)
                end,
                Path
        end,
    try
        %% Fails the first time
        ?assertThrow(
           {error, eexist},
           mkdtemp_n(F, 1)),
        %% Reset state
        file:del_dir(Path),
        %% Succeeds the second time
        ?assertEqual(
           Path,
           mkdtemp_n(F, 2))
    after rmtempdir(D)
    end,
    ok.

mkdtemp_n_fail_test() ->
    {ok, Cwd} = file:get_cwd(),
    ?assertThrow(
       {error, eexist},
       mkdtemp_n(fun () -> Cwd end, 1)),
    ?assertThrow(
       {error, eexist},
       mkdtemp_n(fun () -> Cwd end, 2)),
    ok.

make_dir_fail_test() ->
    {ok, Cwd} = file:get_cwd(),
    ?assertThrow(
      {error, eexist},
      make_dir(Cwd)),
    ok.

mkdtemp_test() ->
    crypto:start(),
    D = mkdtemp(),
    ?assertEqual(
       true,
       filelib:is_dir(D)),
    ?assertEqual(
       ok,
       file:del_dir(D)),
    ok.

rmtempdir_test() ->
    crypto:start(),
    D1 = mkdtemp(),
    ?assertEqual(
       true,
       filelib:is_dir(D1)),
    ?assertEqual(
       ok,
       rmtempdir(D1)),
    D2 = mkdtemp(),
    ?assertEqual(
       true,
       filelib:is_dir(D2)),
    ok = file:write_file(filename:join([D2, "foo"]), <<"bytes">>),
    D3 = mkdtemp("suffix", "prefix", D2),
    ?assertEqual(
       true,
       filelib:is_dir(D3)),
    ok = file:write_file(filename:join([D3, "foo"]), <<"bytes">>),
    ?assertEqual(
       ok,
       rmtempdir(D2)),
    ?assertEqual(
       {error, enoent},
       file:consult(D3)),
    ?assertEqual(
       {error, enoent},
       file:consult(D2)),
    ok.

gettempdir_env_test() ->
    Env = pushenv(["TMPDIR", "TEMP", "TMP"]),
    FalseEnv = [{"TMPDIR", false}, {"TEMP", false}, {"TMP", false}],
    try
        popenv(FalseEnv),
        popenv([{"TMPDIR", "/"}]),
        ?assertEqual(
           "/",
           os:getenv("TMPDIR")),
        ?assertEqual(
           "/",
           gettempdir()),
        {ok, Cwd} = file:get_cwd(),
        popenv(FalseEnv),
        popenv([{"TMP", Cwd}]),
        ?assertEqual(
           normalize_dir(Cwd),
           gettempdir())
    after popenv(Env)
    end,
    ok.

-endif.
%% @copyright 2010 Mochi Media, Inc.
%% @author Bob Ippolito <bob@mochimedia.com>

%% @doc Algorithm to convert any binary to a valid UTF-8 sequence by ignoring
%%      invalid bytes.

-module(mochiutf8).
-export([valid_utf8_bytes/1, codepoint_to_bytes/1, codepoints_to_bytes/1]).
-export([bytes_to_codepoints/1, bytes_foldl/3, codepoint_foldl/3]).
-export([read_codepoint/1, len/1]).

%% External API

-type unichar_low() :: 0..16#d7ff.
-type unichar_high() :: 16#e000..16#10ffff.
-type unichar() :: unichar_low() | unichar_high().

-spec codepoint_to_bytes(unichar()) -> binary().
%% @doc Convert a unicode codepoint to UTF-8 bytes.
codepoint_to_bytes(C) when (C >= 16#00 andalso C =< 16#7f) ->
    %% U+0000 - U+007F - 7 bits
    <<C>>;
codepoint_to_bytes(C) when (C >= 16#080 andalso C =< 16#07FF) ->
    %% U+0080 - U+07FF - 11 bits
    <<0:5, B1:5, B0:6>> = <<C:16>>,
    <<2#110:3, B1:5,
      2#10:2, B0:6>>;
codepoint_to_bytes(C) when (C >= 16#0800 andalso C =< 16#FFFF) andalso
                           (C < 16#D800 orelse C > 16#DFFF) ->
    %% U+0800 - U+FFFF - 16 bits (excluding UTC-16 surrogate code points)
    <<B2:4, B1:6, B0:6>> = <<C:16>>,
    <<2#1110:4, B2:4,
      2#10:2, B1:6,
      2#10:2, B0:6>>;
codepoint_to_bytes(C) when (C >= 16#010000 andalso C =< 16#10FFFF) ->
    %% U+10000 - U+10FFFF - 21 bits
    <<0:3, B3:3, B2:6, B1:6, B0:6>> = <<C:24>>,
    <<2#11110:5, B3:3,
      2#10:2, B2:6,
      2#10:2, B1:6,
      2#10:2, B0:6>>.

-spec codepoints_to_bytes([unichar()]) -> binary().
%% @doc Convert a list of codepoints to a UTF-8 binary.
codepoints_to_bytes(L) ->
    <<<<(codepoint_to_bytes(C))/binary>> || C <- L>>.

-spec read_codepoint(binary()) -> {unichar(), binary(), binary()}.
read_codepoint(Bin = <<2#0:1, C:7, Rest/binary>>) ->
    %% U+0000 - U+007F - 7 bits
    <<B:1/binary, _/binary>> = Bin,
    {C, B, Rest};
read_codepoint(Bin = <<2#110:3, B1:5,
                       2#10:2, B0:6,
                       Rest/binary>>) ->
    %% U+0080 - U+07FF - 11 bits
    case <<B1:5, B0:6>> of
        <<C:11>> when C >= 16#80 ->
            <<B:2/binary, _/binary>> = Bin,
            {C, B, Rest}
    end;
read_codepoint(Bin = <<2#1110:4, B2:4,
                       2#10:2, B1:6,
                       2#10:2, B0:6,
                       Rest/binary>>) ->
    %% U+0800 - U+FFFF - 16 bits (excluding UTC-16 surrogate code points)
    case <<B2:4, B1:6, B0:6>> of
        <<C:16>> when (C >= 16#0800 andalso C =< 16#FFFF) andalso
                      (C < 16#D800 orelse C > 16#DFFF) ->
            <<B:3/binary, _/binary>> = Bin,
            {C, B, Rest}
    end;
read_codepoint(Bin = <<2#11110:5, B3:3,
                       2#10:2, B2:6,
                       2#10:2, B1:6,
                       2#10:2, B0:6,
                       Rest/binary>>) ->
    %% U+10000 - U+10FFFF - 21 bits
    case <<B3:3, B2:6, B1:6, B0:6>> of
        <<C:21>> when (C >= 16#010000 andalso C =< 16#10FFFF) ->
            <<B:4/binary, _/binary>> = Bin,
            {C, B, Rest}
    end.

-spec codepoint_foldl(fun((unichar(), _) -> _), _, binary()) -> _.
codepoint_foldl(F, Acc, <<>>) when is_function(F, 2) ->
    Acc;
codepoint_foldl(F, Acc, Bin) ->
    {C, _, Rest} = read_codepoint(Bin),
    codepoint_foldl(F, F(C, Acc), Rest).

-spec bytes_foldl(fun((binary(), _) -> _), _, binary()) -> _.
bytes_foldl(F, Acc, <<>>) when is_function(F, 2) ->
    Acc;
bytes_foldl(F, Acc, Bin) ->
    {_, B, Rest} = read_codepoint(Bin),
    bytes_foldl(F, F(B, Acc), Rest).

-spec bytes_to_codepoints(binary()) -> [unichar()].
bytes_to_codepoints(B) ->
    lists:reverse(codepoint_foldl(fun (C, Acc) -> [C | Acc] end, [], B)).

-spec len(binary()) -> non_neg_integer().
len(<<>>) ->
    0;
len(B) ->
    {_, _, Rest} = read_codepoint(B),
    1 + len(Rest).

-spec valid_utf8_bytes(B::binary()) -> binary().
%% @doc Return only the bytes in B that represent valid UTF-8. Uses
%%      the following recursive algorithm: skip one byte if B does not
%%      follow UTF-8 syntax (a 1-4 byte encoding of some number),
%%      skip sequence of 2-4 bytes if it represents an overlong encoding
%%      or bad code point (surrogate U+D800 - U+DFFF or > U+10FFFF).
valid_utf8_bytes(B) when is_binary(B) ->
    binary_skip_bytes(B, invalid_utf8_indexes(B)).

%% Internal API

-spec binary_skip_bytes(binary(), [non_neg_integer()]) -> binary().
%% @doc Return B, but skipping the 0-based indexes in L.
binary_skip_bytes(B, []) ->
    B;
binary_skip_bytes(B, L) ->
    binary_skip_bytes(B, L, 0, []).

%% @private
-spec binary_skip_bytes(binary(), [non_neg_integer()], non_neg_integer(), iolist()) -> binary().
binary_skip_bytes(B, [], _N, Acc) ->
    iolist_to_binary(lists:reverse([B | Acc]));
binary_skip_bytes(<<_, RestB/binary>>, [N | RestL], N, Acc) ->
    binary_skip_bytes(RestB, RestL, 1 + N, Acc);
binary_skip_bytes(<<C, RestB/binary>>, L, N, Acc) ->
    binary_skip_bytes(RestB, L, 1 + N, [C | Acc]).

-spec invalid_utf8_indexes(binary()) -> [non_neg_integer()].
%% @doc Return the 0-based indexes in B that are not valid UTF-8.
invalid_utf8_indexes(B) ->
    invalid_utf8_indexes(B, 0, []).

%% @private.
-spec invalid_utf8_indexes(binary(), non_neg_integer(), [non_neg_integer()]) -> [non_neg_integer()].
invalid_utf8_indexes(<<C, Rest/binary>>, N, Acc) when C < 16#80 ->
    %% U+0000 - U+007F - 7 bits
    invalid_utf8_indexes(Rest, 1 + N, Acc);
invalid_utf8_indexes(<<C1, C2, Rest/binary>>, N, Acc)
  when C1 band 16#E0 =:= 16#C0,
       C2 band 16#C0 =:= 16#80 ->
    %% U+0080 - U+07FF - 11 bits
    case ((C1 band 16#1F) bsl 6) bor (C2 band 16#3F) of
	C when C < 16#80 ->
            %% Overlong encoding.
            invalid_utf8_indexes(Rest, 2 + N, [1 + N, N | Acc]);
        _ ->
            %% Upper bound U+07FF does not need to be checked
            invalid_utf8_indexes(Rest, 2 + N, Acc)
    end;
invalid_utf8_indexes(<<C1, C2, C3, Rest/binary>>, N, Acc)
  when C1 band 16#F0 =:= 16#E0,
       C2 band 16#C0 =:= 16#80,
       C3 band 16#C0 =:= 16#80 ->
    %% U+0800 - U+FFFF - 16 bits
    case ((((C1 band 16#0F) bsl 6) bor (C2 band 16#3F)) bsl 6) bor
	(C3 band 16#3F) of
	C when (C < 16#800) orelse (C >= 16#D800 andalso C =< 16#DFFF) ->
	    %% Overlong encoding or surrogate.
            invalid_utf8_indexes(Rest, 3 + N, [2 + N, 1 + N, N | Acc]);
	_ ->
            %% Upper bound U+FFFF does not need to be checked
	    invalid_utf8_indexes(Rest, 3 + N, Acc)
    end;
invalid_utf8_indexes(<<C1, C2, C3, C4, Rest/binary>>, N, Acc)
  when C1 band 16#F8 =:= 16#F0,
       C2 band 16#C0 =:= 16#80,
       C3 band 16#C0 =:= 16#80,
       C4 band 16#C0 =:= 16#80 ->
    %% U+10000 - U+10FFFF - 21 bits
    case ((((((C1 band 16#0F) bsl 6) bor (C2 band 16#3F)) bsl 6) bor
           (C3 band 16#3F)) bsl 6) bor (C4 band 16#3F) of
	C when (C < 16#10000) orelse (C > 16#10FFFF) ->
	    %% Overlong encoding or invalid code point.
	    invalid_utf8_indexes(Rest, 4 + N, [3 + N, 2 + N, 1 + N, N | Acc]);
	_ ->
	    invalid_utf8_indexes(Rest, 4 + N, Acc)
    end;
invalid_utf8_indexes(<<_, Rest/binary>>, N, Acc) ->
    %% Invalid char
    invalid_utf8_indexes(Rest, 1 + N, [N | Acc]);
invalid_utf8_indexes(<<>>, _N, Acc) ->
    lists:reverse(Acc).

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

binary_skip_bytes_test() ->
    ?assertEqual(<<"foo">>,
                 binary_skip_bytes(<<"foo">>, [])),
    ?assertEqual(<<"foobar">>,
                 binary_skip_bytes(<<"foo bar">>, [3])),
    ?assertEqual(<<"foo">>,
                 binary_skip_bytes(<<"foo bar">>, [3, 4, 5, 6])),
    ?assertEqual(<<"oo bar">>,
                 binary_skip_bytes(<<"foo bar">>, [0])),
    ok.

invalid_utf8_indexes_test() ->
    ?assertEqual(
       [],
       invalid_utf8_indexes(<<"unicode snowman for you: ", 226, 152, 131>>)),
    ?assertEqual(
       [0],
       invalid_utf8_indexes(<<128>>)),
    ?assertEqual(
       [57,59,60,64,66,67],
       invalid_utf8_indexes(<<"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; (",
                              167, 65, 170, 186, 73, 83, 80, 166, 87, 186, 217, 41, 41>>)),
    ok.

codepoint_to_bytes_test() ->
    %% U+0000 - U+007F - 7 bits
    %% U+0080 - U+07FF - 11 bits
    %% U+0800 - U+FFFF - 16 bits (excluding UTC-16 surrogate code points)
    %% U+10000 - U+10FFFF - 21 bits
    ?assertEqual(
       <<"a">>,
       codepoint_to_bytes($a)),
    ?assertEqual(
       <<16#c2, 16#80>>,
       codepoint_to_bytes(16#80)),
    ?assertEqual(
       <<16#df, 16#bf>>,
       codepoint_to_bytes(16#07ff)),
    ?assertEqual(
       <<16#ef, 16#bf, 16#bf>>,
       codepoint_to_bytes(16#ffff)),
    ?assertEqual(
       <<16#f4, 16#8f, 16#bf, 16#bf>>,
       codepoint_to_bytes(16#10ffff)),
    ok.

bytes_foldl_test() ->
    ?assertEqual(
       <<"abc">>,
       bytes_foldl(fun (B, Acc) -> <<Acc/binary, B/binary>> end, <<>>, <<"abc">>)),
    ?assertEqual(
       <<"abc", 226, 152, 131, 228, 184, 173, 194, 133, 244,143,191,191>>,
       bytes_foldl(fun (B, Acc) -> <<Acc/binary, B/binary>> end, <<>>,
                   <<"abc", 226, 152, 131, 228, 184, 173, 194, 133, 244,143,191,191>>)),
    ok.

bytes_to_codepoints_test() ->
    ?assertEqual(
       "abc" ++ [16#2603, 16#4e2d, 16#85, 16#10ffff],
       bytes_to_codepoints(<<"abc", 226, 152, 131, 228, 184, 173, 194, 133, 244,143,191,191>>)),
    ok.

codepoint_foldl_test() ->
    ?assertEqual(
       "cba",
       codepoint_foldl(fun (C, Acc) -> [C | Acc] end, [], <<"abc">>)),
    ?assertEqual(
       [16#10ffff, 16#85, 16#4e2d, 16#2603 | "cba"],
       codepoint_foldl(fun (C, Acc) -> [C | Acc] end, [],
                       <<"abc", 226, 152, 131, 228, 184, 173, 194, 133, 244,143,191,191>>)),
    ok.

len_test() ->
    ?assertEqual(
       29,
       len(<<"unicode snowman for you: ", 226, 152, 131, 228, 184, 173, 194, 133, 244, 143, 191, 191>>)),
    ok.

codepoints_to_bytes_test() ->
    ?assertEqual(
       iolist_to_binary(lists:map(fun codepoint_to_bytes/1, lists:seq(1, 1000))),
       codepoints_to_bytes(lists:seq(1, 1000))),
    ok.

valid_utf8_bytes_test() ->
    ?assertEqual(
       <<"invalid U+11ffff: ">>,
       valid_utf8_bytes(<<"invalid U+11ffff: ", 244, 159, 191, 191>>)),
    ?assertEqual(
       <<"U+10ffff: ", 244, 143, 191, 191>>,
       valid_utf8_bytes(<<"U+10ffff: ", 244, 143, 191, 191>>)),
    ?assertEqual(
       <<"overlong 2-byte encoding (a): ">>,
       valid_utf8_bytes(<<"overlong 2-byte encoding (a): ", 2#11000001, 2#10100001>>)),
    ?assertEqual(
       <<"overlong 2-byte encoding (!): ">>,
       valid_utf8_bytes(<<"overlong 2-byte encoding (!): ", 2#11000000, 2#10100001>>)),
    ?assertEqual(
       <<"mu: ", 194, 181>>,
       valid_utf8_bytes(<<"mu: ", 194, 181>>)),
    ?assertEqual(
       <<"bad coding bytes: ">>,
       valid_utf8_bytes(<<"bad coding bytes: ", 2#10011111, 2#10111111, 2#11111111>>)),
    ?assertEqual(
       <<"low surrogate (unpaired): ">>,
       valid_utf8_bytes(<<"low surrogate (unpaired): ", 237, 176, 128>>)),
    ?assertEqual(
       <<"high surrogate (unpaired): ">>,
       valid_utf8_bytes(<<"high surrogate (unpaired): ", 237, 191, 191>>)),
    ?assertEqual(
       <<"unicode snowman for you: ", 226, 152, 131>>,
       valid_utf8_bytes(<<"unicode snowman for you: ", 226, 152, 131>>)),
    ?assertEqual(
       <<"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; (AISPW))">>,
       valid_utf8_bytes(<<"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; (",
                          167, 65, 170, 186, 73, 83, 80, 166, 87, 186, 217, 41, 41>>)),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2010 Mochi Media, Inc.

%% @doc MochiWeb acceptor.

-module(mochiweb_acceptor).
-author('bob@mochimedia.com').

-include("internal.hrl").

-export([start_link/3, init/3]).

start_link(Server, Listen, Loop) ->
    proc_lib:spawn_link(?MODULE, init, [Server, Listen, Loop]).

init(Server, Listen, Loop) ->
    T1 = now(),
    case catch mochiweb_socket:accept(Listen) of
        {ok, Socket} ->
            gen_server:cast(Server, {accepted, self(), timer:now_diff(now(), T1)}),
            call_loop(Loop, Socket);
        {error, closed} ->
            exit(normal);
        {error, timeout} ->
            init(Server, Listen, Loop);
        {error, esslaccept} ->
            exit(normal);
        Other ->
            error_logger:error_report(
              [{application, mochiweb},
               "Accept failed error",
               lists:flatten(io_lib:format("~p", [Other]))]),
            exit({error, accept_failed})
    end.

call_loop({M, F}, Socket) ->
    M:F(Socket);
call_loop({M, F, [A1]}, Socket) ->
    M:F(Socket, A1);
call_loop({M, F, A}, Socket) ->
    erlang:apply(M, F, [Socket | A]);
call_loop(Loop, Socket) ->
    Loop(Socket).

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Converts HTML 4 charrefs and entities to codepoints.
-module(mochiweb_charref).
-export([charref/1]).

%% External API.

%% @spec charref(S) -> integer() | undefined
%% @doc Convert a decimal charref, hex charref, or html entity to a unicode
%%      codepoint, or return undefined on failure.
%%      The input should not include an ampersand or semicolon.
%%      charref("#38") = 38, charref("#x26") = 38, charref("amp") = 38.
charref(B) when is_binary(B) ->
    charref(binary_to_list(B));
charref([$#, C | L]) when C =:= $x orelse C =:= $X ->
    try erlang:list_to_integer(L, 16)
    catch
        error:badarg -> undefined
    end;
charref([$# | L]) ->
    try list_to_integer(L)
    catch
        error:badarg -> undefined
    end;
charref(L) ->
    entity(L).

%% Internal API.

entity("nbsp") -> 160;
entity("iexcl") -> 161;
entity("cent") -> 162;
entity("pound") -> 163;
entity("curren") -> 164;
entity("yen") -> 165;
entity("brvbar") -> 166;
entity("sect") -> 167;
entity("uml") -> 168;
entity("copy") -> 169;
entity("ordf") -> 170;
entity("laquo") -> 171;
entity("not") -> 172;
entity("shy") -> 173;
entity("reg") -> 174;
entity("macr") -> 175;
entity("deg") -> 176;
entity("plusmn") -> 177;
entity("sup2") -> 178;
entity("sup3") -> 179;
entity("acute") -> 180;
entity("micro") -> 181;
entity("para") -> 182;
entity("middot") -> 183;
entity("cedil") -> 184;
entity("sup1") -> 185;
entity("ordm") -> 186;
entity("raquo") -> 187;
entity("frac14") -> 188;
entity("frac12") -> 189;
entity("frac34") -> 190;
entity("iquest") -> 191;
entity("Agrave") -> 192;
entity("Aacute") -> 193;
entity("Acirc") -> 194;
entity("Atilde") -> 195;
entity("Auml") -> 196;
entity("Aring") -> 197;
entity("AElig") -> 198;
entity("Ccedil") -> 199;
entity("Egrave") -> 200;
entity("Eacute") -> 201;
entity("Ecirc") -> 202;
entity("Euml") -> 203;
entity("Igrave") -> 204;
entity("Iacute") -> 205;
entity("Icirc") -> 206;
entity("Iuml") -> 207;
entity("ETH") -> 208;
entity("Ntilde") -> 209;
entity("Ograve") -> 210;
entity("Oacute") -> 211;
entity("Ocirc") -> 212;
entity("Otilde") -> 213;
entity("Ouml") -> 214;
entity("times") -> 215;
entity("Oslash") -> 216;
entity("Ugrave") -> 217;
entity("Uacute") -> 218;
entity("Ucirc") -> 219;
entity("Uuml") -> 220;
entity("Yacute") -> 221;
entity("THORN") -> 222;
entity("szlig") -> 223;
entity("agrave") -> 224;
entity("aacute") -> 225;
entity("acirc") -> 226;
entity("atilde") -> 227;
entity("auml") -> 228;
entity("aring") -> 229;
entity("aelig") -> 230;
entity("ccedil") -> 231;
entity("egrave") -> 232;
entity("eacute") -> 233;
entity("ecirc") -> 234;
entity("euml") -> 235;
entity("igrave") -> 236;
entity("iacute") -> 237;
entity("icirc") -> 238;
entity("iuml") -> 239;
entity("eth") -> 240;
entity("ntilde") -> 241;
entity("ograve") -> 242;
entity("oacute") -> 243;
entity("ocirc") -> 244;
entity("otilde") -> 245;
entity("ouml") -> 246;
entity("divide") -> 247;
entity("oslash") -> 248;
entity("ugrave") -> 249;
entity("uacute") -> 250;
entity("ucirc") -> 251;
entity("uuml") -> 252;
entity("yacute") -> 253;
entity("thorn") -> 254;
entity("yuml") -> 255;
entity("fnof") -> 402;
entity("Alpha") -> 913;
entity("Beta") -> 914;
entity("Gamma") -> 915;
entity("Delta") -> 916;
entity("Epsilon") -> 917;
entity("Zeta") -> 918;
entity("Eta") -> 919;
entity("Theta") -> 920;
entity("Iota") -> 921;
entity("Kappa") -> 922;
entity("Lambda") -> 923;
entity("Mu") -> 924;
entity("Nu") -> 925;
entity("Xi") -> 926;
entity("Omicron") -> 927;
entity("Pi") -> 928;
entity("Rho") -> 929;
entity("Sigma") -> 931;
entity("Tau") -> 932;
entity("Upsilon") -> 933;
entity("Phi") -> 934;
entity("Chi") -> 935;
entity("Psi") -> 936;
entity("Omega") -> 937;
entity("alpha") -> 945;
entity("beta") -> 946;
entity("gamma") -> 947;
entity("delta") -> 948;
entity("epsilon") -> 949;
entity("zeta") -> 950;
entity("eta") -> 951;
entity("theta") -> 952;
entity("iota") -> 953;
entity("kappa") -> 954;
entity("lambda") -> 955;
entity("mu") -> 956;
entity("nu") -> 957;
entity("xi") -> 958;
entity("omicron") -> 959;
entity("pi") -> 960;
entity("rho") -> 961;
entity("sigmaf") -> 962;
entity("sigma") -> 963;
entity("tau") -> 964;
entity("upsilon") -> 965;
entity("phi") -> 966;
entity("chi") -> 967;
entity("psi") -> 968;
entity("omega") -> 969;
entity("thetasym") -> 977;
entity("upsih") -> 978;
entity("piv") -> 982;
entity("bull") -> 8226;
entity("hellip") -> 8230;
entity("prime") -> 8242;
entity("Prime") -> 8243;
entity("oline") -> 8254;
entity("frasl") -> 8260;
entity("weierp") -> 8472;
entity("image") -> 8465;
entity("real") -> 8476;
entity("trade") -> 8482;
entity("alefsym") -> 8501;
entity("larr") -> 8592;
entity("uarr") -> 8593;
entity("rarr") -> 8594;
entity("darr") -> 8595;
entity("harr") -> 8596;
entity("crarr") -> 8629;
entity("lArr") -> 8656;
entity("uArr") -> 8657;
entity("rArr") -> 8658;
entity("dArr") -> 8659;
entity("hArr") -> 8660;
entity("forall") -> 8704;
entity("part") -> 8706;
entity("exist") -> 8707;
entity("empty") -> 8709;
entity("nabla") -> 8711;
entity("isin") -> 8712;
entity("notin") -> 8713;
entity("ni") -> 8715;
entity("prod") -> 8719;
entity("sum") -> 8721;
entity("minus") -> 8722;
entity("lowast") -> 8727;
entity("radic") -> 8730;
entity("prop") -> 8733;
entity("infin") -> 8734;
entity("ang") -> 8736;
entity("and") -> 8743;
entity("or") -> 8744;
entity("cap") -> 8745;
entity("cup") -> 8746;
entity("int") -> 8747;
entity("there4") -> 8756;
entity("sim") -> 8764;
entity("cong") -> 8773;
entity("asymp") -> 8776;
entity("ne") -> 8800;
entity("equiv") -> 8801;
entity("le") -> 8804;
entity("ge") -> 8805;
entity("sub") -> 8834;
entity("sup") -> 8835;
entity("nsub") -> 8836;
entity("sube") -> 8838;
entity("supe") -> 8839;
entity("oplus") -> 8853;
entity("otimes") -> 8855;
entity("perp") -> 8869;
entity("sdot") -> 8901;
entity("lceil") -> 8968;
entity("rceil") -> 8969;
entity("lfloor") -> 8970;
entity("rfloor") -> 8971;
entity("lang") -> 9001;
entity("rang") -> 9002;
entity("loz") -> 9674;
entity("spades") -> 9824;
entity("clubs") -> 9827;
entity("hearts") -> 9829;
entity("diams") -> 9830;
entity("quot") -> 34;
entity("amp") -> 38;
entity("lt") -> 60;
entity("gt") -> 62;
entity("OElig") -> 338;
entity("oelig") -> 339;
entity("Scaron") -> 352;
entity("scaron") -> 353;
entity("Yuml") -> 376;
entity("circ") -> 710;
entity("tilde") -> 732;
entity("ensp") -> 8194;
entity("emsp") -> 8195;
entity("thinsp") -> 8201;
entity("zwnj") -> 8204;
entity("zwj") -> 8205;
entity("lrm") -> 8206;
entity("rlm") -> 8207;
entity("ndash") -> 8211;
entity("mdash") -> 8212;
entity("lsquo") -> 8216;
entity("rsquo") -> 8217;
entity("sbquo") -> 8218;
entity("ldquo") -> 8220;
entity("rdquo") -> 8221;
entity("bdquo") -> 8222;
entity("dagger") -> 8224;
entity("Dagger") -> 8225;
entity("permil") -> 8240;
entity("lsaquo") -> 8249;
entity("rsaquo") -> 8250;
entity("euro") -> 8364;
entity(_) -> undefined.


%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

exhaustive_entity_test() ->
    T = mochiweb_cover:clause_lookup_table(?MODULE, entity),
    [?assertEqual(V, entity(K)) || {K, V} <- T].

charref_test() ->
    1234 = charref("#1234"),
    255 = charref("#xfF"),
    255 = charref(<<"#XFf">>),
    38 = charref("amp"),
    38 = charref(<<"amp">>),
    undefined = charref("not_an_entity"),
    undefined = charref("#not_an_entity"),
    undefined = charref("#xnot_an_entity"),
    ok.

-endif.
%% @author Emad El-Haraty <emad@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc HTTP Cookie parsing and generating (RFC 2109, RFC 2965).

-module(mochiweb_cookies).
-export([parse_cookie/1, cookie/3, cookie/2]).

-define(QUOTE, $\").

-define(IS_WHITESPACE(C),
        (C =:= $\s orelse C =:= $\t orelse C =:= $\r orelse C =:= $\n)).

%% RFC 2616 separators (called tspecials in RFC 2068)
-define(IS_SEPARATOR(C),
        (C < 32 orelse
         C =:= $\s orelse C =:= $\t orelse
         C =:= $( orelse C =:= $) orelse C =:= $< orelse C =:= $> orelse
         C =:= $@ orelse C =:= $, orelse C =:= $; orelse C =:= $: orelse
         C =:= $\\ orelse C =:= $\" orelse C =:= $/ orelse
         C =:= $[ orelse C =:= $] orelse C =:= $? orelse C =:= $= orelse
         C =:= ${ orelse C =:= $})).

%% @type proplist() = [{Key::string(), Value::string()}].
%% @type header() = {Name::string(), Value::string()}.
%% @type int_seconds() = integer().

%% @spec cookie(Key::string(), Value::string()) -> header()
%% @doc Short-hand for <code>cookie(Key, Value, [])</code>.
cookie(Key, Value) ->
    cookie(Key, Value, []).

%% @spec cookie(Key::string(), Value::string(), Options::[Option]) -> header()
%% where Option = {max_age, int_seconds()} | {local_time, {date(), time()}}
%%                | {domain, string()} | {path, string()}
%%                | {secure, true | false} | {http_only, true | false}
%%
%% @doc Generate a Set-Cookie header field tuple.
cookie(Key, Value, Options) ->
    Cookie = [any_to_list(Key), "=", quote(Value), "; Version=1"],
    %% Set-Cookie:
    %%    Comment, Domain, Max-Age, Path, Secure, Version
    %% Set-Cookie2:
    %%    Comment, CommentURL, Discard, Domain, Max-Age, Path, Port, Secure,
    %%    Version
    ExpiresPart =
        case proplists:get_value(max_age, Options) of
            undefined ->
                "";
            RawAge ->
                When = case proplists:get_value(local_time, Options) of
                           undefined ->
                               calendar:local_time();
                           LocalTime ->
                               LocalTime
                       end,
                Age = case RawAge < 0 of
                          true ->
                              0;
                          false ->
                              RawAge
                      end,
                ["; Expires=", age_to_cookie_date(Age, When),
                 "; Max-Age=", quote(Age)]
        end,
    SecurePart =
        case proplists:get_value(secure, Options) of
            true ->
                "; Secure";
            _ ->
                ""
        end,
    DomainPart =
        case proplists:get_value(domain, Options) of
            undefined ->
                "";
            Domain ->
                ["; Domain=", quote(Domain)]
        end,
    PathPart =
        case proplists:get_value(path, Options) of
            undefined ->
                "";
            Path ->
                ["; Path=", quote(Path)]
        end,
    HttpOnlyPart =
        case proplists:get_value(http_only, Options) of
            true ->
                "; HttpOnly";
            _ ->
                ""
        end,
    CookieParts = [Cookie, ExpiresPart, SecurePart, DomainPart, PathPart, HttpOnlyPart],
    {"Set-Cookie", lists:flatten(CookieParts)}.


%% Every major browser incorrectly handles quoted strings in a
%% different and (worse) incompatible manner.  Instead of wasting time
%% writing redundant code for each browser, we restrict cookies to
%% only contain characters that browsers handle compatibly.
%%
%% By replacing the definition of quote with this, we generate
%% RFC-compliant cookies:
%%
%%     quote(V) ->
%%         Fun = fun(?QUOTE, Acc) -> [$\\, ?QUOTE | Acc];
%%                  (Ch, Acc) -> [Ch | Acc]
%%               end,
%%         [?QUOTE | lists:foldr(Fun, [?QUOTE], V)].

%% Convert to a string and raise an error if quoting is required.
quote(V0) ->
    V = any_to_list(V0),
    lists:all(fun(Ch) -> Ch =:= $/ orelse not ?IS_SEPARATOR(Ch) end, V)
        orelse erlang:error({cookie_quoting_required, V}),
    V.


%% Return a date in the form of: Wdy, DD-Mon-YYYY HH:MM:SS GMT
%% See also: rfc2109: 10.1.2
rfc2109_cookie_expires_date(LocalTime) ->
    {{YYYY,MM,DD},{Hour,Min,Sec}} =
        case calendar:local_time_to_universal_time_dst(LocalTime) of
            [Gmt]   -> Gmt;
            [_,Gmt] -> Gmt
        end,
    DayNumber = calendar:day_of_the_week({YYYY,MM,DD}),
    lists:flatten(
      io_lib:format("~s, ~2.2.0w-~3.s-~4.4.0w ~2.2.0w:~2.2.0w:~2.2.0w GMT",
                    [httpd_util:day(DayNumber),DD,httpd_util:month(MM),YYYY,Hour,Min,Sec])).

add_seconds(Secs, LocalTime) ->
    Greg = calendar:datetime_to_gregorian_seconds(LocalTime),
    calendar:gregorian_seconds_to_datetime(Greg + Secs).

age_to_cookie_date(Age, LocalTime) ->
    rfc2109_cookie_expires_date(add_seconds(Age, LocalTime)).

%% @spec parse_cookie(string()) -> [{K::string(), V::string()}]
%% @doc Parse the contents of a Cookie header field, ignoring cookie
%% attributes, and return a simple property list.
parse_cookie("") ->
    [];
parse_cookie(Cookie) ->
    parse_cookie(Cookie, []).

%% Internal API

parse_cookie([], Acc) ->
    lists:reverse(Acc);
parse_cookie(String, Acc) ->
    {{Token, Value}, Rest} = read_pair(String),
    Acc1 = case Token of
               "" ->
                   Acc;
               "$" ++ _ ->
                   Acc;
               _ ->
                   [{Token, Value} | Acc]
           end,
    parse_cookie(Rest, Acc1).

read_pair(String) ->
    {Token, Rest} = read_token(skip_whitespace(String)),
    {Value, Rest1} = read_value(skip_whitespace(Rest)),
    {{Token, Value}, skip_past_separator(Rest1)}.

read_value([$= | Value]) ->
    Value1 = skip_whitespace(Value),
    case Value1 of
        [?QUOTE | _] ->
            read_quoted(Value1);
        _ ->
            read_token(Value1)
    end;
read_value(String) ->
    {"", String}.

read_quoted([?QUOTE | String]) ->
    read_quoted(String, []).

read_quoted([], Acc) ->
    {lists:reverse(Acc), []};
read_quoted([?QUOTE | Rest], Acc) ->
    {lists:reverse(Acc), Rest};
read_quoted([$\\, Any | Rest], Acc) ->
    read_quoted(Rest, [Any | Acc]);
read_quoted([C | Rest], Acc) ->
    read_quoted(Rest, [C | Acc]).

skip_whitespace(String) ->
    F = fun (C) -> ?IS_WHITESPACE(C) end,
    lists:dropwhile(F, String).

read_token(String) ->
    F = fun (C) -> not ?IS_SEPARATOR(C) end,
    lists:splitwith(F, String).

skip_past_separator([]) ->
    [];
skip_past_separator([$; | Rest]) ->
    Rest;
skip_past_separator([$, | Rest]) ->
    Rest;
skip_past_separator([_ | Rest]) ->
    skip_past_separator(Rest).

any_to_list(V) when is_list(V) ->
    V;
any_to_list(V) when is_atom(V) ->
    atom_to_list(V);
any_to_list(V) when is_binary(V) ->
    binary_to_list(V);
any_to_list(V) when is_integer(V) ->
    integer_to_list(V).

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

quote_test() ->
    %% ?assertError eunit macro is not compatible with coverage module
    try quote(":wq")
    catch error:{cookie_quoting_required, ":wq"} -> ok
    end,
    ?assertEqual(
       "foo",
       quote(foo)),
    ok.

parse_cookie_test() ->
    %% RFC example
    C1 = "$Version=\"1\"; Customer=\"WILE_E_COYOTE\"; $Path=\"/acme\";
    Part_Number=\"Rocket_Launcher_0001\"; $Path=\"/acme\";
    Shipping=\"FedEx\"; $Path=\"/acme\"",
    ?assertEqual(
       [{"Customer","WILE_E_COYOTE"},
        {"Part_Number","Rocket_Launcher_0001"},
        {"Shipping","FedEx"}],
       parse_cookie(C1)),
    %% Potential edge cases
    ?assertEqual(
       [{"foo", "x"}],
       parse_cookie("foo=\"\\x\"")),
    ?assertEqual(
       [],
       parse_cookie("=")),
    ?assertEqual(
       [{"foo", ""}, {"bar", ""}],
       parse_cookie("  foo ; bar  ")),
    ?assertEqual(
       [{"foo", ""}, {"bar", ""}],
       parse_cookie("foo=;bar=")),
    ?assertEqual(
       [{"foo", "\";"}, {"bar", ""}],
       parse_cookie("foo = \"\\\";\";bar ")),
    ?assertEqual(
       [{"foo", "\";bar"}],
       parse_cookie("foo=\"\\\";bar")),
    ?assertEqual(
       [],
       parse_cookie([])),
    ?assertEqual(
       [{"foo", "bar"}, {"baz", "wibble"}],
       parse_cookie("foo=bar , baz=wibble ")),
    ok.

domain_test() ->
    ?assertEqual(
       {"Set-Cookie",
        "Customer=WILE_E_COYOTE; "
        "Version=1; "
        "Domain=acme.com; "
        "HttpOnly"},
       cookie("Customer", "WILE_E_COYOTE",
              [{http_only, true}, {domain, "acme.com"}])),
    ok.

local_time_test() ->
    {"Set-Cookie", S} = cookie("Customer", "WILE_E_COYOTE",
                               [{max_age, 111}, {secure, true}]),
    ?assertMatch(
       ["Customer=WILE_E_COYOTE",
        " Version=1",
        " Expires=" ++ _,
        " Max-Age=111",
        " Secure"],
       string:tokens(S, ";")),
    ok.

cookie_test() ->
    C1 = {"Set-Cookie",
          "Customer=WILE_E_COYOTE; "
          "Version=1; "
          "Path=/acme"},
    C1 = cookie("Customer", "WILE_E_COYOTE", [{path, "/acme"}]),
    C1 = cookie("Customer", "WILE_E_COYOTE",
                [{path, "/acme"}, {badoption, "negatory"}]),
    C1 = cookie('Customer', 'WILE_E_COYOTE', [{path, '/acme'}]),
    C1 = cookie(<<"Customer">>, <<"WILE_E_COYOTE">>, [{path, <<"/acme">>}]),

    {"Set-Cookie","=NoKey; Version=1"} = cookie("", "NoKey", []),
    {"Set-Cookie","=NoKey; Version=1"} = cookie("", "NoKey"),
    LocalTime = calendar:universal_time_to_local_time({{2007, 5, 15}, {13, 45, 33}}),
    C2 = {"Set-Cookie",
          "Customer=WILE_E_COYOTE; "
          "Version=1; "
          "Expires=Tue, 15-May-2007 13:45:33 GMT; "
          "Max-Age=0"},
    C2 = cookie("Customer", "WILE_E_COYOTE",
                [{max_age, -111}, {local_time, LocalTime}]),
    C3 = {"Set-Cookie",
          "Customer=WILE_E_COYOTE; "
          "Version=1; "
          "Expires=Wed, 16-May-2007 13:45:50 GMT; "
          "Max-Age=86417"},
    C3 = cookie("Customer", "WILE_E_COYOTE",
                [{max_age, 86417}, {local_time, LocalTime}]),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2010 Mochi Media, Inc.

%% @doc Workarounds for various cover deficiencies.
-module(mochiweb_cover).
-export([get_beam/1, get_abstract_code/1,
         get_clauses/2, clause_lookup_table/1]).
-export([clause_lookup_table/2]).

%% Internal

get_beam(Module) ->
    {Module, Beam, _Path} = code:get_object_code(Module),
    Beam.

get_abstract_code(Beam) ->
    {ok, {_Module,
          [{abstract_code,
            {raw_abstract_v1, L}}]}} = beam_lib:chunks(Beam, [abstract_code]),
    L.

get_clauses(Function, Code) ->
    [L] = [Clauses || {function, _, FName, _, Clauses}
                          <- Code, FName =:= Function],
    L.

clause_lookup_table(Module, Function) ->
    clause_lookup_table(
      get_clauses(Function,
                  get_abstract_code(get_beam(Module)))).

clause_lookup_table(Clauses) ->
    lists:foldr(fun clause_fold/2, [], Clauses).

clause_fold({clause, _,
             [InTerm],
             _Guards=[],
             [OutTerm]},
            Acc) ->
    try [{erl_parse:normalise(InTerm), erl_parse:normalise(OutTerm)} | Acc]
    catch error:_ -> Acc
    end;
clause_fold(_, Acc) ->
    Acc.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
foo_table(a) -> b;
foo_table("a") -> <<"b">>;
foo_table(123) -> {4, 3, 2};
foo_table([list]) -> [];
foo_table([list1, list2]) -> [list1, list2, list3];
foo_table(ignored) -> some, code, ignored;
foo_table(Var) -> Var.

foo_table_test() ->
    T = clause_lookup_table(?MODULE, foo_table),
    [?assertEqual(V, foo_table(K)) || {K, V} <- T].

clause_lookup_table_test() ->
    ?assertEqual(b, foo_table(a)),
    ?assertEqual(ignored, foo_table(ignored)),
    ?assertEqual('Var', foo_table('Var')),
    ?assertEqual(
       [{a, b},
        {"a", <<"b">>},
        {123, {4, 3, 2}},
        {[list], []},
        {[list1, list2], [list1, list2, list3]}],
       clause_lookup_table(?MODULE, foo_table)).

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Simple and stupid echo server to demo mochiweb_socket_server.

-module(mochiweb_echo).
-author('bob@mochimedia.com').
-export([start/0, stop/0, loop/1]).

stop() ->
    mochiweb_socket_server:stop(?MODULE).

start() ->
    mochiweb_socket_server:start([{link, false} | options()]).

options() ->
    [{name, ?MODULE},
     {port, 6789},
     {ip, "127.0.0.1"},
     {max, 1},
     {loop, {?MODULE, loop}}].

loop(Socket) ->
    case mochiweb_socket:recv(Socket, 0, 30000) of
        {ok, Data} ->
            case mochiweb_socket:send(Socket, Data) of
                ok ->
                    loop(Socket);
                _ ->
                    exit(normal)
            end;
        _Other ->
            exit(normal)
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Start and stop the MochiWeb server.

-module(mochiweb).
-author('bob@mochimedia.com').

-export([new_request/1, new_response/1]).
-export([all_loaded/0, all_loaded/1, reload/0]).
-export([ensure_started/1]).

reload() ->
    [c:l(Module) || Module <- all_loaded()].

all_loaded() ->
    all_loaded(filename:dirname(code:which(?MODULE))).

all_loaded(Base) when is_atom(Base) ->
    [];
all_loaded(Base) ->
    FullBase = Base ++ "/",
    F = fun ({_Module, Loaded}, Acc) when is_atom(Loaded) ->
                Acc;
            ({Module, Loaded}, Acc) ->
                case lists:prefix(FullBase, Loaded) of
                    true ->
                        [Module | Acc];
                    false ->
                        Acc
                end
        end,
    lists:foldl(F, [], code:all_loaded()).


%% @spec new_request({Socket, Request, Headers}) -> MochiWebRequest
%% @doc Return a mochiweb_request data structure.
new_request({Socket, {Method, {abs_path, Uri}, Version}, Headers}) ->
    mochiweb_request:new(Socket,
                         Method,
                         Uri,
                         Version,
                         mochiweb_headers:make(Headers));
% this case probably doesn't "exist".
new_request({Socket, {Method, {absoluteURI, _Protocol, _Host, _Port, Uri},
                      Version}, Headers}) ->
    mochiweb_request:new(Socket,
                         Method,
                         Uri,
                         Version,
                         mochiweb_headers:make(Headers));
%% Request-URI is "*"
%% From http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.1.2
new_request({Socket, {Method, '*'=Uri, Version}, Headers}) ->
    mochiweb_request:new(Socket,
                         Method,
                         Uri,
                         Version,
                         mochiweb_headers:make(Headers)).

%% @spec new_response({Request, integer(), Headers}) -> MochiWebResponse
%% @doc Return a mochiweb_response data structure.
new_response({Request, Code, Headers}) ->
    mochiweb_response:new(Request,
                          Code,
                          mochiweb_headers:make(Headers)).

%% @spec ensure_started(App::atom()) -> ok
%% @doc Start the given App if it has not been started already.
ensure_started(App) ->
    case application:start(App) of
        ok ->
            ok;
        {error, {already_started, App}} ->
            ok
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-record(treq, {path, body= <<>>, xreply= <<>>}).

ssl_cert_opts() ->
    EbinDir = filename:dirname(code:which(?MODULE)),
    CertDir = filename:join([EbinDir, "..", "support", "test-materials"]),
    CertFile = filename:join(CertDir, "test_ssl_cert.pem"),
    KeyFile = filename:join(CertDir, "test_ssl_key.pem"),
    [{certfile, CertFile}, {keyfile, KeyFile}].

with_server(Transport, ServerFun, ClientFun) ->
    ServerOpts0 = [{ip, "127.0.0.1"}, {port, 0}, {loop, ServerFun}],
    ServerOpts = case Transport of
        plain ->
            ServerOpts0;
        ssl ->
            ServerOpts0 ++ [{ssl, true}, {ssl_opts, ssl_cert_opts()}]
    end,
    {ok, Server} = mochiweb_http:start_link(ServerOpts),
    Port = mochiweb_socket_server:get(Server, port),
    Res = (catch ClientFun(Transport, Port)),
    mochiweb_http:stop(Server),
    Res.

request_test() ->
    R = mochiweb_request:new(z, z, "/foo/bar/baz%20wibble+quux?qs=2", z, []),
    "/foo/bar/baz wibble quux" = R:get(path),
    ok.

-define(LARGE_TIMEOUT, 60).

single_http_GET_test() ->
    do_GET(plain, 1).

single_https_GET_test() ->
    do_GET(ssl, 1).

multiple_http_GET_test() ->
    do_GET(plain, 3).

multiple_https_GET_test() ->
    do_GET(ssl, 3).

hundred_http_GET_test_() -> % note the underscore
    {timeout, ?LARGE_TIMEOUT,
     fun() -> ?assertEqual(ok, do_GET(plain,100)) end}.

hundred_https_GET_test_() -> % note the underscore
    {timeout, ?LARGE_TIMEOUT,
     fun() -> ?assertEqual(ok, do_GET(ssl,100)) end}.

single_128_http_POST_test() ->
    do_POST(plain, 128, 1).

single_128_https_POST_test() ->
    do_POST(ssl, 128, 1).

single_2k_http_POST_test() ->
    do_POST(plain, 2048, 1).

single_2k_https_POST_test() ->
    do_POST(ssl, 2048, 1).

single_100k_http_POST_test() ->
    do_POST(plain, 102400, 1).

single_100k_https_POST_test() ->
    do_POST(ssl, 102400, 1).

multiple_100k_http_POST_test() ->
    do_POST(plain, 102400, 3).

multiple_100K_https_POST_test() ->
    do_POST(ssl, 102400, 3).

hundred_128_http_POST_test_() -> % note the underscore
    {timeout, ?LARGE_TIMEOUT,
     fun() -> ?assertEqual(ok, do_POST(plain, 128, 100)) end}.

hundred_128_https_POST_test_() -> % note the underscore
    {timeout, ?LARGE_TIMEOUT,
     fun() -> ?assertEqual(ok, do_POST(ssl, 128, 100)) end}.

do_GET(Transport, Times) ->
    PathPrefix = "/whatever/",
    ReplyPrefix = "You requested: ",
    ServerFun = fun (Req) ->
                        Reply = ReplyPrefix ++ Req:get(path),
                        Req:ok({"text/plain", Reply})
                end,
    TestReqs = [begin
                    Path = PathPrefix ++ integer_to_list(N),
                    ExpectedReply = list_to_binary(ReplyPrefix ++ Path),
                    #treq{path=Path, xreply=ExpectedReply}
                end || N <- lists:seq(1, Times)],
    ClientFun = new_client_fun('GET', TestReqs),
    ok = with_server(Transport, ServerFun, ClientFun),
    ok.

do_POST(Transport, Size, Times) ->
    ServerFun = fun (Req) ->
                        Body = Req:recv_body(),
                        Headers = [{"Content-Type", "application/octet-stream"}],
                        Req:respond({201, Headers, Body})
                end,
    TestReqs = [begin
                    Path = "/stuff/" ++ integer_to_list(N),
                    Body = crypto:rand_bytes(Size),
                    #treq{path=Path, body=Body, xreply=Body}
                end || N <- lists:seq(1, Times)],
    ClientFun = new_client_fun('POST', TestReqs),
    ok = with_server(Transport, ServerFun, ClientFun),
    ok.

new_client_fun(Method, TestReqs) ->
    fun (Transport, Port) ->
            client_request(Transport, Port, Method, TestReqs)
    end.

client_request(Transport, Port, Method, TestReqs) ->
    Opts = [binary, {active, false}, {packet, http}],
    SockFun = case Transport of
        plain ->
            {ok, Socket} = gen_tcp:connect("127.0.0.1", Port, Opts),
            fun (recv) ->
                    gen_tcp:recv(Socket, 0);
                ({recv, Length}) ->
                    gen_tcp:recv(Socket, Length);
                ({send, Data}) ->
                    gen_tcp:send(Socket, Data);
                ({setopts, L}) ->
                    inet:setopts(Socket, L)
            end;
        ssl ->
            {ok, Socket} = ssl:connect("127.0.0.1", Port, [{ssl_imp, new} | Opts]),
            fun (recv) ->
                    ssl:recv(Socket, 0);
                ({recv, Length}) ->
                    ssl:recv(Socket, Length);
                ({send, Data}) ->
                    ssl:send(Socket, Data);
                ({setopts, L}) ->
                    ssl:setopts(Socket, L)
            end
    end,
    client_request(SockFun, Method, TestReqs).

client_request(SockFun, _Method, []) ->
    {the_end, {error, closed}} = {the_end, SockFun(recv)},
    ok;
client_request(SockFun, Method,
               [#treq{path=Path, body=Body, xreply=ExReply} | Rest]) ->
    Request = [atom_to_list(Method), " ", Path, " HTTP/1.1\r\n",
               client_headers(Body, Rest =:= []),
               "\r\n",
               Body],
    ok = SockFun({send, Request}),
    case Method of
        'GET' ->
            {ok, {http_response, {1,1}, 200, "OK"}} = SockFun(recv);
        'POST' ->
            {ok, {http_response, {1,1}, 201, "Created"}} = SockFun(recv)
    end,
    ok = SockFun({setopts, [{packet, httph}]}),
    {ok, {http_header, _, 'Server', _, "MochiWeb" ++ _}} = SockFun(recv),
    {ok, {http_header, _, 'Date', _, _}} = SockFun(recv),
    {ok, {http_header, _, 'Content-Type', _, _}} = SockFun(recv),
    {ok, {http_header, _, 'Content-Length', _, ConLenStr}} = SockFun(recv),
    ContentLength = list_to_integer(ConLenStr),
    {ok, http_eoh} = SockFun(recv),
    ok = SockFun({setopts, [{packet, raw}]}),
    {payload, ExReply} = {payload, drain_reply(SockFun, ContentLength, <<>>)},
    ok = SockFun({setopts, [{packet, http}]}),
    client_request(SockFun, Method, Rest).

client_headers(Body, IsLastRequest) ->
    ["Host: localhost\r\n",
     case Body of
        <<>> ->
            "";
        _ ->
            ["Content-Type: application/octet-stream\r\n",
             "Content-Length: ", integer_to_list(byte_size(Body)), "\r\n"]
     end,
     case IsLastRequest of
         true ->
             "Connection: close\r\n";
         false ->
             ""
     end].

drain_reply(_SockFun, 0, Acc) ->
    Acc;
drain_reply(SockFun, Length, Acc) ->
    Sz = erlang:min(Length, 1024),
    {ok, B} = SockFun({recv, Sz}),
    drain_reply(SockFun, Length - Sz, <<Acc/bytes, B/bytes>>).

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Case preserving (but case insensitive) HTTP Header dictionary.

-module(mochiweb_headers).
-author('bob@mochimedia.com').
-export([empty/0, from_list/1, insert/3, enter/3, get_value/2, lookup/2]).
-export([delete_any/2, get_primary_value/2]).
-export([default/3, enter_from_list/2, default_from_list/2]).
-export([to_list/1, make/1]).
-export([from_binary/1]).

%% @type headers().
%% @type key() = atom() | binary() | string().
%% @type value() = atom() | binary() | string() | integer().

%% @spec empty() -> headers()
%% @doc Create an empty headers structure.
empty() ->
    gb_trees:empty().

%% @spec make(headers() | [{key(), value()}]) -> headers()
%% @doc Construct a headers() from the given list.
make(L) when is_list(L) ->
    from_list(L);
%% assume a non-list is already mochiweb_headers.
make(T) ->
    T.

%% @spec from_binary(iolist()) -> headers()
%% @doc Transforms a raw HTTP header into a mochiweb headers structure.
%%
%%      The given raw HTTP header can be one of the following:
%%
%%      1) A string or a binary representing a full HTTP header ending with
%%         double CRLF.
%%         Examples:
%%         ```
%%         "Content-Length: 47\r\nContent-Type: text/plain\r\n\r\n"
%%         <<"Content-Length: 47\r\nContent-Type: text/plain\r\n\r\n">>'''
%%
%%      2) A list of binaries or strings where each element represents a raw
%%         HTTP header line ending with a single CRLF.
%%         Examples:
%%         ```
%%         [<<"Content-Length: 47\r\n">>, <<"Content-Type: text/plain\r\n">>]
%%         ["Content-Length: 47\r\n", "Content-Type: text/plain\r\n"]
%%         ["Content-Length: 47\r\n", <<"Content-Type: text/plain\r\n">>]'''
%%
from_binary(RawHttpHeader) when is_binary(RawHttpHeader) ->
    from_binary(RawHttpHeader, []);
from_binary(RawHttpHeaderList) ->
    from_binary(list_to_binary([RawHttpHeaderList, "\r\n"])).

from_binary(RawHttpHeader, Acc) ->
    case erlang:decode_packet(httph, RawHttpHeader, []) of
        {ok, {http_header, _, H, _, V}, Rest} ->
            from_binary(Rest, [{H, V} | Acc]);
        _ ->
            make(Acc)
    end.

%% @spec from_list([{key(), value()}]) -> headers()
%% @doc Construct a headers() from the given list.
from_list(List) ->
    lists:foldl(fun ({K, V}, T) -> insert(K, V, T) end, empty(), List).

%% @spec enter_from_list([{key(), value()}], headers()) -> headers()
%% @doc Insert pairs into the headers, replace any values for existing keys.
enter_from_list(List, T) ->
    lists:foldl(fun ({K, V}, T1) -> enter(K, V, T1) end, T, List).

%% @spec default_from_list([{key(), value()}], headers()) -> headers()
%% @doc Insert pairs into the headers for keys that do not already exist.
default_from_list(List, T) ->
    lists:foldl(fun ({K, V}, T1) -> default(K, V, T1) end, T, List).

%% @spec to_list(headers()) -> [{key(), string()}]
%% @doc Return the contents of the headers. The keys will be the exact key
%%      that was first inserted (e.g. may be an atom or binary, case is
%%      preserved).
to_list(T) ->
    F = fun ({K, {array, L}}, Acc) ->
                L1 = lists:reverse(L),
                lists:foldl(fun (V, Acc1) -> [{K, V} | Acc1] end, Acc, L1);
            (Pair, Acc) ->
                [Pair | Acc]
        end,
    lists:reverse(lists:foldl(F, [], gb_trees:values(T))).

%% @spec get_value(key(), headers()) -> string() | undefined
%% @doc Return the value of the given header using a case insensitive search.
%%      undefined will be returned for keys that are not present.
get_value(K, T) ->
    case lookup(K, T) of
        {value, {_, V}} ->
            expand(V);
        none ->
            undefined
    end.

%% @spec get_primary_value(key(), headers()) -> string() | undefined
%% @doc Return the value of the given header up to the first semicolon using
%%      a case insensitive search. undefined will be returned for keys
%%      that are not present.
get_primary_value(K, T) ->
    case get_value(K, T) of
        undefined ->
            undefined;
        V ->
            lists:takewhile(fun (C) -> C =/= $; end, V)
    end.

%% @spec lookup(key(), headers()) -> {value, {key(), string()}} | none
%% @doc Return the case preserved key and value for the given header using
%%      a case insensitive search. none will be returned for keys that are
%%      not present.
lookup(K, T) ->
    case gb_trees:lookup(normalize(K), T) of
        {value, {K0, V}} ->
            {value, {K0, expand(V)}};
        none ->
            none
    end.

%% @spec default(key(), value(), headers()) -> headers()
%% @doc Insert the pair into the headers if it does not already exist.
default(K, V, T) ->
    K1 = normalize(K),
    V1 = any_to_list(V),
    try gb_trees:insert(K1, {K, V1}, T)
    catch
        error:{key_exists, _} ->
            T
    end.

%% @spec enter(key(), value(), headers()) -> headers()
%% @doc Insert the pair into the headers, replacing any pre-existing key.
enter(K, V, T) ->
    K1 = normalize(K),
    V1 = any_to_list(V),
    gb_trees:enter(K1, {K, V1}, T).

%% @spec insert(key(), value(), headers()) -> headers()
%% @doc Insert the pair into the headers, merging with any pre-existing key.
%%      A merge is done with Value = V0 ++ ", " ++ V1.
insert(K, V, T) ->
    K1 = normalize(K),
    V1 = any_to_list(V),
    try gb_trees:insert(K1, {K, V1}, T)
    catch
        error:{key_exists, _} ->
            {K0, V0} = gb_trees:get(K1, T),
            V2 = merge(K1, V1, V0),
            gb_trees:update(K1, {K0, V2}, T)
    end.

%% @spec delete_any(key(), headers()) -> headers()
%% @doc Delete the header corresponding to key if it is present.
delete_any(K, T) ->
    K1 = normalize(K),
    gb_trees:delete_any(K1, T).

%% Internal API

expand({array, L}) ->
    mochiweb_util:join(lists:reverse(L), ", ");
expand(V) ->
    V.

merge("set-cookie", V1, {array, L}) ->
    {array, [V1 | L]};
merge("set-cookie", V1, V0) ->
    {array, [V1, V0]};
merge(_, V1, V0) ->
    V0 ++ ", " ++ V1.

normalize(K) when is_list(K) ->
    string:to_lower(K);
normalize(K) when is_atom(K) ->
    normalize(atom_to_list(K));
normalize(K) when is_binary(K) ->
    normalize(binary_to_list(K)).

any_to_list(V) when is_list(V) ->
    V;
any_to_list(V) when is_atom(V) ->
    atom_to_list(V);
any_to_list(V) when is_binary(V) ->
    binary_to_list(V);
any_to_list(V) when is_integer(V) ->
    integer_to_list(V).

%%
%% Tests.
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

make_test() ->
    Identity = make([{hdr, foo}]),
    ?assertEqual(
       Identity,
       make(Identity)).

enter_from_list_test() ->
    H = make([{hdr, foo}]),
    ?assertEqual(
       [{baz, "wibble"}, {hdr, "foo"}],
       to_list(enter_from_list([{baz, wibble}], H))),
    ?assertEqual(
       [{hdr, "bar"}],
       to_list(enter_from_list([{hdr, bar}], H))),
    ok.

default_from_list_test() ->
    H = make([{hdr, foo}]),
    ?assertEqual(
       [{baz, "wibble"}, {hdr, "foo"}],
       to_list(default_from_list([{baz, wibble}], H))),
    ?assertEqual(
       [{hdr, "foo"}],
       to_list(default_from_list([{hdr, bar}], H))),
    ok.

get_primary_value_test() ->
    H = make([{hdr, foo}, {baz, <<"wibble;taco">>}]),
    ?assertEqual(
       "foo",
       get_primary_value(hdr, H)),
    ?assertEqual(
       undefined,
       get_primary_value(bar, H)),
    ?assertEqual(
       "wibble",
       get_primary_value(<<"baz">>, H)),
    ok.

set_cookie_test() ->
    H = make([{"set-cookie", foo}, {"set-cookie", bar}, {"set-cookie", baz}]),
    ?assertEqual(
       [{"set-cookie", "foo"}, {"set-cookie", "bar"}, {"set-cookie", "baz"}],
       to_list(H)),
    ok.

headers_test() ->
    H = ?MODULE:make([{hdr, foo}, {"Hdr", "bar"}, {'Hdr', 2}]),
    [{hdr, "foo, bar, 2"}] = ?MODULE:to_list(H),
    H1 = ?MODULE:insert(taco, grande, H),
    [{hdr, "foo, bar, 2"}, {taco, "grande"}] = ?MODULE:to_list(H1),
    H2 = ?MODULE:make([{"Set-Cookie", "foo"}]),
    [{"Set-Cookie", "foo"}] = ?MODULE:to_list(H2),
    H3 = ?MODULE:insert("Set-Cookie", "bar", H2),
    [{"Set-Cookie", "foo"}, {"Set-Cookie", "bar"}] = ?MODULE:to_list(H3),
    "foo, bar" = ?MODULE:get_value("set-cookie", H3),
    {value, {"Set-Cookie", "foo, bar"}} = ?MODULE:lookup("set-cookie", H3),
    undefined = ?MODULE:get_value("shibby", H3),
    none = ?MODULE:lookup("shibby", H3),
    H4 = ?MODULE:insert("content-type",
                        "application/x-www-form-urlencoded; charset=utf8",
                        H3),
    "application/x-www-form-urlencoded" = ?MODULE:get_primary_value(
                                             "content-type", H4),
    H4 = ?MODULE:delete_any("nonexistent-header", H4),
    H3 = ?MODULE:delete_any("content-type", H4),
    HB = <<"Content-Length: 47\r\nContent-Type: text/plain\r\n\r\n">>,
    H_HB = ?MODULE:from_binary(HB),
    H_HB = ?MODULE:from_binary(binary_to_list(HB)),
    "47" = ?MODULE:get_value("Content-Length", H_HB),
    "text/plain" = ?MODULE:get_value("Content-Type", H_HB),
    L_H_HB = ?MODULE:to_list(H_HB),
    2 = length(L_H_HB),
    true = lists:member({'Content-Length', "47"}, L_H_HB),
    true = lists:member({'Content-Type', "text/plain"}, L_H_HB),
    HL = [ <<"Content-Length: 47\r\n">>, <<"Content-Type: text/plain\r\n">> ],
    HL2 = [ "Content-Length: 47\r\n", <<"Content-Type: text/plain\r\n">> ],
    HL3 = [ <<"Content-Length: 47\r\n">>, "Content-Type: text/plain\r\n" ],
    H_HL = ?MODULE:from_binary(HL),
    H_HL = ?MODULE:from_binary(HL2),
    H_HL = ?MODULE:from_binary(HL3),
    "47" = ?MODULE:get_value("Content-Length", H_HL),
    "text/plain" = ?MODULE:get_value("Content-Type", H_HL),
    L_H_HL = ?MODULE:to_list(H_HL),
    2 = length(L_H_HL),
    true = lists:member({'Content-Length', "47"}, L_H_HL),
    true = lists:member({'Content-Type', "text/plain"}, L_H_HL),
    [] = ?MODULE:to_list(?MODULE:from_binary(<<>>)),
    [] = ?MODULE:to_list(?MODULE:from_binary(<<"">>)),
    [] = ?MODULE:to_list(?MODULE:from_binary(<<"\r\n">>)),
    [] = ?MODULE:to_list(?MODULE:from_binary(<<"\r\n\r\n">>)),
    [] = ?MODULE:to_list(?MODULE:from_binary("")),
    [] = ?MODULE:to_list(?MODULE:from_binary([<<>>])),
    [] = ?MODULE:to_list(?MODULE:from_binary([<<"">>])),
    [] = ?MODULE:to_list(?MODULE:from_binary([<<"\r\n">>])),
    [] = ?MODULE:to_list(?MODULE:from_binary([<<"\r\n\r\n">>])),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Loosely tokenizes and generates parse trees for HTML 4.
-module(mochiweb_html).
-export([tokens/1, parse/1, parse_tokens/1, to_tokens/1, escape/1,
         escape_attr/1, to_html/1]).

%% This is a macro to placate syntax highlighters..
-define(QUOTE, $\").
-define(SQUOTE, $\').
-define(ADV_COL(S, N),
        S#decoder{column=N+S#decoder.column,
                  offset=N+S#decoder.offset}).
-define(INC_COL(S),
        S#decoder{column=1+S#decoder.column,
                  offset=1+S#decoder.offset}).
-define(INC_LINE(S),
        S#decoder{column=1,
                  line=1+S#decoder.line,
                  offset=1+S#decoder.offset}).
-define(INC_CHAR(S, C),
        case C of
            $\n ->
                S#decoder{column=1,
                          line=1+S#decoder.line,
                          offset=1+S#decoder.offset};
            _ ->
                S#decoder{column=1+S#decoder.column,
                          offset=1+S#decoder.offset}
        end).

-define(IS_WHITESPACE(C),
        (C =:= $\s orelse C =:= $\t orelse C =:= $\r orelse C =:= $\n)).
-define(IS_LITERAL_SAFE(C),
        ((C >= $A andalso C =< $Z) orelse (C >= $a andalso C =< $z)
         orelse (C >= $0 andalso C =< $9))).
-define(PROBABLE_CLOSE(C),
        (C =:= $> orelse ?IS_WHITESPACE(C))).

-record(decoder, {line=1,
                  column=1,
                  offset=0}).

%% @type html_node() = {string(), [html_attr()], [html_node() | string()]}
%% @type html_attr() = {string(), string()}
%% @type html_token() = html_data() | start_tag() | end_tag() | inline_html() | html_comment() | html_doctype()
%% @type html_data() = {data, string(), Whitespace::boolean()}
%% @type start_tag() = {start_tag, Name, [html_attr()], Singleton::boolean()}
%% @type end_tag() = {end_tag, Name}
%% @type html_comment() = {comment, Comment}
%% @type html_doctype() = {doctype, [Doctype]}
%% @type inline_html() = {'=', iolist()}

%% External API.

%% @spec parse(string() | binary()) -> html_node()
%% @doc tokenize and then transform the token stream into a HTML tree.
parse(Input) ->
    parse_tokens(tokens(Input)).

%% @spec parse_tokens([html_token()]) -> html_node()
%% @doc Transform the output of tokens(Doc) into a HTML tree.
parse_tokens(Tokens) when is_list(Tokens) ->
    %% Skip over doctype, processing instructions
    F = fun (X) ->
                case X of
                    {start_tag, _, _, false} ->
                        false;
                    _ ->
                        true
                end
        end,
    [{start_tag, Tag, Attrs, false} | Rest] = lists:dropwhile(F, Tokens),
    {Tree, _} = tree(Rest, [norm({Tag, Attrs})]),
    Tree.

%% @spec tokens(StringOrBinary) -> [html_token()]
%% @doc Transform the input UTF-8 HTML into a token stream.
tokens(Input) ->
    tokens(iolist_to_binary(Input), #decoder{}, []).

%% @spec to_tokens(html_node()) -> [html_token()]
%% @doc Convert a html_node() tree to a list of tokens.
to_tokens({Tag0}) ->
    to_tokens({Tag0, [], []});
to_tokens(T={'=', _}) ->
    [T];
to_tokens(T={doctype, _}) ->
    [T];
to_tokens(T={comment, _}) ->
    [T];
to_tokens({Tag0, Acc}) ->
    %% This is only allowed in sub-tags: {p, [{"class", "foo"}]}
    to_tokens({Tag0, [], Acc});
to_tokens({Tag0, Attrs, Acc}) ->
    Tag = to_tag(Tag0),
    to_tokens([{Tag, Acc}], [{start_tag, Tag, Attrs, is_singleton(Tag)}]).

%% @spec to_html([html_token()] | html_node()) -> iolist()
%% @doc Convert a list of html_token() to a HTML document.
to_html(Node) when is_tuple(Node) ->
    to_html(to_tokens(Node));
to_html(Tokens) when is_list(Tokens) ->
    to_html(Tokens, []).

%% @spec escape(string() | atom() | binary()) -> binary()
%% @doc Escape a string such that it's safe for HTML (amp; lt; gt;).
escape(B) when is_binary(B) ->
    escape(binary_to_list(B), []);
escape(A) when is_atom(A) ->
    escape(atom_to_list(A), []);
escape(S) when is_list(S) ->
    escape(S, []).

%% @spec escape_attr(string() | binary() | atom() | integer() | float()) -> binary()
%% @doc Escape a string such that it's safe for HTML attrs
%%      (amp; lt; gt; quot;).
escape_attr(B) when is_binary(B) ->
    escape_attr(binary_to_list(B), []);
escape_attr(A) when is_atom(A) ->
    escape_attr(atom_to_list(A), []);
escape_attr(S) when is_list(S) ->
    escape_attr(S, []);
escape_attr(I) when is_integer(I) ->
    escape_attr(integer_to_list(I), []);
escape_attr(F) when is_float(F) ->
    escape_attr(mochinum:digits(F), []).

to_html([], Acc) ->
    lists:reverse(Acc);
to_html([{'=', Content} | Rest], Acc) ->
    to_html(Rest, [Content | Acc]);
to_html([{pi, Bin} | Rest], Acc) ->
    Open = [<<"<?">>,
            Bin,
            <<"?>">>],
    to_html(Rest, [Open | Acc]);
to_html([{pi, Tag, Attrs} | Rest], Acc) ->
    Open = [<<"<?">>,
            Tag,
            attrs_to_html(Attrs, []),
            <<"?>">>],
    to_html(Rest, [Open | Acc]);
to_html([{comment, Comment} | Rest], Acc) ->
    to_html(Rest, [[<<"<!--">>, Comment, <<"-->">>] | Acc]);
to_html([{doctype, Parts} | Rest], Acc) ->
    Inside = doctype_to_html(Parts, Acc),
    to_html(Rest, [[<<"<!DOCTYPE">>, Inside, <<">">>] | Acc]);
to_html([{data, Data, _Whitespace} | Rest], Acc) ->
    to_html(Rest, [escape(Data) | Acc]);
to_html([{start_tag, Tag, Attrs, Singleton} | Rest], Acc) ->
    Open = [<<"<">>,
            Tag,
            attrs_to_html(Attrs, []),
            case Singleton of
                true -> <<" />">>;
                false -> <<">">>
            end],
    to_html(Rest, [Open | Acc]);
to_html([{end_tag, Tag} | Rest], Acc) ->
    to_html(Rest, [[<<"</">>, Tag, <<">">>] | Acc]).

doctype_to_html([], Acc) ->
    lists:reverse(Acc);
doctype_to_html([Word | Rest], Acc) ->
    case lists:all(fun (C) -> ?IS_LITERAL_SAFE(C) end,
                   binary_to_list(iolist_to_binary(Word))) of
        true ->
            doctype_to_html(Rest, [[<<" ">>, Word] | Acc]);
        false ->
            doctype_to_html(Rest, [[<<" \"">>, escape_attr(Word), ?QUOTE] | Acc])
    end.

attrs_to_html([], Acc) ->
    lists:reverse(Acc);
attrs_to_html([{K, V} | Rest], Acc) ->
    attrs_to_html(Rest,
                  [[<<" ">>, escape(K), <<"=\"">>,
                    escape_attr(V), <<"\"">>] | Acc]).

escape([], Acc) ->
    list_to_binary(lists:reverse(Acc));
escape("<" ++ Rest, Acc) ->
    escape(Rest, lists:reverse("&lt;", Acc));
escape(">" ++ Rest, Acc) ->
    escape(Rest, lists:reverse("&gt;", Acc));
escape("&" ++ Rest, Acc) ->
    escape(Rest, lists:reverse("&amp;", Acc));
escape([C | Rest], Acc) ->
    escape(Rest, [C | Acc]).

escape_attr([], Acc) ->
    list_to_binary(lists:reverse(Acc));
escape_attr("<" ++ Rest, Acc) ->
    escape_attr(Rest, lists:reverse("&lt;", Acc));
escape_attr(">" ++ Rest, Acc) ->
    escape_attr(Rest, lists:reverse("&gt;", Acc));
escape_attr("&" ++ Rest, Acc) ->
    escape_attr(Rest, lists:reverse("&amp;", Acc));
escape_attr([?QUOTE | Rest], Acc) ->
    escape_attr(Rest, lists:reverse("&quot;", Acc));
escape_attr([C | Rest], Acc) ->
    escape_attr(Rest, [C | Acc]).

to_tag(A) when is_atom(A) ->
    norm(atom_to_list(A));
to_tag(L) ->
    norm(L).

to_tokens([], Acc) ->
    lists:reverse(Acc);
to_tokens([{Tag, []} | Rest], Acc) ->
    to_tokens(Rest, [{end_tag, to_tag(Tag)} | Acc]);
to_tokens([{Tag0, [{T0} | R1]} | Rest], Acc) ->
    %% Allow {br}
    to_tokens([{Tag0, [{T0, [], []} | R1]} | Rest], Acc);
to_tokens([{Tag0, [T0={'=', _C0} | R1]} | Rest], Acc) ->
    %% Allow {'=', iolist()}
    to_tokens([{Tag0, R1} | Rest], [T0 | Acc]);
to_tokens([{Tag0, [T0={comment, _C0} | R1]} | Rest], Acc) ->
    %% Allow {comment, iolist()}
    to_tokens([{Tag0, R1} | Rest], [T0 | Acc]);
to_tokens([{Tag0, [T0={pi, _S0} | R1]} | Rest], Acc) ->
    %% Allow {pi, binary()}
    to_tokens([{Tag0, R1} | Rest], [T0 | Acc]);
to_tokens([{Tag0, [T0={pi, _S0, _A0} | R1]} | Rest], Acc) ->
    %% Allow {pi, binary(), list()}
    to_tokens([{Tag0, R1} | Rest], [T0 | Acc]);
to_tokens([{Tag0, [{T0, A0=[{_, _} | _]} | R1]} | Rest], Acc) ->
    %% Allow {p, [{"class", "foo"}]}
    to_tokens([{Tag0, [{T0, A0, []} | R1]} | Rest], Acc);
to_tokens([{Tag0, [{T0, C0} | R1]} | Rest], Acc) ->
    %% Allow {p, "content"} and {p, <<"content">>}
    to_tokens([{Tag0, [{T0, [], C0} | R1]} | Rest], Acc);
to_tokens([{Tag0, [{T0, A1, C0} | R1]} | Rest], Acc) when is_binary(C0) ->
    %% Allow {"p", [{"class", "foo"}], <<"content">>}
    to_tokens([{Tag0, [{T0, A1, binary_to_list(C0)} | R1]} | Rest], Acc);
to_tokens([{Tag0, [{T0, A1, C0=[C | _]} | R1]} | Rest], Acc)
  when is_integer(C) ->
    %% Allow {"p", [{"class", "foo"}], "content"}
    to_tokens([{Tag0, [{T0, A1, [C0]} | R1]} | Rest], Acc);
to_tokens([{Tag0, [{T0, A1, C1} | R1]} | Rest], Acc) ->
    %% Native {"p", [{"class", "foo"}], ["content"]}
    Tag = to_tag(Tag0),
    T1 = to_tag(T0),
    case is_singleton(norm(T1)) of
        true ->
            to_tokens([{Tag, R1} | Rest], [{start_tag, T1, A1, true} | Acc]);
        false ->
            to_tokens([{T1, C1}, {Tag, R1} | Rest],
                      [{start_tag, T1, A1, false} | Acc])
    end;
to_tokens([{Tag0, [L | R1]} | Rest], Acc) when is_list(L) ->
    %% List text
    Tag = to_tag(Tag0),
    to_tokens([{Tag, R1} | Rest], [{data, iolist_to_binary(L), false} | Acc]);
to_tokens([{Tag0, [B | R1]} | Rest], Acc) when is_binary(B) ->
    %% Binary text
    Tag = to_tag(Tag0),
    to_tokens([{Tag, R1} | Rest], [{data, B, false} | Acc]).

tokens(B, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary>> ->
            lists:reverse(Acc);
        _ ->
            {Tag, S1} = tokenize(B, S),
            case parse_flag(Tag) of
                script ->
                    {Tag2, S2} = tokenize_script(B, S1),
                    tokens(B, S2, [Tag2, Tag | Acc]);
                textarea ->
                    {Tag2, S2} = tokenize_textarea(B, S1),
                    tokens(B, S2, [Tag2, Tag | Acc]);
                none ->
                    tokens(B, S1, [Tag | Acc])
            end
    end.

parse_flag({start_tag, B, _, false}) ->
    case string:to_lower(binary_to_list(B)) of
        "script" ->
            script;
        "textarea" ->
            textarea;
        _ ->
            none
    end;
parse_flag(_) ->
    none.

tokenize(B, S=#decoder{offset=O}) ->
    case B of
        <<_:O/binary, "<!--", _/binary>> ->
            tokenize_comment(B, ?ADV_COL(S, 4));
        <<_:O/binary, "<!DOCTYPE", _/binary>> ->
            tokenize_doctype(B, ?ADV_COL(S, 10));
        <<_:O/binary, "<![CDATA[", _/binary>> ->
            tokenize_cdata(B, ?ADV_COL(S, 9));
        <<_:O/binary, "<?php", _/binary>> ->
            {Body, S1} = raw_qgt(B, ?ADV_COL(S, 2)),
            {{pi, Body}, S1};
        <<_:O/binary, "<?", _/binary>> ->
            {Tag, S1} = tokenize_literal(B, ?ADV_COL(S, 2)),
            {Attrs, S2} = tokenize_attributes(B, S1),
            S3 = find_qgt(B, S2),
            {{pi, Tag, Attrs}, S3};
        <<_:O/binary, "&", _/binary>> ->
            tokenize_charref(B, ?INC_COL(S));
        <<_:O/binary, "</", _/binary>> ->
            {Tag, S1} = tokenize_literal(B, ?ADV_COL(S, 2)),
            {S2, _} = find_gt(B, S1),
            {{end_tag, Tag}, S2};
        <<_:O/binary, "<", C, _/binary>> when ?IS_WHITESPACE(C) ->
            %% This isn't really strict HTML
            {{data, Data, _Whitespace}, S1} = tokenize_data(B, ?INC_COL(S)),
            {{data, <<$<, Data/binary>>, false}, S1};
        <<_:O/binary, "<", _/binary>> ->
            {Tag, S1} = tokenize_literal(B, ?INC_COL(S)),
            {Attrs, S2} = tokenize_attributes(B, S1),
            {S3, HasSlash} = find_gt(B, S2),
            Singleton = HasSlash orelse is_singleton(Tag),
            {{start_tag, Tag, Attrs, Singleton}, S3};
        _ ->
            tokenize_data(B, S)
    end.

tree_data([{data, Data, Whitespace} | Rest], AllWhitespace, Acc) ->
    tree_data(Rest, (Whitespace andalso AllWhitespace), [Data | Acc]);
tree_data(Rest, AllWhitespace, Acc) ->
    {iolist_to_binary(lists:reverse(Acc)), AllWhitespace, Rest}.

tree([], Stack) ->
    {destack(Stack), []};
tree([{end_tag, Tag} | Rest], Stack) ->
    case destack(norm(Tag), Stack) of
        S when is_list(S) ->
            tree(Rest, S);
        Result ->
            {Result, []}
    end;
tree([{start_tag, Tag, Attrs, true} | Rest], S) ->
    tree(Rest, append_stack_child(norm({Tag, Attrs}), S));
tree([{start_tag, Tag, Attrs, false} | Rest], S) ->
    tree(Rest, stack(norm({Tag, Attrs}), S));
tree([T={pi, _Raw} | Rest], S) ->
    tree(Rest, append_stack_child(T, S));
tree([T={pi, _Tag, _Attrs} | Rest], S) ->
    tree(Rest, append_stack_child(T, S));
tree([T={comment, _Comment} | Rest], S) ->
    tree(Rest, append_stack_child(T, S));
tree(L=[{data, _Data, _Whitespace} | _], S) ->
    case tree_data(L, true, []) of
        {_, true, Rest} ->
            tree(Rest, S);
        {Data, false, Rest} ->
            tree(Rest, append_stack_child(Data, S))
    end;
tree([{doctype, _} | Rest], Stack) ->
    tree(Rest, Stack).

norm({Tag, Attrs}) ->
    {norm(Tag), [{norm(K), iolist_to_binary(V)} || {K, V} <- Attrs], []};
norm(Tag) when is_binary(Tag) ->
    Tag;
norm(Tag) ->
    list_to_binary(string:to_lower(Tag)).

stack(T1={TN, _, _}, Stack=[{TN, _, _} | _Rest])
  when TN =:= <<"li">> orelse TN =:= <<"option">> ->
    [T1 | destack(TN, Stack)];
stack(T1={TN0, _, _}, Stack=[{TN1, _, _} | _Rest])
  when (TN0 =:= <<"dd">> orelse TN0 =:= <<"dt">>) andalso
       (TN1 =:= <<"dd">> orelse TN1 =:= <<"dt">>) ->
    [T1 | destack(TN1, Stack)];
stack(T1, Stack) ->
    [T1 | Stack].

append_stack_child(StartTag, [{Name, Attrs, Acc} | Stack]) ->
    [{Name, Attrs, [StartTag | Acc]} | Stack].

destack(<<"br">>, Stack) ->
    %% This is an ugly hack to make dumb_br_test() pass,
    %% this makes it such that br can never have children.
    Stack;
destack(TagName, Stack) when is_list(Stack) ->
    F = fun (X) ->
                case X of
                    {TagName, _, _} ->
                        false;
                    _ ->
                        true
                end
        end,
    case lists:splitwith(F, Stack) of
        {_, []} ->
            %% If we're parsing something like XML we might find
            %% a <link>tag</link> that is normally a singleton
            %% in HTML but isn't here
            case {is_singleton(TagName), Stack} of
                {true, [{T0, A0, Acc0} | Post0]} ->
                    case lists:splitwith(F, Acc0) of
                        {_, []} ->
                            %% Actually was a singleton
                            Stack;
                        {Pre, [{T1, A1, Acc1} | Post1]} ->
                            [{T0, A0, [{T1, A1, Acc1 ++ lists:reverse(Pre)} | Post1]}
                             | Post0]
                    end;
                _ ->
                    %% No match, no state change
                    Stack
            end;
        {_Pre, [_T]} ->
            %% Unfurl the whole stack, we're done
            destack(Stack);
        {Pre, [T, {T0, A0, Acc0} | Post]} ->
            %% Unfurl up to the tag, then accumulate it
            [{T0, A0, [destack(Pre ++ [T]) | Acc0]} | Post]
    end.

destack([{Tag, Attrs, Acc}]) ->
    {Tag, Attrs, lists:reverse(Acc)};
destack([{T1, A1, Acc1}, {T0, A0, Acc0} | Rest]) ->
    destack([{T0, A0, [{T1, A1, lists:reverse(Acc1)} | Acc0]} | Rest]).

is_singleton(<<"br">>) -> true;
is_singleton(<<"hr">>) -> true;
is_singleton(<<"img">>) -> true;
is_singleton(<<"input">>) -> true;
is_singleton(<<"base">>) -> true;
is_singleton(<<"meta">>) -> true;
is_singleton(<<"link">>) -> true;
is_singleton(<<"area">>) -> true;
is_singleton(<<"param">>) -> true;
is_singleton(<<"col">>) -> true;
is_singleton(_) -> false.

tokenize_data(B, S=#decoder{offset=O}) ->
    tokenize_data(B, S, O, true).

tokenize_data(B, S=#decoder{offset=O}, Start, Whitespace) ->
    case B of
        <<_:O/binary, C, _/binary>> when (C =/= $< andalso C =/= $&) ->
            tokenize_data(B, ?INC_CHAR(S, C), Start,
                          (Whitespace andalso ?IS_WHITESPACE(C)));
        _ ->
            Len = O - Start,
            <<_:Start/binary, Data:Len/binary, _/binary>> = B,
            {{data, Data, Whitespace}, S}
    end.

tokenize_attributes(B, S) ->
    tokenize_attributes(B, S, []).

tokenize_attributes(B, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary>> ->
            {lists:reverse(Acc), S};
        <<_:O/binary, C, _/binary>> when (C =:= $> orelse C =:= $/) ->
            {lists:reverse(Acc), S};
        <<_:O/binary, "?>", _/binary>> ->
            {lists:reverse(Acc), S};
        <<_:O/binary, C, _/binary>> when ?IS_WHITESPACE(C) ->
            tokenize_attributes(B, ?INC_CHAR(S, C), Acc);
        _ ->
            {Attr, S1} = tokenize_literal(B, S),
            {Value, S2} = tokenize_attr_value(Attr, B, S1),
            tokenize_attributes(B, S2, [{Attr, Value} | Acc])
    end.

tokenize_attr_value(Attr, B, S) ->
    S1 = skip_whitespace(B, S),
    O = S1#decoder.offset,
    case B of
        <<_:O/binary, "=", _/binary>> ->
            S2 = skip_whitespace(B, ?INC_COL(S1)),
            tokenize_quoted_or_unquoted_attr_value(B, S2);
        _ ->
            {Attr, S1}
    end.
    
tokenize_quoted_or_unquoted_attr_value(B, S=#decoder{offset=O}) ->
    case B of
        <<_:O/binary>> ->
            { [], S };
        <<_:O/binary, Q, _/binary>> when Q =:= ?QUOTE orelse
                                         Q =:= ?SQUOTE ->
            tokenize_quoted_attr_value(B, ?INC_COL(S), [], Q);
        <<_:O/binary, _/binary>> ->
            tokenize_unquoted_attr_value(B, S, [])
    end.
    
tokenize_quoted_attr_value(B, S=#decoder{offset=O}, Acc, Q) ->
    case B of
        <<_:O/binary>> ->
            { iolist_to_binary(lists:reverse(Acc)), S };
        <<_:O/binary, $&, _/binary>> ->
            {{data, Data, false}, S1} = tokenize_charref(B, ?INC_COL(S)),
            tokenize_quoted_attr_value(B, S1, [Data|Acc], Q);
        <<_:O/binary, Q, _/binary>> ->
            { iolist_to_binary(lists:reverse(Acc)), ?INC_COL(S) };
        <<_:O/binary, $\n, _/binary>> ->
            { iolist_to_binary(lists:reverse(Acc)), ?INC_LINE(S) };
        <<_:O/binary, C, _/binary>> ->
            tokenize_quoted_attr_value(B, ?INC_COL(S), [C|Acc], Q)
    end.
    
tokenize_unquoted_attr_value(B, S=#decoder{offset=O}, Acc) ->
    case B of
        <<_:O/binary>> ->
            { iolist_to_binary(lists:reverse(Acc)), S };
        <<_:O/binary, $&, _/binary>> ->
            {{data, Data, false}, S1} = tokenize_charref(B, ?INC_COL(S)),
            tokenize_unquoted_attr_value(B, S1, [Data|Acc]);
        <<_:O/binary, $/, $>, _/binary>> ->
            { iolist_to_binary(lists:reverse(Acc)), S };
        <<_:O/binary, C, _/binary>> when ?PROBABLE_CLOSE(C) ->
            { iolist_to_binary(lists:reverse(Acc)), S };
        <<_:O/binary, C, _/binary>> ->
            tokenize_unquoted_attr_value(B, ?INC_COL(S), [C|Acc])
    end.   

skip_whitespace(B, S=#decoder{offset=O}) ->
    case B of
        <<_:O/binary, C, _/binary>> when ?IS_WHITESPACE(C) ->
            skip_whitespace(B, ?INC_CHAR(S, C));
        _ ->
            S
    end.

tokenize_literal(Bin, S=#decoder{offset=O}) ->
    case Bin of
        <<_:O/binary, C, _/binary>> when C =:= $>
                                    orelse C =:= $/
                                    orelse C =:= $= ->
            %% Handle case where tokenize_literal would consume
            %% 0 chars. http://github.com/mochi/mochiweb/pull/13
            {[C], ?INC_COL(S)};
        _ ->
            tokenize_literal(Bin, S, [])
    end.

tokenize_literal(Bin, S=#decoder{offset=O}, Acc) ->
    case Bin of
        <<_:O/binary, $&, _/binary>> ->
            {{data, Data, false}, S1} = tokenize_charref(Bin, ?INC_COL(S)),
            tokenize_literal(Bin, S1, [Data | Acc]);
        <<_:O/binary, C, _/binary>> when not (?IS_WHITESPACE(C)
                                              orelse C =:= $>
                                              orelse C =:= $/
                                              orelse C =:= $=) ->
            tokenize_literal(Bin, ?INC_COL(S), [C | Acc]);
        _ ->
            {iolist_to_binary(string:to_lower(lists:reverse(Acc))), S}
    end.

raw_qgt(Bin, S=#decoder{offset=O}) ->
    raw_qgt(Bin, S, O).

raw_qgt(Bin, S=#decoder{offset=O}, Start) ->
    case Bin of
        <<_:O/binary, "?>", _/binary>> ->
            Len = O - Start,
            <<_:Start/binary, Raw:Len/binary, _/binary>> = Bin,
            {Raw, ?ADV_COL(S, 2)};
        <<_:O/binary, C, _/binary>> ->
            raw_qgt(Bin, ?INC_CHAR(S, C), Start);
        <<_:O/binary>> ->
            <<_:Start/binary, Raw/binary>> = Bin,
            {Raw, S}
    end.

find_qgt(Bin, S=#decoder{offset=O}) ->
    case Bin of
        <<_:O/binary, "?>", _/binary>> ->
            ?ADV_COL(S, 2);
        <<_:O/binary, ">", _/binary>> ->
			?ADV_COL(S, 1);
        <<_:O/binary, "/>", _/binary>> ->
			?ADV_COL(S, 2);
        %% tokenize_attributes takes care of this state:
        %% <<_:O/binary, C, _/binary>> ->
        %%     find_qgt(Bin, ?INC_CHAR(S, C));
        <<_:O/binary>> ->
            S
    end.

find_gt(Bin, S) ->
    find_gt(Bin, S, false).

find_gt(Bin, S=#decoder{offset=O}, HasSlash) ->
    case Bin of
        <<_:O/binary, $/, _/binary>> ->
            find_gt(Bin, ?INC_COL(S), true);
        <<_:O/binary, $>, _/binary>> ->
            {?INC_COL(S), HasSlash};
        <<_:O/binary, C, _/binary>> ->
            find_gt(Bin, ?INC_CHAR(S, C), HasSlash);
        _ ->
            {S, HasSlash}
    end.

tokenize_charref(Bin, S=#decoder{offset=O}) ->
    tokenize_charref(Bin, S, O).

tokenize_charref(Bin, S=#decoder{offset=O}, Start) ->
    case Bin of
        <<_:O/binary>> ->
            <<_:Start/binary, Raw/binary>> = Bin,
            {{data, Raw, false}, S};
        <<_:O/binary, C, _/binary>> when ?IS_WHITESPACE(C)
                                         orelse C =:= ?SQUOTE
                                         orelse C =:= ?QUOTE
                                         orelse C =:= $/
                                         orelse C =:= $> ->
            Len = O - Start,
            <<_:Start/binary, Raw:Len/binary, _/binary>> = Bin,
            {{data, Raw, false}, S};
        <<_:O/binary, $;, _/binary>> ->
            Len = O - Start,
            <<_:Start/binary, Raw:Len/binary, _/binary>> = Bin,
            Data = case mochiweb_charref:charref(Raw) of
                       undefined ->
                           Start1 = Start - 1,
                           Len1 = Len + 2,
                           <<_:Start1/binary, R:Len1/binary, _/binary>> = Bin,
                           R;
                       Unichar ->
                           mochiutf8:codepoint_to_bytes(Unichar)
                   end,
            {{data, Data, false}, ?INC_COL(S)};
        _ ->
            tokenize_charref(Bin, ?INC_COL(S), Start)
    end.

tokenize_doctype(Bin, S) ->
    tokenize_doctype(Bin, S, []).

tokenize_doctype(Bin, S=#decoder{offset=O}, Acc) ->
    case Bin of
        <<_:O/binary>> ->
            {{doctype, lists:reverse(Acc)}, S};
        <<_:O/binary, $>, _/binary>> ->
            {{doctype, lists:reverse(Acc)}, ?INC_COL(S)};
        <<_:O/binary, C, _/binary>> when ?IS_WHITESPACE(C) ->
            tokenize_doctype(Bin, ?INC_CHAR(S, C), Acc);
        _ ->
            {Word, S1} = tokenize_word_or_literal(Bin, S),
            tokenize_doctype(Bin, S1, [Word | Acc])
    end.

tokenize_word_or_literal(Bin, S=#decoder{offset=O}) ->
    case Bin of
        <<_:O/binary, C, _/binary>> when C =:= ?QUOTE orelse C =:= ?SQUOTE ->
            tokenize_word(Bin, ?INC_COL(S), C);
        <<_:O/binary, C, _/binary>> when not ?IS_WHITESPACE(C) ->
            %% Sanity check for whitespace
            tokenize_literal(Bin, S)
    end.

tokenize_word(Bin, S, Quote) ->
    tokenize_word(Bin, S, Quote, []).

tokenize_word(Bin, S=#decoder{offset=O}, Quote, Acc) ->
    case Bin of
        <<_:O/binary>> ->
            {iolist_to_binary(lists:reverse(Acc)), S};
        <<_:O/binary, Quote, _/binary>> ->
            {iolist_to_binary(lists:reverse(Acc)), ?INC_COL(S)};
        <<_:O/binary, $&, _/binary>> ->
            {{data, Data, false}, S1} = tokenize_charref(Bin, ?INC_COL(S)),
            tokenize_word(Bin, S1, Quote, [Data | Acc]);
        <<_:O/binary, C, _/binary>> ->
            tokenize_word(Bin, ?INC_CHAR(S, C), Quote, [C | Acc])
    end.

tokenize_cdata(Bin, S=#decoder{offset=O}) ->
    tokenize_cdata(Bin, S, O).

tokenize_cdata(Bin, S=#decoder{offset=O}, Start) ->
    case Bin of
        <<_:O/binary, "]]>", _/binary>> ->
            Len = O - Start,
            <<_:Start/binary, Raw:Len/binary, _/binary>> = Bin,
            {{data, Raw, false}, ?ADV_COL(S, 3)};
        <<_:O/binary, C, _/binary>> ->
            tokenize_cdata(Bin, ?INC_CHAR(S, C), Start);
        _ ->
            <<_:O/binary, Raw/binary>> = Bin,
            {{data, Raw, false}, S}
    end.

tokenize_comment(Bin, S=#decoder{offset=O}) ->
    tokenize_comment(Bin, S, O).

tokenize_comment(Bin, S=#decoder{offset=O}, Start) ->
    case Bin of
        <<_:O/binary, "-->", _/binary>> ->
            Len = O - Start,
            <<_:Start/binary, Raw:Len/binary, _/binary>> = Bin,
            {{comment, Raw}, ?ADV_COL(S, 3)};
        <<_:O/binary, C, _/binary>> ->
            tokenize_comment(Bin, ?INC_CHAR(S, C), Start);
        <<_:Start/binary, Raw/binary>> ->
            {{comment, Raw}, S}
    end.

tokenize_script(Bin, S=#decoder{offset=O}) ->
    tokenize_script(Bin, S, O).

tokenize_script(Bin, S=#decoder{offset=O}, Start) ->
    case Bin of
        %% Just a look-ahead, we want the end_tag separately
        <<_:O/binary, $<, $/, SS, CC, RR, II, PP, TT, ZZ, _/binary>>
        when (SS =:= $s orelse SS =:= $S) andalso
             (CC =:= $c orelse CC =:= $C) andalso
             (RR =:= $r orelse RR =:= $R) andalso
             (II =:= $i orelse II =:= $I) andalso
             (PP =:= $p orelse PP =:= $P) andalso
             (TT=:= $t orelse TT =:= $T) andalso
             ?PROBABLE_CLOSE(ZZ) ->
            Len = O - Start,
            <<_:Start/binary, Raw:Len/binary, _/binary>> = Bin,
            {{data, Raw, false}, S};
        <<_:O/binary, C, _/binary>> ->
            tokenize_script(Bin, ?INC_CHAR(S, C), Start);
        <<_:Start/binary, Raw/binary>> ->
            {{data, Raw, false}, S}
    end.

tokenize_textarea(Bin, S=#decoder{offset=O}) ->
    tokenize_textarea(Bin, S, O).

tokenize_textarea(Bin, S=#decoder{offset=O}, Start) ->
    case Bin of
        %% Just a look-ahead, we want the end_tag separately
        <<_:O/binary, $<, $/, TT, EE, XX, TT2, AA, RR, EE2, AA2, ZZ, _/binary>>
        when (TT =:= $t orelse TT =:= $T) andalso
             (EE =:= $e orelse EE =:= $E) andalso
             (XX =:= $x orelse XX =:= $X) andalso
             (TT2 =:= $t orelse TT2 =:= $T) andalso
             (AA =:= $a orelse AA =:= $A) andalso
             (RR =:= $r orelse RR =:= $R) andalso
             (EE2 =:= $e orelse EE2 =:= $E) andalso
             (AA2 =:= $a orelse AA2 =:= $A) andalso
             ?PROBABLE_CLOSE(ZZ) ->
            Len = O - Start,
            <<_:Start/binary, Raw:Len/binary, _/binary>> = Bin,
            {{data, Raw, false}, S};
        <<_:O/binary, C, _/binary>> ->
            tokenize_textarea(Bin, ?INC_CHAR(S, C), Start);
        <<_:Start/binary, Raw/binary>> ->
            {{data, Raw, false}, S}
    end.


%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

to_html_test() ->
    ?assertEqual(
       <<"<html><head><title>hey!</title></head><body><p class=\"foo\">what's up<br /></p><div>sucka</div>RAW!<!-- comment! --></body></html>">>,
       iolist_to_binary(
         to_html({html, [],
                  [{<<"head">>, [],
                    [{title, <<"hey!">>}]},
                   {body, [],
                    [{p, [{class, foo}], [<<"what's">>, <<" up">>, {br}]},
                     {'div', <<"sucka">>},
                     {'=', <<"RAW!">>},
                     {comment, <<" comment! ">>}]}]}))),
    ?assertEqual(
       <<"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">">>,
       iolist_to_binary(
         to_html({doctype,
                  [<<"html">>, <<"PUBLIC">>,
                   <<"-//W3C//DTD XHTML 1.0 Transitional//EN">>,
                   <<"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">>]}))),
    ?assertEqual(
       <<"<html><?xml:namespace prefix=\"o\" ns=\"urn:schemas-microsoft-com:office:office\"?></html>">>,
       iolist_to_binary(
         to_html({<<"html">>,[],
                  [{pi, <<"xml:namespace">>,
                    [{<<"prefix">>,<<"o">>},
                     {<<"ns">>,<<"urn:schemas-microsoft-com:office:office">>}]}]}))),
    ok.

escape_test() ->
    ?assertEqual(
       <<"&amp;quot;\"word &gt;&lt;&lt;up!&amp;quot;">>,
       escape(<<"&quot;\"word ><<up!&quot;">>)),
    ?assertEqual(
       <<"&amp;quot;\"word &gt;&lt;&lt;up!&amp;quot;">>,
       escape("&quot;\"word ><<up!&quot;")),
    ?assertEqual(
       <<"&amp;quot;\"word &gt;&lt;&lt;up!&amp;quot;">>,
       escape('&quot;\"word ><<up!&quot;')),
    ok.

escape_attr_test() ->
    ?assertEqual(
       <<"&amp;quot;&quot;word &gt;&lt;&lt;up!&amp;quot;">>,
       escape_attr(<<"&quot;\"word ><<up!&quot;">>)),
    ?assertEqual(
       <<"&amp;quot;&quot;word &gt;&lt;&lt;up!&amp;quot;">>,
       escape_attr("&quot;\"word ><<up!&quot;")),
    ?assertEqual(
       <<"&amp;quot;&quot;word &gt;&lt;&lt;up!&amp;quot;">>,
       escape_attr('&quot;\"word ><<up!&quot;')),
    ?assertEqual(
       <<"12345">>,
       escape_attr(12345)),
    ?assertEqual(
       <<"1.5">>,
       escape_attr(1.5)),
    ok.

tokens_test() ->
    ?assertEqual(
       [{start_tag, <<"foo">>, [{<<"bar">>, <<"baz">>},
                                {<<"wibble">>, <<"wibble">>},
                                {<<"alice">>, <<"bob">>}], true}],
       tokens(<<"<foo bar=baz wibble='wibble' alice=\"bob\"/>">>)),
    ?assertEqual(
       [{start_tag, <<"foo">>, [{<<"bar">>, <<"baz">>},
                                {<<"wibble">>, <<"wibble">>},
                                {<<"alice">>, <<"bob">>}], true}],
       tokens(<<"<foo bar=baz wibble='wibble' alice=bob/>">>)),
    ?assertEqual(
       [{comment, <<"[if lt IE 7]>\n<style type=\"text/css\">\n.no_ie { display: none; }\n</style>\n<![endif]">>}],
       tokens(<<"<!--[if lt IE 7]>\n<style type=\"text/css\">\n.no_ie { display: none; }\n</style>\n<![endif]-->">>)),
    ?assertEqual(
       [{start_tag, <<"script">>, [{<<"type">>, <<"text/javascript">>}], false},
        {data, <<" A= B <= C ">>, false},
        {end_tag, <<"script">>}],
       tokens(<<"<script type=\"text/javascript\"> A= B <= C </script>">>)),
    ?assertEqual(
       [{start_tag, <<"script">>, [{<<"type">>, <<"text/javascript">>}], false},
        {data, <<" A= B <= C ">>, false},
        {end_tag, <<"script">>}],
       tokens(<<"<script type =\"text/javascript\"> A= B <= C </script>">>)),
    ?assertEqual(
       [{start_tag, <<"script">>, [{<<"type">>, <<"text/javascript">>}], false},
        {data, <<" A= B <= C ">>, false},
        {end_tag, <<"script">>}],
       tokens(<<"<script type = \"text/javascript\"> A= B <= C </script>">>)),
    ?assertEqual(
       [{start_tag, <<"script">>, [{<<"type">>, <<"text/javascript">>}], false},
        {data, <<" A= B <= C ">>, false},
        {end_tag, <<"script">>}],
       tokens(<<"<script type= \"text/javascript\"> A= B <= C </script>">>)),
    ?assertEqual(
       [{start_tag, <<"textarea">>, [], false},
        {data, <<"<html></body>">>, false},
        {end_tag, <<"textarea">>}],
       tokens(<<"<textarea><html></body></textarea>">>)),
    ?assertEqual(
       [{start_tag, <<"textarea">>, [], false},
        {data, <<"<html></body></textareaz>">>, false}],
       tokens(<<"<textarea ><html></body></textareaz>">>)),
    ?assertEqual(
       [{pi, <<"xml:namespace">>,
         [{<<"prefix">>,<<"o">>},
          {<<"ns">>,<<"urn:schemas-microsoft-com:office:office">>}]}],
       tokens(<<"<?xml:namespace prefix=\"o\" ns=\"urn:schemas-microsoft-com:office:office\"?>">>)),
    ?assertEqual(
       [{pi, <<"xml:namespace">>,
         [{<<"prefix">>,<<"o">>},
          {<<"ns">>,<<"urn:schemas-microsoft-com:office:office">>}]}],
       tokens(<<"<?xml:namespace prefix=o ns=urn:schemas-microsoft-com:office:office \n?>">>)),
    ?assertEqual(
       [{pi, <<"xml:namespace">>,
         [{<<"prefix">>,<<"o">>},
          {<<"ns">>,<<"urn:schemas-microsoft-com:office:office">>}]}],
       tokens(<<"<?xml:namespace prefix=o ns=urn:schemas-microsoft-com:office:office">>)),
    ?assertEqual(
       [{data, <<"<">>, false}],
       tokens(<<"&lt;">>)),
    ?assertEqual(
       [{data, <<"not html ">>, false},
        {data, <<"< at all">>, false}],
       tokens(<<"not html < at all">>)),
    ok.

parse_test() ->
    D0 = <<"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">
<html>
 <head>
   <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">
   <title>Foo</title>
   <link rel=\"stylesheet\" type=\"text/css\" href=\"/static/rel/dojo/resources/dojo.css\" media=\"screen\">
   <link rel=\"stylesheet\" type=\"text/css\" href=\"/static/foo.css\" media=\"screen\">
   <!--[if lt IE 7]>
   <style type=\"text/css\">
     .no_ie { display: none; }
   </style>
   <![endif]-->
   <link rel=\"icon\" href=\"/static/images/favicon.ico\" type=\"image/x-icon\">
   <link rel=\"shortcut icon\" href=\"/static/images/favicon.ico\" type=\"image/x-icon\">
 </head>
 <body id=\"home\" class=\"tundra\"><![CDATA[&lt;<this<!-- is -->CDATA>&gt;]]></body>
</html>">>,
    ?assertEqual(
       {<<"html">>, [],
        [{<<"head">>, [],
          [{<<"meta">>,
            [{<<"http-equiv">>,<<"Content-Type">>},
             {<<"content">>,<<"text/html; charset=UTF-8">>}],
            []},
           {<<"title">>,[],[<<"Foo">>]},
           {<<"link">>,
            [{<<"rel">>,<<"stylesheet">>},
             {<<"type">>,<<"text/css">>},
             {<<"href">>,<<"/static/rel/dojo/resources/dojo.css">>},
             {<<"media">>,<<"screen">>}],
            []},
           {<<"link">>,
            [{<<"rel">>,<<"stylesheet">>},
             {<<"type">>,<<"text/css">>},
             {<<"href">>,<<"/static/foo.css">>},
             {<<"media">>,<<"screen">>}],
            []},
           {comment,<<"[if lt IE 7]>\n   <style type=\"text/css\">\n     .no_ie { display: none; }\n   </style>\n   <![endif]">>},
           {<<"link">>,
            [{<<"rel">>,<<"icon">>},
             {<<"href">>,<<"/static/images/favicon.ico">>},
             {<<"type">>,<<"image/x-icon">>}],
            []},
           {<<"link">>,
            [{<<"rel">>,<<"shortcut icon">>},
             {<<"href">>,<<"/static/images/favicon.ico">>},
             {<<"type">>,<<"image/x-icon">>}],
            []}]},
         {<<"body">>,
          [{<<"id">>,<<"home">>},
           {<<"class">>,<<"tundra">>}],
          [<<"&lt;<this<!-- is -->CDATA>&gt;">>]}]},
       parse(D0)),
    ?assertEqual(
       {<<"html">>,[],
        [{pi, <<"xml:namespace">>,
          [{<<"prefix">>,<<"o">>},
           {<<"ns">>,<<"urn:schemas-microsoft-com:office:office">>}]}]},
       parse(
         <<"<html><?xml:namespace prefix=\"o\" ns=\"urn:schemas-microsoft-com:office:office\"?></html>">>)),
    ?assertEqual(
       {<<"html">>, [],
        [{<<"dd">>, [], [<<"foo">>]},
         {<<"dt">>, [], [<<"bar">>]}]},
       parse(<<"<html><dd>foo<dt>bar</html>">>)),
    %% Singleton sadness
    ?assertEqual(
       {<<"html">>, [],
        [{<<"link">>, [], []},
         <<"foo">>,
         {<<"br">>, [], []},
         <<"bar">>]},
       parse(<<"<html><link>foo<br>bar</html>">>)),
    ?assertEqual(
       {<<"html">>, [],
        [{<<"link">>, [], [<<"foo">>,
                           {<<"br">>, [], []},
                           <<"bar">>]}]},
       parse(<<"<html><link>foo<br>bar</link></html>">>)),
    %% Case insensitive tags
    ?assertEqual(
       {<<"html">>, [],
        [{<<"head">>, [], [<<"foo">>,
                           {<<"br">>, [], []},
                           <<"BAR">>]},
         {<<"body">>, [{<<"class">>, <<"">>}, {<<"bgcolor">>, <<"#Aa01fF">>}], []}
        ]},
       parse(<<"<html><Head>foo<bR>BAR</head><body Class=\"\" bgcolor=\"#Aa01fF\"></BODY></html>">>)),
    ok.

exhaustive_is_singleton_test() ->
    T = mochiweb_cover:clause_lookup_table(?MODULE, is_singleton),
    [?assertEqual(V, is_singleton(K)) || {K, V} <- T].

tokenize_attributes_test() ->
    ?assertEqual(
       {<<"foo">>,
        [{<<"bar">>, <<"b\"az">>},
         {<<"wibble">>, <<"wibble">>},
         {<<"taco", 16#c2, 16#a9>>, <<"bell">>},
         {<<"quux">>, <<"quux">>}],
        []},
       parse(<<"<foo bar=\"b&quot;az\" wibble taco&copy;=bell quux">>)),
    ok.

tokens2_test() ->
    D0 = <<"<channel><title>from __future__ import *</title><link>http://bob.pythonmac.org</link><description>Bob's Rants</description></channel>">>,
    ?assertEqual(
       [{start_tag,<<"channel">>,[],false},
        {start_tag,<<"title">>,[],false},
        {data,<<"from __future__ import *">>,false},
        {end_tag,<<"title">>},
        {start_tag,<<"link">>,[],true},
        {data,<<"http://bob.pythonmac.org">>,false},
        {end_tag,<<"link">>},
        {start_tag,<<"description">>,[],false},
        {data,<<"Bob's Rants">>,false},
        {end_tag,<<"description">>},
        {end_tag,<<"channel">>}],
       tokens(D0)),
    ok.

to_tokens_test() ->
    ?assertEqual(
       [{start_tag, <<"p">>, [{class, 1}], false},
        {end_tag, <<"p">>}],
       to_tokens({p, [{class, 1}], []})),
    ?assertEqual(
       [{start_tag, <<"p">>, [], false},
        {end_tag, <<"p">>}],
       to_tokens({p})),
    ?assertEqual(
       [{'=', <<"data">>}],
       to_tokens({'=', <<"data">>})),
    ?assertEqual(
       [{comment, <<"comment">>}],
       to_tokens({comment, <<"comment">>})),
    %% This is only allowed in sub-tags:
    %% {p, [{"class", "foo"}]} as {p, [{"class", "foo"}], []}
    %% On the outside it's always treated as follows:
    %% {p, [], [{"class", "foo"}]} as {p, [], [{"class", "foo"}]}
    ?assertEqual(
       [{start_tag, <<"html">>, [], false},
        {start_tag, <<"p">>, [{class, 1}], false},
        {end_tag, <<"p">>},
        {end_tag, <<"html">>}],
       to_tokens({html, [{p, [{class, 1}]}]})),
    ok.

parse2_test() ->
    D0 = <<"<channel><title>from __future__ import *</title><link>http://bob.pythonmac.org<br>foo</link><description>Bob's Rants</description></channel>">>,
    ?assertEqual(
       {<<"channel">>,[],
        [{<<"title">>,[],[<<"from __future__ import *">>]},
         {<<"link">>,[],[
                         <<"http://bob.pythonmac.org">>,
                         {<<"br">>,[],[]},
                         <<"foo">>]},
         {<<"description">>,[],[<<"Bob's Rants">>]}]},
       parse(D0)),
    ok.

parse_tokens_test() ->
    D0 = [{doctype,[<<"HTML">>,<<"PUBLIC">>,<<"-//W3C//DTD HTML 4.01 Transitional//EN">>]},
          {data,<<"\n">>,true},
          {start_tag,<<"html">>,[],false}],
    ?assertEqual(
       {<<"html">>, [], []},
       parse_tokens(D0)),
    D1 = D0 ++ [{end_tag, <<"html">>}],
    ?assertEqual(
       {<<"html">>, [], []},
       parse_tokens(D1)),
    D2 = D0 ++ [{start_tag, <<"body">>, [], false}],
    ?assertEqual(
       {<<"html">>, [], [{<<"body">>, [], []}]},
       parse_tokens(D2)),
    D3 = D0 ++ [{start_tag, <<"head">>, [], false},
                {end_tag, <<"head">>},
                {start_tag, <<"body">>, [], false}],
    ?assertEqual(
       {<<"html">>, [], [{<<"head">>, [], []}, {<<"body">>, [], []}]},
       parse_tokens(D3)),
    D4 = D3 ++ [{data,<<"\n">>,true},
                {start_tag,<<"div">>,[{<<"class">>,<<"a">>}],false},
                {start_tag,<<"a">>,[{<<"name">>,<<"#anchor">>}],false},
                {end_tag,<<"a">>},
                {end_tag,<<"div">>},
                {start_tag,<<"div">>,[{<<"class">>,<<"b">>}],false},
                {start_tag,<<"div">>,[{<<"class">>,<<"c">>}],false},
                {end_tag,<<"div">>},
                {end_tag,<<"div">>}],
    ?assertEqual(
       {<<"html">>, [],
        [{<<"head">>, [], []},
         {<<"body">>, [],
          [{<<"div">>, [{<<"class">>, <<"a">>}], [{<<"a">>, [{<<"name">>, <<"#anchor">>}], []}]},
           {<<"div">>, [{<<"class">>, <<"b">>}], [{<<"div">>, [{<<"class">>, <<"c">>}], []}]}
          ]}]},
       parse_tokens(D4)),
    D5 = [{start_tag,<<"html">>,[],false},
          {data,<<"\n">>,true},
          {data,<<"boo">>,false},
          {data,<<"hoo">>,false},
          {data,<<"\n">>,true},
          {end_tag,<<"html">>}],
    ?assertEqual(
       {<<"html">>, [], [<<"\nboohoo\n">>]},
       parse_tokens(D5)),
    D6 = [{start_tag,<<"html">>,[],false},
          {data,<<"\n">>,true},
          {data,<<"\n">>,true},
          {end_tag,<<"html">>}],
    ?assertEqual(
       {<<"html">>, [], []},
       parse_tokens(D6)),
    D7 = [{start_tag,<<"html">>,[],false},
          {start_tag,<<"ul">>,[],false},
          {start_tag,<<"li">>,[],false},
          {data,<<"word">>,false},
          {start_tag,<<"li">>,[],false},
          {data,<<"up">>,false},
          {end_tag,<<"li">>},
          {start_tag,<<"li">>,[],false},
          {data,<<"fdsa">>,false},
          {start_tag,<<"br">>,[],true},
          {data,<<"asdf">>,false},
          {end_tag,<<"ul">>},
          {end_tag,<<"html">>}],
    ?assertEqual(
       {<<"html">>, [],
        [{<<"ul">>, [],
          [{<<"li">>, [], [<<"word">>]},
           {<<"li">>, [], [<<"up">>]},
           {<<"li">>, [], [<<"fdsa">>,{<<"br">>, [], []}, <<"asdf">>]}]}]},
       parse_tokens(D7)),
    ok.

destack_test() ->
    {<<"a">>, [], []} =
        destack([{<<"a">>, [], []}]),
    {<<"a">>, [], [{<<"b">>, [], []}]} =
        destack([{<<"b">>, [], []}, {<<"a">>, [], []}]),
    {<<"a">>, [], [{<<"b">>, [], [{<<"c">>, [], []}]}]} =
     destack([{<<"c">>, [], []}, {<<"b">>, [], []}, {<<"a">>, [], []}]),
    [{<<"a">>, [], [{<<"b">>, [], [{<<"c">>, [], []}]}]}] =
     destack(<<"b">>,
             [{<<"c">>, [], []}, {<<"b">>, [], []}, {<<"a">>, [], []}]),
    [{<<"b">>, [], [{<<"c">>, [], []}]}, {<<"a">>, [], []}] =
     destack(<<"c">>,
             [{<<"c">>, [], []}, {<<"b">>, [], []},{<<"a">>, [], []}]),
    ok.

doctype_test() ->
    ?assertEqual(
       {<<"html">>,[],[{<<"head">>,[],[]}]},
       mochiweb_html:parse("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
                           "<html><head></head></body></html>")),
    %% http://code.google.com/p/mochiweb/issues/detail?id=52
    ?assertEqual(
       {<<"html">>,[],[{<<"head">>,[],[]}]},
       mochiweb_html:parse("<html>"
                           "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
                           "<head></head></body></html>")),
    %% http://github.com/mochi/mochiweb/pull/13
    ?assertEqual(
       {<<"html">>,[],[{<<"head">>,[],[]}]},
       mochiweb_html:parse("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"/>"
                           "<html>"
                           "<head></head></body></html>")),
    ok.

dumb_br_test() ->
    %% http://code.google.com/p/mochiweb/issues/detail?id=71
    ?assertEqual(
       {<<"div">>,[],[{<<"br">>, [], []}, {<<"br">>, [], []}, <<"z">>]},
       mochiweb_html:parse("<div><br/><br/>z</br/></br/></div>")),
    ?assertEqual(
       {<<"div">>,[],[{<<"br">>, [], []}, {<<"br">>, [], []}, <<"z">>]},
       mochiweb_html:parse("<div><br><br>z</br/></br/></div>")),
    ?assertEqual(
       {<<"div">>,[],[{<<"br">>, [], []}, {<<"br">>, [], []}, <<"z">>, {<<"br">>, [], []}, {<<"br">>, [], []}]},
       mochiweb_html:parse("<div><br><br>z<br/><br/></div>")),
    ?assertEqual(
       {<<"div">>,[],[{<<"br">>, [], []}, {<<"br">>, [], []}, <<"z">>]},
       mochiweb_html:parse("<div><br><br>z</br></br></div>")).


php_test() ->
    %% http://code.google.com/p/mochiweb/issues/detail?id=71
    ?assertEqual(
       [{pi, <<"php\n">>}],
       mochiweb_html:tokens(
         "<?php\n?>")),
    ?assertEqual(
       {<<"div">>, [], [{pi, <<"php\n">>}]},
       mochiweb_html:parse(
         "<div><?php\n?></div>")),
    ok.

parse_unquoted_attr_test() ->
    D0 = <<"<html><img src=/images/icon.png/></html>">>,
    ?assertEqual(
        {<<"html">>,[],[
            { <<"img">>, [ { <<"src">>, <<"/images/icon.png">> } ], [] }
        ]},
        mochiweb_html:parse(D0)),
    
    D1 = <<"<html><img src=/images/icon.png></img></html>">>,
        ?assertEqual(
            {<<"html">>,[],[
                { <<"img">>, [ { <<"src">>, <<"/images/icon.png">> } ], [] }
            ]},
            mochiweb_html:parse(D1)),
    
    D2 = <<"<html><img src=/images/icon&gt;.png width=100></img></html>">>,
        ?assertEqual(
            {<<"html">>,[],[
                { <<"img">>, [ { <<"src">>, <<"/images/icon>.png">> }, { <<"width">>, <<"100">> } ], [] }
            ]},
            mochiweb_html:parse(D2)),
    ok.        
    
parse_quoted_attr_test() ->    
    D0 = <<"<html><img src='/images/icon.png'></html>">>,
    ?assertEqual(
        {<<"html">>,[],[
            { <<"img">>, [ { <<"src">>, <<"/images/icon.png">> } ], [] }
        ]},
        mochiweb_html:parse(D0)),     
        
    D1 = <<"<html><img src=\"/images/icon.png'></html>">>,
    ?assertEqual(
        {<<"html">>,[],[
            { <<"img">>, [ { <<"src">>, <<"/images/icon.png'></html>">> } ], [] }
        ]},
        mochiweb_html:parse(D1)),     

    D2 = <<"<html><img src=\"/images/icon&gt;.png\"></html>">>,
    ?assertEqual(
        {<<"html">>,[],[
            { <<"img">>, [ { <<"src">>, <<"/images/icon>.png">> } ], [] }
        ]},
        mochiweb_html:parse(D2)),     
    ok.

parse_missing_attr_name_test() ->
    D0 = <<"<html =black></html>">>,
    ?assertEqual(
        {<<"html">>, [ { <<"=">>, <<"=">> }, { <<"black">>, <<"black">> } ], [] },
       mochiweb_html:parse(D0)),
    ok.

parse_broken_pi_test() ->
	D0 = <<"<html><?xml:namespace prefix = o ns = \"urn:schemas-microsoft-com:office:office\" /></html>">>,
	?assertEqual(
		{<<"html">>, [], [
			{ pi, <<"xml:namespace">>, [ { <<"prefix">>, <<"o">> }, 
			                             { <<"ns">>, <<"urn:schemas-microsoft-com:office:office">> } ] }
		] },
		mochiweb_html:parse(D0)),
	ok.

parse_funny_singletons_test() ->
	D0 = <<"<html><input><input>x</input></input></html>">>,
	?assertEqual(
		{<<"html">>, [], [
			{ <<"input">>, [], [] },
			{ <<"input">>, [], [ <<"x">> ] }
		] },
		mochiweb_html:parse(D0)),
	ok.
    
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc HTTP server.

-module(mochiweb_http).
-author('bob@mochimedia.com').
-export([start/1, start_link/1, stop/0, stop/1]).
-export([loop/2]).
-export([after_response/2, reentry/1]).
-export([parse_range_request/1, range_skip_length/2]).

-define(REQUEST_RECV_TIMEOUT, 300000).   %% timeout waiting for request line
-define(HEADERS_RECV_TIMEOUT, 30000).    %% timeout waiting for headers

-define(MAX_HEADERS, 1000).
-define(DEFAULTS, [{name, ?MODULE},
                   {port, 8888}]).

parse_options(Options) ->
    {loop, HttpLoop} = proplists:lookup(loop, Options),
    Loop = {?MODULE, loop, [HttpLoop]},
    Options1 = [{loop, Loop} | proplists:delete(loop, Options)],
    mochilists:set_defaults(?DEFAULTS, Options1).

stop() ->
    mochiweb_socket_server:stop(?MODULE).

stop(Name) ->
    mochiweb_socket_server:stop(Name).

%% @spec start(Options) -> ServerRet
%%     Options = [option()]
%%     Option = {name, atom()} | {ip, string() | tuple()} | {backlog, integer()}
%%              | {nodelay, boolean()} | {acceptor_pool_size, integer()}
%%              | {ssl, boolean()} | {profile_fun, undefined | (Props) -> ok}
%%              | {link, false}
%% @doc Start a mochiweb server.
%%      profile_fun is used to profile accept timing.
%%      After each accept, if defined, profile_fun is called with a proplist of a subset of the mochiweb_socket_server state and timing information.
%%      The proplist is as follows: [{name, Name}, {port, Port}, {active_sockets, ActiveSockets}, {timing, Timing}].
%% @end
start(Options) ->
    mochiweb_socket_server:start(parse_options(Options)).

start_link(Options) ->
    mochiweb_socket_server:start_link(parse_options(Options)).

loop(Socket, Body) ->
    ok = mochiweb_socket:setopts(Socket, [{packet, http}]),
    request(Socket, Body).

request(Socket, Body) ->
    ok = mochiweb_socket:setopts(Socket, [{active, once}]),
    receive
        {Protocol, _, {http_request, Method, Path, Version}} when Protocol == http orelse Protocol == ssl ->
            ok = mochiweb_socket:setopts(Socket, [{packet, httph}]),
            headers(Socket, {Method, Path, Version}, [], Body, 0);
        {Protocol, _, {http_error, "\r\n"}} when Protocol == http orelse Protocol == ssl ->
            request(Socket, Body);
        {Protocol, _, {http_error, "\n"}} when Protocol == http orelse Protocol == ssl ->
            request(Socket, Body);
        {tcp_closed, _} ->
            mochiweb_socket:close(Socket),
            exit(normal);
        {ssl_closed, _} ->
            mochiweb_socket:close(Socket),
            exit(normal);
        _Other ->
            handle_invalid_request(Socket)
    after ?REQUEST_RECV_TIMEOUT ->
        mochiweb_socket:close(Socket),
        exit(normal)
    end.

reentry(Body) ->
    fun (Req) ->
            ?MODULE:after_response(Body, Req)
    end.

headers(Socket, Request, Headers, _Body, ?MAX_HEADERS) ->
    %% Too many headers sent, bad request.
    ok = mochiweb_socket:setopts(Socket, [{packet, raw}]),
    handle_invalid_request(Socket, Request, Headers);
headers(Socket, Request, Headers, Body, HeaderCount) ->
    ok = mochiweb_socket:setopts(Socket, [{active, once}]),
    receive
        {Protocol, _, http_eoh} when Protocol == http orelse Protocol == ssl ->
            Req = new_request(Socket, Request, Headers),
            call_body(Body, Req),
            ?MODULE:after_response(Body, Req);
        {Protocol, _, {http_header, _, Name, _, Value}} when Protocol == http orelse Protocol == ssl ->
            headers(Socket, Request, [{Name, Value} | Headers], Body,
                    1 + HeaderCount);
        {tcp_closed, _} ->
            mochiweb_socket:close(Socket),
            exit(normal);
        _Other ->
            handle_invalid_request(Socket, Request, Headers)
    after ?HEADERS_RECV_TIMEOUT ->
        mochiweb_socket:close(Socket),
        exit(normal)
    end.

call_body({M, F, A}, Req) ->
    erlang:apply(M, F, [Req | A]);
call_body({M, F}, Req) ->
    M:F(Req);
call_body(Body, Req) ->
    Body(Req).

-spec handle_invalid_request(term()) -> no_return().
handle_invalid_request(Socket) ->
    handle_invalid_request(Socket, {'GET', {abs_path, "/"}, {0,9}}, []),
    exit(normal).

-spec handle_invalid_request(term(), term(), term()) -> no_return().
handle_invalid_request(Socket, Request, RevHeaders) ->
    Req = new_request(Socket, Request, RevHeaders),
    Req:respond({400, [], []}),
    mochiweb_socket:close(Socket),
    exit(normal).

new_request(Socket, Request, RevHeaders) ->
    ok = mochiweb_socket:setopts(Socket, [{packet, raw}]),
    mochiweb:new_request({Socket, Request, lists:reverse(RevHeaders)}).

after_response(Body, Req) ->
    Socket = Req:get(socket),
    case Req:should_close() of
        true ->
            mochiweb_socket:close(Socket),
            exit(normal);
        false ->
            Req:cleanup(),
            ?MODULE:loop(Socket, Body)
    end.

parse_range_request("bytes=0-") ->
    undefined;
parse_range_request(RawRange) when is_list(RawRange) ->
    try
        "bytes=" ++ RangeString = RawRange,
        Ranges = string:tokens(RangeString, ","),
        lists:map(fun ("-" ++ V)  ->
                          {none, list_to_integer(V)};
                      (R) ->
                          case string:tokens(R, "-") of
                              [S1, S2] ->
                                  {list_to_integer(S1), list_to_integer(S2)};
                              [S] ->
                                  {list_to_integer(S), none}
                          end
                  end,
                  Ranges)
    catch
        _:_ ->
            fail
    end.

range_skip_length(Spec, Size) ->
    case Spec of
        {none, R} when R =< Size, R >= 0 ->
            {Size - R, R};
        {none, _OutOfRange} ->
            {0, Size};
        {R, none} when R >= 0, R < Size ->
            {R, Size - R};
        {_OutOfRange, none} ->
            invalid_range;
        {Start, End} when 0 =< Start, Start =< End, End < Size ->
            {Start, End - Start + 1};
        {_OutOfRange, _End} ->
            invalid_range
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

range_test() ->
    %% valid, single ranges
    ?assertEqual([{20, 30}], parse_range_request("bytes=20-30")),
    ?assertEqual([{20, none}], parse_range_request("bytes=20-")),
    ?assertEqual([{none, 20}], parse_range_request("bytes=-20")),

    %% trivial single range
    ?assertEqual(undefined, parse_range_request("bytes=0-")),

    %% invalid, single ranges
    ?assertEqual(fail, parse_range_request("")),
    ?assertEqual(fail, parse_range_request("garbage")),
    ?assertEqual(fail, parse_range_request("bytes=-20-30")),

    %% valid, multiple range
    ?assertEqual(
       [{20, 30}, {50, 100}, {110, 200}],
       parse_range_request("bytes=20-30,50-100,110-200")),
    ?assertEqual(
       [{20, none}, {50, 100}, {none, 200}],
       parse_range_request("bytes=20-,50-100,-200")),

    %% no ranges
    ?assertEqual([], parse_range_request("bytes=")),
    ok.

range_skip_length_test() ->
    Body = <<"012345678901234567890123456789012345678901234567890123456789">>,
    BodySize = byte_size(Body), %% 60
    BodySize = 60,

    %% these values assume BodySize =:= 60
    ?assertEqual({1,9}, range_skip_length({1,9}, BodySize)), %% 1-9
    ?assertEqual({10,10}, range_skip_length({10,19}, BodySize)), %% 10-19
    ?assertEqual({40, 20}, range_skip_length({none, 20}, BodySize)), %% -20
    ?assertEqual({30, 30}, range_skip_length({30, none}, BodySize)), %% 30-

    %% valid edge cases for range_skip_length
    ?assertEqual({BodySize, 0}, range_skip_length({none, 0}, BodySize)),
    ?assertEqual({0, BodySize}, range_skip_length({none, BodySize}, BodySize)),
    ?assertEqual({0, BodySize}, range_skip_length({0, none}, BodySize)),
    BodySizeLess1 = BodySize - 1,
    ?assertEqual({BodySizeLess1, 1},
                 range_skip_length({BodySize - 1, none}, BodySize)),

    %% out of range, return whole thing
    ?assertEqual({0, BodySize},
                 range_skip_length({none, BodySize + 1}, BodySize)),
    ?assertEqual({0, BodySize},
                 range_skip_length({none, -1}, BodySize)),

    %% invalid ranges
    ?assertEqual(invalid_range,
                 range_skip_length({-1, 30}, BodySize)),
    ?assertEqual(invalid_range,
                 range_skip_length({0, BodySize + 1}, BodySize)),
    ?assertEqual(invalid_range,
                 range_skip_length({-1, BodySize + 1}, BodySize)),
    ?assertEqual(invalid_range,
                 range_skip_length({BodySize, 40}, BodySize)),
    ?assertEqual(invalid_range,
                 range_skip_length({-1, none}, BodySize)),
    ?assertEqual(invalid_range,
                 range_skip_length({BodySize, none}, BodySize)),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Utilities for dealing with IO devices (open files).

-module(mochiweb_io).
-author('bob@mochimedia.com').

-export([iodevice_stream/3, iodevice_stream/2]).
-export([iodevice_foldl/4, iodevice_foldl/3]).
-export([iodevice_size/1]).
-define(READ_SIZE, 8192).

iodevice_foldl(F, Acc, IoDevice) ->
    iodevice_foldl(F, Acc, IoDevice, ?READ_SIZE).

iodevice_foldl(F, Acc, IoDevice, BufferSize) ->
    case file:read(IoDevice, BufferSize) of
        eof ->
            Acc;
        {ok, Data} ->
            iodevice_foldl(F, F(Data, Acc), IoDevice, BufferSize)
    end.

iodevice_stream(Callback, IoDevice) ->
    iodevice_stream(Callback, IoDevice, ?READ_SIZE).

iodevice_stream(Callback, IoDevice, BufferSize) ->
    F = fun (Data, ok) -> Callback(Data) end,
    ok = iodevice_foldl(F, ok, IoDevice, BufferSize).

iodevice_size(IoDevice) ->
    {ok, Size} = file:position(IoDevice, eof),
    {ok, 0} = file:position(IoDevice, bof),
    Size.


%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Gives a good MIME type guess based on file extension.

-module(mochiweb_mime).
-author('bob@mochimedia.com').
-export([from_extension/1]).

%% @spec from_extension(S::string()) -> string() | undefined
%% @doc Given a filename extension (e.g. ".html") return a guess for the MIME
%%      type such as "text/html". Will return the atom undefined if no good
%%      guess is available.

from_extension(".stl") ->
    "application/SLA";
from_extension(".stp") ->
    "application/STEP";
from_extension(".step") ->
    "application/STEP";
from_extension(".dwg") ->
    "application/acad";
from_extension(".ez") ->
    "application/andrew-inset";
from_extension(".ccad") ->
    "application/clariscad";
from_extension(".drw") ->
    "application/drafting";
from_extension(".tsp") ->
    "application/dsptype";
from_extension(".dxf") ->
    "application/dxf";
from_extension(".xls") ->
    "application/excel";
from_extension(".unv") ->
    "application/i-deas";
from_extension(".jar") ->
    "application/java-archive";
from_extension(".hqx") ->
    "application/mac-binhex40";
from_extension(".cpt") ->
    "application/mac-compactpro";
from_extension(".pot") ->
    "application/vnd.ms-powerpoint";
from_extension(".ppt") ->
    "application/vnd.ms-powerpoint";
from_extension(".dms") ->
    "application/octet-stream";
from_extension(".lha") ->
    "application/octet-stream";
from_extension(".lzh") ->
    "application/octet-stream";
from_extension(".oda") ->
    "application/oda";
from_extension(".ogg") ->
    "application/ogg";
from_extension(".ogm") ->
    "application/ogg";
from_extension(".pdf") ->
    "application/pdf";
from_extension(".pgp") ->
    "application/pgp";
from_extension(".ai") ->
    "application/postscript";
from_extension(".eps") ->
    "application/postscript";
from_extension(".ps") ->
    "application/postscript";
from_extension(".prt") ->
    "application/pro_eng";
from_extension(".rtf") ->
    "application/rtf";
from_extension(".smi") ->
    "application/smil";
from_extension(".smil") ->
    "application/smil";
from_extension(".sol") ->
    "application/solids";
from_extension(".vda") ->
    "application/vda";
from_extension(".xlm") ->
    "application/vnd.ms-excel";
from_extension(".cod") ->
    "application/vnd.rim.cod";
from_extension(".pgn") ->
    "application/x-chess-pgn";
from_extension(".cpio") ->
    "application/x-cpio";
from_extension(".csh") ->
    "application/x-csh";
from_extension(".deb") ->
    "application/x-debian-package";
from_extension(".dcr") ->
    "application/x-director";
from_extension(".dir") ->
    "application/x-director";
from_extension(".dxr") ->
    "application/x-director";
from_extension(".gz") ->
    "application/x-gzip";
from_extension(".hdf") ->
    "application/x-hdf";
from_extension(".ipx") ->
    "application/x-ipix";
from_extension(".ips") ->
    "application/x-ipscript";
from_extension(".js") ->
    "application/x-javascript";
from_extension(".skd") ->
    "application/x-koan";
from_extension(".skm") ->
    "application/x-koan";
from_extension(".skp") ->
    "application/x-koan";
from_extension(".skt") ->
    "application/x-koan";
from_extension(".latex") ->
    "application/x-latex";
from_extension(".lsp") ->
    "application/x-lisp";
from_extension(".scm") ->
    "application/x-lotusscreencam";
from_extension(".mif") ->
    "application/x-mif";
from_extension(".com") ->
    "application/x-msdos-program";
from_extension(".exe") ->
    "application/octet-stream";
from_extension(".cdf") ->
    "application/x-netcdf";
from_extension(".nc") ->
    "application/x-netcdf";
from_extension(".pl") ->
    "application/x-perl";
from_extension(".pm") ->
    "application/x-perl";
from_extension(".rar") ->
    "application/x-rar-compressed";
from_extension(".sh") ->
    "application/x-sh";
from_extension(".shar") ->
    "application/x-shar";
from_extension(".swf") ->
    "application/x-shockwave-flash";
from_extension(".sit") ->
    "application/x-stuffit";
from_extension(".sv4cpio") ->
    "application/x-sv4cpio";
from_extension(".sv4crc") ->
    "application/x-sv4crc";
from_extension(".tar.gz") ->
    "application/x-tar-gz";
from_extension(".tgz") ->
    "application/x-tar-gz";
from_extension(".tar") ->
    "application/x-tar";
from_extension(".tcl") ->
    "application/x-tcl";
from_extension(".texi") ->
    "application/x-texinfo";
from_extension(".texinfo") ->
    "application/x-texinfo";
from_extension(".man") ->
    "application/x-troff-man";
from_extension(".me") ->
    "application/x-troff-me";
from_extension(".ms") ->
    "application/x-troff-ms";
from_extension(".roff") ->
    "application/x-troff";
from_extension(".t") ->
    "application/x-troff";
from_extension(".tr") ->
    "application/x-troff";
from_extension(".ustar") ->
    "application/x-ustar";
from_extension(".src") ->
    "application/x-wais-source";
from_extension(".zip") ->
    "application/zip";
from_extension(".tsi") ->
    "audio/TSP-audio";
from_extension(".au") ->
    "audio/basic";
from_extension(".snd") ->
    "audio/basic";
from_extension(".kar") ->
    "audio/midi";
from_extension(".mid") ->
    "audio/midi";
from_extension(".midi") ->
    "audio/midi";
from_extension(".mp2") ->
    "audio/mpeg";
from_extension(".mp3") ->
    "audio/mpeg";
from_extension(".mpga") ->
    "audio/mpeg";
from_extension(".aif") ->
    "audio/x-aiff";
from_extension(".aifc") ->
    "audio/x-aiff";
from_extension(".aiff") ->
    "audio/x-aiff";
from_extension(".m3u") ->
    "audio/x-mpegurl";
from_extension(".wax") ->
    "audio/x-ms-wax";
from_extension(".wma") ->
    "audio/x-ms-wma";
from_extension(".rpm") ->
    "audio/x-pn-realaudio-plugin";
from_extension(".ram") ->
    "audio/x-pn-realaudio";
from_extension(".rm") ->
    "audio/x-pn-realaudio";
from_extension(".ra") ->
    "audio/x-realaudio";
from_extension(".wav") ->
    "audio/x-wav";
from_extension(".pdb") ->
    "chemical/x-pdb";
from_extension(".ras") ->
    "image/cmu-raster";
from_extension(".gif") ->
    "image/gif";
from_extension(".ief") ->
    "image/ief";
from_extension(".jpe") ->
    "image/jpeg";
from_extension(".jpeg") ->
    "image/jpeg";
from_extension(".jpg") ->
    "image/jpeg";
from_extension(".jp2") ->
    "image/jp2";
from_extension(".png") ->
    "image/png";
from_extension(".tif") ->
    "image/tiff";
from_extension(".tiff") ->
    "image/tiff";
from_extension(".pnm") ->
    "image/x-portable-anymap";
from_extension(".pbm") ->
    "image/x-portable-bitmap";
from_extension(".pgm") ->
    "image/x-portable-graymap";
from_extension(".ppm") ->
    "image/x-portable-pixmap";
from_extension(".rgb") ->
    "image/x-rgb";
from_extension(".xbm") ->
    "image/x-xbitmap";
from_extension(".xwd") ->
    "image/x-xwindowdump";
from_extension(".iges") ->
    "model/iges";
from_extension(".igs") ->
    "model/iges";
from_extension(".mesh") ->
    "model/mesh";
from_extension(".") ->
    "";
from_extension(".msh") ->
    "model/mesh";
from_extension(".silo") ->
    "model/mesh";
from_extension(".vrml") ->
    "model/vrml";
from_extension(".wrl") ->
    "model/vrml";
from_extension(".css") ->
    "text/css";
from_extension(".htm") ->
    "text/html";
from_extension(".html") ->
    "text/html";
from_extension(".asc") ->
    "text/plain";
from_extension(".c") ->
    "text/plain";
from_extension(".cc") ->
    "text/plain";
from_extension(".f90") ->
    "text/plain";
from_extension(".f") ->
    "text/plain";
from_extension(".hh") ->
    "text/plain";
from_extension(".m") ->
    "text/plain";
from_extension(".txt") ->
    "text/plain";
from_extension(".rtx") ->
    "text/richtext";
from_extension(".sgm") ->
    "text/sgml";
from_extension(".sgml") ->
    "text/sgml";
from_extension(".tsv") ->
    "text/tab-separated-values";
from_extension(".jad") ->
    "text/vnd.sun.j2me.app-descriptor";
from_extension(".etx") ->
    "text/x-setext";
from_extension(".xml") ->
    "application/xml";
from_extension(".dl") ->
    "video/dl";
from_extension(".fli") ->
    "video/fli";
from_extension(".flv") ->
    "video/x-flv";
from_extension(".gl") ->
    "video/gl";
from_extension(".mp4") ->
    "video/mp4";
from_extension(".mpe") ->
    "video/mpeg";
from_extension(".mpeg") ->
    "video/mpeg";
from_extension(".mpg") ->
    "video/mpeg";
from_extension(".mov") ->
    "video/quicktime";
from_extension(".qt") ->
    "video/quicktime";
from_extension(".viv") ->
    "video/vnd.vivo";
from_extension(".vivo") ->
    "video/vnd.vivo";
from_extension(".asf") ->
    "video/x-ms-asf";
from_extension(".asx") ->
    "video/x-ms-asx";
from_extension(".wmv") ->
    "video/x-ms-wmv";
from_extension(".wmx") ->
    "video/x-ms-wmx";
from_extension(".wvx") ->
    "video/x-ms-wvx";
from_extension(".avi") ->
    "video/x-msvideo";
from_extension(".movie") ->
    "video/x-sgi-movie";
from_extension(".mime") ->
    "www/mime";
from_extension(".ice") ->
    "x-conference/x-cooltalk";
from_extension(".vrm") ->
    "x-world/x-vrml";
from_extension(".spx") ->
    "audio/ogg";
from_extension(".xhtml") ->
    "application/xhtml+xml";
from_extension(".bz2") ->
    "application/x-bzip2";
from_extension(".doc") ->
    "application/msword";
from_extension(".z") ->
    "application/x-compress";
from_extension(".ico") ->
    "image/x-icon";
from_extension(".bmp") ->
    "image/bmp";
from_extension(".m4a") ->
    "audio/mpeg";
from_extension(".csv") ->
    "text/csv";
from_extension(".eot") ->
    "application/vnd.ms-fontobject";
from_extension(".m4v") ->
    "video/mp4";
from_extension(".svg") ->
    "image/svg+xml";
from_extension(".svgz") ->
    "image/svg+xml";
from_extension(".ttc") ->
    "application/x-font-ttf";
from_extension(".ttf") ->
    "application/x-font-ttf";
from_extension(".vcf") ->
    "text/x-vcard";
from_extension(".webm") ->
    "video/web";
from_extension(".webp") ->
    "image/web";
from_extension(".woff") ->
    "application/x-font-woff";
from_extension(".otf") ->
    "font/opentype";
from_extension(_) ->
    undefined.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

exhaustive_from_extension_test() ->
    T = mochiweb_cover:clause_lookup_table(?MODULE, from_extension),
    [?assertEqual(V, from_extension(K)) || {K, V} <- T].

from_extension_test() ->
    ?assertEqual("text/html",
                 from_extension(".html")),
    ?assertEqual(undefined,
                 from_extension("")),
    ?assertEqual(undefined,
                 from_extension(".wtf")),
    ok.

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Utilities for parsing multipart/form-data.

-module(mochiweb_multipart).
-author('bob@mochimedia.com').

-export([parse_form/1, parse_form/2]).
-export([parse_multipart_request/2]).
-export([parts_to_body/3, parts_to_multipart_body/4]).
-export([default_file_handler/2]).

-define(CHUNKSIZE, 4096).

-record(mp, {state, boundary, length, buffer, callback, req}).

%% TODO: DOCUMENT THIS MODULE.
%% @type key() = atom() | string() | binary().
%% @type value() = atom() | iolist() | integer().
%% @type header() = {key(), value()}.
%% @type bodypart() = {Start::integer(), End::integer(), Body::iolist()}.
%% @type formfile() = {Name::string(), ContentType::string(), Content::binary()}.
%% @type request().
%% @type file_handler() = (Filename::string(), ContentType::string()) -> file_handler_callback().
%% @type file_handler_callback() = (binary() | eof) -> file_handler_callback() | term().

%% @spec parts_to_body([bodypart()], ContentType::string(),
%%                     Size::integer()) -> {[header()], iolist()}
%% @doc Return {[header()], iolist()} representing the body for the given
%%      parts, may be a single part or multipart.
parts_to_body([{Start, End, Body}], ContentType, Size) ->
    HeaderList = [{"Content-Type", ContentType},
                  {"Content-Range",
                   ["bytes ",
                    mochiweb_util:make_io(Start), "-", mochiweb_util:make_io(End),
                    "/", mochiweb_util:make_io(Size)]}],
    {HeaderList, Body};
parts_to_body(BodyList, ContentType, Size) when is_list(BodyList) ->
    parts_to_multipart_body(BodyList, ContentType, Size,
                            mochihex:to_hex(crypto:rand_bytes(8))).

%% @spec parts_to_multipart_body([bodypart()], ContentType::string(),
%%                               Size::integer(), Boundary::string()) ->
%%           {[header()], iolist()}
%% @doc Return {[header()], iolist()} representing the body for the given
%%      parts, always a multipart response.
parts_to_multipart_body(BodyList, ContentType, Size, Boundary) ->
    HeaderList = [{"Content-Type",
                   ["multipart/byteranges; ",
                    "boundary=", Boundary]}],
    MultiPartBody = multipart_body(BodyList, ContentType, Boundary, Size),

    {HeaderList, MultiPartBody}.

%% @spec multipart_body([bodypart()], ContentType::string(),
%%                      Boundary::string(), Size::integer()) -> iolist()
%% @doc Return the representation of a multipart body for the given [bodypart()].
multipart_body([], _ContentType, Boundary, _Size) ->
    ["--", Boundary, "--\r\n"];
multipart_body([{Start, End, Body} | BodyList], ContentType, Boundary, Size) ->
    ["--", Boundary, "\r\n",
     "Content-Type: ", ContentType, "\r\n",
     "Content-Range: ",
         "bytes ", mochiweb_util:make_io(Start), "-", mochiweb_util:make_io(End),
             "/", mochiweb_util:make_io(Size), "\r\n\r\n",
     Body, "\r\n"
     | multipart_body(BodyList, ContentType, Boundary, Size)].

%% @spec parse_form(request()) -> [{string(), string() | formfile()}]
%% @doc Parse a multipart form from the given request using the in-memory
%%      default_file_handler/2.
parse_form(Req) ->
    parse_form(Req, fun default_file_handler/2).

%% @spec parse_form(request(), F::file_handler()) -> [{string(), string() | term()}]
%% @doc Parse a multipart form from the given request using the given file_handler().
parse_form(Req, FileHandler) ->
    Callback = fun (Next) -> parse_form_outer(Next, FileHandler, []) end,
    {_, _, Res} = parse_multipart_request(Req, Callback),
    Res.

parse_form_outer(eof, _, Acc) ->
    lists:reverse(Acc);
parse_form_outer({headers, H}, FileHandler, State) ->
    {"form-data", H1} = proplists:get_value("content-disposition", H),
    Name = proplists:get_value("name", H1),
    Filename = proplists:get_value("filename", H1),
    case Filename of
        undefined ->
            fun (Next) ->
                    parse_form_value(Next, {Name, []}, FileHandler, State)
            end;
        _ ->
            ContentType = proplists:get_value("content-type", H),
            Handler = FileHandler(Filename, ContentType),
            fun (Next) ->
                    parse_form_file(Next, {Name, Handler}, FileHandler, State)
            end
    end.

parse_form_value(body_end, {Name, Acc}, FileHandler, State) ->
    Value = binary_to_list(iolist_to_binary(lists:reverse(Acc))),
    State1 = [{Name, Value} | State],
    fun (Next) -> parse_form_outer(Next, FileHandler, State1) end;
parse_form_value({body, Data}, {Name, Acc}, FileHandler, State) ->
    Acc1 = [Data | Acc],
    fun (Next) -> parse_form_value(Next, {Name, Acc1}, FileHandler, State) end.

parse_form_file(body_end, {Name, Handler}, FileHandler, State) ->
    Value = Handler(eof),
    State1 = [{Name, Value} | State],
    fun (Next) -> parse_form_outer(Next, FileHandler, State1) end;
parse_form_file({body, Data}, {Name, Handler}, FileHandler, State) ->
    H1 = Handler(Data),
    fun (Next) -> parse_form_file(Next, {Name, H1}, FileHandler, State) end.

default_file_handler(Filename, ContentType) ->
    default_file_handler_1(Filename, ContentType, []).

default_file_handler_1(Filename, ContentType, Acc) ->
    fun(eof) ->
            Value = iolist_to_binary(lists:reverse(Acc)),
            {Filename, ContentType, Value};
       (Next) ->
            default_file_handler_1(Filename, ContentType, [Next | Acc])
    end.

parse_multipart_request(Req, Callback) ->
    %% TODO: Support chunked?
    Length = list_to_integer(Req:get_header_value("content-length")),
    Boundary = iolist_to_binary(
                 get_boundary(Req:get_header_value("content-type"))),
    Prefix = <<"\r\n--", Boundary/binary>>,
    BS = byte_size(Boundary),
    Chunk = read_chunk(Req, Length),
    Length1 = Length - byte_size(Chunk),
    <<"--", Boundary:BS/binary, "\r\n", Rest/binary>> = Chunk,
    feed_mp(headers, flash_multipart_hack(#mp{boundary=Prefix,
                                              length=Length1,
                                              buffer=Rest,
                                              callback=Callback,
                                              req=Req})).

parse_headers(<<>>) ->
    [];
parse_headers(Binary) ->
    parse_headers(Binary, []).

parse_headers(Binary, Acc) ->
    case find_in_binary(<<"\r\n">>, Binary) of
        {exact, N} ->
            <<Line:N/binary, "\r\n", Rest/binary>> = Binary,
            parse_headers(Rest, [split_header(Line) | Acc]);
        not_found ->
            lists:reverse([split_header(Binary) | Acc])
    end.

split_header(Line) ->
    {Name, [$: | Value]} = lists:splitwith(fun (C) -> C =/= $: end,
                                           binary_to_list(Line)),
    {string:to_lower(string:strip(Name)),
     mochiweb_util:parse_header(Value)}.

read_chunk(Req, Length) when Length > 0 ->
    case Length of
        Length when Length < ?CHUNKSIZE ->
            Req:recv(Length);
        _ ->
            Req:recv(?CHUNKSIZE)
    end.

read_more(State=#mp{length=Length, buffer=Buffer, req=Req}) ->
    Data = read_chunk(Req, Length),
    Buffer1 = <<Buffer/binary, Data/binary>>,
    flash_multipart_hack(State#mp{length=Length - byte_size(Data),
                                  buffer=Buffer1}).

flash_multipart_hack(State=#mp{length=0, buffer=Buffer, boundary=Prefix}) ->
    %% http://code.google.com/p/mochiweb/issues/detail?id=22
    %% Flash doesn't terminate multipart with \r\n properly so we fix it up here
    PrefixSize = size(Prefix),
    case size(Buffer) - (2 + PrefixSize) of
        Seek when Seek >= 0 ->
            case Buffer of
                <<_:Seek/binary, Prefix:PrefixSize/binary, "--">> ->
                    Buffer1 = <<Buffer/binary, "\r\n">>,
                    State#mp{buffer=Buffer1};
                _ ->
                    State
            end;
        _ ->
            State
    end;
flash_multipart_hack(State) ->
    State.

feed_mp(headers, State=#mp{buffer=Buffer, callback=Callback}) ->
    {State1, P} = case find_in_binary(<<"\r\n\r\n">>, Buffer) of
                      {exact, N} ->
                          {State, N};
                      _ ->
                          S1 = read_more(State),
                          %% Assume headers must be less than ?CHUNKSIZE
                          {exact, N} = find_in_binary(<<"\r\n\r\n">>,
                                                      S1#mp.buffer),
                          {S1, N}
                  end,
    <<Headers:P/binary, "\r\n\r\n", Rest/binary>> = State1#mp.buffer,
    NextCallback = Callback({headers, parse_headers(Headers)}),
    feed_mp(body, State1#mp{buffer=Rest,
                            callback=NextCallback});
feed_mp(body, State=#mp{boundary=Prefix, buffer=Buffer, callback=Callback}) ->
    Boundary = find_boundary(Prefix, Buffer),
    case Boundary of
        {end_boundary, Start, Skip} ->
            <<Data:Start/binary, _:Skip/binary, Rest/binary>> = Buffer,
            C1 = Callback({body, Data}),
            C2 = C1(body_end),
            {State#mp.length, Rest, C2(eof)};
        {next_boundary, Start, Skip} ->
            <<Data:Start/binary, _:Skip/binary, Rest/binary>> = Buffer,
            C1 = Callback({body, Data}),
            feed_mp(headers, State#mp{callback=C1(body_end),
                                      buffer=Rest});
        {maybe, Start} ->
            <<Data:Start/binary, Rest/binary>> = Buffer,
            feed_mp(body, read_more(State#mp{callback=Callback({body, Data}),
                                             buffer=Rest}));
        not_found ->
            {Data, Rest} = {Buffer, <<>>},
            feed_mp(body, read_more(State#mp{callback=Callback({body, Data}),
                                             buffer=Rest}))
    end.

get_boundary(ContentType) ->
    {"multipart/form-data", Opts} = mochiweb_util:parse_header(ContentType),
    case proplists:get_value("boundary", Opts) of
        S when is_list(S) ->
            S
    end.

%% @spec find_in_binary(Pattern::binary(), Data::binary()) ->
%%            {exact, N} | {partial, N, K} | not_found
%% @doc Searches for the given pattern in the given binary.
find_in_binary(P, Data) when size(P) > 0 ->
    PS = size(P),
    DS = size(Data),
    case DS - PS of
        Last when Last < 0 ->
            partial_find(P, Data, 0, DS);
        Last ->
            case binary:match(Data, P) of
                {Pos, _} -> {exact, Pos};
                nomatch -> partial_find(P, Data, Last+1, PS-1)
            end
    end.

partial_find(_B, _D, _N, 0) ->
    not_found;
partial_find(B, D, N, K) ->
    <<B1:K/binary, _/binary>> = B,
    case D of
        <<_Skip:N/binary, B1:K/binary>> ->
            {partial, N, K};
        _ ->
            partial_find(B, D, 1 + N, K - 1)
    end.

find_boundary(Prefix, Data) ->
    case find_in_binary(Prefix, Data) of
        {exact, Skip} ->
            PrefixSkip = Skip + size(Prefix),
            case Data of
                <<_:PrefixSkip/binary, "\r\n", _/binary>> ->
                    {next_boundary, Skip, size(Prefix) + 2};
                <<_:PrefixSkip/binary, "--\r\n", _/binary>> ->
                    {end_boundary, Skip, size(Prefix) + 4};
                _ when size(Data) < PrefixSkip + 4 ->
                    %% Underflow
                    {maybe, Skip};
                _ ->
                    %% False positive
                    not_found
            end;
        {partial, Skip, Length} when (Skip + Length) =:= size(Data) ->
            %% Underflow
            {maybe, Skip};
        _ ->
            not_found
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

ssl_cert_opts() ->
    EbinDir = filename:dirname(code:which(?MODULE)),
    CertDir = filename:join([EbinDir, "..", "support", "test-materials"]),
    CertFile = filename:join(CertDir, "test_ssl_cert.pem"),
    KeyFile = filename:join(CertDir, "test_ssl_key.pem"),
    [{certfile, CertFile}, {keyfile, KeyFile}].

with_socket_server(Transport, ServerFun, ClientFun) ->
    ServerOpts0 = [{ip, "127.0.0.1"}, {port, 0}, {loop, ServerFun}],
    ServerOpts = case Transport of
        plain ->
            ServerOpts0;
        ssl ->
            ServerOpts0 ++ [{ssl, true}, {ssl_opts, ssl_cert_opts()}]
    end,
    {ok, Server} = mochiweb_socket_server:start_link(ServerOpts),
    Port = mochiweb_socket_server:get(Server, port),
    ClientOpts = [binary, {active, false}],
    {ok, Client} = case Transport of
        plain ->
            gen_tcp:connect("127.0.0.1", Port, ClientOpts);
        ssl ->
            ClientOpts1 = [{ssl_imp, new} | ClientOpts],
            {ok, SslSocket} = ssl:connect("127.0.0.1", Port, ClientOpts1),
            {ok, {ssl, SslSocket}}
    end,
    Res = (catch ClientFun(Client)),
    mochiweb_socket_server:stop(Server),
    Res.

fake_request(Socket, ContentType, Length) ->
    mochiweb_request:new(Socket,
                         'POST',
                         "/multipart",
                         {1,1},
                         mochiweb_headers:make(
                           [{"content-type", ContentType},
                            {"content-length", Length}])).

test_callback({body, <<>>}, Rest=[body_end | _]) ->
    %% When expecting the body_end we might get an empty binary
    fun (Next) -> test_callback(Next, Rest) end;
test_callback({body, Got}, [{body, Expect} | Rest]) when Got =/= Expect ->
    %% Partial response
    GotSize = size(Got),
    <<Got:GotSize/binary, Expect1/binary>> = Expect,
    fun (Next) -> test_callback(Next, [{body, Expect1} | Rest]) end;
test_callback(Got, [Expect | Rest]) ->
    ?assertEqual(Got, Expect),
    case Rest of
        [] ->
            ok;
        _ ->
            fun (Next) -> test_callback(Next, Rest) end
    end.

parse3_http_test() ->
    parse3(plain).

parse3_https_test() ->
    parse3(ssl).

parse3(Transport) ->
    ContentType = "multipart/form-data; boundary=---------------------------7386909285754635891697677882",
    BinContent = <<"-----------------------------7386909285754635891697677882\r\nContent-Disposition: form-data; name=\"hidden\"\r\n\r\nmultipart message\r\n-----------------------------7386909285754635891697677882\r\nContent-Disposition: form-data; name=\"file\"; filename=\"test_file.txt\"\r\nContent-Type: text/plain\r\n\r\nWoo multiline text file\n\nLa la la\r\n-----------------------------7386909285754635891697677882--\r\n">>,
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "hidden"}]}}]},
              {body, <<"multipart message">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "file"}, {"filename", "test_file.txt"}]}},
                {"content-type", {"text/plain", []}}]},
              {body, <<"Woo multiline text file\n\nLa la la">>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

parse2_http_test() ->
    parse2(plain).

parse2_https_test() ->
    parse2(ssl).

parse2(Transport) ->
    ContentType = "multipart/form-data; boundary=---------------------------6072231407570234361599764024",
    BinContent = <<"-----------------------------6072231407570234361599764024\r\nContent-Disposition: form-data; name=\"hidden\"\r\n\r\nmultipart message\r\n-----------------------------6072231407570234361599764024\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\"\r\nContent-Type: application/octet-stream\r\n\r\n\r\n-----------------------------6072231407570234361599764024--\r\n">>,
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "hidden"}]}}]},
              {body, <<"multipart message">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "file"}, {"filename", ""}]}},
                {"content-type", {"application/octet-stream", []}}]},
              {body, <<>>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

parse_form_http_test() ->
    do_parse_form(plain).

parse_form_https_test() ->
    do_parse_form(ssl).

do_parse_form(Transport) ->
    ContentType = "multipart/form-data; boundary=AaB03x",
    "AaB03x" = get_boundary(ContentType),
    Content = mochiweb_util:join(
                ["--AaB03x",
                 "Content-Disposition: form-data; name=\"submit-name\"",
                 "",
                 "Larry",
                 "--AaB03x",
                 "Content-Disposition: form-data; name=\"files\";"
                 ++ "filename=\"file1.txt\"",
                 "Content-Type: text/plain",
                 "",
                 "... contents of file1.txt ...",
                 "--AaB03x--",
                 ""], "\r\n"),
    BinContent = iolist_to_binary(Content),
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_form(Req),
                        [{"submit-name", "Larry"},
                         {"files", {"file1.txt", {"text/plain",[]},
                                    <<"... contents of file1.txt ...">>}
                         }] = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

parse_http_test() ->
    do_parse(plain).

parse_https_test() ->
    do_parse(ssl).

do_parse(Transport) ->
    ContentType = "multipart/form-data; boundary=AaB03x",
    "AaB03x" = get_boundary(ContentType),
    Content = mochiweb_util:join(
                ["--AaB03x",
                 "Content-Disposition: form-data; name=\"submit-name\"",
                 "",
                 "Larry",
                 "--AaB03x",
                 "Content-Disposition: form-data; name=\"files\";"
                 ++ "filename=\"file1.txt\"",
                 "Content-Type: text/plain",
                 "",
                 "... contents of file1.txt ...",
                 "--AaB03x--",
                 ""], "\r\n"),
    BinContent = iolist_to_binary(Content),
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "submit-name"}]}}]},
              {body, <<"Larry">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "files"}, {"filename", "file1.txt"}]}},
                 {"content-type", {"text/plain", []}}]},
              {body, <<"... contents of file1.txt ...">>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

parse_partial_body_boundary_http_test() ->
   parse_partial_body_boundary(plain).

parse_partial_body_boundary_https_test() ->
   parse_partial_body_boundary(ssl).

parse_partial_body_boundary(Transport) ->
    Boundary = string:copies("$", 2048),
    ContentType = "multipart/form-data; boundary=" ++ Boundary,
    ?assertEqual(Boundary, get_boundary(ContentType)),
    Content = mochiweb_util:join(
                ["--" ++ Boundary,
                 "Content-Disposition: form-data; name=\"submit-name\"",
                 "",
                 "Larry",
                 "--" ++ Boundary,
                 "Content-Disposition: form-data; name=\"files\";"
                 ++ "filename=\"file1.txt\"",
                 "Content-Type: text/plain",
                 "",
                 "... contents of file1.txt ...",
                 "--" ++ Boundary ++ "--",
                 ""], "\r\n"),
    BinContent = iolist_to_binary(Content),
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "submit-name"}]}}]},
              {body, <<"Larry">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "files"}, {"filename", "file1.txt"}]}},
                {"content-type", {"text/plain", []}}
               ]},
              {body, <<"... contents of file1.txt ...">>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

parse_large_header_http_test() ->
    parse_large_header(plain).

parse_large_header_https_test() ->
    parse_large_header(ssl).

parse_large_header(Transport) ->
    ContentType = "multipart/form-data; boundary=AaB03x",
    "AaB03x" = get_boundary(ContentType),
    Content = mochiweb_util:join(
                ["--AaB03x",
                 "Content-Disposition: form-data; name=\"submit-name\"",
                 "",
                 "Larry",
                 "--AaB03x",
                 "Content-Disposition: form-data; name=\"files\";"
                 ++ "filename=\"file1.txt\"",
                 "Content-Type: text/plain",
                 "x-large-header: " ++ string:copies("%", 4096),
                 "",
                 "... contents of file1.txt ...",
                 "--AaB03x--",
                 ""], "\r\n"),
    BinContent = iolist_to_binary(Content),
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "submit-name"}]}}]},
              {body, <<"Larry">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "files"}, {"filename", "file1.txt"}]}},
                {"content-type", {"text/plain", []}},
                {"x-large-header", {string:copies("%", 4096), []}}
               ]},
              {body, <<"... contents of file1.txt ...">>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

find_boundary_test() ->
    B = <<"\r\n--X">>,
    {next_boundary, 0, 7} = find_boundary(B, <<"\r\n--X\r\nRest">>),
    {next_boundary, 1, 7} = find_boundary(B, <<"!\r\n--X\r\nRest">>),
    {end_boundary, 0, 9} = find_boundary(B, <<"\r\n--X--\r\nRest">>),
    {end_boundary, 1, 9} = find_boundary(B, <<"!\r\n--X--\r\nRest">>),
    not_found = find_boundary(B, <<"--X\r\nRest">>),
    {maybe, 0} = find_boundary(B, <<"\r\n--X\r">>),
    {maybe, 1} = find_boundary(B, <<"!\r\n--X\r">>),
    P = <<"\r\n-----------------------------16037454351082272548568224146">>,
    B0 = <<55,212,131,77,206,23,216,198,35,87,252,118,252,8,25,211,132,229,
          182,42,29,188,62,175,247,243,4,4,0,59, 13,10,45,45,45,45,45,45,45,
          45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,45,
          49,54,48,51,55,52,53,52,51,53,49>>,
    {maybe, 30} = find_boundary(P, B0),
    not_found = find_boundary(B, <<"\r\n--XJOPKE">>),
    ok.

find_in_binary_test() ->
    {exact, 0} = find_in_binary(<<"foo">>, <<"foobarbaz">>),
    {exact, 1} = find_in_binary(<<"oo">>, <<"foobarbaz">>),
    {exact, 8} = find_in_binary(<<"z">>, <<"foobarbaz">>),
    not_found = find_in_binary(<<"q">>, <<"foobarbaz">>),
    {partial, 7, 2} = find_in_binary(<<"azul">>, <<"foobarbaz">>),
    {exact, 0} = find_in_binary(<<"foobarbaz">>, <<"foobarbaz">>),
    {partial, 0, 3} = find_in_binary(<<"foobar">>, <<"foo">>),
    {partial, 1, 3} = find_in_binary(<<"foobar">>, <<"afoo">>),
    ok.

flash_parse_http_test() ->
    flash_parse(plain).

flash_parse_https_test() ->
    flash_parse(ssl).

flash_parse(Transport) ->
    ContentType = "multipart/form-data; boundary=----------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5",
    "----------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5" = get_boundary(ContentType),
    BinContent = <<"------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"Filename\"\r\n\r\nhello.txt\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"success_action_status\"\r\n\r\n201\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"file\"; filename=\"hello.txt\"\r\nContent-Type: application/octet-stream\r\n\r\nhello\n\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"Upload\"\r\n\r\nSubmit Query\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5--">>,
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "Filename"}]}}]},
              {body, <<"hello.txt">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "success_action_status"}]}}]},
              {body, <<"201">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "file"}, {"filename", "hello.txt"}]}},
                {"content-type", {"application/octet-stream", []}}]},
              {body, <<"hello\n">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "Upload"}]}}]},
              {body, <<"Submit Query">>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

flash_parse2_http_test() ->
    flash_parse2(plain).

flash_parse2_https_test() ->
    flash_parse2(ssl).

flash_parse2(Transport) ->
    ContentType = "multipart/form-data; boundary=----------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5",
    "----------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5" = get_boundary(ContentType),
    Chunk = iolist_to_binary(string:copies("%", 4096)),
    BinContent = <<"------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"Filename\"\r\n\r\nhello.txt\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"success_action_status\"\r\n\r\n201\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"file\"; filename=\"hello.txt\"\r\nContent-Type: application/octet-stream\r\n\r\n", Chunk/binary, "\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"Upload\"\r\n\r\nSubmit Query\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5--">>,
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "Filename"}]}}]},
              {body, <<"hello.txt">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "success_action_status"}]}}]},
              {body, <<"201">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "file"}, {"filename", "hello.txt"}]}},
                {"content-type", {"application/octet-stream", []}}]},
              {body, Chunk},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "Upload"}]}}]},
              {body, <<"Submit Query">>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(Transport, ServerFun, ClientFun),
    ok.

parse_headers_test() ->
    ?assertEqual([], parse_headers(<<>>)).

flash_multipart_hack_test() ->
    Buffer = <<"prefix-">>,
    Prefix = <<"prefix">>,
    State = #mp{length=0, buffer=Buffer, boundary=Prefix},
    ?assertEqual(State,
                 flash_multipart_hack(State)).

parts_to_body_single_test() ->
    {HL, B} = parts_to_body([{0, 5, <<"01234">>}],
                            "text/plain",
                            10),
    [{"Content-Range", Range},
     {"Content-Type", Type}] = lists:sort(HL),
    ?assertEqual(
       <<"bytes 0-5/10">>,
       iolist_to_binary(Range)),
    ?assertEqual(
       <<"text/plain">>,
       iolist_to_binary(Type)),
    ?assertEqual(
       <<"01234">>,
       iolist_to_binary(B)),
    ok.

parts_to_body_multi_test() ->
    {[{"Content-Type", Type}],
     _B} = parts_to_body([{0, 5, <<"01234">>}, {5, 10, <<"56789">>}],
                        "text/plain",
                        10),
    ?assertMatch(
       <<"multipart/byteranges; boundary=", _/binary>>,
       iolist_to_binary(Type)),
    ok.

parts_to_multipart_body_test() ->
    {[{"Content-Type", V}], B} = parts_to_multipart_body(
                                   [{0, 5, <<"01234">>}, {5, 10, <<"56789">>}],
                                   "text/plain",
                                   10,
                                   "BOUNDARY"),
    MB = multipart_body(
           [{0, 5, <<"01234">>}, {5, 10, <<"56789">>}],
           "text/plain",
           "BOUNDARY",
           10),
    ?assertEqual(
       <<"multipart/byteranges; boundary=BOUNDARY">>,
       iolist_to_binary(V)),
    ?assertEqual(
       iolist_to_binary(MB),
       iolist_to_binary(B)),
    ok.

multipart_body_test() ->
    ?assertEqual(
       <<"--BOUNDARY--\r\n">>,
       iolist_to_binary(multipart_body([], "text/plain", "BOUNDARY", 0))),
    ?assertEqual(
       <<"--BOUNDARY\r\n"
         "Content-Type: text/plain\r\n"
         "Content-Range: bytes 0-5/10\r\n\r\n"
         "01234\r\n"
         "--BOUNDARY\r\n"
         "Content-Type: text/plain\r\n"
         "Content-Range: bytes 5-10/10\r\n\r\n"
         "56789\r\n"
         "--BOUNDARY--\r\n">>,
       iolist_to_binary(multipart_body([{0, 5, <<"01234">>}, {5, 10, <<"56789">>}],
                                       "text/plain",
                                       "BOUNDARY",
                                       10))),
    ok.

%% @todo Move somewhere more appropriate than in the test suite

multipart_parsing_benchmark_test() ->
  run_multipart_parsing_benchmark(1).

run_multipart_parsing_benchmark(0) -> ok;
run_multipart_parsing_benchmark(N) ->
     multipart_parsing_benchmark(),
     run_multipart_parsing_benchmark(N-1).

multipart_parsing_benchmark() ->
    ContentType = "multipart/form-data; boundary=----------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5",
    Chunk = binary:copy(<<"This Is_%Some=Quite0Long4String2Used9For7BenchmarKing.5">>, 102400),
    BinContent = <<"------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"Filename\"\r\n\r\nhello.txt\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"success_action_status\"\r\n\r\n201\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"file\"; filename=\"hello.txt\"\r\nContent-Type: application/octet-stream\r\n\r\n", Chunk/binary, "\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5\r\nContent-Disposition: form-data; name=\"Upload\"\r\n\r\nSubmit Query\r\n------------ei4GI3GI3Ij5Ef1ae0KM7Ij5ei4Ij5--">>,
    Expect = [{headers,
               [{"content-disposition",
                 {"form-data", [{"name", "Filename"}]}}]},
              {body, <<"hello.txt">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "success_action_status"}]}}]},
              {body, <<"201">>},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "file"}, {"filename", "hello.txt"}]}},
                {"content-type", {"application/octet-stream", []}}]},
              {body, Chunk},
              body_end,
              {headers,
               [{"content-disposition",
                 {"form-data", [{"name", "Upload"}]}}]},
              {body, <<"Submit Query">>},
              body_end,
              eof],
    TestCallback = fun (Next) -> test_callback(Next, Expect) end,
    ServerFun = fun (Socket) ->
                        ok = mochiweb_socket:send(Socket, BinContent),
                        exit(normal)
                end,
    ClientFun = fun (Socket) ->
                        Req = fake_request(Socket, ContentType,
                                           byte_size(BinContent)),
                        Res = parse_multipart_request(Req, TestCallback),
                        {0, <<>>, ok} = Res,
                        ok
                end,
    ok = with_socket_server(plain, ServerFun, ClientFun),
    ok.
-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc MochiWeb HTTP Request abstraction.

-module(mochiweb_request, [Socket, Method, RawPath, Version, Headers]).
-author('bob@mochimedia.com').

-include_lib("kernel/include/file.hrl").
-include("internal.hrl").

-define(QUIP, "Any of you quaids got a smint?").

-export([get_header_value/1, get_primary_header_value/1, get/1, dump/0]).
-export([send/1, recv/1, recv/2, recv_body/0, recv_body/1, stream_body/3]).
-export([start_response/1, start_response_length/1, start_raw_response/1]).
-export([respond/1, ok/1]).
-export([not_found/0, not_found/1]).
-export([parse_post/0, parse_qs/0]).
-export([should_close/0, cleanup/0]).
-export([parse_cookie/0, get_cookie_value/1]).
-export([serve_file/2, serve_file/3]).
-export([accepted_encodings/1]).
-export([accepts_content_type/1, accepted_content_types/1]).

-define(SAVE_QS, mochiweb_request_qs).
-define(SAVE_PATH, mochiweb_request_path).
-define(SAVE_RECV, mochiweb_request_recv).
-define(SAVE_BODY, mochiweb_request_body).
-define(SAVE_BODY_LENGTH, mochiweb_request_body_length).
-define(SAVE_POST, mochiweb_request_post).
-define(SAVE_COOKIE, mochiweb_request_cookie).
-define(SAVE_FORCE_CLOSE, mochiweb_request_force_close).

%% @type iolist() = [iolist() | binary() | char()].
%% @type iodata() = binary() | iolist().
%% @type key() = atom() | string() | binary()
%% @type value() = atom() | string() | binary() | integer()
%% @type headers(). A mochiweb_headers structure.
%% @type response(). A mochiweb_response parameterized module instance.
%% @type ioheaders() = headers() | [{key(), value()}].

% 5 minute default idle timeout
-define(IDLE_TIMEOUT, 300000).

% Maximum recv_body() length of 1MB
-define(MAX_RECV_BODY, (1024*1024)).

%% @spec get_header_value(K) -> undefined | Value
%% @doc Get the value of a given request header.
get_header_value(K) ->
    mochiweb_headers:get_value(K, Headers).

get_primary_header_value(K) ->
    mochiweb_headers:get_primary_value(K, Headers).

%% @type field() = socket | scheme | method | raw_path | version | headers | peer | path | body_length | range

%% @spec get(field()) -> term()
%% @doc Return the internal representation of the given field. If
%%      <code>socket</code> is requested on a HTTPS connection, then
%%      an ssl socket will be returned as <code>{ssl, SslSocket}</code>.
%%      You can use <code>SslSocket</code> with the <code>ssl</code>
%%      application, eg: <code>ssl:peercert(SslSocket)</code>.
get(socket) ->
    Socket;
get(scheme) ->
    case mochiweb_socket:type(Socket) of
        plain ->
            http;
        ssl ->
            https
    end;
get(method) ->
    Method;
get(raw_path) ->
    RawPath;
get(version) ->
    Version;
get(headers) ->
    Headers;
get(peer) ->
    case mochiweb_socket:peername(Socket) of
        {ok, {Addr={10, _, _, _}, _Port}} ->
            case get_header_value("x-forwarded-for") of
                undefined ->
                    inet_parse:ntoa(Addr);
                Hosts ->
                    string:strip(lists:last(string:tokens(Hosts, ",")))
            end;
        {ok, {{127, 0, 0, 1}, _Port}} ->
            case get_header_value("x-forwarded-for") of
                undefined ->
                    "127.0.0.1";
                Hosts ->
                    string:strip(lists:last(string:tokens(Hosts, ",")))
            end;
        {ok, {Addr, _Port}} ->
            inet_parse:ntoa(Addr);
        {error, enotconn} ->
            exit(normal)
    end;
get(path) ->
    case erlang:get(?SAVE_PATH) of
        undefined ->
            {Path0, _, _} = mochiweb_util:urlsplit_path(RawPath),
            Path = mochiweb_util:unquote(Path0),
            put(?SAVE_PATH, Path),
            Path;
        Cached ->
            Cached
    end;
get(body_length) ->
    case erlang:get(?SAVE_BODY_LENGTH) of
        undefined ->
            BodyLength = body_length(),
            put(?SAVE_BODY_LENGTH, {cached, BodyLength}),
            BodyLength;
        {cached, Cached} ->
            Cached
    end;
get(range) ->
    case get_header_value(range) of
        undefined ->
            undefined;
        RawRange ->
            mochiweb_http:parse_range_request(RawRange)
    end.

%% @spec dump() -> {mochiweb_request, [{atom(), term()}]}
%% @doc Dump the internal representation to a "human readable" set of terms
%%      for debugging/inspection purposes.
dump() ->
    {?MODULE, [{method, Method},
               {version, Version},
               {raw_path, RawPath},
               {headers, mochiweb_headers:to_list(Headers)}]}.

%% @spec send(iodata()) -> ok
%% @doc Send data over the socket.
send(Data) ->
    case mochiweb_socket:send(Socket, Data) of
        ok ->
            ok;
        _ ->
            exit(normal)
    end.

%% @spec recv(integer()) -> binary()
%% @doc Receive Length bytes from the client as a binary, with the default
%%      idle timeout.
recv(Length) ->
    recv(Length, ?IDLE_TIMEOUT).

%% @spec recv(integer(), integer()) -> binary()
%% @doc Receive Length bytes from the client as a binary, with the given
%%      Timeout in msec.
recv(Length, Timeout) ->
    case mochiweb_socket:recv(Socket, Length, Timeout) of
        {ok, Data} ->
            put(?SAVE_RECV, true),
            Data;
        _ ->
            exit(normal)
    end.

%% @spec body_length() -> undefined | chunked | unknown_transfer_encoding | integer()
%% @doc  Infer body length from transfer-encoding and content-length headers.
body_length() ->
    case get_header_value("transfer-encoding") of
        undefined ->
            case get_header_value("content-length") of
                undefined ->
                    undefined;
                Length ->
                    list_to_integer(Length)
            end;
        "chunked" ->
            chunked;
        Unknown ->
            {unknown_transfer_encoding, Unknown}
    end.


%% @spec recv_body() -> binary()
%% @doc Receive the body of the HTTP request (defined by Content-Length).
%%      Will only receive up to the default max-body length of 1MB.
recv_body() ->
    recv_body(?MAX_RECV_BODY).

%% @spec recv_body(integer()) -> binary()
%% @doc Receive the body of the HTTP request (defined by Content-Length).
%%      Will receive up to MaxBody bytes.
recv_body(MaxBody) ->
    case erlang:get(?SAVE_BODY) of
        undefined ->
            % we could use a sane constant for max chunk size
            Body = stream_body(?MAX_RECV_BODY, fun
                ({0, _ChunkedFooter}, {_LengthAcc, BinAcc}) ->
                    iolist_to_binary(lists:reverse(BinAcc));
                ({Length, Bin}, {LengthAcc, BinAcc}) ->
                    NewLength = Length + LengthAcc,
                    if NewLength > MaxBody ->
                        exit({body_too_large, chunked});
                    true ->
                        {NewLength, [Bin | BinAcc]}
                    end
                end, {0, []}, MaxBody),
            put(?SAVE_BODY, Body),
            Body;
        Cached -> Cached
    end.

stream_body(MaxChunkSize, ChunkFun, FunState) ->
    stream_body(MaxChunkSize, ChunkFun, FunState, undefined).

stream_body(MaxChunkSize, ChunkFun, FunState, MaxBodyLength) ->
    Expect = case get_header_value("expect") of
                 undefined ->
                     undefined;
                 Value when is_list(Value) ->
                     string:to_lower(Value)
             end,
    case Expect of
        "100-continue" ->
            _ = start_raw_response({100, gb_trees:empty()}),
            ok;
        _Else ->
            ok
    end,
    case body_length() of
        undefined ->
            undefined;
        {unknown_transfer_encoding, Unknown} ->
            exit({unknown_transfer_encoding, Unknown});
        chunked ->
            % In this case the MaxBody is actually used to
            % determine the maximum allowed size of a single
            % chunk.
            stream_chunked_body(MaxChunkSize, ChunkFun, FunState);
        0 ->
            <<>>;
        Length when is_integer(Length) ->
            case MaxBodyLength of
            MaxBodyLength when is_integer(MaxBodyLength), MaxBodyLength < Length ->
                exit({body_too_large, content_length});
            _ ->
                stream_unchunked_body(Length, ChunkFun, FunState)
            end
    end.


%% @spec start_response({integer(), ioheaders()}) -> response()
%% @doc Start the HTTP response by sending the Code HTTP response and
%%      ResponseHeaders. The server will set header defaults such as Server
%%      and Date if not present in ResponseHeaders.
start_response({Code, ResponseHeaders}) ->
    HResponse = mochiweb_headers:make(ResponseHeaders),
    HResponse1 = mochiweb_headers:default_from_list(server_headers(),
                                                    HResponse),
    start_raw_response({Code, HResponse1}).

%% @spec start_raw_response({integer(), headers()}) -> response()
%% @doc Start the HTTP response by sending the Code HTTP response and
%%      ResponseHeaders.
start_raw_response({Code, ResponseHeaders}) ->
    F = fun ({K, V}, Acc) ->
                [mochiweb_util:make_io(K), <<": ">>, V, <<"\r\n">> | Acc]
        end,
    End = lists:foldl(F, [<<"\r\n">>],
                      mochiweb_headers:to_list(ResponseHeaders)),
    send([make_version(Version), make_code(Code), <<"\r\n">> | End]),
    mochiweb:new_response({THIS, Code, ResponseHeaders}).


%% @spec start_response_length({integer(), ioheaders(), integer()}) -> response()
%% @doc Start the HTTP response by sending the Code HTTP response and
%%      ResponseHeaders including a Content-Length of Length. The server
%%      will set header defaults such as Server
%%      and Date if not present in ResponseHeaders.
start_response_length({Code, ResponseHeaders, Length}) ->
    HResponse = mochiweb_headers:make(ResponseHeaders),
    HResponse1 = mochiweb_headers:enter("Content-Length", Length, HResponse),
    start_response({Code, HResponse1}).

%% @spec respond({integer(), ioheaders(), iodata() | chunked | {file, IoDevice}}) -> response()
%% @doc Start the HTTP response with start_response, and send Body to the
%%      client (if the get(method) /= 'HEAD'). The Content-Length header
%%      will be set by the Body length, and the server will insert header
%%      defaults.
respond({Code, ResponseHeaders, {file, IoDevice}}) ->
    Length = mochiweb_io:iodevice_size(IoDevice),
    Response = start_response_length({Code, ResponseHeaders, Length}),
    case Method of
        'HEAD' ->
            ok;
        _ ->
            mochiweb_io:iodevice_stream(fun send/1, IoDevice)
    end,
    Response;
respond({Code, ResponseHeaders, chunked}) ->
    HResponse = mochiweb_headers:make(ResponseHeaders),
    HResponse1 = case Method of
                     'HEAD' ->
                         %% This is what Google does, http://www.google.com/
                         %% is chunked but HEAD gets Content-Length: 0.
                         %% The RFC is ambiguous so emulating Google is smart.
                         mochiweb_headers:enter("Content-Length", "0",
                                                HResponse);
                     _ when Version >= {1, 1} ->
                         %% Only use chunked encoding for HTTP/1.1
                         mochiweb_headers:enter("Transfer-Encoding", "chunked",
                                                HResponse);
                     _ ->
                         %% For pre-1.1 clients we send the data as-is
                         %% without a Content-Length header and without
                         %% chunk delimiters. Since the end of the document
                         %% is now ambiguous we must force a close.
                         put(?SAVE_FORCE_CLOSE, true),
                         HResponse
                 end,
    start_response({Code, HResponse1});
respond({Code, ResponseHeaders, Body}) ->
    Response = start_response_length({Code, ResponseHeaders, iolist_size(Body)}),
    case Method of
        'HEAD' ->
            ok;
        _ ->
            send(Body)
    end,
    Response.

%% @spec not_found() -> response()
%% @doc Alias for <code>not_found([])</code>.
not_found() ->
    not_found([]).

%% @spec not_found(ExtraHeaders) -> response()
%% @doc Alias for <code>respond({404, [{"Content-Type", "text/plain"}
%% | ExtraHeaders], &lt;&lt;"Not found."&gt;&gt;})</code>.
not_found(ExtraHeaders) ->
    respond({404, [{"Content-Type", "text/plain"} | ExtraHeaders],
             <<"Not found.">>}).

%% @spec ok({value(), iodata()} | {value(), ioheaders(), iodata() | {file, IoDevice}}) ->
%%           response()
%% @doc respond({200, [{"Content-Type", ContentType} | Headers], Body}).
ok({ContentType, Body}) ->
    ok({ContentType, [], Body});
ok({ContentType, ResponseHeaders, Body}) ->
    HResponse = mochiweb_headers:make(ResponseHeaders),
    case THIS:get(range) of
        X when (X =:= undefined orelse X =:= fail) orelse Body =:= chunked ->
            %% http://code.google.com/p/mochiweb/issues/detail?id=54
            %% Range header not supported when chunked, return 200 and provide
            %% full response.
            HResponse1 = mochiweb_headers:enter("Content-Type", ContentType,
                                                HResponse),
            respond({200, HResponse1, Body});
        Ranges ->
            {PartList, Size} = range_parts(Body, Ranges),
            case PartList of
                [] -> %% no valid ranges
                    HResponse1 = mochiweb_headers:enter("Content-Type",
                                                        ContentType,
                                                        HResponse),
                    %% could be 416, for now we'll just return 200
                    respond({200, HResponse1, Body});
                PartList ->
                    {RangeHeaders, RangeBody} =
                        mochiweb_multipart:parts_to_body(PartList, ContentType, Size),
                    HResponse1 = mochiweb_headers:enter_from_list(
                                   [{"Accept-Ranges", "bytes"} |
                                    RangeHeaders],
                                   HResponse),
                    respond({206, HResponse1, RangeBody})
            end
    end.

%% @spec should_close() -> bool()
%% @doc Return true if the connection must be closed. If false, using
%%      Keep-Alive should be safe.
should_close() ->
    ForceClose = erlang:get(?SAVE_FORCE_CLOSE) =/= undefined,
    DidNotRecv = erlang:get(?SAVE_RECV) =:= undefined,
    ForceClose orelse Version < {1, 0}
        %% Connection: close
        orelse get_header_value("connection") =:= "close"
        %% HTTP 1.0 requires Connection: Keep-Alive
        orelse (Version =:= {1, 0}
                andalso get_header_value("connection") =/= "Keep-Alive")
        %% unread data left on the socket, can't safely continue
        orelse (DidNotRecv
                andalso get_header_value("content-length") =/= undefined
                andalso list_to_integer(get_header_value("content-length")) > 0)
        orelse (DidNotRecv
                andalso get_header_value("transfer-encoding") =:= "chunked").

%% @spec cleanup() -> ok
%% @doc Clean up any junk in the process dictionary, required before continuing
%%      a Keep-Alive request.
cleanup() ->
    L = [?SAVE_QS, ?SAVE_PATH, ?SAVE_RECV, ?SAVE_BODY, ?SAVE_BODY_LENGTH,
         ?SAVE_POST, ?SAVE_COOKIE, ?SAVE_FORCE_CLOSE],
    lists:foreach(fun(K) ->
                          erase(K)
                  end, L),
    ok.

%% @spec parse_qs() -> [{Key::string(), Value::string()}]
%% @doc Parse the query string of the URL.
parse_qs() ->
    case erlang:get(?SAVE_QS) of
        undefined ->
            {_, QueryString, _} = mochiweb_util:urlsplit_path(RawPath),
            Parsed = mochiweb_util:parse_qs(QueryString),
            put(?SAVE_QS, Parsed),
            Parsed;
        Cached ->
            Cached
    end.

%% @spec get_cookie_value(Key::string) -> string() | undefined
%% @doc Get the value of the given cookie.
get_cookie_value(Key) ->
    proplists:get_value(Key, parse_cookie()).

%% @spec parse_cookie() -> [{Key::string(), Value::string()}]
%% @doc Parse the cookie header.
parse_cookie() ->
    case erlang:get(?SAVE_COOKIE) of
        undefined ->
            Cookies = case get_header_value("cookie") of
                          undefined ->
                              [];
                          Value ->
                              mochiweb_cookies:parse_cookie(Value)
                      end,
            put(?SAVE_COOKIE, Cookies),
            Cookies;
        Cached ->
            Cached
    end.

%% @spec parse_post() -> [{Key::string(), Value::string()}]
%% @doc Parse an application/x-www-form-urlencoded form POST. This
%%      has the side-effect of calling recv_body().
parse_post() ->
    case erlang:get(?SAVE_POST) of
        undefined ->
            Parsed = case recv_body() of
                         undefined ->
                             [];
                         Binary ->
                             case get_primary_header_value("content-type") of
                                 "application/x-www-form-urlencoded" ++ _ ->
                                     mochiweb_util:parse_qs(Binary);
                                 _ ->
                                     []
                             end
                     end,
            put(?SAVE_POST, Parsed),
            Parsed;
        Cached ->
            Cached
    end.

%% @spec stream_chunked_body(integer(), fun(), term()) -> term()
%% @doc The function is called for each chunk.
%%      Used internally by read_chunked_body.
stream_chunked_body(MaxChunkSize, Fun, FunState) ->
    case read_chunk_length() of
        0 ->
            Fun({0, read_chunk(0)}, FunState);
        Length when Length > MaxChunkSize ->
            NewState = read_sub_chunks(Length, MaxChunkSize, Fun, FunState),
            stream_chunked_body(MaxChunkSize, Fun, NewState);
        Length ->
            NewState = Fun({Length, read_chunk(Length)}, FunState),
            stream_chunked_body(MaxChunkSize, Fun, NewState)
    end.

stream_unchunked_body(0, Fun, FunState) ->
    Fun({0, <<>>}, FunState);
stream_unchunked_body(Length, Fun, FunState) when Length > 0 ->
    PktSize = case Length > ?RECBUF_SIZE of
        true ->
            ?RECBUF_SIZE;
        false ->
            Length
    end,
    Bin = recv(PktSize),
    NewState = Fun({PktSize, Bin}, FunState),
    stream_unchunked_body(Length - PktSize, Fun, NewState).

%% @spec read_chunk_length() -> integer()
%% @doc Read the length of the next HTTP chunk.
read_chunk_length() ->
    ok = mochiweb_socket:setopts(Socket, [{packet, line}]),
    case mochiweb_socket:recv(Socket, 0, ?IDLE_TIMEOUT) of
        {ok, Header} ->
            ok = mochiweb_socket:setopts(Socket, [{packet, raw}]),
            Splitter = fun (C) ->
                               C =/= $\r andalso C =/= $\n andalso C =/= $
                       end,
            {Hex, _Rest} = lists:splitwith(Splitter, binary_to_list(Header)),
            mochihex:to_int(Hex);
        _ ->
            exit(normal)
    end.

%% @spec read_chunk(integer()) -> Chunk::binary() | [Footer::binary()]
%% @doc Read in a HTTP chunk of the given length. If Length is 0, then read the
%%      HTTP footers (as a list of binaries, since they're nominal).
read_chunk(0) ->
    ok = mochiweb_socket:setopts(Socket, [{packet, line}]),
    F = fun (F1, Acc) ->
                case mochiweb_socket:recv(Socket, 0, ?IDLE_TIMEOUT) of
                    {ok, <<"\r\n">>} ->
                        Acc;
                    {ok, Footer} ->
                        F1(F1, [Footer | Acc]);
                    _ ->
                        exit(normal)
                end
        end,
    Footers = F(F, []),
    ok = mochiweb_socket:setopts(Socket, [{packet, raw}]),
    put(?SAVE_RECV, true),
    Footers;
read_chunk(Length) ->
    case mochiweb_socket:recv(Socket, 2 + Length, ?IDLE_TIMEOUT) of
        {ok, <<Chunk:Length/binary, "\r\n">>} ->
            Chunk;
        _ ->
            exit(normal)
    end.

read_sub_chunks(Length, MaxChunkSize, Fun, FunState) when Length > MaxChunkSize ->
    Bin = recv(MaxChunkSize),
    NewState = Fun({size(Bin), Bin}, FunState),
    read_sub_chunks(Length - MaxChunkSize, MaxChunkSize, Fun, NewState);

read_sub_chunks(Length, _MaxChunkSize, Fun, FunState) ->
    Fun({Length, read_chunk(Length)}, FunState).

%% @spec serve_file(Path, DocRoot) -> Response
%% @doc Serve a file relative to DocRoot.
serve_file(Path, DocRoot) ->
    serve_file(Path, DocRoot, []).

%% @spec serve_file(Path, DocRoot, ExtraHeaders) -> Response
%% @doc Serve a file relative to DocRoot.
serve_file(Path, DocRoot, ExtraHeaders) ->
    case mochiweb_util:safe_relative_path(Path) of
        undefined ->
            not_found(ExtraHeaders);
        RelPath ->
            FullPath = filename:join([DocRoot, RelPath]),
            case filelib:is_dir(FullPath) of
                true ->
                    maybe_redirect(RelPath, FullPath, ExtraHeaders);
                false ->
                    maybe_serve_file(FullPath, ExtraHeaders)
            end
    end.

%% Internal API

%% This has the same effect as the DirectoryIndex directive in httpd
directory_index(FullPath) ->
    filename:join([FullPath, "index.html"]).

maybe_redirect([], FullPath, ExtraHeaders) ->
    maybe_serve_file(directory_index(FullPath), ExtraHeaders);

maybe_redirect(RelPath, FullPath, ExtraHeaders) ->
    case string:right(RelPath, 1) of
        "/" ->
            maybe_serve_file(directory_index(FullPath), ExtraHeaders);
        _   ->
            Host = mochiweb_headers:get_value("host", Headers),
            Location = "http://" ++ Host  ++ "/" ++ RelPath ++ "/",
            LocationBin = list_to_binary(Location),
            MoreHeaders = [{"Location", Location},
                           {"Content-Type", "text/html"} | ExtraHeaders],
            Top = <<"<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">"
            "<html><head>"
            "<title>301 Moved Permanently</title>"
            "</head><body>"
            "<h1>Moved Permanently</h1>"
            "<p>The document has moved <a href=\"">>,
            Bottom = <<">here</a>.</p></body></html>\n">>,
            Body = <<Top/binary, LocationBin/binary, Bottom/binary>>,
            respond({301, MoreHeaders, Body})
    end.

maybe_serve_file(File, ExtraHeaders) ->
    case file:read_file_info(File) of
        {ok, FileInfo} ->
            LastModified = httpd_util:rfc1123_date(FileInfo#file_info.mtime),
            case get_header_value("if-modified-since") of
                LastModified ->
                    respond({304, ExtraHeaders, ""});
                _ ->
                    case file:open(File, [raw, binary]) of
                        {ok, IoDevice} ->
                            ContentType = mochiweb_util:guess_mime(File),
                            Res = ok({ContentType,
                                      [{"last-modified", LastModified}
                                       | ExtraHeaders],
                                      {file, IoDevice}}),
                            ok = file:close(IoDevice),
                            Res;
                        _ ->
                            not_found(ExtraHeaders)
                    end
            end;
        {error, _} ->
            not_found(ExtraHeaders)
    end.

server_headers() ->
    [{"Server", "MochiWeb/1.0 (" ++ ?QUIP ++ ")"},
     {"Date", httpd_util:rfc1123_date()}].

make_code(X) when is_integer(X) ->
    [integer_to_list(X), [" " | httpd_util:reason_phrase(X)]];
make_code(Io) when is_list(Io); is_binary(Io) ->
    Io.

make_version({1, 0}) ->
    <<"HTTP/1.0 ">>;
make_version(_) ->
    <<"HTTP/1.1 ">>.

range_parts({file, IoDevice}, Ranges) ->
    Size = mochiweb_io:iodevice_size(IoDevice),
    F = fun (Spec, Acc) ->
                case mochiweb_http:range_skip_length(Spec, Size) of
                    invalid_range ->
                        Acc;
                    V ->
                        [V | Acc]
                end
        end,
    LocNums = lists:foldr(F, [], Ranges),
    {ok, Data} = file:pread(IoDevice, LocNums),
    Bodies = lists:zipwith(fun ({Skip, Length}, PartialBody) ->
                                   {Skip, Skip + Length - 1, PartialBody}
                           end,
                           LocNums, Data),
    {Bodies, Size};
range_parts(Body0, Ranges) ->
    Body = iolist_to_binary(Body0),
    Size = size(Body),
    F = fun(Spec, Acc) ->
                case mochiweb_http:range_skip_length(Spec, Size) of
                    invalid_range ->
                        Acc;
                    {Skip, Length} ->
                        <<_:Skip/binary, PartialBody:Length/binary, _/binary>> = Body,
                        [{Skip, Skip + Length - 1, PartialBody} | Acc]
                end
        end,
    {lists:foldr(F, [], Ranges), Size}.

%% @spec accepted_encodings([encoding()]) -> [encoding()] | bad_accept_encoding_value
%% @type encoding() = string().
%%
%% @doc Returns a list of encodings accepted by a request. Encodings that are
%%      not supported by the server will not be included in the return list.
%%      This list is computed from the "Accept-Encoding" header and
%%      its elements are ordered, descendingly, according to their Q values.
%%
%%      Section 14.3 of the RFC 2616 (HTTP 1.1) describes the "Accept-Encoding"
%%      header and the process of determining which server supported encodings
%%      can be used for encoding the body for the request's response.
%%
%%      Examples
%%
%%      1) For a missing "Accept-Encoding" header:
%%         accepted_encodings(["gzip", "identity"]) -> ["identity"]
%%
%%      2) For an "Accept-Encoding" header with value "gzip, deflate":
%%         accepted_encodings(["gzip", "identity"]) -> ["gzip", "identity"]
%%
%%      3) For an "Accept-Encoding" header with value "gzip;q=0.5, deflate":
%%         accepted_encodings(["gzip", "deflate", "identity"]) ->
%%            ["deflate", "gzip", "identity"]
%%
accepted_encodings(SupportedEncodings) ->
    AcceptEncodingHeader = case get_header_value("Accept-Encoding") of
        undefined ->
            "";
        Value ->
            Value
    end,
    case mochiweb_util:parse_qvalues(AcceptEncodingHeader) of
        invalid_qvalue_string ->
            bad_accept_encoding_value;
        QList ->
            mochiweb_util:pick_accepted_encodings(
                QList, SupportedEncodings, "identity"
            )
    end.

%% @spec accepts_content_type(string() | binary()) -> boolean() | bad_accept_header
%%
%% @doc Determines whether a request accepts a given media type by analyzing its
%%      "Accept" header.
%%
%%      Examples
%%
%%      1) For a missing "Accept" header:
%%         accepts_content_type("application/json") -> true
%%
%%      2) For an "Accept" header with value "text/plain, application/*":
%%         accepts_content_type("application/json") -> true
%%
%%      3) For an "Accept" header with value "text/plain, */*; q=0.0":
%%         accepts_content_type("application/json") -> false
%%
%%      4) For an "Accept" header with value "text/plain; q=0.5, */*; q=0.1":
%%         accepts_content_type("application/json") -> true
%%
%%      5) For an "Accept" header with value "text/*; q=0.0, */*":
%%         accepts_content_type("text/plain") -> false
%%
accepts_content_type(ContentType1) ->
    ContentType = re:replace(ContentType1, "\\s", "", [global, {return, list}]),
    AcceptHeader = accept_header(),
    case mochiweb_util:parse_qvalues(AcceptHeader) of
        invalid_qvalue_string ->
            bad_accept_header;
        QList ->
            [MainType, _SubType] = string:tokens(ContentType, "/"),
            SuperType = MainType ++ "/*",
            lists:any(
                fun({"*/*", Q}) when Q > 0.0 ->
                        true;
                    ({Type, Q}) when Q > 0.0 ->
                        Type =:= ContentType orelse Type =:= SuperType;
                    (_) ->
                        false
                end,
                QList
            ) andalso
            (not lists:member({ContentType, 0.0}, QList)) andalso
            (not lists:member({SuperType, 0.0}, QList))
    end.

%% @spec accepted_content_types([string() | binary()]) -> [string()] | bad_accept_header
%%
%% @doc Filters which of the given media types this request accepts. This filtering
%%      is performed by analyzing the "Accept" header. The returned list is sorted
%%      according to the preferences specified in the "Accept" header (higher Q values
%%      first). If two or more types have the same preference (Q value), they're order
%%      in the returned list is the same as they're order in the input list.
%%
%%      Examples
%%
%%      1) For a missing "Accept" header:
%%         accepted_content_types(["text/html", "application/json"]) ->
%%             ["text/html", "application/json"]
%%
%%      2) For an "Accept" header with value "text/html, application/*":
%%         accepted_content_types(["application/json", "text/html"]) ->
%%             ["application/json", "text/html"]
%%
%%      3) For an "Accept" header with value "text/html, */*; q=0.0":
%%         accepted_content_types(["text/html", "application/json"]) ->
%%             ["text/html"]
%%
%%      4) For an "Accept" header with value "text/html; q=0.5, */*; q=0.1":
%%         accepts_content_types(["application/json", "text/html"]) ->
%%             ["text/html", "application/json"]
%%
accepted_content_types(Types1) ->
    Types = lists:map(
        fun(T) -> re:replace(T, "\\s", "", [global, {return, list}]) end,
        Types1),
    AcceptHeader = accept_header(),
    case mochiweb_util:parse_qvalues(AcceptHeader) of
        invalid_qvalue_string ->
            bad_accept_header;
        QList ->
            TypesQ = lists:foldr(
                fun(T, Acc) ->
                    case proplists:get_value(T, QList) of
                        undefined ->
                            [MainType, _SubType] = string:tokens(T, "/"),
                            case proplists:get_value(MainType ++ "/*", QList) of
                                undefined ->
                                    case proplists:get_value("*/*", QList) of
                                        Q when is_float(Q), Q > 0.0 ->
                                            [{Q, T} | Acc];
                                        _ ->
                                            Acc
                                    end;
                                Q when Q > 0.0 ->
                                    [{Q, T} | Acc];
                                _ ->
                                    Acc
                            end;
                        Q when Q > 0.0 ->
                            [{Q, T} | Acc];
                        _ ->
                            Acc
                    end
                end,
                [], Types),
            % Note: Stable sort. If 2 types have the same Q value we leave them in the
            % same order as in the input list.
            SortFun = fun({Q1, _}, {Q2, _}) -> Q1 >= Q2 end,
            [Type || {_Q, Type} <- lists:sort(SortFun, TypesQ)]
    end.

accept_header() ->
    case get_header_value("Accept") of
        undefined ->
            "*/*";
        Value ->
            Value
    end.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
-module(mochiweb_request_tests).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

accepts_content_type_test() ->
    Req1 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "multipart/related"}])),
    ?assertEqual(true, Req1:accepts_content_type("multipart/related")),
    ?assertEqual(true, Req1:accepts_content_type(<<"multipart/related">>)),

    Req2 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html"}])),
    ?assertEqual(false, Req2:accepts_content_type("multipart/related")),

    Req3 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html, multipart/*"}])),
    ?assertEqual(true, Req3:accepts_content_type("multipart/related")),

    Req4 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html, multipart/*; q=0.0"}])),
    ?assertEqual(false, Req4:accepts_content_type("multipart/related")),

    Req5 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html, multipart/*; q=0"}])),
    ?assertEqual(false, Req5:accepts_content_type("multipart/related")),

    Req6 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html, */*; q=0.0"}])),
    ?assertEqual(false, Req6:accepts_content_type("multipart/related")),

    Req7 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "multipart/*; q=0.0, */*"}])),
    ?assertEqual(false, Req7:accepts_content_type("multipart/related")),

    Req8 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "*/*; q=0.0, multipart/*"}])),
    ?assertEqual(true, Req8:accepts_content_type("multipart/related")),

    Req9 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "*/*; q=0.0, multipart/related"}])),
    ?assertEqual(true, Req9:accepts_content_type("multipart/related")),

    Req10 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html; level=1"}])),
    ?assertEqual(true, Req10:accepts_content_type("text/html;level=1")),

    Req11 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html; level=1, text/html"}])),
    ?assertEqual(true, Req11:accepts_content_type("text/html")),

    Req12 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html; level=1; q=0.0, text/html"}])),
    ?assertEqual(false, Req12:accepts_content_type("text/html;level=1")),

    Req13 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html; level=1; q=0.0, text/html"}])),
    ?assertEqual(false, Req13:accepts_content_type("text/html; level=1")),

    Req14 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html;level=1;q=0.1, text/html"}])),
    ?assertEqual(true, Req14:accepts_content_type("text/html; level=1")).

accepted_encodings_test() ->
    Req1 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
                                mochiweb_headers:make([])),
    ?assertEqual(["identity"],
                 Req1:accepted_encodings(["gzip", "identity"])),

    Req2 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept-Encoding", "gzip, deflate"}])),
    ?assertEqual(["gzip", "identity"],
                 Req2:accepted_encodings(["gzip", "identity"])),

    Req3 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept-Encoding", "gzip;q=0.5, deflate"}])),
    ?assertEqual(["deflate", "gzip", "identity"],
                 Req3:accepted_encodings(["gzip", "deflate", "identity"])),

    Req4 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept-Encoding", "identity, *;q=0"}])),
    ?assertEqual(["identity"],
                 Req4:accepted_encodings(["gzip", "deflate", "identity"])),

    Req5 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept-Encoding", "gzip; q=0.1, *;q=0"}])),
    ?assertEqual(["gzip"],
                 Req5:accepted_encodings(["gzip", "deflate", "identity"])),

    Req6 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept-Encoding", "gzip; q=, *;q=0"}])),
    ?assertEqual(bad_accept_encoding_value,
                 Req6:accepted_encodings(["gzip", "deflate", "identity"])),

    Req7 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept-Encoding", "gzip;q=2.0, *;q=0"}])),
    ?assertEqual(bad_accept_encoding_value,
                 Req7:accepted_encodings(["gzip", "identity"])),

    Req8 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept-Encoding", "deflate, *;q=0.0"}])),
    ?assertEqual([],
                 Req8:accepted_encodings(["gzip", "identity"])).

accepted_content_types_test() ->
    Req1 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html"}])),
    ?assertEqual(["text/html"],
        Req1:accepted_content_types(["text/html", "application/json"])),

    Req2 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html, */*;q=0"}])),
    ?assertEqual(["text/html"],
        Req2:accepted_content_types(["text/html", "application/json"])),

    Req3 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/*, */*;q=0"}])),
    ?assertEqual(["text/html"],
        Req3:accepted_content_types(["text/html", "application/json"])),

    Req4 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/*;q=0.8, */*;q=0.5"}])),
    ?assertEqual(["text/html", "application/json"],
        Req4:accepted_content_types(["application/json", "text/html"])),

    Req5 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/*;q=0.8, */*;q=0.5"}])),
    ?assertEqual(["text/html", "application/json"],
        Req5:accepted_content_types(["text/html", "application/json"])),

    Req6 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/*;q=0.5, */*;q=0.5"}])),
    ?assertEqual(["application/json", "text/html"],
        Req6:accepted_content_types(["application/json", "text/html"])),

    Req7 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make(
            [{"Accept", "text/html;q=0.5, application/json;q=0.5"}])),
    ?assertEqual(["application/json", "text/html"],
        Req7:accepted_content_types(["application/json", "text/html"])),

    Req8 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/html"}])),
    ?assertEqual([],
        Req8:accepted_content_types(["application/json"])),

    Req9 = mochiweb_request:new(nil, 'GET', "/foo", {1, 1},
        mochiweb_headers:make([{"Accept", "text/*;q=0.9, text/html;q=0.5, */*;q=0.7"}])),
    ?assertEqual(["application/json", "text/html"],
        Req9:accepted_content_types(["text/html", "application/json"])).

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Response abstraction.

-module(mochiweb_response, [Request, Code, Headers]).
-author('bob@mochimedia.com').

-define(QUIP, "Any of you quaids got a smint?").

-export([get_header_value/1, get/1, dump/0]).
-export([send/1, write_chunk/1]).

%% @spec get_header_value(string() | atom() | binary()) -> string() | undefined
%% @doc Get the value of the given response header.
get_header_value(K) ->
    mochiweb_headers:get_value(K, Headers).

%% @spec get(request | code | headers) -> term()
%% @doc Return the internal representation of the given field.
get(request) ->
    Request;
get(code) ->
    Code;
get(headers) ->
    Headers.

%% @spec dump() -> {mochiweb_request, [{atom(), term()}]}
%% @doc Dump the internal representation to a "human readable" set of terms
%%      for debugging/inspection purposes.
dump() ->
    [{request, Request:dump()},
     {code, Code},
     {headers, mochiweb_headers:to_list(Headers)}].

%% @spec send(iodata()) -> ok
%% @doc Send data over the socket if the method is not HEAD.
send(Data) ->
    case Request:get(method) of
        'HEAD' ->
            ok;
        _ ->
            Request:send(Data)
    end.

%% @spec write_chunk(iodata()) -> ok
%% @doc Write a chunk of a HTTP chunked response. If Data is zero length,
%%      then the chunked response will be finished.
write_chunk(Data) ->
    case Request:get(version) of
        Version when Version >= {1, 1} ->
            Length = iolist_size(Data),
            send([io_lib:format("~.16b\r\n", [Length]), Data, <<"\r\n">>]);
        _ ->
            send(Data)
    end.


%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
%% @copyright 2010 Mochi Media, Inc.

%% @doc MochiWeb socket - wrapper for plain and ssl sockets.

-module(mochiweb_socket).

-export([listen/4, accept/1, recv/3, send/2, close/1, port/1, peername/1,
         setopts/2, type/1]).

-define(ACCEPT_TIMEOUT, 2000).

listen(Ssl, Port, Opts, SslOpts) ->
    case Ssl of
        true ->
            case ssl:listen(Port, Opts ++ SslOpts) of
                {ok, ListenSocket} ->
                    {ok, {ssl, ListenSocket}};
                {error, _} = Err ->
                    Err
            end;
        false ->
            gen_tcp:listen(Port, Opts)
    end.

accept({ssl, ListenSocket}) ->
    % There's a bug in ssl:transport_accept/2 at the moment, which is the
    % reason for the try...catch block. Should be fixed in OTP R14.
    try ssl:transport_accept(ListenSocket) of
        {ok, Socket} ->
            case ssl:ssl_accept(Socket) of
                ok ->
                    {ok, {ssl, Socket}};
                {error, _} = Err ->
                    Err
            end;
        {error, _} = Err ->
            Err
    catch
        error:{badmatch, {error, Reason}} ->
            {error, Reason}
    end;
accept(ListenSocket) ->
    gen_tcp:accept(ListenSocket, ?ACCEPT_TIMEOUT).

recv({ssl, Socket}, Length, Timeout) ->
    ssl:recv(Socket, Length, Timeout);
recv(Socket, Length, Timeout) ->
    gen_tcp:recv(Socket, Length, Timeout).

send({ssl, Socket}, Data) ->
    ssl:send(Socket, Data);
send(Socket, Data) ->
    gen_tcp:send(Socket, Data).

close({ssl, Socket}) ->
    ssl:close(Socket);
close(Socket) ->
    gen_tcp:close(Socket).

port({ssl, Socket}) ->
    case ssl:sockname(Socket) of
        {ok, {_, Port}} ->
            {ok, Port};
        {error, _} = Err ->
            Err
    end;
port(Socket) ->
    inet:port(Socket).

peername({ssl, Socket}) ->
    ssl:peername(Socket);
peername(Socket) ->
    inet:peername(Socket).

setopts({ssl, Socket}, Opts) ->
    ssl:setopts(Socket, Opts);
setopts(Socket, Opts) ->
    inet:setopts(Socket, Opts).

type({ssl, _}) ->
    ssl;
type(_) ->
    plain.

%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc MochiWeb socket server.

-module(mochiweb_socket_server).
-author('bob@mochimedia.com').
-behaviour(gen_server).

-include("internal.hrl").

-export([start/1, start_link/1, stop/1]).
-export([init/1, handle_call/3, handle_cast/2, terminate/2, code_change/3,
         handle_info/2]).
-export([get/2, set/3]).

-record(mochiweb_socket_server,
        {port,
         loop,
         name=undefined,
         %% NOTE: This is currently ignored.
         max=2048,
         ip=any,
         listen=null,
         nodelay=false,
         backlog=128,
         active_sockets=0,
         acceptor_pool_size=16,
         ssl=false,
         ssl_opts=[{ssl_imp, new}],
         acceptor_pool=sets:new(),
         profile_fun=undefined}).

-define(is_old_state(State), not is_record(State, mochiweb_socket_server)).

start_link(Options) ->
    start_server(start_link, parse_options(Options)).

start(Options) ->
    case lists:keytake(link, 1, Options) of
        {value, {_Key, false}, Options1} ->
            start_server(start, parse_options(Options1));
        _ ->
            %% TODO: https://github.com/mochi/mochiweb/issues/58
            %%   [X] Phase 1: Add new APIs (Sep 2011)
            %%   [_] Phase 2: Add deprecation warning
            %%   [_] Phase 3: Change default to {link, false} and ignore link
            %%   [_] Phase 4: Add deprecation warning for {link, _} option
            %%   [_] Phase 5: Remove support for {link, _} option
            start_link(Options)
    end.

get(Name, Property) ->
    gen_server:call(Name, {get, Property}).

set(Name, profile_fun, Fun) ->
    gen_server:cast(Name, {set, profile_fun, Fun});
set(Name, Property, _Value) ->
    error_logger:info_msg("?MODULE:set for ~p with ~p not implemented~n",
                          [Name, Property]).

stop(Name) when is_atom(Name) ->
    gen_server:cast(Name, stop);
stop(Pid) when is_pid(Pid) ->
    gen_server:cast(Pid, stop);
stop({local, Name}) ->
    stop(Name);
stop({global, Name}) ->
    stop(Name);
stop(Options) ->
    State = parse_options(Options),
    stop(State#mochiweb_socket_server.name).

%% Internal API

parse_options(State=#mochiweb_socket_server{}) ->
    State;
parse_options(Options) ->
    parse_options(Options, #mochiweb_socket_server{}).

parse_options([], State) ->
    State;
parse_options([{name, L} | Rest], State) when is_list(L) ->
    Name = {local, list_to_atom(L)},
    parse_options(Rest, State#mochiweb_socket_server{name=Name});
parse_options([{name, A} | Rest], State) when A =:= undefined ->
    parse_options(Rest, State#mochiweb_socket_server{name=A});
parse_options([{name, A} | Rest], State) when is_atom(A) ->
    Name = {local, A},
    parse_options(Rest, State#mochiweb_socket_server{name=Name});
parse_options([{name, Name} | Rest], State) ->
    parse_options(Rest, State#mochiweb_socket_server{name=Name});
parse_options([{port, L} | Rest], State) when is_list(L) ->
    Port = list_to_integer(L),
    parse_options(Rest, State#mochiweb_socket_server{port=Port});
parse_options([{port, Port} | Rest], State) ->
    parse_options(Rest, State#mochiweb_socket_server{port=Port});
parse_options([{ip, Ip} | Rest], State) ->
    ParsedIp = case Ip of
                   any ->
                       any;
                   Ip when is_tuple(Ip) ->
                       Ip;
                   Ip when is_list(Ip) ->
                       {ok, IpTuple} = inet_parse:address(Ip),
                       IpTuple
               end,
    parse_options(Rest, State#mochiweb_socket_server{ip=ParsedIp});
parse_options([{loop, Loop} | Rest], State) ->
    parse_options(Rest, State#mochiweb_socket_server{loop=Loop});
parse_options([{backlog, Backlog} | Rest], State) ->
    parse_options(Rest, State#mochiweb_socket_server{backlog=Backlog});
parse_options([{nodelay, NoDelay} | Rest], State) ->
    parse_options(Rest, State#mochiweb_socket_server{nodelay=NoDelay});
parse_options([{acceptor_pool_size, Max} | Rest], State) ->
    MaxInt = ensure_int(Max),
    parse_options(Rest,
                  State#mochiweb_socket_server{acceptor_pool_size=MaxInt});
parse_options([{max, Max} | Rest], State) ->
    error_logger:info_report([{warning, "TODO: max is currently unsupported"},
                              {max, Max}]),
    MaxInt = ensure_int(Max),
    parse_options(Rest, State#mochiweb_socket_server{max=MaxInt});
parse_options([{ssl, Ssl} | Rest], State) when is_boolean(Ssl) ->
    parse_options(Rest, State#mochiweb_socket_server{ssl=Ssl});
parse_options([{ssl_opts, SslOpts} | Rest], State) when is_list(SslOpts) ->
    SslOpts1 = [{ssl_imp, new} | proplists:delete(ssl_imp, SslOpts)],
    parse_options(Rest, State#mochiweb_socket_server{ssl_opts=SslOpts1});
parse_options([{profile_fun, ProfileFun} | Rest], State) when is_function(ProfileFun) ->
    parse_options(Rest, State#mochiweb_socket_server{profile_fun=ProfileFun}).


start_server(F, State=#mochiweb_socket_server{ssl=Ssl, name=Name}) ->
    ok = prep_ssl(Ssl),
    case Name of
        undefined ->
            gen_server:F(?MODULE, State, []);
        _ ->
            gen_server:F(Name, ?MODULE, State, [])
    end.

prep_ssl(true) ->
    ok = mochiweb:ensure_started(crypto),
    ok = mochiweb:ensure_started(public_key),
    ok = mochiweb:ensure_started(ssl);
prep_ssl(false) ->
    ok.

ensure_int(N) when is_integer(N) ->
    N;
ensure_int(S) when is_list(S) ->
    list_to_integer(S).

ipv6_supported() ->
    case (catch inet:getaddr("localhost", inet6)) of
        {ok, _Addr} ->
            true;
        {error, _} ->
            false
    end.

init(State=#mochiweb_socket_server{ip=Ip, port=Port, backlog=Backlog, nodelay=NoDelay}) ->
    process_flag(trap_exit, true),
    BaseOpts = [binary,
                {reuseaddr, true},
                {packet, 0},
                {backlog, Backlog},
                {recbuf, ?RECBUF_SIZE},
                {active, false},
                {nodelay, NoDelay}],
    Opts = case Ip of
        any ->
            case ipv6_supported() of % IPv4, and IPv6 if supported
                true -> [inet, inet6 | BaseOpts];
                _ -> BaseOpts
            end;
        {_, _, _, _} -> % IPv4
            [inet, {ip, Ip} | BaseOpts];
        {_, _, _, _, _, _, _, _} -> % IPv6
            [inet6, {ip, Ip} | BaseOpts]
    end,
    listen(Port, Opts, State).

new_acceptor_pool(Listen,
                  State=#mochiweb_socket_server{acceptor_pool=Pool,
                                                acceptor_pool_size=Size,
                                                loop=Loop}) ->
    F = fun (_, S) ->
                Pid = mochiweb_acceptor:start_link(self(), Listen, Loop),
                sets:add_element(Pid, S)
        end,
    Pool1 = lists:foldl(F, Pool, lists:seq(1, Size)),
    State#mochiweb_socket_server{acceptor_pool=Pool1}.

listen(Port, Opts, State=#mochiweb_socket_server{ssl=Ssl, ssl_opts=SslOpts}) ->
    case mochiweb_socket:listen(Ssl, Port, Opts, SslOpts) of
        {ok, Listen} ->
            {ok, ListenPort} = mochiweb_socket:port(Listen),
            {ok, new_acceptor_pool(
                   Listen,
                   State#mochiweb_socket_server{listen=Listen,
                                                port=ListenPort})};
        {error, Reason} ->
            {stop, Reason}
    end.

do_get(port, #mochiweb_socket_server{port=Port}) ->
    Port;
do_get(active_sockets, #mochiweb_socket_server{active_sockets=ActiveSockets}) ->
    ActiveSockets.


state_to_proplist(#mochiweb_socket_server{name=Name,
                                          port=Port,
                                          active_sockets=ActiveSockets}) ->
    [{name, Name}, {port, Port}, {active_sockets, ActiveSockets}].

upgrade_state(State = #mochiweb_socket_server{}) ->
    State;
upgrade_state({mochiweb_socket_server, Port, Loop, Name,
             Max, IP, Listen, NoDelay, Backlog, ActiveSockets,
             AcceptorPoolSize, SSL, SSL_opts,
             AcceptorPool}) ->
    #mochiweb_socket_server{port=Port, loop=Loop, name=Name, max=Max, ip=IP,
                            listen=Listen, nodelay=NoDelay, backlog=Backlog,
                            active_sockets=ActiveSockets,
                            acceptor_pool_size=AcceptorPoolSize,
                            ssl=SSL,
                            ssl_opts=SSL_opts,
                            acceptor_pool=AcceptorPool}.

handle_call(Req, From, State) when ?is_old_state(State) ->
    handle_call(Req, From, upgrade_state(State));
handle_call({get, Property}, _From, State) ->
    Res = do_get(Property, State),
    {reply, Res, State};
handle_call(_Message, _From, State) ->
    Res = error,
    {reply, Res, State}.


handle_cast(Req, State) when ?is_old_state(State) ->
    handle_cast(Req, upgrade_state(State));
handle_cast({accepted, Pid, Timing},
            State=#mochiweb_socket_server{active_sockets=ActiveSockets}) ->
    State1 = State#mochiweb_socket_server{active_sockets=1 + ActiveSockets},
    case State#mochiweb_socket_server.profile_fun of
        undefined ->
            undefined;
        F when is_function(F) ->
            catch F([{timing, Timing} | state_to_proplist(State1)])
    end,
    {noreply, recycle_acceptor(Pid, State1)};
handle_cast({set, profile_fun, ProfileFun}, State) ->
    State1 = case ProfileFun of
                 ProfileFun when is_function(ProfileFun); ProfileFun =:= undefined ->
                     State#mochiweb_socket_server{profile_fun=ProfileFun};
                 _ ->
                     State
             end,
    {noreply, State1};
handle_cast(stop, State) ->
    {stop, normal, State}.


terminate(Reason, State) when ?is_old_state(State) ->
    terminate(Reason, upgrade_state(State));
terminate(_Reason, #mochiweb_socket_server{listen=Listen}) ->
    mochiweb_socket:close(Listen).

code_change(_OldVsn, State, _Extra) ->
    State.

recycle_acceptor(Pid, State=#mochiweb_socket_server{
                        acceptor_pool=Pool,
                        listen=Listen,
                        loop=Loop,
                        active_sockets=ActiveSockets}) ->
    case sets:is_element(Pid, Pool) of
        true ->
            Acceptor = mochiweb_acceptor:start_link(self(), Listen, Loop),
            Pool1 = sets:add_element(Acceptor, sets:del_element(Pid, Pool)),
            State#mochiweb_socket_server{acceptor_pool=Pool1};
        false ->
            State#mochiweb_socket_server{active_sockets=ActiveSockets - 1}
    end.

handle_info(Msg, State) when ?is_old_state(State) ->
    handle_info(Msg, upgrade_state(State));
handle_info({'EXIT', Pid, normal}, State) ->
    {noreply, recycle_acceptor(Pid, State)};
handle_info({'EXIT', Pid, Reason},
            State=#mochiweb_socket_server{acceptor_pool=Pool}) ->
    case sets:is_element(Pid, Pool) of
        true ->
            %% If there was an unexpected error accepting, log and sleep.
            error_logger:error_report({?MODULE, ?LINE,
                                       {acceptor_error, Reason}}),
            timer:sleep(100);
        false ->
            ok
    end,
    {noreply, recycle_acceptor(Pid, State)};

% this is what release_handler needs to get a list of modules,
% since our supervisor modules list is set to 'dynamic'
% see sasl-2.1.9.2/src/release_handler_1.erl get_dynamic_mods
handle_info({From, Tag, get_modules}, State = #mochiweb_socket_server{name={local,Mod}}) ->
    From ! {element(2,Tag), [Mod]},
    {noreply, State};

% If for some reason we can't get the module name, send empty list to avoid release_handler timeout:
handle_info({From, Tag, get_modules}, State) ->
    error_logger:info_msg("mochiweb_socket_server replying to dynamic modules request as '[]'~n",[]),
    From ! {element(2,Tag), []},
    {noreply, State};

handle_info(Info, State) ->
    error_logger:info_report([{'INFO', Info}, {'State', State}]),
    {noreply, State}.



%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

upgrade_state_test() ->
    OldState = {mochiweb_socket_server,
                port, loop, name,
                max, ip, listen,
                nodelay, backlog,
                active_sockets,
                acceptor_pool_size,
                ssl, ssl_opts, acceptor_pool},
    State = upgrade_state(OldState),
    CmpState = #mochiweb_socket_server{port=port, loop=loop,
                                       name=name, max=max, ip=ip,
                                       listen=listen, nodelay=nodelay,
                                       backlog=backlog,
                                       active_sockets=active_sockets,
                                       acceptor_pool_size=acceptor_pool_size,
                                       ssl=ssl, ssl_opts=ssl_opts,
                                       acceptor_pool=acceptor_pool,
                                       profile_fun=undefined},
    ?assertEqual(CmpState, State).

-endif.
%% @author Bob Ippolito <bob@mochimedia.com>
%% @copyright 2007 Mochi Media, Inc.

%% @doc Utilities for parsing and quoting.

-module(mochiweb_util).
-author('bob@mochimedia.com').
-export([join/2, quote_plus/1, urlencode/1, parse_qs/1, unquote/1]).
-export([path_split/1]).
-export([urlsplit/1, urlsplit_path/1, urlunsplit/1, urlunsplit_path/1]).
-export([guess_mime/1, parse_header/1]).
-export([shell_quote/1, cmd/1, cmd_string/1, cmd_port/2, cmd_status/1, cmd_status/2]).
-export([record_to_proplist/2, record_to_proplist/3]).
-export([safe_relative_path/1, partition/2]).
-export([parse_qvalues/1, pick_accepted_encodings/3]).
-export([make_io/1]).

-define(PERCENT, 37).  % $\%
-define(FULLSTOP, 46). % $\.
-define(IS_HEX(C), ((C >= $0 andalso C =< $9) orelse
                    (C >= $a andalso C =< $f) orelse
                    (C >= $A andalso C =< $F))).
-define(QS_SAFE(C), ((C >= $a andalso C =< $z) orelse
                     (C >= $A andalso C =< $Z) orelse
                     (C >= $0 andalso C =< $9) orelse
                     (C =:= ?FULLSTOP orelse C =:= $- orelse C =:= $~ orelse
                      C =:= $_))).

hexdigit(C) when C < 10 -> $0 + C;
hexdigit(C) when C < 16 -> $A + (C - 10).

unhexdigit(C) when C >= $0, C =< $9 -> C - $0;
unhexdigit(C) when C >= $a, C =< $f -> C - $a + 10;
unhexdigit(C) when C >= $A, C =< $F -> C - $A + 10.

%% @spec partition(String, Sep) -> {String, [], []} | {Prefix, Sep, Postfix}
%% @doc Inspired by Python 2.5's str.partition:
%%      partition("foo/bar", "/") = {"foo", "/", "bar"},
%%      partition("foo", "/") = {"foo", "", ""}.
partition(String, Sep) ->
    case partition(String, Sep, []) of
        undefined ->
            {String, "", ""};
        Result ->
            Result
    end.

partition("", _Sep, _Acc) ->
    undefined;
partition(S, Sep, Acc) ->
    case partition2(S, Sep) of
        undefined ->
            [C | Rest] = S,
            partition(Rest, Sep, [C | Acc]);
        Rest ->
            {lists:reverse(Acc), Sep, Rest}
    end.

partition2(Rest, "") ->
    Rest;
partition2([C | R1], [C | R2]) ->
    partition2(R1, R2);
partition2(_S, _Sep) ->
    undefined.



%% @spec safe_relative_path(string()) -> string() | undefined
%% @doc Return the reduced version of a relative path or undefined if it
%%      is not safe. safe relative paths can be joined with an absolute path
%%      and will result in a subdirectory of the absolute path.
safe_relative_path("/" ++ _) ->
    undefined;
safe_relative_path(P) ->
    safe_relative_path(P, []).

safe_relative_path("", Acc) ->
    case Acc of
        [] ->
            "";
        _ ->
            string:join(lists:reverse(Acc), "/")
    end;
safe_relative_path(P, Acc) ->
    case partition(P, "/") of
        {"", "/", _} ->
            %% /foo or foo//bar
            undefined;
        {"..", _, _} when Acc =:= [] ->
            undefined;
        {"..", _, Rest} ->
            safe_relative_path(Rest, tl(Acc));
        {Part, "/", ""} ->
            safe_relative_path("", ["", Part | Acc]);
        {Part, _, Rest} ->
            safe_relative_path(Rest, [Part | Acc])
    end.

%% @spec shell_quote(string()) -> string()
%% @doc Quote a string according to UNIX shell quoting rules, returns a string
%%      surrounded by double quotes.
shell_quote(L) ->
    shell_quote(L, [$\"]).

%% @spec cmd_port([string()], Options) -> port()
%% @doc open_port({spawn, mochiweb_util:cmd_string(Argv)}, Options).
cmd_port(Argv, Options) ->
    open_port({spawn, cmd_string(Argv)}, Options).

%% @spec cmd([string()]) -> string()
%% @doc os:cmd(cmd_string(Argv)).
cmd(Argv) ->
    os:cmd(cmd_string(Argv)).

%% @spec cmd_string([string()]) -> string()
%% @doc Create a shell quoted command string from a list of arguments.
cmd_string(Argv) ->
    string:join([shell_quote(X) || X <- Argv], " ").

%% @spec cmd_status([string()]) -> {ExitStatus::integer(), Stdout::binary()}
%% @doc Accumulate the output and exit status from the given application,
%%      will be spawned with cmd_port/2.
cmd_status(Argv) ->
    cmd_status(Argv, []).

%% @spec cmd_status([string()], [atom()]) -> {ExitStatus::integer(), Stdout::binary()}
%% @doc Accumulate the output and exit status from the given application,
%%      will be spawned with cmd_port/2.
cmd_status(Argv, Options) ->
    Port = cmd_port(Argv, [exit_status, stderr_to_stdout,
                           use_stdio, binary | Options]),
    try cmd_loop(Port, [])
    after catch port_close(Port)
    end.

%% @spec cmd_loop(port(), list()) -> {ExitStatus::integer(), Stdout::binary()}
%% @doc Accumulate the output and exit status from a port.
cmd_loop(Port, Acc) ->
    receive
        {Port, {exit_status, Status}} ->
            {Status, iolist_to_binary(lists:reverse(Acc))};
        {Port, {data, Data}} ->
            cmd_loop(Port, [Data | Acc])
    end.

%% @spec join([iolist()], iolist()) -> iolist()
%% @doc Join a list of strings or binaries together with the given separator
%%      string or char or binary. The output is flattened, but may be an
%%      iolist() instead of a string() if any of the inputs are binary().
join([], _Separator) ->
    [];
join([S], _Separator) ->
    lists:flatten(S);
join(Strings, Separator) ->
    lists:flatten(revjoin(lists:reverse(Strings), Separator, [])).

revjoin([], _Separator, Acc) ->
    Acc;
revjoin([S | Rest], Separator, []) ->
    revjoin(Rest, Separator, [S]);
revjoin([S | Rest], Separator, Acc) ->
    revjoin(Rest, Separator, [S, Separator | Acc]).

%% @spec quote_plus(atom() | integer() | float() | string() | binary()) -> string()
%% @doc URL safe encoding of the given term.
quote_plus(Atom) when is_atom(Atom) ->
    quote_plus(atom_to_list(Atom));
quote_plus(Int) when is_integer(Int) ->
    quote_plus(integer_to_list(Int));
quote_plus(Binary) when is_binary(Binary) ->
    quote_plus(binary_to_list(Binary));
quote_plus(Float) when is_float(Float) ->
    quote_plus(mochinum:digits(Float));
quote_plus(String) ->
    quote_plus(String, []).

quote_plus([], Acc) ->
    lists:reverse(Acc);
quote_plus([C | Rest], Acc) when ?QS_SAFE(C) ->
    quote_plus(Rest, [C | Acc]);
quote_plus([$\s | Rest], Acc) ->
    quote_plus(Rest, [$+ | Acc]);
quote_plus([C | Rest], Acc) ->
    <<Hi:4, Lo:4>> = <<C>>,
    quote_plus(Rest, [hexdigit(Lo), hexdigit(Hi), ?PERCENT | Acc]).

%% @spec urlencode([{Key, Value}]) -> string()
%% @doc URL encode the property list.
urlencode(Props) ->
    Pairs = lists:foldr(
              fun ({K, V}, Acc) ->
                      [quote_plus(K) ++ "=" ++ quote_plus(V) | Acc]
              end, [], Props),
    string:join(Pairs, "&").

%% @spec parse_qs(string() | binary()) -> [{Key, Value}]
%% @doc Parse a query string or application/x-www-form-urlencoded.
parse_qs(Binary) when is_binary(Binary) ->
    parse_qs(binary_to_list(Binary));
parse_qs(String) ->
    parse_qs(String, []).

parse_qs([], Acc) ->
    lists:reverse(Acc);
parse_qs(String, Acc) ->
    {Key, Rest} = parse_qs_key(String),
    {Value, Rest1} = parse_qs_value(Rest),
    parse_qs(Rest1, [{Key, Value} | Acc]).

parse_qs_key(String) ->
    parse_qs_key(String, []).

parse_qs_key([], Acc) ->
    {qs_revdecode(Acc), ""};
parse_qs_key([$= | Rest], Acc) ->
    {qs_revdecode(Acc), Rest};
parse_qs_key(Rest=[$; | _], Acc) ->
    {qs_revdecode(Acc), Rest};
parse_qs_key(Rest=[$& | _], Acc) ->
    {qs_revdecode(Acc), Rest};
parse_qs_key([C | Rest], Acc) ->
    parse_qs_key(Rest, [C | Acc]).

parse_qs_value(String) ->
    parse_qs_value(String, []).

parse_qs_value([], Acc) ->
    {qs_revdecode(Acc), ""};
parse_qs_value([$; | Rest], Acc) ->
    {qs_revdecode(Acc), Rest};
parse_qs_value([$& | Rest], Acc) ->
    {qs_revdecode(Acc), Rest};
parse_qs_value([C | Rest], Acc) ->
    parse_qs_value(Rest, [C | Acc]).

%% @spec unquote(string() | binary()) -> string()
%% @doc Unquote a URL encoded string.
unquote(Binary) when is_binary(Binary) ->
    unquote(binary_to_list(Binary));
unquote(String) ->
    qs_revdecode(lists:reverse(String)).

qs_revdecode(S) ->
    qs_revdecode(S, []).

qs_revdecode([], Acc) ->
    Acc;
qs_revdecode([$+ | Rest], Acc) ->
    qs_revdecode(Rest, [$\s | Acc]);
qs_revdecode([Lo, Hi, ?PERCENT | Rest], Acc) when ?IS_HEX(Lo), ?IS_HEX(Hi) ->
    qs_revdecode(Rest, [(unhexdigit(Lo) bor (unhexdigit(Hi) bsl 4)) | Acc]);
qs_revdecode([C | Rest], Acc) ->
    qs_revdecode(Rest, [C | Acc]).

%% @spec urlsplit(Url) -> {Scheme, Netloc, Path, Query, Fragment}
%% @doc Return a 5-tuple, does not expand % escapes. Only supports HTTP style
%%      URLs.
urlsplit(Url) ->
    {Scheme, Url1} = urlsplit_scheme(Url),
    {Netloc, Url2} = urlsplit_netloc(Url1),
    {Path, Query, Fragment} = urlsplit_path(Url2),
    {Scheme, Netloc, Path, Query, Fragment}.

urlsplit_scheme(Url) ->
    case urlsplit_scheme(Url, []) of
        no_scheme ->
            {"", Url};
        Res ->
            Res
    end.

urlsplit_scheme([C | Rest], Acc) when ((C >= $a andalso C =< $z) orelse
                                       (C >= $A andalso C =< $Z) orelse
                                       (C >= $0 andalso C =< $9) orelse
                                       C =:= $+ orelse C =:= $- orelse
                                       C =:= $.) ->
    urlsplit_scheme(Rest, [C | Acc]);
urlsplit_scheme([$: | Rest], Acc=[_ | _]) ->
    {string:to_lower(lists:reverse(Acc)), Rest};
urlsplit_scheme(_Rest, _Acc) ->
    no_scheme.

urlsplit_netloc("//" ++ Rest) ->
    urlsplit_netloc(Rest, []);
urlsplit_netloc(Path) ->
    {"", Path}.

urlsplit_netloc("", Acc) ->
    {lists:reverse(Acc), ""};
urlsplit_netloc(Rest=[C | _], Acc) when C =:= $/; C =:= $?; C =:= $# ->
    {lists:reverse(Acc), Rest};
urlsplit_netloc([C | Rest], Acc) ->
    urlsplit_netloc(Rest, [C | Acc]).


%% @spec path_split(string()) -> {Part, Rest}
%% @doc Split a path starting from the left, as in URL traversal.
%%      path_split("foo/bar") = {"foo", "bar"},
%%      path_split("/foo/bar") = {"", "foo/bar"}.
path_split(S) ->
    path_split(S, []).

path_split("", Acc) ->
    {lists:reverse(Acc), ""};
path_split("/" ++ Rest, Acc) ->
    {lists:reverse(Acc), Rest};
path_split([C | Rest], Acc) ->
    path_split(Rest, [C | Acc]).


%% @spec urlunsplit({Scheme, Netloc, Path, Query, Fragment}) -> string()
%% @doc Assemble a URL from the 5-tuple. Path must be absolute.
urlunsplit({Scheme, Netloc, Path, Query, Fragment}) ->
    lists:flatten([case Scheme of "" -> "";  _ -> [Scheme, "://"] end,
                   Netloc,
                   urlunsplit_path({Path, Query, Fragment})]).

%% @spec urlunsplit_path({Path, Query, Fragment}) -> string()
%% @doc Assemble a URL path from the 3-tuple.
urlunsplit_path({Path, Query, Fragment}) ->
    lists:flatten([Path,
                   case Query of "" -> ""; _ -> [$? | Query] end,
                   case Fragment of "" -> ""; _ -> [$# | Fragment] end]).

%% @spec urlsplit_path(Url) -> {Path, Query, Fragment}
%% @doc Return a 3-tuple, does not expand % escapes. Only supports HTTP style
%%      paths.
urlsplit_path(Path) ->
    urlsplit_path(Path, []).

urlsplit_path("", Acc) ->
    {lists:reverse(Acc), "", ""};
urlsplit_path("?" ++ Rest, Acc) ->
    {Query, Fragment} = urlsplit_query(Rest),
    {lists:reverse(Acc), Query, Fragment};
urlsplit_path("#" ++ Rest, Acc) ->
    {lists:reverse(Acc), "", Rest};
urlsplit_path([C | Rest], Acc) ->
    urlsplit_path(Rest, [C | Acc]).

urlsplit_query(Query) ->
    urlsplit_query(Query, []).

urlsplit_query("", Acc) ->
    {lists:reverse(Acc), ""};
urlsplit_query("#" ++ Rest, Acc) ->
    {lists:reverse(Acc), Rest};
urlsplit_query([C | Rest], Acc) ->
    urlsplit_query(Rest, [C | Acc]).

%% @spec guess_mime(string()) -> string()
%% @doc  Guess the mime type of a file by the extension of its filename.
guess_mime(File) ->
    case mochiweb_mime:from_extension(filename:extension(File)) of
        undefined ->
            "text/plain";
        Mime ->
            Mime
    end.

%% @spec parse_header(string()) -> {Type, [{K, V}]}
%% @doc  Parse a Content-Type like header, return the main Content-Type
%%       and a property list of options.
parse_header(String) ->
    %% TODO: This is exactly as broken as Python's cgi module.
    %%       Should parse properly like mochiweb_cookies.
    [Type | Parts] = [string:strip(S) || S <- string:tokens(String, ";")],
    F = fun (S, Acc) ->
                case lists:splitwith(fun (C) -> C =/= $= end, S) of
                    {"", _} ->
                        %% Skip anything with no name
                        Acc;
                    {_, ""} ->
                        %% Skip anything with no value
                        Acc;
                    {Name, [$\= | Value]} ->
                        [{string:to_lower(string:strip(Name)),
                          unquote_header(string:strip(Value))} | Acc]
                end
        end,
    {string:to_lower(Type),
     lists:foldr(F, [], Parts)}.

unquote_header("\"" ++ Rest) ->
    unquote_header(Rest, []);
unquote_header(S) ->
    S.

unquote_header("", Acc) ->
    lists:reverse(Acc);
unquote_header("\"", Acc) ->
    lists:reverse(Acc);
unquote_header([$\\, C | Rest], Acc) ->
    unquote_header(Rest, [C | Acc]);
unquote_header([C | Rest], Acc) ->
    unquote_header(Rest, [C | Acc]).

%% @spec record_to_proplist(Record, Fields) -> proplist()
%% @doc calls record_to_proplist/3 with a default TypeKey of '__record'
record_to_proplist(Record, Fields) ->
    record_to_proplist(Record, Fields, '__record').

%% @spec record_to_proplist(Record, Fields, TypeKey) -> proplist()
%% @doc Return a proplist of the given Record with each field in the
%%      Fields list set as a key with the corresponding value in the Record.
%%      TypeKey is the key that is used to store the record type
%%      Fields should be obtained by calling record_info(fields, record_type)
%%      where record_type is the record type of Record
record_to_proplist(Record, Fields, TypeKey)
  when tuple_size(Record) - 1 =:= length(Fields) ->
    lists:zip([TypeKey | Fields], tuple_to_list(Record)).


shell_quote([], Acc) ->
    lists:reverse([$\" | Acc]);
shell_quote([C | Rest], Acc) when C =:= $\" orelse C =:= $\` orelse
                                  C =:= $\\ orelse C =:= $\$ ->
    shell_quote(Rest, [C, $\\ | Acc]);
shell_quote([C | Rest], Acc) ->
    shell_quote(Rest, [C | Acc]).

%% @spec parse_qvalues(string()) -> [qvalue()] | invalid_qvalue_string
%% @type qvalue() = {media_type() | encoding() , float()}.
%% @type media_type() = string().
%% @type encoding() = string().
%%
%% @doc Parses a list (given as a string) of elements with Q values associated
%%      to them. Elements are separated by commas and each element is separated
%%      from its Q value by a semicolon. Q values are optional but when missing
%%      the value of an element is considered as 1.0. A Q value is always in the
%%      range [0.0, 1.0]. A Q value list is used for example as the value of the
%%      HTTP "Accept" and "Accept-Encoding" headers.
%%
%%      Q values are described in section 2.9 of the RFC 2616 (HTTP 1.1).
%%
%%      Example:
%%
%%      parse_qvalues("gzip; q=0.5, deflate, identity;q=0.0") ->
%%          [{"gzip", 0.5}, {"deflate", 1.0}, {"identity", 0.0}]
%%
parse_qvalues(QValuesStr) ->
    try
        lists:map(
            fun(Pair) ->
                [Type | Params] = string:tokens(Pair, ";"),
                NormParams = normalize_media_params(Params),
                {Q, NonQParams} = extract_q(NormParams),
                {string:join([string:strip(Type) | NonQParams], ";"), Q}
            end,
            string:tokens(string:to_lower(QValuesStr), ",")
        )
    catch
        _Type:_Error ->
            invalid_qvalue_string
    end.

normalize_media_params(Params) ->
    {ok, Re} = re:compile("\\s"),
    normalize_media_params(Re, Params, []).

normalize_media_params(_Re, [], Acc) ->
    lists:reverse(Acc);
normalize_media_params(Re, [Param | Rest], Acc) ->
    NormParam = re:replace(Param, Re, "", [global, {return, list}]),
    normalize_media_params(Re, Rest, [NormParam | Acc]).

extract_q(NormParams) ->
    {ok, KVRe} = re:compile("^([^=]+)=([^=]+)$"),
    {ok, QRe} = re:compile("^((?:0|1)(?:\\.\\d{1,3})?)$"),
    extract_q(KVRe, QRe, NormParams, []).

extract_q(_KVRe, _QRe, [], Acc) ->
    {1.0, lists:reverse(Acc)};
extract_q(KVRe, QRe, [Param | Rest], Acc) ->
    case re:run(Param, KVRe, [{capture, [1, 2], list}]) of
        {match, [Name, Value]} ->
            case Name of
            "q" ->
                {match, [Q]} = re:run(Value, QRe, [{capture, [1], list}]),
                QVal = case Q of
                    "0" ->
                        0.0;
                    "1" ->
                        1.0;
                    Else ->
                        list_to_float(Else)
                end,
                case QVal < 0.0 orelse QVal > 1.0 of
                false ->
                    {QVal, lists:reverse(Acc) ++ Rest}
                end;
            _ ->
                extract_q(KVRe, QRe, Rest, [Param | Acc])
            end
    end.

%% @spec pick_accepted_encodings([qvalue()], [encoding()], encoding()) ->
%%    [encoding()]
%%
%% @doc Determines which encodings specified in the given Q values list are
%%      valid according to a list of supported encodings and a default encoding.
%%
%%      The returned list of encodings is sorted, descendingly, according to the
%%      Q values of the given list. The last element of this list is the given
%%      default encoding unless this encoding is explicitily or implicitily
%%      marked with a Q value of 0.0 in the given Q values list.
%%      Note: encodings with the same Q value are kept in the same order as
%%            found in the input Q values list.
%%
%%      This encoding picking process is described in section 14.3 of the
%%      RFC 2616 (HTTP 1.1).
%%
%%      Example:
%%
%%      pick_accepted_encodings(
%%          [{"gzip", 0.5}, {"deflate", 1.0}],
%%          ["gzip", "identity"],
%%          "identity"
%%      ) ->
%%          ["gzip", "identity"]
%%
pick_accepted_encodings(AcceptedEncs, SupportedEncs, DefaultEnc) ->
    SortedQList = lists:reverse(
        lists:sort(fun({_, Q1}, {_, Q2}) -> Q1 < Q2 end, AcceptedEncs)
    ),
    {Accepted, Refused} = lists:foldr(
        fun({E, Q}, {A, R}) ->
            case Q > 0.0 of
                true ->
                    {[E | A], R};
                false ->
                    {A, [E | R]}
            end
        end,
        {[], []},
        SortedQList
    ),
    Refused1 = lists:foldr(
        fun(Enc, Acc) ->
            case Enc of
                "*" ->
                    lists:subtract(SupportedEncs, Accepted) ++ Acc;
                _ ->
                    [Enc | Acc]
            end
        end,
        [],
        Refused
    ),
    Accepted1 = lists:foldr(
        fun(Enc, Acc) ->
            case Enc of
                "*" ->
                    lists:subtract(SupportedEncs, Accepted ++ Refused1) ++ Acc;
                _ ->
                    [Enc | Acc]
            end
        end,
        [],
        Accepted
    ),
    Accepted2 = case lists:member(DefaultEnc, Accepted1) of
        true ->
            Accepted1;
        false ->
            Accepted1 ++ [DefaultEnc]
    end,
    [E || E <- Accepted2, lists:member(E, SupportedEncs),
        not lists:member(E, Refused1)].

make_io(Atom) when is_atom(Atom) ->
    atom_to_list(Atom);
make_io(Integer) when is_integer(Integer) ->
    integer_to_list(Integer);
make_io(Io) when is_list(Io); is_binary(Io) ->
    Io.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

make_io_test() ->
    ?assertEqual(
       <<"atom">>,
       iolist_to_binary(make_io(atom))),
    ?assertEqual(
       <<"20">>,
       iolist_to_binary(make_io(20))),
    ?assertEqual(
       <<"list">>,
       iolist_to_binary(make_io("list"))),
    ?assertEqual(
       <<"binary">>,
       iolist_to_binary(make_io(<<"binary">>))),
    ok.

-record(test_record, {field1=f1, field2=f2}).
record_to_proplist_test() ->
    ?assertEqual(
       [{'__record', test_record},
        {field1, f1},
        {field2, f2}],
       record_to_proplist(#test_record{}, record_info(fields, test_record))),
    ?assertEqual(
       [{'typekey', test_record},
        {field1, f1},
        {field2, f2}],
       record_to_proplist(#test_record{},
                          record_info(fields, test_record),
                          typekey)),
    ok.

shell_quote_test() ->
    ?assertEqual(
       "\"foo \\$bar\\\"\\`' baz\"",
       shell_quote("foo $bar\"`' baz")),
    ok.

cmd_port_test_spool(Port, Acc) ->
    receive
        {Port, eof} ->
            Acc;
        {Port, {data, {eol, Data}}} ->
            cmd_port_test_spool(Port, ["\n", Data | Acc]);
        {Port, Unknown} ->
            throw({unknown, Unknown})
    after 1000 ->
            throw(timeout)
    end.

cmd_port_test() ->
    Port = cmd_port(["echo", "$bling$ `word`!"],
                    [eof, stream, {line, 4096}]),
    Res = try lists:append(lists:reverse(cmd_port_test_spool(Port, [])))
          after catch port_close(Port)
          end,
    self() ! {Port, wtf},
    try cmd_port_test_spool(Port, [])
    catch throw:{unknown, wtf} -> ok
    end,
    try cmd_port_test_spool(Port, [])
    catch throw:timeout -> ok
    end,
    ?assertEqual(
       "$bling$ `word`!\n",
       Res).

cmd_test() ->
    ?assertEqual(
       "$bling$ `word`!\n",
       cmd(["echo", "$bling$ `word`!"])),
    ok.

cmd_string_test() ->
    ?assertEqual(
       "\"echo\" \"\\$bling\\$ \\`word\\`!\"",
       cmd_string(["echo", "$bling$ `word`!"])),
    ok.

cmd_status_test() ->
    ?assertEqual(
       {0, <<"$bling$ `word`!\n">>},
       cmd_status(["echo", "$bling$ `word`!"])),
    ok.


parse_header_test() ->
    ?assertEqual(
       {"multipart/form-data", [{"boundary", "AaB03x"}]},
       parse_header("multipart/form-data; boundary=AaB03x")),
    %% This tests (currently) intentionally broken behavior
    ?assertEqual(
       {"multipart/form-data",
        [{"b", ""},
         {"cgi", "is"},
         {"broken", "true\"e"}]},
       parse_header("multipart/form-data;b=;cgi=\"i\\s;broken=true\"e;=z;z")),
    ok.

guess_mime_test() ->
    "text/plain" = guess_mime(""),
    "text/plain" = guess_mime(".text"),
    "application/zip" = guess_mime(".zip"),
    "application/zip" = guess_mime("x.zip"),
    "text/html" = guess_mime("x.html"),
    "application/xhtml+xml" = guess_mime("x.xhtml"),
    ok.

path_split_test() ->
    {"", "foo/bar"} = path_split("/foo/bar"),
    {"foo", "bar"} = path_split("foo/bar"),
    {"bar", ""} = path_split("bar"),
    ok.

urlsplit_test() ->
    {"", "", "/foo", "", "bar?baz"} = urlsplit("/foo#bar?baz"),
    {"http", "host:port", "/foo", "", "bar?baz"} =
        urlsplit("http://host:port/foo#bar?baz"),
    {"http", "host", "", "", ""} = urlsplit("http://host"),
    {"", "", "/wiki/Category:Fruit", "", ""} =
        urlsplit("/wiki/Category:Fruit"),
    ok.

urlsplit_path_test() ->
    {"/foo/bar", "", ""} = urlsplit_path("/foo/bar"),
    {"/foo", "baz", ""} = urlsplit_path("/foo?baz"),
    {"/foo", "", "bar?baz"} = urlsplit_path("/foo#bar?baz"),
    {"/foo", "", "bar?baz#wibble"} = urlsplit_path("/foo#bar?baz#wibble"),
    {"/foo", "bar", "baz"} = urlsplit_path("/foo?bar#baz"),
    {"/foo", "bar?baz", "baz"} = urlsplit_path("/foo?bar?baz#baz"),
    ok.

urlunsplit_test() ->
    "/foo#bar?baz" = urlunsplit({"", "", "/foo", "", "bar?baz"}),
    "http://host:port/foo#bar?baz" =
        urlunsplit({"http", "host:port", "/foo", "", "bar?baz"}),
    ok.

urlunsplit_path_test() ->
    "/foo/bar" = urlunsplit_path({"/foo/bar", "", ""}),
    "/foo?baz" = urlunsplit_path({"/foo", "baz", ""}),
    "/foo#bar?baz" = urlunsplit_path({"/foo", "", "bar?baz"}),
    "/foo#bar?baz#wibble" = urlunsplit_path({"/foo", "", "bar?baz#wibble"}),
    "/foo?bar#baz" = urlunsplit_path({"/foo", "bar", "baz"}),
    "/foo?bar?baz#baz" = urlunsplit_path({"/foo", "bar?baz", "baz"}),
    ok.

join_test() ->
    ?assertEqual("foo,bar,baz",
                  join(["foo", "bar", "baz"], $,)),
    ?assertEqual("foo,bar,baz",
                  join(["foo", "bar", "baz"], ",")),
    ?assertEqual("foo bar",
                  join([["foo", " bar"]], ",")),
    ?assertEqual("foo bar,baz",
                  join([["foo", " bar"], "baz"], ",")),
    ?assertEqual("foo",
                  join(["foo"], ",")),
    ?assertEqual("foobarbaz",
                  join(["foo", "bar", "baz"], "")),
    ?assertEqual("foo" ++ [<<>>] ++ "bar" ++ [<<>>] ++ "baz",
                 join(["foo", "bar", "baz"], <<>>)),
    ?assertEqual("foobar" ++ [<<"baz">>],
                 join(["foo", "bar", <<"baz">>], "")),
    ?assertEqual("",
                 join([], "any")),
    ok.

quote_plus_test() ->
    "foo" = quote_plus(foo),
    "1" = quote_plus(1),
    "1.1" = quote_plus(1.1),
    "foo" = quote_plus("foo"),
    "foo+bar" = quote_plus("foo bar"),
    "foo%0A" = quote_plus("foo\n"),
    "foo%0A" = quote_plus("foo\n"),
    "foo%3B%26%3D" = quote_plus("foo;&="),
    "foo%3B%26%3D" = quote_plus(<<"foo;&=">>),
    ok.

unquote_test() ->
    ?assertEqual("foo bar",
                 unquote("foo+bar")),
    ?assertEqual("foo bar",
                 unquote("foo%20bar")),
    ?assertEqual("foo\r\n",
                 unquote("foo%0D%0A")),
    ?assertEqual("foo\r\n",
                 unquote(<<"foo%0D%0A">>)),
    ok.

urlencode_test() ->
    "foo=bar&baz=wibble+%0D%0A&z=1" = urlencode([{foo, "bar"},
                                                 {"baz", "wibble \r\n"},
                                                 {z, 1}]),
    ok.

parse_qs_test() ->
    ?assertEqual(
       [{"foo", "bar"}, {"baz", "wibble \r\n"}, {"z", "1"}],
       parse_qs("foo=bar&baz=wibble+%0D%0a&z=1")),
    ?assertEqual(
       [{"", "bar"}, {"baz", "wibble \r\n"}, {"z", ""}],
       parse_qs("=bar&baz=wibble+%0D%0a&z=")),
    ?assertEqual(
       [{"foo", "bar"}, {"baz", "wibble \r\n"}, {"z", "1"}],
       parse_qs(<<"foo=bar&baz=wibble+%0D%0a&z=1">>)),
    ?assertEqual(
       [],
       parse_qs("")),
    ?assertEqual(
       [{"foo", ""}, {"bar", ""}, {"baz", ""}],
       parse_qs("foo;bar&baz")),
    ok.

partition_test() ->
    {"foo", "", ""} = partition("foo", "/"),
    {"foo", "/", "bar"} = partition("foo/bar", "/"),
    {"foo", "/", ""} = partition("foo/", "/"),
    {"", "/", "bar"} = partition("/bar", "/"),
    {"f", "oo/ba", "r"} = partition("foo/bar", "oo/ba"),
    ok.

safe_relative_path_test() ->
    "foo" = safe_relative_path("foo"),
    "foo/" = safe_relative_path("foo/"),
    "foo" = safe_relative_path("foo/bar/.."),
    "bar" = safe_relative_path("foo/../bar"),
    "bar/" = safe_relative_path("foo/../bar/"),
    "" = safe_relative_path("foo/.."),
    "" = safe_relative_path("foo/../"),
    undefined = safe_relative_path("/foo"),
    undefined = safe_relative_path("../foo"),
    undefined = safe_relative_path("foo/../.."),
    undefined = safe_relative_path("foo//"),
    ok.

parse_qvalues_test() ->
    [] = parse_qvalues(""),
    [{"identity", 0.0}] = parse_qvalues("identity;q=0"),
    [{"identity", 0.0}] = parse_qvalues("identity ;q=0"),
    [{"identity", 0.0}] = parse_qvalues(" identity; q =0 "),
    [{"identity", 0.0}] = parse_qvalues("identity ; q = 0"),
    [{"identity", 0.0}] = parse_qvalues("identity ; q= 0.0"),
    [{"gzip", 1.0}, {"deflate", 1.0}, {"identity", 0.0}] = parse_qvalues(
        "gzip,deflate,identity;q=0.0"
    ),
    [{"deflate", 1.0}, {"gzip", 1.0}, {"identity", 0.0}] = parse_qvalues(
        "deflate,gzip,identity;q=0.0"
    ),
    [{"gzip", 1.0}, {"deflate", 1.0}, {"gzip", 1.0}, {"identity", 0.0}] =
        parse_qvalues("gzip,deflate,gzip,identity;q=0"),
    [{"gzip", 1.0}, {"deflate", 1.0}, {"identity", 0.0}] = parse_qvalues(
        "gzip, deflate , identity; q=0.0"
    ),
    [{"gzip", 1.0}, {"deflate", 1.0}, {"identity", 0.0}] = parse_qvalues(
        "gzip; q=1, deflate;q=1.0, identity;q=0.0"
    ),
    [{"gzip", 0.5}, {"deflate", 1.0}, {"identity", 0.0}] = parse_qvalues(
        "gzip; q=0.5, deflate;q=1.0, identity;q=0"
    ),
    [{"gzip", 0.5}, {"deflate", 1.0}, {"identity", 0.0}] = parse_qvalues(
        "gzip; q=0.5, deflate , identity;q=0.0"
    ),
    [{"gzip", 0.5}, {"deflate", 0.8}, {"identity", 0.0}] = parse_qvalues(
        "gzip; q=0.5, deflate;q=0.8, identity;q=0.0"
    ),
    [{"gzip", 0.5}, {"deflate", 1.0}, {"identity", 1.0}] = parse_qvalues(
        "gzip; q=0.5,deflate,identity"
    ),
    [{"gzip", 0.5}, {"deflate", 1.0}, {"identity", 1.0}, {"identity", 1.0}] =
        parse_qvalues("gzip; q=0.5,deflate,identity, identity "),
    [{"text/html;level=1", 1.0}, {"text/plain", 0.5}] =
        parse_qvalues("text/html;level=1, text/plain;q=0.5"),
    [{"text/html;level=1", 0.3}, {"text/plain", 1.0}] =
        parse_qvalues("text/html;level=1;q=0.3, text/plain"),
    [{"text/html;level=1", 0.3}, {"text/plain", 1.0}] =
        parse_qvalues("text/html; level = 1; q = 0.3, text/plain"),
    [{"text/html;level=1", 0.3}, {"text/plain", 1.0}] =
        parse_qvalues("text/html;q=0.3;level=1, text/plain"),
    invalid_qvalue_string = parse_qvalues("gzip; q=1.1, deflate"),
    invalid_qvalue_string = parse_qvalues("gzip; q=0.5, deflate;q=2"),
    invalid_qvalue_string = parse_qvalues("gzip, deflate;q=AB"),
    invalid_qvalue_string = parse_qvalues("gzip; q=2.1, deflate"),
    invalid_qvalue_string = parse_qvalues("gzip; q=0.1234, deflate"),
    invalid_qvalue_string = parse_qvalues("text/html;level=1;q=0.3, text/html;level"),
    ok.

pick_accepted_encodings_test() ->
    ["identity"] = pick_accepted_encodings(
        [],
        ["gzip", "identity"],
        "identity"
    ),
    ["gzip", "identity"] = pick_accepted_encodings(
        [{"gzip", 1.0}],
        ["gzip", "identity"],
        "identity"
    ),
    ["identity"] = pick_accepted_encodings(
        [{"gzip", 0.0}],
        ["gzip", "identity"],
        "identity"
    ),
    ["gzip", "identity"] = pick_accepted_encodings(
        [{"gzip", 1.0}, {"deflate", 1.0}],
        ["gzip", "identity"],
        "identity"
    ),
    ["gzip", "identity"] = pick_accepted_encodings(
        [{"gzip", 0.5}, {"deflate", 1.0}],
        ["gzip", "identity"],
        "identity"
    ),
    ["identity"] = pick_accepted_encodings(
        [{"gzip", 0.0}, {"deflate", 0.0}],
        ["gzip", "identity"],
        "identity"
    ),
    ["gzip"] = pick_accepted_encodings(
        [{"gzip", 1.0}, {"deflate", 1.0}, {"identity", 0.0}],
        ["gzip", "identity"],
        "identity"
    ),
    ["gzip", "deflate", "identity"] = pick_accepted_encodings(
        [{"gzip", 1.0}, {"deflate", 1.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip", "deflate"] = pick_accepted_encodings(
        [{"gzip", 1.0}, {"deflate", 1.0}, {"identity", 0.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["deflate", "gzip", "identity"] = pick_accepted_encodings(
        [{"gzip", 0.2}, {"deflate", 1.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["deflate", "deflate", "gzip", "identity"] = pick_accepted_encodings(
        [{"gzip", 0.2}, {"deflate", 1.0}, {"deflate", 1.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["deflate", "gzip", "gzip", "identity"] = pick_accepted_encodings(
        [{"gzip", 0.2}, {"deflate", 1.0}, {"gzip", 1.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip", "deflate", "gzip", "identity"] = pick_accepted_encodings(
        [{"gzip", 0.2}, {"deflate", 0.9}, {"gzip", 1.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    [] = pick_accepted_encodings(
        [{"*", 0.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip", "deflate", "identity"] = pick_accepted_encodings(
        [{"*", 1.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip", "deflate", "identity"] = pick_accepted_encodings(
        [{"*", 0.6}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip"] = pick_accepted_encodings(
        [{"gzip", 1.0}, {"*", 0.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip", "deflate"] = pick_accepted_encodings(
        [{"gzip", 1.0}, {"deflate", 0.6}, {"*", 0.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["deflate", "gzip"] = pick_accepted_encodings(
        [{"gzip", 0.5}, {"deflate", 1.0}, {"*", 0.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip", "identity"] = pick_accepted_encodings(
        [{"deflate", 0.0}, {"*", 1.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ["gzip", "identity"] = pick_accepted_encodings(
        [{"*", 1.0}, {"deflate", 0.0}],
        ["gzip", "deflate", "identity"],
        "identity"
    ),
    ok.

-endif.
%% @copyright 2007 Mochi Media, Inc.
%% @author Matthew Dempsky <matthew@mochimedia.com>
%%
%% @doc Erlang module for automatically reloading modified modules
%% during development.

-module(reloader).
-author("Matthew Dempsky <matthew@mochimedia.com>").

-include_lib("kernel/include/file.hrl").

-behaviour(gen_server).
-export([start/0, start_link/0]).
-export([stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([all_changed/0]).
-export([is_changed/1]).
-export([reload_modules/1]).
-record(state, {last, tref}).

%% External API

%% @spec start() -> ServerRet
%% @doc Start the reloader.
start() ->
    gen_server:start({local, ?MODULE}, ?MODULE, [], []).

%% @spec start_link() -> ServerRet
%% @doc Start the reloader.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @spec stop() -> ok
%% @doc Stop the reloader.
stop() ->
    gen_server:call(?MODULE, stop).

%% gen_server callbacks

%% @spec init([]) -> {ok, State}
%% @doc gen_server init, opens the server in an initial state.
init([]) ->
    {ok, TRef} = timer:send_interval(timer:seconds(1), doit),
    {ok, #state{last = stamp(), tref = TRef}}.

%% @spec handle_call(Args, From, State) -> tuple()
%% @doc gen_server callback.
handle_call(stop, _From, State) ->
    {stop, shutdown, stopped, State};
handle_call(_Req, _From, State) ->
    {reply, {error, badrequest}, State}.

%% @spec handle_cast(Cast, State) -> tuple()
%% @doc gen_server callback.
handle_cast(_Req, State) ->
    {noreply, State}.

%% @spec handle_info(Info, State) -> tuple()
%% @doc gen_server callback.
handle_info(doit, State) ->
    Now = stamp(),
    _ = doit(State#state.last, Now),
    {noreply, State#state{last = Now}};
handle_info(_Info, State) ->
    {noreply, State}.

%% @spec terminate(Reason, State) -> ok
%% @doc gen_server termination callback.
terminate(_Reason, State) ->
    {ok, cancel} = timer:cancel(State#state.tref),
    ok.


%% @spec code_change(_OldVsn, State, _Extra) -> State
%% @doc gen_server code_change callback (trivial).
code_change(_Vsn, State, _Extra) ->
    {ok, State}.

%% @spec reload_modules([atom()]) -> [{module, atom()} | {error, term()}]
%% @doc code:purge/1 and code:load_file/1 the given list of modules in order,
%%      return the results of code:load_file/1.
reload_modules(Modules) ->
    [begin code:purge(M), code:load_file(M) end || M <- Modules].

%% @spec all_changed() -> [atom()]
%% @doc Return a list of beam modules that have changed.
all_changed() ->
    [M || {M, Fn} <- code:all_loaded(), is_list(Fn), is_changed(M)].

%% @spec is_changed(atom()) -> boolean()
%% @doc true if the loaded module is a beam with a vsn attribute
%%      and does not match the on-disk beam file, returns false otherwise.
is_changed(M) ->
    try
        module_vsn(M:module_info()) =/= module_vsn(code:get_object_code(M))
    catch _:_ ->
            false
    end.

%% Internal API

module_vsn({M, Beam, _Fn}) ->
    {ok, {M, Vsn}} = beam_lib:version(Beam),
    Vsn;
module_vsn(L) when is_list(L) ->
    {_, Attrs} = lists:keyfind(attributes, 1, L),
    {_, Vsn} = lists:keyfind(vsn, 1, Attrs),
    Vsn.

doit(From, To) ->
    [case file:read_file_info(Filename) of
         {ok, #file_info{mtime = Mtime}} when Mtime >= From, Mtime < To ->
             reload(Module);
         {ok, _} ->
             unmodified;
         {error, enoent} ->
             %% The Erlang compiler deletes existing .beam files if
             %% recompiling fails.  Maybe it's worth spitting out a
             %% warning here, but I'd want to limit it to just once.
             gone;
         {error, Reason} ->
             io:format("Error reading ~s's file info: ~p~n",
                       [Filename, Reason]),
             error
     end || {Module, Filename} <- code:all_loaded(), is_list(Filename)].

reload(Module) ->
    io:format("Reloading ~p ...", [Module]),
    code:purge(Module),
    case code:load_file(Module) of
        {module, Module} ->
            io:format(" ok.~n"),
            case erlang:function_exported(Module, test, 0) of
                true ->
                    io:format(" - Calling ~p:test() ...", [Module]),
                    case catch Module:test() of
                        ok ->
                            io:format(" ok.~n"),
                            reload;
                        Reason ->
                            io:format(" fail: ~p.~n", [Reason]),
                            reload_but_test_failed
                    end;
                false ->
                    reload
            end;
        {error, Reason} ->
            io:format(" fail: ~p.~n", [Reason]),
            error
    end.


stamp() ->
    erlang:localtime().

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

% vim: set sw=4:
