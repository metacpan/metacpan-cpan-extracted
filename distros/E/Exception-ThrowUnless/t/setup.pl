use Exception::ThrowUnless qw(:all);

system("chmod -R 700 tmp; rm -fr tmp") if ( -e 'tmp' );
smkdir 'tmp', 0700;
