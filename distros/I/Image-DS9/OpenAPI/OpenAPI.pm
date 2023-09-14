# ABSTRACT: Grammar definitions

use strict;
use warnings;

use JSON::PP;
use latest;
our $VERSION = '0.189';

# TODO:
#  shm

my %Schemas = (

    'object_name' => {
        type => 'string',
    },

    'angle_unit' => {
        type => 'string',
        enum => [ 'degrees', 'arcmin', 'arcsec' ],
    },

    'skyframe' => {
        type => 'string',
        enum => [ 'fk4', 'fk5', 'icrs', 'galactic', 'ecliptic' ],
    },

    'skyformat' => {
        type => 'string',
        enum => [ 'degrees', 'sexagesimal' ],
    },

    'endian' => {
        type => 'string',
        enum => [ 'big', 'little', 'native' ],
    },

    'coordsys' => {
        type => 'string',
        enum => [ 'physical', 'image', 'wcs', map { 'wcs' . $_ } ( 'a' .. 'z' ) ],
    },

    'sexagesimal_dec' => {
        'pattern' => '[+-]?\d{2}:\d{2}:\d{2}(?:.\d+)?',
    },

    'sexagesimal_ra' => {
        'pattern' => '\d{2}:\d{2}:\d{2}(?:.\d+)?',
    },

    'positive_integer' => {
        type             => 'integer',
        exclusiveMinimum => 0,
    },

    'positive_number' => {
        type             => 'number',
        exclusiveMinimum => 0,
    },

    surveySize => {
        type       => 'object',
        properties => {
            width  => { '$ref' => '#/components/schemas/positive_number' },
            height => { '$ref' => '#/components/schemas/positive_number' },
            unit   => { '$ref' => '#/components/schemas/angle_unit' },
        },
    },

    'coords' => {
        type       => 'object',
        properties => {
            ra  => { '$ref' => '#/components/schemas/sexagesimal_ra' },
            dec => { '$ref' => '#/components/schemas/sexagesimal_dec' },
        },
    },

    frame_location => {
        type => 'string',
        emum => [ 'new', 'location' ],
    },

    '2mass_surveys' => {
        type => 'string',
        enum => [ 'j', 'h', 'k' ],
    },

);

my %Parameters = (

    widthParam => {
        name     => 'width',
        in       => 'path',
        required => 'true',
        schema   => { '$ref' => '#/components/schemas/positive_number' },
    },

    heightParam => {
        name     => 'width',
        in       => 'path',
        required => 'true',
        schema   => { '$ref' => '#/components/schemas/positive_number' },
    },

    angular_unitParam => {
        name     => 'angular_unit',
        in       => 'path',
        required => 'true',
        schema   => { '$ref' => '#/components/schemas/angular_unit' },
    },

    frame_locationParam => {
        name     => 'location',
        in       => 'path',
        required => 'true',
        schema   => { '$ref' => '#/components/schemas/frame_location' },
    },

);


my %Responses = (

    emptySuccess => {
        description => 'empty success',
        content     => {},
    },

    objectName => {
        description => 'object name',
        content     => {
            '*/*' => {
                schema => { '$ref' => '#/components/schemas/object_name' },
            },
        },
    },

    surveySize => {
        description => 'size of survey image',
        content     => {
            '*/*' => {
                schema => { '$ref' => '#/components/schemas/surveySize' },
            },
        },
    },
);

my %Paths = (

    '/2mass' => {
        summary => 'pop up 2mass catalogue requestor',
        'put'   => {
            operationId => '2pmass_put',
            responses   => {
                '200' => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
        'get' => {
            operationId => '2pmass_get',
            responses   => {
                '200' => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
    },

    '/2mass/name' => {
        'get' => {
            operationId => '2mass_name',
            responses   => {
                '200' => { '$ref' => '#/components/responses/object_name' },
            },
        },
    },

    '/2mass/name/clear' => {
        'put' => {
            operationId => '2mass_name_clear',
            responses   => {
                '200' => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
    },

    '/2mass/name/{object}' => {
        'put' => {
            operationId => '2mass_name_object',
            responses   => {
                '200' => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
        'parameters' => [ {
                name     => 'object',
                in       => 'path',
                required => 'true',
                schema   => { '$ref' => '#/components/schema/object_name' },
            },
        ],
    },

    '/2mass/name/{ra}/{dec}' => {
        'put' => {
            operationId => '2mass_name_put',
        },
        'parameters' => [

            {
                name     => 'ra',
                in       => 'path',
                required => 'true',
                schema   => {
                    '$ref' => '#/components/schema/sexagesimal_ra',
                },
            },
            {
                name     => 'dec',
                in       => 'path',
                required => 'true',
                schema   => {
                    '$ref' => '#/components/schema/sexagesimal_dec',
                },
            },
        ],
    },

    '/2mass/coord' => {
        'get' => {
            description => 'retrieve coordinate of object',
            operationId => 'get2MassCoord',
            responses   => {
                '200' => {
                    content => {
                        '*/*' => {
                            schema => {
                                '$ref' => '#/components/schemas/coords',
                            },
                        },
                    },
                },
            },
        },
    },

    '/2mass/size/{width}/{height}/{angular_unit}' => {
        'put' => {
            operationId => '2mass_put_size',
            responses   => {
                200 => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
        'parameters' => [ {
                '$ref' => '#/components/parameters/widthParam',
            },
            {
                '$ref' => '#/components/parameters/heightParam',
            },
            {
                '$ref' => '#/components/parameters/angular_unitParam',
            },
        ],
    },

    '/2mass/size' => {
        'get' => {
            operationId => '2mass_get_size',
            responses   => {
                200 => { '$ref' => '#/components/responses/surveySize' },
            },
        },
    },

    '/2mass/save/{save}' => {
        'put' => {
            operationId => '2mass_put_save',
            responses   => {
                200 => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
        'parameters' => [ {
                name   => 'save',
                in     => 'path',
                schema => {
                    type => 'boolean',
                },
                required => 1,
            },
        ],
    },

    '/2mass/save' => {
        'get' => {
            operationId => '2mass_get_save',
            responses   => {
                200 => {
                    content => {
                        '*/*' => {
                            schema => {
                                type => 'boolean',
                            },
                        },
                    },
                },
            },
        },
    },

    '/2mass/frame/{location}' => {
        'put' => {
            operationId => '2mass_put_frame',
            responses   => {
                200 => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
        'parameters' => [ {
                '$ref' => '#/components/parameters/frame_locationParam',
            },
        ],
    },

    '/2mass/frame' => {
        'get' => {
            operationId => '2mass_get_frame',
            responses   => {
                200 => {
                    content => {
                        '*/*' => {
                            schema => {
                                '$ref' => '#/components/schemas/frame_location',
                            },
                        },
                    },
                },
            },
        },
    },

    '/2mass/update/{what}' => {
        'put' => {
            operationId => '2mass_put_update',
            responses   => {
                200 => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
        'parameters' => [ {
                name     => 'what',
                required => 1,
                schema   => {
                    type => 'string',
                    enum => [ 'frame', 'crosshair' ],
                },
            },
        ],
    },

    '/2mass/survey/{survey}' => {
        'put' => {
            operationId => '2mass_put_survey',
            responses   => {
                200 => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
        'parameters' => [ {
                name     => 'survey',
                required => 1,
                schema   => { '$ref' => '#/components/schemas/2mass_surveys' },
            },
        ],

    },

    '/2mass/survey' => {
        'get' => {
            operationId => '2mass_get_survey',
            responses   => {
                200 => {
                    content => {
                        '*/*' => {
                            schema => {
                                '$ref' => '#/components/schemas/2mass_surveys',
                            },
                        },
                    },
                },
            },
        },
    },


    '/2mass/open' => {
        'put' => {
            operationId => '2mass_put_open',
            responses   => {
                200 => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
    },

    '/2mass/close' => {
        'put' => {
            operationId => '2mass_put_close',
            responses   => {
                200 => { '$ref' => '#/components/responses/emptySuccess' },
            },
        },
    },

);


say JSON::PP->new->pretty()->encode( {
        openapi => '3.0.3',
        info    => {
            title   => 'DS9 XPA/SAMP Interface',
            version => '0.01',
        },
        components => {
            schemas    => \%Schemas,
            parameters => \%Parameters,
            responses  => \%Responses,

        },
        paths => \%Paths,
    } );

1;
