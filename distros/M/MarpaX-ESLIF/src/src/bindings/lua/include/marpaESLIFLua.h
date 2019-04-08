#ifndef MARPAESLIFLUA_H
#define MARPAESLIFLUA_H

#include "lua.h"         /* And not <lua.h> because it is not standardized as per CMake recommandation */

#ifndef MARPAESLIFLUA_EMBEDDED
#include <marpaESLIFLua/export.h>

#ifdef __cplusplus
extern "C" {
#endif
  marpaESLIFLua_EXPORT int luaopen_marpaESLIFLua(lua_State *L);
#ifdef __cplusplus
}
#endif
#else
/* ------------------------------------------------------------------------------------------------- */
/* When MARPAESLIFLUA_EMBEDDED is on, the source file marpaESLIFLua.c should be included as-is, NO   */
/* symbol is exported. The file that includes marpaESLIFLua.c is expected to:                        */
/*                                                                                                   */
/* - Register marpaESLIFLua programmatically:                                                        */
/*   ----------------------------------------                                                        */
/*   luaopen_marpaESLIFLua(L);                                                                       */
/*   lua_pop(1);                                                                                     */
/*                                                                                                   */
/*   OR                                                                                              */
/*                                                                                                   */
/*   luaL_requiref(L, "marpaESLIFLua", marpaESLIFLua_installi, 1);                                   */
/*   lua_pop(1);                                                                                     */
/*                                                                                                   */
/* - Inject external contexts programmatically if required:                                          */
/*   ------------------------------------------------------                                          */
/* - marpaESLIF, marpaESLIFGrammar, marpaESLIFRecognizer marpaESLIFValue                             */
/*   all have explicit methods to inject unmanaged values:                                           */
/*                                                                                                   */
/*   marpaESLIF_newFromUnmanaged(L, marpaESLIFp)                                                     */
/*   marpaESLIFGrammar_newFromUnmanaged(L, marpaESLIFGrammarp)                                       */
/*   marpaESLIFRecognizer_newFromUnmanaged(L, marpaESLIFRecognizerp)                                 */
/*   marpaESLIFValue_newFromUnmanaged(L, marpaESLIFValuep)                                           */
/*                                                                                                   */
/*   If the caller defines MARPAESLIFLUA_CONTEXT then it is taken as-is.                             */
/*                                                                                                   */
/* All those functions:                                                                              */
/* - are available only programmatically                                                             */
/* - pushes on lua stack the same lua object as their "new" counterparts but with NO reference thus  */
/*   no guaranteed lifetime                                                                          */
/*                                                                                                   */
/* The caller is responsible to manage these objects lifetime buy storing these objects. The easiest */
/* way to do that is to store them as global variables.                                              */
/* ------------------------------------------------------------------------------------------------- */
#endif /* MARPAESLIFLUA_EMBEDDED */

#endif /* MARPAESLIFLUA_H*/
