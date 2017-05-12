use inc::Module::Install;

&replace_perl_path;

name 'Lingua-JA-TFIDF';
all_from 'lib/Lingua/JA/TFIDF.pm';

requires('Text::MeCab');
requires('List::MoreUtils');
requires('Storable');
requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('LWP::UserAgent');
requires('XML::TreePP');
requires('Carp');
requires('HTML::Feature');
build_requires 'Test::More';
build_requires 'Test::HTTP::Server::Simple';
build_requires 'HTTP::Server::Simple::CGI';
recommends('YAML::Sync');
recommends('Getopt::Long');
recommends('Term::ReadLine');
recommends('HTML::Feature');
use_test_base;
auto_install;

install_script('script/tfidf');
WriteAll;

sub replace_perl_path {
    my $perl_path = `which perl`;
    open(SCRIPT, "+<script/tfidf");
    my @code = <SCRIPT>;
    return if $code[0] =~ /^#!/;
    seek(SCRIPT,0,0);
    print SCRIPT '#!' . $perl_path . "\n";
    for(@code){
        print SCRIPT $_;
    }
    truncate(SCRIPT,tell);
    close(SCRIPT);
}
