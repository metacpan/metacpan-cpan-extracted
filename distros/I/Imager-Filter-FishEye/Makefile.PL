use inc::Module::Install;
name 'Imager-Filter-FishEye';
all_from 'lib/Imager/Filter/FishEye.pm';

configure_requires  'Imager'           => '0.65';
requires 'Imager' => 0.65;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
auto_set_repository();
author_tests 'xt';
WriteAll;

sub MY::post_constants {
    eval { require Imager::ExtUtils };
    if ($@) {
        warn "*** You must install Imager.";
        exit 0;    # tell cpan testers that this is not a failure
    }
    my $typemap  = Imager::ExtUtils->typemap;
    my $includes = Imager::ExtUtils->includes;
    return <<"POST_CONST";
XSUBPPARGS += -typemap $typemap
INC += $includes
POST_CONST
}

