%module RmiExample


%typemap(out) jstring {
        EXTEND(sp, 1);
        $result = sv_newmortal();

        jint len = JvGetStringUTFLength($1);
        if ( len == 0 ) {
                sv_setpv($result, "");
        } else {
                char *buffer = new char[len + 1];
                JvGetStringUTFRegion($1, 0, len, buffer);
                buffer[(int) len] = '\0';
                sv_setpv($result, buffer);
                SvUTF8_on($result);
                delete buffer;
        }
        argvi++;
}

class Client
{
public:
  Client ();
  virtual void connect ();
  virtual ::SomeBean *getBeanFromServer ();
  static void main (JArray< ::java::lang::String *> *);
};

class SomeBean
{
public:
  SomeBean ();
  virtual void setValue (::java::lang::String *);
  virtual jstring getValue () { return value; }
};

