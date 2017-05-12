char* __HugsServerAPI__clearError (HugsServerAPI*);
void __HugsServerAPI__setHugsArgs (HugsServerAPI*, int,  char**);
int __HugsServerAPI__getNumScripts (HugsServerAPI*);
void __HugsServerAPI__reset (HugsServerAPI*, int);
void __HugsServerAPI__setOutputEnable (HugsServerAPI*, unsigned);
void __HugsServerAPI__changeDir (HugsServerAPI*, char*);
void __HugsServerAPI__loadProject (HugsServerAPI*, char*);
void __HugsServerAPI__loadFile (HugsServerAPI*, char*);
void __HugsServerAPI__loadFromBuffer (HugsServerAPI*, char*);
void __HugsServerAPI__setOptions (HugsServerAPI*, char*);
char* __HugsServerAPI__getOptions (HugsServerAPI*);
HVal __HugsServerAPI__compileExpr (HugsServerAPI*, char*, char*);
void __HugsServerAPI__garbageCollect (HugsServerAPI*);
void __HugsServerAPI__lookupName (HugsServerAPI*, char*, char*);
void __HugsServerAPI__mkInt (HugsServerAPI*, int);
void __HugsServerAPI__mkAddr (HugsServerAPI*, void*);
void __HugsServerAPI__mkString (HugsServerAPI*, char*);
void __HugsServerAPI__apply (HugsServerAPI*);
int __HugsServerAPI__evalInt (HugsServerAPI*);
void* __HugsServerAPI__evalAddr (HugsServerAPI*);
char* __HugsServerAPI__evalString (HugsServerAPI*);
int __HugsServerAPI__doIO (HugsServerAPI*);
int __HugsServerAPI__doIO_Int (HugsServerAPI*, int*);
int __HugsServerAPI__doIO_Addr (HugsServerAPI*, void**);
HVal __HugsServerAPI__popHVal (HugsServerAPI*);
void __HugsServerAPI__pushHVal (HugsServerAPI*, HVal);
void __HugsServerAPI__freeHVal (HugsServerAPI*, HVal);
%{
#define __HugsServerAPI__clearError(hugs) (hugs->clearError())
#define __HugsServerAPI__setHugsArgs(hugs, hugs_var1, hugs_var2) (hugs->setHugsArgs(hugs_var1, hugs_var2))
#define __HugsServerAPI__getNumScripts(hugs) (hugs->getNumScripts())
#define __HugsServerAPI__reset(hugs, hugs_var1) (hugs->reset(hugs_var1))
#define __HugsServerAPI__setOutputEnable(hugs, hugs_var1) (hugs->setOutputEnable(hugs_var1))
#define __HugsServerAPI__changeDir(hugs, hugs_var1) (hugs->changeDir(hugs_var1))
#define __HugsServerAPI__loadProject(hugs, hugs_var1) (hugs->loadProject(hugs_var1))
#define __HugsServerAPI__loadFile(hugs, hugs_var1) (hugs->loadFile(hugs_var1))
#define __HugsServerAPI__loadFromBuffer(hugs, hugs_var1) (hugs->loadFromBuffer(hugs_var1))
#define __HugsServerAPI__setOptions(hugs, hugs_var1) (hugs->setOptions(hugs_var1))
#define __HugsServerAPI__getOptions(hugs) (hugs->getOptions())
#define __HugsServerAPI__compileExpr(hugs, hugs_var1, hugs_var2) (hugs->compileExpr(hugs_var1, hugs_var2))
#define __HugsServerAPI__garbageCollect(hugs) (hugs->garbageCollect())
#define __HugsServerAPI__lookupName(hugs, hugs_var1, hugs_var2) (hugs->lookupName(hugs_var1, hugs_var2))
#define __HugsServerAPI__mkInt(hugs, hugs_var1) (hugs->mkInt(hugs_var1))
#define __HugsServerAPI__mkAddr(hugs, hugs_var1) (hugs->mkAddr(hugs_var1))
#define __HugsServerAPI__mkString(hugs, hugs_var1) (hugs->mkString(hugs_var1))
#define __HugsServerAPI__apply(hugs) (hugs->apply())
#define __HugsServerAPI__evalInt(hugs) (hugs->evalInt())
#define __HugsServerAPI__evalAddr(hugs) (hugs->evalAddr())
#define __HugsServerAPI__evalString(hugs) (hugs->evalString())
#define __HugsServerAPI__doIO(hugs) (hugs->doIO())
#define __HugsServerAPI__doIO_Int(hugs, hugs_var1) (hugs->doIO_Int(hugs_var1))
#define __HugsServerAPI__doIO_Addr(hugs, hugs_var1) (hugs->doIO_Addr(hugs_var1))
#define __HugsServerAPI__popHVal(hugs) (hugs->popHVal())
#define __HugsServerAPI__pushHVal(hugs, hugs_var1) (hugs->pushHVal(hugs_var1))
#define __HugsServerAPI__freeHVal(hugs, hugs_var1) (hugs->freeHVal(hugs_var1))
%}
