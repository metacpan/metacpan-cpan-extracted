

/* need undef 'cause PERM is a pdl macro as well as a meschach typedef */
#undef PERM

MAT *pdl2mat( pdl* , int* );
VEC *pdl2vec( pdl* , int* );
PERM *pdl2perm( pdl* , int* );

pdl	*mat2pdl( pdl* , MAT *,  int, int );
pdl	*vec2pdl( pdl* , VEC *,  int, int, int* );
pdl	*perm2pdl( pdl* , PERM *,  int, int );

int mes_free_m( MAT * , int  );	
int mes_free_v( VEC * , int  );	
int mes_free_px( PERM * , int  );	
