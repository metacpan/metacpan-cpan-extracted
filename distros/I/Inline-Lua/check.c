#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#if (LUA_VERSION_NUM < 501) || (LUA_VERSION_NUM > 503)
# error "Lua 5.1, 5.2, 5.3 required"
#endif

int main (void) {
    void *p = (void *) lua_getfield;
    return 0;
}
