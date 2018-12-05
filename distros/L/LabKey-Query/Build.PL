use strict;
use warnings;
use Module::Build;

# See perldoc Module::Build for details of how this works
Module::Build->new (
    module_name => 'LabKey::Query',

    dist_author => ['LabKey Software <info@labkey.com>'],
    dist_abstract => 'For interacting with data in LabKey Server',
    dist_name => 'LabKey-Query',
    dist_version_from => 'lib/LabKey/Query.pm',

    license => 'apache',
    create_license => 1,
    create_readme => 0,

    provides => {
        'LabKey::Query' => {
            file => 'lib/LabKey/Query.pm'
        }
    },

    requires => {
        'LWP::UserAgent' => 0,
        'HTTP::Request' => 0,
        'Data::Dumper' => 0,
        'JSON' => 2,
        'File::Spec' => 0,
        'File::HomeDir' => 0,
        'FileHandle' => 0,
        'URI' => 0,
        'Carp' => 0,
        'IO::Socket::SSL' => 0
    },

    configure_requires => {
        'Module::Build' => 0.42
    },

    add_to_cleanup => [ 'LabKey-Query-*' ],

    meta_merge => {
        resources => {
            homepage => 'https://www.labkey.org/Documentation/wiki-page.view?name=viewAPIs',
            issues => 'https://www.labkey.org/home/Developer/issues/issues-list.view?issues-issues.area~eq=Perl%20Client%20API',
            repository => 'https://github.com/LabKey/labkey-api-perl'
        }
    }

)->create_build_script;
