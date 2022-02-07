# http://bit.ly/cpanfile
# http://bit.ly/cpanfile_version_formats
requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';

# for CLI
requires 'Pod::Usage';
requires 'Getopt::Long';
requires 'JSON';

on 'test' => sub {
    requires 'File::Basename';
    requires 'YAML', '1.15';
    requires 'List::Util';
    requires 'Test::More', '1.3';
    requires 'Test::AllModules', '0.17';
    requires 'HTTP::Headers';
    # for CLI
    requires 'Capture::Tiny';
};

on 'configure' => sub {
    requires 'Module::Build' , '0.42';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};

on 'develop' => sub {
    requires 'Software::License';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod';
    requires 'Test::NoTabs';
    requires 'Test::Vars';
    requires 'File::Find::Rule::ConflictMarker';
    requires 'File::Find::Rule::BOM';
};
