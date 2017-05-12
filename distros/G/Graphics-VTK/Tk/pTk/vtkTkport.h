/* VTK Tk header file for perltk implementation of VTK TK widgets */


/* C++ Doesn't like the declarations like 'typedef struct Var *Var' in the 
   Lang.h header, so we make our own type defs to 'typedef struct Var *Var_',
   and then redefined Var to Var_
*/
typedef struct Var *Var_;
#define Var Var_

typedef struct LangCallback *LangCallback_;
#define LangCallback LangCallback_

#undef Arg
typedef struct Tcl_Obj *Arg_;
#define Arg Arg_

