#!perl

on runtime => sub {

    requires 'IO::ReStoreFH' => 0.04;
    requires 'IPC::Run';
    requires 'List::Util' => 1.34;
    requires 'List::MoreUtils';
    requires 'Module::Load';
    requires 'Module::Runtime';
    requires 'Moo'        => '1.001000';
    requires 'Type::Tiny' => 0.038;
    requires 'MooX::Attributes::Shadow';
    requires 'Safe::Isa';
    requires 'Template::Tiny';
    requires 'Term::ANSIColor';
    requires 'Try::Tiny';
    requires 'parent';
    requires 'String::ShellQuote';

    requires 'Win32::Console::ANSI'
        if $^O =~ /Win32/i;

};


on develop => sub {

    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';

    requires 'Module::Install';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::AuthorTests';


};

on test => sub {

    requires 'File::pushd';
    requires 'Devel::FindPerl';
    requires 'Test::Base';
    requires 'Test::Deep';
    requires 'Test::Exception';
    requires 'Test::File';
    requires 'Test::Lib';
    requires 'Test::More';
    requires 'Test::Most';
    requires 'Test::Trap';

};
