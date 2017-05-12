#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#if (LUA_VERSION_NUM < 501) || (LUA_VERSION_NUM > 502)
# error "Lua 5.1 or 5.2 required"
#endif

int main (void) {
    void *p = (void *) lua_getfield;
    return 0;
}
