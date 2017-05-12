/*
  The following main function can be used in place of the standard main
  function within ezxml.c to create an ezxml.exe that can be used with
  the benchmarking system in XML::Bare. Note EZ_XMLTEST should be defined
  in ezxml.c as well in order to build an exe.
*/
int main(int argc, char **argv)
{
    ezxml_t xml;
    
    xml = ezxml_parse_file(argv[1]);
    
    ezxml_free(xml);
    return (i) ? 1 : 0;
}