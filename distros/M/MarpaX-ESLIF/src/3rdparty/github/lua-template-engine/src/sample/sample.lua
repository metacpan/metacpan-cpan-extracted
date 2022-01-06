local tpleval = require('template-text').template_eval

-- In the whole file we skip checking the 'ok' return value assuming everything
-- goes fine, for brevity.


-- -------------------------------------------------------------------------- --
-- BASIC

local tpl = [[
This is a text template.
It supports variables:
Hello $(name) !
]]

local ok, text = tpleval(tpl, {name="Marco"} )
print(text)
print("\n\n")


-- -------------------------------------------------------------------------- --
-- Xtend STYLE VARIABLES

tpl = [[
Xtend style variables are also supported, using the appropriate option.
Hello «name» !
]]

ok, text = tpleval(tpl, {name="Marco"}, {xtendStyle=true} )
print(text)
print("\n\n")


-- -------------------------------------------------------------------------- --
-- EXPRESSIONS

tpl = [[
The thing enclosed in the special delimiters can be any valid Lua expression
that is defined in the environment passed to the template evaluation function.

This is an example using a function: «func(4)»
]]

local myFunc = function(i) return i*4 end
ok, text = tpleval(tpl, {func=myFunc}, {xtendStyle=true})
print(text)
print("\n\n")


-- -------------------------------------------------------------------------- --
-- LUA CODE

tpl = [[
The template can also contain arbitrary Lua code. Just start the line with '@'.
Here is an example using a for loop:
@ for k,v in pairs(aTable) do
This is the value in the table: «v»
@ end
]]

local myTable = {"dog", "cat", "chicken", "pig", "crocodile" }
ok, text = tpleval(tpl, {aTable=myTable}, {xtendStyle=true})
print(text)
print("\n\n")


-- -------------------------------------------------------------------------- --
-- RETURN TABLE and TABLE EXPANSION

tpl = [[
Another option is to return a table instead of text.
The table will have an element for each line of the original template.
This is very powerful in combination with the table expansion syntax.

   ${aTable}
]]

ok, tabletext = tpleval(tpl, {aTable=myTable}, {returnTable=true}) -- note the option 'returnTable'

tpl = [[
    ${tabletext}

Note how the table expansion preserves the indentation for each line inside the
table itself
]]

ok, text = tpleval(tpl, {tabletext=tabletext} )
print(text)
print("\n\n")



