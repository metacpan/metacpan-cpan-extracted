#ifndef luaunpanic_macros_h
#define luaunpanic_macros_h

#define LUAUNPANIC_ON_VOID_FUNCTION(wrapper, L_decl_hook, call, ...)    \
  short wrapper(__VA_ARGS__) {                                          \
    L_decl_hook                                                         \
    short rc = 1;                                                       \
    luaunpanic_userdata_t *LW;                                          \
    if (L == NULL) {                                                    \
      errno = EINVAL;                                                   \
    } else {                                                            \
      LW = lua_getuserdata(L);                                          \
      if (LW != NULL) {                                                 \
        if (LW->panicstring != NULL) {                                  \
          if ((LW->panicstring != LUAUNPANIC_DEFAULT_PANICSTRING) && (LW->panicstring != LUAUNPANIC_UNKNOWN_PANICSTRING)) { \
            free(LW->panicstring);                                      \
          }                                                             \
          LW->panicstring = LUAUNPANIC_DEFAULT_PANICSTRING;             \
        }                                                               \
        TRY(LW) {                                                       \
          call;                                                         \
          rc = 0;                                                       \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        call;                                                           \
        rc = 0;                                                         \
      }                                                                 \
    }                                                                   \
    return rc;                                                          \
  }

#define LUAUNPANIC_ON_NON_VOID_FUNCTION(wrapper, L_decl_hook, type, call, ...) \
  short wrapper(type *luarcp, __VA_ARGS__) {                            \
    L_decl_hook                                                         \
    short rc = 1;                                                       \
    luaunpanic_userdata_t *LW;                                          \
    if (L == NULL) {                                                    \
      errno = EINVAL;                                                   \
    } else {                                                            \
      LW = lua_getuserdata(L);                                          \
      if (LW != NULL) {                                                 \
        if (LW->panicstring != NULL) {                                  \
          if ((LW->panicstring != LUAUNPANIC_DEFAULT_PANICSTRING) && (LW->panicstring != LUAUNPANIC_UNKNOWN_PANICSTRING)) { \
            free(LW->panicstring);                                      \
          }                                                             \
          LW->panicstring = LUAUNPANIC_DEFAULT_PANICSTRING;             \
        }                                                               \
        TRY(LW) {                                                       \
          type luarc;							\
          luarc = call;							\
          if (luarcp != NULL) {                                         \
            *luarcp = luarc;                                            \
          }                                                             \
          rc = 0;                                                       \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        type luarc;							\
        luarc = call;							\
        if (luarcp != NULL) {                                           \
          *luarcp = luarc;                                              \
        }                                                               \
        rc = 0;                                                         \
      }                                                                 \
    }                                                                   \
    return rc;                                                          \
  }

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
        if (LW->panicstring != NULL) {                                  \
          if ((LW->panicstring != LUAUNPANIC_DEFAULT_PANICSTRING) && (LW->panicstring != LUAUNPANIC_UNKNOWN_PANICSTRING)) { \
            free(LW->panicstring);                                      \
          }                                                             \
          LW->panicstring = LUAUNPANIC_DEFAULT_PANICSTRING;             \
        }                                                               \
        TRY(LW) {                                                       \
          type luarc;							\
          luarc = call;							\
          if (luarcp != NULL) {                                         \
            *luarcp = luarc;                                            \
          }                                                             \
          rc = 0;                                                       \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        type luarc;							\
        luarc = call;							\
        rc = 0;                                                         \
      }                                                                 \
    }                                                                   \
    va_end(apnamecopy);                                                 \
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
        if (LW->panicstring != NULL) {                                  \
          if ((LW->panicstring != LUAUNPANIC_DEFAULT_PANICSTRING) && (LW->panicstring != LUAUNPANIC_UNKNOWN_PANICSTRING)) { \
            free(LW->panicstring);                                      \
          }                                                             \
          LW->panicstring = LUAUNPANIC_DEFAULT_PANICSTRING;             \
        }                                                               \
        TRY(LW) {                                                       \
          type luarc;							\
          luarc = call;							\
          if (luarcp != NULL) {                                         \
            *luarcp = luarc;                                            \
          }                                                             \
          rc = 0;                                                       \
        }                                                               \
        ETRY(LW);							\
      } else {                                                          \
        type luarc;							\
        luarc = call;							\
        rc = 0;                                                         \
      }                                                                 \
    }                                                                   \
    va_end(apname);                                                     \
    return rc;                                                          \
  }

/* Take care: luaunpanic_is##what returns true if no panic and condition is true */
#define LUAUNPANIC_IS_XXX(what, condition, luatype)             \
  short luaunpanic_is##what(int *rcp, lua_State *L, int n)      \
  {                                                             \
    int type;                                                   \
    int rc;                                                     \
                                                                \
    if (! luaunpanic_type(&type, L, n)) {                       \
      rc = (type condition luatype);                            \
      if (rcp != NULL) {                                        \
        *rcp = rc;                                              \
      }                                                         \
      return 0;                                                 \
    } else {                                                    \
      return 1;                                                 \
    }                                                           \
  }

#endif /* luaunpanic_macros_h */
