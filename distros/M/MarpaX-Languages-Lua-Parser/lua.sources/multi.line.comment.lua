result = 1 +
--[[
Testing multi-line comment 1
]]
2 +
--[[ Testing multi-line comment 2 ]]
3 +
--[=[ ]]  ]=]
4 +
--[==[
]] ]=] -- spurious terminators
]==]
5

io.write("Testing multi-line comment. Using ",_VERSION,
  ", result=", result, "\n")
