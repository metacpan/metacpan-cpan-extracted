#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "libstardict.h"

#define MSTR(str) # str




/*  */
static bool bContainRule(const char* sWord)
{
  int i;
  for(i=0;sWord[i]!=0;i++){
    if(sWord[i]=='*' || sWord[i]=='?'){
      return true;
    }
  }
  
  return false;
}



class StarDict: public LibCore {
  public:
    StarDict(const StringsList & enable_list, 
	     const StringsList & disable_list, 
	     const char *_stardict_data_dir=NULL);
};
StarDict::StarDict(
	     const StringsList & enable_list, 
	     const StringsList & disable_list, 
	     const char *_stardict_data_dir
	     ) : LibCore (enable_list, disable_list, _stardict_data_dir) 
	     {};


// -- END OF C/C++ PART -- //




MODULE = Lingua::StarDict		PACKAGE = Lingua::StarDict		

StarDict *
StarDict::new(...)
    CODE:

        StringsList enable_list;
	StringsList disable_list;

	SV* name = sv_newmortal();
	SV* val = sv_newmortal();;

	/*  Parse input params   */
	if ( 0 == (items - 1) % 2){ // without THIS
	    for( int i = 1; i < items; i = i+2){
		name = ST(i);
		val  = ST(i+1);
		if ( SvOK( name ) && SvOK(val) ){
		    if ( strEQ( SvPV(name, PL_na), "dict" )){
			/* define certain dictionary */
			enable_list.push_back( SvPV(val, PL_na) );
		    }
		}
		
	    }
	}
    

	RETVAL = new StarDict(enable_list, disable_list, NULL);

    OUTPUT:
	RETVAL

void
StarDict::DESTROY()


void
StarDict::dictionaries()
    PPCODE:

        dTARG;

	// result array
	AV* dicts = (AV *)sv_2mortal((SV *)newAV());


        std::vector<BookInfo> dicts_list=THIS->GetBooksInfo();
        for(std::vector<BookInfo>::iterator ptr=dicts_list.begin();
	    ptr!=dicts_list.end(); ++ptr
	){
	    HV* dict;
	    dict = (HV *)sv_2mortal((SV *)newHV());

	    hv_store( dict, 
		"bookname", strlen("bookname"), 
		newSVpv( ptr->bookname.c_str(), strlen(ptr->bookname.c_str()) ),
		0);

	    hv_store( dict, 
		"wordcount", strlen("wordcount"), 
		newSViv( (IV) ptr->wordcount ),
		0);


	    hv_store( dict, 
		"ifofile", strlen("ifofile"), 
		newSVpv( ptr->name_of_ifofile.c_str(), strlen(ptr->name_of_ifofile.c_str()) ),
		0);

	    av_push(dicts, newRV( (SV*) dict) );
		
	}

    
	SV* ref = newRV( (SV*) dicts );
    
	EXTEND(SP, 1);
        PUSHs(sv_2mortal( ref ));


	
void
StarDict::search( str )
    char * str
    PPCODE:


	LibCore::SearchResultsList res;
	bool is_found=false;
	  
	if(str[0]=='/'){
	    is_found=THIS->LookupWithFuzzy(str+1, res);
	}
	else if(bContainRule(str)){
	    is_found=THIS->LookupWithRule(str, res);
	}
	else{
	    if(!(is_found=THIS->SimpleLookup(str, res)))
	      is_found=THIS->LookupWithFuzzy(str, res);
	}


	AV * a_res;
	a_res = (AV *)sv_2mortal((SV *)newAV());

        LibCore::PSearchResult ptr;
	for(ptr=res.begin(); ptr!=res.end(); ++ptr){
	    HV* w = (HV *)sv_2mortal((SV *)newHV());

	    hv_store( w,
		"bookname", strlen("bookname"),
		newSVpv( ptr->bookname.c_str(), strlen(ptr->bookname.c_str()) ),
		0);

	    hv_store( w,
		"definition", strlen("definition"),
		newSVpv( ptr->definition.c_str(), strlen(ptr->definition.c_str()) ),
		0);

	    hv_store( w,
		"explanation", strlen("explanation"),
		newSVpv( ptr->explanation.c_str(), strlen(ptr->explanation.c_str()) ),
		0);

	    av_push(a_res, newRV( (SV*) w ) );
	}



	SV* ref = newRV( (SV*) a_res );
    
	EXTEND(SP, 1);
        PUSHs(sv_2mortal( ref ));





