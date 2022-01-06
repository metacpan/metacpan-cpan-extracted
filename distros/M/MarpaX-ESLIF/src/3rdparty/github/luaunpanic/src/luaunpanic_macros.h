#ifndef luaunpanic_macros_h
#define luaunpanic_macros_h

#define _LUAUNPANIC_ON_VOID_FUNCTION(wrapper, L_decl_hook, call, luaunpanic_rc_if_success, ...) \
  short wrapper(__VA_ARGS__) {                                          \
    L_decl_hook                                                         \
    short rc = 1;                                                       \
    luaunpanic_userdata_t *LW;                                          \
                                                                        \
    if (L == NULL) {                                                    \
      errno = EINVAL;                                                   \
    } else {                                                            \
      LW = lua_getuserdata(L);                                          \
      if (LW != NULL) {                                                 \
        TRY(LW) {                                                       \
          call;                                                         \
          rc = luaunpanic_rc_if_success;                                \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        call;                                                           \
        rc = luaunpanic_rc_if_success;                                  \
      }                                                                 \
    }                                                                   \
                                                                        \
    return rc;                                                          \
  }

#define LUAUNPANIC_ON_VOID_FUNCTION(wrapper, L_decl_hook, call, ...)       _LUAUNPANIC_ON_VOID_FUNCTION(wrapper, L_decl_hook, call, 0, __VA_ARGS__)
#define LUAUNPANIC_ON_VOID_ERROR_FUNCTION(wrapper, L_decl_hook, call, ...) _LUAUNPANIC_ON_VOID_FUNCTION(wrapper, L_decl_hook, call, 1, __VA_ARGS__)

#define _LUAUNPANIC_ON_NON_VOID_FUNCTION(wrapper, L_decl_hook, type, luaunpanic_rc_if_success, call, ...) \
  short wrapper(type *luarcp, __VA_ARGS__) {                            \
    L_decl_hook                                                         \
    short rc = 1;                                                       \
    luaunpanic_userdata_t *LW;                                          \
                                                                        \
    if (L == NULL) {                                                    \
      errno = EINVAL;                                                   \
    } else {                                                            \
      LW = lua_getuserdata(L);                                          \
      if (LW != NULL) {                                                 \
        TRY(LW) {                                                       \
          type luarc;							\
          luarc = call;							\
          rc = luaunpanic_rc_if_success;                                \
          if (luarcp != NULL) {                                         \
            *luarcp = luarc;                                            \
          }                                                             \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        type luarc;							\
        luarc = call;							\
        rc = luaunpanic_rc_if_success;                                  \
        if (luarcp != NULL) {                                           \
          *luarcp = luarc;                                              \
        }                                                               \
      }                                                                 \
    }                                                                   \
                                                                        \
    return rc;                                                          \
  }

#define LUAUNPANIC_ON_NON_VOID_FUNCTION(wrapper, L_decl_hook, type, call, ...)       _LUAUNPANIC_ON_NON_VOID_FUNCTION(wrapper, L_decl_hook, type, 0, call, __VA_ARGS__)
#define LUAUNPANIC_ON_NON_VOID_ERROR_FUNCTION(wrapper, L_decl_hook, type, call, ...) _LUAUNPANIC_ON_NON_VOID_FUNCTION(wrapper, L_decl_hook, type, 1, call, __VA_ARGS__)

/* Special macro when the lua prototype ends with va_list */
#ifdef C_VA_COPY
#define LUAUNPANIC2ON_NON_VOID_FUNCTION(wrapper, L_decl_hook, type, call, apname, apnamecopy, ...) \
  short wrapper(type *luarcp, __VA_ARGS__) {                            \
    L_decl_hook                                                         \
    va_list apnamecopy;                                                 \
    short rc = 1;                                                       \
    luaunpanic_userdata_t *LW;                                          \
                                                                        \
    C_VA_COPY(apnamecopy, apname);                                      \
    if (L == NULL) {                                                    \
      errno = EINVAL;                                                   \
    } else {                                                            \
      LW = lua_getuserdata(L);                                          \
      if (LW != NULL) {                                                 \
        TRY(LW) {                                                       \
          type luarc;							\
          luarc = call;							\
          rc = 0;                                                       \
          if (luarcp != NULL) {                                         \
            *luarcp = luarc;                                            \
          }                                                             \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        type luarc;							\
        luarc = call;							\
        rc = 0;                                                         \
        if (luarcp != NULL) {                                           \
          *luarcp = luarc;                                              \
        }                                                               \
      }                                                                 \
    }                                                                   \
    va_end(apnamecopy);                                                 \
                                                                        \
    return rc;                                                          \
  }
#endif /* C_VA_COPY */

/* Special macro when the lua prototype ends with ... (ellipsis) */
#define LUAUNPANIC3ON_NON_VOID_FUNCTION(wrapper, L_decl_hook, type, call, vaguard, apname, ...) \
  short wrapper(type *luarcp, __VA_ARGS__) {                            \
    L_decl_hook                                                         \
    va_list apname;                                                     \
    short rc = 1;                                                       \
    luaunpanic_userdata_t *LW;                                          \
                                                                        \
    va_start(apname, vaguard);                                          \
    if (L == NULL) {                                                    \
      errno = EINVAL;                                                   \
    } else {                                                            \
      LW = lua_getuserdata(L);                                          \
      if (LW != NULL) {                                                 \
        TRY(LW) {                                                       \
          type luarc;							\
          luarc = call;							\
          rc = 0;                                                       \
          if (luarcp != NULL) {                                         \
            *luarcp = luarc;                                            \
          }                                                             \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        type luarc;							\
        luarc = call;							\
        rc = 0;                                                         \
        if (luarcp != NULL) {                                           \
          *luarcp = luarc;                                              \
        }                                                               \
      }                                                                 \
    }                                                                   \
    va_end(apname);                                                     \
                                                                        \
    return rc;                                                          \
  }

/* Take care: luaunpanic_is##what returns true if no panic and condition is true */
#define LUAUNPANIC_IS_XXX(what, condition, luatype)             \
  short luaunpanic_is##what(int *rcp, lua_State *L, int n)      \
  {                                                             \
    int type;                                                   \
    int rc;                                                     \
                                                                \
    if (luaunpanic_type(&type, L, n)) {                         \
      return 1;                                                 \
    }                                                           \
                                                                \
    rc = (type condition luatype);                              \
    if (rcp != NULL) {                                          \
      *rcp = rc;                                                \
    }                                                           \
                                                                \
    return 0;                                                   \
  }

#endif /* luaunpanic_macros_h */
