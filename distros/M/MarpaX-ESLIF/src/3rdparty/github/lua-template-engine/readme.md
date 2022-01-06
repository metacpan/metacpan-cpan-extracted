This is the readme file of the Lua Template Engine

# Overview
A Lua module for the evaluation of textual templates, for example to support
code generation.

Using a special syntax, templates can refer to _any valid Lua expression_ which
must be defined _in the environment passed to the evaluation function_.
Arbitrary Lua code can also be intertwined with the text.

Below is a representative example. For more simple examples, please see
`src/sample/sample.lua`.

```Lua
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
```

Running this sample with
```
cd src/sample
lua fromreadme.lua
```
should produce the following output:
```
Hi! This is a text template!
It can reference any symbol which is defined in the environment (i.e. a table)
given to the evaluation function:

Hello Marco for 15 times!

Actual Lua code can be used in the template, starting the line with a '@':
key: 1    value: bear
key: 2    value: wolf
key: 3    value: shark
key: 4    value: monkey

```

# Installing

## Via LuaRocks

If you can use [LuaRocks](https://luarocks.org/), then this command will install
the package from the public repository:

```
luarocks install --local template-text
```

Alternatively, you can install from a local clone of the source repository:

```sh
git clone https://github.com/mfrigerio17/lua-template-engine.git
cd lua-template-engine/
luarocks --local make           # installs the module locally
eval `luarocks path`            # need this everytime, with --local
lua src/sample/fromreadme.lua   # try a sample
```

Avoid the `--local` switch to install the module in a system-wide Lua directory.

## Manual installation
You may simply copy the source file `template-text.lua` in a system-wide Lua
directory.

```sh
git clone https://github.com/mfrigerio17/lua-template-engine.git
cd lua-template-engine/

# This one will need root privileges
mkdir -p /usr/local/share/lua/5.2/ && cp src/template-text.lua /usr/local/share/lua/5.2/

# Run a sample
lua src/sample/fromreadme.lua
```


## Installing LuaRocks
See [the official website](https://luarocks.org/).

Beware that the package-manger version of LuaRocks might default to Lua 5.1.
Install it manually with something like the following (replace `apt` with your
package manager, and run the install commands with root privileges):

```sh
apt install make wget unzip   # required later
apt install liblua5.2-dev     # also required, by LuaRocks
wget https://luarocks.org/releases/luarocks-3.3.1.tar.gz
tar zxpf luarocks-3.3.1.tar.gz
cd luarocks-3.3.1
./configure --lua-version=5.2
make && make install
```

# Dependencies

The template engine does not depend on any other module. Lua > 5.1 is required.

# Authorship

By Marco Frigerio, heavily based on the code available in the
[Lua-users-wiki](http://lua-users.org/wiki/SlightlyLessSimpleLuaPreprocessor)

Copyright © 2020-2021 Marco Frigerio  
All rights reserved.

Released under a permissive BSD license. See the `LICENSE` file for details.
