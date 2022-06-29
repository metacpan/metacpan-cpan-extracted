#!/bin/csh

set self = `/usr/sbin/lsof +p $$ | grep -oE /.\*nuggit.csh`
set rootdir = `dirname $self`
set abs_rootdir = `cd $rootdir && pwd`

# Add the bin dir to your path
setenv PATH ${abs_rootdir}/bin:${PATH}

# And lib to perl5lib
if ( $?PERL5LIB ) then
    setenv PERL5LIB ${abs_rootdir}/lib:${PERL5LIB}
else
    setenv PERL5LIB ${abs_rootdir}/lib
endif

# Autocomplete (ngt will provide autocomplete responses for itself, when appropriate env variable is set)
complete ngt 'p/*/`ngt`/'
