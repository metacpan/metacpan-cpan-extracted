cd $(dirname $0)
cd ..
${PERL:-perl} Build.PL
${COVER:-cover} -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover ./Build test
${COVER:-cover}
