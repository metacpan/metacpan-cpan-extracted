class Foo {
 public:
   Foo() {
 	secret=0;
   }

   ~Foo() { }

   int get_secret() { return secret; }
   void set_secret(int s) {
        Inline_Stack_Vars;
        secret = s;
   }

 protected:
   int secret;
};

class Bar : public Foo {
 public:
   Bar(int s) { secret = s; }
   ~Bar() {  }

   void set_secret(int s) { secret = s * 2; }
};
