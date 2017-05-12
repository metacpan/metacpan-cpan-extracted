# MakeMaker for File::FindByRegex module.
#
# Author: Enrique Castilla Contreras <ecastilla@wanadoo.es>. Jan-2003.
#

use ExtUtils::MakeMaker;

my $dists_dir = 'd:\enriw\mylib\dists';

WriteMakefile(
    'NAME' => 'File::FindByRegex',
    'VERSION_FROM' => 'FindByRegex.pm', # finds $VERSION

    ($] >= 5.005 ?    ## new keywords supported since 5.005
      (ABSTRACT_FROM => 'FindByRegex.pm', # retrieve abstract from module
       AUTHOR     => 'Enrique Castilla <ecastilla@wanadoo.es>') : ()),

    'PM' => {
               'FindByRegex.pm' => '$(INST_LIBDIR)/FindByRegex.pm'
            },

    'HTMLLIBPODS' => { 'FindByRegex.pm' => '$(INST_HTMLLIBDIR)/FindByRegex.html'},

    # !! IMPORTANTE !!:
    # Los siguientes atributos de WriteMakefile (que despues se convierten en
    # macros en el Makefile generado), no reciben un valor por defecto, por
    # lo que hay que asignarselos explicitamente.
    # 
    # Significan:
    #
    # INST_HTMLLIBDIR       = Donde se generan los html al ejecutar 'make'.
    # INSTALLHTMLPRIVLIBDIR = Donde se instalan los html si $(INSTALLDIRS) es 'perl'
    # INSTALLHTMLSITELIBDIR = Idem si $(INSTALLDIRS) es 'site'.
    #                            
    # INST_HTMLSCRIPTDIR    = Donde se generan los html de scripts al ejecutar 'make'.
    # INSTALLHTMLSCRIPTDIR  = Donde se instalan los html de scripts.

    INST_HTMLLIBDIR       => './blib/html',
    INSTALLHTMLPRIVLIBDIR => '$(PREFIX)/html/site/lib/File',
    INSTALLHTMLSITELIBDIR => '$(PREFIX)/html/site/lib/File',
                               
    INST_HTMLSCRIPTDIR    => './blib/script',
    INSTALLHTMLSCRIPTDIR  => '$(INSTALLSCRIPT)',

    # Que ficheos hay que borrar ademas de los de por defecto, cuando se ejecuta
    # el target 'make clean' o 'make realclean'.
    clean => { FILES => 'pod2htmd.x~~ pod2htmi.x~~ #*#' },
    realclean => { FILES => 'pod2htmd.x~~ pod2htmi.x~~ .exists #*# *.tar.gz' },

    # La clave 'dist' permite customizar comose genera la distribucion.
    # Hacemos que la distribucion se copie en un directorio determinado: $(PREFIX)
    # dist => { POSTOP => '$(MV) *.tar.gz $(PREFIX)' },  # POr defecto copiamos las distribuciones en C:\Perl
    dist => { POSTOP => '$(MV) *.tar.gz '.$dist_dir },

    htmlifypods => { POD2HTML_EXE => 'C:\Perl\bin\pod2html.bat --css C:\Perl\Html\Active.css' }  
    # No hace nada. Sopongo que es porque la generacion de codigo del Makefile para
    # esta seccion se hace en hardcode, sin tener en cuentan lo que se establezca
    # en WriteMakefile. La solucion es sobreescribir (override) el metodo 
    # 'htmlifypods'. Ver mas adelante.

    # !! NOTA !!
    # Observese que cada comentario del Makefile de la forma '# --- MakeMaker htmlifypods section:'
    # encabeza una seccion que se corresponde con una clave del mismo nombre en el hash de 
    # WriteMakefile.
    # Ademas, la doc de MakeMaker dice que se puede cambiar el codigo fuente del Makefile generado
    # para una seccion sobreescribiendo el metodo del mismo nombre (en el paquete MY).
); 

# !! IMPORTANTE !!
# La documentacion de MakeMaker explica como sobreescribir un metodo para
# generar un codigo fuente distinto para una de las secciones del Makefile.
# Lo siguiente es un extracto literal de la doc de MakeMaker.
#
# Overriding MakeMaker Methods
# If you cannot achieve the desired Makefile behaviour by specifying attributes you may define private subroutines in the Makefile.PL. Each subroutines returns the text it wishes to have written to the Makefile. To override a section of the Makefile you can either say:
#
#         sub MY::c_o { "new literal text" }
# or you can edit the default by saying something like:
#
#         sub MY::c_o {
#             package MY; # so that "SUPER" works right
#             my $inherited = shift->SUPER::c_o(@_);
#             $inherited =~ s/old text/new text/;
#             $inherited;
#         }
#
sub MY::htmlifypods 
{
            package MY; # so that "SUPER" works right
            my $inherited = shift->SUPER::htmlifypods(@_);
            $inherited =~ s/pod2html\.bat/pod2html\.bat --css C:\\Perl\\Html\\Active\.css --header/;
            $inherited;
}

# !! Nota para distribuciones ActivePerl de ActiveState !!:
# Se puede regenerar manualmente la tabla de contenido de la ayuda online
# (C:\Perl\html\perltoc.html) para que incluya la ayuda html de los ultimos
# paquetes instalados con:
#
#    > perl -MActivePerl::DocTools -e  ActivePerl::DocTools::WriteTOC();
#
# O mediante un script:
#
#    use ActivePerl::DocTools;
#    ActivePerl::DocTools::WriteTOC();
# 
# Sin embargo, la funcion WriteTOC() supone que el archivo html de doc
# de cada paquete se llama igual que el paquete (sin .pm) y con extension
# .html. Asi, no es valido nombrar Simple.pm.html el archivo d documentacion
# porq la nueva URL de la tabla de contenido se referira a Simple.html .
#

eval {
         sub MY::install
         {
             package MY; # so that "SUPER" works right
             my $inherited = shift->SUPER::install(@_);

             my $regendoc_cmd = "        perl -MActivePerl::DocTools -e  ActivePerl::DocTools::WriteTOC()\n\n";

             $inherited =~ s|^(doc_site_install\s+::\s+(.+\n)+)([ \t]*\n)|$1$regendoc_cmd|m;
             $inherited =~ s|^(doc_perl_install\s+::\s+(.+\n)+)([ \t]*\n)|$1$regendoc_cmd|m;

             #print STDOUT $inherited;

             $inherited;
         }                     
} if $^O eq 'MSWin32';
#
# !! Explicacion !!
# El anterior eval se evalua en tiempo de precompilacion, porque es un bloque (ver doc de eval).
# Al evaluarse hace que se defina una funcion: MY::install, que redefine la seccion 'install'
# del makefile (es decir, la forma en que se genera esta seccion del makefile), añadiendo la
# ejecucion de un comando ($regendoc_cmd), que lo que hace es regenerar la tabla de contenido de
# la doc online de ActivePerl.
# Notese que el comando debe estar indentado por ser codigo de un makefile.


__END__

Las macros con * son las unicas a las que WriteMakefile asigna un valor por
defecto:

                                  INSTALLDIRS set to
                               perl                site
 *    INST_ARCHLIB        INSTALLARCHLIB        INSTALLSITEARCH
 *    INST_LIB            INSTALLPRIVLIB        INSTALLSITELIB
     INST_HTMLLIBDIR     INSTALLHTMLPRIVLIBDIR INSTALLHTMLSITELIBDIR
     INST_HTMLSCRIPTDIR            INSTALLHTMLSCRIPTDIR
 *    INST_BIN                      INSTALLBIN
 *    INST_SCRIPT                   INSTALLSCRIPT
     INST_MAN1DIR                  INSTALLMAN1DIR
     INST_MAN3DIR                  INSTALLMAN3DIR

Las siguientes macros estan en el Makefile generado pero no estan
documentadas. Son utiles si se usa MakeMaker para desarrollar con C/C++:

INST_EXE
INST_STATIC
INST_DYNAMIC
INST_BOOT


Secuencia de comandos mas frecuente:

    perl Makefile.PL
    nmake manifest   (del by hand a line with Makefile)
    nmake
    nmake test
    nmake install
    nmake dist
    nmake realclean  ó nmake clean (que borra menos cosas)
    
