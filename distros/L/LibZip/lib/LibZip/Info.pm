##############################
# INFORMATION OF LIB CONTENT #
##############################

package LibZip::Info ;
use vars qw(%DATA %DEPENDENCIES) ;
no warnings ;

## KEY = MODULE # VAL = PACKAGE WITH <DATA>

%DATA = (
  'Locale::Script' => 'Locale::Script' ,
  'Locale::Language' => 'Locale::Language' ,
  'Devel::PPPort' => 'Devel::PPPort' ,
  'Opcode' => 'contains' ,
  'Locale::Currency' => 'Locale::Currency' ,
  'I18N::LangTags::List' => 'I18N::LangTags::List' ,
  'Term::Cap' => 'Term::Cap' ,
  'Pod::Functions' => 'variable' ,
  'Locale::Country' => 'Locale::Country' ,
) ;


## KEY = MODULE # VAL = ARRAY REF OR MODULES (IO = IO::* | Storable.pm = file )

%DEPENDENCIES = (
#'IO::Socket' => ['IO'] ,
#'StorableFile' => ['Storable.pm'] ,
) ;

1;


