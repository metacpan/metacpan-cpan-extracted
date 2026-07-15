use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple function
{
	my $code = <<'END';
local function greet(name)
	return "Hello, " .. name .. "!"
end
END
	is(lua($code), $code, 'Lua: simple function');
}

# 2. if/elseif/else
{
	my $code = <<'END';
local function classify(n)
	if n < 0 then
		return "negative"
	elseif n == 0 then
		return "zero"
	else
		return "positive"
	end
end
END
	is(lua($code), $code, 'Lua: if/elseif/else');
}

# 3. for numeric loop
{
	my $code = <<'END';
local function sum_to(n)
	local total = 0
	for i = 1, n do
		total = total + i
	end
	return total
end
END
	is(lua($code), $code, 'Lua: numeric for loop');
}

# 4. while loop
{
	my $code = <<'END';
local function count_digits(n)
	local count = 0
	n = math.abs(n)
	repeat
		count = count + 1
		n = math.floor(n / 10)
	until n == 0
	return count
end
END
	is(lua($code), $code, 'Lua: repeat/until loop');
}

# 5. table as array
{
	my $code = <<'END';
local function map(t, fn)
	local out = {}
	for i, v in ipairs(t) do
		out[i] = fn(v)
	end
	return out
end
END
	is(lua($code), $code, 'Lua: table map with ipairs');
}

# 6. table as dict
{
	my $code = <<'END';
local function keys(t)
	local ks = {}
	for k in pairs(t) do
		ks[#ks + 1] = k
	end
	table.sort(ks)
	return ks
end
END
	is(lua($code), $code, 'Lua: keys with pairs');
}

# 7. closure
{
	my $code = <<'END';
local function make_counter(start)
	local n = start or 0
	return function()
		n = n + 1
		return n
	end
end
END
	is(lua($code), $code, 'Lua: closure counter');
}

# 8. OOP with metatables
{
	my $code = <<'END';
local Animal = {}
Animal.__index = Animal

function Animal.new(name, sound)
	local self = setmetatable({}, Animal)
	self.name  = name
	self.sound = sound
	return self
end

function Animal:speak()
	print(self.name .. " says " .. self.sound)
end
END
	is(lua($code), $code, 'Lua: OOP with metatable');
}

# 9. inheritance
{
	my $code = <<'END';
local Dog = setmetatable({}, { __index = Animal })
Dog.__index = Dog

function Dog.new(name)
	local self = Animal.new(name, "woof")
	return setmetatable(self, Dog)
end

function Dog:fetch(item)
	print(self.name .. " fetches " .. item)
end
END
	is(lua($code), $code, 'Lua: metatable inheritance');
}

# 10. module pattern
{
	my $code = <<'END';
local M = {}

function M.trim(s)
	return s:match("^%s*(.-)%s*$")
end

function M.split(s, sep)
	local parts = {}
	for part in s:gmatch("[^" .. sep .. "]+") do
		parts[#parts + 1] = part
	end
	return parts
end

return M
END
	is(lua($code), $code, 'Lua: module pattern');
}

# 11. pcall error handling
{
	my $code = <<'END';
local function safe_call(fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		io.stderr:write("Error: " .. tostring(result) .. "\n")
		return nil, result
	end
	return result, nil
end
END
	is(lua($code), $code, 'Lua: pcall wrapper');
}

# 12. coroutine producer
{
	my $code = <<'END';
local function range_iter(from, to)
	return coroutine.wrap(function()
	for i = from, to do
	coroutine.yield(i)
	end
	end)
end
END
	is(lua($code), $code, 'Lua: coroutine range iterator');
}

# 13. recursive table printer
{
	my $code = <<'END';
local function dump(t, indent)
	indent = indent or 0
	local prefix = string.rep("  ", indent)
	for k, v in pairs(t) do
		if type(v) == "table" then
			print(prefix .. tostring(k) .. ":")
			dump(v, indent + 1)
		else
			print(prefix .. tostring(k) .. " = " .. tostring(v))
		end
	end
end
END
	is(lua($code), $code, 'Lua: recursive table dump');
}

# 14. memoize
{
	my $code = <<'END';
local function memoize(fn)
	local cache = {}
	return function(...)
		local key = table.concat({...}, "\0")
		if cache[key] == nil then
			cache[key] = fn(...)
		end
		return cache[key]
	end
end
END
	is(lua($code), $code, 'Lua: memoize decorator');
}

# 15. filter and reduce
{
	my $code = <<'END';
local function filter(t, pred)
	local out = {}
	for _, v in ipairs(t) do
		if pred(v) then
			out[#out + 1] = v
		end
	end
	return out
end

local function reduce(t, fn, init)
	local acc = init
	for _, v in ipairs(t) do
		acc = fn(acc, v)
	end
	return acc
end
END
	is(lua($code), $code, 'Lua: filter and reduce');
}

# 16. string patterns
{
	my $code = <<'END';
local function parse_kv(line)
	local key, val = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
	if not key then
		return nil, "bad format"
	end
	return key, val
end
END
	is(lua($code), $code, 'Lua: key-value pattern parser');
}

# 17. deep copy
{
	my $code = <<'END';
local function deep_copy(orig)
	local copy
	if type(orig) == "table" then
		copy = {}
		for k, v in pairs(orig) do
			copy[deep_copy(k)] = deep_copy(v)
		end
		setmetatable(copy, getmetatable(orig))
	else
		copy = orig
	end
	return copy
end
END
	is(lua($code), $code, 'Lua: deep copy');
}

# 18. event emitter
{
	my $code = <<'END';
local Emitter = {}
Emitter.__index = Emitter

function Emitter.new()
	return setmetatable({ _listeners = {} }, Emitter)
end

function Emitter:on(event, fn)
	if not self._listeners[event] then
		self._listeners[event] = {}
	end
	table.insert(self._listeners[event], fn)
end

function Emitter:emit(event, ...)
	for _, fn in ipairs(self._listeners[event] or {}) do
		fn(...)
	end
end
END
	is(lua($code), $code, 'Lua: event emitter');
}

# 19. linked list
{
	my $code = <<'END';
local function List()
	return { head = nil, size = 0 }
end

local function push(list, val)
	list.head = { val = val, next = list.head }
	list.size = list.size + 1
end

local function pop(list)
	if not list.head then
		return nil
	end
	local val = list.head.val
	list.head = list.head.next
	list.size = list.size - 1
	return val
end
END
	is(lua($code), $code, 'Lua: linked list');
}

# 20. binary search
{
	my $code = <<'END';
local function bsearch(arr, target)
	local lo, hi = 1, #arr
	while lo <= hi do
		local mid = math.floor((lo + hi) / 2)
		if arr[mid] == target then
			return mid
		elseif arr[mid] < target then
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
	return nil
end
END
	is(lua($code), $code, 'Lua: binary search');
}

# 21. pipeline
{
	my $code = <<'END';
local function pipeline(...)
	local fns = {...}
	return function(v)
		for _, fn in ipairs(fns) do
			v = fn(v)
		end
		return v
	end
end
END
	is(lua($code), $code, 'Lua: function pipeline');
}

# 22. string builder
{
	my $code = <<'END';
local StringBuilder = {}
StringBuilder.__index = StringBuilder

function StringBuilder.new()
	return setmetatable({ parts = {} }, StringBuilder)
end

function StringBuilder:append(s)
	self.parts[#self.parts + 1] = tostring(s)
	return self
end

function StringBuilder:toString()
	return table.concat(self.parts)
end
END
	is(lua($code), $code, 'Lua: string builder');
}

# 23. queue
{
	my $code = <<'END';
local Queue = {}
Queue.__index = Queue

function Queue.new()
	return setmetatable({ first = 1, last = 0, data = {} }, Queue)
end

function Queue:push(val)
	self.last = self.last + 1
	self.data[self.last] = val
end

function Queue:pop()
	if self.first > self.last then
		return nil
	end
	local val = self.data[self.first]
	self.data[self.first] = nil
	self.first = self.first + 1
	return val
end
END
	is(lua($code), $code, 'Lua: queue implementation');
}

# 24. flatten
{
	my $code = <<'END';
local function flatten(t, out)
	out = out or {}
	for _, v in ipairs(t) do
		if type(v) == "table" then
			flatten(v, out)
		else
			out[#out + 1] = v
		end
	end
	return out
end
END
	is(lua($code), $code, 'Lua: flatten nested table');
}

# 25. trie
{
	my $code = <<'END';
local function Trie()
	return { children = {}, terminal = false }
end

local function insert(root, word)
	local node = root
	for i = 1, #word do
		local c = word:sub(i, i)
		if not node.children[c] then
			node.children[c] = Trie()
		end
		node = node.children[c]
	end
	node.terminal = true
end

local function search(root, word)
	local node = root
	for i = 1, #word do
		local c = word:sub(i, i)
		if not node.children[c] then
			return false
		end
		node = node.children[c]
	end
	return node.terminal
end
END
	is(lua($code), $code, 'Lua: trie insert/search');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
local function factorial(n)
if n <= 1 then
return 1
end
return n * factorial(n - 1)
end
END
	my $exp = <<'END';
local function factorial(n)
	if n <= 1 then
		return 1
	end
	return n * factorial(n - 1)
end
END
	is(lua($in), $exp, 'Lua: unindented factorial normalised');
}

# 27
{
	my $in = <<'END';
local function fib(n)
if n <= 1 then
return n
end
return fib(n-1) + fib(n-2)
end
END
	my $exp = <<'END';
local function fib(n)
	if n <= 1 then
		return n
	end
	return fib(n-1) + fib(n-2)
end
END
	is(lua($in), $exp, 'Lua: unindented fibonacci normalised');
}

# 28
{
	my $in = <<'END';
local function reverse(t)
local out = {}
for i = #t, 1, -1 do
out[#out + 1] = t[i]
end
return out
end
END
	my $exp = <<'END';
local function reverse(t)
	local out = {}
	for i = #t, 1, -1 do
		out[#out + 1] = t[i]
	end
	return out
end
END
	is(lua($in), $exp, 'Lua: unindented reverse normalised');
}

# 29
{
	my $in = <<'END';
local function zip(a, b)
local out = {}
local n = math.min(#a, #b)
for i = 1, n do
out[i] = {a[i], b[i]}
end
return out
end
END
	my $exp = <<'END';
local function zip(a, b)
	local out = {}
	local n = math.min(#a, #b)
	for i = 1, n do
		out[i] = {a[i], b[i]}
	end
	return out
end
END
	is(lua($in), $exp, 'Lua: unindented zip normalised');
}

# 30
{
	my $in = <<'END';
local function partition(t, pred)
local yes, no = {}, {}
for _, v in ipairs(t) do
if pred(v) then
yes[#yes + 1] = v
else
no[#no + 1] = v
end
end
return yes, no
end
END
	my $exp = <<'END';
local function partition(t, pred)
	local yes, no = {}, {}
	for _, v in ipairs(t) do
		if pred(v) then
			yes[#yes + 1] = v
		else
			no[#no + 1] = v
		end
	end
	return yes, no
end
END
	is(lua($in), $exp, 'Lua: unindented partition normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	"local Set={}\nSet.__index=Set\nfunction Set.new(t)\nlocal s=setmetatable({_data={}},Set)\nfor _,v in ipairs(t or {}) do s:add(v) end\nreturn s\nend\nfunction Set:add(v) self._data[v]=true end\nfunction Set:has(v) return self._data[v]==true end\nfunction Set:size() local n=0;for _ in pairs(self._data) do n=n+1 end;return n end\n",
	"local function mergesort(t)\nif #t<=1 then return t end\nlocal mid=math.floor(#t/2)\nlocal a=mergesort({table.unpack(t,1,mid)})\nlocal b=mergesort({table.unpack(t,mid+1)})\nlocal out={}\nlocal i,j=1,1\nwhile i<=#a and j<=#b do\nif a[i]<=b[j] then out[#out+1]=a[i];i=i+1\nelse out[#out+1]=b[j];j=j+1 end\nend\nwhile i<=#a do out[#out+1]=a[i];i=i+1 end\nwhile j<=#b do out[#out+1]=b[j];j=j+1 end\nreturn out\nend\n",
	"local Rx={}\nRx.__index=Rx\nfunction Rx.new() return setmetatable({subs={}},Rx) end\nfunction Rx:subscribe(fn) local id=#self.subs+1;self.subs[id]=fn;return function() self.subs[id]=nil end end\nfunction Rx:next(v) for _,fn in pairs(self.subs) do fn(v) end end\nfunction Rx:map(fn) local out=Rx.new();self:subscribe(function(v) out:next(fn(v)) end);return out end\n",
	"local function chunk(t,size)\nlocal out={}\nfor i=1,#t,size do\nout[#out+1]={table.unpack(t,i,math.min(i+size-1,#t))}\nend\nreturn out\nend\n",
	"local function compose(...)\nlocal fns={...}\nreturn function(v)\nfor i=#fns,1,-1 do v=fns[i](v) end\nreturn v\nend\nend\n",
	"local LRU={}\nLRU.__index=LRU\nfunction LRU.new(cap) return setmetatable({cap=cap,cache={},order={}},LRU) end\nfunction LRU:get(k)\nif not self.cache[k] then return nil end\nfor i,v in ipairs(self.order) do if v==k then table.remove(self.order,i);break end end\ntable.insert(self.order,1,k)\nreturn self.cache[k]\nend\nfunction LRU:set(k,v)\nif not self.cache[k] and #self.order>=self.cap then\nlocal evict=table.remove(self.order)\nself.cache[evict]=nil\nend\nself.cache[k]=v\nfor i,x in ipairs(self.order) do if x==k then table.remove(self.order,i);break end end\ntable.insert(self.order,1,k)\nend\n",
	"local function once(fn)\nlocal done=false;local result\nreturn function(...)\nif not done then result=fn(...);done=true end\nreturn result\nend\nend\n",
	"local function debounce(fn,delay)\nlocal timer\nreturn function(...)\nif timer then timer:cancel() end\ntimer=vim and vim.defer_fn and vim.defer_fn(function() fn(...) end,delay) or nil\nend\nend\n",
	"local function group_by(t,key_fn)\nlocal groups={}\nfor _,v in ipairs(t) do\nlocal k=key_fn(v)\nif not groups[k] then groups[k]={} end\ngroups[k][#groups[k]+1]=v\nend\nreturn groups\nend\n",
	"local function any(t,pred)\nfor _,v in ipairs(t) do if pred(v) then return true end end\nreturn false\nend\nlocal function all(t,pred)\nfor _,v in ipairs(t) do if not pred(v) then return false end end\nreturn true\nend\n",
) {
	my $once = lua($snippet);
	is(lua($once), $once, 'Lua: snippet idempotent');
}

done_testing;
