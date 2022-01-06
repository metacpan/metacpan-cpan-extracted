local tpleval = require('template-text').template_eval

local tpl = [[
Hi! This is a text template!
It can reference any symbol which is defined in the environment (i.e. a table)
given to the evaluation function:

Hello $(name) for $(many(5)) times!

Actual Lua code can be used in the template, starting the line with a '@':
@ for k,v in pairs( aTable ) do
key: $(k)    value: $(v)
@ end
]]

local dummyF = function(i) return i*3 end
local dummyT = {"bear", "wolf", "shark", "monkey"}

local ok, text = tpleval(tpl,
  { name   = "Marco",
    many   = dummyF,
    aTable = dummyT}
)
if not ok then
  print("ERROR: " .. text) -- in this case text would be an error message
else
  print(text)
end
