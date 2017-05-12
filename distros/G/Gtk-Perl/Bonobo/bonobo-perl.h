
typedef CORBA_ORB              CORBA__ORB;
typedef CORBA_Object           CORBA__Object;
typedef CORBA_TypeCode         CORBA__TypeCode;
typedef ORBit_RootObject       CORBA__ORBit__RootObject;

typedef CORBA_long_long     CORBA__LongLong;
typedef CORBA_unsigned_long_long    CORBA__ULongLong;
typedef CORBA_long_double   CORBA__LongDouble;

typedef PortableServer_POA            PortableServer__POA;
typedef PortableServer_POAManager     PortableServer__POAManager;
typedef PortableServer_ObjectId       PortableServer__ObjectId;
typedef PortableServer_Servant        PortableServer__ServantBase;

#define DEFINE_EXCEPTION(ev)                  \
   CORBA_Environment ev;                      \
   CORBA_exception_init (&ev);

#define CHECK_EXCEPTION(ev)                   \
   if (ev._major != CORBA_NO_EXCEPTION) {     \
      SV *__sv = porbit_builtin_except (&ev); \
      porbit_throw (__sv);                    \
   }

#define TRY(expr)                             \
   G_STMT_START {                             \
       DEFINE_EXCEPTION(ev)                   \
       expr;                                  \
       CHECK_EXCEPTION(ev)                    \
   } G_STMT_END


extern CORBA__Object porbit_sv_to_objref (SV*);
extern SV * porbit_objref_to_sv (CORBA__Object);

typedef BonoboUINode* Bonobo__UINode;
