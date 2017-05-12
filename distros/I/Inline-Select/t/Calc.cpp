class Calc {
	public:
		Calc() ;
		~Calc() ;
		int add(int a, int b) ;
		char *language() ;

	private:
		char *lang ;
} ;


Calc::Calc(){
	lang = strdup("CPP") ;
}

int Calc::add(int a, int b){
	return a + b ;
}

char *Calc::language(){
	return lang ;
}

Calc::~Calc(){
	free(lang) ;
}
