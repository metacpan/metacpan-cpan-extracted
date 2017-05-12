
/* Strucuture that keeps track of contexts */
struct PJS_Context {
    /* total number of branch_operations the runtime went through in this context */
    int branch_count;
   
    /* max number of branch_operations allowed in this context */ 
    int branch_max;
};

typedef struct PJS_Context PJS_Context;

