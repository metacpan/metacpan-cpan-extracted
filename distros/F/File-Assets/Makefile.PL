use inc::Module::Install 0.64;

#use 5.008001; 
#perl_version '5.8.1';

name     'File-Assets';
all_from 'lib/File/Assets.pm';
author   'Robert Krimen <rkrimen@cpan.org>';

resources repository => 'http://github.com/robertkrimen/file-assets/tree/master';

{
    require ExtUtils::MakeMaker;
    use strict;
    no strict 'refs';

    my $libscan = \&{"ExtUtils::MM_Any::libscan"};
    *{"ExtUtils::MM_Any::libscan"} = sub {
        return '' unless $libscan->(@_);
        return '' if $_[1] =~ /\.sw[p-z]$/;
        return $_[1];
    };
}

{
    map { my ($pk, $vr) = split m/\s/; build_requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Test::Memory::Cycle
Directory::Scratch
Test::More
_END_

    map { my ($pk, $vr) = split m/\s/; requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
MIME::Types
Module::Pluggable
Path::Resource
Scalar::Util
Tie::LLHash
Digest
Digest::MD5
Digest::SHA
Carp::Clan::Share
Object::Tiny
HTML::Declare
XML::Tiny
IO::Scalar
_END_

    map { my ($pk, $vr) = split m/\s/; recommends $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
CSS::Minifier
JavaScript::Minifier
CSS::Minifier::XS 0.3
JavaScript::Minifier::XS 0.3
_END_
}

if (-e 'inc/.author') {
    my $all_from = join '/', 'lib', split m/-/, name . '.pm';
    `perldoc -tF $all_from > README` if ! -e 'README' || (stat $all_from)[9] > (stat 'README')[9];
}


auto_install;

WriteAll;

